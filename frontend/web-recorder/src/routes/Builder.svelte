<script lang="ts">
  import { app } from "../stores/app.svelte.ts";
  import { newId, upsertSession } from "../lib/sessionStore";
  import {
    ensureSeeded,
    canonicalExercises,
    evaluateBucket,
    createEvaluatedExercise,
  } from "../lib/exerciseStore";
  import type { Exercise, ExerciseBlock, Session, EffortKind } from "../lib/types";

  let library = $state<Exercise[]>(ensureSeeded());
  const canonical = $derived(canonicalExercises(library));
  const evaluating = $derived(evaluateBucket(library));

  let focus = $state("");
  let query = $state("");

  // Selected exercises, in session order. Each carries per-session overrides
  // on top of the source exercise's defaults.
  interface SelectedBlock {
    id: string;                  // block id for the upcoming session
    exerciseId: string;
    exerciseName: string;
    effortKind: EffortKind;
    sets: number;
    reps: number;
    seconds?: number;
    weight?: number;
    restSeconds: number;
  }
  let selected = $state<SelectedBlock[]>([]);

  const addExercise = (ex: Exercise) => {
    selected = [
      ...selected,
      {
        id: newId(),
        exerciseId: ex.id,
        exerciseName: ex.name,
        effortKind: ex.defaultEffortKind,
        sets: ex.defaultSets ?? 3,
        reps: ex.defaultReps ?? 8,
        seconds: ex.defaultSeconds,
        weight: ex.defaultWeight,
        restSeconds: ex.defaultRestSeconds ?? 60,
      },
    ];
  };

  const removeAt = (i: number) => {
    selected = selected.filter((_, idx) => idx !== i);
  };

  const moveUp = (i: number) => {
    if (i === 0) return;
    const copy = [...selected];
    [copy[i - 1], copy[i]] = [copy[i], copy[i - 1]];
    selected = copy;
  };

  const moveDown = (i: number) => {
    if (i === selected.length - 1) return;
    const copy = [...selected];
    [copy[i], copy[i + 1]] = [copy[i + 1], copy[i]];
    selected = copy;
  };

  // Filter match: case-insensitive substring over all library entries.
  const filtered = $derived.by(() => {
    const q = query.trim().toLowerCase();
    if (!q) return library.slice().sort((a, b) => a.name.localeCompare(b.name));
    return library
      .filter((e) => e.name.toLowerCase().includes(q))
      .sort((a, b) => a.name.localeCompare(b.name));
  });

  // -- inline "create new exercise" form
  let creating = $state(false);
  let newName = $state("");
  let newKind = $state<EffortKind>("reps");
  let newReps = $state<number | "">(8);
  let newSeconds = $state<number | "">(30);
  let newWeight = $state<number | "">("");
  let newSets = $state<number | "">(3);
  let newRest = $state<number | "">(60);

  const openCreate = () => {
    creating = true;
    // Pre-fill the name from the current query if any — fast path.
    newName = query.trim();
  };

  const cancelCreate = () => {
    creating = false;
    newName = "";
  };

  const submitCreate = () => {
    const name = newName.trim();
    if (!name) return;
    const created = createEvaluatedExercise({
      name,
      defaultEffortKind: newKind,
      defaultReps: newKind === "reps" && newReps !== "" ? Number(newReps) : undefined,
      defaultSeconds: newKind === "time" && newSeconds !== "" ? Number(newSeconds) : undefined,
      defaultWeight: newWeight === "" ? undefined : Number(newWeight),
      defaultSets: newSets === "" ? undefined : Number(newSets),
      defaultRestSeconds: newRest === "" ? undefined : Number(newRest),
    });
    library = [...library, created];
    addExercise(created);
    // Reset the form for the next inline create.
    creating = false;
    newName = "";
    query = "";
  };

  const startTraining = () => {
    if (selected.length === 0) return;
    const today = new Date().toISOString().slice(0, 10);
    const sessionId = newId();
    const session: Session = {
      id: sessionId,
      userId: "marco",
      type: "training",
      focus: focus.trim() || undefined,
      date: today,
      status: "in_progress",
      exerciseBlocks: selected.map<ExerciseBlock>((s) => ({
        id: s.id,
        exerciseId: s.exerciseId,
        exerciseName: s.exerciseName,
        plannedSets: s.sets,
        plannedReps: s.reps,
        plannedSeconds: s.effortKind === "time" ? s.seconds : undefined,
        defaultEffortKind: s.effortKind,
        plannedWeight: s.weight,
        restSeconds: s.restSeconds,
        actualSets: [],
      })),
      recordings: [],
      source: "in-app-recorder",
      idempotencyKey: sessionId,
      startedAt: new Date().toISOString(),
    };
    upsertSession(session);
    (app as any).activeSessionId = sessionId;
    app.goto("active");
  };
</script>

<div class="page">
  <header class="page-header">
    <button class="ghost icon" onclick={() => app.goto("sessions")} aria-label="Cancel">×</button>
    <h1>Build training</h1>
    <p class="text-secondary lede">
      Pick exercises from the library, create new ones inline, and set your targets.
      New exercises land in the <strong>evaluate</strong> bucket — an AI pass later promotes them to the canonical library.
    </p>
  </header>

  <section class="section">
    <div class="section-head">
      <h3>Session focus</h3>
    </div>
    <input
      class="focus-input"
      type="text"
      bind:value={focus}
      placeholder="e.g. Lower body · pull day · mobility"
    />
  </section>

  <section class="section">
    <div class="section-head">
      <h3>Your session</h3>
      <span class="count">{selected.length} exercise{selected.length === 1 ? "" : "s"}</span>
    </div>

    {#if selected.length === 0}
      <div class="empty">
        <p class="text-secondary">No exercises yet — pick or create one below.</p>
      </div>
    {:else}
      <ul class="selected-list">
        {#each selected as b, i (b.id)}
          <li class="selected-row">
            <div class="sel-head">
              <span class="sel-idx">{i + 1}</span>
              <span class="sel-name">{b.exerciseName}</span>
              <span class="sel-kind-pill">{b.effortKind}</span>
              <div class="sel-actions">
                <button class="ghost icon-sm" onclick={() => moveUp(i)} disabled={i === 0} aria-label="Move up">↑</button>
                <button class="ghost icon-sm" onclick={() => moveDown(i)} disabled={i === selected.length - 1} aria-label="Move down">↓</button>
                <button class="ghost icon-sm danger" onclick={() => removeAt(i)} aria-label="Remove">×</button>
              </div>
            </div>
            <div class="sel-fields">
              <label>
                <span class="field-label">Sets</span>
                <input type="number" min="1" bind:value={selected[i].sets} />
              </label>
              {#if b.effortKind === "reps"}
                <label>
                  <span class="field-label">Reps</span>
                  <input type="number" min="1" bind:value={selected[i].reps} />
                </label>
              {:else}
                <label>
                  <span class="field-label">Seconds</span>
                  <input type="number" min="1" bind:value={selected[i].seconds} />
                </label>
              {/if}
              <label>
                <span class="field-label">Weight (kg)</span>
                <input type="number" min="0" step="0.5" bind:value={selected[i].weight} />
              </label>
              <label>
                <span class="field-label">Rest (s)</span>
                <input type="number" min="0" bind:value={selected[i].restSeconds} />
              </label>
              <label class="kind-field">
                <span class="field-label">Type</span>
                <div class="kind-toggle">
                  <button type="button" class:active={b.effortKind === "reps"} onclick={() => (selected[i].effortKind = "reps")}>Reps</button>
                  <button type="button" class:active={b.effortKind === "time"} onclick={() => (selected[i].effortKind = "time")}>Time</button>
                </div>
              </label>
            </div>
          </li>
        {/each}
      </ul>
    {/if}
  </section>

  <section class="section">
    <div class="section-head">
      <h3>Add an exercise</h3>
      <span class="text-secondary count">{canonical.length} canonical · {evaluating.length} to evaluate</span>
    </div>
    <input
      class="search-input"
      type="text"
      bind:value={query}
      placeholder="Search by name — or type a brand-new exercise and create it"
    />

    <ul class="library-list">
      {#each filtered as ex (ex.id)}
        <li class="library-row">
          <div class="lib-text">
            <span class="lib-name">{ex.name}</span>
            {#if ex.source === "user-created"}
              <span class="pill pill-outline evaluate-pill" title="Pending AI evaluation">evaluate</span>
            {/if}
            <span class="lib-meta text-secondary">
              {#if ex.defaultEffortKind === "time"}
                {ex.defaultSeconds ?? "—"}s
              {:else}
                {ex.defaultReps ?? "—"} reps
              {/if}
              · {ex.defaultSets ?? "?"} sets · {ex.defaultRestSeconds ?? "?"}s rest
            </span>
          </div>
          <button class="primary compact" onclick={() => addExercise(ex)}>+ Add</button>
        </li>
      {/each}
      {#if filtered.length === 0}
        <li class="library-empty text-secondary">
          No matches for "{query}". Create it →
        </li>
      {/if}
    </ul>

    {#if !creating}
      <button class="ghost create-btn" onclick={openCreate}>
        + Create new exercise{query.trim() ? ` "${query.trim()}"` : ""}
      </button>
    {:else}
      <div class="create-card">
        <div class="create-head">
          <h4>New exercise</h4>
          <span class="text-secondary small-label">goes to "evaluate" bucket</span>
        </div>
        <div class="create-fields">
          <label class="full">
            <span class="field-label">Name</span>
            <input type="text" bind:value={newName} placeholder="e.g. Paused Front Squat" />
          </label>
          <label class="kind-field full">
            <span class="field-label">Type</span>
            <div class="kind-toggle">
              <button type="button" class:active={newKind === "reps"} onclick={() => (newKind = "reps")}>Reps</button>
              <button type="button" class:active={newKind === "time"} onclick={() => (newKind = "time")}>Time</button>
            </div>
          </label>
          {#if newKind === "reps"}
            <label>
              <span class="field-label">Default reps</span>
              <input type="number" min="1" bind:value={newReps} />
            </label>
          {:else}
            <label>
              <span class="field-label">Default seconds</span>
              <input type="number" min="1" bind:value={newSeconds} />
            </label>
          {/if}
          <label>
            <span class="field-label">Default weight (kg)</span>
            <input type="number" min="0" step="0.5" bind:value={newWeight} />
          </label>
          <label>
            <span class="field-label">Default sets</span>
            <input type="number" min="1" bind:value={newSets} />
          </label>
          <label>
            <span class="field-label">Default rest (s)</span>
            <input type="number" min="0" bind:value={newRest} />
          </label>
        </div>
        <div class="create-actions">
          <button class="ghost" onclick={cancelCreate}>Cancel</button>
          <button class="primary" onclick={submitCreate} disabled={!newName.trim()}>Create & add</button>
        </div>
      </div>
    {/if}
  </section>

  <footer class="sticky-cta">
    <button
      class="big primary"
      onclick={startTraining}
      disabled={selected.length === 0}
    >
      Start training ({selected.length} exercise{selected.length === 1 ? "" : "s"})
    </button>
  </footer>
</div>

<style>
  .page {
    max-width: 900px;
    width: 100%;
    margin: 0 auto;
    padding: 24px 24px 120px;
    display: flex;
    flex-direction: column;
    gap: 22px;
    animation: fade-rise var(--motion-settled) var(--easing-settled) both;
  }
  .page-header { display: flex; flex-direction: column; gap: 10px; position: relative; }
  .page-header .ghost.icon {
    position: absolute; top: 0; right: 0;
    width: 40px; height: 40px; padding: 0;
    border-radius: 50%;
    font-size: 22px; line-height: 1;
  }
  .page-header h1 { font-size: 36px; letter-spacing: -0.4px; }
  .lede { font-size: 14px; max-width: 640px; }

  .section { display: flex; flex-direction: column; gap: 10px; }
  .section-head {
    display: flex; justify-content: space-between; align-items: baseline;
    padding: 0 2px;
  }
  .section-head h3 { font-size: 14px; font-weight: 700; letter-spacing: 0.04em; text-transform: uppercase; color: var(--text-secondary); }
  .count { font-family: var(--font-mono); font-size: 12px; color: var(--text-secondary); }

  .focus-input, .search-input {
    width: 100%;
    padding: 12px 14px;
    font-size: 15px;
    background: var(--surface);
    border: 1px solid var(--border);
    border-radius: var(--radius-input);
    font-family: var(--font-body);
  }

  /* Selected list */
  .empty {
    padding: 20px;
    text-align: center;
    border: 1px dashed var(--border);
    border-radius: var(--radius-card);
    background: var(--surface);
  }
  .selected-list { list-style: none; margin: 0; padding: 0; display: flex; flex-direction: column; gap: 10px; }
  .selected-row {
    padding: 14px;
    background: var(--surface);
    border: 1px solid var(--border);
    border-radius: var(--radius-card);
    display: flex;
    flex-direction: column;
    gap: 10px;
  }
  .sel-head {
    display: grid;
    grid-template-columns: auto 1fr auto auto;
    align-items: center;
    gap: 10px;
  }
  .sel-idx {
    width: 28px; height: 28px;
    border-radius: 50%;
    background: var(--primary);
    color: #F5EFE7;
    font-family: var(--font-mono);
    font-size: 13px;
    font-weight: 600;
    display: inline-flex; align-items: center; justify-content: center;
  }
  .sel-name { font-size: 15px; font-weight: 600; }
  .sel-kind-pill {
    font-family: var(--font-mono);
    font-size: 10px;
    letter-spacing: 0.08em;
    text-transform: uppercase;
    padding: 2px 8px;
    border: 1px solid var(--border);
    border-radius: 999px;
    color: var(--text-secondary);
  }
  .sel-actions { display: flex; gap: 4px; }
  .icon-sm {
    width: 28px; height: 28px; padding: 0;
    border-radius: 50%;
    font-size: 14px; line-height: 1;
  }
  .icon-sm.danger:hover { color: var(--error); border-color: var(--error); }
  .sel-fields {
    display: grid;
    grid-template-columns: repeat(5, minmax(0, 1fr));
    gap: 10px;
  }
  @media (max-width: 720px) {
    .sel-fields { grid-template-columns: repeat(2, 1fr); }
  }
  .sel-fields label { display: flex; flex-direction: column; gap: 4px; min-width: 0; }
  .field-label {
    font-size: 10px;
    font-weight: 600;
    letter-spacing: 0.08em;
    text-transform: uppercase;
    color: var(--text-secondary);
  }
  .sel-fields input {
    width: 100%;
    padding: 8px 10px;
    background: var(--surface-raised);
    border: 1px solid var(--border);
    border-radius: var(--radius-input);
    font-family: var(--font-mono);
    font-variant-numeric: tabular-nums;
    min-width: 0;
  }

  .kind-field { grid-column: span 1; }
  .kind-toggle {
    display: inline-flex;
    border: 1px solid var(--border);
    border-radius: 999px;
    padding: 2px;
    background: var(--surface-raised);
    width: fit-content;
  }
  .kind-toggle button {
    padding: 4px 12px;
    border-radius: 999px;
    border: none;
    background: transparent;
    color: var(--text-secondary);
    font-family: var(--font-body);
    font-size: 12px;
    font-weight: 600;
    letter-spacing: 0.04em;
    cursor: pointer;
  }
  .kind-toggle button.active {
    background: var(--primary);
    color: #F5EFE7;
  }

  /* Library list */
  .library-list {
    list-style: none; margin: 0; padding: 0;
    display: flex; flex-direction: column;
    background: var(--surface);
    border: 1px solid var(--border);
    border-radius: var(--radius-card);
    max-height: 360px;
    overflow-y: auto;
  }
  .library-row {
    display: flex; align-items: center; justify-content: space-between;
    gap: 12px;
    padding: 10px 14px;
    border-bottom: 1px solid var(--border);
  }
  .library-row:last-child { border-bottom: none; }
  .lib-text { display: flex; align-items: center; gap: 10px; flex-wrap: wrap; min-width: 0; }
  .lib-name { font-size: 14px; font-weight: 600; }
  .lib-meta { font-family: var(--font-mono); font-size: 11px; }
  .evaluate-pill {
    font-size: 10px;
    padding: 1px 8px;
    letter-spacing: 0.06em;
  }
  .library-empty { padding: 16px; text-align: center; font-size: 13px; }
  .primary.compact {
    padding: 6px 12px;
    font-size: 12px;
  }

  .create-btn { align-self: flex-start; }
  .create-card {
    background: var(--surface);
    border: 1.5px dashed var(--primary);
    border-radius: var(--radius-card);
    padding: 16px;
    display: flex; flex-direction: column; gap: 12px;
  }
  .create-head {
    display: flex; justify-content: space-between; align-items: baseline;
  }
  .create-head h4 { font-size: 16px; font-weight: 700; margin: 0; }
  .small-label {
    font-size: 10px;
    letter-spacing: 0.08em;
    text-transform: uppercase;
  }
  .create-fields {
    display: grid;
    grid-template-columns: repeat(3, minmax(0, 1fr));
    gap: 10px;
  }
  .create-fields label { display: flex; flex-direction: column; gap: 4px; min-width: 0; }
  .create-fields label.full { grid-column: 1 / -1; }
  .create-fields input[type="text"],
  .create-fields input[type="number"] {
    width: 100%;
    padding: 8px 10px;
    background: var(--surface-raised);
    border: 1px solid var(--border);
    border-radius: var(--radius-input);
    font-family: var(--font-body);
  }
  .create-fields input[type="number"] { font-family: var(--font-mono); font-variant-numeric: tabular-nums; }
  .create-actions {
    display: flex; justify-content: flex-end; gap: 10px;
    padding-top: 4px;
    border-top: 1px dashed var(--border);
  }
  @media (max-width: 720px) {
    .create-fields { grid-template-columns: repeat(2, 1fr); }
  }

  .sticky-cta {
    position: sticky;
    bottom: 16px;
    background: var(--surface);
    border: 1px solid var(--border);
    padding: 14px;
    border-radius: var(--radius-card);
    box-shadow: 0 8px 32px rgba(0,0,0,0.1);
    display: flex;
    justify-content: center;
  }
  .sticky-cta .big.primary { min-width: 260px; }
</style>
