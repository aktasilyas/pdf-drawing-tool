import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drawing_ui/src/l10n/l10n.dart';
import 'package:drawing_ui/src/panels/sticker_catalog.dart';
import 'package:drawing_ui/src/panels/sticker_panel_actions.dart';
import 'package:drawing_ui/src/panels/sticker_panel_parts.dart';
import 'package:drawing_ui/src/theme/theme.dart';

/// Settings panel for the sticker tool.
///
/// Displays sticker categories and a grid of stickers. Tapping a sticker
/// selects it; the add button (or a double tap) enters placement mode -
/// tap the canvas to place it.
class StickerPanel extends ConsumerStatefulWidget {
  const StickerPanel({super.key});

  @override
  ConsumerState<StickerPanel> createState() => _StickerPanelState();
}

class _StickerPanelState extends ConsumerState<StickerPanel>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  int _selectedStickerIndex = -1;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: StickerCategory.values.length,
      vsync: this,
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = context.drawingStrings;
    final cs = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final actions = ref.read(stickerPanelActionsProvider);
    return Padding(
      padding: const EdgeInsets.all(ChromeSpacing.md),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            s.catalog.stickersTitle,
            style: textTheme.bodyMedium?.copyWith(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: cs.onSurface,
            ),
          ),
          const SizedBox(height: 10),
          // Category tabs
          SizedBox(
            height: 32,
            child: TabBar(
              controller: _tabController,
              isScrollable: true,
              labelColor: cs.primary,
              unselectedLabelColor: cs.onSurfaceVariant,
              indicatorColor: cs.primary,
              indicatorSize: TabBarIndicatorSize.label,
              labelStyle: textTheme.labelSmall,
              unselectedLabelStyle: textTheme.labelSmall?.copyWith(
                fontWeight: FontWeight.normal,
              ),
              indicatorWeight: 2,
              dividerHeight: 0,
              tabs: [
                for (final cat in StickerCategory.values)
                  Tab(text: cat.label(s)),
              ],
            ),
          ),
          const SizedBox(height: 10),

          // Sticker grid
          SizedBox(
            height: 200,
            child: TabBarView(
              controller: _tabController,
              children: [
                for (final category in StickerCategory.values)
                  StickerGrid(
                    category: category,
                    selectedIndex: _selectedStickerIndex,
                    onStickerSelected: (index) {
                      setState(() => _selectedStickerIndex = index);
                    },
                    onStickerDoubleTap: actions.place,
                  ),
              ],
            ),
          ),
          const SizedBox(height: 10),

          // Insert button
          StickerActionButton(
            label: s.catalog.addSticker,
            icon: ElyanotesIcons.plus,
            enabled: _selectedStickerIndex >= 0,
            onPressed: () => actions.placeSelected(
              StickerCategory.values[_tabController.index],
              _selectedStickerIndex,
            ),
          ),
        ],
      ),
    );
  }
}
