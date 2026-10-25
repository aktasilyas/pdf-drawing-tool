import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:example_app/core/bootstrap/app_bootstrap.dart';
import 'package:example_app/core/bootstrap/app_overrides.dart';
import 'package:example_app/core/core.dart';
import 'package:example_app/features/settings/settings.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Hide status bar globally for entire app
  SystemChrome.setEnabledSystemUIMode(
    SystemUiMode.immersiveSticky,
    overlays: [],
  );

  final flags = FeatureFlags.fromEnvironment();
  final result = await AppBootstrap(flags: flags).run();

  runApp(
    ProviderScope(
      overrides: buildAppOverrides(
        flags: flags,
        prefs: result.prefs,
        crashReporter: result.crashReporter,
      ),
      child: const ElyaNotesApp(),
    ),
  );
}

/// Main application widget for ElyaNotes.
class ElyaNotesApp extends ConsumerWidget {
  const ElyaNotesApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);

    final themeMode = switch (settings.themeMode) {
      AppThemeMode.light => ThemeMode.light,
      AppThemeMode.dark => ThemeMode.dark,
      AppThemeMode.system => ThemeMode.system,
    };

    return MaterialApp.router(
      title: 'ElyaNotes',
      debugShowCheckedModeBanner: false,
      builder: (context, child) {
        // In landscape, remove all system padding so content fills
        // the entire screen including the notch/cutout area.
        if (MediaQuery.of(context).orientation == Orientation.landscape) {
          return MediaQuery.removePadding(
            context: context,
            removeLeft: true,
            removeRight: true,
            removeTop: true,
            removeBottom: true,
            child: child!,
          );
        }
        return child!;
      },
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: themeMode,
      routerConfig: ref.watch(appRouterProvider),
    );
  }
}
