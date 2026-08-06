import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:latlong2/latlong.dart';
import 'package:shoein/core/models/client.dart';
import 'package:shoein/core/presentation/map_tiles.dart';
import 'package:shoein/core/presentation/widgets.dart';
import 'package:shoein/core/providers/settings_providers.dart';
import 'package:shoein/core/providers/data_providers.dart';
import 'package:shoein/core/theme/app_theme.dart';

class MapScreen extends ConsumerWidget {
  const MapScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final clientsAsync = ref.watch(clientsProvider);
    final mapStyle = ref.watch(mapStyleNameProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Map')),
      body: clientsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (clients) {
          final located = clients.where((c) => c.hasLocation).toList();
          if (located.isEmpty) {
            return const EmptyState(
              icon: Icons.map_outlined,
              title: 'No mapped clients',
              message:
                  'Add an address to a client and they\'ll show up here as a pin.',
            );
          }
          return FlutterMap(
            options: MapOptions(
              initialCenter: _center(located),
              initialZoom: located.length == 1 ? 13 : 9,
            ),
            children: [
              appTileLayer(mapStyle),
              MarkerLayer(
                markers: [
                  for (final c in located)
                    Marker(
                      point: LatLng(c.lat!, c.lng!),
                      width: 140,
                      height: 58,
                      alignment: Alignment.topCenter,
                      child: _Pin(client: c),
                    ),
                ],
              ),
              appMapAttribution(),
            ],
          );
        },
      ),
    );
  }

  LatLng _center(List<Client> clients) {
    final lat =
        clients.map((c) => c.lat!).reduce((a, b) => a + b) / clients.length;
    final lng =
        clients.map((c) => c.lng!).reduce((a, b) => a + b) / clients.length;
    return LatLng(lat, lng);
  }
}

class _Pin extends StatelessWidget {
  final Client client;
  const _Pin({required this.client});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.push('/clients/${client.id}'),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.location_on, color: kForge, size: 38),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: kBorderColor),
            ),
            child: Text(
              client.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}
