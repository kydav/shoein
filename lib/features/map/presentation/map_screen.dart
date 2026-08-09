import 'dart:typed_data';

import 'package:flutter/material.dart';
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
  List<Client> _located = const [];

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
  }

  Future<void> _addPins() async {
    final pins = _pins;
    final bytes = _pinBytes;
    if (pins == null || bytes == null) return;
    await pins.deleteAll();
    _annToClient.clear();
    for (final c in _located) {
      final annotation = await pins.create(
        PointAnnotationOptions(
          geometry: Point(coordinates: Position(c.lng!, c.lat!)),
          image: bytes,
          iconSize: 0.55,
          iconAnchor: IconAnchor.BOTTOM,
          textField: c.name,
          textOffset: [0, 0.6],
          textSize: 12,
        ),
      );
      _annToClient[annotation.id] = c.id;
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
        padding: const EdgeInsets.only(bottom: 125.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            FloatingActionButton.extended(
              heroTag: 'plan-route',
              onPressed: () => context.push(readOnly ? '/paywall' : '/route'),
              icon: Icon(
                readOnly ? Icons.lock_outline_rounded : Icons.alt_route,
              ),
              label: const Text('Plan route'),
            ),
            const SizedBox(height: 10),
            Material(
              color: context.colors.surface,
              shape: const CircleBorder(),
              elevation: 3,
              child: IconButton(
                icon: const Icon(Icons.layers_outlined, color: kForge),
                tooltip: 'Map style',
                onPressed: _showStyleSheet,
              ),
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
            styleUri: style.styleUri,
            onMapCreated: _onMapCreated,
            onStyleLoadedListener: _onStyleLoaded,
          );
        },
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
