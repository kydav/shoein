import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart' hide Size;
import 'package:shoein/core/config/map_config.dart';
import 'package:shoein/core/models/client.dart';
import 'package:shoein/core/models/horse.dart';
import 'package:shoein/core/presentation/widgets.dart';
import 'package:shoein/core/providers/access_providers.dart';
import 'package:shoein/core/providers/data_providers.dart';
import 'package:shoein/core/providers/settings_providers.dart';
import 'package:shoein/core/theme/app_theme.dart';
import 'package:url_launcher/url_launcher.dart';

class ClientDetailScreen extends ConsumerWidget {
  final String clientId;
  const ClientDetailScreen({required this.clientId, super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final clientAsync = ref.watch(clientProvider(clientId));
    final horsesAsync = ref.watch(horsesProvider(clientId));
    final readOnly = ref.watch(isReadOnlyProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Client'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            onPressed: () =>
                context.push(readOnly ? '/paywall' : '/clients/$clientId/edit'),
            tooltip: 'Edit client',
          ),
          if (!readOnly)
            IconButton(
              icon: const Icon(Icons.delete_outline_rounded),
              onPressed: () => _confirmDelete(context, ref),
              tooltip: 'Delete client',
            ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push(
          readOnly ? '/paywall' : '/clients/$clientId/horse/new',
        ),
        icon: Icon(readOnly ? Icons.lock_outline_rounded : Icons.add),
        label: const Text('Horse'),
      ),
      body: clientAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (client) {
          if (client == null) {
            return const Center(child: Text('Client not found.'));
          }
          final horses = horsesAsync.value ?? const [];
          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
            children: [
              Text(
                client.name,
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: 12),
              if (client.hasLocation) _MiniMap(client: client),
              _ContactActions(client: client),
              if (client.notes.isNotEmpty) ...[
                const SizedBox(height: 12),
                SoftCard(
                  color: kForge.withValues(alpha: 0.06),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(
                        Icons.sticky_note_2_outlined,
                        size: 18,
                        color: kForge,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          client.notes,
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 24),
              Row(
                children: [
                  Text(
                    'Horses',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '(${horses.length})',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: context.colors.textSecondary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              if (horses.isEmpty)
                SoftCard(
                  child: Row(
                    children: [
                      Icon(
                        Icons.add_circle_outline,
                        color: context.colors.textSecondary,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'No horses yet. Add this client\'s horses to track service dates.',
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(color: context.colors.textSecondary),
                        ),
                      ),
                    ],
                  ),
                )
              else
                for (final h in horses) ...[
                  _HorseTile(clientId: clientId, horse: h),
                  const SizedBox(height: 10),
                ],
            ],
          );
        },
      ),
    );
  }

  Future<void> _confirmDelete(BuildContext context, WidgetRef ref) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete client?'),
        content: const Text('This removes the client and all of their horses.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: kOverdueRed),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (ok == true && context.mounted) {
      await ref.read(repositoryProvider).deleteClient(clientId);
      if (context.mounted) context.pop();
    }
  }
}

class _MiniMap extends ConsumerStatefulWidget {
  final Client client;
  const _MiniMap({required this.client});

  @override
  ConsumerState<_MiniMap> createState() => _MiniMapState();
}

class _MiniMapState extends ConsumerState<_MiniMap> {
  MapboxMap? _map;
  Uint8List? _pinBytes;

  @override
  void initState() {
    super.initState();
    rootBundle.load(kMapPinAsset).then((d) {
      _pinBytes = d.buffer.asUint8List();
    });
  }

  Future<void> _onStyleLoaded(StyleLoadedEventData _) async {
    final map = _map;
    if (map == null || !mounted) return;
    // Static preview — no interaction.
    await map.gestures.updateSettings(
      GesturesSettings(
        rotateEnabled: false,
        scrollEnabled: false,
        pinchToZoomEnabled: false,
        pitchEnabled: false,
        doubleTapToZoomInEnabled: false,
        doubleTouchToZoomOutEnabled: false,
        quickZoomEnabled: false,
      ),
    );
    final c = widget.client;
    final bytes = _pinBytes;
    if (bytes != null) {
      final pins = await map.annotations.createPointAnnotationManager();
      await pins.create(
        PointAnnotationOptions(
          geometry: Point(coordinates: Position(c.lng!, c.lat!)),
          image: bytes,
          iconSize: 0.5,
          iconAnchor: IconAnchor.BOTTOM,
        ),
      );
    }
    await map.setCamera(
      CameraOptions(
        center: Point(coordinates: Position(c.lng!, c.lat!)),
        zoom: 13,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final style = ref.watch(mapStyleNameProvider);
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: SizedBox(
          height: 170,
          child: Stack(
            children: [
              MapWidget(
                key: ValueKey('mini-${widget.client.id}'),
                styleUri: style.styleUri,
                onMapCreated: (m) => _map = m,
                onStyleLoadedListener: _onStyleLoaded,
              ),
              Positioned(
                right: 10,
                bottom: 10,
                child: FilledButton.icon(
                  style: FilledButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: kAnvil,
                    minimumSize: const Size(0, 38),
                  ),
                  onPressed: () => _directions(widget.client),
                  icon: const Icon(Icons.directions, size: 18),
                  label: const Text('Directions'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ContactActions extends StatelessWidget {
  final Client client;
  const _ContactActions({required this.client});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: [
        if (client.phone.isNotEmpty)
          _ActionChip(
            icon: Icons.call,
            label: 'Call',
            onTap: () => _launch('tel:${client.phone}'),
          ),
        if (client.phone.isNotEmpty)
          _ActionChip(
            icon: Icons.sms_outlined,
            label: 'Text',
            onTap: () => _launch('sms:${client.phone}'),
          ),
        if (client.address.isNotEmpty)
          _ActionChip(
            icon: Icons.directions,
            label: 'Directions',
            onTap: () => _directions(client),
          ),
      ],
    );
  }
}

class _ActionChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _ActionChip({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: onTap,
      icon: Icon(icon, size: 18),
      label: Text(label),
    );
  }
}

class _HorseTile extends StatelessWidget {
  final String clientId;
  final Horse horse;
  const _HorseTile({required this.clientId, required this.horse});

  @override
  Widget build(BuildContext context) {
    return SoftCard(
      onTap: () => context.push('/clients/$clientId/horse/${horse.id}/edit'),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: kForge.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.pets, color: kForge),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        horse.name,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ),
                    ServiceBadge(daysSince: horse.daysSinceService),
                  ],
                ),
                if (horse.breed.isNotEmpty || horse.notes.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    [
                      if (horse.breed.isNotEmpty) horse.breed,
                      if (horse.notes.isNotEmpty) horse.notes,
                    ].join(' · '),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

Future<void> _launch(String uri) async {
  final u = Uri.parse(uri);
  if (await canLaunchUrl(u)) await launchUrl(u);
}

Future<void> _directions(Client client) async {
  try {
    final url = Platform.isIOS
        ? Uri.parse(
            'maps:${client.lat},${client.lng}?q=${client.lat},${client.lng}',
          )
        : Uri.parse(
            'geo:${client.lat},${client.lng}?q=${client.lat},${client.lng}',
          );
    if (await canLaunchUrl(url)) {
      await launchUrl(url);
    } else {
      throw 'Could not launch $url';
    }
  } catch (error) {
    debugPrint('Error launching directions: $error');
  }
}
