import 'package:flutter_map/flutter_map.dart';
import 'package:shoein/core/providers/settings_providers.dart';
import 'package:url_launcher/url_launcher.dart';

/// Map tiles come from **Geoapify** — its free plan permits commercial use
/// (within the free daily quota) and serves ready-to-use raster tiles, with
/// attribution (rendered by [appMapAttribution]).
///
/// The key is injected at build time:
///   flutter run --dart-define-from-file=.env      (local, see .env.example)
///   CI passes it from the GEOAPIFY_API_KEY repo secret.
/// Get a free key at https://myprojects.geoapify.com/ .
const _geoapifyApiKey = String.fromEnvironment('GEOAPIFY_API_KEY');

/// Whether a production tile provider (Geoapify) is configured.
bool get mapTilesConfigured => _geoapifyApiKey.isNotEmpty;

/// Shared tile layer for every map, using the user's selected [MapStyle].
TileLayer appTileLayer(MapStyle style) {
  if (mapTilesConfigured) {
    return TileLayer(
      urlTemplate:
          'https://maps.geoapify.com/v1/tile/${style.slug}/{z}/{x}/{y}.png?apiKey=$_geoapifyApiKey',
      userAgentPackageName: 'app.auaha.shoein',
      maxNativeZoom: 20,
    );
  }
  // Dev fallback when no key is set — public OSM tiles (prints a usage-policy
  // warning; not permitted for production).
  return TileLayer(
    urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
    userAgentPackageName: 'app.auaha.shoein',
  );
}

/// Shared attribution overlay, required by the tile providers.
RichAttributionWidget appMapAttribution() {
  return RichAttributionWidget(
    alignment: AttributionAlignment.bottomLeft,
    showFlutterMapAttribution: false,
    attributions: [
      TextSourceAttribution(
        'OpenStreetMap contributors',
        onTap: () => _open('https://www.openstreetmap.org/copyright'),
      ),
      if (mapTilesConfigured) ...[
        TextSourceAttribution(
          'Geoapify',
          onTap: () => _open('https://www.geoapify.com/'),
        ),
        TextSourceAttribution(
          'OpenMapTiles',
          onTap: () => _open('https://openmaptiles.org/'),
        ),
      ],
    ],
  );
}

void _open(String url) {
  launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
}
