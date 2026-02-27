import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:example_app/features/ai/presentation/widgets/ai_widgets.dart';

/// Full-screen AI chat modal (bottom sheet).
///
/// Delegates all chat UI to [AIChatContent].
class AIChatModal extends ConsumerWidget {
  const AIChatModal({super.key});

  /// Show the AI chat modal as a full-screen modal bottom sheet.
  static Future<void> show(BuildContext context) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const AIChatModal(),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius:
            const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: AIChatContent(
        onClose: () => Navigator.of(context).pop(),
      ),
    );
  }
}
