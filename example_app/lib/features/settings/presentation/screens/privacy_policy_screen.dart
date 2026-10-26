/// In-app privacy policy (bundled Markdown, works offline).
library;

import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';

import 'package:example_app/core/theme/index.dart';
import 'package:example_app/core/widgets/index.dart';
import 'package:example_app/features/settings/domain/entities/app_about_info.dart';

class PrivacyPolicyScreen extends StatefulWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  State<PrivacyPolicyScreen> createState() => _PrivacyPolicyScreenState();
}

class _PrivacyPolicyScreenState extends State<PrivacyPolicyScreen> {
  Future<String>? _policy;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Not cached: opened rarely, and a cached Future would outlive the
    // zone it completed in (breaks repeated loads in widget tests).
    const asset = AppAboutInfo.privacyPolicyAsset;
    final bundle = DefaultAssetBundle.of(context);
    _policy ??= bundle.loadString(asset, cache: false);
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Scaffold(
      backgroundColor: palette.background,
      appBar: AppBar(
        backgroundColor: palette.surface,
        leading: AppIconButton(
          icon: Icons.arrow_back,
          variant: AppIconButtonVariant.ghost,
          tooltip: 'Geri',
          onPressed: () => Navigator.of(context).maybePop(),
        ),
        title: Text(
          'Gizlilik politikası',
          style: AppTypography.titleLarge.copyWith(color: palette.textPrimary),
        ),
      ),
      body: FutureBuilder<String>(
        future: _policy,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const AppEmptyState(
              icon: Icons.error_outline,
              title: 'Gizlilik politikası açılamadı',
            );
          }
          final text = snapshot.data;
          if (text == null) {
            return const Center(child: CircularProgressIndicator());
          }
          return _PolicyBody(markdown: text);
        },
      ),
    );
  }
}

class _PolicyBody extends StatelessWidget {
  const _PolicyBody({required this.markdown});

  final String markdown;

  @override
  Widget build(BuildContext context) {
    final primary = context.palette.textPrimary;
    final body = AppTypography.bodyMedium.copyWith(color: primary);
    final sheet = MarkdownStyleSheet.fromTheme(Theme.of(context));
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 720),
        child: Markdown(
          data: markdown,
          padding: const EdgeInsets.all(AppSpacing.lg),
          styleSheet: sheet.copyWith(
            p: body,
            listBullet: body,
            h1: AppTypography.headlineMedium.copyWith(color: primary),
            h3: AppTypography.titleMedium.copyWith(
              color: primary,
              fontWeight: FontWeight.w600,
            ),
            h3Padding: const EdgeInsets.only(top: AppSpacing.xl),
          ),
        ),
      ),
    );
  }
}
