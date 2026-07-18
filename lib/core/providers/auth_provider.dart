import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shoein/core/services/firebase_bootstrap.dart';

/// Auth state. Backed by Firebase Auth when configured; otherwise a local demo
/// session so the app is fully usable before `flutterfire configure`.
class AuthNotifier extends ChangeNotifier {
  FirebaseAuth? get _auth => firebaseReady ? FirebaseAuth.instance : null;

  bool _demoLoggedIn = false;
  String _demoName = '';
  String _demoEmail = '';

  AuthNotifier() {
    _auth?.authStateChanges().listen((_) => notifyListeners());
  }

  bool get isLoggedIn =>
      firebaseReady ? _auth!.currentUser != null : _demoLoggedIn;

  String get uid =>
      firebaseReady ? (_auth!.currentUser?.uid ?? '') : 'demo-user';

  String get userEmail =>
      firebaseReady ? (_auth!.currentUser?.email ?? '') : _demoEmail;

  String get userName {
    if (firebaseReady) {
      final user = _auth!.currentUser;
      if (user?.displayName?.isNotEmpty ?? false) return user!.displayName!;
      final email = user?.email ?? '';
      return email.isNotEmpty ? email.split('@').first : 'Farrier';
    }
    if (_demoName.isNotEmpty) return _demoName;
    return _demoEmail.isNotEmpty ? _demoEmail.split('@').first : 'Farrier';
  }

  String get userInitials {
    final parts = userName.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
    }
    if (userName.isNotEmpty) return userName[0].toUpperCase();
    return 'F';
  }

  Future<void> signIn({required String email, required String password}) async {
    if (!firebaseReady) {
      _demoLoggedIn = true;
      _demoEmail = email;
      notifyListeners();
      return;
    }
    await _auth!.signInWithEmailAndPassword(email: email, password: password);
  }

  Future<void> signUp({
    required String email,
    required String password,
    String? name,
  }) async {
    if (!firebaseReady) {
      _demoLoggedIn = true;
      _demoEmail = email;
      _demoName = name ?? '';
      notifyListeners();
      return;
    }
    final cred = await _auth!.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
    if (name != null && name.trim().isNotEmpty) {
      await cred.user?.updateDisplayName(name.trim());
    }
    notifyListeners();
  }

  Future<void> sendPasswordReset(String email) async {
    if (!firebaseReady) return;
    await _auth!.sendPasswordResetEmail(email: email);
  }

  Future<void> signOut() async {
    if (!firebaseReady) {
      _demoLoggedIn = false;
      notifyListeners();
      return;
    }
    await _auth!.signOut();
  }
}

final authNotifierProvider = ChangeNotifierProvider<AuthNotifier>(
  (ref) => AuthNotifier(),
);
