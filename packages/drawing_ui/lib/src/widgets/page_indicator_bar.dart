import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:drawing_ui/src/providers/providers.dart';
import 'package:drawing_ui/src/theme/starnote_icons.dart';

/// Compact floating page indicator bar shown below the canvas.
///
/// Displays current page number, total pages, and navigation arrows.
/// Hidden for single-page documents. Auto-hides after 3 seconds.
class PageIndicatorBar extends ConsumerStatefulWidget {
  const PageIndicatorBar({super.key, this.autoHideDuration = const Duration(seconds: 3)});
  final Duration autoHideDuration;

  @override
  ConsumerState<PageIndicatorBar> createState() => _PageIndicatorBarState();
}

class _PageIndicatorBarState extends ConsumerState<PageIndicatorBar>
    with SingleTickerProviderStateMixin {
  late final AnimationController _fade;
  Timer? _hideTimer;

  @override
  void initState() {
    super.initState();
    _fade = AnimationController(vsync: this, duration: const Duration(milliseconds: 300), value: 1.0);
    _scheduleHide();
  }

  @override
  void dispose() { _hideTimer?.cancel(); _fade.dispose(); super.dispose(); }

  void _scheduleHide() {
    _hideTimer?.cancel();
    _hideTimer = Timer(widget.autoHideDuration, () { if (mounted) _fade.reverse(); });
  }

  void _showBar() {
    if (_fade.isDismissed || _fade.status == AnimationStatus.reverse) _fade.forward();
    _scheduleHide();
  }

  @override
  Widget build(BuildContext context) {
    final pageCount = ref.watch(pageCountProvider);
    final currentIndex = ref.watch(currentPageIndexProvider);
    final canPrev = ref.watch(canGoPreviousProvider);
    final canNext = ref.watch(canGoNextProvider);
    final cs = Theme.of(context).colorScheme;
    ref.listen<int>(currentPageIndexProvider, (_, __) => _showBar());
    if (pageCount <= 1) return const SizedBox.shrink();

    return GestureDetector(
      onTap: _showBar,
      child: FadeTransition(
        opacity: _fade,
        child: Container(
          height: 36,
          margin: const EdgeInsets.only(bottom: 8),
          child: Center(child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
            decoration: BoxDecoration(
              color: cs.surfaceContainerHigh.withValues(alpha: 0.92),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 8, offset: const Offset(0, 2))],
            ),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              _NavArrow(icon: StarNoteIcons.chevronLeft, onTap: canPrev ? () { ref.read(pageManagerProvider.notifier).previousPage(); _showBar(); } : null),
              GestureDetector(
                onTap: () => _showGoToPageDialog(context, ref, pageCount),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Text('Sayfa ${currentIndex + 1} / $pageCount',
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: cs.onSurface)),
                ),
              ),
              _NavArrow(icon: StarNoteIcons.chevronRight, onTap: canNext ? () { ref.read(pageManagerProvider.notifier).nextPage(); _showBar(); } : null),
            ]),
          )),
        ),
      ),
    );
  }

  void _showGoToPageDialog(BuildContext context, WidgetRef ref, int pageCount) {
    final controller = TextEditingController();
    showDialog(context: context, builder: (ctx) => AlertDialog(
      title: const Text('Sayfaya Git'),
      content: TextField(
        controller: controller, keyboardType: TextInputType.number, autofocus: true,
        decoration: InputDecoration(hintText: '1 - $pageCount', border: const OutlineInputBorder()),
        onSubmitted: (v) { _goTo(v, pageCount, ref, ctx); },
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx), child: Text('Iptal', style: TextStyle(color: Theme.of(ctx).colorScheme.onSurfaceVariant))),
        FilledButton(onPressed: () { _goTo(controller.text, pageCount, ref, ctx); }, child: const Text('Git')),
      ],
    ));
  }

  void _goTo(String value, int pageCount, WidgetRef ref, BuildContext ctx) {
    final page = int.tryParse(value);
    if (page != null && page >= 1 && page <= pageCount) {
      ref.read(pageManagerProvider.notifier).goToPage(page - 1);
      Navigator.pop(ctx);
    }
  }
}

/// Small circular navigation arrow for page indicator.
class _NavArrow extends StatelessWidget {
  const _NavArrow({required this.icon, required this.onTap});
  final PhosphorIconData icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap, borderRadius: BorderRadius.circular(14),
        child: SizedBox(width: 28, height: 28, child: Center(
          child: PhosphorIcon(icon, size: 16, color: onTap != null ? cs.onSurface : cs.onSurface.withValues(alpha: 0.25)),
        )),
      ),
    );
  }
}
