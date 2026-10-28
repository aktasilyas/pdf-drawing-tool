/// ElyaNotes Design System - MasterDetailLayout Component
///
/// Master-detail pattern. Phone: tek sütun, Tablet: iki sütun.
///
/// Kullanım:
/// ```dart
/// MasterDetailLayout(
///   master: DocumentList(),
///   detail: selectedDoc != null ? DocumentDetail(doc: selectedDoc) : null,
///   masterWidth: 320,
/// )
/// ```
library;

import 'package:flutter/material.dart';

import 'package:example_app/core/utils/responsive.dart';
import 'package:example_app/core/widgets/feedback/index.dart';
import 'package:example_app/core/widgets/layout/index.dart';
import 'package:example_app/l10n/l10n.dart';

/// ElyaNotes master-detail layout komponenti.
///
/// Tablet'te yan yana, phone'da tek ekran.
class MasterDetailLayout extends StatelessWidget {
  /// Master panel (liste vb.).
  final Widget master;

  /// Detail panel (seçili item detayı).
  final Widget? detail;

  /// Detail null iken gösterilecek placeholder.
  final Widget? emptyDetail;

  /// Master panel genişliği (tablet).
  final double masterWidth;

  /// Phone'da master gösterilsin mi? (phone-only).
  final bool showMaster;

  const MasterDetailLayout({
    required this.master,
    this.detail,
    this.emptyDetail,
    this.masterWidth = 320,
    this.showMaster = true,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final isPhone = Responsive.isPhone(context);

    if (isPhone) {
      return _buildPhoneLayout();
    } else {
      return _buildTabletLayout(context);
    }
  }

  Widget _buildPhoneLayout() {
    // Phone: master VEYA detail göster
    if (showMaster || detail == null) {
      return master;
    } else {
      return detail!;
    }
  }

  Widget _buildTabletLayout(BuildContext context) {
    return Row(
      children: [
        // Master panel
        SizedBox(
          width: masterWidth,
          child: master,
        ),
        // Divider
        const AppDivider(),
        // Detail panel
        Expanded(
          child: detail ?? _buildEmptyDetail(context),
        ),
      ],
    );
  }

  Widget _buildEmptyDetail(BuildContext context) {
    return emptyDetail ??
        AppEmptyState(
          icon: Icons.touch_app_outlined,
          title: context.l10n.commonSelectItemTitle,
          description: context.l10n.commonSelectItemDescription,
        );
  }
}
