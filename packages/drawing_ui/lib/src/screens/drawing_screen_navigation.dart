import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drawing_core/drawing_core.dart' as core;
import 'package:drawing_ui/src/l10n/l10n.dart';
import 'package:drawing_ui/src/providers/providers.dart';
import 'package:drawing_ui/src/canvas/page_slide_transition.dart';
import 'package:drawing_ui/src/panels/page_structure_undo.dart';
import 'package:drawing_ui/src/screens/drawing_screen.dart';

/// Page navigation, swipe handling and "add page by swiping" for
/// [DrawingScreen]'s state.
mixin DrawingScreenNavigation on ConsumerState<DrawingScreen> {
  final GlobalKey<PageSlideTransitionState> pageTransitionKey =
      GlobalKey<PageSlideTransitionState>();
  bool _isPageTransitioning = false;
  int? _preSwitchPageIndex; // Original page index before interactive pre-switch

  Future<void> navigateToPage(int targetIndex) async {
    final currentIndex = ref.read(currentPageIndexProvider);
    if (targetIndex == currentIndex || _isPageTransitioning) return;

    _isPageTransitioning = true;
    try {
      final forward = targetIndex > currentIndex;
      await pageTransitionKey.currentState?.captureSnapshot(forward: forward);
      ref.read(pageManagerProvider.notifier).goToPage(targetIndex);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        pageTransitionKey.currentState?.startAnimation();
        _isPageTransitioning = false;
      });
    } catch (_) {
      _isPageTransitioning = false;
    }
  }

  /// Called when drag direction is determined. Pre-switches the page so the
  /// live child renders the target page. Returns true if pre-switch happened.
  bool onDragDirectionDetermined(int direction) {
    final currentIdx = ref.read(currentPageIndexProvider);
    final count = ref.read(pageCountProvider);
    final targetIdx = currentIdx + direction;
    if (targetIdx >= 0 && targetIdx < count) {
      _preSwitchPageIndex = currentIdx;
      ref.read(pageManagerProvider.notifier).goToPage(targetIdx);
      return true;
    }
    return false; // Last page forward — can't pre-switch
  }

  /// Called when a pre-switched drag is cancelled. Reverts to original page.
  void onDragReverted() {
    if (_preSwitchPageIndex != null) {
      ref.read(pageManagerProvider.notifier).goToPage(_preSwitchPageIndex!);
      _preSwitchPageIndex = null;
    }
  }

  /// Called when interactive swipe completes (only for non-pre-switched cases).
  void handleSwipeNavigate(int direction) {
    if (_preSwitchPageIndex != null) {
      // Page was already pre-switched — just clear saved index
      _preSwitchPageIndex = null;
      return;
    }
    // Not pre-switched (e.g., last page forward) — handle normally
    final currentIndex = ref.read(currentPageIndexProvider);
    if (direction == 1) {
      final count = ref.read(pageCountProvider);
      if (currentIndex < count - 1) {
        ref.read(pageManagerProvider.notifier).goToPage(currentIndex + 1);
      } else {
        _addPageAfterLast();
      }
    } else if (direction == -1) {
      if (currentIndex > 0) {
        ref.read(pageManagerProvider.notifier).goToPage(currentIndex - 1);
      }
    }
  }

  /// Resolves the background for a new page added by swipe.
  /// If the current page is a built-in template, reuse it.
  /// Otherwise (PDF, cover, etc.) fall back to thin_lined template.
  core.PageBackground resolveNewPageBackground() {
    final bg = ref.read(currentPageProvider).background;
    switch (bg.type) {
      case core.BackgroundType.template:
      case core.BackgroundType.blank:
      case core.BackgroundType.grid:
      case core.BackgroundType.lined:
      case core.BackgroundType.dotted:
        return bg;
      case core.BackgroundType.pdf:
      case core.BackgroundType.cover:
        final t = core.TemplateRegistry.getById('thin_lined')!;
        return core.PageBackground.fromTemplate(t);
    }
  }

  /// Adds a new page after the last page and offers undo.
  void _addPageAfterLast() {
    final doc = ref.read(documentProvider);
    final actions = ref.read(pageStructureActionsProvider);
    final change = actions.insertPage(
      doc.pages.length,
      core.Page.create(
        index: doc.pages.length,
        size: doc.settings.defaultPageSize,
        background: resolveNewPageBackground(),
      ),
    );
    final strings = context.drawingStrings;
    showPageUndoSnackBar(
      ScaffoldMessenger.maybeOf(context),
      actions,
      change,
      strings.pages.pageAdded,
      undoLabel: strings.toolbar.undo,
    );
  }

  /// Returns the background color of the page at offset from current.
  /// offset: 1 for next page, -1 for previous page.
  Color? adjacentPageColor(int offset) {
    final pages = ref.read(pagesProvider);
    final currentIndex = ref.read(currentPageIndexProvider);
    final targetIndex = currentIndex + offset;
    if (targetIndex >= 0 && targetIndex < pages.length) {
      return Color(pages[targetIndex].background.color);
    }
    // For "add page after last", show same background as current page
    if (offset > 0) {
      return Color(pages[currentIndex].background.color);
    }
    return null;
  }
}
