import 'package:flutter_map/flutter_map.dart';
import 'package:url_launcher/url_launcher.dart';

/// Stadia Maps API key, injected at build time:
///
///   flutter run --dart-define=STADIA_API_KEY=YOUR_KEY
///
/// Get a free key (no credit card) at https://client.stadiamaps.com/ and add
/// this app's bundle id (`app.auaha.shoein`) as an allowed property so the key
/// can't be reused elsewhere.
///
/// When the key is empty (e.g. local dev without one) the app falls back to
/// OpenStreetMap's public tiles. That's fine for development, but those tiles
/// must NOT ship to production — OSM's tile usage policy forbids it, which is
/// what the console warning is about. Provide a Stadia key for release builds.
const _stadiaApiKey = String.fromEnvironment('STADIA_API_KEY');

/// Whether a production tile provider (Stadia) is configured.
bool get mapTilesConfigured => _stadiaApiKey.isNotEmpty;

/// Shared tile layer used by every map in the app.
TileLayer appTileLayer() {
  if (mapTilesConfigured) {
    return TileLayer(
      urlTemplate:
          'https://tiles.stadiamaps.com/tiles/alidade_smooth/{z}/{x}/{y}.png?api_key=$_stadiaApiKey',
      userAgentPackageName: 'app.auaha.shoein',
    );
  }
  // Dev fallback — public OSM tiles (prints the usage-policy warning).
  return TileLayer(
    urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
    userAgentPackageName: 'app.auaha.shoein',
  );
}

/// Shared attribution overlay, required by both Stadia and OpenStreetMap.
RichAttributionWidget appMapAttribution() {
  return RichAttributionWidget(
    alignment: AttributionAlignment.bottomLeft,
    showFlutterMapAttribution: false,
    attributions: [
      if (mapTilesConfigured)
        TextSourceAttribution(
          'Stadia Maps',
          onTap: () => _open('https://stadiamaps.com/'),
        ),
      TextSourceAttribution(
        'OpenStreetMap contributors',
        onTap: () => _open('https://www.openstreetmap.org/copyright'),
      ),
    ],
  );
}

void _open(String url) {
  launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
}
