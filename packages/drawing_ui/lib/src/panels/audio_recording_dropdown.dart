import 'package:flutter/material.dart';

import 'package:drawing_ui/src/panels/page_options_widgets.dart';
import 'package:drawing_ui/src/theme/starnote_icons.dart';

/// Dropdown panel for the microphone toolbar button.
///
/// Shows two options: start recording (placeholder) and show recordings list.
class AudioRecordingDropdown extends StatelessWidget {
  const AudioRecordingDropdown({
    super.key,
    required this.onClose,
    required this.onShowRecordings,
  });

  final VoidCallback onClose;
  final VoidCallback onShowRecordings;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const PageOptionsHeader(title: 'Ses Kaydi'),
          Divider(height: 0.5, thickness: 0.5, color: cs.outlineVariant),
          PageOptionsMenuItem(
            icon: StarNoteIcons.recordCircle,
            label: 'Kaydet',
            onTap: onClose,
          ),
          PageOptionsMenuItem(
            icon: StarNoteIcons.waveform,
            label: 'Kayitlari goster',
            onTap: () {
              onClose();
              onShowRecordings();
            },
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}
