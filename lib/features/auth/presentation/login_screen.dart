import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:shoein/core/providers/auth_provider.dart';
import 'package:shoein/core/services/firebase_bootstrap.dart';
import 'package:shoein/core/theme/app_theme.dart';

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
      } catch (e) {
        error.value = e.toString();
      } finally {
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
                  Container(
                    width: 68,
                    height: 68,
                    decoration: BoxDecoration(
                      color: kForge,
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: const Icon(
                      Icons.hardware_rounded,
                      color: Colors.white,
                      size: 36,
                    ),
                  ),
                  const SizedBox(height: 18),
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
                          decoration: const InputDecoration(labelText: 'Email'),
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          controller: password,
                          obscureText: true,
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
