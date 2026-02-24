import 'package:flutter/material.dart';

/// Shows a dialog to rename an audio recording.
///
/// Returns the new title or null if cancelled.
Future<String?> showAudioRenameDialog(
  BuildContext context,
  String currentTitle,
) {
  final controller = TextEditingController(text: currentTitle);
  controller.selection = TextSelection(
    baseOffset: 0,
    extentOffset: currentTitle.length,
  );

  return showDialog<String>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text('Yeniden Adlandir'),
      content: TextField(
        controller: controller,
        autofocus: true,
        decoration: const InputDecoration(hintText: 'Kayit adi'),
        onSubmitted: (v) {
          final trimmed = v.trim();
          Navigator.pop(ctx, trimmed.isEmpty ? null : trimmed);
        },
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx),
          child: const Text('İptal'),
        ),
        FilledButton(
          onPressed: () {
            final trimmed = controller.text.trim();
            Navigator.pop(ctx, trimmed.isEmpty ? null : trimmed);
          },
          child: const Text('Kaydet'),
        ),
      ],
    ),
  );
}
