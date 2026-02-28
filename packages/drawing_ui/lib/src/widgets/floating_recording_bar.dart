import 'package:drawing_core/drawing_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../providers/audio_recording_provider.dart';
import '../providers/document_provider.dart';
import '../providers/page_provider.dart';
import '../providers/sidebar_filter_provider.dart';
import '../services/audio_recording_service.dart';
import '../theme/starnote_icons.dart';

/// Floating recording bar shown during active audio recording.
///
/// Displays a pulsating red dot, elapsed time, pause/resume, and stop buttons.
/// Positioned at top-right of canvas, below the toolbar.
class FloatingRecordingBar extends ConsumerWidget {
  const FloatingRecordingBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isActive = ref.watch(isRecordingProvider);

    return AnimatedPositioned(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOutCubic,
      top: isActive ? 16 : -60,
      right: 16,
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 250),
        opacity: isActive ? 1.0 : 0.0,
        child: _RecordingBarContent(isActive: isActive),
      ),
    );
  }
}

class _RecordingBarContent extends ConsumerWidget {
  const _RecordingBarContent({required this.isActive});
  final bool isActive;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (!isActive) return const SizedBox.shrink();

    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final stateAsync = ref.watch(audioRecordingStateProvider);
    final durationAsync = ref.watch(recordingDurationProvider);

    final state = stateAsync.valueOrNull ?? AudioRecordingState.recording;
    final elapsed = durationAsync.valueOrNull ?? Duration.zero;
    final isPaused = state == AudioRecordingState.paused;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(22),
        border: isDark
            ? Border.all(color: cs.outlineVariant)
            : null,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _PulsatingDot(isPaused: isPaused),
          const SizedBox(width: 10),
          _TimerDisplay(elapsed: elapsed, cs: cs),
          const SizedBox(width: 16),
          _PauseResumeButton(isPaused: isPaused, cs: cs, ref: ref),
          const SizedBox(width: 8),
          _StopButton(cs: cs, ref: ref, elapsed: elapsed),
        ],
      ),
    );
  }
}

class _PulsatingDot extends StatefulWidget {
  const _PulsatingDot({required this.isPaused});
  final bool isPaused;

  @override
  State<_PulsatingDot> createState() => _PulsatingDotState();
}

class _PulsatingDotState extends State<_PulsatingDot>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    _animation = Tween<double>(begin: 0.4, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
    if (!widget.isPaused) _controller.repeat(reverse: true);
  }

  @override
  void didUpdateWidget(_PulsatingDot oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isPaused && _controller.isAnimating) {
      _controller.stop();
    } else if (!widget.isPaused && !_controller.isAnimating) {
      _controller.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.red.withValues(alpha: _animation.value),
          ),
        );
      },
    );
  }
}

class _TimerDisplay extends StatelessWidget {
  const _TimerDisplay({required this.elapsed, required this.cs});
  final Duration elapsed;
  final ColorScheme cs;

  @override
  Widget build(BuildContext context) {
    final minutes = elapsed.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = elapsed.inSeconds.remainder(60).toString().padLeft(2, '0');
    return Text(
      '$minutes:$seconds',
      style: GoogleFonts.sourceSerif4(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        fontFeatures: const [FontFeature.tabularFigures()],
        color: cs.onSurface,
      ),
    );
  }
}

class _PauseResumeButton extends StatelessWidget {
  const _PauseResumeButton({
    required this.isPaused,
    required this.cs,
    required this.ref,
  });
  final bool isPaused;
  final ColorScheme cs;
  final WidgetRef ref;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 48,
      height: 36,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: () {
            final service = ref.read(audioRecordingServiceProvider);
            if (isPaused) {
              service.resumeRecording();
            } else {
              service.pauseRecording();
            }
          },
          child: Center(
            child: PhosphorIcon(
              isPaused ? StarNoteIcons.play : StarNoteIcons.pause,
              size: 18,
              color: cs.onSurface,
            ),
          ),
        ),
      ),
    );
  }
}

class _StopButton extends StatelessWidget {
  const _StopButton({
    required this.cs,
    required this.ref,
    required this.elapsed,
  });
  final ColorScheme cs;
  final WidgetRef ref;
  final Duration elapsed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 48,
      height: 36,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: () => _handleStop(),
          child: Center(
            child: Container(
              width: 16,
              height: 16,
              decoration: BoxDecoration(
                color: cs.error,
                borderRadius: BorderRadius.circular(3),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _handleStop() async {
    final service = ref.read(audioRecordingServiceProvider);
    final filePath = await service.stopRecording();
    if (filePath == null) return;

    final docNotifier = ref.read(documentProvider.notifier);
    final pageIndex = ref.read(currentPageIndexProvider);
    final count = ref.read(audioRecordingCountProvider);

    final recording = AudioRecording.create(
      title: 'Kayit ${count + 1}',
      pageIndex: pageIndex,
    ).copyWith(filePath: filePath, duration: elapsed);

    addRecording(docNotifier, recording);

    // Open sidebar with recordings tab
    ref.read(sidebarFilterProvider.notifier).state = SidebarFilter.recordings;
    ref.read(sidebarOpenProvider.notifier).state = true;
  }
}
