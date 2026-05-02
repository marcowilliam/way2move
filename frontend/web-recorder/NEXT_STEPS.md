# web-recorder — next steps

Last refreshed 2026-05-02. The recorder is now shippable for solo offline use. This file lists what's deferred, in rough priority order.

## Deferred — not blocking v1 daily use

1. **Firestore migration**. localStorage persistence works for one user on one machine. Replace `sessionStore.ts` + `exerciseStore.ts` with Firestore-backed implementations once way2move has real Firebase credentials. No schema changes needed — the types in `lib/types.ts` already mirror way2move's `Session` / `ExerciseBlock` / `Recording` domain shape.
2. **`Recording` entity in Flutter**. Add a `recordings: List<Recording>` field to `frontend/mobile/lib/features/sessions/domain/entities/session.dart`, plus Firestore (de)serialization in `session_model.dart`. Use the shape from `web-recorder/src/lib/types.ts` as the source of truth.
3. **Mobile recorder companion**. Eventually the phone records a single camera during training (Flutter feature, same repo). The web recorder handles the 3-camera composite case; mobile is the "always with me" 1-camera case.
4. **Lefthook integration**. `way2move/lefthook.yml` doesn't run anything from `frontend/web-recorder/` yet. Wire `npm run check` (svelte-check) on pre-commit for any change under `frontend/web-recorder/`.
5. **Replay during rest**. Show the last take's video on the rest screen so the athlete can self-correct before the next set. Parked feature ideas live in `~/.claude/projects/.../memory/web_recorder_debrief_ideas.md` — playback speed, draw-on-screen, auto-pose, misalignment color cues. The way2sense pose+hand sidecar (port 8766) is reusable here once we wire the WebSocket consumer.
6. **Camera config UX cleanup**. Minor: CameraPicker has its own h2 inside the card AND Settings wraps it with another section header — slight redundancy.
7. **Way2MoveLogoMark**. Only the wordmark renders in the topbar today. The "Rooted 2" symbol-only mark could live as a 24px favicon-style accent next to the wordmark, or as the page favicon (currently the Vite default).

## Verify before assuming "done"

- [ ] `npm run dev` boots clean on port 5193, no console errors.
- [ ] Settings → Detect cameras lists ≥3 devices including Iriun.
- [ ] After picking 3 cameras + a save folder, Home shows "Ready to record" pill.
- [ ] Starting an ad-hoc session jumps into a hero card with TTS reading the cues.
- [ ] Recording a set saves a file at `<root>/<training>/<date>/<exercise>/rep1.<ext>` with real video frames (not a black frame).
- [ ] Logging reps + weight appends to `actualSets[]` (visible in `localStorage` under `way2train.sessions.v1`).
- [ ] Skipping an exercise mid-session pushes it down the sidebar; un-skipping restores it.
- [ ] Closing/reopening the tab remembers cameras + folder permission (folder may need a one-click re-grant).

## Known limitations

- **Chromium only** for v1. Firefox lacks the File System Access API and Web Speech API. Don't bother.
- **`canvas.captureStream(30)` actual FPS** depends on the slowest camera. If a camera lags, the composite stutters.
- **TTS interrupts itself** — every `speak()` call cancels the previous utterance. Intentional. Change `voice.ts:speak()` to remove the `cancel()` call if you want TTS lines to queue.
- **Speech recognition restarts after silence** with a 300ms gap. May briefly miss a command at the boundary.
- **No way to delete a take or session from the UI yet.** Clear `localStorage` in DevTools.
