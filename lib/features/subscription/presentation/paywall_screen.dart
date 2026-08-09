import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:shoein/core/providers/access_providers.dart';
import 'package:shoein/core/services/subscription_service.dart';
import 'package:shoein/core/theme/app_theme.dart';
import 'package:url_launcher/url_launcher.dart';

const _termsUrl = 'https://auaha.app/shoein/terms';
const _privacyUrl = 'https://auaha.app/shoein/privacy';

class PaywallScreen extends HookConsumerWidget {
  const PaywallScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final offeringAsync = ref.watch(offeringsProvider);
    final selected = useState<Package?>(null);
    final busy = useState(false);
    final error = useState<String?>(null);
    final daysLeft = ref.watch(trialDaysLeftProvider);
    final expired = ref.watch(accessProvider) == AccessStatus.expired;

    Future<void> subscribe() async {
      final pkg = selected.value;
      if (pkg == null) return;
      busy.value = true;
      error.value = null;
      try {
        final ok = await ref
            .read(subscriptionProvider.notifier)
            .purchasePackage(pkg);
        if (ok && context.mounted) Navigator.of(context).maybePop();
      } catch (_) {
        error.value = "That didn't go through. Please try again.";
      } finally {
        busy.value = false;
      }
    }

    Future<void> restore() async {
      busy.value = true;
      error.value = null;
      try {
        await ref.read(subscriptionProvider.notifier).restore();
        if (ref.read(accessProvider) == AccessStatus.subscribed &&
            context.mounted) {
          Navigator.of(context).maybePop();
        } else {
          error.value = 'No active subscription found to restore.';
        }
      } catch (_) {
        error.value = "Couldn't restore purchases. Please try again.";
      } finally {
        busy.value = false;
      }
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Shoein\' Pro'),
        automaticallyImplyLeading: !expired,
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
          children: [
            Center(
              child: Image.asset(
                'assets/logo/shoein_mark.png',
                width: 72,
                height: 72,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              expired
                  ? 'Your free trial has ended'
                  : 'Keep your whole book in your pocket',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 6),
            Text(
              expired
                  ? 'Subscribe to keep adding clients, horses, and service records.'
                  : daysLeft != null
                  ? '$daysLeft ${daysLeft == 1 ? 'day' : 'days'} left in your free trial.'
                  : 'Subscribe for full access.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: context.colors.textSecondary,
              ),
            ),
            const SizedBox(height: 20),
            const _Feature('Unlimited clients & horses'),
            const _Feature('Service dates & due tracking'),
            const _Feature(
              'Map of your route + one-tap call, text & directions',
            ),
            const _Feature('Your book synced securely across devices'),
            const SizedBox(height: 22),
            offeringAsync.when(
              loading: () => const Center(
                child: Padding(
                  padding: EdgeInsets.all(24),
                  child: CircularProgressIndicator(),
                ),
              ),
              error: (_, _) => const _Unavailable(),
              data: (offering) {
                if (offering == null) return const _Unavailable();
                final packages = [
                  if (offering.annual != null) offering.annual!,
                  if (offering.monthly != null) offering.monthly!,
                  ...offering.availablePackages.where(
                    (p) =>
                        p.packageType != PackageType.annual &&
                        p.packageType != PackageType.monthly,
                  ),
                ];
                selected.value ??= packages.isNotEmpty ? packages.first : null;
                return Column(
                  children: [
                    for (final p in packages)
                      _PlanCard(
                        package: p,
                        selected: selected.value == p,
                        onTap: () => selected.value = p,
                      ),
                  ],
                );
              },
            ),
            if (error.value != null) ...[
              const SizedBox(height: 12),
              Text(
                error.value!,
                textAlign: TextAlign.center,
                style: const TextStyle(color: kOverdueRed, fontSize: 13),
              ),
            ],
            const SizedBox(height: 18),
            FilledButton(
              onPressed: (busy.value || selected.value == null)
                  ? null
                  : subscribe,
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(52),
              ),
              child: busy.value
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Text('Subscribe'),
            ),
            TextButton(
              onPressed: busy.value ? null : restore,
              child: const Text('Restore purchases'),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                TextButton(
                  onPressed: () => launchUrl(
                    Uri.parse(_termsUrl),
                    mode: LaunchMode.externalApplication,
                  ),
                  child: const Text('Terms'),
                ),
                Text(
                  '·',
                  style: TextStyle(color: context.colors.textSecondary),
                ),
                TextButton(
                  onPressed: () => launchUrl(
                    Uri.parse(_privacyUrl),
                    mode: LaunchMode.externalApplication,
                  ),
                  child: const Text('Privacy'),
                ),
              ],
            ),
            Text(
              'Subscriptions renew automatically until cancelled. Manage or '
              'cancel anytime in your App Store / Google Play account settings.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: context.colors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Feature extends StatelessWidget {
  final String text;
  const _Feature(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          const Icon(Icons.check_circle_rounded, color: kForge, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(text, style: Theme.of(context).textTheme.bodyMedium),
          ),
        ],
      ),
    );
  }
}

class _PlanCard extends StatelessWidget {
  final Package package;
  final bool selected;
  final VoidCallback onTap;
  const _PlanCard({
    required this.package,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final product = package.storeProduct;
    final isAnnual = package.packageType == PackageType.annual;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: selected
            ? kForge.withValues(alpha: 0.10)
            : context.colors.surface,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: selected ? kForge : context.colors.border,
                width: selected ? 2 : 1,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  selected
                      ? Icons.radio_button_checked_rounded
                      : Icons.radio_button_unchecked_rounded,
                  color: selected ? kForge : context.colors.textSecondary,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            isAnnual ? 'Annual' : 'Monthly',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          if (isAnnual) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: kForge,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: const Text(
                                'Best value',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      Text(
                        product.title,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
                Text(
                  product.priceString,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Unavailable extends StatelessWidget {
  const _Unavailable();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.colors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: context.colors.border),
      ),
      child: Text(
        'Plans aren\'t available right now. Please check your connection and '
        'try again in a moment.',
        textAlign: TextAlign.center,
        style: Theme.of(
          context,
        ).textTheme.bodyMedium?.copyWith(color: context.colors.textSecondary),
      ),
    );
  }
}
