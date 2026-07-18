import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

/// True once a real Firebase app is initialized. Until `flutterfire configure`
/// wires up the native config, this stays false and the app runs against an
/// in-memory demo store so the whole thing is browsable.
bool firebaseReady = false;

Future<void> bootstrapFirebase() async {
  try {
    await Firebase.initializeApp();
    firebaseReady = true;
  } catch (e) {
    firebaseReady = false;
    debugPrint('Firebase not configured yet — running in demo mode. ($e)');
  }
}
