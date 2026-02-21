import 'package:drawing_core/drawing_core.dart';
import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import 'package:drawing_ui/src/theme/starnote_icons.dart';

/// A single audio recording row in the sidebar recordings list.
class AudioRecordingListItem extends StatelessWidget {
  const AudioRecordingListItem({
    super.key,
    required this.recording,
    required this.onPlay,
    required this.onRename,
    required this.onDelete,
    required this.onGoToPage,
  });

  final AudioRecording recording;
  final VoidCallback onPlay;
  final VoidCallback onRename;
  final VoidCallback onDelete;
  final VoidCallback onGoToPage;

  String _formatDuration(Duration d) {
    final minutes = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}.'
        '${date.month.toString().padLeft(2, '0')}.'
        '${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return InkWell(
      onTap: onGoToPage,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Row(
          children: [
            // Play button placeholder
            _PlayButton(cs: cs, onTap: onPlay),
            const SizedBox(width: 10),
            // Title + metadata
            Expanded(child: _TitleAndMeta(
              title: recording.title,
              duration: _formatDuration(recording.duration),
              pageIndex: recording.pageIndex,
              date: _formatDate(recording.createdAt),
              cs: cs,
            )),
            // More menu
            _MoreMenu(
              cs: cs,
              onRename: onRename,
              onDelete: onDelete,
            ),
          ],
        ),
      ),
    );
  }
}

class _PlayButton extends StatelessWidget {
  const _PlayButton({required this.cs, required this.onTap});
  final ColorScheme cs;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: cs.primaryContainer,
        ),
        child: Center(
          child: PhosphorIcon(
            StarNoteIcons.play,
            size: 16,
            color: cs.onPrimaryContainer,
          ),
        ),
      ),
    );
  }
}

class _TitleAndMeta extends StatelessWidget {
  const _TitleAndMeta({
    required this.title,
    required this.duration,
    required this.pageIndex,
    required this.date,
    required this.cs,
  });
  final String title;
  final String duration;
  final int pageIndex;
  final String date;
  final ColorScheme cs;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: cs.onSurface,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 2),
        Text(
          '$duration  ·  Sayfa ${pageIndex + 1}  ·  $date',
          style: TextStyle(fontSize: 11, color: cs.onSurfaceVariant),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }
}

class _MoreMenu extends StatelessWidget {
  const _MoreMenu({
    required this.cs,
    required this.onRename,
    required this.onDelete,
  });
  final ColorScheme cs;
  final VoidCallback onRename;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      icon: PhosphorIcon(
        StarNoteIcons.moreVert,
        size: 18,
        color: cs.onSurfaceVariant,
      ),
      padding: EdgeInsets.zero,
      constraints: const BoxConstraints(minWidth: 160),
      onSelected: (value) {
        if (value == 'rename') onRename();
        if (value == 'delete') onDelete();
      },
      itemBuilder: (_) => [
        PopupMenuItem(
          value: 'rename',
          child: Row(
            children: [
              PhosphorIcon(StarNoteIcons.editPencil, size: 18,
                  color: cs.onSurface),
              const SizedBox(width: 12),
              const Text('Yeniden adlandir'),
            ],
          ),
        ),
        PopupMenuItem(
          value: 'delete',
          child: Row(
            children: [
              PhosphorIcon(StarNoteIcons.trash, size: 18, color: cs.error),
              const SizedBox(width: 12),
              Text('Sil', style: TextStyle(color: cs.error)),
            ],
          ),
        ),
      ],
    );
  }
}
