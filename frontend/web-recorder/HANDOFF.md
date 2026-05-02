# web-recorder — handoff

Last refreshed 2026-05-02. The original camera-black bug from 2026-04-23 is resolved (cameras stream into the composite recorder; recordings save with the right names and folder structure). Since then a lot of v1 has shipped — see commit log for receipts.

---

## Current state — what works end-to-end

- **Setup**: Settings (gear icon → cards) lets you pick the save root folder, the 3 cameras, the TTS voice, and reseed Ground Up / Notion library data. Folder permission is persisted via IndexedDB and re-granted on return.
- **Home (SessionsList)**: today's training pinned to the top (planned session card with sensation lookback), plus a Notion library section ("Workouts library"), plus an "Add ad-hoc session" affordance. Readiness card surfaces what's missing (folder, cameras).
- **Active session**: voice-coached state machine over the planned exercise blocks. Hero card per step (set ↔ rest), bottom chip-track for steps inside a block, sidebar timeline for blocks across the session. Skip-exercise + un-skip from the sidebar. Mid-session set editor for plan changes.
- **Recording**: 3-camera composite (2x2 canvas, 1280x960, 4:3) via MediaRecorder. MP4 if Chrome supports it, WebM/VP8 fallback. Files land at `<root>/<training>/<date>/<exercise>/repN[-takeM].<ext>`.
- **Voice**: SpeechRecognition vocabulary `start | stop | next | skip | repeat | quit`. TTS reads block cues when sets start; cue pace slowed; a "best voice" auto-picker plus a manual override in Settings.
- **Educational content**: per-exercise schema + UI; full content for the 11 Ground Up exercises and 52 DAY A/B/C/E entries. Renders in the active session and in the library detail.
- **Persistence**: localStorage for sessions/exerciseStore (mirrors way2move's domain shape). Ready to swap for Firestore when real Firebase creds land — no schema changes needed.

## How to run

```
cd /projects/my-projects/personal/way2move/main/frontend/web-recorder
npm install            # first time only
npm run dev            # http://localhost:5193 (Chrome/Edge — Web Speech + File System APIs)
npm run check          # svelte-check (currently clean: 0 errors / 0 warnings)
```

If `/dev/video0` is held by another process (commonly the way2sense perception sidecar), free it before opening the recorder:
```
fuser -k /dev/video0
```

## What's still pending — see NEXT_STEPS.md

Short version: Firestore migration, mobile recorder companion, lefthook integration, replay during rest, and a handful of brand polish items.
