import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphor_icons/phosphor_icons.dart';
import 'package:drawing_ui/src/l10n/l10n.dart';
import 'package:drawing_ui/src/providers/providers.dart';
import 'package:drawing_ui/src/theme/drawing_shadows.dart';
import 'package:drawing_ui/src/theme/elyanotes_icons.dart';
import 'package:drawing_ui/src/widgets/go_to_page_dialog.dart';

/// Compact floating page indicator bar shown below the canvas.
///
/// Displays current page number, total pages, and navigation arrows.
/// Hidden for single-page documents. Auto-hides after 3 seconds.
class PageIndicatorBar extends ConsumerStatefulWidget {
  const PageIndicatorBar(
      {super.key,
      this.autoHideDuration = const Duration(seconds: 3),
      this.onPageChanged});
  final Duration autoHideDuration;
  final ValueChanged<int>? onPageChanged;

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
    _fade = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 300), value: 1.0);
    _scheduleHide();
  }

  @override
  void dispose() {
    _hideTimer?.cancel();
    _fade.dispose();
    super.dispose();
  }

  void _scheduleHide() {
    _hideTimer?.cancel();
    _hideTimer = Timer(widget.autoHideDuration, () {
      if (mounted) _fade.reverse();
    });
  }

  void _showBar() {
    if (_fade.isDismissed || _fade.status == AnimationStatus.reverse)
      _fade.forward();
    _scheduleHide();
  }

  @override
  Widget build(BuildContext context) {
    final pageCount = ref.watch(pageCountProvider);
    final currentIndex = ref.watch(currentPageIndexProvider);
    final canPrev = ref.watch(canGoPreviousProvider);
    final canNext = ref.watch(canGoNextProvider);
    final scrollDir = ref.watch(scrollDirectionProvider);
    final isDual = ref.watch(dualPageModeProvider);
    final cs = Theme.of(context).colorScheme;
    final strings = context.drawingStrings;
    ref.listen<int>(currentPageIndexProvider, (_, __) => _showBar());
    if (pageCount <= 1) return const SizedBox.shrink();

    // Dual mode label: "Pages X-Y of N", single: "Page X of N"
    final String pageLabel;
    if (isDual && currentIndex + 1 < pageCount) {
      pageLabel = strings.pageList
          .pageRangeOf(currentIndex + 1, currentIndex + 2, pageCount);
    } else {
      pageLabel = strings.pageList.pageOf(currentIndex + 1, pageCount);
    }

    // In dual mode: can go next if there are 2+ pages beyond current
    final bool effectiveCanNext =
        isDual ? currentIndex + 2 < pageCount : canNext;

    return GestureDetector(
      onTap: _showBar,
      child: FadeTransition(
        opacity: _fade,
        child: Container(
          height: 48,
          margin: const EdgeInsets.only(bottom: 8),
          child: Center(
              child: Container(
            // No vertical padding: the 48dp pill keeps 48dp hit targets.
            padding: const EdgeInsets.symmetric(horizontal: 4),
            decoration: BoxDecoration(
              color: cs.surfaceContainerHigh.withValues(alpha: 0.92),
              borderRadius: BorderRadius.circular(20),
              boxShadow: DrawingShadows.toolbar(Theme.of(context).brightness),
            ),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              _NavArrow(
                  icon: scrollDir == Axis.horizontal
                      ? ElyanotesIcons.chevronLeft
                      : ElyanotesIcons.caretUp,
                  tooltip: strings.pageList.previousPage,
                  onTap: canPrev
                      ? () {
                          _navigateTo(
                              isDual
                                  ? (currentIndex - 2).clamp(0, pageCount - 1)
                                  : currentIndex - 1,
                              ref);
                        }
                      : null),
              Tooltip(
                message: strings.pages.goToPage,
                child: Semantics(
                  label: strings.pageList.goToPageHint(pageLabel),
                  button: true,
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () => _showGoToPageDialog(context, ref, pageCount),
                    // Full-height hit area: 48dp like the arrows beside it.
                    child: Container(
                      height: 48,
                      alignment: Alignment.center,
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: Text(pageLabel,
                          style: Theme.of(context)
                              .textTheme
                              .bodySmall
                              ?.copyWith(fontSize: 13, color: cs.onSurface)),
                    ),
                  ),
                ),
              ),
              _NavArrow(
                  icon: scrollDir == Axis.horizontal
                      ? ElyanotesIcons.chevronRight
                      : ElyanotesIcons.caretDown,
                  tooltip: strings.pageList.nextPage,
                  onTap: effectiveCanNext
                      ? () {
                          _navigateTo(
                              isDual
                                  ? (currentIndex + 2).clamp(0, pageCount - 1)
                                  : currentIndex + 1,
                              ref);
                        }
                      : null),
            ]),
          )),
        ),
      ),
    );
  }

  void _navigateTo(int index, WidgetRef ref) {
    if (widget.onPageChanged != null) {
      widget.onPageChanged!(index);
    } else {
      ref.read(pageManagerProvider.notifier).goToPage(index);
    }
    _showBar();
  }

  Future<void> _showGoToPageDialog(
      BuildContext context, WidgetRef ref, int pageCount) async {
    final index = await pickGoToPageIndex(context, pageCount: pageCount);
    if (index != null && mounted) _navigateTo(index, ref);
  }
}

/// Small circular navigation arrow for page indicator.
class _NavArrow extends StatelessWidget {
  const _NavArrow(
      {required this.icon, required this.onTap, required this.tooltip});
  final PhosphorIconData icon;
  final VoidCallback? onTap;
  final String tooltip;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Tooltip(
      message: tooltip,
      child: Semantics(
        label: tooltip,
        button: true,
        enabled: onTap != null,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(24),
            child: SizedBox(
                width: 48,
                height: 48,
                child: Center(
                  child: PhosphorIcon(icon,
                      size: 16,
                      color: onTap != null
                          ? cs.onSurface
                          : cs.onSurface.withValues(alpha: 0.25)),
                )),
          ),
        ),
      ),
    );
  }
}
