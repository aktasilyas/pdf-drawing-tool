/// Drawing UI shadow tokens — Emerald #00B988 tinted.
///
/// Mirrors AppShadows pattern from the host app.
/// Light mode: 2-layer (tint + black). Dark mode: minimal.
library;

import 'package:flutter/material.dart';

/// Shadow helpers for drawing UI chrome (panels, toolbars, floats).
abstract class DrawingShadows {
  static const Color _tint = Color(0xFF00B988);

  /// Panel shadow — tool_panel, popover_panel, anchored_panel,
  /// selection_toolbar, compact_color_picker, selection_overflow_menu.
  static List<BoxShadow> panel(Brightness brightness) {
    if (brightness == Brightness.light) {
      return [
        BoxShadow(
          color: _tint.withValues(alpha: 0.08),
          offset: const Offset(0, 2),
          blurRadius: 8,
        ),
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.06),
          offset: const Offset(0, 4),
          blurRadius: 12,
          spreadRadius: -2,
        ),
      ];
    }
    return [
      BoxShadow(
        color: Colors.black.withValues(alpha: 0.25),
        offset: const Offset(0, 2),
        blurRadius: 8,
      ),
    ];
  }

  /// Floating element shadow — floating_pen_box, floating_undo_redo,
  /// floating_recording_bar, floating_export_progress,
  /// floating_quick_colors, page_navigator, text_style_popup,
  /// paste_context_menu, ruler_overlay.
  static List<BoxShadow> floating(Brightness brightness) {
    if (brightness == Brightness.light) {
      return [
        BoxShadow(
          color: _tint.withValues(alpha: 0.06),
          offset: const Offset(0, 1),
          blurRadius: 4,
        ),
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.08),
          offset: const Offset(0, 2),
          blurRadius: 8,
          spreadRadius: -1,
        ),
      ];
    }
    return [
      BoxShadow(
        color: Colors.black.withValues(alpha: 0.20),
        offset: const Offset(0, 1),
        blurRadius: 4,
      ),
    ];
  }

  /// Selection highlight shadow — color_chip selected, pen_preset_slot.
  static List<BoxShadow> selection(
    Brightness brightness, [
    Color? tintColor,
  ]) {
    final color = tintColor ?? _tint;
    if (brightness == Brightness.light) {
      return [
        BoxShadow(
          color: color.withValues(alpha: 0.25),
          offset: const Offset(0, 1),
          blurRadius: 4,
        ),
      ];
    }
    return [
      BoxShadow(
        color: color.withValues(alpha: 0.30),
        offset: const Offset(0, 1),
        blurRadius: 4,
      ),
    ];
  }

  /// Toolbar shadow — page_indicator_bar, top bars. Very subtle.
  static List<BoxShadow> toolbar(Brightness brightness) {
    if (brightness == Brightness.light) {
      return [
        BoxShadow(
          color: _tint.withValues(alpha: 0.04),
          offset: const Offset(0, 1),
          blurRadius: 3,
        ),
      ];
    }
    return [
      BoxShadow(
        color: Colors.black.withValues(alpha: 0.15),
        offset: const Offset(0, 1),
        blurRadius: 2,
      ),
    ];
  }

  /// Page shadow — page_thumbnail, page_sidebar_widgets,
  /// drawing_screen page container.
  static List<BoxShadow> page(Brightness brightness) {
    if (brightness == Brightness.light) {
      return [
        BoxShadow(
          color: _tint.withValues(alpha: 0.06),
          offset: const Offset(0, 2),
          blurRadius: 8,
        ),
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.05),
          offset: const Offset(0, 4),
          blurRadius: 16,
          spreadRadius: -2,
        ),
      ];
    }
    return [
      BoxShadow(
        color: Colors.black.withValues(alpha: 0.25),
        offset: const Offset(0, 2),
        blurRadius: 8,
      ),
    ];
  }

  /// No shadow.
  static List<BoxShadow> get none => [];
}
