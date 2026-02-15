import 'package:flutter/material.dart';

/// Default color palette for the drawing UI.
///
/// These colors are used throughout the drawing UI components.
/// Override via [DrawingTheme] to customize.
class DrawingColors {
  const DrawingColors._();

  /// Default pen colors available in the color picker.
  static const List<Color> penColors = [
    Color(0xFF000000), // Black
    Color(0xFF424242), // Dark Gray
    Color(0xFF757575), // Gray
    Color(0xFFBDBDBD), // Light Gray
    Color(0xFFFFFFFF), // White
    Color(0xFFD32F2F), // Red
    Color(0xFFE91E63), // Pink
    Color(0xFF9C27B0), // Purple
    Color(0xFF673AB7), // Deep Purple
    Color(0xFF3F51B5), // Indigo
    Color(0xFF2196F3), // Blue
    Color(0xFF03A9F4), // Light Blue
    Color(0xFF00BCD4), // Cyan
    Color(0xFF009688), // Teal
    Color(0xFF4CAF50), // Green
    Color(0xFF8BC34A), // Light Green
    Color(0xFFCDDC39), // Lime
    Color(0xFFFFEB3B), // Yellow
    Color(0xFFFFC107), // Amber
    Color(0xFFFF9800), // Orange
    Color(0xFFFF5722), // Deep Orange
    Color(0xFF795548), // Brown
  ];

  /// Default highlighter colors (translucent).
  static const List<Color> highlighterColors = [
    Color(0x80FFEB3B), // Yellow
    Color(0x8000E676), // Green
    Color(0x8040C4FF), // Light Blue
    Color(0x80FF80AB), // Pink
    Color(0x80E040FB), // Purple
    Color(0x80FF6E40), // Orange
  ];

  /// Toolbar background color.
  static const Color toolbarBackground = Color(0xFFF4F5F9);

  /// Toolbar icon color (default state).
  static const Color toolbarIcon = Color(0xFF8E92A4);

  /// Toolbar icon color (selected state).
  static const Color toolbarIconSelected = Color(0xFF1B2141);

  /// Toolbar icon color (disabled state).
  static const Color toolbarIconDisabled = Color(0xFFCDD0DB);

  /// Pen box background color.
  static const Color penBoxBackground = Color(0xFFFFFFFF);

  /// Pen box slot selected background.
  static const Color penBoxSlotSelected = Color(0xFFEEEFF5);

  /// Panel background color.
  static const Color panelBackground = Color(0xFFFFFFFF);

  /// Panel border color.
  static const Color panelBorder = Color(0xFFE2E4ED);

  /// Canvas background color.
  static const Color canvasBackground = Color(0xFFFFFFFF);

  /// Selection highlight color — lacivert tint.
  static const Color selectionHighlight = Color(0x401B2141);

  /// Eraser preview color.
  static const Color eraserPreview = Color(0x40EF4444);
}
