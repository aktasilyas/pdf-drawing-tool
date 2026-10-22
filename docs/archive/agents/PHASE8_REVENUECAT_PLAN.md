# Phase 8 — RevenueCat Entegrasyonu

> **Bu doküman Phase 7 tamamlandıktan sonra uygulanır.**
> Önceki Phase'lerdeki FeatureGateService, UpgradePromptSheet, Paywall UI ve tüm gate logic'ler hazır olmalıdır.
> Bu Phase gerçek satın alma akışını aktif eder.

---

## Ön Hazırlık (Agent Değil, Geliştirici Yapacak)

Aşağıdaki adımlar RevenueCat Dashboard ve Store Console'larında manuel yapılır. Agent bu adımları atlayıp Adım 8.1'den başlar.

### A — RevenueCat Hesap & Proje Kurulumu

1. https://app.revenuecat.com adresinde hesap oluştur
2. Yeni proje oluştur: "ElyaNotes"
3. iOS App ekle → App Store Connect'ten Bundle ID ve App-Specific Shared Secret gir
4. Android App ekle → Google Play Console'dan package name ve Service Credentials JSON yükle
5. Dashboard'dan **API Keys** al:
   - iOS Public API Key: `appl_xxxxxxxxxx`
   - Android Public API Key: `goog_xxxxxxxxxx`

### B — App Store Connect'te Ürün Tanımlama (iOS)

Subscription Group: "ElyaNotes Premium" adıyla oluştur.

Ürünler:
- `elyanotes_premium_monthly` → ₺149.99/ay (Auto-Renewable)
- `elyanotes_premium_yearly` → ₺999.99/yıl (Auto-Renewable)
- `elyanotes_pro_monthly` → ₺299.99/ay (Auto-Renewable)
- `elyanotes_pro_yearly` → ₺1999.99/yıl (Auto-Renewable)

Her ürün için 7 günlük ücretsiz deneme (Introductory Offer) tanımla.

### C — Google Play Console'da Ürün Tanımlama (Android)

Aynı product ID'leri kullanarak Base Plan + Offer tanımla:
- `elyanotes_premium_monthly` → ₺149.99/ay, 7 gün free trial
- `elyanotes_premium_yearly` → ₺999.99/yıl, 7 gün free trial
- `elyanotes_pro_monthly` → ₺299.99/ay, 7 gün free trial
- `elyanotes_pro_yearly` → ₺1999.99/yıl, 7 gün free trial

### D — RevenueCat Dashboard Konfigürasyonu

**Entitlements:**
- `premium` → elyanotes_premium_monthly, elyanotes_premium_yearly ürünlerini ekle
- `pro` → elyanotes_pro_monthly, elyanotes_pro_yearly ürünlerini ekle

**Offerings:**
- "default" offering oluştur
- İçine 4 Package ekle:
  - `$rc_monthly` → elyanotes_premium_monthly
  - `$rc_annual` → elyanotes_premium_yearly
  - `pro_monthly` → elyanotes_pro_monthly
  - `pro_annual` → elyanotes_pro_yearly

### E — .env Dosyasına Key Ekle

```
REVENUECAT_APPLE_KEY=appl_xxxxxxxxxx
REVENUECAT_GOOGLE_KEY=goog_xxxxxxxxxx
```

---

## Adım 8.1 — purchases_flutter Paketini Ekle

**Dosya:** `example_app/pubspec.yaml`

**Değişiklik:** dependencies bloğuna ekle:

```yaml
dependencies:
  # ... mevcut dependencies ...
  purchases_flutter: ^8.0.0
```

Sonra çalıştır:
```bash
cd example_app && flutter pub get
```

**Android ek ayar:**

**Dosya:** `example_app/android/app/src/main/AndroidManifest.xml`

Billing permission ekle (application tag'inin dışına, manifest içine):
```xml
<uses-permission android:name="com.android.vending.BILLING" />
```

**Dosya:** `example_app/android/app/src/main/kotlin/.../MainActivity.kt`

FlutterActivity'yi FlutterFragmentActivity ile değiştir:

```kotlin
// ESKİ:
import io.flutter.embedding.android.FlutterActivity
class MainActivity: FlutterActivity()

// YENİ:
import io.flutter.embedding.android.FlutterFragmentActivity
class MainActivity: FlutterFragmentActivity()
```

**iOS ek ayar:**

Xcode'da proje aç → Target → Signing & Capabilities → "+ Capability" → "In-App Purchase" ekle.

### Doğrulama Kriterleri — 8.1
- [ ] `flutter pub get` hatasız tamamlanmalı
- [ ] `import 'package:purchases_flutter/purchases_flutter.dart';` çalışmalı
- [ ] Android'de BILLING permission eklenmiş olmalı
- [ ] MainActivity FlutterFragmentActivity'den extend etmeli

---

## Adım 8.2 — RevenueCat Servis Katmanı (Domain + Data)

### 8.2.1 — RevenueCat sabitleri

**Dosya (yeni):** `lib/features/premium/data/constants/revenuecat_constants.dart`

```dart
import 'dart:io';

/// RevenueCat konfigürasyon sabitleri.
abstract class RevenueCatConstants {
  /// Entitlement ID'leri — RevenueCat Dashboard'da tanımlanan.
  static const entitlementPremium = 'premium';
  static const entitlementPro = 'pro';

  /// Platform'a göre API key döndür.
  /// .env'den okunan değerler buraya inject edilecek.
  static String get apiKey {
    if (Platform.isIOS || Platform.isMacOS) {
      return const String.fromEnvironment(
        'REVENUECAT_APPLE_KEY',
        defaultValue: '',
      );
    }
    return const String.fromEnvironment(
      'REVENUECAT_GOOGLE_KEY',
      defaultValue: '',
    );
  }
}
```

**NOT:** Eğer projede `flutter_dotenv` ile env okuma yapılıyorsa (main.dart'ta `dotenv.load()` var), sabitleri dotenv üzerinden oku:

```dart
static String get apiKey {
  if (Platform.isIOS || Platform.isMacOS) {
    return dotenv.env['REVENUECAT_APPLE_KEY'] ?? '';
  }
  return dotenv.env['REVENUECAT_GOOGLE_KEY'] ?? '';
}
```

### 8.2.2 — Purchase repository interface

**Dosya (yeni):** `lib/features/premium/domain/repositories/purchase_repository.dart`

```dart
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:example_app/features/premium/domain/entities/subscription.dart';

/// Satın alma operasyonları için repository contract.
abstract class PurchaseRepository {
  /// RevenueCat SDK'yı initialize et.
  Future<void> initialize();

  /// Mevcut kullanıcının aktif tier'ını döndür.
  Future<SubscriptionTier> getCurrentTier();

  /// Tier değişikliklerini stream olarak dinle.
  Stream<SubscriptionTier> watchTierChanges();

  /// Mevcut offering'leri (ürün listesi) getir.
  Future<Offerings?> getOfferings();

  /// Bir package satın al.
  Future<bool> purchasePackage(Package package);

  /// Önceki satın almaları restore et.
  Future<SubscriptionTier> restorePurchases();

  /// Kullanıcının aktif abonelik bilgisini getir.
  Future<CustomerInfo> getCustomerInfo();

  /// Supabase user ID ile RevenueCat'i eşleştir.
  Future<void> loginUser(String userId);

  /// Çıkış yap.
  Future<void> logoutUser();
}
```

### 8.2.3 — Purchase repository implementation

**Dosya (yeni):** `lib/features/premium/data/repositories/purchase_repository_impl.dart`

```dart
import 'dart:async';
import 'dart:io';

import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:example_app/features/premium/data/constants/revenuecat_constants.dart';
import 'package:example_app/features/premium/domain/entities/subscription.dart';
import 'package:example_app/features/premium/domain/repositories/purchase_repository.dart';

class PurchaseRepositoryImpl implements PurchaseRepository {
  bool _initialized = false;

  @override
  Future<void> initialize() async {
    if (_initialized) return;

    final apiKey = RevenueCatConstants.apiKey;
    if (apiKey.isEmpty) {
      throw Exception('RevenueCat API key not configured');
    }

    final config = PurchasesConfiguration(apiKey);
    await Purchases.configure(config);
    _initialized = true;
  }

  @override
  Future<SubscriptionTier> getCurrentTier() async {
    final info = await Purchases.getCustomerInfo();
    return _mapCustomerInfoToTier(info);
  }

  @override
  Stream<SubscriptionTier> watchTierChanges() {
    return Purchases.customerInfoStream.map(_mapCustomerInfoToTier);
  }

  @override
  Future<Offerings?> getOfferings() async {
    return Purchases.getOfferings();
  }

  @override
  Future<bool> purchasePackage(Package package) async {
    try {
      await Purchases.purchasePackage(package);
      return true;
    } on PurchasesErrorCode catch (e) {
      if (e == PurchasesErrorCode.purchaseCancelledError) {
        return false; // Kullanıcı iptal etti, hata değil
      }
      rethrow;
    }
  }

  @override
  Future<SubscriptionTier> restorePurchases() async {
    final info = await Purchases.restorePurchases();
    return _mapCustomerInfoToTier(info);
  }

  @override
  Future<CustomerInfo> getCustomerInfo() async {
    return Purchases.getCustomerInfo();
  }

  @override
  Future<void> loginUser(String userId) async {
    await Purchases.logIn(userId);
  }

  @override
  Future<void> logoutUser() async {
    await Purchases.logOut();
  }

  /// RevenueCat CustomerInfo → SubscriptionTier mapping.
  SubscriptionTier _mapCustomerInfoToTier(CustomerInfo info) {
    final entitlements = info.entitlements.active;

    if (entitlements.containsKey(RevenueCatConstants.entitlementPro)) {
      return SubscriptionTier.premiumPlus;
    }
    if (entitlements.containsKey(RevenueCatConstants.entitlementPremium)) {
      return SubscriptionTier.premium;
    }
    return SubscriptionTier.free;
  }
}
```

### Doğrulama Kriterleri — 8.2
- [ ] Repository interface SOLID'e uygun olmalı (dependency inversion)
- [ ] `_mapCustomerInfoToTier` pro entitlement → premiumPlus, premium → premium, yoksa → free dönmeli
- [ ] `purchasePackage` kullanıcı iptalinde false dönmeli, exception fırlatmamalı
- [ ] Compile hatası olmamalı

---

## Adım 8.3 — Riverpod Provider'ları

**Dosya (yeni):** `lib/features/premium/presentation/providers/purchase_providers.dart`

```dart
import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:purchases_flutter/purchases_flutter.dart';

import 'package:example_app/features/premium/data/repositories/purchase_repository_impl.dart';
import 'package:example_app/features/premium/domain/entities/subscription.dart';
import 'package:example_app/features/premium/domain/repositories/purchase_repository.dart';

/// PurchaseRepository singleton provider.
final purchaseRepositoryProvider = Provider<PurchaseRepository>((ref) {
  return PurchaseRepositoryImpl();
});

/// Kullanıcının aktif subscription tier'ı — real-time stream.
/// Bu provider mevcut `currentTierProvider`'ı REPLACE edecek.
final subscriptionTierProvider =
    StreamProvider<SubscriptionTier>((ref) async* {
  final repo = ref.watch(purchaseRepositoryProvider);

  // İlk değeri hemen yayınla
  final currentTier = await repo.getCurrentTier();
  yield currentTier;

  // Sonra stream'i dinle
  yield* repo.watchTierChanges();
});

/// Mevcut offering'ler (ürün listesi ve fiyatlar).
final offeringsProvider = FutureProvider<Offerings?>((ref) async {
  final repo = ref.watch(purchaseRepositoryProvider);
  return repo.getOfferings();
});

/// Satın alma işlemi state'i.
final purchaseStateProvider =
    StateNotifierProvider<PurchaseNotifier, PurchaseState>((ref) {
  final repo = ref.watch(purchaseRepositoryProvider);
  return PurchaseNotifier(repo);
});

/// Satın alma durumu.
class PurchaseState {
  final bool isLoading;
  final String? error;
  final bool purchaseSuccess;

  const PurchaseState({
    this.isLoading = false,
    this.error,
    this.purchaseSuccess = false,
  });

  PurchaseState copyWith({
    bool? isLoading,
    String? error,
    bool? purchaseSuccess,
  }) {
    return PurchaseState(
      isLoading: isLoading ?? this.isLoading,
      error: error,
      purchaseSuccess: purchaseSuccess ?? this.purchaseSuccess,
    );
  }
}

/// Satın alma işlemlerini yöneten notifier.
class PurchaseNotifier extends StateNotifier<PurchaseState> {
  final PurchaseRepository _repo;

  PurchaseNotifier(this._repo) : super(const PurchaseState());

  /// Bir package satın al.
  Future<void> purchase(Package package) async {
    state = state.copyWith(isLoading: true, error: null, purchaseSuccess: false);

    try {
      final success = await _repo.purchasePackage(package);
      state = state.copyWith(
        isLoading: false,
        purchaseSuccess: success,
        error: success ? null : null, // İptal durumunda hata yok
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: _mapError(e),
      );
    }
  }

  /// Önceki satın almaları restore et.
  Future<void> restore() async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      await _repo.restorePurchases();
      state = state.copyWith(isLoading: false, purchaseSuccess: true);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Satın almalar geri yüklenemedi. Lütfen tekrar deneyin.',
      );
    }
  }

  String _mapError(dynamic error) {
    final msg = error.toString();
    if (msg.contains('StoreProblemError')) {
      return 'Mağaza bağlantısında sorun var. Lütfen tekrar deneyin.';
    }
    if (msg.contains('NetworkError')) {
      return 'İnternet bağlantınızı kontrol edin.';
    }
    return 'Satın alma işlemi başarısız. Lütfen tekrar deneyin.';
  }
}
```

### Doğrulama Kriterleri — 8.3
- [ ] `subscriptionTierProvider` stream olarak tier değişikliklerini yayınlamalı
- [ ] `offeringsProvider` RevenueCat'ten ürün listesini çekmeli
- [ ] `PurchaseNotifier` satın alma sırasında loading state yönetmeli
- [ ] Kullanıcı iptalinde error state olmamalı
- [ ] Compile hatası olmamalı

---

## Adım 8.4 — main.dart'ta RevenueCat Initialize

**Dosya:** `lib/main.dart`

**Değişiklik:** `main()` fonksiyonunda Supabase initialize'dan sonra RevenueCat'i de initialize et.

**Eklenecek import:**
```dart
import 'package:example_app/features/premium/data/repositories/purchase_repository_impl.dart';
```

**Eklenecek kod (Supabase initialize'dan sonra):**

```dart
// Initialize RevenueCat
try {
  final purchaseRepo = PurchaseRepositoryImpl();
  await purchaseRepo.initialize();
  logger.i('RevenueCat initialized');
} catch (e) {
  logger.e('RevenueCat init failed: $e');
  // RevenueCat init başarısız olsa bile uygulama çalışmaya devam etmeli
}
```

### Doğrulama Kriterleri — 8.4
- [ ] Uygulama açılışında "RevenueCat initialized" log'u görünmeli
- [ ] RevenueCat init başarısız olursa uygulama crash olmamalı
- [ ] API key boşsa exception fırlatılmalı ama catch edilmeli

---

## Adım 8.5 — Mevcut currentTierProvider'ı RevenueCat'e Bağla

**Dosya:** Projedeki mevcut `currentTierProvider` tanımının olduğu dosya (muhtemelen `lib/features/premium/presentation/providers/premium_providers.dart`)

**Değişiklik:** Mevcut hardcoded veya mock tier provider'ı, RevenueCat stream provider'ına bağla.

**ESKİ (tahmini — projedeki mevcut koda göre ayarla):**
```dart
final currentTierProvider = Provider<SubscriptionTier>((ref) {
  // Mock veya Supabase'den okunan tier
  return SubscriptionTier.free;
});
```

**YENİ:**
```dart
import 'package:example_app/features/premium/presentation/providers/purchase_providers.dart';

final currentTierProvider = Provider<SubscriptionTier>((ref) {
  final tierAsync = ref.watch(subscriptionTierProvider);
  return tierAsync.when(
    data: (tier) => tier,
    loading: () => SubscriptionTier.free, // Yüklenirken free varsay
    error: (_, __) => SubscriptionTier.free, // Hata durumunda free varsay
  );
});
```

**ÖNEMLİ:** Bu değişiklik tüm uygulamadaki premium kontrollerini otomatik olarak RevenueCat'e bağlar, çünkü FeatureGateService ve diğer tüm premium logic'ler `currentTierProvider`'a depend ediyor.

### Doğrulama Kriterleri — 8.5
- [ ] `currentTierProvider` artık RevenueCat'ten gerçek tier döndürmeli
- [ ] Satın alma yapılınca tüm uygulamadaki gate'ler otomatik açılmalı
- [ ] RevenueCat'e bağlanamadığında free tier varsayılmalı (graceful degradation)
- [ ] Mevcut FeatureGateService, AI rate limit ve diğer tüm kontroller çalışmaya devam etmeli

---

## Adım 8.6 — Paywall Ekranına Gerçek Satın Alma Bağla

**Dosya:** `lib/features/premium/presentation/screens/paywall_placeholder_screen.dart`

**Değişiklik:** Phase 7'de oluşturulan paywall ekranındaki "Premium'a Geç" butonlarını gerçek satın alma akışına bağla.

**Eklenecek logic:**

```dart
// Paywall widget'ı ConsumerStatefulWidget olmalı.

// offerings'i yükle:
final offerings = ref.watch(offeringsProvider);
final purchaseState = ref.watch(purchaseStateProvider);

// Ürünleri göster:
offerings.when(
  data: (offerings) {
    if (offerings == null || offerings.current == null) {
      return const Text('Ürünler yüklenemedi');
    }
    final packages = offerings.current!.availablePackages;
    // packages'ı plan kartlarına bağla
  },
  loading: () => const CircularProgressIndicator(),
  error: (e, _) => Text('Hata: $e'),
);

// Satın alma butonu:
void _onPurchase(Package package) {
  ref.read(purchaseStateProvider.notifier).purchase(package);
}

// Purchase success dinle:
ref.listen(purchaseStateProvider, (prev, next) {
  if (next.purchaseSuccess) {
    Navigator.pop(context);
    // Opsiyonel: Başarı mesajı göster
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Premium aktivasyonu başarılı!')),
    );
  }
  if (next.error != null) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(next.error!)),
    );
  }
});

// Loading overlay:
if (purchaseState.isLoading) {
  // Satın alma sırasında loading indicator göster
  // Butonları disable et
}
```

**Fiyat gösterimi — RevenueCat'ten lokalize fiyat al:**

```dart
// Package'dan lokalize fiyat string'i:
final priceString = package.storeProduct.priceString; // "₺149,99"
final title = package.storeProduct.title;
```

**Restore butonu — Paywall'ın altına ekle:**

```dart
TextButton(
  onPressed: () {
    ref.read(purchaseStateProvider.notifier).restore();
  },
  child: const Text('Satın Almayı Geri Yükle'),
),
```

**ÖNEMLİ — Apple Rejection Önleme:**
- "Satın Almayı Geri Yükle" butonu MUTLAKA görünür olmalı
- Fiyat bilgisi net ve okunabilir olmalı
- "İptal edilene kadar otomatik yenilenir" disclamer'ı olmalı
- Gizlilik politikası ve kullanım şartları linkleri olmalı

### Doğrulama Kriterleri — 8.6
- [ ] Paywall ekranında gerçek ürün fiyatları (RevenueCat'ten) gösterilmeli
- [ ] Satın alma butonu tıklandığında Store satın alma dialog'u açılmalı
- [ ] Satın alma başarılı olunca paywall kapanmalı ve tier güncellenimeli
- [ ] Kullanıcı iptal edince hata gösterilmemeli
- [ ] "Satın Almayı Geri Yükle" butonu çalışmalı
- [ ] Loading state doğru yönetilmeli
- [ ] Apple rejection checklist: Restore butonu ✅, fiyat bilgisi ✅, disclaimer ✅

---

## Adım 8.7 — Supabase User ID Eşleştirmesi

**Dosya:** Auth akışının olduğu dosya (login/register sonrası çağrılan yer)

**Açıklama:** Kullanıcı giriş yaptığında RevenueCat'e Supabase user ID'sini bildir. Bu, farklı cihazlarda aynı kullanıcının tier'ının senkron kalmasını sağlar.

**Login sonrası ekle:**

```dart
// Auth callback'te (login/register başarılı olduğunda):
final userId = Supabase.instance.client.auth.currentUser?.id;
if (userId != null) {
  final purchaseRepo = ref.read(purchaseRepositoryProvider);
  await purchaseRepo.loginUser(userId);
}
```

**Logout'ta ekle:**

```dart
// Logout callback'te:
final purchaseRepo = ref.read(purchaseRepositoryProvider);
await purchaseRepo.logoutUser();
```

### Doğrulama Kriterleri — 8.7
- [ ] Login sonrası RevenueCat'e user ID gönderilmeli
- [ ] Logout'ta RevenueCat'ten de çıkış yapılmalı
- [ ] Farklı cihazda aynı hesapla giriş yapınca tier korunmalı

---

## Adım 8.8 — Supabase Webhook (Backend Tier Sync)

### Amaç
RevenueCat'ten Supabase'e webhook ile tier güncellemesi gönder. Bu, Edge Function'ların (AI chat vs.) kullanıcının gerçek tier'ını bilmesini sağlar.

### 8.8.1 — Webhook Edge Function oluştur

**Dosya (yeni):** `supabase/functions/revenuecat-webhook/index.ts`

```typescript
import "jsr:@supabase/functions-js/edge-runtime.d.ts";
import { createClient } from "jsr:@supabase/supabase-js@2";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, content-type",
};

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  try {
    // RevenueCat webhook auth header doğrulama
    const authHeader = req.headers.get("authorization");
    const webhookSecret = Deno.env.get("REVENUECAT_WEBHOOK_SECRET");
    if (webhookSecret && authHeader !== `Bearer ${webhookSecret}`) {
      return new Response("Unauthorized", { status: 401 });
    }

    const event = await req.json();
    const eventType = event.event?.type;
    const appUserId = event.event?.app_user_id;

    if (!appUserId) {
      return new Response(JSON.stringify({ error: "Missing user ID" }), {
        status: 400,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      });
    }

    // Tier belirleme
    let tier = "free";
    const entitlements = event.event?.subscriber?.entitlements || {};

    if (entitlements.pro?.expires_date) {
      const proExpiry = new Date(entitlements.pro.expires_date);
      if (proExpiry > new Date()) tier = "premiumPlus";
    }
    if (tier === "free" && entitlements.premium?.expires_date) {
      const premiumExpiry = new Date(entitlements.premium.expires_date);
      if (premiumExpiry > new Date()) tier = "premium";
    }

    // Supabase'de kullanıcının tier'ını güncelle
    const supabase = createClient(
      Deno.env.get("SUPABASE_URL")!,
      Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!,
    );

    await supabase
      .from("user_profiles")
      .update({
        subscription_tier: tier,
        subscription_updated_at: new Date().toISOString(),
      })
      .eq("id", appUserId);

    console.log(`[Webhook] User ${appUserId}: ${eventType} → tier=${tier}`);

    return new Response(JSON.stringify({ success: true, tier }), {
      headers: { ...corsHeaders, "Content-Type": "application/json" },
    });
  } catch (error) {
    console.error("[Webhook] Error:", error);
    return new Response(JSON.stringify({ error: "Internal error" }), {
      status: 500,
      headers: { ...corsHeaders, "Content-Type": "application/json" },
    });
  }
});
```

### 8.8.2 — config.toml'a function ekle

**Dosya:** `supabase/config.toml`

```toml
[functions.revenuecat-webhook]
enabled = true
verify_jwt = false  # Webhook dışarıdan gelir, JWT yok
entrypoint = "./functions/revenuecat-webhook/index.ts"
```

### 8.8.3 — RevenueCat Dashboard'da webhook tanımla

1. RevenueCat Dashboard → Project Settings → Webhooks
2. URL: `https://YOUR_SUPABASE_URL/functions/v1/revenuecat-webhook`
3. Authorization Header: `Bearer YOUR_WEBHOOK_SECRET`
4. Events: INITIAL_PURCHASE, RENEWAL, CANCELLATION, EXPIRATION, BILLING_ISSUE, PRODUCT_CHANGE

### 8.8.4 — Secret ekle

```bash
supabase secrets set REVENUECAT_WEBHOOK_SECRET=whsec_your_secret_here
```

### Doğrulama Kriterleri — 8.8
- [ ] Webhook endpoint deploy edilmiş olmalı
- [ ] Satın alma sonrası user_profiles tablosunda tier güncellenmiş olmalı
- [ ] İptal/expiration durumunda tier "free"ye dönmeli
- [ ] Edge Function log'larında webhook event'leri görünmeli
- [ ] Unauthorized request'ler 401 dönmeli

---

## Özet — Phase 8 Bağımlılık Haritası

```
8.1 (Paket kurulum)         → Bağımsız, hemen başla
8.2 (Repository katmanı)    → 8.1 bitmeli
8.3 (Riverpod providers)    → 8.2 bitmeli
8.4 (main.dart init)        → 8.2 bitmeli
8.5 (currentTier bağlama)   → 8.3 + 8.4 bitmeli
8.6 (Paywall gerçek satış)  → 8.3 + 8.5 bitmeli
8.7 (User ID eşleştirme)    → 8.4 bitmeli
8.8 (Supabase webhook)      → 8.6 bitmeli, bağımsız deploy
```

## Test Akışı

### Sandbox Test (iOS)
1. App Store Connect → Users and Access → Sandbox Testers → yeni tester ekle
2. iPhone'da Settings → App Store → Sandbox Account ile giriş yap
3. Uygulamada satın alma yap → Sandbox dialog'u açılmalı
4. Sandbox'ta abonelik her 5 dakikada yenilenir (aylık simülasyon)

### Test (Android)
1. Google Play Console → Setup → License testing → test email'ini ekle
2. Uygulamada satın alma yap → "Test Card, Always Approves" seçeneği görünmeli

### Tam E2E Test Senaryosu
1. Free kullanıcı olarak giriş yap
2. 3 notebook oluştur → 4. notebook'ta upgrade prompt görmeli
3. Paywall'ı aç → Gerçek fiyatlar görünmeli
4. Premium satın al (sandbox) → Paywall kapanmalı
5. 4. notebook oluşturulabilmeli → Gate açılmış olmalı
6. AI mesaj limiti 150'ye yükselmeli
7. Ses kaydı limitsiz olmalı
8. Supabase'de user tier "premium" olmalı
