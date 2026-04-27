<script lang="ts">
  import { onMount } from "svelte";
  import CameraPicker from "../components/CameraPicker.svelte";
  import FolderPicker from "../components/FolderPicker.svelte";
  import { app } from "../stores/app.svelte.ts";
  import {
    listEnglishVoices,
    setPreferredVoice,
    getPreferredVoice,
    speak,
  } from "../lib/voice";

  type Category = "recording" | "voice" | "about";

  const categories: { id: Category; label: string; hint: string }[] = [
    { id: "recording", label: "Recording", hint: "Cameras + save folder" },
    { id: "voice",     label: "Voice",     hint: "Coach voice + pacing" },
    { id: "about",     label: "About",     hint: "Version + brand" },
  ];

  let active = $state<Category>("recording");

  const onCameras = (ids: [string, string, string]) => { app.cameraIds = ids; };
  const onFolder = (handle: FileSystemDirectoryHandle) => { app.saveFolder = handle; };

  // Voice picker state. Voices arrive async on most browsers — re-read on
  // mount AND on the voiceschanged event (which our voice.ts wires globally).
  const VOICE_PREF_KEY = "way2train.preferredVoice.v1";
  let voices = $state<SpeechSynthesisVoice[]>([]);
  let selectedVoiceName = $state<string>("");
  let testText = $state<string>(
    "Set one of one. Foam roller bridge. Jelly belly, push through the inside edge of the foot.",
  );

  const refreshVoices = () => {
    voices = listEnglishVoices();
    if (!selectedVoiceName) {
      selectedVoiceName = getPreferredVoice()?.name ?? "";
    }
  };

  onMount(() => {
    // Pull persisted preference, apply to the global picker, then refresh.
    const stored = localStorage.getItem(VOICE_PREF_KEY);
    if (stored) {
      setPreferredVoice(stored);
      selectedVoiceName = stored;
    }
    refreshVoices();
    if ("speechSynthesis" in window) {
      const handler = () => refreshVoices();
      window.speechSynthesis.addEventListener("voiceschanged", handler);
      return () => window.speechSynthesis.removeEventListener("voiceschanged", handler);
    }
  });

  const onVoiceChange = (name: string) => {
    selectedVoiceName = name;
    setPreferredVoice(name || null);
    if (name) localStorage.setItem(VOICE_PREF_KEY, name);
    else localStorage.removeItem(VOICE_PREF_KEY);
  };

  const testVoice = () => speak(testText);
</script>

<div class="page">
  <header class="page-header">
    <div class="head-left">
      <button class="ghost icon" onclick={() => app.goto("sessions")} aria-label="Back to today's training">×</button>
      <h1>Settings</h1>
    </div>
    <span class="pill pill-outline">Local · v1</span>
  </header>

  <div class="layout">
    <nav class="side-nav" aria-label="Settings categories">
      {#each categories as c}
        <button
          class="nav-item"
          data-active={active === c.id}
          onclick={() => (active = c.id)}
        >
          <span class="nav-label">{c.label}</span>
          <span class="nav-hint">{c.hint}</span>
        </button>
      {/each}
    </nav>

    <div class="content">
      {#if active === "recording"}
        <div class="panel">
          <div class="panel-head">
            <h2>Recording</h2>
            <p class="text-secondary">
              Optional. Configure cameras + a save folder if you want videos recorded during training.
              Without these, you'll still get the voice-coached training flow.
            </p>
          </div>

          <section class="section">
            <div class="section-head">
              <h3>Save folder</h3>
              {#if app.isFolderReady}
                <span class="pill pill-sage">Ready</span>
              {:else}
                <span class="pill pill-outline">Not configured</span>
              {/if}
            </div>
            <FolderPicker onPicked={onFolder} />
          </section>

          <section class="section">
            <div class="section-head">
              <h3>Cameras</h3>
              {#if app.isCameraReady}
                <span class="pill pill-sage">3 cameras ready</span>
              {:else}
                <span class="pill pill-outline">Not configured</span>
              {/if}
            </div>
            <CameraPicker onConfirm={onCameras} />
          </section>
        </div>
      {:else if active === "voice"}
        <div class="panel">
          <div class="panel-head">
            <h2>Voice</h2>
            <p class="text-secondary">
              Pick the coach voice for cues, prep announcements, and rest timer.
              Google voices sound the most natural; eSpeak is local but robotic.
            </p>
          </div>

          <section class="section">
            <div class="section-head">
              <h3>Coach voice</h3>
              {#if selectedVoiceName}
                <span class="pill pill-sage">Saved</span>
              {:else}
                <span class="pill pill-outline">Auto-pick</span>
              {/if}
            </div>

            {#if voices.length === 0}
              <p class="text-secondary">
                No English voices found yet. If this persists, your TTS engine may not be installed.
              </p>
            {:else}
              <select
                class="voice-select"
                value={selectedVoiceName}
                onchange={(e) => onVoiceChange((e.currentTarget as HTMLSelectElement).value)}
                aria-label="Coach voice"
              >
                <option value="">Auto (best available)</option>
                {#each voices as v (v.name)}
                  <option value={v.name}>{v.name} — {v.lang}</option>
                {/each}
              </select>

              <div class="voice-test">
                <textarea
                  class="voice-test-text"
                  bind:value={testText}
                  rows="2"
                  aria-label="Voice test text"
                ></textarea>
                <button class="ghost" onclick={testVoice}>▶ Test voice</button>
              </div>

              <p class="text-secondary text-small">
                Some voices need a network connection (Google ones stream from Google's servers).
                Local voices like eSpeak work offline but sound flatter.
              </p>
            {/if}
          </section>
        </div>
      {:else if active === "about"}
        <div class="panel">
          <div class="panel-head">
            <h2>About</h2>
            <p class="text-secondary">
              Way2Move Training Recorder — a local-first web tool for recording 3-camera training
              sessions with voice coaching.
            </p>
          </div>

          <section class="section">
            <div class="about-grid">
              <div class="about-row">
                <span class="about-key">App</span>
                <span class="about-val">Training Recorder</span>
              </div>
              <div class="about-row">
                <span class="about-key">Version</span>
                <span class="about-val text-mono">v1 · local storage</span>
              </div>
              <div class="about-row">
                <span class="about-key">Data</span>
                <span class="about-val">Stored in this browser only</span>
              </div>
            </div>
          </section>
        </div>
      {/if}

      <button class="primary big done-btn" onclick={() => app.goto("sessions")}>Done</button>
    </div>
  </div>
</div>

<style>
  .page {
    max-width: 1120px; width: 100%; margin: 0 auto;
    padding: 24px 24px 96px;
    display: flex; flex-direction: column; gap: 24px;
    animation: fade-rise var(--motion-settled) var(--easing-settled) both;
  }

  .page-header {
    display: flex; align-items: center; justify-content: space-between;
  }
  .head-left { display: flex; align-items: center; gap: 16px; }
  .page-header h1 { font-size: 40px; letter-spacing: -0.5px; }

  .ghost.icon {
    width: 40px; height: 40px; padding: 0; border-radius: 50%;
    font-size: 22px; line-height: 1;
  }

  .layout {
    display: grid;
    grid-template-columns: 240px 1fr;
    gap: 32px;
    align-items: start;
  }

  .side-nav {
    display: flex;
    flex-direction: column;
    gap: 4px;
    position: sticky;
    top: 24px;
  }
  .nav-item {
    display: flex;
    flex-direction: column;
    align-items: flex-start;
    gap: 2px;
    padding: 12px 14px;
    border-radius: var(--radius-card);
    background: transparent;
    color: var(--text);
    border: 1px solid transparent;
    text-align: left;
  }
  .nav-item:hover:not([data-active="true"]) {
    background: var(--surface-raised);
    border-color: var(--border);
  }
  .nav-item[data-active="true"] {
    background: var(--surface);
    border-color: var(--border);
    border-left: 3px solid var(--primary);
    padding-left: 12px;
  }
  .nav-label {
    font-weight: 700;
    font-size: 15px;
    color: var(--text);
  }
  .nav-hint {
    font-size: 12px;
    color: var(--text-secondary);
  }

  .content {
    display: flex;
    flex-direction: column;
    gap: 24px;
    min-width: 0;
  }

  .panel {
    background: var(--surface);
    border: 1px solid var(--border);
    border-radius: var(--radius-card);
    padding: 28px;
    display: flex;
    flex-direction: column;
    gap: 28px;
  }
  .panel-head { display: flex; flex-direction: column; gap: 8px; }
  .panel-head h2 { font-size: 28px; letter-spacing: -0.3px; }
  .panel-head p { font-size: 14px; max-width: 640px; }

  .section { display: flex; flex-direction: column; gap: 12px; }
  .section-head {
    display: flex; align-items: baseline; justify-content: space-between;
    padding: 0 4px;
  }
  .section-head h3 { font-size: 17px; font-weight: 700; }

  .about-grid {
    display: flex;
    flex-direction: column;
    border: 1px solid var(--border);
    border-radius: var(--radius-card);
    overflow: hidden;
  }
  .about-row {
    display: grid;
    grid-template-columns: 140px 1fr;
    gap: 16px;
    padding: 14px 18px;
    background: var(--surface);
  }
  .about-row + .about-row { border-top: 1px solid var(--border); }
  .about-key { color: var(--text-secondary); font-size: 13px; font-weight: 600; }
  .about-val { color: var(--text); font-size: 14px; }

  .done-btn { align-self: flex-start; }

  /* Voice picker */
  .voice-select {
    width: 100%;
    padding: 12px 14px;
    border: 1px solid var(--border);
    border-radius: var(--radius-input);
    background: var(--surface);
    color: var(--text);
    font-family: var(--font-body);
    font-size: 14px;
    line-height: 1.4;
    cursor: pointer;
  }
  .voice-select:focus {
    outline: none;
    border-color: var(--sage);
    box-shadow: 0 0 0 3px rgba(122, 155, 118, 0.15);
  }
  .voice-test {
    display: flex;
    flex-direction: column;
    gap: 8px;
    margin-top: 4px;
  }
  .voice-test-text {
    width: 100%;
    padding: 10px 12px;
    border: 1px solid var(--border);
    border-radius: var(--radius-input);
    background: var(--surface);
    color: var(--text);
    font-family: var(--font-body);
    font-size: 13px;
    line-height: 1.5;
    resize: vertical;
  }
  .voice-test-text:focus {
    outline: none;
    border-color: var(--sage);
    box-shadow: 0 0 0 3px rgba(122, 155, 118, 0.15);
  }
  .text-small { font-size: 12px; }

  @media (max-width: 760px) {
    .layout {
      grid-template-columns: 1fr;
      gap: 16px;
    }
    .side-nav {
      position: static;
      flex-direction: row;
      overflow-x: auto;
    }
    .nav-item {
      flex: 0 0 auto;
    }
    .nav-item[data-active="true"] {
      border-left: 1px solid var(--border);
      border-top: 3px solid var(--primary);
      padding-left: 14px;
      padding-top: 10px;
    }
  }
</style>
