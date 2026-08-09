import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:shoein/core/theme/app_theme.dart';

class AppShell extends StatelessWidget {
  final String location;
  final Widget child;
  const AppShell({required this.location, required this.child, super.key});

  static const _items = [
    (
      path: '/dashboard',
      icon: Icons.today_outlined,
      active: Icons.today,
      label: 'Today',
    ),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: child,
      backgroundColor: context.colors.pageBg,
      extendBody: true, // so the nav pill can float over the body
      bottomNavigationBar: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 6, 14, 12),
          child: _FloatingNav(location: location, items: _items),
        ),
      ),
    );
  }
}

typedef _NavItem = ({
  String path,
  IconData icon,
  IconData active,
  String label,
});

class _FloatingNav extends StatelessWidget {
  final String location;
  final List<_NavItem> items;
  const _FloatingNav({required this.location, required this.items});

  // Brighter "hot iron" amber than kForge so the active item pops on the
  // dark pill (matches the app icon's highlight).
  static const _activeAmber = Color(0xFFF59E0B);

  bool _isActive(String path) =>
      location == path || location.startsWith('$path/');

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 66,
      decoration: BoxDecoration(
        color: kAnvil,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.22),
            blurRadius: 22,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: items.map((item) {
          final active = _isActive(item.path);
          final color = active
              ? _activeAmber
              : Colors.white.withValues(alpha: 0.55);
          return Expanded(
            child: GestureDetector(
              onTap: () {
                HapticFeedback.lightImpact();
                context.go(item.path);
              },
              behavior: HitTestBehavior.opaque,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    active ? item.active : item.icon,
                    color: color,
                    size: 22,
                  ),
                  const SizedBox(height: 3),
                  Text(
                    item.label,
                    style: TextStyle(
                      color: color,
                      fontSize: 10,
                      fontWeight: active ? FontWeight.w600 : FontWeight.normal,
                    ),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}
