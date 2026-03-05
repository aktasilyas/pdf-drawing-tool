import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:drawing_ui/src/panels/page_options_widgets.dart';
import 'package:drawing_ui/src/providers/audio_recording_provider.dart';
import 'package:drawing_ui/src/theme/elyanotes_icons.dart';

/// Dropdown panel for the microphone toolbar button.
///
/// Shows two options: start recording and show recordings list.
/// When recording is active, the "Kaydet" button is replaced with a
/// disabled "Kayit devam ediyor..." label.
class AudioRecordingDropdown extends ConsumerWidget {
  const AudioRecordingDropdown({
    super.key,
    required this.onClose,
    required this.onShowRecordings,
  });

  final VoidCallback onClose;
  final VoidCallback onShowRecordings;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;
    final isActive = ref.watch(isRecordingProvider);

    return SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const PageOptionsHeader(title: 'Ses Kaydi'),
          Divider(height: 0.5, thickness: 0.5, color: cs.outlineVariant),
          if (isActive)
            PageOptionsMenuItem(
              icon: ElyanotesIcons.recordCircle,
              label: 'Kayit devam ediyor...',
              onTap: null,
            )
          else
            PageOptionsMenuItem(
              icon: ElyanotesIcons.recordCircle,
              label: 'Kaydet',
              onTap: () => _startRecording(context, ref),
            ),
          PageOptionsMenuItem(
            icon: ElyanotesIcons.waveform,
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

  Future<void> _startRecording(BuildContext context, WidgetRef ref) async {
    // Check total recording limit before starting
    final canStart = ref.read(canStartRecordingProvider);
    if (!canStart) {
      final callback = ref.read(onRecordingBlockedProvider);
      // Capture the navigator's overlay context before closing dropdown.
      // This context survives dropdown disposal.
      final overlayContext =
          Navigator.of(context).overlay?.context ?? context;
      onClose();
      if (callback != null) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (overlayContext.mounted) callback(overlayContext);
        });
      }
      return;
    }

    final service = ref.read(audioRecordingServiceProvider);

    final hasPerms = await service.hasPermission();
    if (!hasPerms) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Mikrofon izni gerekli. '
                'Lütfen ayarlardan izin verin.'),
          ),
        );
      }
      return;
    }

    final started = await service.startRecording();
    if (started) {
      onClose();
    }
  }
}
