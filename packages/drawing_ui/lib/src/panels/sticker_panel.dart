import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'tool_panel.dart';

/// MOCK sticker categories for UI display - Turkish.
const _mockStickerCategories = [
  'Emoji',
  'Hayvanlar',
  'Yiyecek',
  'Seyahat',
  'Nesneler',
  'Semboller',
];

/// Settings panel for the sticker tool.
///
/// Displays sticker categories and a grid of stickers.
/// All interactions are MOCKED - no real sticker insertion.
class StickerPanel extends ConsumerStatefulWidget {
  const StickerPanel({
    super.key,
    this.onClose,
  });

  /// Callback when panel is closed.
  final VoidCallback? onClose;

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
      length: _mockStickerCategories.length,
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
    return ToolPanel(
      title: 'Çıkartmalar',
      onClose: widget.onClose,
      width: 320,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Category tabs - compact
          SizedBox(
            height: 32,
            child: TabBar(
              controller: _tabController,
              isScrollable: true,
              labelColor: const Color(0xFF4A9DFF),
              unselectedLabelColor: Colors.grey,
              indicatorSize: TabBarIndicatorSize.label,
              labelStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500),
              unselectedLabelStyle: const TextStyle(fontSize: 11),
              indicatorWeight: 2,
              tabs: _mockStickerCategories.map((cat) => Tab(text: cat)).toList(),
            ),
          ),
          const SizedBox(height: 10),

          // Sticker grid - compact
          SizedBox(
            height: 160,
            child: TabBarView(
              controller: _tabController,
              children: _mockStickerCategories.map((category) {
                return _StickerGrid(
                  category: category,
                  selectedIndex: _selectedStickerIndex,
                  onStickerSelected: (index) {
                    setState(() {
                      _selectedStickerIndex = index;
                    });
                  },
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 10),

          // Premium stickers section (locked) - compact
          _CompactLockedSection(
            title: 'Premium Çıkartmalar',
            onTap: () => _showPremiumPrompt(context),
          ),
          const SizedBox(height: 10),

          // Insert button - compact
          _CompactActionButton(
            label: 'Çıkartma Ekle',
            icon: Icons.add,
            enabled: _selectedStickerIndex >= 0,
            onPressed: () {
              // MOCK: Would insert sticker
              widget.onClose?.call();
            },
          ),
        ],
      ),
    );
  }

  void _showPremiumPrompt(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Premium çıkartmalar için abonelik gerekli'),
        duration: Duration(seconds: 2),
      ),
    );
  }
}

/// Compact locked section
class _CompactLockedSection extends StatelessWidget {
  const _CompactLockedSection({
    required this.title,
    required this.onTap,
  });

  final String title;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Row(
          children: [
            const Icon(Icons.lock, size: 14, color: Colors.orange),
            const SizedBox(width: 6),
            Text(
              title,
              style: const TextStyle(
                fontSize: 11,
                color: Color(0xFF666666),
              ),
            ),
            const Spacer(),
            const Icon(Icons.chevron_right, size: 16, color: Color(0xFF999999)),
          ],
        ),
      ),
    );
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
    final color = enabled ? const Color(0xFF4A9DFF) : Colors.grey;
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

/// Grid of stickers for a category - compact.
class _StickerGrid extends StatelessWidget {
  const _StickerGrid({
    required this.category,
    required this.selectedIndex,
    required this.onStickerSelected,
  });

  final String category;
  final int selectedIndex;
  final ValueChanged<int> onStickerSelected;

  @override
  Widget build(BuildContext context) {
    // MOCK: Generate placeholder stickers based on category
    final stickers = _getMockStickersForCategory(category);

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
          child: Container(
            decoration: BoxDecoration(
              color: isSelected ? const Color(0xFF4A9DFF).withValues(alpha: 0.1) : Colors.grey.shade100,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(
                color: isSelected ? const Color(0xFF4A9DFF) : Colors.grey.shade300,
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

  List<String> _getMockStickersForCategory(String category) {
    switch (category) {
      case 'Emoji':
        return ['😀', '😂', '🥰', '😎', '🤔', '😊', '🙂', '😇', '🤩', '😋', '😜', '🤗'];
      case 'Hayvanlar':
        return ['🐶', '🐱', '🐭', '🐹', '🐰', '🦊', '🐻', '🐼', '🐨', '🐯', '🦁', '🐮'];
      case 'Yiyecek':
        return ['🍎', '🍕', '🍔', '🌮', '🍣', '🍩', '🍪', '🎂', '🍦', '🍫', '☕', '🧁'];
      case 'Seyahat':
        return ['✈️', '🚗', '🚀', '⛵', '🏖️', '🗽', '🏔️', '🌍', '🏰', '🎡', '⛺', '🏝️'];
      case 'Nesneler':
        return ['📱', '💻', '📷', '🎮', '🎧', '📚', '✏️', '🔑', '💡', '⌚', '🎁', '🎈'];
      case 'Semboller':
        return ['❤️', '⭐', '✨', '💫', '🔥', '💯', '✅', '❌', '⚡', '💪', '👍', '🎉'];
      default:
        return ['❓'];
    }
  }
}
