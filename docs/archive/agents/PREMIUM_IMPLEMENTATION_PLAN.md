# Premium Altyapısı Aktivasyon Planı — ElyaNotes

> **Bu doküman bir AI Agent tarafından okunup adım adım uygulanmak üzere hazırlanmıştır.**
> Her phase bağımsızdır. Bir phase tamamlanmadan diğerine geçilmez.
> Projedeki mevcut premium altyapısı (SubscriptionTier, paywall_placeholder_screen, AI rate limit) temel alınır.

---

## Strateji Özeti

**Felsefe:** Kullanıcıyı sıkmadan, değer fark ettir ve dönüştür. Free tier gerçekten kullanışlı olmalı, premium ise "keşke olsa" dedirten akıllı özellikler sunmalı.

**Kısıtlamalar (Soft Paywall):**
- **Doküman limiti:** Free kullanıcı max 3 notebook oluşturabilir (GoodNotes modeli)
- **Ses kaydı:** Free'de kayıt max 5 dakika/session, premium'da sınırsız
- **AI chat:** Free'de 15 mesaj/gün (zaten mevcut), premium'da 150
- **PDF import:** Free'de max 3 PDF import, premium'da sınırsız
- **Export:** Free'de watermark var, premium'da yok

**Upgrade Prompt Kuralları:**
- Asla popup ile kesme, sadece ilgili aksiyon anında göster
- Lock icon + kısa açıklama → ilgi varsa paywall'a yönlendir
- Agresif değil, "bu özellik seni bekliyor" tonu

---

## Phase 1 — Feature Gate Service (Domain Layer)

### Amaç
Tüm premium kısıtlamalarını tek bir merkezden yöneten, test edilebilir bir servis oluştur.

### Adım 1.1 — FeatureGate entity oluştur

**Dosya (yeni):** `lib/features/premium/domain/entities/feature_gate.dart`

```dart
/// Uygulamadaki kısıtlanabilir özelliklerin tanımı.
enum GatedFeature {
  createNotebook,
  importPdf,
  audioRecording,
  aiChat,
  exportWithoutWatermark,
  cloudSync,
  advancedPdfAnnotation,
  aiTranscription,
}

/// Bir özelliğin mevcut erişim durumu.
class FeatureAccess {
  final bool isAllowed;
  final int? currentUsage;
  final int? maxUsage;
  final String? upgradeMessage;

  const FeatureAccess({
    required this.isAllowed,
    this.currentUsage,
    this.maxUsage,
    this.upgradeMessage,
  });

  /// Kullanımın yüzde kaçına ulaşıldı (progress bar için).
  double get usageRatio {
    if (currentUsage == null || maxUsage == null || maxUsage == 0) return 0;
    return (currentUsage! / maxUsage!).clamp(0.0, 1.0);
  }

  /// Limite yaklaşıldığında uyarı göster (>80%).
  bool get isNearLimit => usageRatio >= 0.8;

  factory FeatureAccess.allowed() =>
      const FeatureAccess(isAllowed: true);

  factory FeatureAccess.blocked({
    int? currentUsage,
    int? maxUsage,
    String? message,
  }) =>
      FeatureAccess(
        isAllowed: false,
        currentUsage: currentUsage,
        maxUsage: maxUsage,
        upgradeMessage: message,
      );
}
```

### Adım 1.2 — FeatureGateService oluştur

**Dosya (yeni):** `lib/features/premium/domain/services/feature_gate_service.dart`

```dart
import 'package:example_app/features/premium/domain/entities/feature_gate.dart';
import 'package:example_app/features/premium/domain/entities/subscription.dart';

/// Merkezi feature gating servisi.
/// Tüm premium kısıtlamaları buradan yönetilir.
class FeatureGateService {
  final SubscriptionTier _tier;

  FeatureGateService(this._tier);

  /// Free tier limitleri.
  static const _freeLimits = {
    GatedFeature.createNotebook: 3,
    GatedFeature.importPdf: 3,
    GatedFeature.audioRecording: 5,      // dakika
    GatedFeature.aiChat: 15,             // mesaj/gün
  };

  /// Premium tier limitleri.
  static const _premiumLimits = {
    GatedFeature.createNotebook: 999,    // pratikte sınırsız
    GatedFeature.importPdf: 999,
    GatedFeature.audioRecording: 999,
    GatedFeature.aiChat: 150,
  };

  /// PremiumPlus (Pro) tier limitleri.
  static const _proLimits = {
    GatedFeature.createNotebook: 999,
    GatedFeature.importPdf: 999,
    GatedFeature.audioRecording: 999,
    GatedFeature.aiChat: 1000,
  };

  /// Özelliğe erişim kontrolü.
  FeatureAccess checkAccess(GatedFeature feature, {int currentUsage = 0}) {
    // Premium+ kullanıcılar her şeye erişebilir
    if (_tier == SubscriptionTier.premiumPlus) {
      return FeatureAccess.allowed();
    }

    // Premium kullanıcılar — sadece AI chat limiti var
    if (_tier == SubscriptionTier.premium) {
      final limit = _premiumLimits[feature];
      if (limit == null) return FeatureAccess.allowed();
      if (currentUsage >= limit) {
        return FeatureAccess.blocked(
          currentUsage: currentUsage,
          maxUsage: limit,
          message: _upgradeMessage(feature),
        );
      }
      return FeatureAccess(
        isAllowed: true,
        currentUsage: currentUsage,
        maxUsage: limit,
      );
    }

    // Free kullanıcılar
    final limit = _freeLimits[feature];

    // Limitsiz gated özellikler (export, sync vs.)
    if (limit == null) {
      final alwaysBlocked = [
        GatedFeature.exportWithoutWatermark,
        GatedFeature.cloudSync,
        GatedFeature.advancedPdfAnnotation,
        GatedFeature.aiTranscription,
      ];
      if (alwaysBlocked.contains(feature)) {
        return FeatureAccess.blocked(message: _upgradeMessage(feature));
      }
      return FeatureAccess.allowed();
    }

    // Sayısal limitli özellikler
    if (currentUsage >= limit) {
      return FeatureAccess.blocked(
        currentUsage: currentUsage,
        maxUsage: limit,
        message: _upgradeMessage(feature),
      );
    }

    return FeatureAccess(
      isAllowed: true,
      currentUsage: currentUsage,
      maxUsage: limit,
    );
  }

  /// Özelliğe göre Türkçe upgrade mesajı.
  String _upgradeMessage(GatedFeature feature) {
    return switch (feature) {
      GatedFeature.createNotebook =>
        'Ücretsiz planda en fazla 3 defter oluşturabilirsiniz. Premium\'a geçerek sınırsız defter oluşturun.',
      GatedFeature.importPdf =>
        'Ücretsiz planda en fazla 3 PDF içe aktarabilirsiniz. Premium ile sınırsız PDF kullanın.',
      GatedFeature.audioRecording =>
        'Ücretsiz planda ses kaydı 5 dakika ile sınırlıdır. Premium ile sınırsız kayıt yapın.',
      GatedFeature.aiChat =>
        'Günlük AI mesaj limitinize ulaştınız. Premium\'a geçerek daha fazla soru sorun.',
      GatedFeature.exportWithoutWatermark =>
        'Filigransız dışa aktarım Premium özelliğidir.',
      GatedFeature.cloudSync =>
        'Bulut senkronizasyonu Premium özelliğidir. Notlarınız tüm cihazlarınızda olsun.',
      GatedFeature.advancedPdfAnnotation =>
        'Gelişmiş PDF araçları Premium özelliğidir.',
      GatedFeature.aiTranscription =>
        'Ses kaydını metne dönüştürme Premium özelliğidir.',
    };
  }

  /// Kullanıcının mevcut tier'ı.
  SubscriptionTier get currentTier => _tier;

  /// Premium mı?
  bool get isPremium =>
      _tier == SubscriptionTier.premium ||
      _tier == SubscriptionTier.premiumPlus;
}
```

### Adım 1.3 — Riverpod provider oluştur

**Dosya (yeni):** `lib/features/premium/presentation/providers/feature_gate_provider.dart`

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:example_app/features/premium/domain/entities/feature_gate.dart';
import 'package:example_app/features/premium/domain/services/feature_gate_service.dart';
import 'package:example_app/features/premium/presentation/providers/premium_providers.dart';

/// FeatureGateService provider.
final featureGateServiceProvider = Provider<FeatureGateService>((ref) {
  final tier = ref.watch(currentTierProvider);
  return FeatureGateService(tier);
});

/// Belirli bir özelliğin erişim durumunu kontrol eden provider.
/// Kullanım: ref.watch(featureAccessProvider(FeatureAccessParams(...)))
final featureAccessProvider =
    Provider.family<FeatureAccess, FeatureAccessParams>((ref, params) {
  final gate = ref.watch(featureGateServiceProvider);
  return gate.checkAccess(params.feature, currentUsage: params.currentUsage);
});

/// Feature access parametreleri.
class FeatureAccessParams {
  final GatedFeature feature;
  final int currentUsage;

  const FeatureAccessParams({
    required this.feature,
    this.currentUsage = 0,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is FeatureAccessParams &&
          feature == other.feature &&
          currentUsage == other.currentUsage;

  @override
  int get hashCode => Object.hash(feature, currentUsage);
}
```

### Adım 1.4 — Barrel export güncelle

**Dosya:** `lib/features/premium/premium.dart` (veya ilgili barrel file)

Feature gate entity, service ve provider'ı export'a ekle.

### Doğrulama Kriterleri — Phase 1

- [ ] `FeatureGateService` free tier'da `createNotebook` için 3 limit dönmeli
- [ ] Premium tier'da `createNotebook` allowed dönmeli
- [ ] `FeatureAccess.usageRatio` 2/3 = 0.666 dönmeli
- [ ] `FeatureAccess.isNearLimit` 3/3 = true dönmeli
- [ ] Provider'lar compile hatası vermemeli

---

## Phase 2 — Notebook Limiti (3 Defter Kısıtlaması)

### Amaç
Free kullanıcı 3'ten fazla notebook oluşturmaya çalıştığında nazik bir upgrade prompt göster.

### Adım 2.1 — Notebook sayısını sorgulayan provider

**Dosya (yeni veya mevcut):** `lib/features/premium/presentation/providers/usage_providers.dart`

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Kullanıcının mevcut notebook sayısını döndürür.
/// Bu provider, document/notebook listesini tutan mevcut provider'dan türetilmeli.
/// Aşağıdaki implementasyon projedeki mevcut yapıya göre ayarlanmalı.
final notebookCountProvider = Provider<int>((ref) {
  // TODO: Mevcut document list provider'ından notebook sayısını al.
  // Örnek: ref.watch(documentsProvider).length
  // Geçici olarak 0 döndür, Phase 2.3'te bağlanacak.
  return 0;
});
```

**NOT:** Bu provider'ı projedeki mevcut doküman/notebook listeleme yapısına bağla. `documents` tablosundan veya local DB'den sayıyı çek.

### Adım 2.2 — Upgrade prompt widget'ı oluştur

**Dosya (yeni):** `lib/features/premium/presentation/widgets/upgrade_prompt_sheet.dart`

```dart
import 'package:flutter/material.dart';
import 'package:example_app/core/theme/index.dart';
import 'package:example_app/features/premium/domain/entities/feature_gate.dart';

/// Contextual upgrade prompt — bottom sheet olarak gösterilir.
/// Agresif değil, bilgilendirici ton.
class UpgradePromptSheet extends StatelessWidget {
  const UpgradePromptSheet({
    super.key,
    required this.access,
    required this.featureIcon,
    required this.featureTitle,
    this.onUpgrade,
    this.onDismiss,
  });

  final FeatureAccess access;
  final IconData featureIcon;
  final String featureTitle;
  final VoidCallback? onUpgrade;
  final VoidCallback? onDismiss;

  /// Bottom sheet olarak göster.
  static Future<void> show(
    BuildContext context, {
    required FeatureAccess access,
    required IconData featureIcon,
    required String featureTitle,
    VoidCallback? onUpgrade,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => UpgradePromptSheet(
        access: access,
        featureIcon: featureIcon,
        featureTitle: featureTitle,
        onUpgrade: onUpgrade ?? () => Navigator.pop(context),
        onDismiss: () => Navigator.pop(context),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      margin: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(AppRadius.xl),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Drag handle
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),

            // Icon
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                featureIcon,
                size: 32,
                color: theme.colorScheme.primary,
              ),
            ),
            const SizedBox(height: AppSpacing.md),

            // Başlık
            Text(
              featureTitle,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.sm),

            // Açıklama
            Text(
              access.upgradeMessage ?? 'Bu özellik Premium planla kullanılabilir.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.sm),

            // Usage bar (limit varsa)
            if (access.currentUsage != null && access.maxUsage != null) ...[
              const SizedBox(height: AppSpacing.sm),
              _buildUsageBar(theme),
              const SizedBox(height: AppSpacing.sm),
            ],

            const SizedBox(height: AppSpacing.lg),

            // Premium butonu
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: onUpgrade,
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppRadius.lg),
                  ),
                ),
                child: const Text('Premium\'a Geç'),
              ),
            ),
            const SizedBox(height: AppSpacing.sm),

            // Kapat butonu
            TextButton(
              onPressed: onDismiss,
              child: Text(
                'Şimdilik Değil',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUsageBar(ThemeData theme) {
    return Column(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: access.usageRatio,
            minHeight: 8,
            backgroundColor: theme.colorScheme.surfaceContainerHighest,
            valueColor: AlwaysStoppedAnimation(
              access.isNearLimit
                  ? theme.colorScheme.error
                  : theme.colorScheme.primary,
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          '${access.currentUsage} / ${access.maxUsage} kullanıldı',
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}
```

### Adım 2.3 — Notebook oluşturma aksiyonuna gate ekle

**Dosya:** Projedeki notebook/doküman oluşturma butonunun olduğu widget.

**Açıklama:** Notebook oluştur butonuna basıldığında, `FeatureGateService` üzerinden kontrol yap. Mevcut notebook sayısı >= 3 ise `UpgradePromptSheet.show()` çağır, değilse normal oluşturma devam etsin.

**Örnek entegrasyon kodu:**

```dart
void _onCreateNotebook(BuildContext context, WidgetRef ref) {
  final notebookCount = ref.read(notebookCountProvider);
  final access = ref.read(featureAccessProvider(
    FeatureAccessParams(
      feature: GatedFeature.createNotebook,
      currentUsage: notebookCount,
    ),
  ));

  if (!access.isAllowed) {
    UpgradePromptSheet.show(
      context,
      access: access,
      featureIcon: Icons.book_outlined,
      featureTitle: 'Defter Limitine Ulaştınız',
      onUpgrade: () {
        Navigator.pop(context);
        // Paywall ekranına yönlendir
        // context.push('/paywall');
      },
    );
    return;
  }

  // Normal notebook oluşturma akışı
  _createNotebook();
}
```

### Adım 2.4 — Notebook listesinde "near limit" uyarısı (opsiyonel)

**Açıklama:** Kullanıcı 2/3 notebook'a ulaştığında, liste ekranının altına küçük bir banner göster:

```dart
// Notebook listesi widget'ında:
if (access.isNearLimit && !access.isAllowed == false) {
  // Küçük bilgi banner'ı: "1 defter hakkınız kaldı"
}
```

### Doğrulama Kriterleri — Phase 2

- [ ] Free kullanıcı 3 notebook varken yeni oluşturmaya çalışınca UpgradePromptSheet gösterilmeli
- [ ] Usage bar 3/3 göstermeli, kırmızı renkte
- [ ] "Şimdilik Değil" butonuyla sheet kapanmalı
- [ ] "Premium'a Geç" butonuyla paywall ekranına yönlendirmeli
- [ ] Premium kullanıcıda hiçbir kısıtlama olmamalı
- [ ] 2/3 notebook'ta isNearLimit true olmalı (opsiyonel banner)

---

## Phase 3 — Ses Kaydı Kısıtlaması (5 Dakika Free Limit)

### Amaç
Free kullanıcıların ses kaydı 5 dakikada otomatik durmalı, premium'da sınırsız.

### Adım 3.1 — Ses kaydı servisine limit kontrolü ekle

**Dosya:** Projedeki ses kaydı servis/provider dosyası.

**Açıklama:** Ses kaydı başlatıldığında veya devam ederken, timer ile 5 dakikayı kontrol et. Limit aşıldığında kaydı durdur ve upgrade prompt göster.

**Örnek timer logic:**

```dart
// Audio recording provider/service içinde:

static const _freeRecordingLimitSeconds = 5 * 60; // 5 dakika

void _onRecordingTick(Duration elapsed) {
  if (!_isPremium && elapsed.inSeconds >= _freeRecordingLimitSeconds) {
    stopRecording();
    _showRecordingLimitReached();
  }
}

void _showRecordingLimitReached() {
  // UpgradePromptSheet.show() çağır:
  // featureIcon: Icons.mic_outlined
  // featureTitle: 'Kayıt Süresi Doldu'
  // message: 'Ücretsiz planda ses kaydı 5 dakika ile sınırlıdır.'
}
```

### Adım 3.2 — Kayıt başlamadan önce kalan süreyi göster

**Açıklama:** Free kullanıcı kayıt butonuna bastığında, UI'da "5:00 kaldı" şeklinde geri sayım göster. Bu hem bilgilendirme hem de premium'a yönlendirme sağlar.

```dart
// Recording UI widget'ında:
if (!isPremium) {
  final remaining = Duration(seconds: _freeRecordingLimitSeconds) - elapsed;
  Text(
    'Kalan: ${remaining.inMinutes}:${(remaining.inSeconds % 60).toString().padLeft(2, '0')}',
    style: theme.textTheme.bodySmall?.copyWith(
      color: remaining.inSeconds < 60
          ? theme.colorScheme.error  // Son 1 dakikada kırmızı
          : theme.colorScheme.onSurfaceVariant,
    ),
  );
}
```

### Adım 3.3 — Kayıt bittiğinde nazik prompt

**Açıklama:** 5 dakika dolduğunda kayıt otomatik durur. Kayıt kaydedilir (kullanıcı kaybetmez!). Sonra upgrade prompt gösterilir.

**ÖNEMLİ:** Kaydı silme veya kaydetmeme ASLA yapılmaz. Kullanıcının kaydı her zaman korunur. Sadece daha uzun kayıt için premium önerilir.

### Doğrulama Kriterleri — Phase 3

- [ ] Free kullanıcı 5 dakikadan sonra kayıt otomatik durmalı
- [ ] Kayıt kaydedilmeli (kullanıcı kaybetmemeli!)
- [ ] Süre dolduğunda UpgradePromptSheet gösterilmeli
- [ ] Kayıt sırasında kalan süre görünmeli
- [ ] Son 1 dakikada kırmızı renk olmalı
- [ ] Premium kullanıcıda timer/limit olmamalı

---

## Phase 4 — PDF Import Limiti (3 PDF Kısıtlaması)

### Amaç
Free kullanıcı max 3 PDF import edebilsin.

### Adım 4.1 — PDF import sayısını takip et

**Dosya:** Projedeki PDF import logic'i.

**Açıklama:** Import edilen PDF sayısını local DB'de veya SharedPreferences'ta tut. Her import'ta sayaç artır.

```dart
// PDF import akışında:
void _onImportPdf(BuildContext context, WidgetRef ref) {
  final importedCount = ref.read(pdfImportCountProvider);
  final access = ref.read(featureAccessProvider(
    FeatureAccessParams(
      feature: GatedFeature.importPdf,
      currentUsage: importedCount,
    ),
  ));

  if (!access.isAllowed) {
    UpgradePromptSheet.show(
      context,
      access: access,
      featureIcon: Icons.picture_as_pdf_outlined,
      featureTitle: 'PDF Import Limitine Ulaştınız',
      onUpgrade: () {
        Navigator.pop(context);
        // Paywall'a yönlendir
      },
    );
    return;
  }

  // Normal PDF import akışı
  _importPdf();
}
```

### Adım 4.2 — Import sayacı provider

**Dosya:** `lib/features/premium/presentation/providers/usage_providers.dart`

```dart
/// Import edilmiş PDF sayısı.
/// SharedPreferences veya local DB'den okunur.
final pdfImportCountProvider = Provider<int>((ref) {
  // TODO: Mevcut PDF/document listesinden import edilmiş olanları say
  return 0;
});
```

### Doğrulama Kriterleri — Phase 4

- [ ] Free kullanıcı 3 PDF import ettikten sonra yeni import engellenip prompt gösterilmeli
- [ ] Usage bar 3/3 göstermeli
- [ ] Premium kullanıcıda limit olmamalı
- [ ] Mevcut PDF'ler silinince import hakkı geri gelmeli (isteğe bağlı karar)

---

## Phase 5 — Export Watermark Sistemi

### Amaç
Free kullanıcı export ettiğinde çıktıya küçük "ElyaNotes" watermark ekle, premium'da watermark olmasın.

### Adım 5.1 — Export servisine watermark kontrolü ekle

**Dosya:** Projedeki export/share servis dosyası.

**Açıklama:** Export sırasında tier kontrolü yap. Free ise çıktının sağ alt köşesine küçük, şeffaf watermark ekle.

```dart
// Export logic içinde:
Future<File> exportDocument(Document doc, {required SubscriptionTier tier}) async {
  final image = await renderDocument(doc);

  if (tier == SubscriptionTier.free) {
    return _addWatermark(image);
  }

  return image;
}

Future<File> _addWatermark(File image) async {
  // Canvas'a küçük "ElyaNotes" texti çiz
  // Opaklık: 0.3 (çok belirgin olmasın)
  // Konum: sağ alt köşe
  // Font: 12px, gri
}
```

### Adım 5.2 — Export butonunda bilgilendirme

**Açıklama:** Free kullanıcı export butonuna bastığında, export işlemi başlamadan önce küçük bir bilgi göster: "Ücretsiz planda dışa aktarımlarda ElyaNotes filigranı eklenir." Premium butonu ile birlikte.

Bu bir engelleme DEĞİL, bilgilendirme. Export işlemi yine yapılır.

### Doğrulama Kriterleri — Phase 5

- [ ] Free kullanıcı export'unda watermark olmalı
- [ ] Watermark küçük, şeffaf ve köşede olmalı (UI'ı bozmamalı)
- [ ] Premium kullanıcı export'unda watermark olmamalı
- [ ] Export öncesi bilgilendirme gösterilmeli (engellemeden)

---

## Phase 6 — Near-Limit Uyarı Banner Sistemi

### Amaç
Kullanıcı limite yaklaştığında (>80%) nazik bir banner göster.

### Adım 6.1 — NearLimitBanner widget'ı

**Dosya (yeni):** `lib/features/premium/presentation/widgets/near_limit_banner.dart`

```dart
import 'package:flutter/material.dart';
import 'package:example_app/core/theme/index.dart';

/// Limite yaklaşıldığında gösterilen ince banner.
/// Sayfanın üst veya altına yerleştirilir.
class NearLimitBanner extends StatelessWidget {
  const NearLimitBanner({
    super.key,
    required this.message,
    required this.onUpgrade,
    this.onDismiss,
  });

  final String message;
  final VoidCallback onUpgrade;
  final VoidCallback? onDismiss;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: theme.colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: Row(
        children: [
          Icon(
            Icons.info_outline,
            size: 18,
            color: theme.colorScheme.onPrimaryContainer,
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              message,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onPrimaryContainer,
              ),
            ),
          ),
          TextButton(
            onPressed: onUpgrade,
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: Text(
              'Yükselt',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          if (onDismiss != null)
            IconButton(
              onPressed: onDismiss,
              icon: const Icon(Icons.close, size: 16),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
              visualDensity: VisualDensity.compact,
            ),
        ],
      ),
    );
  }
}
```

### Adım 6.2 — Banner'ı kritik ekranlara ekle

**Açıklama:** Aşağıdaki ekranlarda kullanım kontrol et, near-limit ise banner göster:

- **Notebook listesi ekranı:** "1 defter hakkınız kaldı" (2/3 kullanımda)
- **AI chat sidebar:** "5 AI mesajınız kaldı" (10/15 kullanımda)
- **PDF import akışı:** "1 PDF import hakkınız kaldı"

```dart
// Örnek kullanım (herhangi bir ekranda):
final access = ref.watch(featureAccessProvider(
  FeatureAccessParams(
    feature: GatedFeature.createNotebook,
    currentUsage: notebookCount,
  ),
));

if (access.isAllowed && access.isNearLimit) {
  NearLimitBanner(
    message: '${access.maxUsage! - access.currentUsage!} defter hakkınız kaldı',
    onUpgrade: () => context.push('/paywall'),
    onDismiss: () { /* dismiss state */ },
  );
}
```

### Doğrulama Kriterleri — Phase 6

- [ ] 2/3 notebook'ta banner gösterilmeli: "1 defter hakkınız kaldı"
- [ ] 12/15 AI mesajda banner gösterilmeli: "3 AI mesajınız kaldı"
- [ ] Banner'daki "Yükselt" butonu paywall'a yönlendirmeli
- [ ] "X" ile kapatılabilmeli ve aynı session'da tekrar gösterilmemeli
- [ ] Premium kullanıcıda asla banner gösterilmemeli

---

## Phase 7 — Paywall Ekranını İşlevsel Hale Getir

### Amaç
Mevcut `paywall_placeholder_screen.dart`'ı gerçek bir paywall'a dönüştür. RevenueCat entegrasyonu sonraya bırakılabilir, ama UI ve akış tamamlansın.

### Adım 7.1 — Paywall ekranını güncelle

**Dosya:** `lib/features/premium/presentation/screens/paywall_placeholder_screen.dart`

**Değişiklikler:**
- Plan kartlarındaki "Yakında" butonlarını aktif butonlara çevir
- Yıllık/aylık toggle ekle
- Fiyatları Türk Lirası ile göster: Premium ₺149/ay veya ₺999/yıl, Pro ₺299/ay veya ₺1.999/yıl
- "7 gün ücretsiz dene" CTA ekle
- Yıllık seçildiğinde "Aylık ₺83 — %44 tasarruf" göster

### Adım 7.2 — Plan kartlarını güncellenmiş özelliklerle yenile

```
Free:
- 3 defter, 3 PDF import
- 5 dk ses kaydı
- 15 AI mesaj/gün
- Temel çizim araçları
- Filiganlı export

Premium (₺149/ay — ₺999/yıl):
- Sınırsız defter ve PDF
- Sınırsız ses kaydı
- 150 AI mesaj/gün
- DeepSeek V3 + Gemini Flash
- Gelişmiş PDF araçları
- Filigransız export
- Bulut senkronizasyon

Pro (₺299/ay — ₺1.999/yıl):
- Premium'daki her şey
- 1000 AI mesaj/gün
- GPT-5 mini + DeepSeek Reasoner
- Ses kaydını metne dönüştürme
- AI flashcard oluşturma
- Öncelikli destek
```

### Adım 7.3 — Paywall'a navigasyon route'u ekle

**Dosya:** `lib/core/routing/` altındaki router dosyası.

**Açıklama:** `/paywall` route'u ekle. `UpgradePromptSheet` ve `NearLimitBanner`'daki upgrade butonları bu route'a yönlendirecek.

### Doğrulama Kriterleri — Phase 7

- [ ] Paywall ekranı açılıyor olmalı
- [ ] Aylık/yıllık toggle çalışmalı
- [ ] Yıllık seçildiğinde tasarruf yüzdesi gösterilmeli
- [ ] Plan kartları güncel özellikleri listelemeli
- [ ] "Premium'a Geç" butonu tıklanabilir olmalı (şimdilik mock, RevenueCat sonra)
- [ ] `/paywall` route'u çalışmalı

---

## Özet — Tüm Phase'lerin Bağımlılık Haritası

```
Phase 1 (Feature Gate Service)    ← Bağımsız, hemen başla
    │
Phase 2 (Notebook Limiti)         ← Phase 1'e bağlı
Phase 3 (Ses Kaydı Limiti)        ← Phase 1'e bağlı
Phase 4 (PDF Import Limiti)       ← Phase 1'e bağlı
    │
Phase 5 (Export Watermark)        ← Phase 1'e bağlı, bağımsız
Phase 6 (Near-Limit Banners)      ← Phase 1 + 2/3/4'e bağlı
    │
Phase 7 (Paywall UI)              ← Phase 6'ya bağlı (banner'lar paywall'a yönlendirir)
```

## Kritik Kurallar

1. **Kullanıcı verisini ASLA silme/engelleme.** Limit aşılınca yeni oluşturma engellenir, mevcut veriler her zaman erişilebilir kalır.
2. **Ses kaydı durduğunda kayıt HER ZAMAN kaydedilir.** Sadece daha uzun kayıt premium.
3. **Banner'lar ve prompt'lar kapatılabilir olmalı.** Kapattıktan sonra aynı session'da tekrar gösterilmez.
4. **Prompt tonu:** "Yapamazsınız" değil, "Premium ile daha fazlasını yapın" tonu.
5. **Free tier kendi başına kullanışlı olmalı.** 3 defter + 15 AI mesaj + 5dk kayıt bir öğrenci için başlangıç olarak yeterli.
