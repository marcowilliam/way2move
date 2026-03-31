import * as admin from 'firebase-admin';
admin.initializeApp();

export { onUserCreate } from './auth/onUserCreate';
export { onAssessmentComplete } from './assessments/onAssessmentComplete';
export { sendReAssessmentReminders } from './notifications/sendReAssessmentReminders';
export { calculateNightlyRecoveryScores } from './recovery/calculateNightlyRecoveryScores';
export { transcribeAudio } from './stt/transcribeAudio';
// export { seedDatabase } from './seed/seedDatabase';
