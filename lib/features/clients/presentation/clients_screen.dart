import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:shoein/core/models/client.dart';
import 'package:shoein/core/presentation/widgets.dart';
import 'package:shoein/core/providers/access_providers.dart';
import 'package:shoein/core/providers/data_providers.dart';
import 'package:shoein/core/theme/app_theme.dart';
import 'package:shoein/features/subscription/presentation/access_banner.dart';

class ClientsScreen extends HookConsumerWidget {
  const ClientsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final clientsAsync = ref.watch(clientsProvider);
    final readOnly = ref.watch(isReadOnlyProvider);
    final query = useState('');

    void addClient() => context.push(readOnly ? '/paywall' : '/clients/new');
    return Scaffold(
      appBar: AppBar(title: const Text('Clients')),
      resizeToAvoidBottomInset: false,
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 125.0),
        child: FloatingActionButton.extended(
          onPressed: addClient,
          icon: Icon(readOnly ? Icons.lock_outline_rounded : Icons.add),
          label: const Text('Client'),
        ),
      ),
      body: Column(
        children: [
          const AccessBanner(),
          Expanded(
            child: clientsAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('Error: $e')),
              data: (all) {
                final clients = query.value.isEmpty
                    ? all
                    : all
                          .where(
                            (c) => c.name.toLowerCase().contains(
                              query.value.toLowerCase(),
                            ),
                          )
                          .toList();
                if (all.isEmpty) {
                  return EmptyState(
                    icon: Icons.people_alt_outlined,
                    title: 'No clients yet',
                    message:
                        'Add your first client to start tracking their horses and service schedule.',
                    action: FilledButton.icon(
                      onPressed: addClient,
                      icon: const Icon(Icons.add),
                      label: const Text('Add client'),
                    ),
                  );
                }
                return ListView(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
                  children: [
                    TextField(
                      onChanged: (v) => query.value = v,
                      decoration: const InputDecoration(
                        hintText: 'Search clients',
                        prefixIcon: Icon(Icons.search),
                      ),
                    ),
                    const SizedBox(height: 12),
                    for (final c in clients) ...[
                      _ClientTile(client: c),
                      const SizedBox(height: 10),
                    ],
                    if (clients.isEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 40),
                        child: Text(
                          'No clients match "${query.value}".',
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(color: context.colors.textSecondary),
                        ),
                      ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _ClientTile extends ConsumerWidget {
  final Client client;
  const _ClientTile({required this.client});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final horsesAsync = ref.watch(horsesProvider(client.id));
    final count = horsesAsync.value?.length;
    return SoftCard(
      onTap: () => context.push('/clients/${client.id}'),
      child: Row(
        children: [
          CircleAvatar(
            radius: 22,
            backgroundColor: kForge.withValues(alpha: 0.14),
            child: Text(
              _initials(client.name),
              style: const TextStyle(
                color: kForgeDark,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  client.name,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 2),
                Text(
                  [
                    if (count != null)
                      '$count ${count == 1 ? 'horse' : 'horses'}',
                    if (client.address.isNotEmpty) client.address,
                  ].join(' · '),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
          Icon(
            Icons.chevron_right_rounded,
            color: context.colors.textSecondary,
          ),
        ],
      ),
    );
  }

  String _initials(String name) {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.length >= 2) {
      return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
    }
    return name.isNotEmpty ? name[0].toUpperCase() : '?';
  }
}
