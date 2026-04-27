<script lang="ts">
  import { onMount, onDestroy, tick } from "svelte";
  import {
    closeStreams,
    startComposite,
    CompositeRecorder,
    COMPOSITE_W,
    COMPOSITE_H,
    TILE_W,
    TILE_H,
    type RecordingResult,
  } from "../lib/recorder";

  interface Props {
    selectedDeviceIds: [string, string, string] | null;
    onRecorded: (r: RecordingResult) => void | Promise<void>;
  }
  let { selectedDeviceIds, onRecorded }: Props = $props();

  // Plain refs populated synchronously by bind:this on mount.
  let canvas: HTMLCanvasElement;
  let videoEl0: HTMLVideoElement;
  let videoEl1: HTMLVideoElement;
  let videoEl2: HTMLVideoElement;

  let streams: (MediaStream | null)[] = [null, null, null];
  let stopDraw: (() => void) | null = null;
  const recorder = new CompositeRecorder();
  let recording = $state(false);
  let error = $state<string | null>(null);

  type CamStatus = "idle" | "opening" | "playing" | "error";
  let camStatus = $state<CamStatus[]>(["idle", "idle", "idle"]);
  let camLabel = $state<string[]>(["", "", ""]);
  let camError = $state<(string | null)[]>([null, null, null]);
  let streamsStarted = $state(false);

  const openOne = async (
    v: HTMLVideoElement,
    deviceId: string,
    i: number,
  ): Promise<MediaStream | null> => {
    camStatus[i] = "opening";
    camError[i] = null;
    try {
      console.log(`[CompositeRecorder] cam${i} opening id=${deviceId.slice(0, 12)}...`);
      const stream = await navigator.mediaDevices.getUserMedia({
        video: {
          deviceId: { exact: deviceId },
          width: { exact: TILE_W },
          height: { exact: TILE_H },
        },
        audio: false,
      });
      v.srcObject = stream;
      v.muted = true;
      v.autoplay = true;
      v.playsInline = true;
      try {
        await v.play();
      } catch (e) {
        console.warn(`[CompositeRecorder] cam${i} play() rejected:`, e);
      }
      if (v.readyState < 2) {
        await new Promise<void>((res) => {
          v.addEventListener("loadeddata", () => res(), { once: true });
        });
      }
      const track = stream.getVideoTracks()[0];
      camLabel[i] = `${v.videoWidth}×${v.videoHeight} · ${track?.label ?? "camera"}`;
      camStatus[i] = "playing";
      console.log(`[CompositeRecorder] cam${i} ready: ${camLabel[i]}`);
      return stream;
    } catch (e: any) {
      const msg = `${e.name ?? "Error"}: ${e.message ?? e}`;
      camStatus[i] = "error";
      camError[i] = msg;
      console.error(`[CompositeRecorder] cam${i} failed:`, e);
      return null;
    }
  };

  const startStreams = async (ids: [string, string, string]) => {
    error = null;
    closeStreams(streams);
    stopDraw?.();
    streams = [null, null, null];

    const vids = [videoEl0, videoEl1, videoEl2];
    if (!canvas || vids.some((v) => !v)) {
      error = "Camera surfaces not mounted yet.";
      return;
    }

    streams[0] = await openOne(vids[0], ids[0], 0);
    streams[1] = await openOne(vids[1], ids[1], 1);
    streams[2] = await openOne(vids[2], ids[2], 2);

    // Canvas still draws the 3-up composite — that's what MediaRecorder
    // captures. The canvas itself is never shown to the user (hidden
    // off-screen). The saved file is the composite; the live preview is
    // the 3 separate cameras above.
    stopDraw = startComposite(canvas, vids);
    streamsStarted = true;
    console.log("[CompositeRecorder] composite draw loop started (off-screen)");
  };

  onMount(async () => {
    await tick();
    if (selectedDeviceIds) await startStreams(selectedDeviceIds);
  });

  export const start = () => {
    if (recording || !canvas) return;
    try {
      recorder.start(canvas);
      recording = true;
    } catch (e: any) {
      error = e.message ?? String(e);
    }
  };

  export const stop = async () => {
    if (!recording) return;
    const result = await recorder.stop();
    recording = false;
    await onRecorded(result);
  };

  const retryCameras = async () => {
    if (selectedDeviceIds) await startStreams(selectedDeviceIds);
  };

  onDestroy(() => {
    stopDraw?.();
    closeStreams(streams);
  });
</script>

<div class="composite-recorder">
  {#if error}
    <div class="error">{error}</div>
  {/if}

  <!-- Three cameras shown separately with the label UNDER each frame. The
       composite canvas is kept off-screen; it exists only so MediaRecorder
       has a source to capture. -->
  <div class="raw-row" aria-label="Live cameras">
    <div class="raw-tile">
      <div class="cam-frame">
        <video bind:this={videoEl0} autoplay muted playsinline></video>
      </div>
      <div class="raw-caption" data-status={camStatus[0]}>
        {#if camStatus[0] === "opening"}Opening…
        {:else if camStatus[0] === "playing"}{camLabel[0]}
        {:else if camStatus[0] === "error"}✗ {camError[0]}
        {:else}—{/if}
      </div>
    </div>
    <div class="raw-tile">
      <div class="cam-frame">
        <video bind:this={videoEl1} autoplay muted playsinline></video>
      </div>
      <div class="raw-caption" data-status={camStatus[1]}>
        {#if camStatus[1] === "opening"}Opening…
        {:else if camStatus[1] === "playing"}{camLabel[1]}
        {:else if camStatus[1] === "error"}✗ {camError[1]}
        {:else}—{/if}
      </div>
    </div>
    <div class="raw-tile">
      <div class="cam-frame">
        <video bind:this={videoEl2} autoplay muted playsinline></video>
      </div>
      <div class="raw-caption" data-status={camStatus[2]}>
        {#if camStatus[2] === "opening"}Opening…
        {:else if camStatus[2] === "playing"}{camLabel[2]}
        {:else if camStatus[2] === "error"}✗ {camError[2]}
        {:else}—{/if}
      </div>
    </div>
  </div>

  {#if recording}
    <div class="recording-badge">
      <span class="dot"></span>
      Recording
    </div>
  {/if}

  <div class="cam-actions">
    <button class="ghost" type="button" onclick={retryCameras}>Retry cameras</button>
    <span class="text-secondary hint">
      {#if !streamsStarted}Cameras starting…
      {:else if camStatus.some((s) => s === "error")}Click to retry failed cameras after freeing the device.
      {:else}All cameras live.{/if}
    </span>
  </div>

  <!-- Canvas parked off-screen: drawing every frame (so captureStream works)
       but never visible. -->
  <canvas
    class="offscreen-canvas"
    bind:this={canvas}
    width={COMPOSITE_W}
    height={COMPOSITE_H}
  ></canvas>
</div>

<style>
  .composite-recorder {
    display: flex;
    flex-direction: column;
    gap: 0.75rem;
  }
  .raw-row {
    display: grid;
    grid-template-columns: repeat(3, 1fr);
    gap: 12px;
  }
  .raw-tile {
    display: flex;
    flex-direction: column;
    gap: 6px;
  }
  /* Wrapper enforces 4:3 regardless of the camera's native aspect ratio
     (e.g. C922 Pro Stream defaults to 16:9 at 1080p). */
  .cam-frame {
    position: relative;
    aspect-ratio: 4 / 3;
    background: var(--warm-charcoal);
    border-radius: var(--radius-input);
    overflow: hidden;
  }
  .cam-frame video {
    position: absolute;
    inset: 0;
    width: 100%;
    height: 100%;
    object-fit: cover;
    display: block;
  }
  .raw-caption {
    font-family: var(--font-mono);
    font-size: 11px;
    line-height: 1.3;
    color: var(--text-secondary);
    padding: 2px 2px 0;
    white-space: nowrap;
    overflow: hidden;
    text-overflow: ellipsis;
  }
  .raw-caption[data-status="playing"] { color: var(--sage, #6B8E7B); }
  .raw-caption[data-status="error"] {
    color: var(--error);
    white-space: normal;
  }
  .recording-badge {
    display: inline-flex;
    align-items: center;
    gap: 8px;
    padding: 4px 12px 4px 10px;
    background: rgba(26, 22, 18, 0.72);
    border-radius: 999px;
    color: #F5EFE7;
    font-family: var(--font-body);
    font-size: 11px;
    font-weight: 600;
    letter-spacing: 0.4px;
    text-transform: uppercase;
    align-self: flex-start;
    animation: fade-rise var(--motion-settled) var(--easing-settled) both;
  }
  .recording-badge .dot {
    width: 7px;
    height: 7px;
    border-radius: 50%;
    background: var(--accent);
    animation: breath var(--motion-breath) ease-in-out infinite;
  }
  .offscreen-canvas {
    position: absolute;
    left: -99999px;
    top: 0;
    width: 1px;
    height: 1px;
    pointer-events: none;
  }
  .cam-actions {
    display: flex;
    align-items: center;
    gap: 12px;
    flex-wrap: wrap;
  }
  .hint { font-size: 12px; }
  .error {
    background: rgba(190, 74, 58, 0.1);
    color: var(--error);
    padding: 12px 16px;
    border-radius: var(--radius-input);
    border: 1.5px solid var(--error);
    font-size: 14px;
  }
</style>
