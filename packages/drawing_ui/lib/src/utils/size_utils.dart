/// Size and layout utility extensions.
import 'package:flutter/material.dart';

/// Extension methods for BuildContext to access screen dimensions.
///
/// Provides convenient shortcuts for MediaQuery operations.
extension SizeUtils on BuildContext {
  /// Check if device is in landscape orientation.
  ///
  /// Example:
  /// ```dart
  /// if (context.isLandscape) {
  ///   // Show landscape-specific UI
  /// }
  /// ```
  bool get isLandscape {
    final size = MediaQuery.of(this).size;
    return size.width > size.height;
  }

  /// Check if device is in portrait orientation.
  bool get isPortrait => !isLandscape;

  /// Get screen width in logical pixels.
  ///
  /// Example:
  /// ```dart
  /// final halfWidth = context.screenWidth / 2;
  /// ```
  double get screenWidth => MediaQuery.of(this).size.width;

  /// Get screen height in logical pixels.
  ///
  /// Example:
  /// ```dart
  /// final quarterHeight = context.screenHeight / 4;
  /// ```
  double get screenHeight => MediaQuery.of(this).size.height;

  /// Get screen size.
  Size get screenSize => MediaQuery.of(this).size;

  /// Get device pixel ratio.
  double get devicePixelRatio => MediaQuery.of(this).devicePixelRatio;

  /// Get text scale factor.
  double get textScaleFactor => MediaQuery.of(this).textScaler.scale(1.0);

  /// Get safe area padding (notch, status bar, etc).
  EdgeInsets get safeAreaPadding => MediaQuery.of(this).padding;

  /// Get view insets (keyboard, etc).
  EdgeInsets get viewInsets => MediaQuery.of(this).viewInsets;

  /// Check if keyboard is visible.
  bool get isKeyboardVisible => viewInsets.bottom > 0;
}
