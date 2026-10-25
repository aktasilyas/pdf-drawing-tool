/// ElyaNotes Documents Header - title, search, sort/view/select and "Yeni".
///
/// Layout depends on the content pane width: `wide` (>= 720) is one row,
/// `compact` is two rows (docs/specs/51-library-screen.md §3).
library;

import 'package:drawing_ui/drawing_ui.dart' show ElyanotesIcons;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:example_app/core/theme/index.dart';
import 'package:example_app/core/widgets/index.dart';
import 'package:example_app/features/documents/domain/entities/sort_option.dart';
import 'package:example_app/features/documents/presentation/providers/documents_provider.dart';
import 'package:example_app/features/documents/presentation/widgets/library_header_parts.dart';
import 'package:example_app/features/documents/presentation/widgets/selection_mode_header.dart';
import 'package:example_app/features/premium/premium.dart';

class DocumentsHeader extends ConsumerWidget {
  /// Pane width from which the one-row layout is used.
  static const double wideBreakpoint = 720;

  /// Fixed width of the search field in the wide layout.
  static const double searchWidth = 240;

  final VoidCallback onNewPressed;
  final SortOption sortOption;
  final ValueChanged<SortOption> onSortChanged;
  final GlobalKey? newButtonKey;
  final List<String> allDocumentIds;
  final List<String> allFolderIds;
  final bool isTrashSection;
  final VoidCallback? onEmptyTrash;

  /// Section title; replaced by [breadcrumb] when set.
  final String title;
  final Widget? breadcrumb;
  final VoidCallback? onSettingsTap;

  /// Phone drawer button.
  final VoidCallback? onMenuTap;

  /// Non-null only while the tablet sidebar is collapsed.
  final VoidCallback? onSidebarToggle;

  const DocumentsHeader({
    super.key,
    required this.onNewPressed,
    required this.sortOption,
    required this.onSortChanged,
    this.newButtonKey,
    this.allDocumentIds = const [],
    this.allFolderIds = const [],
    this.isTrashSection = false,
    this.onEmptyTrash,
    this.title = '',
    this.breadcrumb,
    this.onSettingsTap,
    this.onMenuTap,
    this.onSidebarToggle,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isSelectionMode = ref.watch(selectionModeProvider);
    final totalCount = ref.watch(totalDocumentCountProvider).valueOrNull ?? 0;
    final access = ref.watch(featureAccessProvider(
      FeatureAccessParams(
        feature: GatedFeature.createDocument,
        currentUsage: totalCount,
      ),
    ));

    return LayoutBuilder(
      builder: (context, constraints) {
        final wide = constraints.maxWidth >= wideBreakpoint;
        final Widget content;
        if (isSelectionMode) {
          content = Padding(
            key: const ValueKey('selection'),
            padding: wide
                ? const EdgeInsets.fromLTRB(
                    AppSpacing.xl, AppSpacing.md, AppSpacing.xl, AppSpacing.sm)
                : const EdgeInsets.fromLTRB(
                    AppSpacing.lg, AppSpacing.sm, AppSpacing.lg, AppSpacing.sm),
            child: SelectionModeHeader(
              allDocumentIds: allDocumentIds,
              allFolderIds: allFolderIds,
              isTrashSection: isTrashSection,
            ),
          );
        } else {
          content = KeyedSubtree(
            key: const ValueKey('normal'),
            child: wide
                ? _wide(context, isLocked: !access.isAllowed)
                : _compact(
                    context,
                    isLocked: !access.isAllowed,
                  ),
          );
        }
        return AnimatedSwitcher(
          duration: AppDurations.fast,
          switchInCurve: AppCurves.fade,
          switchOutCurve: AppCurves.fade,
          child: content,
        );
      },
    );
  }

  Widget _titleWidget(BuildContext context, TextStyle style) {
    return breadcrumb ??
        Text(
          title,
          style: style.copyWith(color: context.palette.textPrimary),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        );
  }

  Widget _sidebarToggle() => AppIconButton(
        icon: ElyanotesIcons.librarySidebar,
        variant: AppIconButtonVariant.ghost,
        tooltip: 'Kenar çubuğunu aç',
        onPressed: onSidebarToggle,
      );

  Widget _settings() => AppIconButton(
        icon: ElyanotesIcons.librarySettings,
        variant: AppIconButtonVariant.ghost,
        size: AppIconButtonSize.small,
        tooltip: 'Ayarlar',
        onPressed: onSettingsTap,
      );

  Widget _newButton({required bool compact, required bool isLocked}) =>
      LibraryNewButton(
        key: newButtonKey,
        compact: compact,
        isLocked: isLocked,
        onPressed: onNewPressed,
      );

  Widget _trashInfo() => Padding(
        padding: const EdgeInsets.only(bottom: AppSpacing.sm),
        child: LibraryTrashInfo(
          onEmptyTrash: allDocumentIds.isNotEmpty ? onEmptyTrash : null,
        ),
      );

  Widget _wide(BuildContext context, {required bool isLocked}) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.xl,
        AppSpacing.md,
        AppSpacing.xl,
        AppSpacing.lg - AppSpacing.sm,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (isTrashSection) _trashInfo(),
          Row(
            children: [
              if (onSidebarToggle != null) _sidebarToggle(),
              Expanded(
                child: _titleWidget(context, AppTypography.displayMedium),
              ),
              const SizedBox(width: AppSpacing.lg),
              if (!isTrashSection) ...[
                const SizedBox(
                  width: searchWidth,
                  child: LibrarySearchField(),
                ),
                const SizedBox(width: AppSpacing.sm),
              ],
              LibraryViewActions(
                sortOption: sortOption,
                onSortChanged: onSortChanged,
              ),
              if (onSettingsTap != null) _settings(),
              if (!isTrashSection) ...[
                const SizedBox(width: AppSpacing.md),
                _newButton(compact: false, isLocked: isLocked),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _compact(BuildContext context, {required bool isLocked}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(
              AppSpacing.xs, AppSpacing.sm, AppSpacing.lg, 0),
          child: Row(
            children: [
              if (onMenuTap != null)
                AppIconButton(
                  icon: ElyanotesIcons.libraryMenu,
                  variant: AppIconButtonVariant.ghost,
                  tooltip: 'Menü',
                  onPressed: onMenuTap,
                ),
              if (onSidebarToggle != null) _sidebarToggle(),
              if (onMenuTap == null && onSidebarToggle == null)
                const SizedBox(width: AppSpacing.md),
              Expanded(
                child: _titleWidget(context, AppTypography.headlineLarge),
              ),
              if (onSettingsTap != null) _settings(),
              if (!isTrashSection)
                _newButton(compact: true, isLocked: isLocked),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg,
            0,
            AppSpacing.lg,
            AppSpacing.md - AppSpacing.sm,
          ),
          child: Column(
            children: [
              if (isTrashSection) _trashInfo(),
              Row(
                children: [
                  if (!isTrashSection) ...[
                    const Expanded(child: LibrarySearchField()),
                    const SizedBox(width: AppSpacing.sm),
                  ] else
                    const Spacer(),
                  LibraryViewActions(
                    sortOption: sortOption,
                    onSortChanged: onSortChanged,
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}
