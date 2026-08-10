/// Social sign-in configuration.
///
/// [kGoogleServerClientId] is the **Web** OAuth 2.0 client ID from the Firebase
/// console (Authentication → Sign-in method → Google → Web SDK configuration,
/// or the `client_type: 3` entry in google-services.json once Google sign-in is
/// enabled). It's required on Android so Google returns an ID token whose
/// audience Firebase will accept. On iOS the client ID is read automatically
/// from GoogleService-Info.plist, so this can stay empty for iOS-only testing.
///
/// Defaults to this project's Web client ID (the `client_type: 3` entry in
/// google-services.json). Client IDs are not secrets — they ship inside the app
/// via google-services.json / GoogleService-Info.plist — so hardcoding the
/// default here means Google sign-in works on Android without a build flag. A
/// `GOOGLE_SERVER_CLIENT_ID` dart-define still overrides it if ever needed.
const String kGoogleServerClientId = String.fromEnvironment(
  'GOOGLE_SERVER_CLIENT_ID',
  defaultValue:
      '309428367489-crtner8sps74iung9l2f9hl6d8p16u7n.apps.googleusercontent.com',
);
