import 'package:drawing_core/drawing_core.dart' show PdfPathResolver;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:example_app/core/bootstrap/app_bootstrap.dart';
import 'package:example_app/core/bootstrap/app_overrides.dart';
import 'package:example_app/core/bootstrap/startup_gate.dart';
import 'package:example_app/core/core.dart';
import 'package:example_app/features/documents/documents.dart';
import 'package:example_app/features/settings/settings.dart';
import 'package:example_app/l10n/l10n.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Hide status bar globally for entire app
  SystemChrome.setEnabledSystemUIMode(
    SystemUiMode.immersiveSticky,
    overlays: [],
  );

  final flags = FeatureFlags.fromEnvironment();
  final bootstrap = AppBootstrap(flags: flags);
  // First attempt before runApp: on success the native splash stays up until
  // the library's first frame. On failure the gate shows a Retry screen.
  final initial = await attemptStartup(bootstrap.run);

  runApp(
    StartupGate(
      initial: initial,
      bootstrap: bootstrap.run,
      appBuilder: (result) => ProviderScope(
        overrides: buildAppOverrides(
          flags: flags,
          prefs: result.prefs,
          crashReporter: result.crashReporter,
          pdfPaths: getIt<PdfPathResolver>(),
        ),
        child: const ElyaNotesApp(),
      ),
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

    final router = ref.watch(appRouterProvider);

    return MaterialApp.router(
      title: 'ElyaNotes', // l10n-ignore
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      debugShowCheckedModeBanner: false,
      builder: (context, child) {
        // Failed library mutations surface as a snackbar on any screen.
        final content = LibraryErrorListener(
          // Above the routes: PDFs opened from other apps are handled on
          // every screen, including while an editor is open.
          child: IncomingPdfListener(
            navigatorKey: ref.watch(appNavigatorKeyProvider),
            routeChanges: router.routerDelegate,
            isRouterReady: () => RouteNames.isLibraryRoute(
              router.routerDelegate.currentConfiguration.uri.path,
            ),
            child: child!,
          ),
        );
        // In landscape, remove all system padding so content fills
        // the entire screen including the notch/cutout area.
        if (MediaQuery.of(context).orientation == Orientation.landscape) {
          return MediaQuery.removePadding(
            context: context,
            removeLeft: true,
            removeRight: true,
            removeTop: true,
            removeBottom: true,
            child: content,
          );
        }
        return content;
      },
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: themeMode,
      routerConfig: router,
    );
  }
}
