import * as admin from 'firebase-admin';

// Seed exercises from JSON file
async function seedExercises(): Promise<void> {
  const exercises = require('../../../seeds/exercises.json');
  const db = admin.firestore();
  const batch = db.batch();

  for (const exercise of exercises) {
    const ref = db.collection('exercises').doc(exercise.id);
    const snap = await ref.get();
    if (!snap.exists) {
      batch.set(ref, exercise);
    }
  }

  await batch.commit();
  console.log(`Seeded ${exercises.length} exercises`);
}

async function main(): Promise<void> {
  // Initialize admin SDK if not already initialized
  if (!admin.apps.length) {
    admin.initializeApp();
  }

  await seedExercises();
  console.log('Seed complete');
}

main().catch(console.error);
