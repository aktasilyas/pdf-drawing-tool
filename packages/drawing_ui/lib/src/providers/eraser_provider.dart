import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drawing_core/drawing_core.dart';

/// Eraser mode state - stroke veya pixel
final eraserModeProvider = StateProvider<EraserMode>((ref) {
  return EraserMode.stroke;
});

/// Eraser size state (piksel cinsinden)
final eraserSizeProvider = StateProvider<double>((ref) {
  return 20.0;
});

/// Aktif eraser tool instance.
///
/// Mode veya size değiştiğinde otomatik yeniden oluşturulur.
final eraserToolProvider = Provider<EraserTool>((ref) {
  final mode = ref.watch(eraserModeProvider);
  final size = ref.watch(eraserSizeProvider);

  return EraserTool(mode: mode, eraserSize: size);
});

/// Eraser aktif mi? (currentTool eraser tiplerinden biri mi?)
final isEraserActiveProvider = Provider<bool>((ref) {
  // Bu provider tool_style_provider'daki currentToolProvider'a bağlı
  // Şimdilik false döndürüyor, DrawingCanvas entegrasyonunda güncellenecek
  return false;
});
