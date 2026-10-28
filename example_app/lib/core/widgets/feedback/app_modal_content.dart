part of 'app_modal.dart';

// ══════════════════════════════════════════════════════════════════════════
// BOTTOM SHEET CONTENT
// ══════════════════════════════════════════════════════════════════════════

class _BottomSheetContent extends StatelessWidget {
  final String title;
  final Widget content;
  final List<Widget>? actions;
  final bool showCloseButton;

  const _BottomSheetContent({
    required this.title,
    required this.content,
    required this.actions,
    required this.showCloseButton,
  });

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final textPrimary = palette.textPrimary;
    final handleColor = palette.border;

    return SafeArea(
      child: Padding(
        // ✅ Keyboard-safe: klavye açılınca modal yukarı kayar
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Drag handle
            Center(
              child: Container(
                width: AppSpacing.xxl,
                height: AppSpacing.xs,
                margin: const EdgeInsets.only(top: AppSpacing.sm),
                decoration: BoxDecoration(
                  color: handleColor,
                  borderRadius: BorderRadius.circular(AppRadius.full),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            // Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      title,
                      style: AppTypography.headlineSmall.copyWith(
                        color: textPrimary,
                      ),
                    ),
                  ),
                  if (showCloseButton) const _ModalCloseButton(),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            // Content (scrollable)
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
                child: content,
              ),
            ),
            // Actions
            if (actions != null && actions!.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.xl),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: _buildActionButtons(actions!),
                ),
              ),
            ],
            const SizedBox(height: AppSpacing.xl),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildActionButtons(List<Widget> actions) {
    final children = <Widget>[];
    for (var i = 0; i < actions.length; i++) {
      if (i > 0) children.add(const SizedBox(width: AppSpacing.sm));
      children.add(actions[i]);
    }
    return children;
  }
}

// ══════════════════════════════════════════════════════════════════════════
// DIALOG CONTENT
// ══════════════════════════════════════════════════════════════════════════

class _DialogContent extends StatelessWidget {
  final String title;
  final Widget content;
  final List<Widget>? actions;
  final bool showCloseButton;

  const _DialogContent({
    required this.title,
    required this.content,
    required this.actions,
    required this.showCloseButton,
  });

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final textPrimary = palette.textPrimary;

    return Padding(
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header
          Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: AppTypography.headlineSmall.copyWith(
                    color: textPrimary,
                  ),
                ),
              ),
              if (showCloseButton) const _ModalCloseButton(),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          // Content (scrollable - keyboard-safe)
          Flexible(
            child: SingleChildScrollView(
              child: content,
            ),
          ),
          // Actions
          if (actions != null && actions!.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.xl),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: _buildActionButtons(actions!),
            ),
          ],
        ],
      ),
    );
  }

  List<Widget> _buildActionButtons(List<Widget> actions) {
    final children = <Widget>[];
    for (var i = 0; i < actions.length; i++) {
      if (i > 0) children.add(const SizedBox(width: AppSpacing.sm));
      children.add(actions[i]);
    }
    return children;
  }
}

/// Close button shared by the sheet and the dialog layout. `AppIconButton`
/// carries the 48dp hit area and the screen-reader label.
class _ModalCloseButton extends StatelessWidget {
  const _ModalCloseButton();

  @override
  Widget build(BuildContext context) {
    return AppIconButton(
      icon: Icons.close,
      variant: AppIconButtonVariant.ghost,
      tooltip: context.l10n.commonClose,
      onPressed: () => Navigator.of(context).pop(),
    );
  }
}
