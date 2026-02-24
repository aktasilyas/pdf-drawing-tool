import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../providers/export_progress_provider.dart';
import '../theme/starnote_icons.dart';

/// Floating progress indicator for PDF export operations.
///
/// Follows the same positioning/animation pattern as [FloatingRecordingBar]:
/// slides in from top-right, auto-dismisses on completion.
class FloatingExportProgress extends ConsumerWidget {
  const FloatingExportProgress({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(exportProgressProvider);
    final isActive = state.status != ExportProgressStatus.idle;

    return AnimatedPositioned(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOutCubic,
      top: isActive ? 16 : -120,
      right: 16,
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 250),
        opacity: isActive ? 1.0 : 0.0,
        child: isActive
            ? _ExportProgressContent(state: state)
            : const SizedBox.shrink(),
      ),
    );
  }
}

class _ExportProgressContent extends ConsumerWidget {
  const _ExportProgressContent({required this.state});
  final ExportProgressState state;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTap: state.status == ExportProgressStatus.error
          ? () => ref.read(exportProgressProvider.notifier).dismiss()
          : null,
      child: Container(
        width: 240,
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: cs.surface,
          borderRadius: BorderRadius.circular(16),
          border: isDark ? Border.all(color: cs.outlineVariant) : null,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.1),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 10),
              child: _buildBody(cs),
            ),
            _buildProgressBar(cs),
          ],
        ),
      ),
    );
  }

  Widget _buildBody(ColorScheme cs) {
    return switch (state.status) {
      ExportProgressStatus.exporting => _ExportingBody(state: state, cs: cs),
      ExportProgressStatus.completed => _CompletedBody(state: state, cs: cs),
      ExportProgressStatus.error => _ErrorBody(state: state, cs: cs),
      ExportProgressStatus.idle => const SizedBox.shrink(),
    };
  }

  Widget _buildProgressBar(ColorScheme cs) {
    final color = switch (state.status) {
      ExportProgressStatus.exporting => cs.primary,
      ExportProgressStatus.completed => Colors.green,
      ExportProgressStatus.error => cs.error,
      ExportProgressStatus.idle => cs.primary,
    };

    return SizedBox(
      height: 3,
      child: LinearProgressIndicator(
        value: state.status == ExportProgressStatus.error ? 1.0 : state.progress,
        backgroundColor: Colors.transparent,
        valueColor: AlwaysStoppedAnimation<Color>(color),
      ),
    );
  }
}

class _ExportingBody extends StatelessWidget {
  const _ExportingBody({required this.state, required this.cs});
  final ExportProgressState state;
  final ColorScheme cs;

  @override
  Widget build(BuildContext context) {
    final pct = (state.progress * 100).round();
    final estimate = state.estimatedTimeRemaining;
    final detail = StringBuffer('%$pct');
    if (state.totalPages > 0) {
      detail.write(' \u00b7 ${state.currentPage}/${state.totalPages}');
    }
    if (estimate.isNotEmpty) detail.write(' \u00b7 $estimate');

    return Row(
      children: [
        SizedBox(
          width: 18,
          height: 18,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            valueColor: AlwaysStoppedAnimation<Color>(cs.primary),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'PDF Dışa Aktarılıyor...',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: cs.onSurface,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                detail.toString(),
                style: TextStyle(
                  fontSize: 11,
                  color: cs.onSurfaceVariant,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _CompletedBody extends StatelessWidget {
  const _CompletedBody({required this.state, required this.cs});
  final ExportProgressState state;
  final ColorScheme cs;

  @override
  Widget build(BuildContext context) {
    final sizeText =
        state.fileSize != null ? ' (${state.fileSize})' : '';

    return Row(
      children: [
        PhosphorIcon(
          StarNoteIcons.checkCircle,
          size: 18,
          color: Colors.green,
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            'PDF Kaydedildi$sizeText',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: cs.onSurface,
            ),
          ),
        ),
      ],
    );
  }
}

class _ErrorBody extends StatelessWidget {
  const _ErrorBody({required this.state, required this.cs});
  final ExportProgressState state;
  final ColorScheme cs;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        PhosphorIcon(
          StarNoteIcons.warningCircle,
          size: 18,
          color: cs.error,
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            state.errorMessage ?? 'PDF dışa aktarılamadı',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: cs.error,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
