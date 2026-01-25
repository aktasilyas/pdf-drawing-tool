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
    return ListTile(
      leading: Icon(
        icon,
        color: enabled ? null : Colors.grey,
      ),
      title: Text(
        title,
        style: TextStyle(
          color: enabled ? null : Colors.grey,
        ),
      ),
      subtitle: subtitle != null
          ? Text(
              subtitle!,
              style: TextStyle(
                color: enabled ? Colors.grey[600] : Colors.grey[400],
                fontSize: 13,
              ),
            )
          : null,
      trailing: trailing ?? (showArrow && onTap != null
          ? Icon(Icons.chevron_right, color: Colors.grey[400])
          : null),
      onTap: enabled ? onTap : null,
      enabled: enabled,
    );
  }
}
