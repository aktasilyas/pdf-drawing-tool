/// ElyaNotes Design System - AppBadge Component
///
/// Badge/notification indicator komponenti.
///
/// Kullanım:
/// ```dart
/// AppBadge(
///   label: '5',
///   child: Icon(Icons.notifications),
/// )
///
/// // Dot badge
/// AppBadge(
///   child: Icon(Icons.chat),
/// )
/// ```
library;

import 'package:flutter/material.dart';

import 'package:example_app/core/theme/index.dart';

/// ElyaNotes badge komponenti.
///
/// Widget'ın üzerine badge ekler (dot veya label).
class AppBadge extends StatelessWidget {
  /// Badge eklenecek child widget.
  final Widget child;

  /// Badge label'ı (null ise dot gösterilir).
  final String? label;

  /// Badge rengi.
  final Color? color;

  /// Badge gösterilsin mi?
  final bool isVisible;

  const AppBadge({
    required this.child,
    this.label,
    this.color,
    this.isVisible = true,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    if (!isVisible) {
      return child;
    }

    return Stack(
      clipBehavior: Clip.none,
      children: [
        child,
        Positioned(
          right: -4,
          top: -4,
          child: _buildBadge(),
        ),
      ],
    );
  }

  Widget _buildBadge() {
    final badgeColor = color ?? AppColors.error;

    if (label == null || label!.isEmpty) {
      // Dot badge
      return Container(
        width: 8,
        height: 8,
        decoration: BoxDecoration(
          color: badgeColor,
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white, width: 1.5),
        ),
      );
    }

    // Label badge
    return Container(
      constraints: const BoxConstraints(
        minWidth: 16,
        minHeight: 16,
      ),
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: badgeColor,
        borderRadius: BorderRadius.circular(AppRadius.full),
        border: Border.all(color: Colors.white, width: 1.5),
      ),
      child: Center(
        child: Text(
          label!,
          style: const TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w600,
            color: Colors.white,
            height: 1.0,
          ),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}
