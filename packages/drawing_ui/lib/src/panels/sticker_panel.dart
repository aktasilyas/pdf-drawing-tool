import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drawing_ui/src/theme/theme.dart';
import 'package:drawing_ui/src/providers/providers.dart';

/// Sticker categories.
const _stickerCategories = [
  'Emoji',
  'Hayvanlar',
  'Yiyecek',
  'Seyahat',
  'Nesneler',
  'Semboller',
  'Eller',
  'Doğa',
];

/// Returns sticker list for a given category.
List<String> _getStickersForCategory(String category) {
  switch (category) {
    case 'Emoji':
      return [
        '😀', '😃', '😄', '😁', '😂', '🤣', '😊', '😇',
        '🥰', '😍', '🤩', '😘', '😋', '😜', '🤪', '😎',
        '🤔', '🤨', '😏', '😌', '🥳', '🤗', '🫡', '🫠',
      ];
    case 'Hayvanlar':
      return [
        '🐶', '🐱', '🐭', '🐹', '🐰', '🦊', '🐻', '🐼',
        '🐨', '🐯', '🦁', '🐮', '🐷', '🐸', '🐵', '🐔',
        '🦄', '🐝', '🦋', '🐢', '🐙', '🦀', '🐬', '🦅',
      ];
    case 'Yiyecek':
      return [
        '🍎', '🍊', '🍋', '🍇', '🍓', '🍑', '🍕', '🍔',
        '🌮', '🌯', '🍣', '🍱', '🍩', '🍪', '🎂', '🍰',
        '🍦', '🍫', '☕', '🧁', '🥐', '🥗', '🍿', '🧃',
      ];
    case 'Seyahat':
      return [
        '✈️', '🚗', '🚀', '⛵', '🏖️', '🗽', '🏔️', '🌍',
        '🏰', '🎡', '⛺', '🏝️', '🗼', '🌋', '🏕️', '🚂',
        '🚁', '⛷️', '🏄', '🎢', '🚢', '🛸', '🌅', '🗺️',
      ];
    case 'Nesneler':
      return [
        '📱', '💻', '📷', '🎮', '🎧', '📚', '✏️', '🔑',
        '💡', '⌚', '🎁', '🎈', '🔔', '📌', '🎯', '🏆',
        '🎪', '🎭', '🎬', '🎤', '🎸', '🎹', '🔬', '🔭',
      ];
    case 'Semboller':
      return [
        '❤️', '🧡', '💛', '💚', '💙', '💜', '🤎', '🖤',
        '⭐', '✨', '💫', '🔥', '💯', '✅', '❌', '⚡',
        '💪', '👍', '🎉', '🎊', '♻️', '💎', '🏳️‍🌈', '☮️',
      ];
    case 'Eller':
      return [
        '👋', '🤚', '✋', '🖖', '👌', '🤌', '🤏', '✌️',
        '🤞', '🫰', '🤟', '🤙', '👈', '👉', '👆', '👇',
        '☝️', '👍', '👎', '👏', '🙌', '🫶', '🤝', '🙏',
      ];
    case 'Doğa':
      return [
        '🌸', '🌺', '🌻', '🌹', '🌷', '🪻', '💐', '🌿',
        '🍀', '🍁', '🍂', '🌴', '🌵', '🌊', '☀️', '🌙',
        '⭐', '🌈', '☁️', '❄️', '💧', '🌪️', '🔥', '🍃',
      ];
    default:
      return ['❓'];
  }
}

/// Settings panel for the sticker tool.
///
/// Displays sticker categories and a grid of stickers.
/// Selecting a sticker enters placement mode - tap the canvas to place it.
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
      length: _stickerCategories.length,
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
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Çıkartmalar', style: TextStyle(
            fontSize: 15, fontWeight: FontWeight.w600, color: cs.onSurface)),
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
              labelStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500),
              unselectedLabelStyle: const TextStyle(fontSize: 11),
              indicatorWeight: 2,
              dividerHeight: 0,
              tabs: _stickerCategories.map((cat) => Tab(text: cat)).toList(),
            ),
          ),
          const SizedBox(height: 10),

          // Sticker grid
          SizedBox(
            height: 200,
            child: TabBarView(
              controller: _tabController,
              children: _stickerCategories.map((category) {
                return _StickerGrid(
                  category: category,
                  selectedIndex: _selectedStickerIndex,
                  onStickerSelected: (index) {
                    setState(() => _selectedStickerIndex = index);
                  },
                  onStickerDoubleTap: (emoji) {
                    ref.read(stickerPlacementProvider.notifier).selectEmoji(emoji);
                    ref.read(activePanelProvider.notifier).state = null;
                  },
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 10),

          // Insert button
          _CompactActionButton(
            label: 'Çıkartma Ekle',
            icon: StarNoteIcons.plus,
            enabled: _selectedStickerIndex >= 0,
            onPressed: () {
              final emoji = _getSelectedEmoji();
              if (emoji == null) return;
              ref.read(stickerPlacementProvider.notifier).selectEmoji(emoji);
              ref.read(activePanelProvider.notifier).state = null;
            },
          ),
        ],
      ),
    );
  }

  String? _getSelectedEmoji() {
    if (_selectedStickerIndex < 0) return null;
    final category = _stickerCategories[_tabController.index];
    final stickers = _getStickersForCategory(category);
    if (_selectedStickerIndex >= stickers.length) return null;
    return stickers[_selectedStickerIndex];
  }
}

/// Compact action button
class _CompactActionButton extends StatelessWidget {
  const _CompactActionButton({
    required this.label,
    required this.icon,
    required this.onPressed,
    this.enabled = true,
  });

  final String label;
  final IconData icon;
  final VoidCallback onPressed;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final color = enabled ? cs.primary : cs.onSurfaceVariant;
    return InkWell(
      onTap: enabled ? onPressed : null,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: color.withValues(alpha: enabled ? 0.1 : 0.05),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 16, color: color),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Grid of stickers for a category.
class _StickerGrid extends StatelessWidget {
  const _StickerGrid({
    required this.category,
    required this.selectedIndex,
    required this.onStickerSelected,
    this.onStickerDoubleTap,
  });

  final String category;
  final int selectedIndex;
  final ValueChanged<int> onStickerSelected;
  final ValueChanged<String>? onStickerDoubleTap;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final stickers = _getStickersForCategory(category);

    return GridView.builder(
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 6,
        mainAxisSpacing: 4,
        crossAxisSpacing: 4,
      ),
      itemCount: stickers.length,
      itemBuilder: (context, index) {
        final isSelected = index == selectedIndex;
        return GestureDetector(
          onTap: () => onStickerSelected(index),
          onDoubleTap: () => onStickerDoubleTap?.call(stickers[index]),
          child: Container(
            decoration: BoxDecoration(
              color: isSelected
                  ? cs.primary.withValues(alpha: 0.12)
                  : cs.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(
                color: isSelected ? cs.primary : cs.outlineVariant,
                width: isSelected ? 1.5 : 1,
              ),
            ),
            child: Center(
              child: Text(
                stickers[index],
                style: const TextStyle(fontSize: 18),
              ),
            ),
          ),
        );
      },
    );
  }
}
