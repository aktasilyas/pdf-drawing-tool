/// ElyaNotes Documents Empty States
///
/// Çeşitli bölümler için boş durum widget'ları.
/// Tüm empty state'ler AppEmptyState widget'ını kullanır.
library;

import 'package:drawing_core/drawing_core.dart' show CoverFamily;
import 'package:drawing_ui/drawing_ui.dart'
    show CoverPreviewWidget, ElyanotesIcons;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:example_app/core/theme/index.dart';
import 'package:example_app/core/widgets/index.dart';
import 'package:example_app/features/documents/presentation/providers/documents_provider.dart';

/// Tüm Notlar bölümü boş durumu
class DocumentsEmptyState extends StatelessWidget {
  const DocumentsEmptyState({super.key, this.onCreateNew});

  /// Shows the "Yeni not" call to action when non-null.
  final VoidCallback? onCreateNew;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 320),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CoverPreviewWidget(
                cover: CoverFamily.linenSand,
                width: 120,
                height: 160,
                showBorder: false,
              ),
              const SizedBox(height: AppSpacing.xl),
              Text(
                'Henüz not yok',
                style: AppTypography.headlineMedium
                    .copyWith(color: palette.textPrimary),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                'Yeni bir defter oluşturun ya da bir PDF içe aktarın.',
                style:
                    AppTypography.bodyMedium.copyWith(color: palette.textMuted),
                textAlign: TextAlign.center,
              ),
              if (onCreateNew != null) ...[
                const SizedBox(height: AppSpacing.xl),
                ConstrainedBox(
                  constraints: const BoxConstraints(
                    minHeight: AppSpacing.minTouchTarget,
                  ),
                  child: AppButton(
                    label: 'Yeni not',
                    leadingIcon: ElyanotesIcons.libraryPlus,
                    onPressed: onCreateNew,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Favoriler bölümü boş durumu
class FavoritesEmptyState extends StatelessWidget {
  const FavoritesEmptyState({super.key});

  @override
  Widget build(BuildContext context) {
    return const AppEmptyState(
      icon: Icons.star_outline,
      title: 'Favori not yok',
      description:
          'Notlarınızı favorilere eklemek için yıldız ikonuna tıklayın',
    );
  }
}

/// Klasör bölümü boş durumu
class FolderEmptyState extends StatelessWidget {
  const FolderEmptyState({super.key});

  @override
  Widget build(BuildContext context) {
    return const AppEmptyState(
      icon: Icons.folder_open,
      title: 'Bu klasör boş',
      description: 'Notlarınızı buraya taşıyın veya yeni not oluşturun',
    );
  }
}

/// Çöp Kutusu bölümü boş durumu
class TrashEmptyState extends StatelessWidget {
  const TrashEmptyState({super.key});

  @override
  Widget build(BuildContext context) {
    return const AppEmptyState(
      icon: Icons.delete_outline,
      title: 'Çöp kutusu boş',
      description: 'Silinen notlar burada görünecek',
    );
  }
}

/// Arama sonucu boş durumu
class DocumentsEmptySearchResult extends ConsumerWidget {
  final String query;

  const DocumentsEmptySearchResult({
    super.key,
    required this.query,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.xxl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              ElyanotesIcons.librarySearch,
              size: AppIconSize.emptyState,
              color: context.palette.textMuted,
            ),
            const SizedBox(height: AppSpacing.xl),
            Text(
              'Sonuç bulunamadı',
              style: AppTypography.headlineSmall.copyWith(
                color: context.palette.textPrimary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              '"$query" için eşleşen not bulunamadı',
              style: AppTypography.bodyMedium.copyWith(
                color: context.palette.textMuted,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.xl),
            AppButton(
              label: 'Aramayı temizle',
              variant: AppButtonVariant.outline,
              size: AppButtonSize.medium,
              leadingIcon: ElyanotesIcons.libraryClose,
              onPressed: () {
                ref.read(searchQueryProvider.notifier).state = '';
              },
            ),
          ],
        ),
      ),
    );
  }
}
