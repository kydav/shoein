# Google & Apple Sign-In — setup

The app code is done: a "Continue with Google" button (all platforms) and a
"Sign in with Apple" button (iOS/macOS) on the login screen, wired through
`SocialAuth` → `AuthNotifier`. What's left is provider + native config that can
only be done in the Firebase / Apple / Google consoles.

## 1. Firebase console (both providers)
Authentication → Sign-in method → **Add new provider**:
- **Google** → Enable → save. Note the auto-created **Web client ID** (you'll
  need it for Android below).
- **Apple** → Enable → save. For a native iOS app that's all that's required;
  you only need the Services ID / key flow if you later add Apple sign-in on the
  web.

## 2. Android — Google
Google sign-in on Android needs a SHA-1 (and SHA-256) fingerprint registered, or
it returns no ID token.
1. Get your signing fingerprints:
   - Debug: `keytool -list -v -keystore ~/.android/debug.keystore -alias androiddebugkey -storepass android -keypass android`
   - Release: from your upload keystore, **and** grab Play App Signing's SHA-1
     from Play Console → Setup → App integrity.
2. Firebase → Project settings → your **Android app** → **Add fingerprint** for
   each SHA-1/SHA-256.
3. **Re-download `google-services.json`** and replace `android/app/google-services.json`.
   (This populates the `oauth_client` block that's currently empty.)
4. The **Web client ID** (the `client_type: 3` entry in google-services.json) is
   what Android needs as `serverClientId` to mint an ID token Firebase accepts.
   It's now **hardcoded as the default** in `lib/core/config/auth_config.dart`
   (client IDs aren't secrets — they ship in google-services.json anyway), so no
   build flag is required. If you ever rotate it or point at a different Firebase
   project, either update that default or override it with a
   `--dart-define=GOOGLE_SERVER_CLIENT_ID=…`.

## 3. iOS — Google
1. After enabling Google in Firebase, **re-download `GoogleService-Info.plist`**
   (it'll now contain `CLIENT_ID` / `REVERSED_CLIENT_ID`) → replace
   `ios/Runner/GoogleService-Info.plist`.
2. Add the reversed client ID as a URL scheme. In Xcode: Runner target → Info →
   URL Types → **+**, paste the `REVERSED_CLIENT_ID` value as the URL Scheme.
   (Or add a `CFBundleURLTypes` entry to `ios/Runner/Info.plist` with that
   string.) Google sign-in cannot open its callback without this.

## 4. iOS — Apple
1. `ios/Runner/Runner.entitlements` is already created with the
   `com.apple.developer.applesignin` key.
2. In Xcode: Runner target → **Signing & Capabilities → + Capability → Sign in
   with Apple**. This links the entitlements file to the target *and* enables the
   capability on your App ID in the Apple Developer portal (required — the build
   is rejected otherwise).
3. Make sure the Apple provider is enabled in Firebase (step 1).

## 5. Test
- iOS: real device or simulator with an iCloud account → both buttons.
- Android: real device / emulator with Google Play services, signed with a key
  whose SHA-1 you registered.
- Demo mode (no Firebase) just logs in a fake Google/Apple user, so the buttons
  are always tappable while developing.

## Note on App Store review
Apple **requires** Sign in with Apple whenever you offer another third-party
login (Google). Since we now show Apple alongside Google on iOS, you're
compliant — just don't hide the Apple button on iOS.
