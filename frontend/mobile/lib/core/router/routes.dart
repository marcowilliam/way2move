abstract class Routes {
  static const auth = '/auth';
  static const login = '/auth/login';
  static const signup = '/auth/signup';
  static const home = '/';
  static const profile = '/profile';
  static const session = '/session';
  static const exercises = '/exercises';
  static String exerciseDetail(String id) => '/exercises/$id';
  static const programs = '/programs';
  static const programDetail = '/programs/:programId';
  static const programBuilder = '/programs/new';
  static const calendar = '/calendar';
  static const progress = '/progress';
  static const assessment = '/assessment';
  static const sleep = '/sleep';
}
