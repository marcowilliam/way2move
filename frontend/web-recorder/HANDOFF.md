# web-recorder — handoff (2026-04-23 evening)

Picking up tomorrow. **Cameras still showing black.** Everything else is in a coherent state.

---

## TL;DR — first thing to do tomorrow

1. Free `/dev/video0` if `way2sense/main/apps/perception/main.py` grabbed it again:
   ```
   fuser -k /dev/video0
   ```
2. Make sure Iriun is foregrounded on the phone.
3. Start the dev server:
   ```
   cd /projects/my-projects/personal/way2move/main/frontend/web-recorder && npm run dev
   ```
4. Open Chrome at `http://localhost:5193` → gear icon → Settings → pick folder + 3 cameras → Done → Start ad-hoc session.
5. **Open DevTools (F12) → Console tab** — diagnostic `[CompositeRecorder] ...` logs are wired in. Read them. They tell us exactly which step is failing. **Paste them at the start of the next session.**

---

## The bug: composite + thumbnails are all black

### What's confirmed working
- Cameras enumerate (Settings → Detect cameras → 3 distinct devices including Iriun show up).
- Permission is granted.
- Files save to disk with the right names (`rep1.webm`, `rep2.webm`, ...) and folder structure (`<root>/<training>/<date>/<exercise>/`).
- MediaRecorder writes a real (non-empty) WebM, but **the contents are all black** — meaning the canvas itself was black during recording.
- `web_test.html` (the standalone test) **does work** — `/projects/my-projects/personal/way2train/web_test.html` served via `python -m http.server` shows live cameras and saves real video.

### What's broken
- In the Svelte web-recorder, the 3 raw `<video>` thumbnails AND the composite canvas are all black during the active session.
- See `Screenshot from 2026-04-23 22-39-43.png` — black tiles in the brand-faced UI.

### What's been tried
1. **Off-screen positioning** of raw videos (`position: absolute; left: -9999px; width: 1px`) → black. Hypothesis: browser suspends decoding for zero-size or clipped elements. ✗
2. **Visible thumbnail strip** below the composite (3 video tags rendered at real size) → still black. ✗
3. **Switched refs from plain `let` to `$state` slots** (so Svelte 5's `$effect` re-runs when `bind:this` populates them) → user says still not working, but they didn't share the console logs to confirm if `startStreams` even ran. **This is the most important diagnostic gap to close tomorrow.**
4. Added `await v.play()` + `loadeddata` event wait before starting the canvas draw loop. ✗ (or unverified)
5. Added rich `console.log` instrumentation through the whole flow — these logs will reveal which step is dying.

### Most likely remaining causes (in order of probability)
1. **`$effect` still not firing** — Svelte 5 `$state<HTMLVideoElement | undefined>()` slot might not actually be reactive on `bind:this` writes. Need to verify with the console logs. If `[CompositeRecorder] mounted + ids ready` doesn't print, that's it. Workaround: drop `$effect`, call `startStreams` from `onMount` after `tick()`.
2. **`getUserMedia` opens a stream but the device delivers no frames.** This is what happens if `main.py` (way2sense) re-grabs `/dev/video0` between enumeration and open. The device returns a stream object but no data. Check: does `[CompositeRecorder] cam0 playing (0x0)` show up in logs? `0x0` size = stream opened but no frames.
3. **`srcObject` assignment isn't actually attaching the stream** because of a Svelte reactivity quirk with bound DOM refs. Workaround: assign with `videoEl0.srcObject = streams[0]` and immediately `videoEl0.muted = true; videoEl0.autoplay = true; await videoEl0.play()` — verify `videoEl0.srcObject` after assignment.

### How to differentiate (read these console lines)
| What you see | What it means |
|---|---|
| Nothing at all | `$effect` didn't fire — refs/binding broken |
| `mounted + ids ready -> opening streams` then nothing | `openStreams` is hung or threw silently — wrap in `try/catch` |
| `streams opened: [...]` then `cam0 play() rejected` | autoplay policy — needs user gesture; move `startStreams` into a button click |
| `cam0 playing (0x0)` | stream opened with no actual video data — device held by another process |
| `cam0 playing (640x480)` then `loadeddata` then `draw loop started` and STILL black | canvas / drawImage issue. Check the canvas exists and `videoEl0.readyState >= 2` |

---

## What's been built (state of the codebase)

### Repo location
`/projects/my-projects/personal/way2move/main/frontend/web-recorder/` — sibling of `frontend/mobile/`. Svelte 5 + Vite + TypeScript. NOT inside the Flutter codebase.

### File tree (what matters)
```
web-recorder/
├── package.json              Svelte 5, Vite 5, svelte-check, TS 5
├── vite.config.ts            dev server on port 5193
├── tsconfig.json
├── svelte.config.js
├── index.html
├── public/logo/              way2move logo SVGs (mark, wordmark, app-icon — copied from docs/branding/logo)
└── src/
    ├── main.ts               Svelte 5 mount()
    ├── App.svelte            topbar with way2move wordmark + gear icon (Settings)
    ├── styles/global.css     FULL brand v1 token system: exact hex from app_colors.dart, Manrope+Fraunces+JetBrains Mono via Google Fonts, button/pill/card/input recipes from docs/branding/preview.html, motion (280/450/2400ms with WayMotion cubic curves), light-first w/ dark via prefers-color-scheme, breath/breath-glow/fade-rise keyframes
    ├── stores/
    │   └── app.svelte.ts     Tiny app state (route, saveFolder, cameraIds, isCameraReady/isFolderReady/isRecordingReady getters, activeSessionId)
    ├── lib/
    │   ├── types.ts          Session/ExerciseBlock/SetEntry/Recording — mirrors way2move sessions/domain/entities/session.dart
    │   ├── recorder.ts       camera enum, openStreams, canvas composite (NEW: 2x2 layout, 1280x960 4:3), MediaRecorder wrapper
    │   ├── voice.ts          SpeechRecognition (start/stop/skip/repeat/next/quit) + speak()/stopSpeaking() TTS
    │   ├── storage.ts        File System Access API: pick root, persist via IndexedDB, walk <training>/<date>/<exercise>/, write blob (3 levels — project was dropped per Marco's request)
    │   └── sessionStore.ts   localStorage CRUD for Session[]
    ├── components/
    │   ├── CameraPicker.svelte       (uses .card; section header in Settings owns the h3)
    │   ├── FolderPicker.svelte       (same)
    │   ├── CompositeRecorder.svelte  THE BUG IS HERE
    │   ├── RestTimer.svelte          (JetBrains Mono numbers, sage color, breath cues, +10s/Skip/Pause)
    │   └── SetEntryForm.svelte       (reps + weight, sage "Mark set logged" — sage is body-awareness confirmation per brand)
    └── routes/
        ├── Settings.svelte           (X close → home, brand-faced, sectioned cards w/ Ready/Not configured pills)
        ├── SessionsList.svelte       (HOME — shows readiness card linking to settings, today's sessions, "+ ad-hoc")
        └── ActiveSession.svelte      (mirrors way2move session_view header pattern; hero exercise card; "up next" list; conditional CompositeRecorder if isRecordingReady, otherwise "Guided training only" note)
```

### Brand alignment (what's done)
- Verbatim color tokens from `frontend/mobile/lib/core/theme/app_colors.dart` and `docs/branding/brand-identity-plan.md`.
- Real way2move wordmark + mark SVGs in topbar (auto-swaps light/dark with `prefers-color-scheme`).
- Manrope (UI/body) + Fraunces (display) + JetBrains Mono (timer/numbers) via Google Fonts.
- Motion = `WayMotion` (`standard` 280ms, `settled` 450ms, `breath` 2400ms) with the exact cubic curves.
- Light-first with dark via `@media (prefers-color-scheme: dark)` (per brand intent — way2move mobile force-darks during migration but light is the default).
- Component recipes (buttons, pills, inputs, cards) match `docs/branding/preview.html`.

### UX state
- Home = Today's training (was Setup — fixed today).
- Topbar: way2move wordmark (left) + gear icon → Settings (right).
- Home shows a clickable readiness card: "Ready to record" / "Pick a folder to record" / "Cameras off — guided training only" — all link to Settings.
- Settings has X back, brand-faced, sectioned cards.
- Active session: mirrors way2move session_view structure (X close + progress chip header, page title + date, hero exercise card with set counter / exercise name / phase pill, then composite recorder OR "guided only" note, then voice-coached state machine, then Up next list).
- File naming: `rep1.<ext>`, `rep2.<ext>`, with `-take2` suffix on redo (Marco's request — uses "rep" terminology).
- Folder structure: `<root>/<training>/<date>/<exercise>/` (3 levels — project was dropped).
- Cameras are OPTIONAL — guided training works without them.

---

## Decisions persisted in memory

In `/home/marco/.claude/projects/-projects-my-projects-personal-way2move/memory/`:
- `web_recorder_feature.md` — what the feature is, why it's not in Flutter, why it's not a separate repo, the data model addition needed in Flutter sessions
- `brand_design_sources.md` — pointers to brand-identity-plan.md + preview.html + logo SVGs

In `/home/marco/.claude/projects/-projects-my-projects-personal-way2train/memory/`:
- `project_repositioning.md` — way2train repo is now prototype-only; production lives in way2move
- `way2move_stack.md`
- `v1_architecture_decisions.md` — full decision log

---

## What's NOT done (defer or do next)

1. **Fix the black camera bug** ← top priority for next session
2. **Wire real Programs/Sessions data from Firestore** — currently SessionsList.startNew() creates a hardcoded "Foundation — Lower Body" with 3 stub exercises (Squats, Romanian Deadlifts, Walking Lunges). When way2move's Firebase has real credentials, query today's planned session from Firestore.
3. **Add `Recording` entity to Flutter sessions** — `frontend/mobile/lib/features/sessions/domain/entities/session.dart` needs a `recordings: List<Recording>` field, with serialization in `session_model.dart`. Use the Recording shape from `web-recorder/src/lib/types.ts`.
4. **Mobile recorder companion** — eventually the phone records a single camera during training (separate Flutter feature in the same repo).
5. **Lefthook integration** — `way2move/lefthook.yml` doesn't run anything from `frontend/web-recorder/` yet. Add `npm run check` on commit?
6. **Replay during rest** — currently the rest phase shows the timer + set entry form. The "replay last take" affordance from the original Python prototype isn't yet wired in (Marco wanted "replays on resting time").
7. **Camera config UX** — currently CameraPicker has its own h2 inside the card AND Settings wraps it with another section header. Slight redundancy. Cleanup pass needed.
8. **`Way2MoveLogoMark` (the symbol-only "Rooted 2")** — only the wordmark is currently used. The mark could appear as a 24px favicon-style accent next to the wordmark, or as the page favicon (currently the Vite default).

---

## Things to try first when fixing the camera bug

In rough order of cost:

1. **Read the console logs.** They'll tell us exactly where it dies.
2. **Compare with web_test.html** — that file works. Diff the recording flow. The biggest difference: web_test.html uses `getElementById` on top-level video elements, no Svelte reactivity in the loop.
3. **Replace `$effect` with `onMount` + `tick()`** — most defensive. After mount, await tick(), then call startStreams directly. Removes any reactivity gotcha.
4. **Verify the user-gesture trap** — Chrome's autoplay policy may require `play()` to be called within a user gesture (button click). Currently startStreams is triggered by `$effect` which is NOT a user gesture. Workaround: defer stream opening until user clicks "Start set" the first time.
5. **Render videos visibly with explicit width/height attributes** (not CSS). Some browsers gate decoding on the actual `width`/`height` HTML attributes being present.
6. **As a last resort**, fall back to the web_test.html approach exactly: imperative DOM via `getElementById`, no Svelte refs at all.
