# Phase 6 — Deployment & Distribution: Implementation Checklist

> **Depends on:** nothing (can start mid-Phase 1)
> **Can run parallel with:** Phase 1 and all subsequent phases
> **Blocks:** public launch (but not development)

---

## Block 0 — App Store and Google Play Accounts

- [ ] Create Apple Developer account (or use existing org account)
- [ ] Create Google Play Developer account
- [ ] Set up App Store Connect app entry
- [ ] Set up Google Play Console app entry
- [ ] Configure signing keys (Android keystore, iOS certificates + provisioning profiles)

---

## Block 1 — App Identity

- [ ] Design app icon (1024x1024 source, all platform sizes)
- [ ] Design adaptive icon for Android (foreground + background layers)
- [ ] Create splash screen (native splash via flutter_native_splash)
- [ ] Set bundle ID: com.way2move.app (iOS) and applicationId (Android)
- [ ] Set app display name for both platforms
- [ ] Configure launch screen storyboard (iOS)

---

## Block 2 — Production Firebase Configuration

- [ ] Create production Firebase project (separate from dev)
- [ ] Configure Firebase Auth providers (email, Google, Apple) for production
- [ ] Deploy Firestore security rules to production
- [ ] Deploy Cloud Functions to production
- [ ] Run seed script against production Firestore
- [ ] Set up Firebase Crashlytics for production crash reporting
- [ ] Configure environment-based Firebase config switching (dev vs prod)

---

## Block 3 — Privacy Policy and Terms of Service

- [ ] Draft privacy policy (data collected, storage, third-party services, deletion rights)
- [ ] Draft terms of service
- [ ] Host privacy policy and ToS at public URL (GitHub Pages or Firebase Hosting)
- [ ] Add links to privacy policy and ToS in app settings and sign-up flow
- [ ] Ensure GDPR compliance (data export, account deletion)

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

## Block 5 — Test Builds

- [ ] Configure Codemagic for iOS builds (code signing, TestFlight upload)
- [ ] Configure GitHub Actions for Android builds (signed APK/AAB)
- [ ] Set up Internal Testing track on Google Play
- [ ] Set up TestFlight for iOS beta testing
- [ ] Distribute first test build to internal testers
- [ ] Set up Sentry for error monitoring in test builds

---

## Block 6 — Freemium Model Implementation

- [ ] Define free tier limits (e.g., 1 active program, basic exercises, no AI assessment)
- [ ] Define premium features (unlimited programs, AI assessment, nutrition, wearable sync)
- [ ] Integrate RevenueCat (or in-app purchases directly) for subscription management
- [ ] Implement paywall UI (shown when accessing premium features)
- [ ] Configure subscription products in App Store Connect and Google Play Console
- [ ] Handle subscription status in app (check entitlements, gate features)
- [ ] Tests: unit tests for entitlement checks

---

## Block 7 — Public Launch

- [ ] Submit app for App Store review
- [ ] Submit app for Google Play review
- [ ] Address any review feedback or rejections
- [ ] Phased rollout on Google Play (start at 10%)
- [ ] Monitor crash-free rate and key metrics post-launch
- [ ] Set up Firebase Analytics for key events (sign_up, session_completed, program_created)
