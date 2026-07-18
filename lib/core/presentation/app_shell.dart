import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shoein/core/theme/app_theme.dart';

class AppShell extends StatelessWidget {
  final String location;
  final Widget child;
  const AppShell({required this.location, required this.child, super.key});

  static const _items = [
    (
      path: '/clients',
      icon: Icons.people_alt_outlined,
      active: Icons.people_alt,
      label: 'Clients',
    ),
    (path: '/map', icon: Icons.map_outlined, active: Icons.map, label: 'Map'),
    (
      path: '/profile',
      icon: Icons.person_outline_rounded,
      active: Icons.person_rounded,
      label: 'Profile',
    ),
  ];

  int get _index {
    final i = _items.indexWhere((e) => location.startsWith(e.path));
    return i < 0 ? 0 : i;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: child,
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        backgroundColor: Colors.white,
        indicatorColor: kForge.withValues(alpha: 0.14),
        onDestinationSelected: (i) => context.go(_items[i].path),
        destinations: [
          for (final it in _items)
            NavigationDestination(
              icon: Icon(it.icon),
              selectedIcon: Icon(it.active, color: kForge),
              label: it.label,
            ),
        ],
      ),
    );
  }
}
