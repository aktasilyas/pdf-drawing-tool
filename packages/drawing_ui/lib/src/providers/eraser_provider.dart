import 'dart:ui';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drawing_core/drawing_core.dart';
import 'package:drawing_ui/src/providers/drawing_providers.dart' as dp;

// EraserSettings ve EraserSettingsNotifier drawing_providers.dart'ta tanımlı
// Burada sadece re-export ediyoruz
export 'package:drawing_ui/src/providers/drawing_providers.dart' 
    show EraserSettings, EraserSettingsNotifier, eraserSettingsProvider;

/// Eraser mode state - stroke, pixel veya lasso (backward compatibility)
final eraserModeProvider = StateProvider<dp.EraserMode>((ref) {
  return ref.watch(dp.eraserSettingsProvider).mode;
});

/// Eraser size state (piksel cinsinden) (backward compatibility)
final eraserSizeProvider = StateProvider<double>((ref) {
  return ref.watch(dp.eraserSettingsProvider).size;
});

/// Aktif eraser tool instance.
///
/// Mode veya size değiştiğinde otomatik yeniden oluşturulur.
final eraserToolProvider = Provider<EraserTool>((ref) {
  final settings = ref.watch(dp.eraserSettingsProvider);
  
  // drawing_providers.dart'taki EraserMode'u drawing_core'daki EraserMode'a çevir
  final coreMode = switch (settings.mode) {
    dp.EraserMode.stroke => EraserMode.stroke,
    dp.EraserMode.pixel => EraserMode.pixel,
    dp.EraserMode.lasso => EraserMode.stroke, // Lasso için de stroke kullan
  };

  return EraserTool(mode: coreMode, eraserSize: settings.size);
});

/// Pixel eraser tool instance
final pixelEraserToolProvider = Provider<PixelEraserTool>((ref) {
  final settings = ref.watch(dp.eraserSettingsProvider);
  return PixelEraserTool(
    size: settings.size,
    pressureSensitive: settings.pressureSensitive,
  );
});

/// Lasso eraser tool instance
final lassoEraserToolProvider = Provider<LassoEraserTool>((ref) {
  return LassoEraserTool();
});

/// Current eraser cursor position
final eraserCursorPositionProvider = StateProvider<Offset?>((ref) => null);

/// Lasso eraser path points
final lassoEraserPointsProvider = StateProvider<List<Offset>>((ref) => []);

/// Pixel eraser preview - affected segments (strokeId -> segment indices)
final pixelEraserPreviewProvider = StateProvider<Map<String, List<int>>>((ref) => {});

/// Eraser aktif mi? (currentTool eraser tiplerinden biri mi?)
final isEraserActiveProvider = Provider<bool>((ref) {
  // Bu provider tool_style_provider'daki currentToolProvider'a bağlı
  // Şimdilik false döndürüyor, DrawingCanvas entegrasyonunda güncellenecek
  return false;
});
