import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:shoein/core/presentation/widgets.dart';
import 'package:shoein/core/providers/access_providers.dart';
import 'package:shoein/core/providers/auth_provider.dart';
import 'package:shoein/core/providers/data_providers.dart';
import 'package:shoein/core/providers/settings_providers.dart';
import 'package:shoein/core/services/notification_service.dart';
import 'package:shoein/core/services/subscription_service.dart';
import 'package:shoein/core/theme/app_theme.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authNotifierProvider);
    final clients = ref.watch(clientsProvider).value ?? const [];
    final themeMode = ref.watch(themeModeProvider);
    final access = ref.watch(accessProvider);
    final daysLeft = ref.watch(trialDaysLeftProvider);
    final remindersEnabled = ref.watch(remindersEnabledProvider);
    final businessName = ref.watch(businessNameProvider);
    final paymentLink = ref.watch(paymentLinkProvider);

    final subscribed = access == AccessStatus.subscribed;
    final subStatusLine = switch (access) {
      AccessStatus.subscribed => "Shoein' Pro — active",
      AccessStatus.trialing =>
        'Free trial — ${daysLeft ?? 0} ${daysLeft == 1 ? 'day' : 'days'} left',
      AccessStatus.expired => 'Trial ended — read-only',
      AccessStatus.loading => 'Checking subscription…',
    };

    Future<void> restore() async {
      try {
        await ref.read(subscriptionProvider.notifier).restore();
        if (!context.mounted) return;
        final ok = ref.read(accessProvider) == AccessStatus.subscribed;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              ok ? 'Purchases restored.' : 'No active subscription found.',
            ),
          ),
        );
      } catch (_) {
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Couldn't restore purchases.")),
        );
      }
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 40),
        children: [
          SoftCard(
            child: Row(
              children: [
                CircleAvatar(
                  radius: 28,
                  backgroundColor: kForge.withValues(alpha: 0.16),
                  child: Text(
                    auth.userInitials,
                    style: const TextStyle(
                      color: kForgeDark,
                      fontWeight: FontWeight.w700,
                      fontSize: 20,
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        auth.userName,
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                      if (auth.userEmail.isNotEmpty)
                        Text(
                          auth.userEmail,
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          SoftCard(
            child: Row(
              children: [
                const Icon(Icons.people_alt_outlined, color: kForge),
                const SizedBox(width: 12),
                Text(
                  '${clients.length} ${clients.length == 1 ? 'client' : 'clients'}',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          SoftCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Appearance',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 14),
                Text('Theme', style: Theme.of(context).textTheme.bodySmall),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: SegmentedButton<ThemeMode>(
                    segments: const [
                      ButtonSegment(
                        value: ThemeMode.system,
                        label: Text('System'),
                      ),
                      ButtonSegment(
                        value: ThemeMode.light,
                        label: Text('Light'),
                      ),
                      ButtonSegment(value: ThemeMode.dark, label: Text('Dark')),
                    ],
                    selected: {themeMode},
                    showSelectedIcon: false,
                    onSelectionChanged: (selection) => ref
                        .read(themeModeProvider.notifier)
                        .set(selection.first),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          SoftCard(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: SwitchListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 8),
              title: const Text('Trim reminders'),
              subtitle: const Text('A reminder when a horse is due for a trim'),
              value: remindersEnabled,
              onChanged: (v) async {
                await ref.read(remindersEnabledProvider.notifier).set(v);
                if (v) await NotificationService.instance.requestPermission();
              },
            ),
          ),
          const SizedBox(height: 16),
          SoftCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.receipt_long_outlined, color: kForge),
                    const SizedBox(width: 12),
                    Text(
                      'Business & payments',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const Spacer(),
                    TextButton(
                      onPressed: () => _editBusinessInfo(context, ref),
                      child: const Text('Edit'),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  businessName.isEmpty
                      ? 'Add your business name'
                      : businessName,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                Text(
                  paymentLink.isEmpty
                      ? 'Add a Venmo/Stripe payment link for invoices'
                      : paymentLink,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: context.colors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          SoftCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.workspace_premium_outlined, color: kForge),
                    const SizedBox(width: 12),
                    Text(
                      'Subscription',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  subStatusLine,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: context.colors.textSecondary,
                  ),
                ),
                const SizedBox(height: 12),
                if (!subscribed)
                  FilledButton(
                    onPressed: () => context.push('/paywall'),
                    style: FilledButton.styleFrom(
                      minimumSize: const Size.fromHeight(46),
                    ),
                    child: const Text('Subscribe'),
                  ),
                TextButton(
                  onPressed: restore,
                  child: const Text('Restore purchases'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          OutlinedButton.icon(
            onPressed: () => auth.signOut(),
            icon: const Icon(Icons.logout_rounded, color: kOverdueRed),
            label: const Text('Sign out', style: TextStyle(color: kOverdueRed)),
            style: OutlinedButton.styleFrom(
              minimumSize: const Size.fromHeight(50),
            ),
          ),
        ],
      ),
    );
  }
}

Future<void> _editBusinessInfo(BuildContext context, WidgetRef ref) async {
  final nameCtrl = TextEditingController(text: ref.read(businessNameProvider));
  final linkCtrl = TextEditingController(text: ref.read(paymentLinkProvider));
  final saved = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text('Business & payments'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: nameCtrl,
            textCapitalization: TextCapitalization.words,
            decoration: const InputDecoration(labelText: 'Business name'),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: linkCtrl,
            keyboardType: TextInputType.url,
            autocorrect: false,
            decoration: const InputDecoration(
              labelText: 'Payment link',
              hintText: 'venmo.com/u/… or a Stripe link',
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx, false),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(ctx, true),
          child: const Text('Save'),
        ),
      ],
    ),
  );
  if (saved == true) {
    await ref.read(businessNameProvider.notifier).set(nameCtrl.text);
    await ref.read(paymentLinkProvider.notifier).set(linkCtrl.text);
  }
  nameCtrl.dispose();
  linkCtrl.dispose();
}
