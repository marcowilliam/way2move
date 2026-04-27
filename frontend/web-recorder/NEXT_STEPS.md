# web-recorder — next steps

Scaffold built 2026-04-23 evening. This is what was done, what's stubbed, what's open.

## How to run it

```
cd /projects/my-projects/personal/way2move/main/frontend/web-recorder
npm install
npm run dev
```

Open `http://localhost:5193` in **Chrome or Edge** (File System Access API + Web Speech API are Chromium-only). Firefox won't work for v1.

`npm install` has not been run yet — I scaffolded the files but didn't pull dependencies. First-time setup is ~30 seconds; verify the dependency list in `package.json` is what you want before running it.

## What's built

```
web-recorder/
├── package.json              Svelte 5 + Vite + TypeScript + svelte-check
├── vite.config.ts            dev server on port 5193 (5193 ≈ "5193")
├── tsconfig.json             strict TS, bundler resolution
├── svelte.config.js
├── index.html                single page entry
├── .gitignore
└── src/
    ├── main.ts               Svelte 5 mount()
    ├── App.svelte            top-level shell with simple route switch
    ├── styles/global.css     way2move brand v1 tokens (terracotta + sage + soft gold + Fraunces)
    ├── stores/
    │   └── app.svelte.ts     app-wide state (route, saveFolder handle, cameraIds)
    ├── lib/
    │   ├── types.ts          Session/ExerciseBlock/SetEntry/Recording — mirrors way2move's domain
    │   ├── recorder.ts       camera enumeration, openStreams, canvas composite, MediaRecorder
    │   ├── voice.ts          SpeechRecognition wrapper + speak()/stopSpeaking() TTS
    │   ├── storage.ts        File System Access API: pick root folder, persist via IndexedDB, walk <training>/<date>/<exercise>/, write blob
    │   └── sessionStore.ts   localStorage CRUD for Session[]
    ├── components/
    │   ├── CameraPicker.svelte       3-slot dropdown UI, persists choice
    │   ├── FolderPicker.svelte       pick + remember the save root, re-grant permission on return
    │   ├── CompositeRecorder.svelte  canvas + 3 hidden videos + recorder; emits Blob on stop
    │   ├── RestTimer.svelte          countdown with TTS cues at 10/5/0
    │   └── SetEntryForm.svelte       reps + weight input per set
    └── routes/
        ├── Setup.svelte           CameraPicker + FolderPicker + Continue
        ├── SessionsList.svelte    today's sessions, "+ ad-hoc session" button
        └── ActiveSession.svelte   the heart: state machine prep → recording → rest → exercise_done; voice-coached with TTS+STT
```

## What's stubbed / fake

1. **Session data is hardcoded.** `SessionsList.startNew()` creates a single ad-hoc Session with one ExerciseBlock: "Squats, 5 sets × 8 reps, 90s rest". When way2move's Programs/Sessions Firestore data is wired in, this becomes "load today's planned session from Firestore."
2. **No login.** `userId: "marco"` is hardcoded everywhere. v1 single-user assumption.
3. **No multi-exercise programs.** Active session UI handles next-exercise transitions but only one exercise is ever loaded.
4. **No Firestore.** Sessions persist to `localStorage`. Schema mirrors way2move's `Session`/`Recording`. Migration to Firestore is mechanical: replace `sessionStore.ts` with a Firestore-backed module that has the same exports.
5. **Recordings are NOT yet linked back to set entries in the UI** — the data structure links them (`Recording.setNumber` + `exerciseBlockId`), but there's no "view recordings for set 3" affordance yet.

## Open decisions for you to make

1. **`npm install` ok?** It pulls Svelte 5, Vite 5, TypeScript 5, svelte-check, vite-plugin-svelte, tsconfig/svelte. ~80MB in `node_modules/`. Confirm the version pins in `package.json` are fine.
2. **Lefthook / CI integration**: currently the web-recorder isn't wired into way2move's `lefthook.yml`. Add a hook to run `npm run check` from `frontend/web-recorder/` on commit? Or keep it manual for now?
3. **Firestore migration trigger**: when way2move gets real Firebase credentials, do we (a) immediately port `sessionStore.ts` to Firestore, or (b) wait until the mobile-app version of the recorder also needs the DB? Current bet: defer until mobile recorder lands.
4. **Recording entity location**: when we go to Firestore, the `Recording` field on `Session` should be added to `frontend/mobile/lib/features/sessions/domain/entities/session.dart` (so the Flutter app can read recordings too). Right now my `types.ts` is the only place it's defined. Pick whether the canonical schema lives in the Dart entity (mobile) or a shared schema doc.
5. **Voice command vocabulary**: I implemented "start", "stop", "next", "skip", "repeat", "quit". Anything else worth adding? "redo" (delete last take and re-record)? "log it" (skip the form, accept planned reps)?

## Things to verify when you run it

- [ ] `npm run dev` starts on port 5193 without errors.
- [ ] Setup screen shows; "Detect cameras" lists ≥3 devices including Iriun.
- [ ] After picking 3 cameras + a save folder, "Continue" advances to Sessions list.
- [ ] "Start ad-hoc session" jumps straight into a "Squats, set 1 of 5" view.
- [ ] TTS speaks "Set 1 of 5. Squats. 8 reps. Say start when ready."
- [ ] Saying "start" (or clicking Start) begins recording (canvas glows red).
- [ ] Saying "stop" (or clicking Stop) saves a single composite file under `<root>/<training>/<date>/<exercise>/<HH-MM-SS>.{mp4,webm}` and shows the rest timer.
- [ ] Filling reps + weight + clicking "Log set" appends to `actualSets[]` (visible in `localStorage` under `way2train.sessions.v1`).
- [ ] Cycle through 5 sets → "Finish exercise" → "End session" → returns to sessions list.
- [ ] Closing and reopening the app remembers cameras + folder permission (the latter may need a re-grant click).

## Known limitations / risks

- **MediaRecorder MP4 vs WebM**: Chrome's MP4/H.264 support is fairly recent (~v130). The picker tries MP4 first, falls back to WebM/VP8. Logged automatically; check the browser console.
- **`canvas.captureStream(30)` actual FPS** depends on the slowest camera. If a camera lags, the composite stutters. Test with all 3 cameras attached.
- **TTS interrupts itself** — every `speak()` call cancels the previous utterance. Intentional, but if you want TTS lines to queue, change `voice.ts:speak()` to remove the `cancel()` call.
- **Speech recognition restarts after silence** (Chrome auto-stops). I auto-restart in `voice.ts:VoiceListener.onend` with a 300ms delay — may briefly miss a command at the boundary.
- **No way to delete a take or session from the UI yet.** Do it manually in DevTools by clearing `localStorage`.
- **No offline indicator**, since v1 is offline-first by design. Will become relevant when Firestore lands.

## What's deferred for tomorrow / later

- Wire way2move's real Programs/Sessions data once Firebase is real.
- Write the `Recording` Dart entity in `frontend/mobile/lib/features/sessions/domain/entities/session.dart` to match.
- Add a "session review" screen showing all recordings + actualSets for a finished session.
- Add per-take redo ("redo" voice command).
- Rest timer should auto-advance to next set when it hits zero (configurable).
- Mobile-app version of the recorder (Flutter, on the phone, single camera).
- CI integration (lefthook hook, or whatever way2move standardizes on).
