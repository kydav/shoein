import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart' as geo;
import 'package:flutter/services.dart' show rootBundle;
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';
import 'package:shoein/core/config/map_config.dart';
import 'package:shoein/core/models/client.dart';
import 'package:shoein/core/presentation/widgets.dart';
import 'package:shoein/core/providers/access_providers.dart';
import 'package:shoein/core/providers/data_providers.dart';
import 'package:shoein/core/providers/settings_providers.dart';
import 'package:shoein/core/theme/app_theme.dart';

class MapScreen extends ConsumerStatefulWidget {
  const MapScreen({super.key});

  @override
  ConsumerState<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends ConsumerState<MapScreen> {
  MapboxMap? _map;
  PointAnnotationManager? _pins;
  Uint8List? _pinBytes;
  final Map<String, String> _annToClient = {};
  final Map<String, Uint8List> _chipCache = {};
  List<Client> _located = const [];
  bool _locating = false;

  // Chip scale factor — render at 3× and shrink with iconSize for a crisp label.
  static const double _chipScale = 3.0;

  /// A rounded "chip" label (client name) baked into a PNG so it's legible over
  /// any map style. Cached per name.
  Future<Uint8List> _chipBytes(String name) async {
    final cached = _chipCache[name];
    if (cached != null) return cached;
    final tp = TextPainter(
      text: TextSpan(
        text: name,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 12 * _chipScale,
          fontWeight: FontWeight.w600,
        ),
      ),
      textDirection: TextDirection.ltr,
      maxLines: 1,
      ellipsis: '…',
    )..layout(maxWidth: 150 * _chipScale);
    const padH = 11 * _chipScale;
    const padV = 6 * _chipScale;
    final w = tp.width + padH * 2;
    final h = tp.height + padV * 2;
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    final rect = Rect.fromLTWH(0, 0, w, h);
    canvas.drawRRect(
      RRect.fromRectAndRadius(rect, Radius.circular(h / 2)),
      Paint()..color = kAnvil.withValues(alpha: 0.92),
    );
    tp.paint(canvas, const Offset(padH, padV));
    final img = await recorder.endRecording().toImage(w.ceil(), h.ceil());
    final data = await img.toByteData(format: ui.ImageByteFormat.png);
    final bytes = data!.buffer.asUint8List();
    _chipCache[name] = bytes;
    return bytes;
  }

  /// Initial viewport so the map opens already framed on the clients instead of
  /// flashing the whole world before the style loads.
  ViewportState? _initialViewport() {
    if (_located.isEmpty) return null;
    final lat =
        _located.map((c) => c.lat!).reduce((a, b) => a + b) / _located.length;
    final lng =
        _located.map((c) => c.lng!).reduce((a, b) => a + b) / _located.length;
    return CameraViewportState(
      center: Point(coordinates: Position(lng, lat)),
      zoom: _located.length == 1 ? 13 : 8.5,
    );
  }

  @override
  void initState() {
    super.initState();
    rootBundle.load(kMapPinAsset).then((d) {
      _pinBytes = d.buffer.asUint8List();
    });
  }

  void _onMapCreated(MapboxMap map) => _map = map;

  // Runs on the first style load and again after each style switch — the
  // annotation manager lives on the style, so pins are (re)added here.
  Future<void> _onStyleLoaded(StyleLoadedEventData _) async {
    final map = _map;
    if (map == null || !mounted) return;
    _pins = await map.annotations.createPointAnnotationManager();
    _pins!.tapEvents(
      onTap: (annotation) {
        final id = _annToClient[annotation.id];
        if (id != null && mounted) context.push('/clients/$id');
      },
    );
    await _addPins();
    await _fitCamera();
    // Restore the location puck across style switches if we already have
    // permission — without prompting on a fresh map open.
    final perm = await geo.Geolocator.checkPermission();
    if (perm == geo.LocationPermission.whileInUse ||
        perm == geo.LocationPermission.always) {
      await _enableLocationPuck();
    }
  }

  /// Turns on Mapbox's built-in location puck (the live blue dot).
  Future<void> _enableLocationPuck() async {
    try {
      await _map?.location.updateSettings(
        LocationComponentSettings(enabled: true, pulsingEnabled: true),
      );
    } catch (_) {}
  }

  Future<void> _addPins() async {
    final pins = _pins;
    final bytes = _pinBytes;
    if (pins == null || bytes == null) return;
    await pins.deleteAll();
    _annToClient.clear();
    for (final c in _located) {
      final point = Point(coordinates: Position(c.lng!, c.lat!));
      final pin = await pins.create(
        PointAnnotationOptions(
          geometry: point,
          image: bytes,
          iconSize: 0.55,
          iconAnchor: IconAnchor.BOTTOM,
        ),
      );
      _annToClient[pin.id] = c.id;
      // A readable name chip sitting just under the pin's tip.
      final chip = await pins.create(
        PointAnnotationOptions(
          geometry: point,
          image: await _chipBytes(c.name),
          iconSize: 1 / _chipScale,
          iconAnchor: IconAnchor.TOP,
          iconOffset: [0, 10],
        ),
      );
      _annToClient[chip.id] = c.id;
    }
  }

  Future<void> _fitCamera() async {
    final map = _map;
    if (map == null || _located.isEmpty) return;
    final lat =
        _located.map((c) => c.lat!).reduce((a, b) => a + b) / _located.length;
    final lng =
        _located.map((c) => c.lng!).reduce((a, b) => a + b) / _located.length;
    await map.setCamera(
      CameraOptions(
        center: Point(coordinates: Position(lng, lat)),
        zoom: _located.length == 1 ? 13 : 8.5,
      ),
    );
  }

  void _showStyleSheet() {
    showModalBottomSheet<void>(
      context: context,
      useRootNavigator: true,
      backgroundColor: context.colors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _MapStyleSheet(
        current: ref.read(mapStyleNameProvider),
        onSelected: (style) {
          Navigator.of(context, rootNavigator: true).pop();
          ref.read(mapStyleNameProvider.notifier).set(style);
        },
      ),
    );
  }

  Future<void> _goToCurrentLocation() async {
    setState(() => _locating = true);
    try {
      var permission = await geo.Geolocator.checkPermission();
      if (permission == geo.LocationPermission.denied) {
        permission = await geo.Geolocator.requestPermission();
      }
      if (permission == geo.LocationPermission.deniedForever ||
          permission == geo.LocationPermission.denied) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Location permission is required')),
          );
        }
        return;
      }
      // Show the live location puck now that permission is granted.
      await _enableLocationPuck();
      final pos = await geo.Geolocator.getCurrentPosition(
        locationSettings: const geo.LocationSettings(
          accuracy: geo.LocationAccuracy.high,
          timeLimit: Duration(seconds: 10),
        ),
      );
      final map = _map;
      if (map != null && mounted) {
        await map.flyTo(
          CameraOptions(
            center: Point(coordinates: Position(pos.longitude, pos.latitude)),
            zoom: 15,
          ),
          MapAnimationOptions(duration: 1000),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not get current location')),
        );
      }
    } finally {
      if (mounted) setState(() => _locating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final clientsAsync = ref.watch(clientsProvider);
    final style = ref.watch(mapStyleNameProvider);
    final readOnly = ref.watch(isReadOnlyProvider);

    // Re-add pins when the client set changes.
    ref.listen(clientsProvider, (_, next) {
      _located = (next.valueOrNull ?? const [])
          .where((c) => c.hasLocation)
          .toList();
      _addPins();
      _fitCamera();
    });
    // Reload the Mapbox style when the user picks a new one.
    ref.listen(mapStyleNameProvider, (_, s) => _map?.loadStyleURI(s.styleUri));

    return Scaffold(
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(right: 4, bottom: 125.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            _MapIconButton(
              icon: readOnly ? Icons.lock_outline_rounded : Icons.alt_route,
              tooltip: 'Plan route',
              onPressed: () => context.push(readOnly ? '/paywall' : '/route'),
            ),
            const SizedBox(height: 10),
            _MapIconButton(
              icon: Icons.layers_outlined,
              tooltip: 'Map style',
              onPressed: _showStyleSheet,
            ),
            const SizedBox(height: 10),
            _MapIconButton(
              icon: Icons.my_location,
              tooltip: 'Center map',
              onPressed: _locating ? null : _goToCurrentLocation,
            ),
          ],
        ),
      ),
      body: clientsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (all) {
          _located = all.where((c) => c.hasLocation).toList();
          if (_located.isEmpty) {
            return const EmptyState(
              icon: Icons.map_outlined,
              title: 'No mapped clients',
              message:
                  'Add an address to a client and they\'ll show up here as a pin.',
            );
          }
          return MapWidget(
            key: const ValueKey('clients-map'),
            viewport: _initialViewport(),
            styleUri: style.styleUri,
            onMapCreated: _onMapCreated,
            onStyleLoadedListener: _onStyleLoaded,
          );
        },
      ),
    );
  }
}

/// A circular map control button — the on-map style for both the route and
/// map-style actions.
class _MapIconButton extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback? onPressed;
  const _MapIconButton({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: context.colors.surface,
      shape: const CircleBorder(),
      elevation: 3,
      child: IconButton(
        icon: Icon(icon, color: kForge),
        tooltip: tooltip,
        onPressed: onPressed,
      ),
    );
  }
}

/// Bottom sheet for choosing the Mapbox style.
class _MapStyleSheet extends StatelessWidget {
  final MapStyle current;
  final void Function(MapStyle) onSelected;
  const _MapStyleSheet({required this.current, required this.onSelected});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 14, 24, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: context.colors.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 18),
          Text('Map style', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: MapStyle.values.map((s) {
              final selected = current == s;
              return GestureDetector(
                onTap: () => onSelected(s),
                child: Column(
                  children: [
                    Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        color: selected
                            ? kForge.withValues(alpha: 0.14)
                            : context.colors.surfaceAlt,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: selected ? kForge : context.colors.border,
                          width: selected ? 2 : 1,
                        ),
                      ),
                      child: Icon(
                        s.icon,
                        color: selected ? kForge : context.colors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      s.label,
                      style: TextStyle(
                        fontSize: 11,
                        color: selected ? kForge : context.colors.textSecondary,
                        fontWeight: selected
                            ? FontWeight.w600
                            : FontWeight.normal,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}
