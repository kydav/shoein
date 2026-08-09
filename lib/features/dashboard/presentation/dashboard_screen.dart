import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:shoein/core/models/horse.dart';
import 'package:shoein/core/presentation/widgets.dart';
import 'package:shoein/core/providers/access_providers.dart';
import 'package:shoein/core/providers/data_providers.dart';
import 'package:shoein/core/services/contact_actions.dart';
import 'package:shoein/core/theme/app_theme.dart';
import 'package:shoein/features/services/presentation/log_visit_sheet.dart';
import 'package:shoein/features/subscription/presentation/access_banner.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final due = ref.watch(dueHorsesProvider);
    final hasClients =
        ref.watch(clientsProvider).valueOrNull?.isNotEmpty ?? false;

    List<DueHorse> withStatus(DueStatus s) =>
        due.where((d) => d.horse.dueStatus == s).toList();

    final overdue = withStatus(DueStatus.overdue);
    final thisWeek = withStatus(DueStatus.dueThisWeek);
    final upcoming = withStatus(DueStatus.upcoming);
    final needsDate = withStatus(DueStatus.neverServiced);
    final nothingToShow =
        overdue.isEmpty &&
        thisWeek.isEmpty &&
        upcoming.isEmpty &&
        needsDate.isEmpty;

    return Scaffold(
      appBar: AppBar(title: const Text('Today')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(0, 0, 0, 120),
        children: [
          const AccessBanner(),
          if (nothingToShow)
            _EmptyState(hasClients: hasClients)
          else ...[
            _Section(title: 'Overdue', accent: kOverdueRed, items: overdue),
            _Section(title: 'Due this week', accent: kForge, items: thisWeek),
            _Section(title: 'Coming up', accent: kForge, items: upcoming),
            _Section(
              title: 'Needs a service date',
              accent: kTextSecondary,
              items: needsDate,
            ),
          ],
        ],
      ),
    );
  }
}

class _Section extends StatelessWidget {
  final String title;
  final Color accent;
  final List<DueHorse> items;
  const _Section({
    required this.title,
    required this.accent,
    required this.items,
  });

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 18, 16, 8),
          child: Row(
            children: [
              Text(
                title,
                style: Theme.of(
                  context,
                ).textTheme.titleSmall?.copyWith(color: accent),
              ),
              const SizedBox(width: 8),
              Text(
                '${items.length}',
                style: Theme.of(
                  context,
                ).textTheme.labelSmall?.copyWith(color: accent),
              ),
            ],
          ),
        ),
        for (final d in items)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
            child: _DueRow(item: d),
          ),
      ],
    );
  }
}

class _DueRow extends ConsumerWidget {
  final DueHorse item;
  const _DueRow({required this.item});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final client = item.client;
    final horse = item.horse;
    final readOnly = ref.watch(isReadOnlyProvider);

    Future<void> logVisit() async {
      if (readOnly) {
        context.push('/paywall');
        return;
      }
      await showLogVisitSheet(context, clientId: client.id, horse: horse);
    }

    return SoftCard(
      onTap: () => context.push('/clients/${client.id}'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      horse.name,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    Text(
                      client.name,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              ServiceBadge(horse: horse),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              if (client.phone.isNotEmpty) ...[
                _MiniAction(
                  icon: Icons.call,
                  onTap: () => callNumber(client.phone),
                ),
                _MiniAction(
                  icon: Icons.sms_outlined,
                  onTap: () => textNumber(client.phone),
                ),
              ],
              if (client.address.isNotEmpty)
                _MiniAction(
                  icon: Icons.directions,
                  onTap: () => openDirections(client),
                ),
              const Spacer(),
              FilledButton.icon(
                onPressed: logVisit,
                icon: Icon(
                  readOnly ? Icons.lock_outline_rounded : Icons.check,
                  size: 18,
                ),
                label: const Text('Log visit'),
                style: FilledButton.styleFrom(
                  minimumSize: const Size(0, 38),
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MiniAction extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _MiniAction({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 6),
      child: IconButton(
        onPressed: onTap,
        icon: Icon(icon, size: 20, color: kForge),
        visualDensity: VisualDensity.compact,
        style: IconButton.styleFrom(
          backgroundColor: kForge.withValues(alpha: 0.10),
          minimumSize: const Size(38, 38),
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final bool hasClients;
  const _EmptyState({required this.hasClients});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 60, 24, 24),
      child: Column(
        children: [
          Icon(
            hasClients ? Icons.check_circle_outline : Icons.people_alt_outlined,
            size: 56,
            color: kForge.withValues(alpha: 0.6),
          ),
          const SizedBox(height: 16),
          Text(
            hasClients ? 'You\'re all caught up' : 'No clients yet',
            style: Theme.of(context).textTheme.headlineSmall,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 6),
          Text(
            hasClients
                ? 'No horses are due right now. Due and overdue horses will show up here.'
                : 'Add clients and their horses to start tracking trim cycles.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: context.colors.textSecondary,
            ),
          ),
          if (!hasClients) ...[
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: () => context.push('/clients/new'),
              icon: const Icon(Icons.add),
              label: const Text('Add client'),
            ),
          ],
        ],
      ),
    );
  }
}
