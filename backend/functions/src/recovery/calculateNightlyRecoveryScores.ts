import * as functions from 'firebase-functions';
import * as admin from 'firebase-admin';
import {
  calculateComponents,
  calculateScore,
  recommendationForScore,
  SleepLogData,
  SessionData,
  WeeklyPulseData,
  MealData,
} from './recoveryService';

// Runs at 2:00 AM daily (server time UTC).
export const calculateNightlyRecoveryScores = functions.pubsub
  .schedule('0 2 * * *')
  .onRun(async () => {
    const db = admin.firestore();
    const yesterday = new Date();
    yesterday.setDate(yesterday.getDate() - 1);
    yesterday.setHours(0, 0, 0, 0);

    const today = new Date();
    today.setHours(0, 0, 0, 0);

    const dateKey = _dateKey(yesterday);

    // Process all users
    const usersSnap = await db.collection('users').get();

    await Promise.all(
      usersSnap.docs.map((userDoc) =>
        _processUser(db, userDoc.id, yesterday, today, dateKey),
      ),
    );

    functions.logger.info(
      `Nightly recovery scores calculated for ${usersSnap.docs.length} users`,
    );
  });

async function _processUser(
  db: admin.firestore.Firestore,
  userId: string,
  yesterday: Date,
  today: Date,
  dateKey: string,
): Promise<void> {
  try {
    // Fetch sleep logs for yesterday
    const sleepSnap = await db
      .collection('sleepLogs')
      .where('userId', '==', userId)
      .where('date', '>=', admin.firestore.Timestamp.fromDate(yesterday))
      .where('date', '<', admin.firestore.Timestamp.fromDate(today))
      .get();
    const sleepLogs: SleepLogData[] = sleepSnap.docs.map((d) => ({
      quality: (d.data()['quality'] as number) ?? 3,
    }));

    // Fetch sessions from last 7 days
    const sevenDaysAgo = new Date(today.getTime() - 7 * 24 * 60 * 60 * 1000);
    const sessionsSnap = await db
      .collection('sessions')
      .where('userId', '==', userId)
      .where('date', '>=', admin.firestore.Timestamp.fromDate(sevenDaysAgo))
      .get();
    const sessions: SessionData[] = sessionsSnap.docs.map((d) => ({
      status: d.data()['status'] as string,
      date: (d.data()['date'] as admin.firestore.Timestamp).toDate(),
    }));

    // Fetch weekly pulse entries from last 7 days
    const pulseSnap = await db
      .collection('weeklyPulses')
      .where('userId', '==', userId)
      .where('date', '>=', admin.firestore.Timestamp.fromDate(sevenDaysAgo))
      .get();
    const weeklyPulses: WeeklyPulseData[] = pulseSnap.docs.map((d) => ({
      energyScore: (d.data()['energyScore'] as number) ?? 3,
      sorenessScore: (d.data()['sorenessScore'] as number) ?? 3,
      motivationScore: (d.data()['motivationScore'] as number) ?? 3,
      sleepQualityScore: (d.data()['sleepQualityScore'] as number) ?? 3,
    }));

    // Fetch meals for yesterday
    const mealsSnap = await db
      .collection('meals')
      .where('userId', '==', userId)
      .where('date', '>=', admin.firestore.Timestamp.fromDate(yesterday))
      .where('date', '<', admin.firestore.Timestamp.fromDate(today))
      .get();
    const meals: MealData[] = mealsSnap.docs.map((d) => ({
      stomachFeeling: (d.data()['stomachFeeling'] as number) ?? 3,
    }));

    const components = calculateComponents(
      sleepLogs,
      sessions,
      weeklyPulses,
      meals,
      today,
    );
    const score = calculateScore(components);
    const recommendation = recommendationForScore(score);

    const scoreDoc = {
      userId,
      date: admin.firestore.Timestamp.fromDate(yesterday),
      score,
      components: {
        sleep: components.sleep,
        trainingLoad: components.trainingLoad,
        weeklyPulse: components.weeklyPulse,
        gutFeeling: components.gutFeeling,
      },
      recommendation,
      calculatedAt: admin.firestore.FieldValue.serverTimestamp(),
    };

    const batch = db.batch();

    // Write to per-user daily subcollection
    const dailyRef = db
      .collection('recoveryScores')
      .doc(userId)
      .collection('daily')
      .doc(dateKey);
    batch.set(dailyRef, scoreDoc);

    // Update user document with today's score for quick home reads
    const userRef = db.collection('users').doc(userId);
    batch.update(userRef, {
      todayRecoveryScore: score,
      todayRecoveryZone: _zone(score),
    });

    await batch.commit();
  } catch (err) {
    functions.logger.error(`Failed to calculate recovery for user ${userId}`, err);
  }
}

function _dateKey(date: Date): string {
  const y = date.getFullYear();
  const m = String(date.getMonth() + 1).padStart(2, '0');
  const d = String(date.getDate()).padStart(2, '0');
  return `${y}-${m}-${d}`;
}

function _zone(score: number): string {
  if (score >= 75) return 'green';
  if (score >= 50) return 'yellow';
  return 'red';
}
