import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shoein/core/config/revenue_cat_config.dart';
import 'package:shoein/core/providers/auth_provider.dart';
import 'package:shoein/core/services/firebase_bootstrap.dart';
import 'package:shoein/core/services/subscription_service.dart';

enum AccessStatus { loading, trialing, subscribed, expired }

/// Reads/creates the write-once `trialStartedAt` on the user's doc.
class TrialService {
  TrialService(this._db, this._uid);
  final FirebaseFirestore _db;
  final String _uid;

  DocumentReference<Map<String, dynamic>> get _doc =>
      _db.collection('users').doc(_uid);

  /// Set the trial start once, the first time the user is seen.
  Future<void> ensureStarted() async {
    final snap = await _doc.get();
    if (!snap.exists || snap.data()?['trialStartedAt'] == null) {
      await _doc.set({
        'trialStartedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    }
  }

  Stream<DateTime?> watch() => _doc.snapshots().map(
    (d) => (d.data()?['trialStartedAt'] as Timestamp?)?.toDate(),
  );
}

/// When the current user's trial started (null until the server timestamp
/// resolves). Ensures the trial is started on first read.
final trialStartProvider = StreamProvider<DateTime?>((ref) {
  if (!firebaseReady) return Stream.value(DateTime.now());
  final uid = ref.watch(authNotifierProvider).uid;
  if (uid.isEmpty) return Stream.value(null);
  final svc = TrialService(FirebaseFirestore.instance, uid);
  svc.ensureStarted(); // fire-and-forget; write-once by rules
  return svc.watch();
});

/// Days remaining in the trial (0 if expired, null if unknown/subscribed).
final trialDaysLeftProvider = Provider<int?>((ref) {
  final started = ref.watch(trialStartProvider).valueOrNull;
  if (started == null) return null;
  final left = kTrialDays - DateTime.now().difference(started).inDays;
  return left < 0 ? 0 : left;
});

/// The user's overall access state, combining subscription + trial.
final accessProvider = Provider<AccessStatus>((ref) {
  // Paywall disabled (beta builds) or demo mode → full access.
  if (!kPaywallEnabled || !firebaseReady) return AccessStatus.trialing;

  final sub = ref.watch(subscriptionProvider).valueOrNull;
  final subscribed =
      sub?.entitlements.active.containsKey(kEntitlementId) ?? false;
  if (subscribed) return AccessStatus.subscribed;

  return ref
      .watch(trialStartProvider)
      .when(
        data: (started) {
          if (started == null) return AccessStatus.loading;
          final daysUsed = DateTime.now().difference(started).inDays;
          return daysUsed < kTrialDays
              ? AccessStatus.trialing
              : AccessStatus.expired;
        },
        loading: () => AccessStatus.loading,
        // Fail open — never lock a legitimate user out on a transient read error.
        error: (_, _) => AccessStatus.trialing,
      );
});

/// True when the app should be read-only (trial expired, not subscribed).
final isReadOnlyProvider = Provider<bool>(
  (ref) => ref.watch(accessProvider) == AccessStatus.expired,
);
