export interface RecoveryScoreComponents {
  sleep: number; // 0–100
  trainingLoad: number; // 0–100
  weeklyPulse: number; // 0–100
  gutFeeling: number; // 0–100
}

export interface SleepLogData {
  quality: number; // 1–5
}

export interface SessionData {
  status: string; // 'completed' | 'planned' | 'inProgress' | 'skipped'
  date: Date;
}

export interface WeeklyPulseData {
  energyScore: number; // 1–5
  sorenessScore: number; // 1–5
  motivationScore: number; // 1–5
  sleepQualityScore: number; // 1–5
}

export interface MealData {
  stomachFeeling: number; // 1–5
}

/**
 * Pure calculation functions — no Firebase imports, fully testable.
 */

export function sleepComponent(logs: SleepLogData[]): number {
  if (logs.length === 0) return 50;
  const avg = logs.reduce((sum, l) => sum + l.quality, 0) / logs.length;
  return clamp(((avg - 1) / 4) * 100, 0, 100);
}

export function trainingLoadComponent(
  sessions: SessionData[],
  now: Date = new Date(),
): number {
  const completed = sessions.filter((s) => s.status === 'completed');
  if (completed.length === 0) return 75;

  const cutoff3 = new Date(now.getTime() - 3 * 24 * 60 * 60 * 1000);
  const cutoff7 = new Date(now.getTime() - 7 * 24 * 60 * 60 * 1000);

  const last3 = completed.filter((s) => s.date > cutoff3).length;
  const prev4 = completed.filter(
    (s) => s.date > cutoff7 && s.date <= cutoff3,
  ).length;

  const dailyLast3 = last3 / 3;
  const dailyPrev4 = prev4 / 4;

  if (dailyPrev4 === 0 && dailyLast3 === 0) return 75;
  if (dailyPrev4 === 0) return 50; // sudden load after rest

  const ratio = dailyLast3 / dailyPrev4;
  return clamp((1 - Math.min(ratio / 2, 1)) * 100, 0, 100);
}

export function weeklyPulseComponent(pulses: WeeklyPulseData[]): number {
  if (pulses.length === 0) return 50;
  const total = pulses.reduce((sum, p) => {
    const energy = ((p.energyScore - 1) / 4) * 100;
    const soreness = ((p.sorenessScore - 1) / 4) * 100;
    const motivation = ((p.motivationScore - 1) / 4) * 100;
    const sleep = ((p.sleepQualityScore - 1) / 4) * 100;
    return sum + (energy + soreness + motivation + sleep) / 4;
  }, 0);
  return clamp(total / pulses.length, 0, 100);
}

export function gutFeelingComponent(meals: MealData[]): number {
  if (meals.length === 0) return 50;
  const avg = meals.reduce((sum, m) => sum + m.stomachFeeling, 0) / meals.length;
  return clamp(((avg - 1) / 4) * 100, 0, 100);
}

export function calculateComponents(
  sleepLogs: SleepLogData[],
  sessions: SessionData[],
  weeklyPulses: WeeklyPulseData[],
  meals: MealData[],
  now?: Date,
): RecoveryScoreComponents {
  return {
    sleep: sleepComponent(sleepLogs),
    trainingLoad: trainingLoadComponent(sessions, now),
    weeklyPulse: weeklyPulseComponent(weeklyPulses),
    gutFeeling: gutFeelingComponent(meals),
  };
}

export function calculateScore(components: RecoveryScoreComponents): number {
  const raw =
    components.sleep * 0.3 +
    components.trainingLoad * 0.4 +
    components.weeklyPulse * 0.2 +
    components.gutFeeling * 0.1;
  return clamp(raw, 0, 100);
}

export function recommendationForScore(score: number): string {
  if (score >= 75) return "You're well-recovered. Train as planned.";
  if (score >= 50)
    return 'Mild fatigue. Consider reducing volume by 20% or swapping to mobility work.';
  return 'High fatigue. Take a rest day or do light active recovery only.';
}

function clamp(value: number, min: number, max: number): number {
  return Math.max(min, Math.min(max, value));
}
