<script lang="ts">
  import type { SetEntry, EffortRow, EffortKind } from "../lib/types";
  import { newId } from "../lib/sessionStore";

  interface Props {
    setNumber: number;
    defaultKind?: EffortKind;
    plannedReps?: number;
    plannedSeconds?: number;
    plannedWeight?: number;
    // Existing entry for this set — rows will pre-populate from here if provided.
    initial?: SetEntry;
    onSave: (entry: SetEntry) => void;
  }
  let {
    setNumber,
    defaultKind = "reps",
    plannedReps,
    plannedSeconds,
    plannedWeight,
    initial,
    onSave,
  }: Props = $props();

  const makeDefaultRow = (kind: EffortKind = defaultKind): EffortRow => ({
    id: newId(),
    kind,
    reps: kind === "reps" ? plannedReps : undefined,
    seconds: kind === "time" ? plannedSeconds : undefined,
    weight: plannedWeight,
  });

  // Seed rows from existing entry if we have one, otherwise start with a
  // single row reflecting the exercise's planned target. Legacy entries
  // (written before the multi-row model) carried top-level reps/weight —
  // synthesize a row from those so old logs stay visible.
  const seedRows = (): EffortRow[] => {
    if (initial?.rows?.length) return initial.rows.map((r) => ({ ...r }));
    if (initial && (initial.reps != null || initial.weight != null)) {
      return [{
        id: newId(),
        kind: "reps",
        reps: initial.reps,
        weight: initial.weight,
      }];
    }
    return [makeDefaultRow()];
  };
  let rows = $state<EffortRow[]>(seedRows());

  const addRow = () => {
    // Copy kind + weight from the last row — "same weight" is the common
    // case; a drop-set is the interesting one and user can edit the copy.
    const last = rows[rows.length - 1];
    rows = [
      ...rows,
      {
        id: newId(),
        kind: last?.kind ?? defaultKind,
        weight: last?.weight,
      },
    ];
  };

  const removeRow = (i: number) => {
    if (rows.length <= 1) return;
    rows = rows.filter((_, idx) => idx !== i);
  };

  const toggleKind = (i: number, k: EffortKind) => {
    rows[i] = { ...rows[i], kind: k };
  };

  const save = () => {
    const cleaned: EffortRow[] = rows.map((r) => ({
      id: r.id,
      kind: r.kind,
      reps: r.kind === "reps" && r.reps != null && r.reps !== ("" as any) ? Number(r.reps) : undefined,
      seconds: r.kind === "time" && r.seconds != null && r.seconds !== ("" as any) ? Number(r.seconds) : undefined,
      weight: r.weight != null && r.weight !== ("" as any) ? Number(r.weight) : undefined,
    }));
    onSave({ setNumber, rows: cleaned, completed: true });
  };

  const planSummary = $derived(() => {
    if (defaultKind === "time" && plannedSeconds) return `planned ${plannedSeconds}s`;
    if (plannedReps) return `planned ${plannedReps} reps`;
    return "";
  });
</script>

<form class="entry-form" onsubmit={(e) => { e.preventDefault(); save(); }}>
  <div class="head">
    <span class="label">Log set {setNumber}</span>
    {#if planSummary()}<span class="planned">{planSummary()}</span>{/if}
  </div>

  <div class="rows">
    {#each rows as row, i (row.id)}
      <div class="row">
        <div class="kind-toggle" role="group" aria-label="Effort type">
          <button
            type="button"
            class:active={row.kind === "reps"}
            onclick={() => toggleKind(i, "reps")}
          >Reps</button>
          <button
            type="button"
            class:active={row.kind === "time"}
            onclick={() => toggleKind(i, "time")}
          >Time</button>
        </div>

        <div class="row-fields">
          {#if row.kind === "reps"}
            <label class="field">
              <input type="number" min="0" bind:value={rows[i].reps} placeholder="0" />
              <span class="unit">reps</span>
            </label>
          {:else}
            <label class="field">
              <input type="number" min="0" bind:value={rows[i].seconds} placeholder="0" />
              <span class="unit">sec</span>
            </label>
          {/if}

          <span class="sep">×</span>

          <label class="field">
            <input type="number" min="0" step="0.5" bind:value={rows[i].weight} placeholder="0" />
            <span class="unit">kg</span>
          </label>
        </div>

        {#if rows.length > 1}
          <button
            type="button"
            class="row-remove"
            aria-label="Remove row"
            onclick={() => removeRow(i)}
          >×</button>
        {/if}
      </div>
    {/each}
  </div>

  <div class="actions">
    <button type="button" class="ghost add-row" onclick={addRow}>+ Add row</button>
    <button type="submit" class="accent">Save</button>
  </div>
</form>

<style>
  .entry-form {
    display: flex;
    flex-direction: column;
    gap: 12px;
  }
  .head {
    display: flex;
    justify-content: space-between;
    align-items: baseline;
  }
  .label {
    font-family: var(--font-body);
    font-size: 11px;
    font-weight: 600;
    letter-spacing: 0.08em;
    text-transform: uppercase;
    color: var(--text-secondary);
  }
  .planned {
    color: var(--text-secondary);
    font-size: 12px;
    font-family: var(--font-mono);
  }
  .rows {
    display: flex;
    flex-direction: column;
    gap: 8px;
  }
  .row {
    display: grid;
    grid-template-columns: auto 1fr auto;
    gap: 10px;
    align-items: center;
  }
  .kind-toggle {
    display: inline-flex;
    border: 1px solid var(--border);
    border-radius: 999px;
    padding: 2px;
    background: var(--surface);
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
  .row-fields {
    display: flex;
    align-items: center;
    gap: 8px;
    min-width: 0;
  }
  .field {
    display: inline-flex;
    align-items: center;
    gap: 4px;
    background: var(--surface);
    border: 1px solid var(--border);
    border-radius: var(--radius-input);
    padding: 4px 10px;
    min-width: 0;
    flex: 1;
  }
  .field input {
    border: none;
    background: transparent;
    width: 100%;
    font-family: var(--font-mono);
    font-size: 16px;
    font-variant-numeric: tabular-nums;
    padding: 2px 0;
    color: var(--text);
    min-width: 0;
  }
  .field input:focus { outline: none; }
  .unit {
    font-family: var(--font-mono);
    font-size: 11px;
    color: var(--text-secondary);
    letter-spacing: 0.04em;
    flex-shrink: 0;
  }
  .sep {
    font-family: var(--font-mono);
    color: var(--text-secondary);
    font-size: 14px;
    flex-shrink: 0;
  }
  .row-remove {
    width: 28px;
    height: 28px;
    border-radius: 50%;
    border: 1px solid var(--border);
    background: transparent;
    color: var(--text-secondary);
    font-size: 16px;
    line-height: 1;
    cursor: pointer;
    padding: 0;
  }
  .row-remove:hover {
    color: var(--error);
    border-color: var(--error);
  }
  .actions {
    display: flex;
    justify-content: space-between;
    gap: 10px;
    align-items: center;
    padding-top: 4px;
    border-top: 1px dashed var(--border);
  }
  .add-row {
    font-size: 12px;
    padding: 6px 12px;
  }
</style>
