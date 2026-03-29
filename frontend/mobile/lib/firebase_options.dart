// Firebase options for local emulator development.
// Replace with real options from `flutterfire configure` before production deploy.
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show TargetPlatform, defaultTargetPlatform, kIsWeb;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) return web;
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      case TargetPlatform.macOS:
        return macos;
      default:
        return android;
    }
  }

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'dev-api-key',
    appId: '1:000000000000:android:0000000000000000000000',
    messagingSenderId: '000000000000',
    projectId: 'way2move-dev',
    storageBucket: 'way2move-dev.appspot.com',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'dev-api-key',
    appId: '1:000000000000:ios:0000000000000000000000',
    messagingSenderId: '000000000000',
    projectId: 'way2move-dev',
    storageBucket: 'way2move-dev.appspot.com',
    iosBundleId: 'com.way2move.app',
  );

  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'dev-api-key',
    appId: '1:000000000000:ios:0000000000000000000000',
    messagingSenderId: '000000000000',
    projectId: 'way2move-dev',
    storageBucket: 'way2move-dev.appspot.com',
    iosBundleId: 'com.way2move.app',
  );

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'dev-api-key',
    appId: '1:000000000000:web:0000000000000000000000',
    messagingSenderId: '000000000000',
    projectId: 'way2move-dev',
    storageBucket: 'way2move-dev.appspot.com',
    authDomain: 'way2move-dev.firebaseapp.com',
  );
}
