/// Drawing UI shadow tokens — neutral (black) only.
///
/// Values follow docs/specs/52-editor-chrome.md section 5. Light mode uses
/// two soft black layers; dark mode keeps depth minimal (no chrome shadow,
/// one stronger panel shadow).
library;

import 'package:flutter/material.dart';

/// Shadow helpers for drawing UI chrome (panels, toolbars, floats).
abstract class DrawingShadows {
  static const Color _shade = Colors.black;

  /// Chrome shadow — toolbar capsules and the docked tablet sidebar card.
  ///
  /// Light: black 6% y1 blur3 + black 4% y4 blur12 spread-2. Dark: none.
  static List<BoxShadow> chrome(Brightness brightness) {
    if (brightness == Brightness.light) {
      return [
        BoxShadow(
          color: _shade.withValues(alpha: 0.06),
          offset: const Offset(0, 1),
          blurRadius: 3,
        ),
        BoxShadow(
          color: _shade.withValues(alpha: 0.04),
          offset: const Offset(0, 4),
          blurRadius: 12,
          spreadRadius: -2,
        ),
      ];
    }
    return const [];
  }

  /// Panel shadow — tool_panel, popover_panel, anchored_panel,
  /// selection_toolbar, compact_color_picker, selection_overflow_menu.
  ///
  /// Light: black 8% y8 blur24 spread-4 + black 4% y1 blur3.
  /// Dark: black 32% y8 blur24 spread-4.
  static List<BoxShadow> panel(Brightness brightness) {
    if (brightness == Brightness.light) {
      return [
        BoxShadow(
          color: _shade.withValues(alpha: 0.08),
          offset: const Offset(0, 8),
          blurRadius: 24,
          spreadRadius: -4,
        ),
        BoxShadow(
          color: _shade.withValues(alpha: 0.04),
          offset: const Offset(0, 1),
          blurRadius: 3,
        ),
      ];
    }
    return [
      BoxShadow(
        color: _shade.withValues(alpha: 0.32),
        offset: const Offset(0, 8),
        blurRadius: 24,
        spreadRadius: -4,
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
          color: _shade.withValues(alpha: 0.06),
          offset: const Offset(0, 1),
          blurRadius: 4,
        ),
        BoxShadow(
          color: _shade.withValues(alpha: 0.08),
          offset: const Offset(0, 2),
          blurRadius: 8,
          spreadRadius: -1,
        ),
      ];
    }
    return [
      BoxShadow(
        color: _shade.withValues(alpha: 0.20),
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
    final color = tintColor ?? _shade;
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
          color: _shade.withValues(alpha: 0.04),
          offset: const Offset(0, 1),
          blurRadius: 3,
        ),
      ];
    }
    return [
      BoxShadow(
        color: _shade.withValues(alpha: 0.15),
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
          color: _shade.withValues(alpha: 0.06),
          offset: const Offset(0, 2),
          blurRadius: 8,
        ),
        BoxShadow(
          color: _shade.withValues(alpha: 0.05),
          offset: const Offset(0, 4),
          blurRadius: 16,
          spreadRadius: -2,
        ),
      ];
    }
    return [
      BoxShadow(
        color: _shade.withValues(alpha: 0.25),
        offset: const Offset(0, 2),
        blurRadius: 8,
      ),
    ];
  }

  /// No shadow.
  static List<BoxShadow> get none => [];
}
