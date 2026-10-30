import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Quick thickness provider - 3 thickness values for quick access.
/// Small, Medium, Large options.
final quickThicknessProvider = StateProvider<List<double>>((ref) {
  return const [1.0, 2.5, 5.0];
});
