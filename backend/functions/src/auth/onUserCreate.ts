import * as functions from 'firebase-functions';
import * as admin from 'firebase-admin';

export const onUserCreate = functions.auth.user().onCreate(async (user) => {
  const db = admin.firestore();
  await db.collection('users').doc(user.uid).set(
    {
      id: user.uid,
      email: user.email ?? '',
      name: user.displayName ?? '',
      avatarUrl: user.photoURL ?? '',
      roles: ['athlete'],
      totalXp: 0,
      meta: {
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
      },
    },
    { merge: true },
  );
});
