import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:drawing_ui/src/providers/providers.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:drawing_ui/src/theme/starnote_icons.dart';

/// Centered zoom overlay shown during and briefly after pinch zoom.
///
/// Displays lock toggle, current zoom % with dropdown caret, and favorite star.
/// Tapping the percentage opens a dropdown with saved favorite zoom levels.
/// Auto-hides 2 seconds after zoom gesture ends.
class ZoomControlBar extends ConsumerStatefulWidget {
  const ZoomControlBar({super.key});

  @override
  ConsumerState<ZoomControlBar> createState() => _ZoomControlBarState();
}

class _ZoomControlBarState extends ConsumerState<ZoomControlBar>
    with SingleTickerProviderStateMixin {
  late final AnimationController _fade;
  Timer? _hideTimer;
  bool _isVisible = false;
  bool _isDropdownOpen = false;

  static const _hideDuration = Duration(seconds: 2);

  @override
  void initState() {
    super.initState();
    _fade = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
  }

  @override
  void dispose() {
    _hideTimer?.cancel();
    _fade.dispose();
    super.dispose();
  }

  void _show() {
    _hideTimer?.cancel();
    if (!_isVisible) setState(() => _isVisible = true);
    _fade.forward();
  }

  void _hide() {
    _fade.reverse().then((_) {
      if (mounted) {
        setState(() {
          _isVisible = false;
          _isDropdownOpen = false;
        });
      }
    });
  }

  void _scheduleHide() {
    _hideTimer?.cancel();
    if (_isDropdownOpen) return;
    _hideTimer = Timer(_hideDuration, () {
      if (mounted) _hide();
    });
  }

  void _toggleDropdown() {
    setState(() => _isDropdownOpen = !_isDropdownOpen);
    if (_isDropdownOpen) {
      _hideTimer?.cancel();
    } else {
      _scheduleHide();
    }
  }

  void _onIconTap(VoidCallback action) {
    action();
    if (_isDropdownOpen) setState(() => _isDropdownOpen = false);
    _show();
    _scheduleHide();
  }

  void _goToFavorite(int percent) {
    final transform = ref.read(canvasTransformProvider);
    final targetZoom = transform.baselineZoom * percent / 100;
    final viewportSize = ref.read(canvasViewportSizeProvider);
    final page = ref.read(currentPageProvider);
    final pageSize = Size(page.size.width, page.size.height);
    if (viewportSize == Size.zero) return;

    ref.read(canvasTransformProvider.notifier).goToZoom(
          targetZoom: targetZoom,
          viewportSize: viewportSize,
          pageSize: pageSize,
        );
    setState(() => _isDropdownOpen = false);
    _scheduleHide();
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<bool>(isZoomingProvider, (_, isZooming) {
      if (isZooming) {
        if (_isDropdownOpen) setState(() => _isDropdownOpen = false);
        _show();
      } else {
        _scheduleHide();
      }
    });

    final transform = ref.watch(canvasTransformProvider);
    final percentage = transform.displayPercentage.round();
    final isLocked = ref.watch(zoomLockedProvider);
    final favorites = ref.watch(favoriteZoomsProvider);
    final isFavorite = favorites.contains(percentage);

    return IgnorePointer(
      ignoring: !_isVisible,
      child: FadeTransition(
        opacity: _fade,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildBar(percentage, isLocked, isFavorite),
            if (_isDropdownOpen) _buildDropdown(favorites, percentage),
          ],
        ),
      ),
    );
  }

  Widget _buildBar(int percentage, bool isLocked, bool isFavorite) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
      decoration: _overlayDecoration,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _BarIconButton(
            icon: isLocked
                ? StarNoteIcons.lockFilled
                : StarNoteIcons.lockOpen,
            isActive: isLocked,
            onTap: () => _onIconTap(
              () => ref.read(zoomLockedProvider.notifier).state = !isLocked,
            ),
          ),
          GestureDetector(
            onTap: _toggleDropdown,
            behavior: HitTestBehavior.opaque,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '$percentage%',
                    style: GoogleFonts.sourceSerif4(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 1,
                    ),
                  ),
                  const SizedBox(width: 4),
                  PhosphorIcon(
                    _isDropdownOpen
                        ? StarNoteIcons.caretUp
                        : StarNoteIcons.caretDown,
                    size: 14,
                    color: Colors.white.withValues(alpha: 0.6),
                  ),
                ],
              ),
            ),
          ),
          _BarIconButton(
            icon: isFavorite
                ? StarNoteIcons.starFilled
                : StarNoteIcons.star,
            isActive: isFavorite,
            onTap: () => _onIconTap(
              () => ref
                  .read(favoriteZoomsProvider.notifier)
                  .toggleFavorite(percentage),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDropdown(List<int> favorites, int currentPercent) {
    if (favorites.isEmpty) return const SizedBox.shrink();
    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.symmetric(vertical: 4),
      constraints: const BoxConstraints(minWidth: 120),
      decoration: _overlayDecoration,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: favorites
            .map((z) => _buildDropdownItem(z, currentPercent == z))
            .toList(),
      ),
    );
  }

  Widget _buildDropdownItem(int zoomPercent, bool isActive) {
    return GestureDetector(
      onTap: () => _goToFavorite(zoomPercent),
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        height: 48,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: 16,
                child: isActive
                    ? const PhosphorIcon(
                        StarNoteIcons.check,
                        size: 14,
                        color: Colors.white,
                      )
                    : null,
              ),
              const SizedBox(width: 12),
              Text(
                '$zoomPercent%',
                style: GoogleFonts.sourceSerif4(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  static final _overlayDecoration = BoxDecoration(
    color: Colors.black.withValues(alpha: 0.7),
    borderRadius: BorderRadius.circular(16),
    boxShadow: [
      BoxShadow(
        color: Colors.black.withValues(alpha: 0.3),
        blurRadius: 10,
        offset: const Offset(0, 4),
      ),
    ],
  );
}

/// Icon button used in the zoom overlay bar.
class _BarIconButton extends StatelessWidget {
  const _BarIconButton({
    required this.icon,
    required this.isActive,
    required this.onTap,
  });

  final IconData icon;
  final bool isActive;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: 48,
        height: 48,
        child: Center(
          child: PhosphorIcon(
            icon,
            size: StarNoteIcons.actionSize,
            color: isActive
                ? Colors.white
                : Colors.white.withValues(alpha: 0.6),
          ),
        ),
      ),
    );
  }
}
