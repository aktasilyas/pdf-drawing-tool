import 'package:flutter/material.dart';

import 'package:example_app/core/theme/index.dart';
import 'package:example_app/core/widgets/buttons/index.dart';

/// Minimal app shown when startup failed. It depends on nothing that startup
/// sets up (no DI, no providers, no stored settings).
class StartupErrorApp extends StatelessWidget {
  const StartupErrorApp({
    required this.onRetry,
    this.retrying = false,
    this.details,
    this.themeMode,
    super.key,
  });

  /// `null` while a retry is running.
  final VoidCallback? onRetry;
  final bool retrying;

  /// Technical detail, shown only in debug builds.
  final String? details;

  /// `null` follows the system: the stored theme setting may be unreadable.
  final ThemeMode? themeMode;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ElyaNotes',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: themeMode ?? ThemeMode.system,
      home: StartupErrorScreen(
        onRetry: onRetry,
        retrying: retrying,
        details: details,
      ),
    );
  }
}

/// Calm failure message, a "your notes are safe" line and one Retry button.
/// No destructive options: the database is never deleted from here.
class StartupErrorScreen extends StatelessWidget {
  const StartupErrorScreen({
    required this.onRetry,
    this.retrying = false,
    this.details,
    super.key,
  });

  final VoidCallback? onRetry;
  final bool retrying;
  final String? details;

  /// Keeps the text block readable on tablets.
  static const double _maxContentWidth = 440;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;

    return Scaffold(
      backgroundColor: p.background,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpacing.xxl),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: _maxContentWidth),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.sync_problem_outlined,
                    size: AppIconSize.huge,
                    color: p.textMuted,
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  Text(
                    'Uygulama başlatılamadı',
                    style: AppTypography.headlineSmall.copyWith(
                      color: p.textPrimary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Text(
                    'Notlarınız güvende, hiçbir şey silinmedi. '
                    'Veriler açılırken bir sorun oluştu. Tekrar deneyin; '
                    'sorun sürerse uygulamayı kapatıp yeniden açın.',
                    style: AppTypography.bodyMedium.copyWith(
                      color: p.textMuted,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  AppButton(
                    label: 'Tekrar dene',
                    leadingIcon: Icons.refresh,
                    size: AppButtonSize.large,
                    isLoading: retrying,
                    onPressed: onRetry,
                  ),
                  if (details != null) ...[
                    const SizedBox(height: AppSpacing.xl),
                    Text(
                      details!,
                      style: AppTypography.caption.copyWith(
                        color: p.textMuted,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
