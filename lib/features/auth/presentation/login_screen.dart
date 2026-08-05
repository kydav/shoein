import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:shoein/core/providers/auth_provider.dart';
import 'package:shoein/core/services/firebase_bootstrap.dart';
import 'package:shoein/core/theme/app_theme.dart';

/// Turns raw auth exceptions into short, friendly messages for end users.
String friendlyAuthError(Object e, {required bool isSignUp}) {
  if (e is FirebaseAuthException) {
    switch (e.code) {
      case 'invalid-email':
        return "That email address doesn't look right.";
      case 'user-disabled':
        return 'This account has been disabled. Contact support if you think this is a mistake.';
      case 'user-not-found':
      case 'wrong-password':
      case 'invalid-credential':
        return 'Incorrect email or password. Please try again.';
      case 'email-already-in-use':
        return 'An account with this email already exists. Try signing in instead.';
      case 'weak-password':
        return 'Please choose a stronger password — at least 6 characters.';
      case 'missing-password':
        return 'Please enter your password.';
      case 'network-request-failed':
        return 'No internet connection. Check your network and try again.';
      case 'too-many-requests':
        return 'Too many attempts. Please wait a moment and try again.';
      case 'operation-not-allowed':
        return "Email sign-in isn't available right now. Please try again later.";
      default:
        return isSignUp
            ? "We couldn't create your account. Please try again."
            : "We couldn't sign you in. Please try again.";
    }
  }
  return 'Something went wrong. Please try again.';
}

class LoginScreen extends HookConsumerWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isSignUp = useState(false);
    final name = useTextEditingController();
    final email = useTextEditingController();
    final password = useTextEditingController();
    final busy = useState(false);
    final error = useState<String?>(null);

    Future<void> submit() async {
      // Basic client-side checks so users get instant, clear feedback.
      if (email.text.trim().isEmpty || password.text.isEmpty) {
        error.value = 'Please enter your email and password.';
        return;
      }
      if (isSignUp.value && name.text.trim().isEmpty) {
        error.value = 'Please enter your name.';
        return;
      }
      busy.value = true;
      error.value = null;
      try {
        final auth = ref.read(authNotifierProvider);
        if (isSignUp.value) {
          await auth.signUp(
            email: email.text.trim(),
            password: password.text,
            name: name.text.trim(),
          );
        } else {
          await auth.signIn(email: email.text.trim(), password: password.text);
        }
        // On success the auth state changes and the router navigates away,
        // disposing this screen — so we don't reset `busy` here.
      } catch (e) {
        error.value = friendlyAuthError(e, isSignUp: isSignUp.value);
        busy.value = false;
      }
    }

    return Scaffold(
      backgroundColor: kAnvil,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Center(
                    child: Image.asset(
                      'assets/logo/shoein_mark.png',
                      width: 96,
                      height: 96,
                      filterQuality: FilterQuality.medium,
                    ),
                  ),
                  const SizedBox(height: 14),
                  const Text(
                    "Shoein'",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 30,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Client & horse management for farriers',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.7),
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 30),
                  Container(
                    padding: const EdgeInsets.all(22),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        if (isSignUp.value) ...[
                          TextField(
                            controller: name,
                            textCapitalization: TextCapitalization.words,
                            textInputAction: TextInputAction.next,
                            decoration: const InputDecoration(
                              labelText: 'Your name',
                            ),
                          ),
                          const SizedBox(height: 12),
                        ],
                        TextField(
                          controller: email,
                          keyboardType: TextInputType.emailAddress,
                          autocorrect: false,
                          textInputAction: TextInputAction.next,
                          decoration: const InputDecoration(labelText: 'Email'),
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          controller: password,
                          obscureText: true,
                          textInputAction: TextInputAction.done,
                          decoration: const InputDecoration(
                            labelText: 'Password',
                          ),
                          onSubmitted: (_) => submit(),
                        ),
                        if (error.value != null) ...[
                          const SizedBox(height: 12),
                          Text(
                            error.value!,
                            style: const TextStyle(
                              color: kOverdueRed,
                              fontSize: 12,
                            ),
                          ),
                        ],
                        const SizedBox(height: 18),
                        FilledButton(
                          onPressed: busy.value ? null : submit,
                          child: busy.value
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : Text(
                                  isSignUp.value ? 'Create account' : 'Sign in',
                                ),
                        ),
                        TextButton(
                          onPressed: () => isSignUp.value = !isSignUp.value,
                          child: Text(
                            isSignUp.value
                                ? 'Already have an account? Sign in'
                                : 'New here? Create an account',
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (!firebaseReady) ...[
                    const SizedBox(height: 16),
                    Text(
                      'Demo mode — Firebase not configured. Any email/password works.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: kForge.withValues(alpha: 0.9),
                        fontSize: 11,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
