import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:drawing_ui/drawing_ui.dart';
import 'package:example_app/core/routing/app_router.dart';
import 'package:example_app/core/di/injection.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize SharedPreferences
  final prefs = await SharedPreferences.getInstance();

  // Initialize GetIt dependencies
  await configureDependencies();

  // TODO: Initialize Supabase when credentials are ready
  // await Supabase.initialize(
  //   url: 'YOUR_SUPABASE_URL',
  //   anonKey: 'YOUR_SUPABASE_ANON_KEY',
  // );

  runApp(
    ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
      ],
      child: const StarNoteApp(),
    ),
  );
}

/// Main application widget for StarNote.
class StarNoteApp extends StatelessWidget {
  const StarNoteApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'StarNote',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      darkTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.blue,
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
      ),
      themeMode: ThemeMode.system,
      routerConfig: appRouter,
    );
  }
}
