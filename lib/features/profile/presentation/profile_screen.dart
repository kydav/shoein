import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:shoein/core/presentation/widgets.dart';
import 'package:shoein/core/providers/auth_provider.dart';
import 'package:shoein/core/providers/data_providers.dart';
import 'package:shoein/core/theme/app_theme.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authNotifierProvider);
    final clients = ref.watch(clientsProvider).value ?? const [];

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
