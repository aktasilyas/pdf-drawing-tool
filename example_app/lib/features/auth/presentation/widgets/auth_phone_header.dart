/// Phone header for auth screens with logo and title.
library;

import 'package:flutter/material.dart';

import 'package:example_app/core/theme/index.dart';

/// Header with logo and title for phone layout in auth screens.
class AuthPhoneHeader extends StatelessWidget {
  const AuthPhoneHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
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
        const SizedBox(height: AppSpacing.md),
        Text(
          'StarNote',
          style: AppTypography.headlineLarge.copyWith(
            color: AppColors.textPrimaryLight,
          ),
        ),
      ],
    );
  }
}
