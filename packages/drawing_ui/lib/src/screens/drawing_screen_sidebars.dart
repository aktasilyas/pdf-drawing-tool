/// Side panels of the drawing screen: docked panels on tablets, sliding
/// drawers on phones. Each builder returns children for the screen's layout.
import 'package:flutter/material.dart';
import 'package:drawing_ui/src/screens/drawing_screen_overlays.dart';
import 'package:drawing_ui/src/screens/page_sidebar.dart';
import 'package:drawing_ui/src/services/thumbnail_cache.dart';

/// Tablet: the external left sidebar (e.g. AI chat) and the page sidebar,
/// docked to the left of the canvas inside the content row.
List<Widget> buildTabletSidePanels({
  required Widget? externalLeftSidebar,
  required bool isExternalLeftSidebarOpen,
  required double externalLeftSidebarWidth,
  required bool showPageSidebar,
  required ThumbnailCache thumbnailCache,
  required ValueChanged<int> onPageTap,
}) {
  return [
    if (externalLeftSidebar != null)
      CollapsibleSidePanel(
        width: isExternalLeftSidebarOpen ? externalLeftSidebarWidth : 0.0,
        contentWidth: externalLeftSidebarWidth,
        child: externalLeftSidebar,
      ),
    CollapsibleSidePanel(
      width: showPageSidebar ? kPageSidebarWidth : 0.0,
      contentWidth: kPageSidebarWidth,
      child: PageSidebar(
        thumbnailCache: thumbnailCache,
        onPageTap: onPageTap,
      ),
    ),
  ];
}

/// Phone: scrims and sliding drawers for the external left sidebar and the
/// page sidebar, stacked over the screen.
List<Widget> buildPhoneDrawers({
  required Widget? externalLeftSidebar,
  required bool isExternalLeftSidebarOpen,
  required double externalLeftSidebarWidth,
  required VoidCallback? onExternalLeftSidebarClose,
  required bool showPageSidebar,
  required double screenWidth,
  required VoidCallback onClosePageSidebar,
  required ThumbnailCache thumbnailCache,
  required ValueChanged<int> onPageTap,
}) {
  // Page drawer: min(280, 85% of the screen).
  final drawerWidth = (screenWidth * 0.85).clamp(0.0, 280.0);
  return [
    if (externalLeftSidebar != null && isExternalLeftSidebarOpen)
      DrawerScrim(onTap: onExternalLeftSidebarClose),
    if (externalLeftSidebar != null)
      SlidingLeftDrawer(
        isOpen: isExternalLeftSidebarOpen,
        width: externalLeftSidebarWidth,
        child: Material(
          elevation: 8,
          child: externalLeftSidebar,
        ),
      ),
    if (showPageSidebar) DrawerScrim(onTap: onClosePageSidebar),
    SlidingLeftDrawer(
      isOpen: showPageSidebar,
      width: drawerWidth,
      child: PageSidebar(
        thumbnailCache: thumbnailCache,
        onPageTap: onPageTap,
        variant: PageSidebarVariant.drawer,
      ),
    ),
  ];
}
