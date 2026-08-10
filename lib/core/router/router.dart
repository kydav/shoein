import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shoein/core/presentation/app_shell.dart';
import 'package:shoein/core/providers/auth_provider.dart';
import 'package:shoein/features/auth/presentation/login_screen.dart';
import 'package:shoein/features/clients/presentation/client_detail_screen.dart';
import 'package:shoein/features/clients/presentation/client_form_screen.dart';
import 'package:shoein/features/clients/presentation/clients_screen.dart';
import 'package:shoein/features/dashboard/presentation/dashboard_screen.dart';
import 'package:shoein/features/earnings/presentation/earnings_screen.dart';
import 'package:shoein/features/invoicing/presentation/invoice_screen.dart';
import 'package:shoein/features/horses/presentation/horse_form_screen.dart';
import 'package:shoein/features/map/presentation/map_screen.dart';
import 'package:shoein/features/profile/presentation/profile_screen.dart';
import 'package:shoein/features/route/presentation/route_planner_screen.dart';
import 'package:shoein/features/schedule/presentation/appointment_form_screen.dart';
import 'package:shoein/features/schedule/presentation/schedule_screen.dart';
import 'package:shoein/features/subscription/presentation/paywall_screen.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final auth = ref.read(authNotifierProvider);
  return GoRouter(
    initialLocation: '/dashboard',
    refreshListenable: auth,
    redirect: (context, state) {
      final loggedIn = auth.isLoggedIn;
      final onLogin = state.matchedLocation == '/login';
      if (!loggedIn && !onLogin) return '/login';
      if (loggedIn && onLogin) return '/dashboard';
      return null;
    },
    routes: [
      GoRoute(path: '/login', builder: (c, s) => const LoginScreen()),
      GoRoute(path: '/paywall', builder: (c, s) => const PaywallScreen()),
      GoRoute(path: '/route', builder: (c, s) => const RoutePlannerScreen()),
      GoRoute(path: '/earnings', builder: (c, s) => const EarningsScreen()),
      GoRoute(
        path: '/schedule/new',
        builder: (c, s) {
          final day = s.uri.queryParameters['day'];
          return AppointmentFormScreen(
            initialDay: day == null ? null : DateTime.tryParse(day),
          );
        },
      ),
      GoRoute(
        path: '/schedule/:id/edit',
        builder: (c, s) =>
            AppointmentFormScreen(appointmentId: s.pathParameters['id']),
      ),
      GoRoute(
        path: '/clients/new',
        builder: (c, s) => const ClientFormScreen(),
      ),
      GoRoute(
        path: '/clients/:id/edit',
        builder: (c, s) => ClientFormScreen(clientId: s.pathParameters['id']),
      ),
      GoRoute(
        path: '/clients/:id/invoice',
        builder: (c, s) => InvoiceScreen(clientId: s.pathParameters['id']!),
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
            path: '/dashboard',
            pageBuilder: (c, s) =>
                const NoTransitionPage(child: DashboardScreen()),
          ),
          GoRoute(
            path: '/clients',
            pageBuilder: (c, s) =>
                const NoTransitionPage(child: ClientsScreen()),
          ),
          GoRoute(
            path: '/schedule',
            pageBuilder: (c, s) =>
                const NoTransitionPage(child: ScheduleScreen()),
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
