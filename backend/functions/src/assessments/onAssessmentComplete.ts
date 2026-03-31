import * as functions from 'firebase-functions';
import * as admin from 'firebase-admin';

const DEFAULT_INTERVAL_WEEKS = 4;

export const onAssessmentComplete = functions.firestore
  .document('assessments/{assessmentId}')
  .onCreate(async (snap, context) => {
    const assessment = snap.data() as {
      userId: string;
      createdAt: admin.firestore.Timestamp;
    };

    const userId = assessment.userId;
    if (!userId) {
      functions.logger.warn('onAssessmentComplete: missing userId', {
        assessmentId: context.params.assessmentId,
      });
      return;
    }

    const db = admin.firestore();
    const scheduleRef = db.collection('reAssessmentSchedules').doc(userId);

    // Fetch existing schedule to preserve intervalWeeks preference
    const existing = await scheduleRef.get();
    const intervalWeeks: number = existing.exists
      ? ((existing.data() as { intervalWeeks?: number }).intervalWeeks ??
          DEFAULT_INTERVAL_WEEKS)
      : DEFAULT_INTERVAL_WEEKS;

    const now = admin.firestore.Timestamp.now();
    const nextDate = new Date(now.toDate().getTime());
    nextDate.setDate(nextDate.getDate() + intervalWeeks * 7);

    await scheduleRef.set(
      {
        userId,
        lastCompletedDate: now,
        nextAssessmentDate: admin.firestore.Timestamp.fromDate(nextDate),
        intervalWeeks,
      },
      { merge: true },
    );

    functions.logger.info('onAssessmentComplete: schedule updated', {
      userId,
      nextAssessmentDate: nextDate.toISOString(),
      intervalWeeks,
    });
  });
