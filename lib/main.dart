import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shoein/core/config/map_config.dart';
import 'package:shoein/core/providers/data_providers.dart';
import 'package:shoein/core/providers/settings_providers.dart';
import 'package:shoein/core/router/router.dart';
import 'package:shoein/core/services/firebase_bootstrap.dart';
import 'package:shoein/core/services/notification_service.dart';
import 'package:shoein/core/services/subscription_service.dart';
import 'package:shoein/core/theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await bootstrapFirebase();
  await configureRevenueCat();
  MapboxOptions.setAccessToken(kMapboxAccessToken);
  await NotificationService.instance.init();
  final prefs = await SharedPreferences.getInstance();
  runApp(
    ProviderScope(
      overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
      child: const ShoeinApp(),
    ),
  );
}

class ShoeinApp extends ConsumerWidget {
  const ShoeinApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);
    final themeMode = ref.watch(themeModeProvider);

    // Keep on-device trim reminders in sync with what's due + the toggle.
    ref.listen(dueHorsesProvider, (_, due) {
      unawaited(
        NotificationService.instance.syncDueReminders(
          due,
          enabled: ref.read(remindersEnabledProvider),
        ),
      );
    });
    ref.listen(remindersEnabledProvider, (_, enabled) {
      unawaited(
        NotificationService.instance.syncDueReminders(
          ref.read(dueHorsesProvider),
          enabled: enabled,
        ),
      );
    });

    return GestureDetector(
      onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
      child: MaterialApp.router(
        title: "Shoein'",
        theme: AppTheme.light,
        darkTheme: AppTheme.dark,
        themeMode: themeMode,
        routerConfig: router,
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}
