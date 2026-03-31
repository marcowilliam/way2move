import * as functions from 'firebase-functions';
import * as admin from 'firebase-admin';

interface ReAssessmentScheduleDoc {
  userId: string;
  nextAssessmentDate: admin.firestore.Timestamp;
  intervalWeeks: number;
}

interface UserDoc {
  fcmToken?: string;
}

/**
 * Runs daily at 09:00 UTC.
 * Sends FCM push notifications to users whose re-assessment is due today
 * or in 3 days.
 */
export const sendReAssessmentReminders = functions.pubsub
  .schedule('0 9 * * *')
  .onRun(async () => {
    const db = admin.firestore();
    const messaging = admin.messaging();

    const today = new Date();
    today.setHours(0, 0, 0, 0);

    const in3Days = new Date(today.getTime() + 3 * 24 * 60 * 60 * 1000);
    const tomorrow = new Date(today.getTime() + 24 * 60 * 60 * 1000);
    const in4Days = new Date(today.getTime() + 4 * 24 * 60 * 60 * 1000);

    // Fetch schedules where nextAssessmentDate is today or exactly 3 days from now
    const snap = await db
      .collection('reAssessmentSchedules')
      .where(
        'nextAssessmentDate',
        '>=',
        admin.firestore.Timestamp.fromDate(today),
      )
      .where(
        'nextAssessmentDate',
        '<',
        admin.firestore.Timestamp.fromDate(in4Days),
      )
      .get();

    if (snap.empty) {
      functions.logger.info('sendReAssessmentReminders: no schedules due');
      return;
    }

    const sendPromises: Promise<void>[] = [];

    for (const doc of snap.docs) {
      const schedule = doc.data() as ReAssessmentScheduleDoc;
      const nextDate = schedule.nextAssessmentDate.toDate();
      nextDate.setHours(0, 0, 0, 0);

      const isToday =
        nextDate >= today && nextDate < tomorrow;
      const isIn3Days =
        nextDate >= in3Days && nextDate < in4Days;

      if (!isToday && !isIn3Days) continue;

      sendPromises.push(
        (async () => {
          const userDoc = await db
            .collection('users')
            .doc(schedule.userId)
            .get();
          if (!userDoc.exists) return;

          const fcmToken = (userDoc.data() as UserDoc).fcmToken;
          if (!fcmToken) return;

          const title = isToday
            ? 'Time to re-assess your movement'
            : 'Movement re-assessment in 3 days';
          const body = isToday
            ? 'See how far you\'ve come — complete your movement re-assessment today.'
            : 'Your movement re-assessment is coming up. Get ready to track your progress.';

          try {
            await messaging.send({
              token: fcmToken,
              notification: { title, body },
              data: { route: '/assessment' },
            });
            functions.logger.info(
              `sendReAssessmentReminders: sent to ${schedule.userId} (${isToday ? 'today' : '3 days'})`,
            );
          } catch (err) {
            functions.logger.warn(
              `sendReAssessmentReminders: failed for ${schedule.userId}`,
              err,
            );
          }
        })(),
      );
    }

    await Promise.all(sendPromises);
  });
