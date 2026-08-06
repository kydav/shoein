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
/// Geoapify raster map styles offered in the picker. [slug] is the Geoapify
/// style id used in the tile URL.
enum MapStyle {
  osmBright('OSM Bright', 'osm-bright'),
  positron('Positron', 'positron'),
  darkMatter('Dark', 'dark-matter'),
  toner('Toner', 'toner'),
  osmCarto('Classic', 'osm-carto');

  const MapStyle(this.label, this.slug);
  final String label;
  final String slug;
}

class MapStyleNotifier extends Notifier<MapStyle> {
  static const _key = 'map_style';

  @override
  MapStyle build() {
    final saved = ref.read(sharedPreferencesProvider).getString(_key);
    return MapStyle.values.firstWhere(
      (s) => s.name == saved,
      orElse: () => MapStyle.osmBright,
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
