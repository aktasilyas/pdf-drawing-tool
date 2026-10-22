# PHASE 5 — STEP 4: Freemium Gating + Usage Tracking UI

## ÖZET
AI özelliklerini mevcut premium sisteme (RevenueCat) entegre et. Subscription tier'a göre model routing'i dinamik yap, usage tracking UI ekle, limit aşımında upgrade prompt göster. Bu step sonunda free/premium/premiumPlus kullanıcılar farklı AI modellere erişecek ve limitlerini görecek.

## BRANCH
```bash
git checkout -b feature/ai-freemium-gating
```

---

## MİMARİ KARARLAR

1. **Mevcut `subscriptionProvider` kullanılır** — yeni premium sistem oluşturulmaz
2. **AI provider'lar subscription'ı watch eder** — tier değişince otomatik güncellenir
3. **Upgrade prompt** — limit aşımında veya premium model istendiğinde gösterilir
4. **Usage bar** — AIChatModal header'ında günlük kullanım progress bar'ı
5. **Model badge** — Her AI yanıtında hangi modelin kullanıldığı gösterilir

---

## @flutter-developer — İMPLEMENTASYON

### BÖLÜM A: AI Provider'ları Subscription'a Bağla

**Önce oku:**
- `example_app/lib/features/premium/presentation/providers/subscription_provider.dart` — mevcut provider'lar
- `example_app/lib/features/premium/domain/entities/subscription.dart` — SubscriptionTier enum
- `example_app/lib/features/ai/presentation/providers/ai_providers.dart` — mevcut AI DI

**1) GÜNCELLE: `example_app/lib/features/ai/presentation/providers/ai_providers.dart`**

Sabit `SubscriptionTier.free` yerine gerçek subscription'ı watch et:

```dart
import 'package:example_app/features/premium/presentation/providers/subscription_provider.dart';

// ... mevcut importlar korunur ...

final aiRepositoryProvider = Provider<AIRepository>((ref) {
  final remote = ref.watch(aiRemoteDataSourceProvider);
  final local = ref.watch(aiLocalDataSourceProvider);

  // Gerçek subscription tier'ını al
  final subscription = ref.watch(subscriptionProvider);
  final tier = subscription.when(
    data: (sub) => sub.tier,
    loading: () => SubscriptionTier.free,
    error: (_, __) => SubscriptionTier.free,
  );

  return AIRepositoryImpl(
    remoteDataSource: remote,
    localDataSource: local,
    userTier: tier,
  );
});

/// Aktif kullanıcının AI tier'ı (UI'da göstermek için).
final aiTierProvider = Provider<SubscriptionTier>((ref) {
  final subscription = ref.watch(subscriptionProvider);
  return subscription.when(
    data: (sub) => sub.tier,
    loading: () => SubscriptionTier.free,
    error: (_, __) => SubscriptionTier.free,
  );
});

/// Aktif kullanıcının AI model adı (UI badge).
final aiModelNameProvider = Provider<String>((ref) {
  final tier = ref.watch(aiTierProvider);
  return switch (tier) {
    SubscriptionTier.free => 'Gemini Flash',
    SubscriptionTier.premium => 'GPT-4o mini',
    SubscriptionTier.premiumPlus => 'GPT-4o',
  };
});

/// AI tier'a göre günlük mesaj limiti.
final aiDailyLimitProvider = Provider<int>((ref) {
  final tier = ref.watch(aiTierProvider);
  return switch (tier) {
    SubscriptionTier.free => 15,
    SubscriptionTier.premium => 150,
    SubscriptionTier.premiumPlus => 1000,
  };
});
```

---

### BÖLÜM B: Usage Tracking Widget

**2) OLUŞTUR: `example_app/lib/features/ai/presentation/widgets/ai_usage_bar.dart`**

Günlük kullanım progress bar — AIChatModal header'ına eklenir.

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:example_app/features/ai/presentation/providers/ai_providers.dart';

/// Compact usage indicator showing daily AI message quota.
///
/// Displays as a thin progress bar with text like "5/15 mesaj".
/// Changes color from green → orange → red as limit approaches.
class AIUsageBar extends ConsumerWidget {
  const AIUsageBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final usageAsync = ref.watch(aiUsageProvider);
    final dailyLimit = ref.watch(aiDailyLimitProvider);
    final modelName = ref.watch(aiModelNameProvider);
    final theme = Theme.of(context);

    return usageAsync.when(
      data: (usage) {
        final used = usage.dailyMessagesUsed;
        final limit = usage.dailyMessagesLimit;
        final percent = limit > 0 ? (used / limit).clamp(0.0, 1.0) : 0.0;

        final color = percent < 0.6
            ? theme.colorScheme.primary
            : percent < 0.85
                ? Colors.orange
                : theme.colorScheme.error;

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  // Model badge
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      modelName,
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const Spacer(),
                  // Usage text
                  Text(
                    '$used / $limit mesaj',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: color,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              // Progress bar
              ClipRRect(
                borderRadius: BorderRadius.circular(2),
                child: LinearProgressIndicator(
                  value: percent,
                  minHeight: 3,
                  backgroundColor: theme.colorScheme.surfaceContainerHighest,
                  valueColor: AlwaysStoppedAnimation<Color>(color),
                ),
              ),
            ],
          ),
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }
}
```

---

### BÖLÜM C: Upgrade Prompt Dialog

**3) OLUŞTUR: `example_app/lib/features/ai/presentation/widgets/ai_upgrade_prompt.dart`**

Rate limit aşılınca veya premium özellik istenince gösterilen modal.

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:example_app/features/premium/domain/entities/subscription.dart';
import 'package:example_app/features/ai/presentation/providers/ai_providers.dart';

/// Shows an upgrade prompt when AI limits are reached or premium features requested.
class AIUpgradePrompt extends StatelessWidget {
  const AIUpgradePrompt({
    super.key,
    required this.reason,
    this.onUpgrade,
    this.onDismiss,
  });

  final AIUpgradeReason reason;
  final VoidCallback? onUpgrade;
  final VoidCallback? onDismiss;

  /// Show as a modal bottom sheet.
  static Future<void> show(
    BuildContext context, {
    required AIUpgradeReason reason,
    VoidCallback? onUpgrade,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => AIUpgradePrompt(
        reason: reason,
        onUpgrade: onUpgrade,
        onDismiss: () => Navigator.of(context).pop(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final config = _getConfig(reason);

    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Icon
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    theme.colorScheme.primary,
                    theme.colorScheme.secondary,
                  ],
                ),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.auto_awesome, color: Colors.white, size: 28),
            ),
            const SizedBox(height: 16),
            // Title
            Text(
              config.title,
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w700,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            // Description
            Text(
              config.description,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            // Features list
            ...config.features.map((feature) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                children: [
                  Icon(Icons.check_circle,
                      size: 20, color: theme.colorScheme.primary),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(feature, style: theme.textTheme.bodyMedium),
                  ),
                ],
              ),
            )),
            const SizedBox(height: 24),
            // CTA button
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: onUpgrade,
                icon: const Icon(Icons.star),
                label: Text(config.ctaText),
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            // Dismiss
            TextButton(
              onPressed: onDismiss,
              child: Text(config.dismissText),
            ),
          ],
        ),
      ),
    );
  }

  _UpgradeConfig _getConfig(AIUpgradeReason reason) {
    return switch (reason) {
      AIUpgradeReason.dailyLimitReached => const _UpgradeConfig(
        title: 'Günlük Limitine Ulaştın',
        description: 'Premium\'a yükselterek daha fazla AI mesajı gönder ve güçlü modellere eriş.',
        features: [
          'Günde 150 mesaj (15 yerine)',
          'GPT-4o mini ile daha akıllı yanıtlar',
          'Gelişmiş matematik çözümü',
          'Görsel analiz',
        ],
        ctaText: 'Premium\'a Yükselt',
        dismissText: 'Yarın tekrar dene',
      ),
      AIUpgradeReason.premiumModelRequested => const _UpgradeConfig(
        title: 'Premium Model Gerekli',
        description: 'Bu özellik premium AI modelleri gerektirir.',
        features: [
          'GPT-4o ile ileri düzey analiz',
          'Karmaşık matematik problemleri',
          'Daha doğru el yazısı tanıma',
          'Öncelikli yanıt süresi',
        ],
        ctaText: 'Premium\'a Yükselt',
        dismissText: 'Ücretsiz model ile devam',
      ),
      AIUpgradeReason.advancedFeature => const _UpgradeConfig(
        title: 'Pro Özellik',
        description: 'Bu özellik Pro abonelere özeldir.',
        features: [
          'Sınırsız AI mesajı',
          'GPT-4o ve o4-mini erişimi',
          'Flashcard oluşturma',
          'Sınav hazırlık modu',
        ],
        ctaText: 'Pro\'ya Yükselt',
        dismissText: 'Daha sonra',
      ),
    };
  }
}

/// Reason for showing upgrade prompt.
enum AIUpgradeReason {
  dailyLimitReached,
  premiumModelRequested,
  advancedFeature,
}

class _UpgradeConfig {
  final String title;
  final String description;
  final List<String> features;
  final String ctaText;
  final String dismissText;

  const _UpgradeConfig({
    required this.title,
    required this.description,
    required this.features,
    required this.ctaText,
    required this.dismissText,
  });
}
```

---

### BÖLÜM D: AIChatModal'ı Güncelle

**4) GÜNCELLE: `example_app/lib/features/ai/presentation/screens/ai_chat_modal.dart`**

Değişiklikler:

1. Header'a `AIUsageBar` ekle (divider'dan hemen önce)
2. Mesaj gönderirken limit kontrolü yap — aşıldıysa `AIUpgradePrompt` göster
3. Input bar'a dinamik model ismi ve kalan mesaj sayısı ver
4. AI yanıt bubble'larına model badge ekle

Yapılacak güncellemeler:

```dart
// Import ekle
import 'package:example_app/features/ai/presentation/widgets/ai_usage_bar.dart';
import 'package:example_app/features/ai/presentation/widgets/ai_upgrade_prompt.dart';

// Header ile divider arasına ekle:
const AIUsageBar(),
const Divider(height: 1),

// _handleSend metodunu güncelle:
void _handleSend(String text) {
  final canSend = ref.read(canSendAIMessageProvider);
  if (!canSend) {
    AIUpgradePrompt.show(
      context,
      reason: AIUpgradeReason.dailyLimitReached,
      onUpgrade: () {
        Navigator.of(context).pop(); // Upgrade prompt'u kapat
        // TODO: Premium sayfasına yönlendir
      },
    );
    return;
  }
  ref.read(aiChatProvider.notifier).sendMessage(text);
  _scrollToBottom();
}

// _handleCanvasCapture'ı da aynı şekilde güncelle (canSend kontrolü ekle)

// AIInputBar'ı güncelle:
AIInputBar(
  onSend: _handleSend,
  onAttachCanvas: _handleCanvasCapture,
  isStreaming: chatState.isStreaming,
  enabled: ref.watch(canSendAIMessageProvider),
  remainingMessages: ref.watch(remainingAIMessagesProvider),
  modelName: ref.watch(aiModelNameProvider),
),
```

5. Mesaj gönderildikten sonra usage'ı yenile:
```dart
// _send tamamlandığında (onDone'da veya stream bitince):
ref.invalidate(aiUsageProvider);
```

AIChatNotifier'da sendMessage/sendWithCanvas sonrası bir callback ile ya da listen ile yap. En basit yol: `ai_chat_modal.dart`'ta `ref.listen(aiChatProvider, ...)` içinde isStreaming false olunca invalidate etmek:

```dart
ref.listen(aiChatProvider, (prev, next) {
  // Stream bitti — usage'ı yenile
  if (prev?.isStreaming == true && !next.isStreaming) {
    ref.invalidate(aiUsageProvider);
  }
  // Auto-scroll
  if (next.isStreaming || next.messages.length != (prev?.messages.length ?? 0)) {
    _scrollToBottom();
  }
});
```

---

### BÖLÜM E: Edge Function'da Tier Bilgisini Kullan

**5) GÜNCELLE: `supabase/functions/ai-chat/index.ts`**

Mevcut Edge Function'da `tier` sabit "free" olarak hardcoded. Bunu Supabase'den çekelim.

Profiles tablosuna `subscription_tier` kolonu eklemek yerine, basit bir yaklaşım: Flutter'dan tier bilgisini request body'de gönder. Edge Function bunu güvenilir kabul eder çünkü zaten JWT ile authenticate edilmiş. Daha güvenli yaklaşım (server-side tier check) ileride RevenueCat webhook ile yapılacak.

Flutter tarafında — `ai_remote_datasource.dart`'taki `chat()` metoduna tier parametresi ekle:

```dart
// AIRemoteDataSource.chat() — body'ye tier ekle
final body = jsonEncode({
  'messages': messages,
  'taskType': taskType,
  'conversationId': conversationId,
  'tier': tier, // ← YENİ
  if (imageBase64 != null) 'image': imageBase64,
});
```

`AIRepositoryImpl.sendMessage()` → `_remoteDataSource.chat()` çağrısına tier geç:

```dart
// AIRepositoryImpl'de tier'ı string'e çevir
String get _tierString => switch (_userTier) {
  SubscriptionTier.free => 'free',
  SubscriptionTier.premium => 'premium',
  SubscriptionTier.premiumPlus => 'premiumPlus',
};
```

Edge Function'da `tier`'ı request body'den al:
```typescript
// Mevcut hardcoded tier'ı değiştir:
// const tier: UserTier = "free";

// Yenisi:
const { messages, taskType = "chat", conversationId, image, tier: requestTier } = await req.json();
const tier: UserTier = (requestTier === "premium" || requestTier === "premiumPlus") 
  ? requestTier 
  : "free";
```

---

### BÖLÜM F: Barrel Export Güncellemeleri

**6) GÜNCELLE: `example_app/lib/features/ai/presentation/widgets/ai_widgets.dart`**

```dart
export 'ai_chat_bubble.dart';
export 'ai_input_bar.dart';
export 'ai_streaming_bubble.dart';
export 'ai_conversation_list.dart';
export 'ai_usage_bar.dart';
export 'ai_upgrade_prompt.dart';
```

---

### BÖLÜM G: Doğrulama

**7) Analyze & Test:**
```bash
cd example_app && flutter analyze
```

**8) Edge Function redeploy:**
```bash
supabase functions deploy ai-chat
```

**9) Dosya yapısını doğrula:**
```
Yeni dosyalar:
  presentation/widgets/ai_usage_bar.dart         ← YENİ
  presentation/widgets/ai_upgrade_prompt.dart     ← YENİ

Güncellenen dosyalar:
  presentation/providers/ai_providers.dart        ← subscription entegrasyonu
  presentation/screens/ai_chat_modal.dart         ← usage bar + limit check
  presentation/widgets/ai_widgets.dart            ← barrel export
  data/datasources/ai_remote_datasource.dart      ← tier parametresi
  data/repositories/ai_repository_impl.dart       ← tier string geçirme
  supabase/functions/ai-chat/index.ts             ← dinamik tier
```

---

## KURALLAR
- Her dosya max 300 satır
- Mevcut premium provider'ları kullan, yenisini oluşturma
- `subscriptionProvider` StreamProvider — `.when()` ile handle et
- Upgrade prompt'ta fiyat hardcode etme — sadece özellik listesi göster
- Usage refresh: invalidate pattern kullan, polling yapma
- withValues(alpha:) kullan, withOpacity() değil

## TEST KRİTERLERİ
- [ ] `flutter analyze` temiz
- [ ] Free user → Gemini Flash model badge görünüyor
- [ ] Free user → 15 mesaj limiti gösteriliyor
- [ ] 15 mesaj sonrası upgrade prompt açılıyor
- [ ] Upgrade prompt dismiss edilebiliyor
- [ ] Usage bar rengi kullanıma göre değişiyor (yeşil → turuncu → kırmızı)
- [ ] Mesaj gönderildikten sonra usage sayısı güncelleniyor
- [ ] Edge Function tier parametresini alıyor ve doğru model seçiyor
- [ ] Dark mode uyumlu
- [ ] Tablet ve telefonda responsive

## COMMIT
```
feat(ai): add freemium gating + usage tracking UI

- Integrate AI providers with subscription system (RevenueCat)
- Dynamic model routing based on subscription tier
- AIUsageBar — daily quota progress indicator
- AIUpgradePrompt — upgrade modal for limit/premium features
- Pass tier to Edge Function for server-side model selection
- Auto-refresh usage after message send
- Free: Gemini Flash (15/day), Premium: GPT-4o-mini (150/day), Pro: GPT-4o (1000/day)
```

## SONRAKİ ADIMLAR (Step 5-7, ileride)
- Step 5: Conversation auto-title (AI ile sohbet başlığı oluştur)
- Step 6: LaTeX rendering iyileştirme (flutter_math_fork entegrasyonu)
- Step 7: Flashcard generation, summarization, advanced features
