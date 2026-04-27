// localStorage-backed session persistence for v1.
// Schema mirrors way2move's Session entity so a future port to Firestore is mechanical.

import type { Session, RecorderSettings } from "./types";

const SESSIONS_KEY = "way2train.sessions.v1";
const SETTINGS_KEY = "way2train.settings.v1";

export const loadSessions = (): Session[] => {
  try {
    const raw = localStorage.getItem(SESSIONS_KEY);
    return raw ? (JSON.parse(raw) as Session[]) : [];
  } catch {
    return [];
  }
};

export const saveSessions = (sessions: Session[]): void => {
  localStorage.setItem(SESSIONS_KEY, JSON.stringify(sessions));
};

export const upsertSession = (session: Session): void => {
  const all = loadSessions();
  const idx = all.findIndex((s) => s.id === session.id);
  if (idx >= 0) all[idx] = session;
  else all.push(session);
  saveSessions(all);
};

export const deleteSession = (id: string): void => {
  const all = loadSessions();
  saveSessions(all.filter((s) => s.id !== id));
};

export const loadSettings = (): RecorderSettings => {
  try {
    const raw = localStorage.getItem(SETTINGS_KEY);
    if (raw) return JSON.parse(raw) as RecorderSettings;
  } catch {}
  return { cameras: [] };
};

export const saveSettings = (s: RecorderSettings): void => {
  localStorage.setItem(SETTINGS_KEY, JSON.stringify(s));
};

export const newId = (): string =>
  (crypto.randomUUID?.() ?? `${Date.now()}-${Math.random().toString(36).slice(2)}`);
