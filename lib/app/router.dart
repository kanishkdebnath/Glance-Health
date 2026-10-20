import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../design/metric_family.dart';
import '../design/theme.dart';
import '../features/settings/data_check_screen.dart';
import '../features/settings/settings_screen.dart';
import 'tabs.dart';

/// Paths double as widget deep links (e.g. glancehealth:///sleep).
final router = GoRouter(
  routes: [
    StatefulShellRoute.indexedStack(
      builder: (context, state, shell) => _Shell(shell),
      branches: [
        for (final tab in AppTab.values)
          StatefulShellBranch(
            routes: [GoRoute(path: tab.path, builder: (_, _) => tab.screen())],
          ),
      ],
    ),
    GoRoute(
      path: '/settings',
      builder: (_, _) => const SettingsScreen(),
      routes: [
        GoRoute(path: 'data-check', builder: (_, _) => const DataCheckScreen()),
      ],
    ),
  ],
);

class _Shell extends StatelessWidget {
  const _Shell(this.shell);
  final StatefulNavigationShell shell;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final t = context.type;
    return Scaffold(
      body: shell,
      bottomNavigationBar: NavigationBarTheme(
        data: NavigationBarThemeData(
          backgroundColor: p.surface,
          indicatorColor: p.chip,
          surfaceTintColor: Colors.transparent,
          labelTextStyle: WidgetStateProperty.resolveWith(
            (s) => t.tab.copyWith(
              color: s.contains(WidgetState.selected) ? p.ink : p.ink3,
            ),
          ),
        ),
        child: NavigationBar(
          height: 68,
          selectedIndex: shell.currentIndex,
          onDestinationSelected: (i) =>
              shell.goBranch(i, initialLocation: i == shell.currentIndex),
          destinations: [
            for (final tab in AppTab.values)
              NavigationDestination(
                icon: Icon(tab.icon, color: p.ink3),
                selectedIcon: Icon(
                  tab.icon,
                  color: tab.family == null
                      ? p.ink
                      : p.family(tab.family!).main,
                ),
                label: tab.label,
              ),
          ],
        ),
      ),
    );
  }
}
