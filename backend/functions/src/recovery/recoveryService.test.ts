import {
  sleepComponent,
  trainingLoadComponent,
  weeklyPulseComponent,
  gutFeelingComponent,
  calculateScore,
  calculateComponents,
  recommendationForScore,
  RecoveryScoreComponents,
} from './recoveryService';

// Fixed "now" for deterministic date math
const NOW = new Date('2024-06-15T12:00:00Z');
const daysAgo = (n: number) =>
  new Date(NOW.getTime() - n * 24 * 60 * 60 * 1000);

describe('sleepComponent', () => {
  it('returns 50 when no logs', () => {
    expect(sleepComponent([])).toBe(50);
  });

  it('maps quality 1 to 0', () => {
    expect(sleepComponent([{ quality: 1 }])).toBe(0);
  });

  it('maps quality 5 to 100', () => {
    expect(sleepComponent([{ quality: 5 }])).toBe(100);
  });

  it('maps quality 3 to 50', () => {
    expect(sleepComponent([{ quality: 3 }])).toBe(50);
  });

  it('averages multiple logs', () => {
    expect(sleepComponent([{ quality: 1 }, { quality: 5 }])).toBe(50);
  });
});

describe('trainingLoadComponent', () => {
  it('returns 75 when no sessions', () => {
    expect(trainingLoadComponent([], NOW)).toBe(75);
  });

  it('returns 75 when all sessions are outside the 7-day window', () => {
    const sessions = [{ status: 'completed', date: daysAgo(10) }];
    expect(trainingLoadComponent(sessions, NOW)).toBe(75);
  });

  it('returns 50 when only recent load and no prior baseline', () => {
    const sessions = [{ status: 'completed', date: daysAgo(1) }];
    expect(trainingLoadComponent(sessions, NOW)).toBe(50);
  });

  it('gives higher score when recent load is lower than baseline', () => {
    // Heavy previous 4 days, nothing recent
    const heavy = [
      { status: 'completed', date: daysAgo(4) },
      { status: 'completed', date: daysAgo(5) },
      { status: 'completed', date: daysAgo(6) },
      { status: 'completed', date: daysAgo(7) },
    ];
    // Light last 3 days, same prior history
    const light = [
      { status: 'completed', date: daysAgo(1) },
      ...heavy,
    ];
    const highRecovery = trainingLoadComponent(heavy, NOW);
    const lowerRecovery = trainingLoadComponent(light, NOW);
    expect(highRecovery).toBeGreaterThan(lowerRecovery);
  });

  it('ignores planned sessions', () => {
    const sessions = [{ status: 'planned', date: daysAgo(1) }];
    expect(trainingLoadComponent(sessions, NOW)).toBe(75);
  });
});

describe('weeklyPulseComponent', () => {
  it('returns 50 when no pulses', () => {
    expect(weeklyPulseComponent([])).toBe(50);
  });

  it('maps all 5s to 100', () => {
    expect(
      weeklyPulseComponent([
        { energyScore: 5, sorenessScore: 5, motivationScore: 5, sleepQualityScore: 5 },
      ]),
    ).toBe(100);
  });

  it('maps all 1s to 0', () => {
    expect(
      weeklyPulseComponent([
        { energyScore: 1, sorenessScore: 1, motivationScore: 1, sleepQualityScore: 1 },
      ]),
    ).toBe(0);
  });

  it('maps all 3s to 50', () => {
    expect(
      weeklyPulseComponent([
        { energyScore: 3, sorenessScore: 3, motivationScore: 3, sleepQualityScore: 3 },
      ]),
    ).toBe(50);
  });
});

describe('gutFeelingComponent', () => {
  it('returns 50 when no meals', () => {
    expect(gutFeelingComponent([])).toBe(50);
  });

  it('maps stomachFeeling 1 to 0', () => {
    expect(gutFeelingComponent([{ stomachFeeling: 1 }])).toBe(0);
  });

  it('maps stomachFeeling 5 to 100', () => {
    expect(gutFeelingComponent([{ stomachFeeling: 5 }])).toBe(100);
  });
});

describe('calculateScore', () => {
  it('weights are 30/40/20/10', () => {
    const components: RecoveryScoreComponents = {
      sleep: 100,
      trainingLoad: 0,
      weeklyPulse: 0,
      gutFeeling: 0,
    };
    expect(calculateScore(components)).toBeCloseTo(30);
  });

  it('all 100 produces 100', () => {
    const c: RecoveryScoreComponents = {
      sleep: 100,
      trainingLoad: 100,
      weeklyPulse: 100,
      gutFeeling: 100,
    };
    expect(calculateScore(c)).toBe(100);
  });

  it('all 0 produces 0', () => {
    const c: RecoveryScoreComponents = {
      sleep: 0,
      trainingLoad: 0,
      weeklyPulse: 0,
      gutFeeling: 0,
    };
    expect(calculateScore(c)).toBe(0);
  });

  it('clamps to 100 on overflow', () => {
    const c: RecoveryScoreComponents = {
      sleep: 200,
      trainingLoad: 200,
      weeklyPulse: 200,
      gutFeeling: 200,
    };
    expect(calculateScore(c)).toBe(100);
  });
});

describe('recommendationForScore', () => {
  it('75 returns green recommendation', () => {
    expect(recommendationForScore(75)).toContain('well-recovered');
  });

  it('74 returns yellow recommendation', () => {
    expect(recommendationForScore(74)).toContain('Mild fatigue');
  });

  it('50 returns yellow recommendation', () => {
    expect(recommendationForScore(50)).toContain('Mild fatigue');
  });

  it('49 returns red recommendation', () => {
    expect(recommendationForScore(49)).toContain('High fatigue');
  });

  it('0 returns red recommendation', () => {
    expect(recommendationForScore(0)).toContain('High fatigue');
  });
});

describe('calculateComponents', () => {
  it('returns components struct with all four fields', () => {
    const c = calculateComponents([], [], [], []);
    expect(c).toHaveProperty('sleep');
    expect(c).toHaveProperty('trainingLoad');
    expect(c).toHaveProperty('weeklyPulse');
    expect(c).toHaveProperty('gutFeeling');
  });
});
