<script lang="ts">
  import {
    isFsApiSupported,
    pickRootFolder,
    restoreRootFolder,
    ensurePermission,
  } from "../lib/storage";

  interface Props {
    onPicked: (handle: FileSystemDirectoryHandle) => void;
  }
  let { onPicked }: Props = $props();

  let supported = $state(isFsApiSupported());
  let pickedName = $state<string | null>(null);
  let needsRegrant = $state(false);
  let busy = $state(false);
  let stored: FileSystemDirectoryHandle | null = null;

  const init = async () => {
    if (!supported) return;
    stored = await restoreRootFolder();
    if (stored) {
      pickedName = stored.name;
      const perm = await (stored as any).queryPermission({ mode: "readwrite" });
      needsRegrant = perm !== "granted";
      if (perm === "granted") onPicked(stored);
    }
  };
  init();

  const pickNew = async () => {
    busy = true;
    try {
      const h = await pickRootFolder();
      pickedName = h.name;
      needsRegrant = false;
      onPicked(h);
    } catch (e: any) {
      if (e.name !== "AbortError") console.error(e);
    } finally {
      busy = false;
    }
  };

  const regrant = async () => {
    if (!stored) return;
    busy = true;
    if (await ensurePermission(stored)) {
      needsRegrant = false;
      onPicked(stored);
    }
    busy = false;
  };
</script>

<section class="card folder-picker">
  <header>
    <h2>Save folder</h2>
    {#if pickedName}<span class="pill pill-outline">{pickedName}</span>{/if}
  </header>

  {#if !supported}
    <div class="error">
      File System Access API not supported in this browser. Use Chrome or Edge.
    </div>
  {:else if needsRegrant}
    <p class="hint">Permission expired for "{pickedName}". Re-grant to continue.</p>
    <button class="primary" onclick={regrant} disabled={busy}>Re-grant access</button>
  {:else}
    <button class="primary" onclick={pickNew} disabled={busy}>
      {pickedName ? "Pick a different folder" : "Pick save folder"}
    </button>
    <p class="hint">
      Recordings will be saved as
      <code>&lt;folder&gt;/&lt;training&gt;/&lt;date&gt;/&lt;exercise&gt;/&lt;time&gt;.{`{mp4|webm}`}</code>
    </p>
  {/if}
</section>

<style>
  .folder-picker { display: flex; flex-direction: column; gap: 0.75rem; }
  header { display: flex; align-items: center; justify-content: space-between; }
  .hint { color: var(--text-secondary); font-size: 0.9rem; margin: 0; }
  code {
    font-size: 0.8rem;
    background: var(--surface-raised);
    padding: 0.15rem 0.4rem;
    border-radius: 4px;
    color: var(--text);
  }
  .error {
    background: var(--error); color: var(--warm-paper);
    padding: 0.6rem 0.9rem; border-radius: var(--radius-input);
  }
</style>
