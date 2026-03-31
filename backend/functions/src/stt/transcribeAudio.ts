import * as functions from 'firebase-functions';
import OpenAI, { toFile } from 'openai';

interface TranscribeAudioData {
  audioBase64: string;
  mimeType: string;
}

interface TranscribeAudioResult {
  transcript: string;
}

/// Transcribes audio using OpenAI Whisper.
///
/// The client sends a base64-encoded audio file (M4A/WAV) recorded on-device.
/// This function decodes it and passes it directly to the Whisper API.
///
/// The OpenAI API key must be configured via:
///   firebase functions:config:set openai.api_key="sk-..."
///
/// Input: { audioBase64: string, mimeType: 'audio/m4a' | 'audio/wav' }
/// Output: { transcript: string }
export const transcribeAudio = functions.https.onCall(
  async (
    data: TranscribeAudioData,
    context,
  ): Promise<TranscribeAudioResult> => {
    if (!context.auth) {
      throw new functions.https.HttpsError(
        'unauthenticated',
        'Must be signed in',
      );
    }

    const { audioBase64, mimeType } = data;

    if (!audioBase64 || typeof audioBase64 !== 'string') {
      throw new functions.https.HttpsError(
        'invalid-argument',
        'audioBase64 must be a non-empty string',
      );
    }

    if (!mimeType || typeof mimeType !== 'string') {
      throw new functions.https.HttpsError(
        'invalid-argument',
        'mimeType must be a non-empty string',
      );
    }

    const apiKey: string | undefined = functions.config().openai?.api_key;
    if (!apiKey) {
      throw new functions.https.HttpsError(
        'internal',
        'OpenAI API key not configured. Set via: firebase functions:config:set openai.api_key="sk-..."',
      );
    }

    try {
      const buffer = Buffer.from(audioBase64, 'base64');
      const ext = mimeType === 'audio/wav' ? 'wav' : 'm4a';
      const file = await toFile(buffer, `audio.${ext}`, { type: mimeType });

      const openai = new OpenAI({ apiKey });
      const transcription = await openai.audio.transcriptions.create({
        file,
        model: 'whisper-1',
      });

      return { transcript: transcription.text };
    } catch (err) {
      if (err instanceof functions.https.HttpsError) throw err;
      throw new functions.https.HttpsError(
        'internal',
        'Whisper transcription failed',
        err instanceof Error ? err.message : String(err),
      );
    }
  },
);
