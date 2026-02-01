/// StarNote Design System - AdaptiveNavigation Component
///
/// Responsive navigation. Phone: BottomNav, Tablet: NavigationRail.
///
/// Kullanım:
/// ```dart
/// AdaptiveNavigation(
///   selectedIndex: _currentIndex,
///   items: [
///     AdaptiveNavItem(
///       icon: Icons.home_outlined,
///       selectedIcon: Icons.home,
///       label: 'Ana Sayfa',
///     ),
///     AdaptiveNavItem(
///       icon: Icons.folder_outlined,
///       selectedIcon: Icons.folder,
///       label: 'Dokümanlar',
///     ),
///   ],
///   onItemSelected: (index) => setState(() => _currentIndex = index),
///   body: pages[_currentIndex],
/// )
/// ```
library;

import 'package:flutter/material.dart';

import 'package:example_app/core/utils/responsive.dart';
import 'package:example_app/core/theme/index.dart';

/// Navigation item modeli.
class AdaptiveNavItem {
  /// Icon (unselected state).
  final IconData icon;

  /// Selected icon (optional, defaults to icon).
  final IconData? selectedIcon;

  /// Label.
  final String label;

  const AdaptiveNavItem({
    required this.icon,
    this.selectedIcon,
    required this.label,
  });
}

/// StarNote adaptive navigation komponenti.
///
/// Phone'da BottomNavigationBar, tablet'te NavigationRail.
class AdaptiveNavigation extends StatelessWidget {
  /// Seçili index.
  final int selectedIndex;

  /// Navigation item'ları.
  final List<AdaptiveNavItem> items;

  /// Item seçildiğinde çağrılır.
  final ValueChanged<int> onItemSelected;

  /// Ana içerik.
  final Widget body;

  const AdaptiveNavigation({
    required this.selectedIndex,
    required this.items,
    required this.onItemSelected,
    required this.body,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final isPhone = Responsive.isPhone(context);

    if (isPhone) {
      return Scaffold(
        body: body,
        bottomNavigationBar: _buildBottomNav(context),
      );
    } else {
      return Scaffold(
        body: Row(
          children: [
            _buildNavigationRail(context),
            const VerticalDivider(width: 1, thickness: 1),
            Expanded(child: body),
          ],
        ),
      );
    }
  }

  Widget _buildBottomNav(BuildContext context) {
    return NavigationBar(
      selectedIndex: selectedIndex,
      onDestinationSelected: onItemSelected,
      destinations: items
          .map(
            (item) => NavigationDestination(
              icon: Icon(item.icon),
              selectedIcon: Icon(item.selectedIcon ?? item.icon),
              label: item.label,
            ),
          )
          .toList(),
    );
  }

  Widget _buildNavigationRail(BuildContext context) {
    return NavigationRail(
      selectedIndex: selectedIndex,
      onDestinationSelected: onItemSelected,
      labelType: NavigationRailLabelType.all,
      destinations: items
          .map(
            (item) => NavigationRailDestination(
              icon: Icon(item.icon, size: AppIconSize.navBar),
              selectedIcon: Icon(
                item.selectedIcon ?? item.icon,
                size: AppIconSize.navBar,
              ),
              label: Text(item.label),
            ),
          )
          .toList(),
    );
  }
}
