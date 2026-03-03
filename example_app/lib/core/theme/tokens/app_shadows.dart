/// ElyaNotes Design System - Shadow Tokens
///
/// Green-tinted soft shadow sistemi.
/// Light modda 2 katmanlı (tint + black), dark modda minimal shadow.
///
/// Onay: 3 Mart 2026
library;

import 'package:flutter/material.dart';

/// Uygulama shadow sistemi — #00B988 tinted
abstract class AppShadows {
  static const Color _tint = Color(0xFF00B988);

  /// Level 1 — Resting card shadow
  static List<BoxShadow> cardResting(Brightness brightness) {
    if (brightness == Brightness.light) {
      return [
        BoxShadow(
          color: _tint.withValues(alpha: 0.06),
          offset: const Offset(0, 1),
          blurRadius: 4,
        ),
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.04),
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
        blurRadius: 3,
      ),
    ];
  }

  /// Level 3 — Elevated/active card, dragging
  static List<BoxShadow> cardElevated(Brightness brightness) {
    if (brightness == Brightness.light) {
      return [
        BoxShadow(
          color: _tint.withValues(alpha: 0.10),
          offset: const Offset(0, 4),
          blurRadius: 12,
        ),
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.08),
          offset: const Offset(0, 8),
          blurRadius: 24,
          spreadRadius: -2,
        ),
      ];
    }
    return [
      BoxShadow(
        color: Colors.black.withValues(alpha: 0.30),
        offset: const Offset(0, 4),
        blurRadius: 12,
      ),
    ];
  }

  /// Level 4 — Modal, dialog
  static List<BoxShadow> modal(Brightness brightness) {
    if (brightness == Brightness.light) {
      return [
        BoxShadow(
          color: _tint.withValues(alpha: 0.08),
          offset: const Offset(0, 4),
          blurRadius: 16,
        ),
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.12),
          offset: const Offset(0, 12),
          blurRadius: 32,
          spreadRadius: -4,
        ),
      ];
    }
    return [
      BoxShadow(
        color: Colors.black.withValues(alpha: 0.40),
        offset: const Offset(0, 8),
        blurRadius: 24,
      ),
    ];
  }

  /// Level 4 — FAB (dark modda primary glow)
  static List<BoxShadow> fab(Brightness brightness) {
    if (brightness == Brightness.light) {
      return [
        BoxShadow(
          color: _tint.withValues(alpha: 0.15),
          offset: const Offset(0, 4),
          blurRadius: 12,
        ),
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.10),
          offset: const Offset(0, 8),
          blurRadius: 24,
          spreadRadius: -2,
        ),
      ];
    }
    return [
      BoxShadow(
        color: _tint.withValues(alpha: 0.20),
        offset: const Offset(0, 4),
        blurRadius: 16,
      ),
      BoxShadow(
        color: Colors.black.withValues(alpha: 0.30),
        offset: const Offset(0, 6),
        blurRadius: 20,
      ),
    ];
  }

  /// Toolbar shadow — çok ince
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

  /// Gölge yok
  static List<BoxShadow> get none => [];
}
