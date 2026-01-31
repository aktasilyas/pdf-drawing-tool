/// Social login buttons for auth screens.
library;

import 'package:example_app/features/auth/presentation/constants/auth_strings.dart';
import 'package:flutter/material.dart';

class SocialLoginButtons extends StatelessWidget {
  final VoidCallback? onGooglePressed;
  final bool isLoading;

  const SocialLoginButtons({
    super.key,
    this.onGooglePressed,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        OutlinedButton.icon(
          onPressed: isLoading ? null : onGooglePressed,
          icon: const Icon(Icons.g_mobiledata),
          label: const Text(AuthStrings.continueWithGoogle),
        ),
      ],
    );
  }
}
