/// Segmented filter header of the page sidebar: all pages / bookmarks /
/// recordings (docs/specs/52-editor-chrome.md, section 4 "Page sidebar").
import 'package:flutter/material.dart';

import 'package:drawing_ui/src/l10n/l10n.dart';
import 'package:drawing_ui/src/providers/providers.dart';
import 'package:drawing_ui/src/theme/chrome_palette.dart';
import 'package:drawing_ui/src/theme/chrome_tokens.dart';
import 'package:drawing_ui/src/theme/elyanotes_icons.dart';
import 'package:drawing_ui/src/toolbar/chrome_icon_button.dart';

/// Centered segmented group of [ChromeIconButton]s (40dp visual, 48dp hit)
/// on a `background` track, above a hairline.
class PageSidebarFilterBar extends StatelessWidget {
  const PageSidebarFilterBar({
    super.key,
    required this.filter,
    required this.onFilterChanged,
    required this.showRecordings,
  });

  final SidebarFilter filter;
  final ValueChanged<SidebarFilter> onFilterChanged;

  /// Recordings tab is hidden while audio recording is frozen.
  final bool showRecordings;

  @override
  Widget build(BuildContext context) {
    final palette = ChromePalette.of(context);
    final strings = context.drawingStrings.pageList;
    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: palette.border, width: 0.5)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: ChromeSpacing.sm),
        child: Center(
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: palette.background,
              borderRadius: BorderRadius.circular(ChromeRadius.lg),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _tab(
                  SidebarFilter.allPages,
                  ElyanotesIcons.gridOn,
                  ElyanotesIcons.gridOnActive,
                  strings.filterAllPages,
                ),
                _tab(
                  SidebarFilter.bookmarked,
                  ElyanotesIcons.bookmark,
                  ElyanotesIcons.bookmarkFilled,
                  strings.filterBookmarks,
                ),
                if (showRecordings)
                  _tab(
                    SidebarFilter.recordings,
                    ElyanotesIcons.waveform,
                    ElyanotesIcons.waveformActive,
                    strings.filterRecordings,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _tab(
    SidebarFilter value,
    IconData icon,
    IconData selectedIcon,
    String tooltip,
  ) {
    return ChromeIconButton(
      icon: icon,
      selectedIcon: selectedIcon,
      tooltip: tooltip,
      selected: filter == value,
      iconSize: ChromeIconSizes.md,
      onPressed: () => onFilterChanged(value),
    );
  }
}
