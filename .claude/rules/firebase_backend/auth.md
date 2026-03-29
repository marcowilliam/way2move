# Firebase Backend — Authentication

## Providers
- Email + password
- Google sign-in
- Apple sign-in (required for iOS App Store monetization)

All via Firebase Auth. No custom auth server.

## Flutter integration

### Auth state as a StreamProvider
The current user is treated as a stream — it changes on login/logout and GoRouter reacts to it:
```dart
// features/auth/presentation/providers/auth_provider.dart
final authStateProvider = StreamProvider<User?>((ref) {
  return ref.watch(firebaseAuthProvider).authStateChanges();
});
```

### Auth datasource
```dart
// features/auth/data/datasources/firebase_auth_datasource.dart
class FirebaseAuthDatasource {
  final FirebaseAuth _auth;
  FirebaseAuthDatasource(this._auth);

  Future<UserCredential> signInWithEmail(String email, String password) =>
      _auth.signInWithEmailAndPassword(email: email, password: password);

  Future<UserCredential> signUpWithEmail(String email, String password) =>
      _auth.createUserWithEmailAndPassword(email: email, password: password);

  Future<UserCredential> signInWithGoogle() async {
    final googleUser = await GoogleSignIn().signIn();
    if (googleUser == null) throw const SignInCancelledException();
    final googleAuth = await googleUser.authentication;
    final credential = GoogleAuthProvider.credential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );
    return _auth.signInWithCredential(credential);
  }

  Future<void> signOut() => _auth.signOut();
}
```

### After sign-up: user document creation
The Cloud Function `onUserCreate` (Auth trigger) automatically creates the Firestore user document when a new user is created. Flutter does not need to create this document manually.

```
User signs up → Firebase Auth creates UID → onUserCreate trigger fires → users/{uid} created in Firestore
```

### Providers wiring
```dart
final firebaseAuthProvider = Provider<FirebaseAuth>((ref) => FirebaseAuth.instance);

final firebaseAuthDatasourceProvider = Provider((ref) =>
    FirebaseAuthDatasource(ref.watch(firebaseAuthProvider)));

final authRepositoryProvider = Provider<AuthRepository>((ref) =>
    AuthRepositoryImpl(ref.watch(firebaseAuthDatasourceProvider)));
```

## Token handling
Firebase ID tokens are managed entirely by the SDK. Never store tokens manually.
- The SDK refreshes tokens automatically before expiry (every ~1 hour)
- When calling Cloud Functions via the `httpsCallable` interface, the SDK passes the token automatically
- For REST calls to Firebase-protected resources, use `await FirebaseAuth.instance.currentUser!.getIdToken()`

## Apple sign-in (iOS)
Apple sign-in requires:
1. `sign_in_with_apple` Flutter package
2. App entitlement `com.apple.developer.applesignin` in `Runner.entitlements`
3. Service ID configured in Firebase Console → Authentication → Apple
4. Nonce generation for security (handled by the package)

```dart
Future<UserCredential> signInWithApple() async {
  final nonce = generateNonce();
  final appleCredential = await SignInWithApple.getAppleIDCredential(
    scopes: [AppleIDAuthorizationScopes.email, AppleIDAuthorizationScopes.fullName],
    nonce: sha256ofString(nonce),
  );
  final oAuthCredential = OAuthProvider('apple.com').credential(
    idToken: appleCredential.identityToken,
    rawNonce: nonce,
  );
  return FirebaseAuth.instance.signInWithCredential(oAuthCredential);
}
```

## Local emulator setup
In development, Firebase Auth runs locally. Initialize the emulator in `main.dart`:
```dart
// main.dart — debug only
if (kDebugMode) {
  await FirebaseAuth.instance.useAuthEmulator('localhost', 9099);
  FirebaseFirestore.instance.useFirestoreEmulator('localhost', 8080);
}
```

## Error codes (email/password)
Handle these in `AuthRepositoryImpl`:
| Firebase error code | User-facing meaning |
|---|---|
| `wrong-password` | Incorrect password |
| `user-not-found` | No account with this email |
| `email-already-in-use` | Account already exists |
| `invalid-email` | Email format invalid |
| `too-many-requests` | Account temporarily locked |
| `network-request-failed` | No internet connection |
