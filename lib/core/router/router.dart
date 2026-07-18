import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shoein/core/presentation/app_shell.dart';
import 'package:shoein/core/providers/auth_provider.dart';
import 'package:shoein/features/auth/presentation/login_screen.dart';
import 'package:shoein/features/clients/presentation/client_detail_screen.dart';
import 'package:shoein/features/clients/presentation/client_form_screen.dart';
import 'package:shoein/features/clients/presentation/clients_screen.dart';
import 'package:shoein/features/horses/presentation/horse_form_screen.dart';
import 'package:shoein/features/map/presentation/map_screen.dart';
import 'package:shoein/features/profile/presentation/profile_screen.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final auth = ref.read(authNotifierProvider);
  return GoRouter(
    initialLocation: '/clients',
    refreshListenable: auth,
    redirect: (context, state) {
      final loggedIn = auth.isLoggedIn;
      final onLogin = state.matchedLocation == '/login';
      if (!loggedIn && !onLogin) return '/login';
      if (loggedIn && onLogin) return '/clients';
      return null;
    },
    routes: [
      GoRoute(path: '/login', builder: (c, s) => const LoginScreen()),
      GoRoute(
        path: '/clients/new',
        builder: (c, s) => const ClientFormScreen(),
      ),
      GoRoute(
        path: '/clients/:id/edit',
        builder: (c, s) => ClientFormScreen(clientId: s.pathParameters['id']),
      ),
      GoRoute(
        path: '/clients/:id/horse/new',
        builder: (c, s) => HorseFormScreen(clientId: s.pathParameters['id']!),
      ),
      GoRoute(
        path: '/clients/:id/horse/:horseId/edit',
        builder: (c, s) => HorseFormScreen(
          clientId: s.pathParameters['id']!,
          horseId: s.pathParameters['horseId'],
        ),
      ),
      GoRoute(
        path: '/clients/:id',
        builder: (c, s) =>
            ClientDetailScreen(clientId: s.pathParameters['id']!),
      ),
      ShellRoute(
        builder: (c, s, child) =>
            AppShell(location: s.matchedLocation, child: child),
        routes: [
          GoRoute(
            path: '/clients',
            pageBuilder: (c, s) =>
                const NoTransitionPage(child: ClientsScreen()),
          ),
          GoRoute(
            path: '/map',
            pageBuilder: (c, s) => const NoTransitionPage(child: MapScreen()),
          ),
          GoRoute(
            path: '/profile',
            pageBuilder: (c, s) =>
                const NoTransitionPage(child: ProfileScreen()),
          ),
        ],
      ),
    ],
  );
});
