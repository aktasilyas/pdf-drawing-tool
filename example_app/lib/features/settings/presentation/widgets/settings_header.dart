/// Settings screen header: title (or account avatar when cloud is on) and
/// a close button.
library;

import 'package:flutter/material.dart';

import 'package:example_app/core/theme/index.dart';
import 'package:example_app/core/widgets/index.dart';
import 'package:example_app/l10n/l10n.dart';

class SettingsHeader extends StatelessWidget {
  const SettingsHeader({super.key, this.userName, this.onNameTap});

  /// Signed-in user's display name; `null` when there is no account
  /// (cloud sync off), in which case the header shows the screen title.
  final String? userName;
  final VoidCallback? onNameTap;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final name = userName;
    final titleStyle = AppTypography.headlineMedium.copyWith(
      color: context.palette.textPrimary,
      fontWeight: FontWeight.w600,
    );
    final close = AppIconButton(
      icon: Icons.close,
      variant: AppIconButtonVariant.ghost,
      tooltip: l10n.commonClose,
      onPressed: () => Navigator.of(context).maybePop(),
    );

    final Widget content;
    if (name == null) {
      content = Row(
        children: [
          Expanded(child: Text(l10n.settingsTitle, style: titleStyle)),
          close,
        ],
      );
    } else {
      final initials = name.isNotEmpty ? name[0].toUpperCase() : 'U';
      content = Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              AppAvatar(
                initials: initials,
                size: AppAvatarSize.medium,
                backgroundColor: AppColors.primary,
              ),
              close,
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Semantics(
            container: true,
            button: true,
            label: name,
            hint: l10n.settingsEditNameHint,
            onTap: onNameTap,
            excludeSemantics: true,
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: onNameTap,
              child: ConstrainedBox(
                constraints: const BoxConstraints(
                  minHeight: AppSpacing.minTouchTarget,
                ),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(name, style: titleStyle),
                ),
              ),
            ),
          ),
        ],
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      child: content,
    );
  }
}
