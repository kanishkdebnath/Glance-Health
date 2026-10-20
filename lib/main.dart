import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app/providers.dart';
import 'app/router.dart';
import 'design/theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final prefs = await SharedPreferences.getInstance();
  runApp(
    ProviderScope(
      overrides: [prefsProvider.overrideWithValue(prefs)],
      child: const GlanceApp(),
    ),
  );
}

class GlanceApp extends ConsumerWidget {
  const GlanceApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themes = ref.watch(themeSetProvider);
    return MaterialApp.router(
      title: 'Glance Health',
      debugShowCheckedModeBanner: false,
      theme: buildTheme(themes.light),
      darkTheme: buildTheme(themes.dark),
      themeMode: ref.watch(themeModeProvider),
      routerConfig: router,
    );
  }
}
