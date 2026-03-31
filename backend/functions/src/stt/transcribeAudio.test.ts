import * as functions from 'firebase-functions';

// ---------------------------------------------------------------------------
// Mocks
// ---------------------------------------------------------------------------

const mockTranscribe = jest.fn();
const mockToFile = jest.fn();

jest.mock('openai', () => {
  const mockCreate = mockTranscribe;
  const mockToFileImpl = mockToFile;

  const OpenAIMock = jest.fn().mockImplementation(() => ({
    audio: {
      transcriptions: {
        create: mockCreate,
      },
    },
  }));

  return {
    __esModule: true,
    default: OpenAIMock,
    toFile: mockToFileImpl,
  };
});

jest.mock('firebase-functions', () => {
  const actual = jest.requireActual('firebase-functions');
  return {
    ...actual,
    config: jest.fn().mockReturnValue({
      openai: { api_key: 'test-api-key' },
    }),
  };
});

// ---------------------------------------------------------------------------
// Helper — build a fake callable context
// ---------------------------------------------------------------------------
function makeContext(uid?: string) {
  return {
    auth: uid ? { uid, token: {} as never } : undefined,
    rawRequest: {} as never,
    resource: {} as never,
    timestamp: new Date().toISOString(),
    eventId: 'test',
    eventType: '',
    params: {},
  };
}

// ---------------------------------------------------------------------------
// Import the function under test AFTER mocks are set up
// ---------------------------------------------------------------------------
import { transcribeAudio } from './transcribeAudio';

// eslint-disable-next-line @typescript-eslint/no-explicit-any
const handler = (transcribeAudio as any).run as (
  data: unknown,
  context: unknown,
) => Promise<{ transcript: string }>;

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------
describe('transcribeAudio', () => {
  beforeEach(() => {
    jest.clearAllMocks();
    // Default: toFile resolves to a fake File-like object.
    mockToFile.mockResolvedValue({ name: 'audio.m4a' });
  });

  it('throws unauthenticated when no auth context', async () => {
    await expect(
      handler({ audioBase64: 'dGVzdA==', mimeType: 'audio/m4a' }, makeContext()),
    ).rejects.toMatchObject({ code: 'unauthenticated' });
  });

  it('throws invalid-argument when audioBase64 is missing', async () => {
    await expect(
      handler({ mimeType: 'audio/m4a' }, makeContext('user1')),
    ).rejects.toMatchObject({ code: 'invalid-argument' });
  });

  it('throws invalid-argument when audioBase64 is empty string', async () => {
    await expect(
      handler({ audioBase64: '', mimeType: 'audio/m4a' }, makeContext('user1')),
    ).rejects.toMatchObject({ code: 'invalid-argument' });
  });

  it('throws invalid-argument when mimeType is missing', async () => {
    await expect(
      handler({ audioBase64: 'dGVzdA==' }, makeContext('user1')),
    ).rejects.toMatchObject({ code: 'invalid-argument' });
  });

  it('throws internal when OpenAI API key is not configured', async () => {
    (functions.config as jest.Mock).mockReturnValueOnce({ openai: {} });

    await expect(
      handler(
        { audioBase64: 'dGVzdA==', mimeType: 'audio/m4a' },
        makeContext('user1'),
      ),
    ).rejects.toMatchObject({ code: 'internal' });
  });

  it('calls toFile with decoded buffer and correct mime type', async () => {
    mockTranscribe.mockResolvedValueOnce({ text: 'Hello world' });

    await handler(
      { audioBase64: 'dGVzdA==', mimeType: 'audio/m4a' },
      makeContext('user1'),
    );

    expect(mockToFile).toHaveBeenCalledWith(
      Buffer.from('dGVzdA==', 'base64'),
      'audio.m4a',
      { type: 'audio/m4a' },
    );
  });

  it('returns transcript from Whisper on success', async () => {
    mockTranscribe.mockResolvedValueOnce({ text: 'Hello world' });

    const result = await handler(
      { audioBase64: 'dGVzdA==', mimeType: 'audio/m4a' },
      makeContext('user1'),
    );

    expect(result).toEqual({ transcript: 'Hello world' });
    expect(mockTranscribe).toHaveBeenCalledWith(
      expect.objectContaining({ model: 'whisper-1' }),
    );
  });

  it('throws internal when Whisper API call fails', async () => {
    mockTranscribe.mockRejectedValueOnce(new Error('rate limit'));

    await expect(
      handler(
        { audioBase64: 'dGVzdA==', mimeType: 'audio/m4a' },
        makeContext('user1'),
      ),
    ).rejects.toMatchObject({ code: 'internal' });
  });

  it('uses .wav filename for audio/wav mimeType', async () => {
    mockTranscribe.mockResolvedValueOnce({ text: 'wav test' });

    await handler(
      { audioBase64: 'dGVzdA==', mimeType: 'audio/wav' },
      makeContext('user1'),
    );

    expect(mockToFile).toHaveBeenCalledWith(
      expect.any(Buffer),
      'audio.wav',
      { type: 'audio/wav' },
    );
  });
});
