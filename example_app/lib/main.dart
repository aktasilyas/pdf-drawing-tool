import 'dart:convert';
import 'dart:io';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:drawing_ui/drawing_ui.dart';

void _writeDebugLog({
  required String hypothesisId,
  required String message,
  Map<String, Object?> data = const {},
}) {
  try {
    final file = File(
      r'c:\Users\aktas\source\repos\starnote_drawing_workspace\.cursor\debug.log',
    );
    final payload = {
      'sessionId': 'debug-session',
      'runId': 'run1',
      'hypothesisId': hypothesisId,
      'location': 'example_app/lib/main.dart',
      'message': message,
      'data': data,
      'timestamp': DateTime.now().millisecondsSinceEpoch,
    };
    file.writeAsStringSync(
      '${jsonEncode(payload)}\n',
      mode: FileMode.append,
    );
  } catch (_) {}
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // #region agent log - H4: App start
  _writeDebugLog(
    hypothesisId: 'H4',
    message: 'app_start',
    data: {'platform': Platform.operatingSystem},
  );
  // #endregion

  FlutterError.onError = (details) {
    // #region agent log - H1/H2/H3: FlutterError
    _writeDebugLog(
      hypothesisId: 'H1',
      message: 'flutter_error',
      data: {
        'exception': details.exceptionAsString(),
        'library': details.library,
      },
    );
    // #endregion
    FlutterError.presentError(details);
  };

  PlatformDispatcher.instance.onError = (error, stack) {
    // #region agent log - H1/H2/H3: PlatformDispatcher error
    _writeDebugLog(
      hypothesisId: 'H1',
      message: 'platform_error',
      data: {'error': error.toString()},
    );
    // #endregion
    return false;
  };

  // Initialize SharedPreferences for toolbar config persistence
  final prefs = await SharedPreferences.getInstance();

  runApp(
    ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
      ],
      child: const StarNoteApp(),
    ),
  );
}

/// Main application widget for the StarNote demo.
class StarNoteApp extends StatelessWidget {
  const StarNoteApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'StarNote Drawing',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      home: const DrawingScreen(),
    );
  }
}
