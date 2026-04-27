// Svelte 5 runes-based stores. Tiny, no svelte/store dependency needed.

import { loadSettings } from "../lib/sessionStore";

type Route = "sessions" | "active" | "settings" | "build" | "library";

// Re-hydrate the camera slot → deviceId mapping from localStorage. Device IDs
// are stable per origin once camera permission is granted, so this survives
// hard refreshes without another permission prompt.
const loadInitialCameraIds = (): [string, string, string] | null => {
  try {
    const cams = loadSettings().cameras;
    if (cams.length !== 3) return null;
    const slots: (string | undefined)[] = [0, 1, 2].map(
      (slot) => cams.find((c) => c.slot === slot)?.deviceId,
    );
    if (slots.some((id) => !id)) return null;
    return slots as [string, string, string];
  } catch {
    return null;
  }
};

class AppState {
  route = $state<Route>("sessions");
  saveFolder = $state<FileSystemDirectoryHandle | null>(null);
  cameraIds = $state<[string, string, string] | null>(loadInitialCameraIds());
  activeSessionId = $state<string | null>(null);

  get isCameraReady() { return this.cameraIds !== null; }
  get isFolderReady() { return this.saveFolder !== null; }
  get isRecordingReady() { return this.isCameraReady && this.isFolderReady; }

  goto(route: Route) { this.route = route; }
}

export const app = new AppState();
