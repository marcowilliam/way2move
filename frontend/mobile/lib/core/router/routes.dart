abstract class Routes {
  static const auth = '/auth';
  static const login = '/auth/login';
  static const signup = '/auth/signup';
  static const home = '/';
  static const profile = '/profile';
  static const session = '/session';
  static const sessionActive = '/session/active';
  static const sessionStandalone = '/session/standalone';
  static String sessionSummary(String id) => '/session/summary/$id';
  static const exercises = '/exercises';
  static String exerciseDetail(String id) => '/exercises/$id';
  static const programs = '/programs';
  static const programDetail = '/programs/:programId';
  static const programBuilder = '/programs/new';
  static const calendar = '/calendar';
  static const progress = '/progress';
  static const assessment = '/assessment';
  static const assessmentHistory = '/assessment/history';
  static const sleep = '/sleep';
  static const onboarding = '/onboarding';
  static const profileEdit = '/profile/edit';
  static const compensationProfile = '/compensations';
  static const compensationAdd = '/compensations/add';
  static String compensationDetail(String id) => '/compensations/$id';

  // Goals
  static const goals = '/goals';
  static const goalsSetup = '/goals/setup';
  static String goalDetail(String id) => '/goals/$id';

  // Nutrition
  static const nutrition = '/nutrition';
  static const mealLog = '/nutrition/log';
  static const stomachPattern = '/nutrition/patterns';
}
