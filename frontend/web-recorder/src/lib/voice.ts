// Web Speech API: recognition (listen) + synthesis (speak).
// Recognition is browser-vendored — webkitSpeechRecognition in Chrome.

export type VoiceCommand = "start" | "stop" | "skip" | "repeat" | "next" | "previous" | "quit";
// "previous" must be checked before "next" in case both words appear in a phrase.
const COMMAND_PATTERNS: Array<[VoiceCommand, RegExp]> = [
  ["previous", /\b(previous|back|go back)\b/i],
  ["start", /\bstart\b/i],
  ["stop", /\bstop\b/i],
  ["skip", /\bskip\b/i],
  ["repeat", /\brepeat\b/i],
  ["next", /\bnext\b/i],
  ["quit", /\bquit\b/i],
];

export const matchCommand = (transcript: string): VoiceCommand | null => {
  for (const [cmd, re] of COMMAND_PATTERNS) {
    if (re.test(transcript)) return cmd;
  }
  return null;
};

export interface VoiceListenerOptions {
  onCommand: (cmd: VoiceCommand, raw: string) => void;
  onTranscript?: (raw: string) => void;
  onError?: (err: string) => void;
  onStateChange?: (listening: boolean) => void;
  lang?: string;
}

export class VoiceListener {
  private rec: any = null;
  private opts: VoiceListenerOptions;
  private wantRestart = false;

  constructor(opts: VoiceListenerOptions) {
    this.opts = opts;
  }

  static isSupported(): boolean {
    return !!((window as any).SpeechRecognition || (window as any).webkitSpeechRecognition);
  }

  start(): void {
    const SR = (window as any).SpeechRecognition || (window as any).webkitSpeechRecognition;
    if (!SR) {
      this.opts.onError?.("SpeechRecognition not supported (use Chrome)");
      return;
    }
    this.rec = new SR();
    this.rec.continuous = true;
    this.rec.interimResults = false;
    this.rec.lang = this.opts.lang ?? "en-US";
    this.rec.onstart = () => this.opts.onStateChange?.(true);
    this.rec.onend = () => {
      this.opts.onStateChange?.(false);
      // Chrome auto-stops after silence; restart if we still want to listen.
      if (this.wantRestart) setTimeout(() => this.rec?.start(), 300);
    };
    this.rec.onerror = (ev: any) => this.opts.onError?.(ev.error);
    this.rec.onresult = (ev: any) => {
      const last = ev.results[ev.results.length - 1];
      const text: string = last[0].transcript.trim();
      this.opts.onTranscript?.(text);
      const cmd = matchCommand(text);
      if (cmd) this.opts.onCommand(cmd, text);
    };
    this.wantRestart = true;
    this.rec.start();
  }

  stop(): void {
    this.wantRestart = false;
    this.rec?.stop();
    this.rec = null;
  }
}

// --- TTS ---

// Default voice on Linux/Chrome is eSpeak (robotic). We auto-pick the best
// English voice — preferring neural Google voices, then Microsoft / Apple
// neural, then any en-US, then any English. The voiceschanged event is
// honored because the voice list often arrives async after page load.
let pickedVoice: SpeechSynthesisVoice | null = null;
let userPreferredVoiceName: string | null = null;

const pickBestVoice = (): SpeechSynthesisVoice | null => {
  if (!("speechSynthesis" in window)) return null;
  const voices = window.speechSynthesis.getVoices();
  if (voices.length === 0) return null;

  if (userPreferredVoiceName) {
    const match = voices.find((v) => v.name === userPreferredVoiceName);
    if (match) return match;
  }

  const isEn = (v: SpeechSynthesisVoice) => v.lang.toLowerCase().startsWith("en");
  const isGoogle = (v: SpeechSynthesisVoice) => /google/i.test(v.name);
  const isMs = (v: SpeechSynthesisVoice) => /microsoft/i.test(v.name);
  const isApple = (v: SpeechSynthesisVoice) =>
    /samantha|daniel|karen|moira|tessa|fiona|siri/i.test(v.name);

  return (
    voices.find((v) => isGoogle(v) && v.lang === "en-US") ??
    voices.find((v) => isGoogle(v) && isEn(v)) ??
    voices.find((v) => isMs(v) && isEn(v)) ??
    voices.find((v) => isApple(v) && isEn(v)) ??
    voices.find((v) => v.lang === "en-US") ??
    voices.find((v) => v.lang === "en-GB") ??
    voices.find(isEn) ??
    voices[0]
  );
};

const ensureVoice = (): void => {
  if (!pickedVoice) pickedVoice = pickBestVoice();
};

if (typeof window !== "undefined" && "speechSynthesis" in window) {
  window.speechSynthesis.onvoiceschanged = () => {
    pickedVoice = pickBestVoice();
  };
  ensureVoice();
}

export const listEnglishVoices = (): SpeechSynthesisVoice[] => {
  if (!("speechSynthesis" in window)) return [];
  return window.speechSynthesis
    .getVoices()
    .filter((v) => v.lang.toLowerCase().startsWith("en"));
};

export const setPreferredVoice = (name: string | null): void => {
  userPreferredVoiceName = name;
  pickedVoice = pickBestVoice();
};

export const getPreferredVoice = (): SpeechSynthesisVoice | null => pickedVoice;

export const speak = (text: string, opts: { rate?: number; pitch?: number } = {}): void => {
  if (!("speechSynthesis" in window)) return;
  ensureVoice();
  const u = new SpeechSynthesisUtterance(text);
  // 0.95 is slightly slower than default — movement cues read better when
  // the athlete has time to apply each one before the next.
  u.rate = opts.rate ?? 0.95;
  u.pitch = opts.pitch ?? 1;
  u.lang = pickedVoice?.lang ?? "en-US";
  if (pickedVoice) u.voice = pickedVoice;
  window.speechSynthesis.cancel();
  window.speechSynthesis.speak(u);
};

export const stopSpeaking = (): void => {
  if ("speechSynthesis" in window) window.speechSynthesis.cancel();
};
