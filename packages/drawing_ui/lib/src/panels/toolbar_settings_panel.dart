import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:drawing_ui/src/providers/providers.dart';
import 'package:drawing_ui/src/theme/theme.dart';
import 'package:drawing_ui/src/widgets/reorderable_tool_list.dart';

/// Panel for customizing toolbar appearance and tool order.
///
/// Two tabs: "Araçlar" (reorderable drawing tools) and
/// "Ek Araçlar" (reorderable extra tools like ruler, audio).
class ToolbarSettingsPanel extends ConsumerStatefulWidget {
  const ToolbarSettingsPanel({super.key});

  @override
  ConsumerState<ToolbarSettingsPanel> createState() =>
      _ToolbarSettingsPanelState();
}

class _ToolbarSettingsPanelState extends ConsumerState<ToolbarSettingsPanel>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final screenHeight = MediaQuery.of(context).size.height;
    final maxHeight = (screenHeight * 0.8).clamp(480.0, 720.0);

    return Container(
      width: 340,
      constraints: BoxConstraints(maxHeight: maxHeight),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildHeader(cs),
          Divider(height: 1, color: cs.outlineVariant.withValues(alpha: 0.5)),
          _buildTabBar(cs),
          Expanded(child: _buildTabContent()),
          const SizedBox(height: 8),
          _buildResetButton(cs),
          const SizedBox(height: 12),
        ],
      ),
    );
  }

  Widget _buildHeader(ColorScheme cs) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 8, 10),
      child: Row(
        children: [
          Container(
            width: 26,
            height: 26,
            decoration: BoxDecoration(
              color: cs.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Icon(
              StarNoteIcons.settings,
              size: 14,
              color: cs.primary,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Araç Çubuğu Ayarları',
              style: GoogleFonts.sourceSerif4(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: cs.onSurface,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          IconButton(
            icon: PhosphorIcon(
              StarNoteIcons.close,
              size: 16,
              color: cs.onSurfaceVariant,
            ),
            onPressed: () => Navigator.of(context).pop(),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
            splashRadius: 16,
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar(ColorScheme cs) {
    return TabBar(
      controller: _tabController,
      labelColor: cs.primary,
      unselectedLabelColor: cs.onSurfaceVariant,
      labelStyle: GoogleFonts.sourceSerif4(fontSize: 13, fontWeight: FontWeight.w600),
      unselectedLabelStyle:
          GoogleFonts.sourceSerif4(fontSize: 13, fontWeight: FontWeight.w400),
      indicatorSize: TabBarIndicatorSize.tab,
      indicatorWeight: 2,
      dividerHeight: 0.5,
      dividerColor: cs.outlineVariant.withValues(alpha: 0.5),
      tabs: const [
        Tab(height: 36, text: 'Araçlar'),
        Tab(height: 36, text: 'Ek Araçlar'),
      ],
    );
  }

  Widget _buildTabContent() {
    return TabBarView(
      controller: _tabController,
      children: [
        _buildToolsTab(),
        _buildExtraToolsTab(),
      ],
    );
  }

  Widget _buildToolsTab() {
    final cs = Theme.of(context).colorScheme;
    return Column(
      children: [
        const SizedBox(height: 6),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              Flexible(
                child: Text(
                  'Araçları sıralayın ve gizleyin',
                  style: GoogleFonts.sourceSerif4(fontSize: 11, color: cs.onSurfaceVariant),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const Spacer(),
              PhosphorIcon(
                StarNoteIcons.dragHandle,
                size: 12,
                color: cs.onSurfaceVariant,
              ),
            ],
          ),
        ),
        const SizedBox(height: 4),
        const Expanded(child: ReorderableToolList()),
      ],
    );
  }

  Widget _buildExtraToolsTab() {
    final cs = Theme.of(context).colorScheme;
    return Column(
      children: [
        const SizedBox(height: 6),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              Flexible(
                child: Text(
                  'Ek araçları sıralayın ve gizleyin',
                  style: GoogleFonts.sourceSerif4(fontSize: 11, color: cs.onSurfaceVariant),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const Spacer(),
              PhosphorIcon(
                StarNoteIcons.dragHandle,
                size: 12,
                color: cs.onSurfaceVariant,
              ),
            ],
          ),
        ),
        const SizedBox(height: 4),
        const Expanded(child: ReorderableExtraToolList()),
      ],
    );
  }

  Widget _buildResetButton(ColorScheme cs) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: SizedBox(
        width: double.infinity,
        height: 34,
        child: OutlinedButton.icon(
          onPressed: () {
            ref.read(toolbarConfigProvider.notifier).resetToDefault();
          },
          icon: PhosphorIcon(StarNoteIcons.rotate, size: 13),
          label: Text(
            'Varsayılana Sıfırla',
            style: GoogleFonts.sourceSerif4(fontSize: 12),
          ),
          style: OutlinedButton.styleFrom(
            foregroundColor: cs.onSurfaceVariant,
            side: BorderSide(color: cs.outline.withValues(alpha: 0.3)),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 12),
          ),
        ),
      ),
    );
  }
}
