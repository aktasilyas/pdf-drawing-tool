/// Branding panel for auth screens (tablet layout).
library;

import 'package:flutter/material.dart';

import 'package:example_app/core/theme/index.dart';

/// Branding panel displayed on the left side of auth screens on tablets.
class AuthBrandingPanel extends StatelessWidget {
  const AuthBrandingPanel({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.primary,
      child: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.xxxl),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Logo
                ClipRRect(
                  borderRadius: BorderRadius.circular(AppRadius.xl),
                  child: Image.asset(
                    'assets/images/elyanotes_logo_transparent.png',
                    width: 120,
                    height: 120,
                    errorBuilder: (_, __, ___) => Container(
                      width: 120,
                      height: 120,
                      padding: const EdgeInsets.all(AppSpacing.xl),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceLight,
                        borderRadius: BorderRadius.circular(AppRadius.xl),
                        boxShadow: AppShadows.lg,
                      ),
                      child: const Icon(
                        Icons.edit_note_rounded,
                        size: AppIconSize.huge + 16,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.xl),
                // Title
                Text(
                  'ElyaNotes',
                  style: AppTypography.displayLarge.copyWith(
                    color: AppColors.onPrimary,
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                // Tagline
                Text(
                  'Notlarını özgürce yarat',
                  style: AppTypography.bodyLarge.copyWith(
                    color: AppColors.onPrimary.withValues(alpha: 0.9),
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppSpacing.xxxl),
                // Feature items
                const _FeatureItem(
                  icon: Icons.note_alt_outlined,
                  text: 'Sınırsız not ve çizim',
                ),
                const SizedBox(height: AppSpacing.lg),
                const _FeatureItem(
                  icon: Icons.picture_as_pdf_outlined,
                  text: 'PDF üzerine çizim',
                ),
                const SizedBox(height: AppSpacing.lg),
                const _FeatureItem(
                  icon: Icons.sync_outlined,
                  text: 'Tüm cihazlarda senkronize',
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _FeatureItem extends StatelessWidget {
  final IconData icon;
  final String text;

  const _FeatureItem({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          icon,
          size: AppIconSize.md,
          color: AppColors.onPrimary.withValues(alpha: 0.85),
        ),
        const SizedBox(width: AppSpacing.sm),
        Text(
          text,
          style: AppTypography.bodyMedium.copyWith(
            color: AppColors.onPrimary.withValues(alpha: 0.85),
          ),
        ),
      ],
    );
  }
}
