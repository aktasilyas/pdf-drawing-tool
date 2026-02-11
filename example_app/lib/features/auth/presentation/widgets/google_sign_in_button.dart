/// Google Sign-In button for auth screens.
library;

import 'package:flutter/material.dart';

import 'package:example_app/core/theme/index.dart';

/// A styled button for Google Sign-In.
class GoogleSignInButton extends StatelessWidget {
  final VoidCallback? onPressed;

  const GoogleSignInButton({
    super.key,
    this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.button),
        ),
        side: const BorderSide(color: AppColors.outlineLight),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.g_mobiledata,
            size: AppIconSize.lg,
            color: AppColors.textPrimaryLight,
          ),
          const SizedBox(width: AppSpacing.sm),
          Text(
            'Google ile Giriş Yap',
            style: AppTypography.labelLarge.copyWith(
              color: AppColors.textPrimaryLight,
            ),
          ),
        ],
      ),
    );
  }
}
