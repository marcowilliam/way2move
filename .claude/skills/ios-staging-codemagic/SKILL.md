---
name: "ios-staging-codemagic"
description: "Deploys a Flutter iOS app to TestFlight via Codemagic CI. Use when setting up a new staging pipeline, troubleshooting a failed build, or performing routine release tasks (version bumps, plist injection, CocoaPods issues)."

---
# iOS Staging with Codemagic

## Contents
- [Mental Model](#mental-model)
- [One-time Setup Checklist](#one-time-setup-checklist)
- [Direct Device Deploy (without Codemagic)](#direct-device-deploy-without-codemagic)
- [Recurring Release Tasks](#recurring-release-tasks)
- [codemagic.yaml Reference](#codemagiccyaml-reference)
- [Troubleshooting — Error → Fix Table](#troubleshooting--error--fix-table)
- [Lessons Learned (Hard-Won)](#lessons-learned-hard-won)

---

## Mental Model

The pipeline has four independent concerns. Debug them independently:

```
1. Code signing    → certificate + provisioning profile + bundle ID all match
2. Firebase init   → GoogleService-Info.plist has correct BUNDLE_ID, injected at build time
3. Build           → flutter build ipa succeeds, IPA is produced
4. Upload          → App Store Connect API key is valid, build number is higher than previous
```

A failure in step 1 never causes a step 4 error. Identify which step failed first.

---

## One-time Setup Checklist

### Step 1 — Pick your bundle ID and use it everywhere

Bundle ID for Way2Move: `com.way2move.app`

| Place | Must match |
|---|---|
| `ios/Runner.xcodeproj/project.pbxproj` → `PRODUCT_BUNDLE_IDENTIFIER` | ✓ |
| Apple Developer Portal → App ID | ✓ |
| App Store Connect → App Information → Bundle ID | ✓ |
| Provisioning profile (created for that App ID) | ✓ |
| `codemagic.yaml` → `ios_signing.bundle_identifier` | ✓ |
| `codemagic.yaml` → export options plist key | ✓ |
| `GoogleService-Info.plist` → `BUNDLE_ID` field | ✓ |

A mismatch at any point causes a cryptic error at a different step.

### Step 2 — Set up Firebase staging project

1. Create Firebase project `way2move-dev` at https://console.firebase.google.com
2. Add an iOS app with bundle ID `com.way2move.app`
3. Download `GoogleService-Info.plist` — **do not commit it to git**
4. Enable Auth (Email/Password, Google, Apple), Firestore, Storage, Functions
5. Run `flutterfire configure` to regenerate `firebase_options.dart` with real values:
   ```bash
   cd frontend/mobile
   flutterfire configure --project=way2move-dev
   ```

### Step 3 — Register App ID in Apple Developer Portal

1. https://developer.apple.com/account/resources/identifiers/list → **+** → App IDs → App
2. Bundle ID: **Explicit** → `com.way2move.app`
3. Capabilities: tick **Sign in with Apple**
4. Register

### Step 4 — Create app in App Store Connect

1. https://appstoreconnect.apple.com → My Apps → **+** → New App
2. Platform: iOS, Bundle ID: select `com.way2move.app`
3. The bundle ID is **permanent** — you cannot change it after creation

### Step 5 — Create distribution certificate (Linux/any OS)

```bash
openssl genrsa -out distribution.key 2048
openssl req -new -key distribution.key \
  -out distribution.csr \
  -subj "/emailAddress=you@email.com/CN=YourName/C=US"
```

Upload `distribution.csr` at https://developer.apple.com/account/resources/certificates/list → **+** → Apple Distribution.

Download `distribution.cer`, then convert to `.p12`:

```bash
openssl x509 -in distribution.cer -inform DER -out distribution.pem
openssl pkcs12 -export \
  -inkey distribution.key \
  -in distribution.pem \
  -out distribution.p12 \
  -name "Apple Distribution"
```

Set a password — you'll need it in Codemagic.

### Step 6 — Create provisioning profile

1. https://developer.apple.com/account/resources/profiles/list → **+** → App Store Connect
2. Select the App ID from Step 3 and the certificate from Step 5
3. **Note the exact profile name** — you'll use it verbatim in the export options plist

### Step 7 — Create App Store Connect API key

1. https://appstoreconnect.apple.com/access/integrations/api → **+**
2. Access: **Developer**
3. Download the `.p8` file **(one-time only)**
4. Note **Key ID** (10 chars) and **Issuer ID** (UUID)

### Step 8 — Configure Codemagic

1. Teams → Integrations → Apple Developer Portal → Connect → upload `.p8`, enter Key ID + Issuer ID → give it a name
2. Teams → Code signing identities → iOS certificates → upload `.p12` + password
3. Teams → Code signing identities → Provisioning profiles → upload `.mobileprovision`

### Step 9 — GoogleService-Info.plist (Firebase)

The plist is gitignored (it contains API keys). Inject it at build time:

1. Copy the contents of `GoogleService-Info.plist` (downloaded from Firebase Console)
2. In Codemagic → your app → Environment variables → add:
   - Name: `GOOGLE_SERVICE_INFO_PLIST`
   - Value: paste the entire plist contents
   - Check **Secure**
3. Add this script step in `codemagic.yaml` **before** `flutter pub get`:
   ```yaml
   - name: Write GoogleService-Info.plist
     script: |
       echo "$GOOGLE_SERVICE_INFO_PLIST" > frontend/mobile/ios/Runner/GoogleService-Info.plist
   ```

**Critical:** the plist `BUNDLE_ID` field must match the actual app bundle ID. Download the plist from Firebase Console → iOS app with the correct bundle ID registered.

**Critical:** The file must also be registered in `Runner.xcodeproj/project.pbxproj` as a resource — see Lessons Learned.

---

## Direct Device Deploy (without Codemagic)

To run the staging build directly on your iPhone (no TestFlight):

```bash
# 1. Get device ID
flutter devices

# 2. Run in staging mode on device
cd frontend/mobile
flutter run --dart-define=ENV=staging -d <device-id>

# 3. Or build a release IPA for manual install via Xcode
flutter build ipa --dart-define=ENV=staging
# Then open Xcode → Window → Devices and Simulators → drag IPA to device
```

**Pre-requisites:**
- `GoogleService-Info.plist` must exist at `ios/Runner/GoogleService-Info.plist` (real values from Firebase Console, not the placeholder)
- `firebase_options.dart` must have real values (run `flutterfire configure --project=way2move-dev`)
- Device must be registered in your Apple Developer account
- Development provisioning profile must include the device

---

## Recurring Release Tasks

### Bump the build number before each TestFlight upload

Apple requires `CFBundleVersion` to be strictly higher than the previous upload. In Flutter, this is the number after `+` in `pubspec.yaml`:

```yaml
version: 1.0.0+3   # 3 is CFBundleVersion, 1.0.0 is CFBundleShortVersionString
```

Bump the `+N` part before every new build. Never re-use a number.

---

## codemagic.yaml Reference

```yaml
workflows:
  flutter-staging-ios:
    name: Flutter Staging Build (iOS)
    instance_type: mac_mini_m1
    max_build_duration: 120
    integrations:
      app_store_connect: <integration-name>   # exact name from Codemagic Teams → Integrations
    environment:
      flutter: stable
      xcode: latest
      cocoapods: default
      ios_signing:
        distribution_type: app_store
        bundle_identifier: com.way2move.app
      vars:
        FLUTTER_BUILD_ARGS: "--dart-define=ENV=staging"
    scripts:
      - name: Set up keychain
        script: |
          keychain initialize
      - name: Set up code signing
        script: |
          keychain add-certificates
          xcode-project use-profiles
      - name: Create export options plist
        script: |
          cat << EOF > /Users/builder/export_options.plist
          <?xml version="1.0" encoding="UTF-8"?>
          <!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
          <plist version="1.0">
          <dict>
            <key>method</key>
            <string>app-store</string>
            <key>provisioningProfiles</key>
            <dict>
              <key>com.way2move.app</key>
              <string><exact-profile-name-from-apple-portal></string>
            </dict>
          </dict>
          </plist>
          EOF
      - name: Write GoogleService-Info.plist
        script: |
          echo "$GOOGLE_SERVICE_INFO_PLIST" > frontend/mobile/ios/Runner/GoogleService-Info.plist
      - name: Get Flutter packages
        script: |
          cd frontend/mobile
          flutter pub get
      - name: Install CocoaPods dependencies
        script: |
          cd frontend/mobile/ios
          pod install --repo-update
      - name: Build IPA for iOS
        script: |
          cd frontend/mobile
          flutter build ipa \
            --release \
            --export-options-plist=/Users/builder/export_options.plist \
            $FLUTTER_BUILD_ARGS
    artifacts:
      - frontend/mobile/build/ios/ipa/*.ipa
    publishing:
      app_store_connect:
        auth: integration
        submit_to_testflight: true
        beta_groups:
          - testers
```

---

## Troubleshooting — Error → Fix Table

| Error message | Root cause | Fix |
|---|---|---|
| `Firebase has not been correctly initialized` | `GoogleService-Info.plist` has wrong `BUNDLE_ID` or is missing from the bundle | Download correct plist from Firebase Console (matching bundle ID), inject via `GOOGLE_SERVICE_INFO_PLIST` env var |
| `The bundle version must be higher than the previously uploaded version` | `CFBundleVersion` (the `+N` in `pubspec.yaml`) is ≤ previous upload | Bump `+N` in `pubspec.yaml`, commit, push, trigger **new** build |
| `No valid code signing certificates were found` | Certificate not in keychain | Add `keychain initialize` + `keychain add-certificates` + `xcode-project use-profiles` before the build |
| `No matching profiles found for bundle identifier` | Profile was created for a different bundle ID | Create new profile for the correct bundle ID in Apple portal |
| `No "iOS App Store" profiles for team matching 'X'` | Export plist profile name doesn't match Apple portal name exactly | Use the exact profile name from developer.apple.com/account/resources/profiles |
| `Cannot determine the Apple ID from Bundle ID` | App Store Connect app has different bundle ID than the IPA | Both must match — check App Store Connect → App Information → Bundle ID |
| `Authentication credentials are missing or invalid` (401) | Wrong Key ID in Codemagic integration | Verify Key ID at appstoreconnect.apple.com/access/integrations/api, update in Codemagic |
| `auth: "integration" requires workflow -> integrations -> app_store_connect` | `integrations` block missing from yaml | Add `integrations: app_store_connect: <name>` at the workflow level |
| `CDN: trunk URL couldn't be downloaded ... Response: 429` | GitHub rate-limits shared CI IPs hitting raw.githubusercontent.com | Commit `ios/Podfile` with `source 'https://github.com/CocoaPods/Specs.git'` as first line |
| `Automatically assigning platform iOS` warning | Podfile not committed — generated fresh each build without platform line | Commit Podfile with `platform :ios, '13.0'` explicitly set |
| `ITMS-90683: Missing purpose string in Info.plist` | Firebase/camera/microphone SDKs require usage descriptions | Already added to `Info.plist`: NSPhotoLibraryUsageDescription, NSCameraUsageDescription, NSMicrophoneUsageDescription |
| `500 internal server error` then `UPLOAD SUCCEEDED` but build marked failed | Transient Apple CDN error during asset upload; altool retried and succeeded | Check App Store Connect → Activity. If the build is there, it uploaded fine. Retrigger if not. |
| `Firebase has not been correctly initialized` even though plist write step exits 0 | `GoogleService-Info.plist` is not referenced in `Runner.xcodeproj/project.pbxproj` — the file is on disk but never bundled into the app | Add the plist to the Xcode project: `PBXBuildFile`, `PBXFileReference`, `PBXGroup` (Runner), and `PBXResourcesBuildPhase` entries in `project.pbxproj` |

---

## Lessons Learned (Hard-Won)

### Always trigger a new build — never re-run
Codemagic's "re-run" button uses the same commit. After pushing a fix, always click **Start new build** and select the branch.

### The plist BUNDLE_ID is validated at runtime, not build time
Firebase iOS SDK checks the `BUNDLE_ID` in the plist against the running app's bundle ID. A mismatch causes a silent failure at init — the app opens with a Firebase error, not a build error. There's no compile-time warning.

### Build number vs version number
- `CFBundleShortVersionString` = the `1.0.0` part → shown to users in App Store / TestFlight
- `CFBundleVersion` = the `+3` part → must increment on every TestFlight upload, never shown to users
- You can keep `1.0.0` for months while incrementing the build number on every push

### Codemagic matches signing assets by bundle ID automatically
Do not specify `certificate_name` or `provisioning_profile_name` in `ios_signing`. Codemagic automatically picks the right certificate and profile from your uploaded assets based on `bundle_identifier` + `distribution_type`. Manual name overrides cause errors.

### The Podfile must be in git
Codemagic generates a fresh Podfile on each build if none exists. The auto-generated one always uses the CDN trunk source, which hits GitHub's rate limiter on shared CI IPs. Committing your own Podfile with the git source bypasses this entirely.

### GoogleService-Info.plist belongs in environment variables, not git
The plist contains an API key. Git history is forever. Use Codemagic's **Secure** environment variable to store the plist contents and write it to disk at build time. Store the value as base64 to avoid multiline XML corruption:
```bash
echo "$GOOGLE_SERVICE_INFO_PLIST" | base64 --decode > frontend/mobile/ios/Runner/GoogleService-Info.plist
```

### GoogleService-Info.plist must be in the Xcode project, not just on disk
Writing the file to `ios/Runner/GoogleService-Info.plist` at CI time is not enough. The file must be registered in `Runner.xcodeproj/project.pbxproj` as a resource, otherwise Xcode never bundles it into the app and Firebase initialization fails at runtime with no clear error. Add entries to: `PBXBuildFile`, `PBXFileReference`, `PBXGroup` (Runner children), and `PBXResourcesBuildPhase` (Runner Resources files list).

### ENV dart-define controls emulator vs staging — not kDebugMode
`kDebugMode` is true even when running a debug build against staging. Use `--dart-define=ENV=staging` and check `Env.isStaging` to control which Firebase endpoint is used. This lets you run debug builds against live Firebase for testing.
