/// StarNote Design System - AppAvatar Component
///
/// Avatar komponenti.
///
/// Kullanım:
/// ```dart
/// AppAvatar(imageUrl: 'https://...', size: AppAvatarSize.medium)
/// AppAvatar(initials: 'IA', size: AppAvatarSize.large)
/// AppAvatar(icon: Icons.person, size: AppAvatarSize.small)
/// ```
library;

import 'package:flutter/material.dart';

import '../../theme/tokens/index.dart';

/// Avatar boyutları.
enum AppAvatarSize {
  /// Küçük: 32dp
  small,

  /// Orta: 40dp (varsayılan)
  medium,

  /// Büyük: 56dp
  large,
}

/// StarNote avatar komponenti.
///
/// 3 farklı boyut, image/initials/icon destekler.
class AppAvatar extends StatelessWidget {
  /// Profil resmi URL'i.
  final String? imageUrl;

  /// İnisiyeller (örn: "IA").
  final String? initials;

  /// Icon (fallback).
  final IconData? icon;

  /// Avatar boyutu.
  final AppAvatarSize size;

  /// Arka plan rengi (null ise varsayılan).
  final Color? backgroundColor;

  const AppAvatar({
    this.imageUrl,
    this.initials,
    this.icon,
    this.size = AppAvatarSize.medium,
    this.backgroundColor,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final sizeValue = _getSizeValue();
    final bgColor =
        backgroundColor ?? AppColors.primaryLight.withValues(alpha: 0.2);

    return Container(
      width: sizeValue,
      height: sizeValue,
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(AppRadius.full),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppRadius.full),
        child: _buildContent(),
      ),
    );
  }

  Widget _buildContent() {
    // Öncelik: imageUrl > initials > icon > default
    if (imageUrl != null && imageUrl!.isNotEmpty) {
      return Image.network(
        imageUrl!,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => _buildFallback(),
      );
    }

    return _buildFallback();
  }

  Widget _buildFallback() {
    if (initials != null && initials!.isNotEmpty) {
      return Center(
        child: Text(
          initials!.toUpperCase(),
          style: _getTextStyle(),
        ),
      );
    }

    final iconData = icon ?? Icons.person;
    return Icon(
      iconData,
      size: _getIconSize(),
      color: AppColors.primary,
    );
  }

  double _getSizeValue() {
    switch (size) {
      case AppAvatarSize.small:
        return 32;
      case AppAvatarSize.medium:
        return 40;
      case AppAvatarSize.large:
        return 56;
    }
  }

  TextStyle _getTextStyle() {
    switch (size) {
      case AppAvatarSize.small:
        return AppTypography.caption.copyWith(
          color: AppColors.primary,
          fontWeight: FontWeight.w600,
        );
      case AppAvatarSize.medium:
        return AppTypography.labelMedium.copyWith(
          color: AppColors.primary,
          fontWeight: FontWeight.w600,
        );
      case AppAvatarSize.large:
        return AppTypography.titleMedium.copyWith(
          color: AppColors.primary,
          fontWeight: FontWeight.w600,
        );
    }
  }

  double _getIconSize() {
    switch (size) {
      case AppAvatarSize.small:
        return AppIconSize.sm;
      case AppAvatarSize.medium:
        return AppIconSize.md;
      case AppAvatarSize.large:
        return AppIconSize.xl;
    }
  }
}
