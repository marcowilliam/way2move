/**
 * Unit tests for sendReAssessmentReminders.
 * Mocks Firestore + FCM — no emulator required.
 */

// ── Mocks ─────────────────────────────────────────────────────────────────────

const mockSend = jest.fn();
const mockUserGet = jest.fn();
const mockSchedulesGet = jest.fn();


// eslint-disable-next-line @typescript-eslint/no-explicit-any
const mockWhere: jest.Mock<any, any> = jest.fn(() => ({ where: mockWhere, get: mockSchedulesGet }));

jest.mock('firebase-admin', () => ({
  firestore: Object.assign(
    () => ({
      collection: (name: string) => {
        if (name === 'users') {
          return { doc: () => ({ get: mockUserGet }) };
        }
        return { where: mockWhere };
      },
    }),
    {
      Timestamp: {
        fromDate: (d: Date) => ({ toDate: () => d }),
      },
    },
  ),
  messaging: () => ({ send: mockSend }),
  initializeApp: jest.fn(),
}));

jest.mock('firebase-functions', () => ({
  pubsub: {
    schedule: (_cron: string) => ({
      onRun: (handler: Function) => handler,
    }),
  },
  logger: { info: jest.fn(), warn: jest.fn() },
}));

import { sendReAssessmentReminders } from './sendReAssessmentReminders';

// ── Helpers ───────────────────────────────────────────────────────────────────

function scheduleDue(daysFromNow: number) {
  const d = new Date();
  d.setHours(0, 0, 0, 0);
  d.setDate(d.getDate() + daysFromNow);
  return {
    data: () => ({
      userId: 'user1',
      nextAssessmentDate: { toDate: () => d },
      intervalWeeks: 4,
    }),
  };
}

// ── Tests ─────────────────────────────────────────────────────────────────────

describe('sendReAssessmentReminders', () => {
  beforeEach(() => {
    jest.clearAllMocks();
    mockUserGet.mockResolvedValue({
      exists: true,
      data: () => ({ fcmToken: 'token123' }),
    });
    mockSend.mockResolvedValue('msg-id');
  });

  it('sends "today" notification when assessment is due today', async () => {
    mockSchedulesGet.mockResolvedValue({ empty: false, docs: [scheduleDue(0)] });

    await (sendReAssessmentReminders as Function)();

    expect(mockSend).toHaveBeenCalledWith(
      expect.objectContaining({
        notification: expect.objectContaining({
          title: 'Time to re-assess your movement',
        }),
      }),
    );
  });

  it('sends "3 days" notification when assessment is due in 3 days', async () => {
    mockSchedulesGet.mockResolvedValue({ empty: false, docs: [scheduleDue(3)] });

    await (sendReAssessmentReminders as Function)();

    expect(mockSend).toHaveBeenCalledWith(
      expect.objectContaining({
        notification: expect.objectContaining({
          title: 'Movement re-assessment in 3 days',
        }),
      }),
    );
  });

  it('does not send when no schedules are due', async () => {
    mockSchedulesGet.mockResolvedValue({ empty: true, docs: [] });

    await (sendReAssessmentReminders as Function)();

    expect(mockSend).not.toHaveBeenCalled();
  });

  it('skips user with no FCM token', async () => {
    mockSchedulesGet.mockResolvedValue({ empty: false, docs: [scheduleDue(0)] });
    mockUserGet.mockResolvedValue({
      exists: true,
      data: () => ({ fcmToken: undefined }),
    });

    await (sendReAssessmentReminders as Function)();

    expect(mockSend).not.toHaveBeenCalled();
  });

  it('skips non-existent user document', async () => {
    mockSchedulesGet.mockResolvedValue({ empty: false, docs: [scheduleDue(0)] });
    mockUserGet.mockResolvedValue({ exists: false });

    await (sendReAssessmentReminders as Function)();

    expect(mockSend).not.toHaveBeenCalled();
  });

  it('continues sending to other users even if one FCM call fails', async () => {
    const doc1 = {
      data: () => ({
        userId: 'user1',
        nextAssessmentDate: { toDate: () => new Date() },
        intervalWeeks: 4,
      }),
    };
    const doc2 = {
      data: () => ({
        userId: 'user2',
        nextAssessmentDate: { toDate: () => new Date() },
        intervalWeeks: 4,
      }),
    };

    mockSchedulesGet.mockResolvedValue({ empty: false, docs: [doc1, doc2] });
    mockUserGet.mockResolvedValue({
      exists: true,
      data: () => ({ fcmToken: 'token' }),
    });
    mockSend
      .mockRejectedValueOnce(new Error('invalid token'))
      .mockResolvedValueOnce('msg-id');

    // Should not throw
    await expect(
      (sendReAssessmentReminders as Function)(),
    ).resolves.toBeUndefined();
  });
});
