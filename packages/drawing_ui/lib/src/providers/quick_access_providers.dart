import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Grid visibility provider.
final gridVisibilityProvider = StateProvider<bool>((ref) => true);

/// Quick colors provider - 5 colors for quick access in toolbar.
/// Default colors based on common drawing tool colors.
final quickColorsProvider = StateProvider<List<Color>>((ref) {
  return const [
    Color(0xFF000000), // Black
    Color(0xFF1976D2), // Blue
    Color(0xFFD32F2F), // Red
    Color(0xFF388E3C), // Green
    Color(0xFFF57C00), // Orange
  ];
});

/// Quick thickness provider - 3 thickness values for quick access.
/// Small, Medium, Large options.
final quickThicknessProvider = StateProvider<List<double>>((ref) {
  return const [1.0, 2.5, 5.0];
});

