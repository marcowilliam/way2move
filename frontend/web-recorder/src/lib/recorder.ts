// Camera + canvas + MediaRecorder. Ported from web_test.html.
// Stays framework-agnostic — Svelte components import this.

export const TILE_W = 640;
export const TILE_H = 480;
export const FPS = 30;
// 2x2 layout: cam0 + cam1 on top row, cam2 centered on bottom. 4:3 composite,
// far less stretched than a 3-wide row (which was 4:1).
export const COMPOSITE_W = TILE_W * 2;   // 1280
export const COMPOSITE_H = TILE_H * 2;   // 960

export const pickMime = (): string => {
  const candidates = [
    "video/mp4;codecs=h264",
    "video/webm;codecs=vp8",
    "video/webm;codecs=vp9",
    "video/webm",
  ];
  return candidates.find((m) => MediaRecorder.isTypeSupported(m)) || "";
};

export const extForMime = (mime: string): "mp4" | "webm" =>
  mime.startsWith("video/mp4") ? "mp4" : "webm";

export interface CameraInfo {
  deviceId: string;
  label: string;
}

export const enumerateCameras = async (): Promise<CameraInfo[]> => {
  // Trigger permission prompt so labels are populated.
  const tmp = await navigator.mediaDevices.getUserMedia({ video: true, audio: false });
  tmp.getTracks().forEach((t) => t.stop());

  const all = await navigator.mediaDevices.enumerateDevices();
  return all
    .filter((d) => d.kind === "videoinput")
    .map((d) => ({ deviceId: d.deviceId, label: d.label || "(no label)" }));
};

export const openStreams = async (deviceIds: string[]): Promise<MediaStream[]> => {
  const streams = await Promise.all(
    deviceIds.map((id) =>
      navigator.mediaDevices.getUserMedia({
        video: { deviceId: { exact: id }, width: { ideal: TILE_W }, height: { ideal: TILE_H } },
        audio: false,
      }),
    ),
  );
  return streams;
};

export const closeStreams = (streams: (MediaStream | null)[]): void => {
  streams.forEach((s) => s?.getTracks().forEach((t) => t.stop()));
};

/** Continuously draws three videos onto a canvas as a side-by-side composite.
 *  Returns a stop function. */
export const startComposite = (
  canvas: HTMLCanvasElement,
  videos: HTMLVideoElement[],
): (() => void) => {
  canvas.width = COMPOSITE_W;
  canvas.height = COMPOSITE_H;
  const ctx = canvas.getContext("2d")!;
  let handle = 0;

  // Tile placement: cam0 top-left, cam1 top-right, cam2 bottom-centered.
  const positions: Array<[number, number]> = [
    [0, 0],                     // cam0
    [TILE_W, 0],                // cam1
    [TILE_W / 2, TILE_H],       // cam2 (centered horizontally on bottom row)
  ];

  const draw = () => {
    ctx.fillStyle = "#000";
    ctx.fillRect(0, 0, canvas.width, canvas.height);
    for (let i = 0; i < videos.length && i < positions.length; i++) {
      const v = videos[i];
      if (v && v.readyState >= 2) {
        const [x, y] = positions[i];
        ctx.drawImage(v, x, y, TILE_W, TILE_H);
      }
    }
    handle = requestAnimationFrame(draw);
  };
  draw();
  return () => cancelAnimationFrame(handle);
};

export interface RecordingResult {
  blob: Blob;
  mimeType: string;
  ext: "mp4" | "webm";
  durationMs: number;
}

/** Records the canvas as a single composite video. */
export class CompositeRecorder {
  private recorder: MediaRecorder | null = null;
  private chunks: Blob[] = [];
  private startedAt = 0;
  private resolveStop: ((r: RecordingResult) => void) | null = null;

  start(canvas: HTMLCanvasElement): void {
    if (this.recorder) throw new Error("already recording");
    const stream = canvas.captureStream(FPS);
    const mimeType = pickMime();
    if (!mimeType) throw new Error("no MediaRecorder mime supported");
    this.chunks = [];
    this.recorder = new MediaRecorder(stream, { mimeType, videoBitsPerSecond: 4_000_000 });
    this.recorder.ondataavailable = (ev) => {
      if (ev.data.size > 0) this.chunks.push(ev.data);
    };
    this.recorder.onstop = () => {
      const mime = this.recorder!.mimeType || mimeType;
      const blob = new Blob(this.chunks, { type: mime });
      const result: RecordingResult = {
        blob,
        mimeType: mime,
        ext: extForMime(mime),
        durationMs: performance.now() - this.startedAt,
      };
      this.recorder = null;
      this.chunks = [];
      this.resolveStop?.(result);
      this.resolveStop = null;
    };
    this.startedAt = performance.now();
    this.recorder.start(1000);
  }

  stop(): Promise<RecordingResult> {
    if (!this.recorder) throw new Error("not recording");
    return new Promise((res) => {
      this.resolveStop = res;
      this.recorder!.stop();
    });
  }

  get isRecording(): boolean {
    return this.recorder !== null && this.recorder.state === "recording";
  }
}
