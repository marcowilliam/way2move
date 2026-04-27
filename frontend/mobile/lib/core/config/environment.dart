/// Compile-time environment configuration.
///
/// Pass --dart-define=ENV=staging to target the staging environment.
/// Pass --dart-define=ENV=emulator (default) to use local Firebase emulators.
library;

enum AppEnvironment { emulator, staging }

abstract class Env {
  static const _rawEnv = String.fromEnvironment(
    'ENV',
    defaultValue: 'emulator',
  );
  static const _emulatorHost = String.fromEnvironment(
    'EMULATOR_HOST',
    defaultValue: 'localhost',
  );

  static AppEnvironment get current =>
      _rawEnv == 'staging' ? AppEnvironment.staging : AppEnvironment.emulator;

  static bool get isEmulator => current == AppEnvironment.emulator;
  static bool get isStaging => current == AppEnvironment.staging;

  static String get emulatorHost => _emulatorHost;
}
