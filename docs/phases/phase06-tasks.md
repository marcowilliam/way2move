# Phase 6 — Deployment & Distribution: Implementation Checklist

> **Depends on:** nothing (can start mid-Phase 1)
> **Can run parallel with:** Phase 1 and all subsequent phases
> **Blocks:** public launch (but not development)

**Status: Not started (2026-03-31). Block 0 is manual/external. Block 1 onward has code tasks.**

### What an AI can do vs what needs a human
- **Needs human:** Block 0 (create developer accounts, configure signing keys), Block 3 (draft legal docs, host them), Block 4 (write store copy, create screenshots), Block 7 (submit for review, monitor)
- **AI can implement:** Block 1 (app icon code + splash screen), Block 2 (Firebase prod config code), Block 5 (CI/CD config files), Block 6 (RevenueCat integration code)

---

## Block 0 — App Store and Google Play Accounts ⚠️ HUMAN REQUIRED

- [ ] Create Apple Developer account (or use existing org account)
- [ ] Create Google Play Developer account
- [ ] Set up App Store Connect app entry
- [ ] Set up Google Play Console app entry
- [ ] Configure signing keys (Android keystore, iOS certificates + provisioning profiles)

> Cannot be done by AI. Requires the developer to log in to Apple/Google portals.

---

## Block 1 — App Identity ← AI CAN DO (code parts)

- [ ] Design app icon (1024x1024 source, all platform sizes) ⚠️ needs designer or AI image gen
- [ ] Design adaptive icon for Android (foreground + background layers) ⚠️ needs designer
- [ ] Create splash screen (native splash via flutter_native_splash) ← AI can do
- [ ] Set bundle ID: com.way2move.app (iOS) and applicationId (Android) ← AI can do
- [ ] Set app display name for both platforms ← AI can do
- [ ] Configure launch screen storyboard (iOS) ← AI can do

### Implementation notes for next AI
- Bundle ID: check current value in `android/app/build.gradle.kts` (applicationId) and `ios/Runner.xcodeproj/project.pbxproj` (PRODUCT_BUNDLE_IDENTIFIER); change both to `com.way2move.app`
- App display name: `android/app/src/main/AndroidManifest.xml` (android:label) and `ios/Runner/Info.plist` (CFBundleDisplayName)
- Splash screen: add `flutter_native_splash` to pubspec.yaml; create `flutter_native_splash.yaml` at project root with brand colors from `lib/core/theme/`; run `dart run flutter_native_splash:create`
- App icon: if no icon asset is provided, create a placeholder SVG programmatically or use `flutter_launcher_icons` with a color block and "W2M" text as placeholder; the real icon can be swapped later

---

## Block 2 — Production Firebase Configuration ← AI CAN DO (code parts)

- [ ] Create production Firebase project (separate from dev) ⚠️ needs human (Firebase Console login)
- [ ] Configure Firebase Auth providers (email, Google, Apple) for production ⚠️ needs human
- [ ] Deploy Firestore security rules to production ← AI can do (once prod project exists)
- [ ] Deploy Cloud Functions to production ← AI can do (once prod project exists)
- [ ] Run seed script against production Firestore ← AI can do (once prod project exists)
- [ ] Set up Firebase Crashlytics for production crash reporting ← AI can do
- [ ] Configure environment-based Firebase config switching (dev vs prod) ← AI can do

### Implementation notes for next AI
- Environment switching: use `--dart-define=ENVIRONMENT=production` build flag; in `main.dart` read `const String env = String.fromEnvironment('ENVIRONMENT', defaultValue: 'development'); `; load the matching `google-services.json` / `GoogleService-Info.plist` via flavor or copy script
- Crashlytics: add `firebase_crashlytics` to pubspec; call `FlutterError.onError = FirebaseCrashlytics.instance.recordFlutterFatalError` in `main.dart`; also `PlatformDispatcher.instance.onError`
- Firestore + Functions deploy: `firebase use production && firebase deploy --only firestore,functions` — requires prod project to exist first

---

## Block 3 — Privacy Policy and Terms of Service ← MIXED (AI drafts, human reviews)

- [ ] Draft privacy policy (data collected, storage, third-party services, deletion rights) ← AI can draft
- [ ] Draft terms of service ← AI can draft
- [ ] Host privacy policy and ToS at public URL (GitHub Pages or Firebase Hosting) ← AI can do
- [ ] Add links to privacy policy and ToS in app settings and sign-up flow ← AI can do
- [ ] Ensure GDPR compliance (data export, account deletion) ← AI can implement data export/deletion

### Implementation notes for next AI
- GDPR data export: Cloud Function `exportUserData` — callable; collects all user Firestore docs and returns as JSON download
- GDPR account deletion: Cloud Function `deleteUserAccount` — callable; deletes all user docs from Firestore + Auth user + Storage files
- Add both functions to `backend/functions/src/gdpr/`
- Privacy policy hosting: create a simple `index.html` in `frontend/web/privacy/` and deploy to Firebase Hosting
- In-app links: add "Privacy Policy" and "Terms of Service" items to the settings/profile page; use `url_launcher` to open the hosted URLs

---

## Block 4 — Store Listings

- [ ] Write App Store description (short + long)
- [ ] Write Google Play description (short + long)
- [ ] Create App Store screenshots (6.7", 6.5", 5.5" sizes minimum)
- [ ] Create Google Play screenshots (phone + tablet)
- [ ] Create feature graphic for Google Play (1024x500)
- [ ] Select app category and keywords for ASO
- [ ] Prepare App Store preview video (optional but recommended)

---

## Block 5 — Test Builds ← AI CAN DO (config files)

- [ ] Configure Codemagic for iOS builds (code signing, TestFlight upload) ← AI writes `codemagic.yaml`
- [ ] Configure GitHub Actions for Android builds (signed APK/AAB) ← AI writes workflow YAML
- [ ] Set up Internal Testing track on Google Play ⚠️ needs human (Play Console)
- [ ] Set up TestFlight for iOS beta testing ⚠️ needs human (App Store Connect)
- [ ] Distribute first test build to internal testers ⚠️ needs human
- [ ] Set up Sentry for error monitoring in test builds ← AI can do

### Implementation notes for next AI
- GitHub Actions Android workflow: `.github/workflows/android.yml` — build signed AAB, upload to Play Internal Testing; requires `KEYSTORE_BASE64`, `KEY_ALIAS`, `KEY_PASSWORD`, `STORE_PASSWORD` secrets in GitHub repo settings
- Codemagic iOS: `codemagic.yaml` at repo root — Flutter workflow, code signing via Codemagic certificate storage, automatic TestFlight upload; requires Apple API key in Codemagic dashboard
- Sentry: add `sentry_flutter` to pubspec; call `SentryFlutter.init()` in `main.dart`; DSN stored in `--dart-define=SENTRY_DSN`
- Check if `.github/workflows/` already exists — there may be an existing CI file to extend

---

## Block 6 — Freemium Model Implementation ← AI CAN DO (code)

- [ ] Define free tier limits (e.g., 1 active program, basic exercises, no AI assessment)
- [ ] Define premium features (unlimited programs, AI assessment, nutrition, wearable sync)
- [ ] Integrate RevenueCat for subscription management ← AI can do
- [ ] Implement paywall UI (shown when accessing premium features) ← AI can do
- [ ] Configure subscription products in App Store Connect and Google Play Console ⚠️ needs human
- [ ] Handle subscription status in app (check entitlements, gate features) ← AI can do
- [ ] Tests: unit tests for entitlement checks ← AI can do

### Implementation notes for next AI
- Package: `purchases_flutter` (RevenueCat official Flutter SDK)
- Initialize in `main.dart`: `await Purchases.configure(PurchasesConfiguration(apiKey))`; API key via `--dart-define=REVENUECAT_API_KEY`
- Create `EntitlementService` at `lib/core/services/entitlement_service.dart` — wraps RevenueCat, exposes `isPremium` stream
- Free tier limits to enforce:
  - Max 1 active program (check count before `CreateProgram`)
  - AI assessment locked (gate `MovementRecordingPage` and `AIRecommendationReviewPage`)
  - Nutrition feature locked (gate `NutritionPage`)
  - Wearable sync locked (gate `WearableConnectionPage`)
- `PaywallPage` at `/paywall` — explain premium benefits, monthly/annual pricing, subscribe CTA
- Use `EntitlementService` in Riverpod providers via `premiumProvider`; check before navigating to premium routes in `app_router.dart`
- Product IDs (to be created in App Store Connect / Play Console by human): `way2move_premium_monthly`, `way2move_premium_annual`

---

## Block 7 — Public Launch

- [ ] Submit app for App Store review
- [ ] Submit app for Google Play review
- [ ] Address any review feedback or rejections
- [ ] Phased rollout on Google Play (start at 10%)
- [ ] Monitor crash-free rate and key metrics post-launch
- [ ] Set up Firebase Analytics for key events (sign_up, session_completed, program_created)
