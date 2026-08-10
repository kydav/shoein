/// Social sign-in configuration.
///
/// [kGoogleServerClientId] is the **Web** OAuth 2.0 client ID from the Firebase
/// console (Authentication → Sign-in method → Google → Web SDK configuration,
/// or the `client_type: 3` entry in google-services.json once Google sign-in is
/// enabled). It's required on Android so Google returns an ID token whose
/// audience Firebase will accept. On iOS the client ID is read automatically
/// from GoogleService-Info.plist, so this can stay empty for iOS-only testing.
///
/// Leave empty until Google sign-in is enabled in Firebase — the button still
/// renders, it just can't complete until this is filled in.
const String kGoogleServerClientId = String.fromEnvironment(
  'GOOGLE_SERVER_CLIENT_ID',
);
