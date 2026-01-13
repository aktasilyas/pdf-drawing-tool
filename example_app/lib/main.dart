import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drawing_ui/drawing_ui.dart';

void main() {
  runApp(
    const ProviderScope(
      child: StarNoteApp(),
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
