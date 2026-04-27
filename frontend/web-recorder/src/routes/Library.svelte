<script lang="ts">
  import { app } from "../stores/app.svelte.ts";
  import {
    ensureSeeded,
    upsertExercise,
    createEvaluatedExercise,
    deleteExercise,
    canonicalExercises,
    evaluateBucket,
  } from "../lib/exerciseStore";
  import type { Exercise, EffortKind } from "../lib/types";

  type Filter = "all" | "canonical" | "evaluate";

  let library = $state<Exercise[]>(ensureSeeded());
  let filter = $state<Filter>("all");
  let query = $state("");
  let editingId = $state<string | null>(null);
  let creating = $state(false);

  // "Draft" for the currently-editing exercise — only committed on Save.
  let draft = $state<Partial<Exercise>>({});

  const canonical = $derived(canonicalExercises(library));
  const evaluating = $derived(evaluateBucket(library));

  const visible = $derived.by(() => {
    const q = query.trim().toLowerCase();
    let list = library;
    if (filter === "canonical") list = canonicalExercises(library);
    else if (filter === "evaluate") list = evaluateBucket(library);
    if (q) list = list.filter((e) => e.name.toLowerCase().includes(q));
    return list.slice().sort((a, b) => a.name.localeCompare(b.name));
  });

  const startEdit = (ex: Exercise) => {
    editingId = ex.id;
    creating = false;
    draft = { ...ex };
  };

  const cancelEdit = () => {
    editingId = null;
    draft = {};
  };

  const saveEdit = () => {
    if (!editingId) return;
    const existing = library.find((e) => e.id === editingId);
    if (!existing) return;
    const updated: Exercise = {
      ...existing,
      ...draft,
      name: (draft.name ?? existing.name).trim() || existing.name,
      defaultEffortKind: (draft.defaultEffortKind ?? existing.defaultEffortKind) as EffortKind,
      defaultReps: normaliseNum(draft.defaultReps),
      defaultSeconds: normaliseNum(draft.defaultSeconds),
      defaultWeight: normaliseNum(draft.defaultWeight),
      defaultSets: normaliseNum(draft.defaultSets),
      defaultRestSeconds: normaliseNum(draft.defaultRestSeconds),
    };
    upsertExercise(updated);
    library = library.map((e) => (e.id === updated.id ? updated : e));
    editingId = null;
    draft = {};
  };

  const normaliseNum = (v: unknown): number | undefined => {
    if (v === "" || v === null || v === undefined) return undefined;
    const n = Number(v);
    return Number.isFinite(n) ? n : undefined;
  };

  const confirmDelete = (ex: Exercise) => {
    if (!window.confirm(`Delete "${ex.name}"? Existing sessions keep their copy — this only removes it from the library.`)) return;
    deleteExercise(ex.id);
    library = library.filter((e) => e.id !== ex.id);
    if (editingId === ex.id) cancelEdit();
  };

  const startCreate = () => {
    creating = true;
    editingId = null;
    draft = {
      name: query.trim(),
      defaultEffortKind: "reps",
      defaultReps: 8,
      defaultSets: 3,
      defaultRestSeconds: 60,
    };
  };

  const cancelCreate = () => { creating = false; draft = {}; };

  const submitCreate = () => {
    const name = (draft.name ?? "").trim();
    if (!name) return;
    const created = createEvaluatedExercise({
      name,
      defaultEffortKind: (draft.defaultEffortKind ?? "reps") as EffortKind,
      defaultReps: draft.defaultEffortKind === "time" ? undefined : normaliseNum(draft.defaultReps),
      defaultSeconds: draft.defaultEffortKind === "time" ? normaliseNum(draft.defaultSeconds) : undefined,
      defaultWeight: normaliseNum(draft.defaultWeight),
      defaultSets: normaliseNum(draft.defaultSets),
      defaultRestSeconds: normaliseNum(draft.defaultRestSeconds),
    });
    library = [...library, created];
    creating = false;
    draft = {};
    query = "";
  };

  const sourceLabel = (ex: Exercise): string => {
    if (ex.source === "seed") return "seed";
    if (ex.source === "promoted") return "canonical";
    if (ex.evaluationStatus === "pending") return "evaluate";
    return ex.evaluationStatus ?? "evaluate";
  };

  const defaultsSummary = (ex: Exercise): string => {
    const effort = ex.defaultEffortKind === "time"
      ? `${ex.defaultSeconds ?? "?"}s`
      : `${ex.defaultReps ?? "?"} reps`;
    const parts = [effort];
    if (ex.defaultWeight != null) parts.push(`${ex.defaultWeight}kg`);
    parts.push(`${ex.defaultSets ?? "?"} sets`);
    parts.push(`${ex.defaultRestSeconds ?? "?"}s rest`);
    return parts.join(" · ");
  };
</script>

<div class="page">
  <header class="page-header">
    <button class="ghost icon" onclick={() => app.goto("sessions")} aria-label="Back">×</button>
    <div class="title-block">
      <span class="pill pill-outline">Library</span>
      <h1>Exercise library</h1>
      <p class="text-secondary lede">
        Canonical exercises + your evaluate bucket. User-created ones stay in "evaluate"
        until an AI pass merges them into the canonical set.
      </p>
    </div>
  </header>

  <div class="toolbar">
    <div class="filters" role="group" aria-label="Filter">
      <button class:active={filter === "all"}        onclick={() => (filter = "all")}>All <span class="count-pill">{library.length}</span></button>
      <button class:active={filter === "canonical"}  onclick={() => (filter = "canonical")}>Canonical <span class="count-pill">{canonical.length}</span></button>
      <button class:active={filter === "evaluate"}   onclick={() => (filter = "evaluate")}>Evaluate <span class="count-pill">{evaluating.length}</span></button>
    </div>
    <input
      class="search-input"
      type="text"
      bind:value={query}
      placeholder="Search by name"
    />
  </div>

  {#if !creating}
    <button class="primary new-btn" onclick={startCreate}>
      + New exercise
    </button>
  {:else}
    <div class="create-card">
      <div class="create-head">
        <h4>New exercise</h4>
        <span class="text-secondary small-label">lands in evaluate bucket</span>
      </div>
      <div class="fields-grid">
        <label class="full">
          <span class="field-label">Name</span>
          <input type="text" bind:value={draft.name} placeholder="e.g. Paused Front Squat" />
        </label>
        <label class="kind-field full">
          <span class="field-label">Type</span>
          <div class="kind-toggle">
            <button type="button" class:active={draft.defaultEffortKind === "reps"} onclick={() => (draft.defaultEffortKind = "reps")}>Reps</button>
            <button type="button" class:active={draft.defaultEffortKind === "time"} onclick={() => (draft.defaultEffortKind = "time")}>Time</button>
          </div>
        </label>
        {#if draft.defaultEffortKind === "time"}
          <label>
            <span class="field-label">Default seconds</span>
            <input type="number" min="1" bind:value={draft.defaultSeconds} />
          </label>
        {:else}
          <label>
            <span class="field-label">Default reps</span>
            <input type="number" min="1" bind:value={draft.defaultReps} />
          </label>
        {/if}
        <label>
          <span class="field-label">Default weight (kg)</span>
          <input type="number" min="0" step="0.5" bind:value={draft.defaultWeight} />
        </label>
        <label>
          <span class="field-label">Default sets</span>
          <input type="number" min="1" bind:value={draft.defaultSets} />
        </label>
        <label>
          <span class="field-label">Default rest (s)</span>
          <input type="number" min="0" bind:value={draft.defaultRestSeconds} />
        </label>
      </div>
      <div class="card-actions">
        <button class="ghost" onclick={cancelCreate}>Cancel</button>
        <button class="primary" onclick={submitCreate} disabled={!(draft.name ?? "").trim()}>Create</button>
      </div>
    </div>
  {/if}

  <ul class="library-list">
    {#each visible as ex (ex.id)}
      <li class="lib-row" data-source={ex.source}>
        {#if editingId === ex.id}
          <div class="edit-block">
            <div class="edit-head">
              <h4>Edit exercise</h4>
              <span class="pill pill-outline small-label" data-source={ex.source}>{sourceLabel(ex)}</span>
            </div>
            <div class="fields-grid">
              <label class="full">
                <span class="field-label">Name</span>
                <input type="text" bind:value={draft.name} />
              </label>
              <label class="kind-field full">
                <span class="field-label">Type</span>
                <div class="kind-toggle">
                  <button type="button" class:active={draft.defaultEffortKind === "reps"} onclick={() => (draft.defaultEffortKind = "reps")}>Reps</button>
                  <button type="button" class:active={draft.defaultEffortKind === "time"} onclick={() => (draft.defaultEffortKind = "time")}>Time</button>
                </div>
              </label>
              {#if draft.defaultEffortKind === "time"}
                <label>
                  <span class="field-label">Default seconds</span>
                  <input type="number" min="1" bind:value={draft.defaultSeconds} />
                </label>
              {:else}
                <label>
                  <span class="field-label">Default reps</span>
                  <input type="number" min="1" bind:value={draft.defaultReps} />
                </label>
              {/if}
              <label>
                <span class="field-label">Default weight (kg)</span>
                <input type="number" min="0" step="0.5" bind:value={draft.defaultWeight} />
              </label>
              <label>
                <span class="field-label">Default sets</span>
                <input type="number" min="1" bind:value={draft.defaultSets} />
              </label>
              <label>
                <span class="field-label">Default rest (s)</span>
                <input type="number" min="0" bind:value={draft.defaultRestSeconds} />
              </label>
            </div>
            <div class="card-actions">
              <button class="ghost danger" onclick={() => confirmDelete(ex)}>Delete</button>
              <div class="spacer"></div>
              <button class="ghost" onclick={cancelEdit}>Cancel</button>
              <button class="primary" onclick={saveEdit}>Save</button>
            </div>
          </div>
        {:else}
          <div class="lib-summary">
            <div class="lib-left">
              <div class="lib-title-row">
                <span class="lib-name">{ex.name}</span>
                <span class="source-pill" data-source={ex.source}>{sourceLabel(ex)}</span>
              </div>
              <div class="lib-meta">{defaultsSummary(ex)}</div>
            </div>
            <div class="lib-right">
              <button class="ghost compact" onclick={() => startEdit(ex)}>Edit</button>
              <button class="ghost compact danger" onclick={() => confirmDelete(ex)} aria-label="Delete">×</button>
            </div>
          </div>
        {/if}
      </li>
    {/each}
    {#if visible.length === 0}
      <li class="lib-empty text-secondary">
        {query
          ? `No exercises match "${query}". Create it above.`
          : filter === "evaluate"
            ? "Evaluate bucket is empty — exercises you create inline land here."
            : "No exercises yet. Create your first one."}
      </li>
    {/if}
  </ul>
</div>

<style>
  .page {
    max-width: 900px;
    width: 100%;
    margin: 0 auto;
    padding: 24px 24px 96px;
    display: flex;
    flex-direction: column;
    gap: 20px;
    animation: fade-rise var(--motion-settled) var(--easing-settled) both;
  }
  .page-header { display: flex; align-items: flex-start; gap: 16px; position: relative; }
  .ghost.icon {
    width: 40px; height: 40px; padding: 0;
    border-radius: 50%;
    font-size: 22px; line-height: 1;
    flex-shrink: 0;
  }
  .title-block { display: flex; flex-direction: column; gap: 8px; flex: 1; min-width: 0; }
  .title-block h1 { font-size: 36px; letter-spacing: -0.4px; margin: 0; }
  .lede { font-size: 14px; max-width: 640px; }

  .toolbar {
    display: grid;
    grid-template-columns: auto 1fr;
    gap: 12px;
    align-items: center;
  }
  @media (max-width: 720px) {
    .toolbar { grid-template-columns: 1fr; }
  }
  .filters {
    display: inline-flex;
    border: 1px solid var(--border);
    border-radius: 999px;
    padding: 3px;
    background: var(--surface);
  }
  .filters button {
    padding: 6px 14px;
    border-radius: 999px;
    border: none;
    background: transparent;
    color: var(--text-secondary);
    font-family: var(--font-body);
    font-size: 12px;
    font-weight: 600;
    letter-spacing: 0.04em;
    text-transform: uppercase;
    cursor: pointer;
    display: inline-flex;
    align-items: center;
    gap: 6px;
  }
  .filters button.active {
    background: var(--primary);
    color: #F5EFE7;
  }
  .count-pill {
    font-family: var(--font-mono);
    font-size: 10px;
    padding: 1px 6px;
    border-radius: 999px;
    background: rgba(0, 0, 0, 0.12);
  }
  .filters button.active .count-pill { background: rgba(255, 255, 255, 0.2); }

  .search-input {
    width: 100%;
    padding: 10px 14px;
    font-size: 14px;
    background: var(--surface);
    border: 1px solid var(--border);
    border-radius: var(--radius-input);
    font-family: var(--font-body);
  }

  .new-btn { align-self: flex-start; }

  .create-card, .edit-block {
    background: var(--surface);
    border: 1.5px dashed var(--primary);
    border-radius: var(--radius-card);
    padding: 16px;
    display: flex;
    flex-direction: column;
    gap: 12px;
  }
  .create-head, .edit-head {
    display: flex; justify-content: space-between; align-items: baseline;
  }
  .create-head h4, .edit-head h4 { font-size: 16px; font-weight: 700; margin: 0; }
  .small-label {
    font-size: 10px;
    letter-spacing: 0.08em;
    text-transform: uppercase;
  }

  .fields-grid {
    display: grid;
    grid-template-columns: repeat(3, minmax(0, 1fr));
    gap: 10px;
  }
  @media (max-width: 720px) {
    .fields-grid { grid-template-columns: repeat(2, 1fr); }
  }
  .fields-grid label { display: flex; flex-direction: column; gap: 4px; min-width: 0; }
  .fields-grid label.full { grid-column: 1 / -1; }
  .field-label {
    font-size: 10px;
    font-weight: 600;
    letter-spacing: 0.08em;
    text-transform: uppercase;
    color: var(--text-secondary);
  }
  .fields-grid input[type="text"],
  .fields-grid input[type="number"] {
    width: 100%;
    padding: 8px 10px;
    background: var(--surface-raised);
    border: 1px solid var(--border);
    border-radius: var(--radius-input);
    font-family: var(--font-body);
  }
  .fields-grid input[type="number"] {
    font-family: var(--font-mono);
    font-variant-numeric: tabular-nums;
  }
  .kind-field .kind-toggle {
    display: inline-flex;
    border: 1px solid var(--border);
    border-radius: 999px;
    padding: 2px;
    background: var(--surface-raised);
    width: fit-content;
  }
  .kind-field .kind-toggle button {
    padding: 4px 14px;
    border-radius: 999px;
    border: none;
    background: transparent;
    color: var(--text-secondary);
    font-family: var(--font-body);
    font-size: 12px;
    font-weight: 600;
    cursor: pointer;
  }
  .kind-field .kind-toggle button.active {
    background: var(--primary);
    color: #F5EFE7;
  }

  .card-actions {
    display: flex;
    gap: 10px;
    align-items: center;
    padding-top: 4px;
    border-top: 1px dashed var(--border);
  }
  .card-actions .spacer { flex: 1; }
  .card-actions .ghost.danger { color: var(--error); }
  .card-actions .ghost.danger:hover { background: rgba(190, 74, 58, 0.08); }

  /* Library list */
  .library-list {
    list-style: none;
    margin: 0;
    padding: 0;
    display: flex;
    flex-direction: column;
    gap: 8px;
  }
  .lib-row {
    background: var(--surface);
    border: 1px solid var(--border);
    border-radius: var(--radius-card);
    overflow: hidden;
    transition: border-color var(--motion-standard) var(--easing-settled);
  }
  .lib-row[data-source="user-created"] {
    border-left: 3px solid var(--reward, #C99F6C);
  }
  .lib-row[data-source="seed"] {
    border-left: 3px solid var(--sage, #6B8E7B);
  }
  .lib-row[data-source="promoted"] {
    border-left: 3px solid var(--primary);
  }

  .lib-summary {
    display: flex;
    align-items: center;
    justify-content: space-between;
    gap: 12px;
    padding: 12px 16px;
  }
  .lib-left { display: flex; flex-direction: column; gap: 4px; min-width: 0; }
  .lib-title-row { display: flex; align-items: center; gap: 10px; flex-wrap: wrap; }
  .lib-name { font-size: 15px; font-weight: 600; }
  .lib-meta {
    font-family: var(--font-mono);
    font-size: 11px;
    color: var(--text-secondary);
  }
  .lib-right { display: flex; gap: 6px; flex-shrink: 0; }
  .compact { padding: 6px 12px; font-size: 12px; }
  .ghost.compact.danger {
    color: var(--text-secondary);
    width: 32px; padding: 6px 0;
    text-align: center;
  }
  .ghost.compact.danger:hover { color: var(--error); border-color: var(--error); }

  .source-pill {
    font-family: var(--font-mono);
    font-size: 10px;
    letter-spacing: 0.08em;
    text-transform: uppercase;
    padding: 2px 8px;
    border-radius: 999px;
    border: 1px solid var(--border);
    color: var(--text-secondary);
  }
  .source-pill[data-source="seed"] { border-color: var(--sage, #6B8E7B); color: var(--sage, #6B8E7B); }
  .source-pill[data-source="promoted"] { border-color: var(--primary); color: var(--primary); }
  .source-pill[data-source="user-created"] { border-color: var(--reward, #C99F6C); color: var(--reward, #C99F6C); }

  .lib-empty {
    padding: 24px;
    text-align: center;
    font-size: 13px;
    background: var(--surface);
    border: 1px dashed var(--border);
    border-radius: var(--radius-card);
  }

  .edit-block {
    border-radius: 0;
    border-left: none;
    border-right: none;
    border-top: none;
    margin: 0;
  }
</style>
