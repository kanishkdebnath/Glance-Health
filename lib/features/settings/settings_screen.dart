import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/providers.dart';
import '../../core/health/health_connect_source.dart';
import '../../design/theme.dart';
import '../../design/tokens.dart';
import '../../design/widgets.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = context.type;
    final mode = ref.watch(themeModeProvider);
    final p = context.palette;
    return Wash(
      colors: Wash.mix(p.steps, p.sleep),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: const Text('Settings'),
          backgroundColor: Colors.transparent,
          scrolledUnderElevation: 0,
        ),
        body: ListView(
          padding: const EdgeInsets.all(Space.screen),
          children: [
            Text('HEALTH DATA', style: t.eyebrow),
            const SizedBox(height: Space.s),
            const _HealthDataCard(),
            const SizedBox(height: Space.xl),
            Text('APPEARANCE', style: t.eyebrow),
            const SizedBox(height: Space.s),
            Segmented(
              values: ThemeMode.values,
              selected: mode,
              labelOf: (m) => switch (m) {
                ThemeMode.system => 'System',
                ThemeMode.light => 'Light',
                ThemeMode.dark => 'Dark',
              },
              onChanged: (m) => ref.read(themeModeProvider.notifier).set(m),
            ),
          ],
        ),
      ),
    );
  }
}

class _HealthDataCard extends ConsumerWidget {
  const _HealthDataCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = context.type;
    final p = context.palette;
    final status = ref.watch(healthStatusProvider);
    final mode = ref.watch(dataModeProvider);
    final connected = status.value == HealthConnectStatus.connected;

    Future<void> connect() async {
      final access = ref.read(healthAccessProvider);
      if (status.value == HealthConnectStatus.unavailable ||
          status.value == HealthConnectStatus.updateRequired) {
        await access.openStoreListing();
        return;
      }
      final ok = await access.connect();
      ref.invalidate(healthStatusProvider);
      if (ok) ref.read(dataModeProvider.notifier).set(DataMode.healthConnect);
      if (context.mounted) {
        showGlassToast(
          context,
          ok
              ? 'Connected to Health Connect'
              : 'Access not granted. You can allow it any time.',
        );
      }
    }

    final (title, detail) = switch (status) {
      AsyncData(value: HealthConnectStatus.connected) => (
        'Health Connect',
        'Connected · read only',
      ),
      AsyncData(value: HealthConnectStatus.notConnected) => (
        'Health Connect',
        'Not connected yet',
      ),
      AsyncData(value: HealthConnectStatus.updateRequired) => (
        'Health Connect',
        'Needs an update from the Play Store',
      ),
      AsyncData(value: HealthConnectStatus.unavailable) => (
        'Health Connect',
        'Not installed on this phone',
      ),
      AsyncError() => ('Health Connect', "Couldn't check access"),
      _ => ('Health Connect', 'Checking…'),
    };

    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: Space.m,
        children: [
          Row(
            children: [
              Icon(
                Icons.link_rounded,
                color: connected ? p.steps.main : p.ink2,
              ),
              const SizedBox(width: Space.m),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: t.body),
                    Text(detail, style: t.small),
                  ],
                ),
              ),
            ],
          ),
          if (!connected)
            FilledButton(
              onPressed: connect,
              child: const Text('Connect Health Connect'),
            ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: Text('Show sample data', style: t.body),
            subtitle: Text(
              'Made-up numbers, for trying the app',
              style: t.small,
            ),
            value: mode == DataMode.sample,
            onChanged: (sample) => ref
                .read(dataModeProvider.notifier)
                .set(sample ? DataMode.sample : DataMode.healthConnect),
          ),
          if (connected)
            OutlinedButton.icon(
              onPressed: () => context.push('/settings/data-check'),
              icon: const Icon(Icons.fact_check_rounded),
              label: const Text('Data check'),
            ),
        ],
      ),
    );
  }
}
