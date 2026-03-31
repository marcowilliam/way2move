/**
 * Unit tests for onAssessmentComplete.
 *
 * Strategy: mock firebase-admin and firebase-functions so no emulator is needed.
 */

// ── Mocks ─────────────────────────────────────────────────────────────────────

const mockSet = jest.fn();
const mockUpdate = jest.fn();
const mockGet = jest.fn();
const mockDoc = jest.fn(() => ({ get: mockGet, set: mockSet, update: mockUpdate }));
const mockCollection = jest.fn(() => ({ doc: mockDoc }));

jest.mock('firebase-admin', () => ({
  firestore: Object.assign(() => ({ collection: mockCollection }), {
    Timestamp: {
      now: () => ({ toDate: () => new Date('2026-03-30T09:00:00Z') }),
      fromDate: (d: Date) => ({ toDate: () => d }),
    },
    FieldValue: { serverTimestamp: () => 'SERVER_TS' },
  }),
  messaging: jest.fn(),
  initializeApp: jest.fn(),
}));

jest.mock('firebase-functions', () => ({
  firestore: {
    document: (_path: string) => ({
      onCreate: (handler: Function) => handler,
    }),
  },
  logger: { info: jest.fn(), warn: jest.fn() },
}));

// ── Import after mocks ─────────────────────────────────────────────────────────

import { onAssessmentComplete } from './onAssessmentComplete';

// ── Helpers ────────────────────────────────────────────────────────────────────

function makeSnap(data: object) {
  return { data: () => data };
}

function makeContext(assessmentId = 'assessment1') {
  return { params: { assessmentId } };
}

// ── Tests ──────────────────────────────────────────────────────────────────────

describe('onAssessmentComplete', () => {
  beforeEach(() => {
    jest.clearAllMocks();
  });

  it('writes schedule with default 4-week interval when no existing schedule', async () => {
    mockGet.mockResolvedValue({ exists: false });
    mockSet.mockResolvedValue(undefined);

    await (onAssessmentComplete as Function)(
      makeSnap({ userId: 'user1', createdAt: {} }),
      makeContext(),
    );

    expect(mockSet).toHaveBeenCalledWith(
      expect.objectContaining({
        userId: 'user1',
        intervalWeeks: 4,
      }),
      { merge: true },
    );
  });

  it('preserves existing intervalWeeks from prior schedule', async () => {
    mockGet.mockResolvedValue({
      exists: true,
      data: () => ({ intervalWeeks: 8 }),
    });
    mockSet.mockResolvedValue(undefined);

    await (onAssessmentComplete as Function)(
      makeSnap({ userId: 'user2', createdAt: {} }),
      makeContext('assessment2'),
    );

    expect(mockSet).toHaveBeenCalledWith(
      expect.objectContaining({ intervalWeeks: 8 }),
      { merge: true },
    );
  });

  it('does nothing when userId is missing', async () => {
    await (onAssessmentComplete as Function)(
      makeSnap({ createdAt: {} }),
      makeContext(),
    );

    expect(mockSet).not.toHaveBeenCalled();
  });

  it('sets lastCompletedDate and nextAssessmentDate', async () => {
    mockGet.mockResolvedValue({ exists: false });
    mockSet.mockResolvedValue(undefined);

    await (onAssessmentComplete as Function)(
      makeSnap({ userId: 'user3', createdAt: {} }),
      makeContext('assessment3'),
    );

    const call = mockSet.mock.calls[0][0] as Record<string, unknown>;
    expect(call).toHaveProperty('lastCompletedDate');
    expect(call).toHaveProperty('nextAssessmentDate');
  });
});
