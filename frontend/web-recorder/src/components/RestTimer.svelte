<script lang="ts">
  import { onDestroy } from "svelte";
  import { speak } from "../lib/voice";

  interface Props {
    seconds: number;
    onDone?: () => void;
    autoStart?: boolean;
    speakCues?: boolean;
  }
  let { seconds, onDone, autoStart = true, speakCues = true }: Props = $props();

  // Initial values are captured intentionally — the timer is mounted fresh per
  // rest block, so prop changes after mount aren't a real concern.
  // svelte-ignore state_referenced_locally
  let remaining = $state(seconds);
  // svelte-ignore state_referenced_locally
  let running = $state(autoStart);
  let interval: ReturnType<typeof setInterval> | null = null;

  const tick = () => {
    remaining--;
    if (speakCues && (remaining === 10 || remaining === 5)) {
      speak(`${remaining} seconds`);
    }
    if (remaining <= 0) {
      stopTimer();
      if (speakCues) speak("Go.");
      onDone?.();
    }
  };

  const startTimer = () => {
    if (interval) return;
    running = true;
    interval = setInterval(tick, 1000);
  };

  const stopTimer = () => {
    if (interval) clearInterval(interval);
    interval = null;
    running = false;
  };

  $effect(() => {
    if (autoStart) startTimer();
    return () => stopTimer();
  });

  onDestroy(() => stopTimer());

  const fmt = (s: number) => {
    const m = Math.floor(s / 60);
    const r = s % 60;
    return `${m}:${r.toString().padStart(2, "0")}`;
  };
</script>

<div class="rest-timer" class:done={remaining <= 0}>
  <div class="time-row">
    <span class="time">{fmt(Math.max(0, remaining))}</span>
  </div>
  <div class="controls">
    {#if running}
      <button class="ghost" onclick={stopTimer}>Pause</button>
    {:else}
      <button class="ghost" onclick={startTimer} disabled={remaining <= 0}>Resume</button>
    {/if}
    <button class="ghost" onclick={() => { remaining += 10; }}>+10s</button>
    <button class="ghost" onclick={() => { stopTimer(); onDone?.(); }}>Skip</button>
  </div>
</div>

<style>
  .rest-timer {
    display: flex;
    flex-direction: column;
    gap: 10px;
  }
  .time-row {
    display: flex;
    align-items: baseline;
    gap: 8px;
  }
  .time {
    font-family: var(--font-mono);
    font-size: 44px;
    font-weight: 600;
    color: var(--accent);
    font-variant-numeric: tabular-nums;
    letter-spacing: -0.02em;
    line-height: 1;
  }
  .done .time { color: var(--reward); }
  .controls { display: flex; gap: 8px; flex-wrap: wrap; }
  .controls button { padding: 8px 14px; font-size: 13px; }
</style>
