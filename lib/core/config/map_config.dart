/// Mapbox public access token. This is a *public* token (safe to ship in the
/// app binary); usage is billed to the Mapbox account. Override at build time
/// with --dart-define=MAPBOX_ACCESS_TOKEN=... if you want a Shoein'-specific one.
///
/// Note: building the app also requires Mapbox's **secret downloads token**
/// (`MAPBOX_DOWNLOADS_TOKEN`, scope `downloads:read`) configured in your global
/// ~/.gradle/gradle.properties (Android) and ~/.netrc (iOS) — same setup Prior
/// already uses. In CI it's provided as a secret.
const kMapboxAccessToken = String.fromEnvironment(
  'MAPBOX_ACCESS_TOKEN',
  defaultValue:
      'pk.eyJ1Ijoia3lkYXYiLCJhIjoiY21xcjNid29sMGtwMzJxcHd2czd6NmQ5aSJ9.NnCfgYoj6EK8Wg9E_dJXGg',
);

/// Asset used as the client marker on the map.
const kMapPinAsset = 'assets/map/pin.png';
