<script lang="ts">
  import { enumerateCameras, type CameraInfo } from "../lib/recorder";
  import { loadSettings, saveSettings } from "../lib/sessionStore";

  interface Props {
    onConfirm: (ids: [string, string, string]) => void;
  }
  let { onConfirm }: Props = $props();

  let cameras = $state<CameraInfo[]>([]);
  let assignments = $state<[string, string, string]>(["", "", ""]);
  let busy = $state(false);
  let error = $state<string | null>(null);

  const refresh = async () => {
    busy = true;
    error = null;
    try {
      cameras = await enumerateCameras();
      const stored = loadSettings().cameras;
      [0, 1, 2].forEach((slot) => {
        const found = stored.find((c) => c.slot === slot);
        const fallback = cameras[slot]?.deviceId ?? "";
        assignments[slot] = found?.deviceId && cameras.some((c) => c.deviceId === found.deviceId)
          ? found.deviceId
          : fallback;
      });
    } catch (e: any) {
      error = `${e.name}: ${e.message}`;
    } finally {
      busy = false;
    }
  };

  const labelFor = (deviceId: string): string =>
    cameras.find((c) => c.deviceId === deviceId)?.label ?? "";

  const distinct = $derived(new Set(assignments).size === 3 && assignments.every(Boolean));

  const confirm = () => {
    saveSettings({
      cameras: assignments.map((deviceId, slot) => ({
        slot: slot as 0 | 1 | 2,
        deviceId,
        label: labelFor(deviceId),
      })),
    });
    onConfirm(assignments);
  };
</script>

<section class="card camera-picker">
  <header>
    <h2>Cameras</h2>
    <button onclick={refresh} disabled={busy}>{cameras.length ? "Refresh" : "Detect cameras"}</button>
  </header>

  {#if error}
    <div class="error">{error}</div>
  {/if}

  {#if cameras.length}
    <div class="grid">
      {#each [0, 1, 2] as slot}
        <label>
          <span class="slot-label">Camera {slot + 1}</span>
          <select bind:value={assignments[slot]}>
            <option value="" disabled>— pick —</option>
            {#each cameras as cam (cam.deviceId)}
              <option value={cam.deviceId}>{cam.label}</option>
            {/each}
          </select>
        </label>
      {/each}
    </div>

    <button class="primary" onclick={confirm} disabled={!distinct}>
      Use these 3 cameras
    </button>
    {#if !distinct && assignments.every(Boolean)}
      <p class="hint">Pick 3 <strong>distinct</strong> devices.</p>
    {/if}
  {:else if !busy}
    <p class="hint">Click "Detect cameras" to grant permission and list available devices.</p>
  {/if}
</section>

<style>
  .camera-picker { display: flex; flex-direction: column; gap: 1rem; }
  header { display: flex; justify-content: space-between; align-items: center; }
  .grid {
    display: grid;
    grid-template-columns: repeat(3, 1fr);
    gap: 0.75rem;
  }
  label { display: flex; flex-direction: column; gap: 0.35rem; }
  .slot-label {
    font-size: 0.85rem;
    color: var(--text-secondary);
    text-transform: uppercase;
    letter-spacing: 0.05em;
  }
  select {
    background: var(--surface-raised);
    color: var(--text);
    border: 1px solid var(--border);
    border-radius: var(--radius-input);
    padding: 0.55rem 0.7rem;
    font-family: var(--font-body);
  }
  .hint { color: var(--text-secondary); font-size: 0.9rem; margin: 0.25rem 0 0; }
  .error {
    background: var(--error); color: var(--warm-paper);
    padding: 0.6rem 0.9rem; border-radius: var(--radius-input);
  }
</style>
