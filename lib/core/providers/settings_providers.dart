import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shoein/core/providers/auth_provider.dart';
import 'package:shoein/core/services/firebase_bootstrap.dart';

/// Overridden in `main` with the loaded instance.
final sharedPreferencesProvider = Provider<SharedPreferences>(
  (ref) => throw UnimplementedError('sharedPreferencesProvider not overridden'),
);

// ─── Theme mode (System / Light / Dark), persisted ──────────────────────────
class ThemeModeNotifier extends Notifier<ThemeMode> {
  static const _key = 'theme_mode';

  @override
  ThemeMode build() {
    final saved = ref.read(sharedPreferencesProvider).getString(_key);
    return switch (saved) {
      'light' => ThemeMode.light,
      'dark' => ThemeMode.dark,
      _ => ThemeMode.system,
    };
  }

  Future<void> set(ThemeMode mode) async {
    state = mode;
    await ref.read(sharedPreferencesProvider).setString(_key, mode.name);
  }
}

final themeModeProvider = NotifierProvider<ThemeModeNotifier, ThemeMode>(
  ThemeModeNotifier.new,
);

// ─── Map style, persisted ────────────────────────────────────────────────────
/// Mapbox styles offered in the on-map style switcher. [styleUri] is the
/// Mapbox style URL passed to the map.
enum MapStyle {
  standard('Standard', Icons.map_outlined, 'mapbox://styles/mapbox/standard'),
  satellite(
    'Satellite',
    Icons.satellite_alt_outlined,
    'mapbox://styles/mapbox/standard-satellite',
  ),
  outdoors(
    'Outdoors',
    Icons.terrain_outlined,
    'mapbox://styles/mapbox/outdoors-v12',
  ),
  dark('Dark', Icons.dark_mode_outlined, 'mapbox://styles/mapbox/dark-v11');

  const MapStyle(this.label, this.icon, this.styleUri);
  final String label;
  final IconData icon;
  final String styleUri;
}

class MapStyleNotifier extends Notifier<MapStyle> {
  static const _key = 'map_style';

  @override
  MapStyle build() {
    final saved = ref.read(sharedPreferencesProvider).getString(_key);
    return MapStyle.values.firstWhere(
      (s) => s.name == saved,
      orElse: () => MapStyle.standard,
    );
  }

  Future<void> set(MapStyle style) async {
    state = style;
    await ref.read(sharedPreferencesProvider).setString(_key, style.name);
  }
}

final mapStyleNameProvider = NotifierProvider<MapStyleNotifier, MapStyle>(
  MapStyleNotifier.new,
);

// ─── Trim reminders on/off, persisted ────────────────────────────────────────
class RemindersEnabledNotifier extends Notifier<bool> {
  static const _key = 'reminders_enabled';

  @override
  bool build() => ref.read(sharedPreferencesProvider).getBool(_key) ?? true;

  Future<void> set(bool value) async {
    state = value;
    await ref.read(sharedPreferencesProvider).setBool(_key, value);
  }
}

final remindersEnabledProvider =
    NotifierProvider<RemindersEnabledNotifier, bool>(
      RemindersEnabledNotifier.new,
    );

// ─── First-run onboarding seen, persisted ────────────────────────────────────
class OnboardingSeenNotifier extends Notifier<bool> {
  static const _key = 'onboarding_seen';

  @override
  bool build() => ref.read(sharedPreferencesProvider).getBool(_key) ?? false;

  Future<void> markSeen() async {
    state = true;
    await ref.read(sharedPreferencesProvider).setBool(_key, true);
  }
}

final onboardingSeenProvider = NotifierProvider<OnboardingSeenNotifier, bool>(
  OnboardingSeenNotifier.new,
);

// ─── Invoicing: business name + one payment link ─────────────────────────────
// Stored on the user's Firestore doc (`users/{uid}`) so they follow the account
// across devices. A local copy is kept in SharedPreferences as an offline cache
// (and the demo-mode / signed-out fallback).

const _kBusinessNameKey = 'business_name';
const _kPaymentLinkKey = 'payment_link';

class BusinessSettings {
  final String businessName;
  final String paymentLink;
  const BusinessSettings({this.businessName = '', this.paymentLink = ''});
}

/// Live business/payment settings, synced from the user's Firestore doc.
/// Falls back to on-device prefs in demo mode or before sign-in.
final businessSettingsProvider = StreamProvider<BusinessSettings>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  BusinessSettings fromPrefs() => BusinessSettings(
    businessName: prefs.getString(_kBusinessNameKey) ?? '',
    paymentLink: prefs.getString(_kPaymentLinkKey) ?? '',
  );

  if (!firebaseReady) return Stream.value(fromPrefs());
  final uid = ref.watch(authNotifierProvider).uid;
  if (uid.isEmpty) return Stream.value(fromPrefs());

  final doc = FirebaseFirestore.instance.collection('users').doc(uid);
  return doc.snapshots().map((snap) {
    final d = snap.data();
    return BusinessSettings(
      businessName: (d?['businessName'] as String?) ?? '',
      paymentLink: (d?['paymentLink'] as String?) ?? '',
    );
  });
});

/// Business name shown on invoices (empty until the profile loads).
final businessNameProvider = Provider<String>(
  (ref) => ref.watch(businessSettingsProvider).valueOrNull?.businessName ?? '',
);

/// The single Venmo/Stripe/PayPal payment link put on every invoice.
final paymentLinkProvider = Provider<String>(
  (ref) => ref.watch(businessSettingsProvider).valueOrNull?.paymentLink ?? '',
);

/// Persist business/payment settings — to the user's Firestore doc when signed
/// in, and always to the local prefs cache (offline + demo fallback).
Future<void> saveBusinessSettings(
  WidgetRef ref, {
  required String businessName,
  required String paymentLink,
}) async {
  final name = businessName.trim();
  final link = paymentLink.trim();
  final prefs = ref.read(sharedPreferencesProvider);
  await prefs.setString(_kBusinessNameKey, name);
  await prefs.setString(_kPaymentLinkKey, link);

  if (!firebaseReady) return;
  final uid = ref.read(authNotifierProvider).uid;
  if (uid.isEmpty) return;
  await FirebaseFirestore.instance.collection('users').doc(uid).set({
    'businessName': name,
    'paymentLink': link,
  }, SetOptions(merge: true));
}
