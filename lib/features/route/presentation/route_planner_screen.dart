import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:shoein/core/models/client.dart';
import 'package:shoein/core/providers/data_providers.dart';
import 'package:shoein/core/services/route_optimizer.dart';
import 'package:shoein/core/theme/app_theme.dart';
import 'package:url_launcher/url_launcher.dart';

class RoutePlannerScreen extends ConsumerStatefulWidget {
  const RoutePlannerScreen({super.key});

  @override
  ConsumerState<RoutePlannerScreen> createState() => _RoutePlannerScreenState();
}

class _RoutePlannerScreenState extends ConsumerState<RoutePlannerScreen> {
  final Set<String> _selected = {};
  List<Client>? _route; // null while selecting

  Future<void> _openInMaps() async {
    final route = _route;
    if (route == null || route.isEmpty) return;
    final destination = '${route.last.lat},${route.last.lng}';
    final waypoints = route
        .sublist(0, route.length - 1)
        .map((c) => '${c.lat},${c.lng}')
        .join('|');
    final url =
        'https://www.google.com/maps/dir/?api=1&travelmode=driving'
        '&destination=$destination'
        '${waypoints.isEmpty ? '' : '&waypoints=${Uri.encodeComponent(waypoints)}'}';
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    final located = (ref.watch(clientsProvider).valueOrNull ?? const [])
        .where((c) => c.hasLocation)
        .toList();
    final route = _route;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Plan route'),
        actions: [
          if (route != null)
            TextButton(
              onPressed: () => setState(() => _route = null),
              child: const Text('Edit'),
            ),
        ],
      ),
      body: located.isEmpty
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  'No clients with an address yet.\nAdd addresses to build a route.',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: context.colors.textSecondary,
                  ),
                ),
              ),
            )
          : route == null
          ? _Selector(
              clients: located,
              selected: _selected,
              onToggle: (id, on) => setState(() {
                if (on) {
                  _selected.add(id);
                } else {
                  _selected.remove(id);
                }
              }),
              onOptimize: _selected.length < 2
                  ? null
                  : () {
                      final chosen = located
                          .where((c) => _selected.contains(c.id))
                          .toList();
                      setState(() => _route = optimizeRoute(chosen));
                    },
            )
          : _RouteView(route: route, onOpenInMaps: _openInMaps),
    );
  }
}

class _Selector extends StatefulWidget {
  final List<Client> clients;
  final Set<String> selected;
  final void Function(String id, bool on) onToggle;
  final VoidCallback? onOptimize;
  const _Selector({
    required this.clients,
    required this.selected,
    required this.onToggle,
    required this.onOptimize,
  });

  @override
  State<_Selector> createState() => _SelectorState();
}

class _SelectorState extends State<_Selector> {
  final _search = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final q = _query.trim().toLowerCase();
    final visible = q.isEmpty
        ? widget.clients
        : widget.clients
              .where(
                (c) =>
                    c.name.toLowerCase().contains(q) ||
                    c.address.toLowerCase().contains(q),
              )
              .toList();
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
          child: TextField(
            controller: _search,
            onChanged: (v) => setState(() => _query = v),
            textInputAction: TextInputAction.search,
            decoration: InputDecoration(
              hintText: 'Search clients',
              prefixIcon: const Icon(Icons.search),
              isDense: true,
              suffixIcon: _query.isEmpty
                  ? null
                  : IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        _search.clear();
                        setState(() => _query = '');
                      },
                    ),
            ),
          ),
        ),
        Expanded(
          child: visible.isEmpty
              ? Center(
                  child: Text(
                    'No clients match "$_query".',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: context.colors.textSecondary,
                    ),
                  ),
                )
              : ListView(
                  children: [
                    for (final c in visible)
                      CheckboxListTile(
                        value: widget.selected.contains(c.id),
                        onChanged: (v) =>
                            setState(() => widget.onToggle(c.id, v ?? false)),
                        title: Text(c.name),
                        subtitle: c.address.isEmpty ? null : Text(c.address),
                      ),
                  ],
                ),
        ),
        SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
            child: FilledButton.icon(
              onPressed: widget.onOptimize,
              icon: const Icon(Icons.alt_route),
              label: Text(
                widget.selected.length < 2
                    ? 'Select 2+ clients'
                    : 'Optimize route (${widget.selected.length})',
              ),
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(50),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _RouteView extends StatelessWidget {
  final List<Client> route;
  final VoidCallback onOpenInMaps;
  const _RouteView({required this.route, required this.onOpenInMaps});

  @override
  Widget build(BuildContext context) {
    final miles = routeLengthKm(route) * 0.621371;
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
          child: Row(
            children: [
              Text(
                '${route.length} stops',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const Spacer(),
              Text(
                '≈ ${miles.toStringAsFixed(1)} mi',
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(color: kForge),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            children: [
              for (var i = 0; i < route.length; i++)
                ListTile(
                  leading: CircleAvatar(
                    radius: 15,
                    backgroundColor: kForge,
                    child: Text(
                      '${i + 1}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  title: Text(route[i].name),
                  subtitle: route[i].address.isEmpty
                      ? null
                      : Text(route[i].address),
                ),
            ],
          ),
        ),
        SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
            child: FilledButton.icon(
              onPressed: onOpenInMaps,
              icon: const Icon(Icons.navigation_outlined),
              label: const Text('Open in Google Maps'),
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(50),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
