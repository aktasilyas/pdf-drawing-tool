import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:example_app/core/core.dart';
import 'package:example_app/features/settings/settings.dart';
import 'package:example_app/features/sync/presentation/providers/sync_provider.dart';
import 'package:drawing_ui/drawing_ui.dart' as drawing_ui;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Hide status bar globally for entire app
  SystemChrome.setEnabledSystemUIMode(
    SystemUiMode.immersiveSticky,
    overlays: [],
  );

  // Load environment variables
  await dotenv.load(fileName: ".env");

  // Initialize Supabase
  await Supabase.initialize(
    url: dotenv.env['SUPABASE_URL']!,
    anonKey: dotenv.env['SUPABASE_ANON_KEY']!,
    debug: true, // Dev için debug açık
  );

  logger.i('Supabase initialized: ${dotenv.env['SUPABASE_URL']}');

  // Initialize SharedPreferences
  final prefs = await SharedPreferences.getInstance();

  // Initialize GetIt dependencies
  await configureDependencies();

  runApp(
    ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        drawing_ui.sharedPreferencesProvider.overrideWithValue(prefs),
      ],
      child: const StarNoteApp(),
    ),
  );
}

/// Global Supabase client getter
final supabase = Supabase.instance.client;

/// Main application widget for StarNote.
class StarNoteApp extends ConsumerWidget {
  const StarNoteApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    
    final themeMode = switch (settings.themeMode) {
      AppThemeMode.light => ThemeMode.light,
      AppThemeMode.dark => ThemeMode.dark,
      AppThemeMode.system => ThemeMode.system,
    };

    return MaterialApp.router(
      title: 'StarNote',
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
      theme: ThemeData(
        colorSchemeSeed: const Color(0xFF38434F),
        useMaterial3: true,
        brightness: Brightness.light,
      ),
      darkTheme: ThemeData(
        colorSchemeSeed: const Color(0xFF38434F),
        useMaterial3: true,
        brightness: Brightness.dark,
      ),
      themeMode: themeMode,
      routerConfig: appRouter,
    );
  }
}
