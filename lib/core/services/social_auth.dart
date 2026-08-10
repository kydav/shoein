import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

import 'package:shoein/core/config/auth_config.dart';

/// Thrown when the user backs out of a Google/Apple sheet. Callers treat this
/// as a silent no-op (no error message shown).
class SocialSignInCancelled implements Exception {
  const SocialSignInCancelled();
}

/// Builds Firebase [AuthCredential]s from the native Google / Apple flows.
///
/// The actual `signInWithCredential` call happens in `AuthNotifier` so all
/// Firebase state changes go through one place.
class SocialAuth {
  SocialAuth._();

  static bool _googleReady = false;

  static Future<void> _ensureGoogleInitialized() async {
    if (_googleReady) return;
    await GoogleSignIn.instance.initialize(
      // Empty string → let the platform read the client id from the native
      // Firebase config (fine on iOS). Android needs the web client id to mint
      // an ID token Firebase will accept.
      serverClientId: kGoogleServerClientId.isEmpty
          ? null
          : kGoogleServerClientId,
    );
    _googleReady = true;
  }

  /// Runs the Google sheet and returns a Firebase credential.
  /// Throws [SocialSignInCancelled] if the user dismisses it.
  static Future<OAuthCredential> googleCredential() async {
    await _ensureGoogleInitialized();
    try {
      final account = await GoogleSignIn.instance.authenticate();
      final idToken = account.authentication.idToken;
      if (idToken == null) {
        throw FirebaseAuthException(
          code: 'missing-google-id-token',
          message: 'Google did not return an ID token.',
        );
      }
      return GoogleAuthProvider.credential(idToken: idToken);
    } on GoogleSignInException catch (e) {
      if (e.code == GoogleSignInExceptionCode.canceled) {
        throw const SocialSignInCancelled();
      }
      rethrow;
    }
  }

  /// Runs the Apple sheet and returns a Firebase credential plus the display
  /// name (Apple only surfaces the name on the *first* authorization, so we
  /// capture it here to set on the fresh Firebase user).
  /// Throws [SocialSignInCancelled] if the user dismisses it.
  static Future<({OAuthCredential credential, String? displayName})>
  appleCredential() async {
    final rawNonce = _generateNonce();
    final hashedNonce = sha256.convert(utf8.encode(rawNonce)).toString();
    try {
      final apple = await SignInWithApple.getAppleIDCredential(
        scopes: const [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
        nonce: hashedNonce,
      );
      final credential = OAuthProvider(
        'apple.com',
      ).credential(idToken: apple.identityToken, rawNonce: rawNonce);
      final name = '${apple.givenName ?? ''} ${apple.familyName ?? ''}'.trim();
      return (credential: credential, displayName: name.isEmpty ? null : name);
    } on SignInWithAppleAuthorizationException catch (e) {
      if (e.code == AuthorizationErrorCode.canceled) {
        throw const SocialSignInCancelled();
      }
      rethrow;
    }
  }

  static String _generateNonce([int length = 32]) {
    const charset =
        '0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz-._';
    final random = Random.secure();
    return List.generate(
      length,
      (_) => charset[random.nextInt(charset.length)],
    ).join();
  }
}
