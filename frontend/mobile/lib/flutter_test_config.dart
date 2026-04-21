import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';

/// Applied to every co-located test under `lib/` (the project follows the
/// "tests next to the source" convention — see `.claude/rules/testing.md`).
/// Mirror of `test/flutter_test_config.dart`; both exist because Flutter
/// discovers these only in the directory tree of the test being run.
///
/// Purpose: neutralize google_fonts' async network fetch in tests. The fetch
/// fails instantly via the fake HttpClient below, and follow-up errors are
/// filtered out so short-lived widget tests don't fail on detached-render
/// object callbacks that fire after dispose.
Future<void> testExecutable(FutureOr<void> Function() testMain) async {
  HttpOverrides.global = _NoNetworkOverrides();
  final priorError = FlutterError.onError;
  FlutterError.onError = (details) {
    if (_isGoogleFontsNoise(details.exception.toString())) return;
    priorError?.call(details);
  };
  PlatformDispatcher.instance.onError = (error, stack) {
    return _isGoogleFontsNoise(error.toString());
  };

  await testMain();
}

bool _isGoogleFontsNoise(String msg) {
  return msg.contains('google_fonts') ||
      msg.contains('Fraunces') ||
      msg.contains('Manrope') ||
      msg.contains('JetBrainsMono');
}

class _NoNetworkOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) => _FakeHttpClient();
}

class _FakeHttpClient implements HttpClient {
  @override
  Future<HttpClientRequest> openUrl(String method, Uri url) =>
      Future.error(Exception('offline test environment'));

  @override
  noSuchMethod(Invocation i) => super.noSuchMethod(i);
}
