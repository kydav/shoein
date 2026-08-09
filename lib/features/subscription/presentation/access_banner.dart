import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:shoein/core/providers/access_providers.dart';
import 'package:shoein/core/theme/app_theme.dart';

/// A tappable banner shown during the trial (days-left countdown) or after it
/// expires (read-only notice). Hidden for subscribers. Tapping opens the paywall.
class AccessBanner extends ConsumerWidget {
  const AccessBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final status = ref.watch(accessProvider);
    final expired = status == AccessStatus.expired;
    final trialing = status == AccessStatus.trialing;
    if (!expired && !trialing) return const SizedBox.shrink();

    final daysLeft = ref.watch(trialDaysLeftProvider);
    final accent = expired ? kOverdueRed : kForge;
    final message = expired
        ? 'Read-only — subscribe to add or edit'
        : daysLeft != null
        ? '$daysLeft ${daysLeft == 1 ? 'day' : 'days'} left in your free trial'
        : 'Free trial';

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      child: Material(
        color: accent.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: () => context.push('/paywall'),
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            child: Row(
              children: [
                Icon(
                  expired ? Icons.lock_outline_rounded : Icons.timer_outlined,
                  color: accent,
                  size: 20,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    message,
                    style: TextStyle(
                      color: accent,
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                ),
                Text(
                  'Subscribe',
                  style: TextStyle(
                    color: accent,
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                  ),
                ),
                Icon(Icons.chevron_right_rounded, color: accent, size: 18),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
