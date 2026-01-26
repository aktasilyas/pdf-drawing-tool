import 'package:flutter/material.dart';

class SettingsTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;
  final bool enabled;
  final bool showArrow;

  const SettingsTile({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    this.trailing,
    this.onTap,
    this.enabled = true,
    this.showArrow = true,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    
    return ListTile(
      leading: Icon(
        icon,
        color: enabled ? colorScheme.onSurface : colorScheme.outline,
      ),
      title: Text(
        title,
        style: TextStyle(
          color: enabled ? colorScheme.onSurface : colorScheme.outline,
        ),
      ),
      subtitle: subtitle != null
          ? Text(
              subtitle!,
              style: TextStyle(
                color: enabled ? colorScheme.onSurfaceVariant : colorScheme.outline,
                fontSize: 13,
              ),
            )
          : null,
      trailing: trailing ?? (showArrow && onTap != null
          ? Icon(Icons.chevron_right, color: colorScheme.outline)
          : null),
      onTap: enabled ? onTap : null,
      enabled: enabled,
    );
  }
}
