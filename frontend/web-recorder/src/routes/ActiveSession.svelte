<script lang="ts">
  import { onMount, onDestroy } from "svelte";
  import CompositeRecorder from "../components/CompositeRecorder.svelte";
  import RestTimer from "../components/RestTimer.svelte";
  import SetEntryForm from "../components/SetEntryForm.svelte";
  import { VoiceListener, speak, stopSpeaking, type VoiceCommand } from "../lib/voice";
  import { saveRecording } from "../lib/storage";
  import { type RecordingResult } from "../lib/recorder";
  import { loadSessions, upsertSession, newId } from "../lib/sessionStore";
  import { app } from "../stores/app.svelte.ts";
  import type { Session, ExerciseBlock, SetEntry, Recording, BodyFeeling } from "../lib/types";

  // UX model: voice-first, one mode at a time. Each exercise is a linear
  // sequence of steps — [set 1, rest 1, set 2, rest 2, ..., set N]. The page
  // shows ONE step's hero at a time (no accordion of everything). A thin
  // step-chip strip at the bottom tracks progress across the exercise.
  type Step =
    | { kind: "set"; n: number; id: string }
    | { kind: "rest"; afterSetN: number; id: string };

  const sessionId = (app as any).activeSessionId as string | undefined;
  let session = $state<Session | null>(loadSessions().find((s) => s.id === sessionId) ?? null);

  // When the user re-opens an in-progress session, resume where they left off
  // (not set 1). Heuristic: find the last recorded set across all blocks, and
  // land on the rest step that follows it. If the last set of the last block
  // is already recorded, stay at that terminal step.
  const resumePoint = (s: Session | null): { blockIdx: number; stepIdx: number } => {
    if (!s) return { blockIdx: 0, stepIdx: 0 };
    const recs = s.recordings ?? [];
    if (recs.length === 0) return { blockIdx: 0, stepIdx: 0 };
    let lastB = -1;
    let lastSet = 0;
    for (let b = 0; b < s.exerciseBlocks.length; b++) {
      const blk = s.exerciseBlocks[b];
      const blkRecs = recs.filter((r) => r.exerciseBlockId === blk.id);
      if (blkRecs.length === 0) continue;
      lastB = b;
      lastSet = Math.max(...blkRecs.map((r) => r.setNumber));
    }
    if (lastB === -1) return { blockIdx: 0, stepIdx: 0 };
    const blk = s.exerciseBlocks[lastB];
    if (lastSet >= blk.plannedSets) {
      if (lastB + 1 < s.exerciseBlocks.length) return { blockIdx: lastB + 1, stepIdx: 0 };
      return { blockIdx: lastB, stepIdx: 2 * blk.plannedSets - 2 };
    }
    // Step index map for a block with N sets: set1=0, rest1=1, set2=2, rest2=3...
    // So "rest after set K" = 2*(K-1) + 1.
    return { blockIdx: lastB, stepIdx: 2 * (lastSet - 1) + 1 };
  };
  const _resume = resumePoint(session);
  let blockIdx = $state(_resume.blockIdx);
  let stepIdx = $state(_resume.stepIdx);

  const block = $derived<ExerciseBlock | null>(session?.exerciseBlocks[blockIdx] ?? null);
  const steps = $derived<Step[]>(() => {
    if (!block) return [];
    const out: Step[] = [];
    for (let n = 1; n <= block.plannedSets; n++) {
      out.push({ kind: "set", n, id: `set-${n}` });
      if (n < block.plannedSets) out.push({ kind: "rest", afterSetN: n, id: `rest-${n}` });
    }
    return out;
  });
  const currentStep = $derived<Step | null>(steps()[stepIdx] ?? null);
  const isLastBlock = $derived(session ? blockIdx >= session.exerciseBlocks.length - 1 : false);
  const isLastStep = $derived(stepIdx >= steps().length - 1);
  const activeSetN = $derived<number>(
    currentStep
      ? currentStep.kind === "set"
        ? currentStep.n
        : currentStep.afterSetN
      : 1,
  );

  type RecState = "idle" | "recording";
  let recState = $state<RecState>("idle");
  let recorderRef: { start: () => void; stop: () => Promise<void> } | undefined = $state();
  let lastBlobUrl = $state<string | null>(null);

  // Finalization (review & save) state ——————————————————————————————
  // Triggered at end-of-session OR via the "Finish" topbar button. Shows a
  // dedicated review panel where the athlete rates, checks in with their
  // body, and optionally dictates notes.
  // If the session is ALREADY completed (user clicked "Review" from the
  // dashboard), we start directly in the finalization panel — resuming
  // the training flow would be wrong, it's already done.
  let finalizing = $state(session?.status === "completed");
  let finalRpe = $state<number | null>(null);
  let finalBody = $state<BodyFeeling | null>(null);
  let finalNotes = $state<string>("");
  // Web Speech Recognition for note dictation — separate from the command
  // listener (which matches start/stop/next/previous).
  let dictating = $state(false);
  let dictationInterim = $state("");
  let dictationRec: any = null;
  let dictationError = $state<string | null>(null);

  // When the session changes (edit, new recording), seed finalization fields
  // so the user's prior review values are preserved on re-open.
  $effect(() => {
    if (!session || finalizing) return;
    if (finalRpe === null && session.rpe != null) finalRpe = session.rpe;
    if (finalBody === null && session.bodyFeeling) finalBody = session.bodyFeeling;
    if (!finalNotes && session.notes) finalNotes = session.notes;
  });

  // Elapsed timer during recording — useful especially for time-based
  // (isometric) sets so the athlete knows how long they've held the effort.
  let recordingStartedAt = $state<number | null>(null);
  let recordingElapsedSec = $state(0);
  let elapsedTicker: ReturnType<typeof setInterval> | null = null;
  const fmtElapsed = (s: number): string => {
    const m = Math.floor(s / 60);
    const r = s % 60;
    return `${m}:${r.toString().padStart(2, "0")}`;
  };
  // Session duration in the athlete's mental unit — hours + minutes for
  // longer trainings ("3h47m"), bare minutes below an hour ("47m").
  const fmtHrMin = (mins: number | null | undefined): string => {
    if (mins == null || mins <= 0) return "0m";
    if (mins < 60) return `${mins}m`;
    const h = Math.floor(mins / 60);
    const m = mins % 60;
    return m === 0 ? `${h}h` : `${h}h${m}m`;
  };

  // Existing entry for the current set (if any). Used to pre-populate the
  // log form — values flow set screen → rest screen automatically because
  // both read from block.actualSets.
  const entryFor = (n: number) =>
    block?.actualSets.find((s) => s.setNumber === n);

  let voice: VoiceListener | null = null;
  let voiceListening = $state(false);
  let voiceTranscript = $state<string>("");
  let voiceError = $state<string | null>(null);

  const prettyDate = (iso: string): string => {
    const d = new Date(iso + "T00:00:00");
    return d.toLocaleDateString("en-US", { weekday: "long", month: "long", day: "numeric" });
  };

  const takesForSet = (n: number): number =>
    session && block ? session.recordings.filter((r) => r.exerciseBlockId === block.id && r.setNumber === n).length : 0;

  const loggedForSet = (n: number): boolean =>
    !!block?.actualSets.some((s) => s.setNumber === n);

  const onCommand = (cmd: VoiceCommand) => {
    if (cmd === "start") onStart();
    else if (cmd === "stop") onStop();
    else if (cmd === "next" || cmd === "skip") nextStep();
    else if (cmd === "previous") prevStep();
  };

  const enableVoice = () => {
    if (!VoiceListener.isSupported()) { voiceError = "Voice not supported (use Chrome)"; return; }
    voice = new VoiceListener({
      onCommand,
      onTranscript: (t) => { voiceTranscript = t; },
      onError: (e) => { voiceError = e; },
      onStateChange: (l) => { voiceListening = l; },
    });
    voice.start();
  };
  const disableVoice = () => { voice?.stop(); voice = null; voiceListening = false; };

  $effect(() => {
    if (finalizing) return;
    if (!block || !currentStep) return;
    stopSpeaking();
    if (currentStep.kind === "set") {
      speak(`Set ${currentStep.n} of ${block.plannedSets}. ${block.exerciseName}. ${block.plannedReps} reps. Say start when ready.`);
    } else {
      speak(`Rest ${block.restSeconds} seconds. Log your reps.`);
    }
  });

  const onStart = () => {
    if (!currentStep || currentStep.kind !== "set") return;
    if (recState === "recording") return;
    stopSpeaking();
    if (app.isRecordingReady && recorderRef) {
      recorderRef.start();
      speak("Recording.");
    } else {
      speak("Go.");
    }
    recState = "recording";
    recordingStartedAt = Date.now();
    recordingElapsedSec = 0;
    elapsedTicker = setInterval(() => {
      if (recordingStartedAt != null) {
        recordingElapsedSec = Math.floor((Date.now() - recordingStartedAt) / 1000);
      }
    }, 250);
  };

  const onStop = async () => {
    if (recState !== "recording") return;
    if (elapsedTicker) { clearInterval(elapsedTicker); elapsedTicker = null; }
    recordingStartedAt = null;
    if (app.isRecordingReady && recorderRef) {
      await recorderRef.stop();
      speak("Stopped.");
    } else {
      speak("Done.");
    }
    recState = "idle";
    nextStep();
  };

  const onRecorded = async (r: RecordingResult) => {
    if (!session || !block || !app.saveFolder || !currentStep || currentStep.kind !== "set") return;
    const setN = currentStep.n;
    const takeNumber = takesForSet(setN) + 1;
    const baseName = `rep${setN}`;
    const fileName = takeNumber === 1 ? `${baseName}.${r.ext}` : `${baseName}-take${takeNumber}.${r.ext}`;
    const path = await saveRecording(
      app.saveFolder,
      { training: session.focus ?? session.type, date: session.date, exercise: block.exerciseName, fileName },
      r.blob,
    );
    const rec: Recording = {
      id: newId(),
      exerciseBlockId: block.id,
      setNumber: setN,
      takeNumber,
      localPath: path,
      fileName,
      mimeType: r.mimeType,
      durationSec: Math.round(r.durationMs / 1000),
      recordedAt: new Date().toISOString(),
    };
    session.recordings = [...session.recordings, rec];
    upsertSession($state.snapshot(session));

    if (lastBlobUrl) URL.revokeObjectURL(lastBlobUrl);
    lastBlobUrl = URL.createObjectURL(r.blob);
  };

  const logSet = (entry: SetEntry) => {
    if (!session || !block) return;
    const existingIdx = block.actualSets.findIndex((s) => s.setNumber === entry.setNumber);
    if (existingIdx >= 0) block.actualSets[existingIdx] = entry;
    else block.actualSets = [...block.actualSets, entry];
    upsertSession($state.snapshot(session));
  };

  // Open the finalization (review & save) panel. Pauses the voice command
  // listener so dictation doesn't fight with the recognizer.
  const startFinalize = () => {
    if (!session) return;
    stopSpeaking();
    voice?.stop();
    voice = null;
    finalizing = true;
  };

  const cancelFinalize = () => {
    stopDictation();
    // For an already-completed session being reviewed, "cancel" means
    // "leave without saving changes" → back to dashboard. Don't fall into
    // the training flow for a session that's already done.
    if (session?.status === "completed") {
      app.goto("sessions");
      return;
    }
    finalizing = false;
    if (!voice) enableVoice();
  };

  const saveFinalize = () => {
    if (!session) return;
    stopDictation();
    const wasCompleted = session.status === "completed";
    session.notes = finalNotes.trim() || undefined;
    session.rpe = finalRpe ?? undefined;
    session.bodyFeeling = finalBody ?? undefined;
    session.status = "completed";
    // Preserve the original completedAt / durationMinutes on re-save.
    if (!wasCompleted) {
      session.completedAt = new Date().toISOString();
      if (session.startedAt) {
        session.durationMinutes = Math.max(
          1,
          Math.round((new Date(session.completedAt).getTime() - new Date(session.startedAt).getTime()) / 60000),
        );
      }
    }
    upsertSession($state.snapshot(session));
    speak(wasCompleted ? "Changes saved." : "Session saved.");
    app.goto("sessions");
  };

  // Voice dictation (separate from the command listener — this one streams
  // interim text into the notes field).
  const startDictation = () => {
    const SR = (window as any).SpeechRecognition || (window as any).webkitSpeechRecognition;
    if (!SR) { dictationError = "Voice dictation needs Chrome/Edge."; return; }
    dictationError = null;
    const rec = new SR();
    rec.continuous = true;
    rec.interimResults = true;
    rec.lang = "en-US";
    rec.onresult = (ev: any) => {
      let interim = "";
      let finalChunk = "";
      for (let i = ev.resultIndex; i < ev.results.length; i++) {
        const r = ev.results[i];
        if (r.isFinal) finalChunk += r[0].transcript;
        else interim += r[0].transcript;
      }
      if (finalChunk) {
        const sep = finalNotes && !/\s$/.test(finalNotes) ? " " : "";
        finalNotes = finalNotes + sep + finalChunk.trim();
      }
      dictationInterim = interim;
    };
    rec.onerror = (ev: any) => { dictationError = ev.error ?? "dictation error"; };
    rec.onend = () => { dictating = false; dictationInterim = ""; };
    rec.start();
    dictationRec = rec;
    dictating = true;
  };

  const stopDictation = () => {
    dictationRec?.stop();
    dictationRec = null;
    dictating = false;
    dictationInterim = "";
  };

  const nextStep = () => {
    if (!session) return;
    if (stepIdx < steps().length - 1) { stepIdx++; return; }
    if (isLastBlock) { startFinalize(); return; }
    blockIdx++;
    stepIdx = 0;
  };

  const prevStep = () => {
    if (stepIdx > 0) { stepIdx--; return; }
    if (blockIdx > 0) { blockIdx--; stepIdx = Math.max(0, steps().length - 1); }
  };

  const jumpTo = (i: number) => {
    if (recState === "recording") return;
    if (i < 0 || i >= steps().length) return;
    stepIdx = i;
  };

  const stepStatus = (i: number): "done" | "active" | "upcoming" => {
    if (i < stepIdx) return "done";
    if (i === stepIdx) return "active";
    return "upcoming";
  };

  const chipLabel = (step: Step): string =>
    step.kind === "set" ? `Set ${step.n}` : `Rest ${step.afterSetN}`;

  // Block-level timeline. Status is derived from the data (sets logged vs.
  // planned) so jumping back to a done block doesn't change what "current"
  // means — the first non-completed block is always the current one.
  const firstUnfinishedBlockIdx = $derived.by(() => {
    if (!session) return 0;
    for (let i = 0; i < session.exerciseBlocks.length; i++) {
      const blk = session.exerciseBlocks[i];
      if (blk.actualSets.length < blk.plannedSets) return i;
    }
    return session.exerciseBlocks.length - 1;
  });

  type BlockStatus = "completed" | "current" | "upcoming";
  const blockStatus = (i: number): BlockStatus => {
    if (!session) return "upcoming";
    const blk = session.exerciseBlocks[i];
    if (blk.actualSets.length >= blk.plannedSets) return "completed";
    if (i === firstUnfinishedBlockIdx) return "current";
    return "upcoming";
  };

  // Data-derived "furthest position reached" in the training flow. Independent
  // of the user's viewing position (blockIdx/stepIdx) — it's computed from
  // what's been logged. The progress bar reads from this so jumping back to
  // a done exercise doesn't wind progress back to 0%.
  const furthestPosition = $derived.by<{ blockIdx: number; stepIdx: number }>(() => {
    if (!session) return { blockIdx: 0, stepIdx: 0 };
    const blocks = session.exerciseBlocks;
    for (let b = blocks.length - 1; b >= 0; b--) {
      const blk = blocks[b];
      if (blk.actualSets.length === 0) continue;
      const k = blk.actualSets.length;
      if (k >= blk.plannedSets) {
        if (b + 1 < blocks.length) return { blockIdx: b + 1, stepIdx: 0 };
        return { blockIdx: b, stepIdx: Math.max(0, 2 * blk.plannedSets - 2) };
      }
      // Partially done: rest after set k = step index 2*(k-1) + 1.
      return { blockIdx: b, stepIdx: 2 * (k - 1) + 1 };
    }
    return { blockIdx: 0, stepIdx: 0 };
  });

  const jumpToBlock = (i: number) => {
    if (recState === "recording") return;
    if (!session) return;
    if (i < 0 || i >= session.exerciseBlocks.length) return;
    if (i === blockIdx) return;
    const status = blockStatus(i);
    if (status === "upcoming") return; // no skipping ahead
    const blk = session.exerciseBlocks[i];
    blockIdx = i;
    // Land where training actually left off in that block:
    //   - completed block → on the last set (the end state the user left)
    //   - current block  → on the furthest step reached in this block
    if (status === "completed") {
      stepIdx = Math.max(0, 2 * blk.plannedSets - 2);
    } else {
      stepIdx = furthestPosition.blockIdx === i ? furthestPosition.stepIdx : 0;
    }
  };

  // Per-exercise progress for the top strip. Session-wide progress lives in
  // the left timeline; this bar tracks only the block the user is viewing.
  const totalStepsInBlock = $derived(
    block ? Math.max(1, 2 * block.plannedSets - 1) : 0,
  );
  const stepsCompletedInBlock = $derived.by(() => {
    if (!session || !block) return 0;
    const { blockIdx: fb, stepIdx: fs } = furthestPosition;
    if (fb > blockIdx) return totalStepsInBlock; // fully done, viewing from later
    if (fb === blockIdx) return Math.min(fs, totalStepsInBlock);
    return 0; // furthest is earlier — shouldn't happen for a reachable block
  });
  const blockPercentDone = $derived(
    totalStepsInBlock > 0
      ? Math.round((stepsCompletedInBlock / totalStepsInBlock) * 100)
      : 0,
  );
  const totalBlocks = $derived(session?.exerciseBlocks.length ?? 0);

  onMount(() => {
    // Don't enable voice commands when we land directly in the review panel
    // (completed session). Dictation inside the panel uses its own recognizer.
    if (!finalizing) enableVoice();
  });
  onDestroy(() => {
    disableVoice();
    stopDictation();
    stopSpeaking();
    if (elapsedTicker) clearInterval(elapsedTicker);
    if (lastBlobUrl) URL.revokeObjectURL(lastBlobUrl);
  });
</script>

{#if !session || !block}
  <div class="page">
    <p>Session not found.</p>
    <button onclick={() => app.goto("sessions")}>Back</button>
  </div>
{:else}
  <div class="page" data-mode={currentStep?.kind === "rest" ? "rest" : (recState === "recording" ? "rec" : "set")}>

    <!-- Top bar: exit · exercise title+set · mode badge · voice state.
         When finalizing, collapse to a minimal "Session review" title so
         stale mid-session labels (like "Set 2 · Resting") don't peek
         through behind the review panel. -->
    <header class="topbar">
      <button class="ghost icon" onclick={() => app.goto("sessions")} aria-label="Exit session">×</button>
      {#if finalizing}
        <div class="topbar-title">
          <span class="ex-name">{session.focus ?? "Training"}</span>
          <span class="ex-sep dim">·</span>
          <span class="ex-set dim">
            {session.status === "completed" ? "Review" : "Finishing"}
          </span>
        </div>
        <div class="topbar-right">
          {#if session.status === "completed"}
            <span class="pill pill-sage mode-pill">Completed</span>
          {/if}
        </div>
      {:else}
        <div class="topbar-title">
          {#if session.focus}
            <span class="session-focus">{session.focus}</span>
          {:else}
            <span class="session-focus dim">Training</span>
          {/if}
        </div>
        <div class="topbar-right">
          {#if currentStep?.kind === "rest"}
            <span class="pill pill-sage mode-pill">Resting</span>
          {:else if recState === "recording"}
            <span class="pill mode-pill rec"><span class="rec-dot"></span>Recording</span>
          {:else}
            <span class="pill pill-outline mode-pill">Working set</span>
          {/if}
          {#if voiceListening}
            <span class="pill pill-sage voice-pill" title={voiceTranscript}>
              <span class="voice-dot"></span>listening
            </span>
          {/if}
          <button
            class="ghost finish-btn"
            onclick={startFinalize}
            disabled={recState === "recording"}
            title="Review and save the session"
          >Finish</button>
        </div>
      {/if}
    </header>

    {#if finalizing}
      {@const totalSetsLogged = session.exerciseBlocks.reduce((sum, b) => sum + b.actualSets.length, 0)}
      {@const totalSetsPlanned = session.exerciseBlocks.reduce((sum, b) => sum + b.plannedSets, 0)}
      {@const endMs = session.completedAt ? new Date(session.completedAt).getTime() : Date.now()}
      {@const sessionMinutes = session.durationMinutes ?? (session.startedAt ? Math.max(1, Math.round((endMs - new Date(session.startedAt).getTime()) / 60000)) : 0)}
      {@const isReviewing = session.status === "completed"}

      <!-- Finalization: review & save. Sage-check hero (body-awareness
           confirmation per brand), rating + body check-in + notes with
           voice dictation, per-exercise summary, save CTA. -->
      <section class="finalize">
        <div class="check-hero">
          <div class="sage-check" aria-hidden="true">
            <svg viewBox="0 0 44 44" width="44" height="44">
              <circle cx="22" cy="22" r="20" fill="none" stroke="currentColor" stroke-width="1.8" opacity="0.3"/>
              <path d="M13 22.5 L19.5 29 L31 16" fill="none" stroke="currentColor" stroke-width="3" stroke-linecap="round" stroke-linejoin="round"/>
            </svg>
          </div>
          <div class="check-title-block">
            <p class="label-xs">{isReviewing ? "Review" : "Review and save"}</p>
            <h1 class="finalize-title">{session.focus ?? "Training"} — done.</h1>
            {#if isReviewing && session.completedAt}
              <p class="finalize-sub text-secondary">
                Completed {new Date(session.completedAt).toLocaleString("en-US", { weekday: "short", month: "short", day: "numeric", hour: "numeric", minute: "2-digit" })}
              </p>
            {/if}
          </div>
        </div>

        <dl class="summary-stats">
          <div class="stat">
            <dt class="stat-lab">exercises</dt>
            <dd class="stat-num mono">{session.exerciseBlocks.length}</dd>
          </div>
          <div class="stat">
            <dt class="stat-lab">sets</dt>
            <dd class="stat-num mono">{totalSetsLogged}<span class="stat-of">/{totalSetsPlanned}</span></dd>
          </div>
          <div class="stat">
            <dt class="stat-lab">takes</dt>
            <dd class="stat-num mono">{session.recordings.length}</dd>
          </div>
          <div class="stat">
            <dt class="stat-lab">duration</dt>
            <dd class="stat-num mono">{fmtHrMin(sessionMinutes)}</dd>
          </div>
        </dl>

        <!-- RPE rating (1-10) — brand: calm, no emoji, no celebration -->
        <section class="f-section">
          <p class="label-xs">How did it feel?</p>
          <div class="rpe-scale" role="radiogroup" aria-label="Rate of perceived exertion">
            {#each [1,2,3,4,5,6,7,8,9,10] as n}
              <button
                type="button"
                class="rpe-chip"
                class:active={finalRpe === n}
                data-zone={n <= 3 ? "easy" : n <= 7 ? "moderate" : "hard"}
                aria-pressed={finalRpe === n}
                onclick={() => (finalRpe = n)}
              >{n}</button>
            {/each}
          </div>
          <div class="rpe-anchors">
            <span>easy</span><span>moderate</span><span>hard</span>
          </div>
        </section>

        <!-- Body check-in — words, not emoji (brand is physio's office). -->
        <section class="f-section">
          <p class="label-xs">Body check-in</p>
          <div class="feeling-row" role="radiogroup" aria-label="Body feeling">
            {#each ["calm","neutral","fatigued","depleted"] as f (f)}
              <button
                type="button"
                class="feeling-chip"
                class:active={finalBody === f}
                aria-pressed={finalBody === f}
                onclick={() => (finalBody = f as BodyFeeling)}
              >{f}</button>
            {/each}
          </div>
        </section>

        <!-- Notes + voice dictation. Separate recognizer from command voice. -->
        <section class="f-section">
          <p class="label-xs">Notes</p>
          <div class="notes-wrap">
            <textarea
              class="notes-area"
              bind:value={finalNotes}
              placeholder="How was the session? Anything to remember for next time."
              rows="4"
            ></textarea>
            {#if dictationInterim}
              <p class="dictation-interim">…{dictationInterim}</p>
            {/if}
            <div class="notes-actions">
              <button
                type="button"
                class="dictate-btn"
                class:active={dictating}
                onclick={() => (dictating ? stopDictation() : startDictation())}
              >
                <span class="mic-dot" aria-hidden="true"></span>
                {dictating ? "Listening · tap to stop" : "Dictate with voice"}
              </button>
              {#if dictationError}
                <span class="dictation-error">{dictationError}</span>
              {/if}
            </div>
          </div>
        </section>

        <!-- Per-exercise summary — sage dots confirm body-level awareness. -->
        <section class="f-section">
          <p class="label-xs">Per exercise</p>
          <ul class="ex-summary">
            {#each session.exerciseBlocks as b (b.id)}
              {@const takes = session.recordings.filter((r) => r.exerciseBlockId === b.id).length}
              {@const isComplete = b.actualSets.length >= b.plannedSets}
              <li class="ex-row" class:complete={isComplete}>
                <span class="ex-dot" aria-hidden="true"></span>
                <span class="ex-name">{b.exerciseName}</span>
                <span class="ex-stats mono">
                  {b.actualSets.length}/{b.plannedSets} sets · {takes} take{takes === 1 ? "" : "s"}
                </span>
              </li>
            {/each}
          </ul>
        </section>

        <footer class="finalize-cta">
          {#if isReviewing}
            <button class="ghost" onclick={cancelFinalize}>← Back to home</button>
            <button class="big primary" onclick={saveFinalize}>Save changes</button>
          {:else}
            <button class="ghost" onclick={cancelFinalize}>← Keep training</button>
            <button class="big primary" onclick={saveFinalize}>Save and close</button>
          {/if}
        </footer>
      </section>

    {:else}

    <!-- Session layout: left rail timeline of all exercises (when > 1 block)
         + main column (current-exercise progress + hero). -->
    <div class="session-layout" data-has-timeline={session.exerciseBlocks.length > 1}>

    {#if session.exerciseBlocks.length > 1}
      <aside class="block-timeline" aria-label="All exercises in this session">
        <h3 class="block-timeline-title">Exercises</h3>
        <ol class="block-rail">
          {#each session.exerciseBlocks as b, i (b.id)}
            {@const status = blockStatus(i)}
            {@const isViewing = i === blockIdx}
            {@const clickable = status !== "upcoming" && recState !== "recording"}
            <li class="block-node" data-status={status} data-viewing={isViewing}>
              <button
                type="button"
                class="block-btn"
                onclick={() => jumpToBlock(i)}
                disabled={!clickable || isViewing}
                aria-current={isViewing ? "step" : undefined}
                title={status === "upcoming" ? "Reach this exercise first" : b.exerciseName}
              >
                <span class="block-marker" aria-hidden="true">
                  {#if status === "completed"}
                    <svg viewBox="0 0 14 14" width="10" height="10" aria-hidden="true">
                      <path d="M2 7.5 L6 11 L12 3.5" fill="none" stroke="currentColor" stroke-width="2.2" stroke-linecap="round" stroke-linejoin="round"/>
                    </svg>
                  {:else if status === "current"}
                    <span class="block-dot"></span>
                  {:else}
                    <span class="block-num">{i + 1}</span>
                  {/if}
                </span>
                <span class="block-body">
                  <span class="block-name">{b.exerciseName}</span>
                  <span class="block-meta mono">
                    {b.actualSets.length}/{b.plannedSets} sets
                    {#if b.defaultEffortKind === "time" && b.plannedSeconds}
                      · {b.plannedSeconds}s
                    {:else}
                      · {b.plannedReps} reps
                    {/if}
                  </span>
                </span>
              </button>
            </li>
          {/each}
        </ol>
      </aside>
    {/if}

    <div class="session-main">

    <!-- Progress strip — anchored to the CURRENT exercise. Full-session
         progress lives in the left timeline; this bar tracks only the
         exercise the user is viewing. Header: exercise title + set
         position (left), fraction + percent (right). -->
    <section class="progress-strip" aria-label="Exercise progress">
      <div class="strip-head">
        <div class="strip-title">
          <h2 class="strip-ex-name">{block.exerciseName}</h2>
          <div class="strip-meta">
            <span class="strip-position">
              Set <span class="mono">{activeSetN}</span> <span class="dim">of</span> <span class="mono">{block.plannedSets}</span>
            </span>
            {#if totalBlocks > 1}
              <span class="strip-sep" aria-hidden="true">·</span>
              <span class="strip-block dim">
                Exercise <span class="mono">{blockIdx + 1}</span><span class="dim">/</span><span class="mono">{totalBlocks}</span>
              </span>
            {/if}
          </div>
        </div>
        <div class="strip-progress">
          <span class="progress-pct mono">{blockPercentDone}%</span>
          <span class="mono progress-fraction">{stepsCompletedInBlock}/{totalStepsInBlock}</span>
        </div>
      </div>

      <div class="progress-bar">
        <div class="progress-fill" style="width: {blockPercentDone}%"></div>
      </div>

      <nav class="chip-track" aria-label="Steps of this exercise">
        {#each steps() as step, i (step.id)}
          {@const status = stepStatus(i)}
          {@const isBlocked = status === "upcoming" || (recState === "recording" && i !== stepIdx)}
          <button
            type="button"
            class="chip"
            data-status={status}
            data-kind={step.kind}
            onclick={() => jumpTo(i)}
            disabled={isBlocked}
            aria-current={i === stepIdx ? "step" : undefined}
            title={status === "upcoming" ? "Finish the current step first" : chipLabel(step)}
          >
            <span class="chip-mark" aria-hidden="true">
              {#if status === "done"}✓
              {:else if status === "active"}<span class="chip-dot"></span>
              {:else}<span class="chip-empty-dot"></span>{/if}
            </span>
            <span class="chip-label">{chipLabel(step)}</span>
            {#if status === "active"}<span class="chip-now">now</span>{/if}
            {#if status === "done" && step.kind === "set"}
              <span class="chip-meta mono">{takesForSet(step.n)}×{loggedForSet(step.n) ? "·✓" : ""}</span>
            {/if}
          </button>
        {/each}
      </nav>
    </section>

    <!-- Hero: videos on top (full width, consistent between set and rest),
         info + log cards in a 2-up row below. CTA under the frame. -->
    <main class="hero">
      <div class="videos-strip">
        {#if currentStep?.kind === "set"}
          {#if app.isRecordingReady}
            <CompositeRecorder
              bind:this={recorderRef}
              selectedDeviceIds={app.cameraIds}
              {onRecorded}
            />
          {:else}
            <div class="no-camera-note">
              <p class="text-secondary">
                <strong>Guided training only</strong> — no recording.
                <button class="link-inline" onclick={() => app.goto("settings")}>Configure cameras</button>
                to enable replay between sets.
              </p>
            </div>
          {/if}
        {:else if lastBlobUrl}
          <div class="replay-row">
            <div class="replay-tile">
              <video class="tile-video tile-0" src={lastBlobUrl} autoplay loop muted playsinline></video>
              <span class="tile-label">Cam 1</span>
            </div>
            <div class="replay-tile">
              <video class="tile-video tile-1" src={lastBlobUrl} autoplay loop muted playsinline></video>
              <span class="tile-label">Cam 2</span>
            </div>
            <div class="replay-tile">
              <video class="tile-video tile-2" src={lastBlobUrl} autoplay loop muted playsinline></video>
              <span class="tile-label">Cam 3</span>
            </div>
          </div>
        {:else}
          <div class="replay-empty">
            <p class="text-secondary">
              {app.isRecordingReady ? "No take recorded for this set." : "Cameras not configured — guided rest only."}
            </p>
          </div>
        {/if}
      </div>

      <div class="cards-strip">
        {#if currentStep?.kind === "set"}
          <!-- Left card: status / elapsed timer during recording. -->
          <div class="info-card" class:recording={recState === "recording"}>
            {#if recState === "recording"}
              <p class="small-label recording-label"><span class="rec-dot"></span>Recording</p>
              <div class="info-main">
                <span class="info-big elapsed">{fmtElapsed(recordingElapsedSec)}</span>
              </div>
              <p class="info-sub">
                target:
                {#if (block.defaultEffortKind ?? "reps") === "time"}
                  {block.plannedSeconds ?? "—"}s
                {:else}
                  {block.plannedReps} reps
                {/if}
                {#if block.plannedWeight} @ {block.plannedWeight}kg{/if}
              </p>
            {:else}
              <p class="small-label">Working · set {currentStep.n} of {block.plannedSets}</p>
              <div class="info-main">
                {#if (block.defaultEffortKind ?? "reps") === "time"}
                  <span class="info-big">{block.plannedSeconds ?? "—"}</span>
                  <span class="info-unit">sec</span>
                {:else}
                  <span class="info-big">{block.plannedReps}</span>
                  <span class="info-unit">reps</span>
                {/if}
              </div>
              <p class="info-sub">
                {block.restSeconds}s rest after ·
                {takesForSet(currentStep.n)} take{takesForSet(currentStep.n) === 1 ? "" : "s"} recorded
              </p>
            {/if}
          </div>

          <!-- Right card: log form (always visible — it's the plan before
               recording and the actuals after). -->
          <div class="info-card">
            <SetEntryForm
              setNumber={currentStep.n}
              defaultKind={block.defaultEffortKind ?? "reps"}
              plannedReps={block.plannedReps}
              plannedSeconds={block.plannedSeconds}
              plannedWeight={block.plannedWeight}
              initial={entryFor(currentStep.n)}
              onSave={logSet}
            />
          </div>

        {:else}
          <div class="info-card timer">
            <p class="small-label">Resting</p>
            <RestTimer
              seconds={block.restSeconds}
              onDone={() => speak("Rest over. Get ready.")}
            />
          </div>

          <div class="info-card">
            <SetEntryForm
              setNumber={currentStep.afterSetN}
              defaultKind={block.defaultEffortKind ?? "reps"}
              plannedReps={block.plannedReps}
              plannedSeconds={block.plannedSeconds}
              plannedWeight={block.plannedWeight}
              initial={entryFor(currentStep.afterSetN)}
              onSave={logSet}
            />
          </div>
        {/if}
      </div>

      <div class="cta-row">
        {#if currentStep?.kind === "set"}
          {#if recState === "idle"}
            <button class="big primary" onclick={onStart}>
              {takesForSet(currentStep.n) > 0 ? "Record another take" : "Start set"}
            </button>
            <span class="text-secondary voice-hint">or say <em>"start"</em></span>
          {:else}
            <button class="big ghost" onclick={onStop}>Stop set</button>
            <span class="text-secondary voice-hint">or say <em>"stop"</em></span>
          {/if}
        {:else}
          <button class="big primary" onclick={nextStep}>
            {isLastStep && isLastBlock ? "Finish session" : `Next set → (set ${currentStep.afterSetN + 1})`}
          </button>
          <span class="text-secondary voice-hint">or say <em>"next"</em></span>
        {/if}
      </div>
    </main>

    </div><!-- /session-main -->
    </div><!-- /session-layout -->
    {/if}

    <footer class="session-footer">
      <div class="footer-meta">
        <span class="text-secondary">{prettyDate(session.date)}</span>
        {#if session.focus}<span class="text-secondary">· {session.focus}</span>{/if}
      </div>
      {#if voiceError}<span class="error-line">voice: {voiceError}</span>{/if}
      {#if voiceTranscript}<span class="text-secondary heard">heard: "{voiceTranscript}"</span>{/if}
    </footer>
  </div>
{/if}

<style>
  .page {
    max-width: 1200px;
    width: 100%;
    margin: 0 auto;
    padding: 16px 24px 40px;
    display: flex;
    flex-direction: column;
    gap: 18px;
  }

  /* Topbar */
  .topbar {
    display: grid;
    grid-template-columns: auto 1fr auto;
    gap: 14px;
    align-items: center;
    animation: fade-rise var(--motion-settled) var(--easing-settled) both;
  }
  .ghost.icon {
    width: 40px; height: 40px; padding: 0;
    border-radius: 50%;
    font-size: 22px; line-height: 1;
  }
  .topbar-title {
    display: flex; align-items: baseline; gap: 8px;
    min-width: 0;
    overflow: hidden; text-overflow: ellipsis; white-space: nowrap;
  }
  .ex-name {
    font-family: var(--font-display);
    font-size: 26px;
    font-weight: 700;
    letter-spacing: -0.2px;
  }
  .ex-sep { color: var(--text-secondary); }
  .ex-set {
    font-family: var(--font-mono);
    font-size: 15px;
    color: var(--text);
    font-variant-numeric: tabular-nums;
  }
  .topbar-right { display: flex; gap: 8px; align-items: center; flex-wrap: wrap; }
  .mode-pill { letter-spacing: 0.04em; text-transform: uppercase; font-size: 11px; }
  .mode-pill.rec {
    background: var(--accent, #BE4A3A);
    color: #F5EFE7;
    border: none;
    display: inline-flex; align-items: center; gap: 6px;
    animation: breath var(--motion-breath) ease-in-out infinite;
  }
  .rec-dot {
    width: 7px; height: 7px; border-radius: 50%;
    background: #F5EFE7;
  }
  .voice-pill { padding: 4px 10px; }
  .voice-dot {
    width: 7px; height: 7px; border-radius: 50%;
    background: var(--accent);
    animation: breath var(--motion-breath) ease-in-out infinite;
  }

  /* Hero */
  .hero {
    display: flex;
    flex-direction: column;
    gap: 20px;
    padding: 20px;
    background: var(--surface);
    border: 1px solid var(--border);
    border-radius: var(--radius-card);
    animation: fade-rise var(--motion-settled) var(--easing-settled) both;
    transition: border-color var(--motion-settled) var(--easing-settled);
  }
  .page[data-mode="rec"] .hero {
    border-color: var(--accent, #BE4A3A);
    box-shadow: 0 0 0 1px rgba(190, 74, 58, 0.18);
  }
  .page[data-mode="rest"] .hero {
    border-color: var(--sage, #6B8E7B);
  }

  .cta-row {
    display: flex;
    gap: 14px;
    flex-wrap: wrap;
    align-items: center;
  }
  .voice-hint { font-size: 13px; }
  .voice-hint em { font-style: italic; color: var(--text); }

  .no-camera-note {
    background: var(--surface-raised);
    border-radius: var(--radius-card);
    border: 1px dashed var(--border);
    padding: 16px 20px;
  }
  .no-camera-note p { font-size: 14px; margin: 0; }
  .link-inline {
    background: transparent; color: var(--primary);
    border: none; padding: 0;
    font-size: inherit;
    text-decoration: underline;
    font-weight: 600;
    display: inline;
  }
  .link-inline:hover { background: transparent; color: var(--primary-pressed); }

  .small-label {
    font-size: 11px;
    letter-spacing: 0.08em;
    text-transform: uppercase;
    font-weight: 600;
    color: var(--text-secondary);
    margin: 0;
  }

  /* Videos on top, cards below. The 3-video strip naturally wants full
     width — cramming it into a side column felt cramped. Cards below go
     in a 2-up row: status/timer card + log-form card. */
  .videos-strip {
    display: flex;
    flex-direction: column;
    gap: 10px;
  }
  .cards-strip {
    display: grid;
    grid-template-columns: minmax(0, 1fr) minmax(0, 1.2fr);
    gap: 16px;
    align-items: stretch;
  }
  @media (max-width: 720px) {
    .cards-strip { grid-template-columns: 1fr; }
  }

  /* Generic right-column card. Used for status, timer, and log form — so
     the rest and set views share the same visual rhythm. */
  .info-card {
    display: flex;
    flex-direction: column;
    gap: 10px;
    padding: 16px 18px;
    background: var(--surface-raised);
    border: 1px solid var(--border);
    border-radius: var(--radius-card);
    transition: border-color var(--motion-standard) var(--easing-settled);
  }
  .info-card.recording {
    border-color: var(--accent, #BE4A3A);
    background: rgba(190, 74, 58, 0.06);
  }
  .info-card.timer { gap: 6px; }
  .info-main {
    display: flex;
    align-items: baseline;
    gap: 8px;
  }
  .info-big {
    font-family: var(--font-mono);
    font-size: 44px;
    font-weight: 600;
    color: var(--primary);
    line-height: 1;
    font-variant-numeric: tabular-nums;
  }
  .info-big.elapsed { color: var(--accent, #BE4A3A); }
  .info-unit {
    font-size: 14px;
    color: var(--text-secondary);
    letter-spacing: 0.04em;
  }
  .info-sub {
    font-size: 12px;
    color: var(--text-secondary);
    margin: 0;
  }
  .recording-label {
    color: var(--accent, #BE4A3A) !important;
    display: inline-flex;
    align-items: center;
    gap: 6px;
  }
  .recording-label .rec-dot {
    width: 7px;
    height: 7px;
    border-radius: 50%;
    background: var(--accent, #BE4A3A);
    animation: breath var(--motion-breath) ease-in-out infinite;
  }

  /* 3 horizontal tiles — same layout language as the recording view. */
  .replay-row {
    display: grid;
    grid-template-columns: repeat(3, 1fr);
    gap: 10px;
  }
  .replay-tile {
    position: relative;
    aspect-ratio: 4 / 3;
    background: var(--warm-charcoal);
    border-radius: var(--radius-input);
    overflow: hidden;
  }
  .tile-video {
    position: absolute;
    width: 200%;
    height: 200%;
    object-fit: cover;
    pointer-events: none;
  }
  /* Composite (1280x960): cam0 (0,0), cam1 (640,0), cam2 (320,480). */
  .tile-0 { left:    0%;  top:    0%; }
  .tile-1 { left: -100%;  top:    0%; }
  .tile-2 { left:  -50%;  top: -100%; }
  .tile-label {
    position: absolute;
    bottom: 6px; left: 6px;
    padding: 2px 8px;
    background: rgba(26, 22, 18, 0.72);
    border-radius: 999px;
    color: #F5EFE7;
    font-family: var(--font-mono);
    font-size: 10px;
    letter-spacing: 0.05em;
  }
  .replay-empty {
    padding: 24px;
    text-align: center;
    background: var(--surface-raised);
    border: 1px dashed var(--border);
    border-radius: var(--radius-card);
    font-size: 14px;
  }

  /* ── Progress strip (top) — scoped to the CURRENT exercise ────────
     Full-session progress lives in the left timeline. This strip tracks
     only the block the user is viewing. Structure:
       strip-head:    exercise title + set position (left) · progress (right)
       progress-bar:  thin filled bar (sage → terracotta gradient)
       chip-track:    per-step chips with ✓/breath-dot/empty-ring */
  .progress-strip {
    display: flex;
    flex-direction: column;
    gap: 12px;
    padding: 14px 16px;
    background: var(--surface);
    border: 1px solid var(--border);
    border-radius: var(--radius-card);
  }
  .strip-head {
    display: flex;
    justify-content: space-between;
    align-items: flex-start;
    gap: 16px;
    flex-wrap: wrap;
  }
  .strip-title {
    display: flex;
    flex-direction: column;
    gap: 4px;
    min-width: 0;
  }
  .strip-ex-name {
    font-family: var(--font-display);
    font-weight: 700;
    font-size: 24px;
    letter-spacing: -0.2px;
    line-height: 1.1;
    margin: 0;
    color: var(--text);
  }
  .strip-meta {
    display: flex;
    align-items: baseline;
    gap: 8px;
    font-family: var(--font-body);
    font-size: 13px;
    color: var(--text);
    flex-wrap: wrap;
  }
  .strip-position { font-weight: 600; }
  .strip-position .dim,
  .strip-block .dim { color: var(--text-secondary); font-weight: 500; }
  .strip-sep { color: var(--text-secondary); }
  .strip-block { font-size: 12px; color: var(--text-secondary); }

  .strip-progress {
    display: flex;
    flex-direction: column;
    align-items: flex-end;
    gap: 2px;
    line-height: 1.1;
  }
  .progress-fraction {
    font-size: 11px;
    color: var(--text-secondary);
    letter-spacing: 0.02em;
  }
  .progress-pct {
    font-size: 18px;
    color: var(--text);
    font-weight: 700;
    letter-spacing: 0.02em;
  }

  .session-focus {
    font-family: var(--font-body);
    font-size: 13px;
    font-weight: 600;
    letter-spacing: 0.04em;
    text-transform: uppercase;
    color: var(--text-secondary);
  }
  .session-focus.dim { color: var(--text-disabled); }

  .progress-bar {
    height: 6px;
    background: var(--border);
    border-radius: 999px;
    overflow: hidden;
  }
  .progress-fill {
    height: 100%;
    background: linear-gradient(90deg, var(--sage, #7A9B76) 0%, var(--primary) 100%);
    border-radius: 999px;
    transition: width var(--motion-settled) var(--easing-settled);
  }

  /* Chips */
  .chip-track {
    display: flex;
    flex-wrap: wrap;
    gap: 6px;
    padding-top: 2px;
  }
  .chip {
    display: inline-flex;
    align-items: center;
    gap: 6px;
    padding: 5px 10px 5px 8px;
    border-radius: 999px;
    border: 1px solid var(--border);
    background: var(--surface);
    color: var(--text-secondary);
    font-family: var(--font-body);
    font-size: 12px;
    letter-spacing: 0.02em;
    cursor: pointer;
    white-space: nowrap;
    transition:
      background var(--motion-standard) var(--easing-settled),
      border-color var(--motion-standard) var(--easing-settled),
      color var(--motion-standard) var(--easing-settled),
      transform var(--motion-standard) var(--easing-settled);
  }
  .chip:hover:not(:disabled) {
    background: var(--surface-raised);
    color: var(--text);
  }
  .chip:disabled { cursor: default; }
  .chip[data-kind="rest"] { font-style: italic; }

  /* DONE — sage filled, checked, reads "you did this" */
  .chip[data-status="done"] {
    background: rgba(122, 155, 118, 0.12);
    border-color: var(--sage, #7A9B76);
    color: var(--sage, #7A9B76);
    font-weight: 600;
  }
  .chip[data-status="done"] .chip-mark {
    color: var(--sage, #7A9B76);
    font-weight: 700;
  }

  /* ACTIVE — terracotta outline, breath dot, "now" badge */
  .chip[data-status="active"] {
    border-color: var(--primary);
    color: var(--text);
    font-weight: 700;
    background: var(--surface);
    box-shadow: 0 0 0 3px rgba(196, 98, 45, 0.12);
  }
  .chip[data-status="active"] .chip-dot {
    background: var(--primary);
    animation: breath var(--motion-breath) ease-in-out infinite;
  }

  /* UPCOMING — muted outline, no lock, just "next up" feel */
  .chip[data-status="upcoming"] {
    color: var(--text-secondary);
    background: transparent;
    opacity: 0.65;
  }
  .chip[data-status="upcoming"] .chip-empty-dot {
    background: transparent;
    border: 1.5px solid var(--border);
  }

  .chip-mark {
    display: inline-flex;
    align-items: center;
    justify-content: center;
    width: 14px;
    height: 14px;
    font-size: 11px;
    line-height: 1;
    flex-shrink: 0;
  }
  .chip-dot,
  .chip-empty-dot {
    width: 9px;
    height: 9px;
    border-radius: 50%;
    flex-shrink: 0;
  }

  .chip-now {
    font-family: var(--font-body);
    font-size: 9px;
    font-weight: 700;
    letter-spacing: 0.12em;
    text-transform: uppercase;
    padding: 1px 7px;
    margin-left: 2px;
    border-radius: 999px;
    background: var(--primary);
    color: var(--on-primary, #F5EFE7);
  }

  .chip-meta {
    font-size: 10px;
    color: var(--sage, #7A9B76);
    padding-left: 6px;
    border-left: 1px solid rgba(122, 155, 118, 0.35);
    margin-left: 2px;
  }

  /* ── Finalization (review & save) ─────────────────────────────────── */
  .finish-btn {
    padding: 4px 14px;
    font-size: 12px;
    letter-spacing: 0.04em;
    border-radius: var(--radius-pill);
    margin-left: 4px;
  }
  .finish-btn:disabled { opacity: 0.35; cursor: not-allowed; }

  .finalize {
    display: flex;
    flex-direction: column;
    gap: 20px;
    padding: 24px 22px 22px;
    background: var(--surface);
    border: 1px solid var(--border);
    border-radius: var(--radius-card);
    animation: fade-rise var(--motion-settled) var(--easing-settled) both;
  }

  .check-hero {
    display: flex;
    align-items: center;
    gap: 16px;
  }
  .sage-check {
    color: var(--sage);
    flex-shrink: 0;
    animation: breath var(--motion-breath) ease-in-out infinite;
  }
  .sage-check svg {
    display: block;
  }
  .check-title-block {
    display: flex;
    flex-direction: column;
    gap: 4px;
    min-width: 0;
  }
  .finalize-title {
    font-family: var(--font-display);
    font-weight: 700;
    font-size: 28px;
    letter-spacing: -0.3px;
    line-height: 1.1;
    margin: 0;
    color: var(--text);
  }
  .finalize-sub {
    font-size: 12px;
    margin: 2px 0 0;
    font-family: var(--font-mono);
  }

  .summary-stats {
    display: grid;
    grid-template-columns: repeat(4, 1fr);
    gap: 10px;
    padding: 14px 16px;
    margin: 0;
    background: var(--surface-raised);
    border-radius: var(--radius-card);
  }
  @media (max-width: 560px) {
    .summary-stats { grid-template-columns: repeat(2, 1fr); }
  }
  .summary-stats .stat {
    display: flex;
    flex-direction: column;
    align-items: center;
    gap: 2px;
    margin: 0;
  }
  .summary-stats .stat-lab {
    font-family: var(--font-body);
    font-size: 10px;
    letter-spacing: 0.08em;
    text-transform: uppercase;
    color: var(--text-secondary);
  }
  .summary-stats .stat-num {
    font-family: var(--font-mono);
    font-size: 24px;
    font-weight: 600;
    color: var(--text);
    line-height: 1;
  }
  .summary-stats .stat-of {
    font-size: 14px;
    color: var(--text-secondary);
    font-weight: 400;
    margin-left: 2px;
  }

  .f-section {
    display: flex;
    flex-direction: column;
    gap: 10px;
  }

  /* RPE scale: 10 neutral cells that color by zone when selected. */
  .rpe-scale {
    display: grid;
    grid-template-columns: repeat(10, 1fr);
    gap: 6px;
  }
  .rpe-chip {
    padding: 10px 0;
    background: var(--surface);
    border: 1px solid var(--border);
    border-radius: var(--radius-input);
    font-family: var(--font-mono);
    font-size: 14px;
    font-variant-numeric: tabular-nums;
    color: var(--text-secondary);
    cursor: pointer;
    transition:
      background var(--motion-standard) var(--easing-settled),
      border-color var(--motion-standard) var(--easing-settled),
      color var(--motion-standard) var(--easing-settled);
  }
  .rpe-chip:hover:not(.active) { border-color: var(--text-secondary); color: var(--text); }
  .rpe-chip.active {
    color: var(--on-primary);
    border-color: transparent;
    font-weight: 600;
  }
  .rpe-chip.active[data-zone="easy"]     { background: var(--sage); }
  .rpe-chip.active[data-zone="moderate"] { background: var(--primary); }
  .rpe-chip.active[data-zone="hard"]     { background: var(--burnt-umber, #9B4A1F); }
  .rpe-anchors {
    display: flex;
    justify-content: space-between;
    font-family: var(--font-body);
    font-size: 10px;
    letter-spacing: 0.08em;
    text-transform: uppercase;
    color: var(--text-secondary);
    padding: 0 2px;
  }
  @media (max-width: 520px) {
    .rpe-scale { grid-template-columns: repeat(5, 1fr); }
  }

  /* Body check-in — word pills, no emoji */
  .feeling-row {
    display: grid;
    grid-template-columns: repeat(4, 1fr);
    gap: 6px;
  }
  @media (max-width: 520px) {
    .feeling-row { grid-template-columns: repeat(2, 1fr); }
  }
  .feeling-chip {
    padding: 10px 14px;
    background: var(--surface);
    border: 1px solid var(--border);
    border-radius: var(--radius-input);
    font-family: var(--font-body);
    font-size: 13px;
    letter-spacing: 0.04em;
    text-transform: capitalize;
    color: var(--text-secondary);
    cursor: pointer;
    transition: all var(--motion-standard) var(--easing-settled);
  }
  .feeling-chip:hover:not(.active) { border-color: var(--text-secondary); color: var(--text); }
  .feeling-chip.active {
    background: rgba(122, 155, 118, 0.14);
    border-color: var(--sage);
    color: var(--sage);
    font-weight: 600;
  }

  /* Notes + dictation */
  .notes-wrap {
    display: flex;
    flex-direction: column;
    gap: 8px;
  }
  .notes-area {
    width: 100%;
    padding: 12px 14px;
    border: 1px solid var(--border);
    border-radius: var(--radius-input);
    background: var(--surface);
    color: var(--text);
    font-family: var(--font-body);
    font-size: 14px;
    line-height: 1.5;
    resize: vertical;
    min-height: 100px;
  }
  .notes-area:focus {
    outline: none;
    border-color: var(--primary);
    box-shadow: 0 0 0 3px rgba(196, 98, 45, 0.12);
  }
  .dictation-interim {
    font-family: var(--font-body);
    font-style: italic;
    font-size: 13px;
    color: var(--text-secondary);
    margin: 0;
    padding: 0 4px;
  }
  .notes-actions {
    display: flex;
    align-items: center;
    gap: 12px;
    flex-wrap: wrap;
  }
  .dictate-btn {
    display: inline-flex;
    align-items: center;
    gap: 8px;
    padding: 8px 14px;
    background: var(--surface);
    border: 1px solid var(--border);
    border-radius: var(--radius-pill);
    font-family: var(--font-body);
    font-size: 12px;
    font-weight: 600;
    letter-spacing: 0.04em;
    color: var(--text-secondary);
    cursor: pointer;
    transition: all var(--motion-standard) var(--easing-settled);
  }
  .dictate-btn:hover:not(.active) { color: var(--text); border-color: var(--text-secondary); }
  .dictate-btn.active {
    background: rgba(190, 74, 58, 0.08);
    border-color: var(--error);
    color: var(--error);
  }
  .dictate-btn .mic-dot {
    width: 8px;
    height: 8px;
    border-radius: 50%;
    background: currentColor;
    opacity: 0.5;
  }
  .dictate-btn.active .mic-dot {
    opacity: 1;
    animation: breath var(--motion-breath) ease-in-out infinite;
  }
  .dictation-error {
    font-size: 12px;
    color: var(--error);
  }

  /* Per-exercise summary list */
  .ex-summary {
    list-style: none;
    margin: 0;
    padding: 0;
    display: flex;
    flex-direction: column;
    gap: 2px;
    border: 1px solid var(--border);
    border-radius: var(--radius-card);
    overflow: hidden;
  }
  .ex-row {
    display: grid;
    grid-template-columns: auto 1fr auto;
    gap: 12px;
    align-items: center;
    padding: 10px 14px;
    background: var(--surface);
    border-bottom: 1px solid var(--border);
  }
  .ex-row:last-child { border-bottom: none; }
  .ex-dot {
    width: 8px;
    height: 8px;
    border-radius: 50%;
    background: transparent;
    border: 1.5px solid var(--border);
    flex-shrink: 0;
  }
  .ex-row.complete .ex-dot {
    background: var(--sage);
    border-color: var(--sage);
  }
  .ex-name { font-size: 14px; font-weight: 600; }
  .ex-stats { font-size: 12px; color: var(--text-secondary); }

  .finalize-cta {
    display: flex;
    justify-content: space-between;
    align-items: center;
    gap: 12px;
    padding-top: 8px;
    border-top: 1px dashed var(--border);
    flex-wrap: wrap;
  }

  /* ── Session layout: left rail timeline + main column ─────────────── */
  .session-layout {
    display: grid;
    grid-template-columns: 240px minmax(0, 1fr);
    gap: 20px;
    align-items: start;
  }
  .session-layout[data-has-timeline="false"] {
    grid-template-columns: 1fr;
  }
  .session-main {
    display: flex;
    flex-direction: column;
    gap: 18px;
    min-width: 0;
  }
  @media (max-width: 960px) {
    .session-layout,
    .session-layout[data-has-timeline="true"] { grid-template-columns: 1fr; }
  }

  /* Left rail — vertical exercise-by-exercise timeline */
  .block-timeline {
    position: sticky;
    top: 16px;
    display: flex;
    flex-direction: column;
    gap: 10px;
    padding: 16px 14px;
    background: var(--surface);
    border: 1px solid var(--border);
    border-radius: var(--radius-card);
    animation: fade-rise var(--motion-settled) var(--easing-settled) both;
  }
  .block-timeline-title {
    font-family: var(--font-body);
    font-size: 11px;
    font-weight: 600;
    letter-spacing: 0.08em;
    text-transform: uppercase;
    color: var(--text-secondary);
    margin: 0 0 2px 2px;
  }
  .block-rail {
    list-style: none;
    padding: 0;
    margin: 0;
    display: flex;
    flex-direction: column;
  }
  .block-node {
    position: relative;
    padding-left: 0;
  }
  /* Connector line between nodes (from marker centre down to next marker). */
  .block-node::before {
    content: "";
    position: absolute;
    left: 19px; /* marker centre (12 + 14/2 + adjustments, matches .block-btn padding) */
    top: 32px;
    bottom: -4px;
    width: 1.5px;
    background: var(--border);
  }
  .block-node:last-child::before { display: none; }
  .block-node[data-status="completed"] + .block-node::before,
  .block-node[data-status="completed"]::before {
    background: var(--sage, #7A9B76);
  }

  .block-btn {
    display: grid;
    grid-template-columns: 28px minmax(0, 1fr);
    gap: 10px;
    align-items: center;
    width: 100%;
    padding: 8px 8px 8px 6px;
    background: transparent;
    border: 1px solid transparent;
    border-radius: var(--radius-card);
    text-align: left;
    color: var(--text);
    cursor: pointer;
    transition:
      background var(--motion-standard) var(--easing-settled),
      border-color var(--motion-standard) var(--easing-settled),
      opacity var(--motion-standard) var(--easing-settled);
  }
  .block-btn:hover:not(:disabled) {
    background: var(--surface-raised);
    border-color: var(--border);
  }
  .block-btn:disabled { cursor: default; }

  .block-marker {
    position: relative;
    z-index: 1;
    display: inline-flex;
    align-items: center;
    justify-content: center;
    width: 26px;
    height: 26px;
    border-radius: 50%;
    background: var(--surface);
    border: 1.5px solid var(--border);
    color: var(--text-secondary);
    flex-shrink: 0;
    transition:
      background var(--motion-standard) var(--easing-settled),
      border-color var(--motion-standard) var(--easing-settled),
      color var(--motion-standard) var(--easing-settled);
  }
  .block-num {
    font-family: var(--font-mono);
    font-size: 11px;
    font-weight: 600;
    font-variant-numeric: tabular-nums;
    line-height: 1;
  }
  .block-dot {
    width: 9px;
    height: 9px;
    border-radius: 50%;
    background: var(--primary);
    animation: breath var(--motion-breath) ease-in-out infinite;
  }

  .block-body {
    display: flex;
    flex-direction: column;
    min-width: 0;
  }
  .block-name {
    font-size: 13px;
    font-weight: 600;
    color: var(--text);
    white-space: nowrap;
    overflow: hidden;
    text-overflow: ellipsis;
  }
  .block-meta {
    font-size: 11px;
    color: var(--text-secondary);
    letter-spacing: 0.02em;
  }

  /* Status styling */
  .block-node[data-status="completed"] .block-marker {
    background: var(--sage, #7A9B76);
    border-color: var(--sage, #7A9B76);
    color: var(--on-primary, #F5EFE7);
  }
  .block-node[data-status="completed"] .block-name { color: var(--text); }

  .block-node[data-status="current"] .block-marker {
    background: var(--surface);
    border-color: var(--primary);
    box-shadow: 0 0 0 3px rgba(196, 98, 45, 0.12);
  }
  .block-node[data-status="current"] .block-name {
    color: var(--text);
    font-weight: 700;
  }

  .block-node[data-status="upcoming"] .block-btn { opacity: 0.6; }
  .block-node[data-status="upcoming"] .block-name { color: var(--text-secondary); font-weight: 500; }

  /* Viewing indicator — a subtle sidebar highlight on whichever block the
     user is currently looking at, independent of data completion status. */
  .block-node[data-viewing="true"] .block-btn {
    background: var(--surface-raised);
    border-color: var(--border);
  }

  /* Narrow screens: rail becomes a horizontal scroller above the main column */
  @media (max-width: 960px) {
    .block-timeline {
      position: static;
    }
    .block-rail {
      flex-direction: row;
      overflow-x: auto;
      gap: 4px;
      padding-bottom: 4px;
    }
    .block-node { flex: 0 0 auto; }
    .block-node::before { display: none; }
    .block-btn { grid-template-columns: auto auto; }
    .block-name { max-width: 140px; }
  }

  .session-footer {
    display: flex;
    align-items: center;
    gap: 14px;
    font-size: 12px;
    flex-wrap: wrap;
    padding-top: 12px;
    border-top: 1px solid var(--border);
    color: var(--text-secondary);
  }
  .footer-meta { display: flex; gap: 6px; }
  .heard { font-style: italic; }
  .error-line { color: var(--error); }
</style>
