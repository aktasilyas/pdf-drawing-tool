/// Phone header for auth screens with logo and title.
library;

import 'package:flutter/material.dart';

import 'package:example_app/core/theme/index.dart';

/// Header with logo and title for phone layout in auth screens.
class AuthPhoneHeader extends StatelessWidget {
  const AuthPhoneHeader({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textPrimary =
        isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight;

    return Column(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(AppRadius.lg),
          child: Image.asset(
            'assets/images/elyanotes_logo_transparent.png',
            width: 80,
            height: 80,
            errorBuilder: (_, __, ___) => Container(
              width: 80,
              height: 80,
              padding: const EdgeInsets.all(AppSpacing.lg),
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(AppRadius.lg),
                boxShadow: AppShadows.sm,
              ),
              child: const Icon(
                Icons.edit_note_rounded,
                size: AppIconSize.huge,
                color: AppColors.onPrimary,
              ),
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        Text(
          'ElyaNotes',
          style: AppTypography.headlineLarge.copyWith(color: textPrimary),
        ),
      ],
    );
  }
}
