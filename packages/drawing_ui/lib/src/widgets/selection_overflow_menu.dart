import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:drawing_ui/src/models/selection_action.dart';

/// GoodNotes-style overflow menu for selection actions.
///
/// Layout:
/// - Top row: 3 icon buttons side-by-side with labels below
/// - Divider
/// - List items: text on left, icon on right
/// - Destructive "Sil" separated by divider at the bottom
class SelectionOverflowMenu extends StatelessWidget {
  final List<SelectionAction> topRowActions;
  final List<SelectionAction> actions;
  final ValueChanged<SelectionAction> onActionTap;

  const SelectionOverflowMenu({
    super.key,
    required this.topRowActions,
    required this.actions,
    required this.onActionTap,
  });

  @override
  Widget build(BuildContext context) {
    // Separate destructive action(s) for bottom section
    final normalActions =
        actions.where((a) => !a.isDestructive).toList();
    final destructiveActions =
        actions.where((a) => a.isDestructive).toList();

    return Container(
      width: 230,
      constraints: const BoxConstraints(maxHeight: 480),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // ── Top row: icon buttons ──
              if (topRowActions.isNotEmpty) ...[
                _buildTopRow(),
                _divider(),
              ],
              // ── List items ──
              for (final action in normalActions)
                _OverflowListItem(
                  action: action,
                  onTap: () => onActionTap(action),
                ),
              // ── Destructive section ──
              if (destructiveActions.isNotEmpty) ...[
                _divider(),
                for (final action in destructiveActions)
                  _OverflowListItem(
                    action: action,
                    onTap: () => onActionTap(action),
                  ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTopRow() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          for (final action in topRowActions)
            _TopRowButton(
              action: action,
              onTap: () => onActionTap(action),
            ),
        ],
      ),
    );
  }

  Widget _divider() => Divider(
        height: 1,
        thickness: 0.5,
        color: Colors.grey.shade200,
      );
}

/// Top-row icon button: icon centered above a small label.
class _TopRowButton extends StatelessWidget {
  final SelectionAction action;
  final VoidCallback onTap;

  const _TopRowButton({required this.action, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final enabled = action.isEnabled;
    final color = enabled ? Colors.black87 : Colors.black38;

    return GestureDetector(
      onTap: enabled ? onTap : null,
      behavior: HitTestBehavior.opaque,
      child: Opacity(
        opacity: enabled ? 1.0 : 0.38,
        child: SizedBox(
          width: 64,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: 48,
                height: 48,
                child: Center(
                  child: PhosphorIcon(action.icon, size: 22, color: color),
                ),
              ),
              Text(
                action.label,
                style: TextStyle(fontSize: 11, color: color),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// List item: label on left, icon on right.
class _OverflowListItem extends StatelessWidget {
  final SelectionAction action;
  final VoidCallback onTap;

  const _OverflowListItem({required this.action, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final enabled = action.isEnabled;
    final color = action.isDestructive
        ? (enabled ? Colors.red : Colors.red.withValues(alpha: 0.38))
        : (enabled ? Colors.black87 : Colors.black38);

    return GestureDetector(
      onTap: enabled ? onTap : null,
      behavior: HitTestBehavior.opaque,
      child: Opacity(
        opacity: enabled ? 1.0 : 0.38,
        child: Container(
          height: 48,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  action.label,
                  style: TextStyle(fontSize: 15, color: color),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              PhosphorIcon(action.icon, size: 20, color: color),
            ],
          ),
        ),
      ),
    );
  }
}
