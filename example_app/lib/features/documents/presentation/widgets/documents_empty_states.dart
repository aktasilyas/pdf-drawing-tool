/// ElyaNotes Documents Empty States
///
/// Çeşitli bölümler için boş durum widget'ları.
/// Tüm empty state'ler AppEmptyState widget'ını kullanır.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:example_app/core/theme/index.dart';
import 'package:example_app/core/widgets/index.dart';
import 'package:example_app/features/documents/presentation/providers/documents_provider.dart';

/// Tüm Notlar bölümü boş durumu
class DocumentsEmptyState extends StatelessWidget {
  const DocumentsEmptyState({super.key});

  @override
  Widget build(BuildContext context) {
    return const AppEmptyState(
      icon: Icons.description_outlined,
      title: 'Henüz not yok',
      description: 'Yeni bir not oluşturmak için "+" butonuna tıklayın',
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
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.xxl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.search_off,
              size: AppIconSize.emptyState,
              color: isDark
                  ? AppColors.textSecondaryDark
                  : AppColors.textSecondaryLight,
            ),
            const SizedBox(height: AppSpacing.xl),
            Text(
              'Sonuç bulunamadı',
              style: AppTypography.headlineSmall.copyWith(
                color: isDark
                    ? AppColors.textPrimaryDark
                    : AppColors.textPrimaryLight,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              '"$query" için eşleşen not bulunamadı',
              style: AppTypography.bodyMedium.copyWith(
                color: isDark
                    ? AppColors.textSecondaryDark
                    : AppColors.textSecondaryLight,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.xl),
            AppButton(
              label: 'Aramayı temizle',
              variant: AppButtonVariant.outline,
              size: AppButtonSize.medium,
              leadingIcon: Icons.clear,
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

/// Yakında gelecek özellikler için placeholder
class DocumentsComingSoon extends StatelessWidget {
  const DocumentsComingSoon({super.key});

  @override
  Widget build(BuildContext context) {
    return const AppEmptyState(
      icon: Icons.construction_outlined,
      title: 'Yakında',
      description: 'Bu özellik üzerinde çalışıyoruz',
    );
  }
}
