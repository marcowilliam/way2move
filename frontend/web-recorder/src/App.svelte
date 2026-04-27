<script lang="ts">
  import Settings from "./routes/Settings.svelte";
  import SessionsList from "./routes/SessionsList.svelte";
  import ActiveSession from "./routes/ActiveSession.svelte";
  import Builder from "./routes/Builder.svelte";
  import Library from "./routes/Library.svelte";
  import { app } from "./stores/app.svelte.ts";

  let prefersDark = $state(false);
  $effect(() => {
    const mq = window.matchMedia("(prefers-color-scheme: dark)");
    prefersDark = mq.matches;
    const handler = (e: MediaQueryListEvent) => { prefersDark = e.matches; };
    mq.addEventListener("change", handler);
    return () => mq.removeEventListener("change", handler);
  });
</script>

<main>
  <nav class="topbar">
    <button class="brand" onclick={() => app.goto("sessions")} aria-label="Way2Move home">
      <img src={prefersDark ? "/logo/wordmark-dark.svg" : "/logo/wordmark.svg"} alt="Way2Move" />
      <span class="sub">Training Recorder</span>
    </button>
    <button
      class="ghost gear"
      onclick={() => app.goto("settings")}
      aria-label="Settings"
      title="Settings"
    >
      <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.8" stroke-linecap="round" stroke-linejoin="round">
        <circle cx="12" cy="12" r="3"/>
        <path d="M19.4 15a1.65 1.65 0 0 0 .33 1.82l.06.06a2 2 0 1 1-2.83 2.83l-.06-.06a1.65 1.65 0 0 0-1.82-.33 1.65 1.65 0 0 0-1 1.51V21a2 2 0 1 1-4 0v-.09a1.65 1.65 0 0 0-1-1.51 1.65 1.65 0 0 0-1.82.33l-.06.06a2 2 0 1 1-2.83-2.83l.06-.06a1.65 1.65 0 0 0 .33-1.82 1.65 1.65 0 0 0-1.51-1H3a2 2 0 1 1 0-4h.09a1.65 1.65 0 0 0 1.51-1 1.65 1.65 0 0 0-.33-1.82l-.06-.06a2 2 0 1 1 2.83-2.83l.06.06a1.65 1.65 0 0 0 1.82.33h0a1.65 1.65 0 0 0 1-1.51V3a2 2 0 1 1 4 0v.09a1.65 1.65 0 0 0 1 1.51h0a1.65 1.65 0 0 0 1.82-.33l.06-.06a2 2 0 1 1 2.83 2.83l-.06.06a1.65 1.65 0 0 0-.33 1.82v0a1.65 1.65 0 0 0 1.51 1H21a2 2 0 1 1 0 4h-.09a1.65 1.65 0 0 0-1.51 1z"/>
      </svg>
    </button>
  </nav>

  {#if app.route === "sessions"}
    <SessionsList />
  {:else if app.route === "build"}
    <Builder />
  {:else if app.route === "library"}
    <Library />
  {:else if app.route === "active"}
    <ActiveSession />
  {:else if app.route === "settings"}
    <Settings />
  {/if}
</main>

<style>
  main {
    display: flex;
    flex-direction: column;
    min-height: 100vh;
  }
  .topbar {
    display: flex;
    justify-content: space-between;
    align-items: center;
    padding: 14px 24px;
    border-bottom: 1px solid var(--border);
    background: var(--surface);
  }
  .brand {
    display: inline-flex;
    align-items: center;
    gap: 12px;
    background: transparent;
    border: none;
    padding: 0;
    cursor: pointer;
  }
  .brand:hover { background: transparent; }
  .brand img {
    height: 22px;
    width: auto;
    display: block;
  }
  .sub {
    font-family: var(--font-body);
    font-weight: 600;
    font-size: 12px;
    letter-spacing: 0.6px;
    text-transform: uppercase;
    color: var(--text-secondary);
  }
  .gear {
    width: 40px;
    height: 40px;
    padding: 0;
    border-radius: 50%;
    color: var(--text-secondary);
  }
  .gear:hover { color: var(--text); }
</style>
