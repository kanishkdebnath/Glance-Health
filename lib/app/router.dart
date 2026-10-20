import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../design/metric_family.dart';
import '../design/theme.dart';
import '../design/tokens.dart';
import '../design/widgets.dart';
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
    // The tab bar floats over the content, so screens scroll beneath it
    // and show through the glass.
    return Scaffold(
      extendBody: true,
      body: shell,
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            Space.screen,
            0,
            Space.screen,
            Space.m,
          ),
          child: _GlassTabBar(shell),
        ),
      ),
    );
  }
}

/// A floating glass capsule. The selected tab sits on a raised inner pill.
class _GlassTabBar extends StatelessWidget {
  const _GlassTabBar(this.shell);
  final StatefulNavigationShell shell;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final t = context.type;
    return GlassSurface(
      key: const Key('tabBar'),
      radius: Radii.chip,
      blur: 8,
      floating: true,
      // Brighter and clearer than cards so it reads as glass over the deep.
      fill: p.surface.withValues(alpha: p.isDark ? 0.10 : 0.30),
      child: SizedBox(
        height: 64,
        child: Padding(
          padding: const EdgeInsets.all(5),
          child: Row(
            children: [
              for (final tab in AppTab.values)
                Expanded(
                  child: Builder(
                    builder: (context) {
                      final on = shell.currentIndex == tab.index;
                      final color = !on
                          ? p.ink3
                          : tab.family == null
                          ? p.ink
                          : p.family(tab.family!).main;
                      final item = AnimatedContainer(
                        duration: Motion.quick,
                        decoration: BoxDecoration(
                          color: on
                              ? p.surface.withValues(
                                  alpha: p.isDark ? 0.12 : 0.7,
                                )
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(Radii.chip),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          spacing: 2,
                          children: [
                            Icon(tab.icon, size: 22, color: color),
                            Text(
                              tab.label,
                              style: t.tab.copyWith(color: on ? p.ink : p.ink3),
                            ),
                          ],
                        ),
                      );
                      return Semantics(
                        button: true,
                        selected: on,
                        label: tab.label,
                        excludeSemantics: true,
                        child: GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onTap: () =>
                              shell.goBranch(tab.index, initialLocation: on),
                          child: on
                              ? Raised(radius: Radii.chip, child: item)
                              : item,
                        ),
                      );
                    },
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
