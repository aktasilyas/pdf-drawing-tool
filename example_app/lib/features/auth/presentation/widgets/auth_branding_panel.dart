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
                Container(
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
                const SizedBox(height: AppSpacing.xl),
                // Title
                Text(
                  'StarNote',
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
              ],
            ),
          ),
        ),
      ),
    );
  }
}
