import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

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

// ─── Invoicing: business name + one payment link, persisted ───────────────────
class _StringPref extends FamilyNotifier<String, String> {
  @override
  String build(String key) =>
      ref.read(sharedPreferencesProvider).getString(key) ?? '';

  Future<void> set(String value) async {
    state = value;
    await ref.read(sharedPreferencesProvider).setString(arg, value.trim());
  }
}

final _stringPrefProvider =
    NotifierProvider.family<_StringPref, String, String>(_StringPref.new);

/// Business name shown on invoices.
final businessNameProvider = _stringPrefProvider('business_name');

/// The single Venmo/Stripe/PayPal payment link put on every invoice.
final paymentLinkProvider = _stringPrefProvider('payment_link');
