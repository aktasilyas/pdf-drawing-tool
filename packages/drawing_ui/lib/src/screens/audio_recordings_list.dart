import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import 'package:drawing_ui/src/providers/audio_recording_provider.dart';
import 'package:drawing_ui/src/providers/document_provider.dart';
import 'package:drawing_ui/src/providers/page_provider.dart';
import 'package:drawing_ui/src/theme/starnote_icons.dart';

import 'audio_recording_list_item.dart';
import 'audio_rename_dialog.dart';

/// Sidebar body showing all audio recordings in the document.
///
/// Displays an empty state placeholder when no recordings exist.
class AudioRecordingsList extends ConsumerWidget {
  const AudioRecordingsList({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final recordings = ref.watch(audioRecordingsProvider).reversed.toList();
    final cs = Theme.of(context).colorScheme;

    if (recordings.isEmpty) {
      return _EmptyState(cs: cs);
    }

    return ListView.separated(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: recordings.length,
      separatorBuilder: (_, __) => Divider(
        height: 0.5,
        thickness: 0.5,
        color: cs.outlineVariant,
        indent: 12,
        endIndent: 12,
      ),
      itemBuilder: (context, index) {
        final recording = recordings[index];
        return AudioRecordingListItem(
          recording: recording,
          onRename: () => _handleRename(context, ref, recording.id,
              recording.title),
          onDelete: () => _handleDelete(context, ref, recording.id),
          onGoToPage: () {
            ref.read(pageManagerProvider.notifier)
                .goToPage(recording.pageIndex);
          },
        );
      },
    );
  }

  Future<void> _handleRename(
    BuildContext context,
    WidgetRef ref,
    String id,
    String currentTitle,
  ) async {
    final newTitle = await showAudioRenameDialog(context, currentTitle);
    if (newTitle != null && newTitle != currentTitle) {
      renameRecording(
        ref.read(documentProvider.notifier),
        id,
        newTitle,
      );
    }
  }

  void _handleDelete(BuildContext context, WidgetRef ref, String id) {
    removeRecording(ref.read(documentProvider.notifier), id);
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.cs});
  final ColorScheme cs;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          PhosphorIcon(
            StarNoteIcons.waveform,
            size: 48,
            color: cs.onSurfaceVariant.withValues(alpha: 0.4),
          ),
          const SizedBox(height: 12),
          Text(
            'Henuz kayit yok',
            style: GoogleFonts.sourceSerif4(
              fontSize: 14,
              color: cs.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}
