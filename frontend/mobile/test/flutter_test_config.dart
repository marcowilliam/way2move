import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';

/// Applies to every test in `test/`. This is Flutter's opt-in global test
/// setup hook — see https://docs.flutter.dev/testing/overview.
///
/// We use it to neutralize [google_fonts] in the test environment.
/// google_fonts tries to fetch TTFs over HTTP on the first style resolution.
/// Tests run offline, so the request fails; the error surfaces asynchronously
/// and can reach a detached RenderObject in short-lived widget tests. The
/// overrides here make the fetch fail instantly with a caught error, and the
/// onError filters swallow the follow-up google_fonts noise.
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
