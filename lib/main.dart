import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shoein/core/router/router.dart';
import 'package:shoein/core/services/firebase_bootstrap.dart';
import 'package:shoein/core/theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await bootstrapFirebase();
  runApp(const ProviderScope(child: ShoeinApp()));
}

class ShoeinApp extends ConsumerWidget {
  const ShoeinApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);
    return GestureDetector(
      onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
      child: MaterialApp.router(
        title: "Shoein'",
        theme: AppTheme.light,
        routerConfig: router,
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}
