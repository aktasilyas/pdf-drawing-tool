import 'package:flutter/material.dart';

import 'package:example_app/features/ai/presentation/widgets/ai_chat_content.dart';

/// Left-side AI chat sidebar used in the editor layout.
///
/// Wraps [AIChatContent] with a right border.
/// Width is controlled by the parent (DrawingScreen's AnimatedContainer).
class AIChatSidebar extends StatelessWidget {
  const AIChatSidebar({super.key, required this.onClose});

  /// Called when the user taps the close button.
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return DecoratedBox(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border(
          right: BorderSide(color: theme.colorScheme.outlineVariant),
        ),
      ),
      child: AIChatContent(onClose: onClose),
    );
  }
}
