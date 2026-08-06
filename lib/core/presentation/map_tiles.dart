import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:vector_map_tiles/vector_map_tiles.dart';

/// Map tiles come from **OpenFreeMap** — a free, keyless, commercial-use-OK
/// OpenStreetMap vector tile host (funded by donations). No API key or `.env`
/// value is needed. Attribution is required and rendered by [appMapAttribution].
///
/// These are *vector* tiles, rendered on-device by `vector_map_tiles`, so maps
/// stay crisp at every zoom. Available styles: liberty | bright | positron |
/// dark | fiord.
const _openFreeMapStyleUrl = 'https://tiles.openfreemap.org/styles/liberty';

/// Loads and parses the vector style once, cached for the app's lifetime so
/// every map screen shares it (the network fetch happens a single time).
final mapStyleProvider = FutureProvider<Style>((ref) async {
  ref.keepAlive();
  return StyleReader(uri: _openFreeMapStyleUrl).read();
});

/// Builds the shared vector tile layer from a loaded [Style]. Add it to a
/// `FlutterMap`'s children once [mapStyleProvider] has resolved.
VectorTileLayer appVectorTileLayer(Style style) => VectorTileLayer(
  theme: style.theme,
  tileProviders: style.providers,
  tileOffset: TileOffset.DEFAULT,
);

/// Shared attribution overlay, required by OpenStreetMap + OpenFreeMap.
RichAttributionWidget appMapAttribution() {
  return RichAttributionWidget(
    alignment: AttributionAlignment.bottomLeft,
    showFlutterMapAttribution: false,
    attributions: [
      TextSourceAttribution(
        'OpenStreetMap contributors',
        onTap: () => _open('https://www.openstreetmap.org/copyright'),
      ),
      TextSourceAttribution(
        'OpenFreeMap',
        onTap: () => _open('https://openfreemap.org/'),
      ),
    ],
  );
}

void _open(String url) {
  launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
}
