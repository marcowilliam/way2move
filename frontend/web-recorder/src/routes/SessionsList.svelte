<script lang="ts">
  import { app } from "../stores/app.svelte.ts";
  import { loadSessions, deleteSession, upsertSession } from "../lib/sessionStore";
  import {
    ensureSeeded,
    canonicalExercises,
    evaluateBucket,
  } from "../lib/exerciseStore";
  import {
    buildGroundUpSession,
    GROUND_UP_WORKOUT_ID,
  } from "../lib/seeds/groundUp";
  import type { Session } from "../lib/types";

  let sessions = $state<Session[]>(loadSessions());
  let library = $state(ensureSeeded());

  const today = new Date();
  const todayISO = today.toISOString().slice(0, 10);

  const greeting = (() => {
    const h = today.getHours();
    if (h < 12) return "Good morning";
    if (h < 18) return "Good afternoon";
    return "Good evening";
  })();

  const prettyDate = (iso: string): string => {
    const d = new Date(iso + "T00:00:00");
    return d.toLocaleDateString("en-US", { weekday: "long", month: "long", day: "numeric" });
  };

  const shortDate = (iso: string): string => {
    const d = new Date(iso + "T00:00:00");
    return d.toLocaleDateString("en-US", { month: "short", day: "numeric" });
  };

  const relDate = (iso: string): string => {
    if (iso === todayISO) return "today";
    const diff = Math.round(
      (new Date(todayISO + "T00:00:00").getTime() - new Date(iso + "T00:00:00").getTime()) /
        86_400_000,
    );
    if (diff === 1) return "yesterday";
    if (diff > 1 && diff < 7) return `${diff}d ago`;
    return iso;
  };

  // Monday-first week of the current date.
  const weekDays = (() => {
    const d0 = new Date(today);
    d0.setDate(d0.getDate() - ((d0.getDay() + 6) % 7));
    return Array.from({ length: 7 }, (_, i) => {
      const d = new Date(d0);
      d.setDate(d0.getDate() + i);
      const iso = d.toISOString().slice(0, 10);
      return {
        iso,
        narrow: d.toLocaleDateString("en-US", { weekday: "narrow" }),
        isToday: iso === todayISO,
        isFuture: iso > todayISO,
        trainedSessions: sessions.filter((s) => s.date === iso),
      };
    });
  })();

  const durationMin = (s: Session): number | null => {
    if (s.durationMinutes != null) return s.durationMinutes;
    if (!s.startedAt) return null;
    const end = s.completedAt ?? (s.status === "in_progress" ? new Date().toISOString() : s.startedAt);
    const m = Math.round(
      (new Date(end).getTime() - new Date(s.startedAt).getTime()) / 60000,
    );
    return m >= 0 ? m : null;
  };

  // "3h47m" when ≥1h, "47m" under. Matches the athlete's mental unit —
  // long sessions shouldn't be displayed as "227m".
  const fmtHrMin = (mins: number | null | undefined): string => {
    if (mins == null || mins <= 0) return "0m";
    if (mins < 60) return `${mins}m`;
    const h = Math.floor(mins / 60);
    const m = mins % 60;
    return m === 0 ? `${h}h` : `${h}h${m}m`;
  };

  const todaySessions = $derived(sessions.filter((s) => s.date === todayISO));
  const todayPrimary = $derived(
    todaySessions.find((s) => s.status === "in_progress") ??
      todaySessions.find((s) => s.status === "completed") ??
      todaySessions[todaySessions.length - 1],
  );
  const todayState = $derived.by(() => {
    if (!todayPrimary) return "idle" as const;
    if (todayPrimary.status === "in_progress") return "in_progress" as const;
    if (todayPrimary.status === "completed") return "completed" as const;
    return "idle" as const;
  });

  const recent = $derived(
    sessions.slice().sort((a, b) => b.date.localeCompare(a.date)).slice(0, 6),
  );

  const weekTrainings = $derived(
    weekDays.filter((d) => d.trainedSessions.length > 0).length,
  );
  const weekMinutes = $derived(
    weekDays
      .flatMap((d) => d.trainedSessions)
      .reduce((sum, s) => sum + (durationMin(s) ?? 0), 0),
  );
  const weekTakes = $derived(
    weekDays
      .flatMap((d) => d.trainedSessions)
      .reduce((sum, s) => sum + s.recordings.length, 0),
  );

  const canonicalCount = $derived(canonicalExercises(library).length);
  const evaluateCount = $derived(evaluateBucket(library).length);

  const openSession = (s: Session) => {
    (app as any).activeSessionId = s.id;
    app.goto("active");
  };

  // "From the Ground Up" — Marco's physio daily routine. Idempotent:
  // if today already has a ground-up session, open it; else create.
  const todayGroundUp = $derived(
    todaySessions.find((s) => s.workoutId === GROUND_UP_WORKOUT_ID),
  );
  const groundUpExerciseCount = 11;

  const startGroundUp = () => {
    if (todayGroundUp) {
      // Heal sessions written by the earlier seed bug (placeholder actualSets
      // with no rows made everything render as completed). Drop empty entries.
      const healed = {
        ...todayGroundUp,
        exerciseBlocks: todayGroundUp.exerciseBlocks.map((b) => ({
          ...b,
          actualSets: b.actualSets.filter((s) => s.rows.length > 0 || s.completed),
        })),
      };
      upsertSession(healed);
      sessions = loadSessions();
      openSession(healed);
      return;
    }
    const fresh = buildGroundUpSession(todayISO);
    upsertSession(fresh);
    sessions = loadSessions();
    openSession(fresh);
  };

  const handleDelete = (e: MouseEvent, s: Session) => {
    e.stopPropagation();
    const when = s.date === todayISO ? "today's" : `${shortDate(s.date)}`;
    const takes = s.recordings.length;
    const msg =
      `Delete ${when} session — "${s.focus ?? s.type}"?\n\n` +
      `${s.exerciseBlocks.length} exercises · ${takes} take${takes === 1 ? "" : "s"}.\n` +
      `Video files on disk are NOT deleted — only this record goes away.`;
    if (!window.confirm(msg)) return;
    deleteSession(s.id);
    sessions = loadSessions();
  };
</script>

<div class="dashboard">
  <!-- Greeting + status header -->
  <header class="dash-header">
    <div class="greeting-block">
      <h1 class="display-greeting">{greeting}, Marco</h1>
      <p class="subtitle">{prettyDate(todayISO)}</p>
    </div>
    <div class="status-row">
      <span class="status-chip" data-state={app.isCameraReady ? "ok" : "off"}>
        Cameras · {app.isCameraReady ? "ready" : "off"}
      </span>
      <span class="status-chip" data-state={app.isFolderReady ? "ok" : "off"}>
        Folder · {app.isFolderReady ? "set" : "missing"}
      </span>
    </div>
  </header>

  <!-- Daily routine — physio "From the Ground Up". Sage = body-listening,
       NEVER Terracotta. Idempotent: tap re-opens today's session if any. -->
  <section
    class="daily-routine"
    data-state={todayGroundUp ? todayGroundUp.status : "idle"}
  >
    <div class="dr-left">
      <p class="label-xs">Daily routine</p>
      <h2 class="dr-title">From the Ground Up</h2>
      <p class="dr-meta">
        <span class="mono">{groundUpExerciseCount}</span> exercises ·
        physio prescription · 6-week protocol
      </p>
    </div>
    <div class="dr-right">
      <button class="big sage" onclick={startGroundUp}>
        {#if todayGroundUp?.status === "in_progress"}
          Continue routine →
        {:else if todayGroundUp?.status === "completed"}
          Done today · review
        {:else}
          Start routine
        {/if}
      </button>
    </div>
  </section>

  <!-- Today hero — state-driven primary CTA -->
  <section class="today" data-state={todayState}>
    <div class="today-left">
      <p class="label-xs">Today</p>
      {#if todayState === "in_progress" && todayPrimary}
        <h2 class="today-title">{todayPrimary.focus ?? "Training in progress"}</h2>
        <p class="today-meta">
          <span class="mono">{todayPrimary.exerciseBlocks.length}</span> exercises ·
          <span class="mono">{todayPrimary.recordings.length}</span> takes
          {#if durationMin(todayPrimary) != null}· <span class="mono">{fmtHrMin(durationMin(todayPrimary))}</span> in{/if}
        </p>
      {:else if todayState === "completed" && todayPrimary}
        <h2 class="today-title">Trained today</h2>
        <p class="today-meta">
          {todayPrimary.focus ?? "Training"} ·
          <span class="mono">{todayPrimary.exerciseBlocks.length}</span> exercises ·
          <span class="mono">{todayPrimary.recordings.length}</span> takes
          {#if durationMin(todayPrimary) != null}· <span class="mono">{fmtHrMin(durationMin(todayPrimary))}</span>{/if}
        </p>
      {:else}
        <h2 class="today-title">No training yet</h2>
        <p class="today-meta">Pick exercises from your library or create new ones.</p>
      {/if}
    </div>
    <div class="today-right">
      {#if todayState === "in_progress" && todayPrimary}
        <button class="big primary" onclick={() => openSession(todayPrimary!)}>
          Continue training
        </button>
      {:else if todayState === "completed" && todayPrimary}
        <button class="ghost" onclick={() => openSession(todayPrimary!)}>Review →</button>
        <button class="primary" onclick={() => app.goto("build")}>+ New training</button>
      {:else}
        <button class="big primary" onclick={() => app.goto("build")}>Build training</button>
      {/if}
    </div>
  </section>

  <!-- Admin grid: sessions left, weekly rhythm + library + tools right -->
  <div class="dash-grid">
    <section class="panel sessions-panel">
      <header class="panel-head">
        <h3 class="panel-title">Recent sessions</h3>
        <span class="panel-meta mono">{sessions.length} total</span>
      </header>
      {#if recent.length === 0}
        <div class="empty-state">
          <p class="text-secondary">No sessions yet. Your first training will show up here.</p>
        </div>
      {:else}
        <ul class="session-table">
          {#each recent as s (s.id)}
            <li class="session-row">
              <button class="session-btn" onclick={() => openSession(s)}>
                <div class="sr-date">
                  <span class="sr-date-main mono">{shortDate(s.date)}</span>
                  <span class="sr-date-rel">{relDate(s.date)}</span>
                </div>
                <div class="sr-info">
                  <span class="sr-title">{s.focus ?? s.type}</span>
                  <span class="sr-meta">
                    <span class="mono">{s.exerciseBlocks.length}</span> ex ·
                    <span class="mono">{s.recordings.length}</span> takes
                    {#if durationMin(s) != null}· <span class="mono">{fmtHrMin(durationMin(s))}</span>{/if}
                  </span>
                </div>
                <div class="sr-status">
                  {#if s.status === "in_progress"}
                    <span class="pill pill-primary">In progress</span>
                  {:else if s.status === "completed"}
                    <span class="pill pill-sage">Completed</span>
                  {:else}
                    <span class="pill pill-outline">{s.status}</span>
                  {/if}
                </div>
              </button>
              <button
                class="sr-delete"
                aria-label="Delete session"
                title="Delete this session record"
                onclick={(e) => handleDelete(e, s)}
              >×</button>
            </li>
          {/each}
        </ul>
      {/if}
    </section>

    <aside class="dash-side">
      <!-- Weekly rhythm -->
      <section class="panel">
        <header class="panel-head">
          <h3 class="panel-title">This week</h3>
          <span class="panel-meta mono">{weekTrainings}/7</span>
        </header>
        <div class="rhythm-strip">
          {#each weekDays as d}
            <div
              class="day"
              class:trained={d.trainedSessions.length > 0}
              class:today={d.isToday}
              class:future={d.isFuture}
              title={d.iso}
            >
              <span class="day-dot"></span>
              <span class="day-label">{d.narrow}</span>
            </div>
          {/each}
        </div>
        <dl class="week-stats">
          <div class="wstat">
            <dt class="wstat-lab">time</dt>
            <dd class="wstat-num mono">{fmtHrMin(weekMinutes)}</dd>
          </div>
          <div class="wstat">
            <dt class="wstat-lab">takes</dt>
            <dd class="wstat-num mono">{weekTakes}</dd>
          </div>
          <div class="wstat">
            <dt class="wstat-lab">trained</dt>
            <dd class="wstat-num mono">{weekTrainings}</dd>
          </div>
        </dl>
      </section>

      <!-- Library summary -->
      <section class="panel">
        <header class="panel-head">
          <h3 class="panel-title">Exercise library</h3>
        </header>
        <div class="lib-stats">
          <div class="lib-stat">
            <span class="lib-num mono">{canonicalCount}</span>
            <span class="lib-lab">canonical</span>
          </div>
          <div class="lib-stat evaluate" class:has-evaluate={evaluateCount > 0}>
            <span class="lib-num mono">{evaluateCount}</span>
            <span class="lib-lab">in evaluate</span>
          </div>
        </div>
        <button class="row-link" onclick={() => app.goto("library")}>
          <span>Manage library</span>
          <span class="chev">›</span>
        </button>
      </section>

      <!-- Tools -->
      <section class="panel">
        <header class="panel-head">
          <h3 class="panel-title">Tools</h3>
        </header>
        <ul class="tools-list">
          <li>
            <button class="row-link" onclick={() => app.goto("build")}>
              <span>Build training</span>
              <span class="chev">›</span>
            </button>
          </li>
          <li>
            <button class="row-link" onclick={() => app.goto("settings")}>
              <span>Recording setup</span>
              <span class="row-side">
                <span class="mini-pill" data-state={app.isRecordingReady ? "ok" : "off"}>
                  {app.isRecordingReady ? "ready" : "setup"}
                </span>
                <span class="chev">›</span>
              </span>
            </button>
          </li>
        </ul>
      </section>
    </aside>
  </div>
</div>

<style>
  .dashboard {
    width: 100%;
    max-width: 1200px;
    margin: 0 auto;
    padding: 24px 24px 64px;
    display: flex;
    flex-direction: column;
    gap: 20px;
    animation: fade-rise var(--motion-settled) var(--easing-settled) both;
  }

  /* ─ Header: greeting + status chips ─────────────────────────────── */
  .dash-header {
    display: grid;
    grid-template-columns: 1fr auto;
    gap: 18px;
    align-items: end;
  }
  @media (max-width: 720px) {
    .dash-header { grid-template-columns: 1fr; }
  }
  .greeting-block { display: flex; flex-direction: column; gap: 6px; min-width: 0; }
  .display-greeting {
    font-family: var(--font-display);
    font-weight: 700;
    font-size: 40px;
    letter-spacing: -0.5px;
    line-height: 1.05;
    margin: 0;
  }
  .subtitle {
    font-size: 14px;
    color: var(--text-secondary);
    margin: 0;
  }
  .status-row {
    display: flex;
    gap: 8px;
    flex-wrap: wrap;
  }
  .status-chip {
    display: inline-flex;
    align-items: center;
    padding: 5px 12px 5px 10px;
    border: 1px solid var(--border);
    border-radius: var(--radius-pill);
    background: var(--surface);
    font-family: var(--font-mono);
    font-size: 11px;
    letter-spacing: 0.02em;
    color: var(--text-secondary);
    white-space: nowrap;
    line-height: 1.3;
  }
  .status-chip::before {
    content: "";
    display: inline-block;
    width: 7px;
    height: 7px;
    margin-right: 8px;
    border-radius: 50%;
    background: var(--border);
    flex-shrink: 0;
    vertical-align: middle;
  }
  .status-chip[data-state="ok"] { color: var(--sage); }
  .status-chip[data-state="ok"]::before { background: var(--sage); }
  .status-chip[data-state="off"] { color: var(--text-secondary); }

  /* ─ Daily routine card (Sage = body-listening, not CTA terracotta) ─ */
  .daily-routine {
    display: grid;
    grid-template-columns: 1fr auto;
    gap: 20px;
    align-items: center;
    padding: 18px 22px;
    background: rgba(122, 155, 118, 0.08); /* var(--sage) at 8% */
    border: 1px solid rgba(122, 155, 118, 0.25);
    border-radius: var(--radius-card);
    border-left: 4px solid var(--sage);
  }
  .daily-routine[data-state="in_progress"] {
    background: rgba(122, 155, 118, 0.14);
  }
  .daily-routine[data-state="completed"] {
    opacity: 0.7;
  }
  @media (max-width: 720px) {
    .daily-routine { grid-template-columns: 1fr; }
    .dr-right { justify-content: flex-start; }
  }
  .dr-left { display: flex; flex-direction: column; gap: 6px; min-width: 0; }
  .dr-title {
    font-family: var(--font-display);
    font-weight: 700;
    font-size: 22px;
    letter-spacing: -0.2px;
    line-height: 1.15;
    margin: 0;
    color: var(--text);
  }
  .dr-meta {
    font-size: 13px;
    color: var(--text-secondary);
    margin: 0;
  }
  .dr-right {
    display: flex;
    gap: 10px;
    justify-content: flex-end;
  }
  .big.sage {
    /* mirrors brand button recipe but with sage tint instead of terracotta */
    appearance: none;
    border: none;
    cursor: pointer;
    padding: 14px 22px;
    min-height: 48px;
    border-radius: var(--radius-pill);
    background: var(--sage);
    color: white;
    font-family: var(--font-body);
    font-weight: 600;
    font-size: 15px;
    letter-spacing: 0.01em;
    transition: transform var(--motion-standard) var(--easing-settled),
                background var(--motion-standard) var(--easing-settled);
  }
  .big.sage:hover { background: #6c8b69; }
  .big.sage:active { transform: scale(0.98); }

  /* ─ Today hero ───────────────────────────────────────────────────── */
  .today {
    display: grid;
    grid-template-columns: 1fr auto;
    gap: 20px;
    align-items: center;
    padding: 20px 22px;
    background: var(--surface);
    border: 1px solid var(--border);
    border-radius: var(--radius-card);
    border-left: 4px solid var(--border);
    transition: border-color var(--motion-standard) var(--easing-settled);
  }
  .today[data-state="in_progress"] { border-left-color: var(--primary); }
  .today[data-state="completed"]   { border-left-color: var(--sage); }
  .today[data-state="idle"]        { border-left-color: var(--border); }
  @media (max-width: 720px) {
    .today { grid-template-columns: 1fr; }
    .today-right { justify-content: flex-start; }
  }

  .today-left { display: flex; flex-direction: column; gap: 6px; min-width: 0; }
  .today-title {
    font-family: var(--font-display);
    font-weight: 700;
    font-size: 26px;
    letter-spacing: -0.2px;
    line-height: 1.15;
    margin: 0;
    color: var(--text);
  }
  .today-meta {
    font-size: 13px;
    color: var(--text-secondary);
    margin: 0;
  }
  .today-right {
    display: flex;
    gap: 10px;
    justify-content: flex-end;
    flex-wrap: wrap;
  }

  .mono { font-family: var(--font-mono); font-variant-numeric: tabular-nums; }

  /* ─ Admin grid ───────────────────────────────────────────────────── */
  .dash-grid {
    display: grid;
    grid-template-columns: minmax(0, 1.6fr) minmax(280px, 1fr);
    gap: 16px;
    align-items: start;
  }
  @media (max-width: 900px) {
    .dash-grid { grid-template-columns: 1fr; }
  }

  .panel {
    background: var(--surface);
    border: 1px solid var(--border);
    border-radius: var(--radius-card);
    padding: 14px 16px 16px;
    display: flex;
    flex-direction: column;
    gap: 12px;
  }
  .panel-head {
    display: flex;
    justify-content: space-between;
    align-items: baseline;
  }
  .panel-title {
    font-family: var(--font-body);
    font-weight: 700;
    font-size: 11px;
    letter-spacing: 0.09em;
    text-transform: uppercase;
    color: var(--text-secondary);
    margin: 0;
  }
  .panel-meta {
    font-size: 11px;
    color: var(--text-secondary);
  }

  .label-xs {
    font-family: var(--font-body);
    font-weight: 700;
    font-size: 10px;
    letter-spacing: 0.12em;
    text-transform: uppercase;
    color: var(--text-secondary);
    margin: 0;
  }

  .empty-state {
    padding: 24px 12px;
    text-align: center;
    font-size: 13px;
  }

  /* ─ Sessions table ───────────────────────────────────────────────── */
  .session-table {
    list-style: none;
    padding: 0;
    margin: 0;
    display: flex;
    flex-direction: column;
  }
  .session-row {
    border-bottom: 1px solid var(--border);
    display: grid;
    grid-template-columns: 1fr auto;
    align-items: center;
  }
  .session-row:last-child { border-bottom: none; }
  .session-row:hover .sr-delete { opacity: 1; }
  .session-btn {
    display: grid;
    grid-template-columns: 96px 1fr auto;
    gap: 14px;
    align-items: center;
    width: 100%;
    padding: 10px 6px;
    background: transparent;
    border: none;
    text-align: left;
    cursor: pointer;
    transition: background var(--motion-standard) var(--easing-settled);
    border-radius: 8px;
  }
  .session-btn:hover { background: var(--surface-raised); }

  .sr-delete {
    opacity: 0;
    width: 28px;
    height: 28px;
    margin: 0 6px 0 4px;
    padding: 0;
    border-radius: 50%;
    border: 1px solid transparent;
    background: transparent;
    color: var(--text-secondary);
    font-size: 16px;
    line-height: 1;
    cursor: pointer;
    transition:
      opacity var(--motion-standard) var(--easing-settled),
      color var(--motion-standard) var(--easing-settled),
      border-color var(--motion-standard) var(--easing-settled),
      background var(--motion-standard) var(--easing-settled);
    flex-shrink: 0;
  }
  .sr-delete:focus { opacity: 1; outline: none; border-color: var(--border); }
  .sr-delete:hover {
    color: var(--error);
    border-color: var(--error);
    background: rgba(190, 74, 58, 0.06);
  }
  .sr-date { display: flex; flex-direction: column; gap: 2px; }
  .sr-date-main { font-size: 14px; font-weight: 600; color: var(--text); letter-spacing: 0.02em; }
  .sr-date-rel {
    font-size: 10px;
    letter-spacing: 0.08em;
    text-transform: uppercase;
    color: var(--text-secondary);
  }
  .sr-info { display: flex; flex-direction: column; gap: 2px; min-width: 0; }
  .sr-title {
    font-size: 14px;
    font-weight: 600;
    color: var(--text);
    overflow: hidden;
    text-overflow: ellipsis;
    white-space: nowrap;
  }
  .sr-meta {
    font-size: 12px;
    color: var(--text-secondary);
  }
  .sr-status { flex-shrink: 0; }

  /* ─ Rhythm strip ─────────────────────────────────────────────────── */
  .rhythm-strip {
    display: grid;
    grid-template-columns: repeat(7, 1fr);
    gap: 4px;
  }
  .day {
    display: flex;
    flex-direction: column;
    align-items: center;
    gap: 6px;
    padding: 8px 0 6px;
    border-radius: 10px;
  }
  .day.today {
    background: var(--surface-raised);
  }
  .day-dot {
    width: 12px; height: 12px;
    border-radius: 50%;
    background: transparent;
    border: 1.5px solid var(--border);
  }
  .day.trained .day-dot {
    background: var(--sage);
    border-color: var(--sage);
  }
  .day.today .day-dot {
    box-shadow: 0 0 0 3px rgba(122, 155, 118, 0.18);
  }
  .day.today.trained .day-dot {
    animation: breath var(--motion-breath) ease-in-out infinite;
  }
  .day.future .day-dot {
    border-style: dashed;
    opacity: 0.55;
  }
  .day-label {
    font-family: var(--font-mono);
    font-size: 10px;
    color: var(--text-secondary);
    letter-spacing: 0.02em;
  }
  .day.today .day-label { color: var(--text); font-weight: 600; }

  .week-stats {
    display: grid;
    grid-template-columns: repeat(3, 1fr);
    gap: 8px;
    margin: 4px 0 0;
    padding: 10px 2px 2px;
    border-top: 1px dashed var(--border);
  }
  .wstat { display: flex; flex-direction: column; align-items: center; gap: 2px; }
  .wstat-lab {
    font-family: var(--font-body);
    font-size: 10px;
    letter-spacing: 0.08em;
    text-transform: uppercase;
    color: var(--text-secondary);
  }
  .wstat-num {
    font-family: var(--font-mono);
    font-size: 20px;
    font-weight: 600;
    color: var(--text);
    line-height: 1;
  }

  /* ─ Library summary ──────────────────────────────────────────────── */
  .lib-stats {
    display: grid;
    grid-template-columns: 1fr 1fr;
    gap: 10px;
  }
  .lib-stat {
    display: flex;
    flex-direction: column;
    align-items: flex-start;
    gap: 2px;
    padding: 10px 12px;
    background: var(--surface-raised);
    border-radius: var(--radius-input);
  }
  .lib-stat.evaluate { background: transparent; border: 1px dashed var(--border); }
  .lib-stat.evaluate.has-evaluate { border-color: var(--reward); }
  .lib-stat.evaluate.has-evaluate .lib-num { color: var(--soft-gold-ink); }
  .lib-num {
    font-size: 22px;
    font-weight: 600;
    color: var(--text);
    line-height: 1;
  }
  .lib-lab {
    font-size: 10px;
    letter-spacing: 0.08em;
    text-transform: uppercase;
    color: var(--text-secondary);
  }

  /* ─ Shared row link (tools + manage) ─────────────────────────────── */
  .row-link {
    display: flex;
    align-items: center;
    justify-content: space-between;
    gap: 8px;
    width: 100%;
    padding: 10px 12px;
    background: transparent;
    border: 1px solid var(--border);
    border-radius: var(--radius-input);
    font-family: var(--font-body);
    font-size: 13px;
    font-weight: 600;
    color: var(--text);
    cursor: pointer;
    transition: background var(--motion-standard) var(--easing-settled);
  }
  .row-link:hover { background: var(--surface-raised); }
  .chev {
    color: var(--text-secondary);
    font-size: 18px;
    line-height: 1;
  }
  .row-side {
    display: inline-flex;
    align-items: center;
    gap: 8px;
  }
  .mini-pill {
    font-family: var(--font-mono);
    font-size: 10px;
    padding: 1px 8px;
    border-radius: var(--radius-pill);
    border: 1px solid var(--border);
    color: var(--text-secondary);
    letter-spacing: 0.04em;
  }
  .mini-pill[data-state="ok"] {
    color: var(--sage);
    border-color: var(--sage);
  }

  .tools-list {
    list-style: none;
    padding: 0;
    margin: 0;
    display: flex;
    flex-direction: column;
    gap: 6px;
  }

  .dash-side { display: flex; flex-direction: column; gap: 12px; }
</style>
