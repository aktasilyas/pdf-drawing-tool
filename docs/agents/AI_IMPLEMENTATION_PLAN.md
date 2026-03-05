# AI Altyapısı İyileştirme Planı — Elyanotes

> **Bu doküman bir AI Agent tarafından okunup adım adım uygulanmak üzere hazırlanmıştır.**
> Her phase bağımsızdır. Bir phase tamamlanmadan diğerine geçilmez.
> Her adımda hangi dosyanın değişeceği, ne yapılacağı ve doğrulama kriterleri açıkça belirtilmiştir.

---

## Mevcut Sorunlar

1. **Context Loss (Bağlam Kaybı):** `AIRepositoryImpl.sendMessage()` backend'e sadece son mesajı gönderiyor. Kullanıcı devam sorusu sorduğunda AI önceki mesajları bilmiyor.
2. **Model Stratejisi:** Tüm tier'larda GPT-4o-mini / GPT-4o kullanılıyor. Daha ucuz ve daha iyi ücretsiz alternatifler mevcut. Task-based routing yok.

---

## Phase 1 — Context Fix (Bağlam Düzeltmesi)

### Amaç
Kullanıcı bir sohbette ardışık sorular sorduğunda AI'ın önceki mesajları hatırlamasını sağla.

### Kök Neden
`ai_repository_impl.dart` → `sendMessage()` metodu `_remoteDataSource.chat()` çağrısında messages array'ine sadece son kullanıcı mesajını koyuyor. Geçmiş mesajlar hiç gönderilmiyor.

### Adım 1.1 — `_buildChatHistory` helper metodu ekle

**Dosya:** `lib/features/ai/data/repositories/ai_repository_impl.dart`

**Konum:** Class'ın private metodları arasına (örn. `_mapTaskType` yanına) ekle.

```dart
/// Conversation geçmişini OpenAI messages formatına çevirir.
/// Token tasarrufu için son [maxMessages] mesaj alınır.
/// Görüntü içeren mesajlardaki image verisi dahil EDİLMEZ (token şişmesini önler).
List<Map<String, dynamic>> _buildChatHistory(
  List<AIMessage> messages, {
  int maxMessages = 20,
}) {
  final recent = messages.length > maxMessages
      ? messages.sublist(messages.length - maxMessages)
      : messages;

  return recent.map((msg) {
    return {
      'role': msg.role == MessageRole.user ? 'user' : 'assistant',
      'content': msg.content,
    };
  }).toList();
}
```

### Adım 1.2 — `sendMessage()` metodunu güncelle

**Dosya:** `lib/features/ai/data/repositories/ai_repository_impl.dart`

**Değişiklik:** `sendMessage()` metodunun `_remoteDataSource.chat()` çağrısından ÖNCE geçmişi çek ve messages parametresini değiştir.

**ESKİ KOD (silinecek / değiştirilecek):**
```dart
// 2. Stream from remote
final buffer = StringBuffer();
await for (final chunk in _remoteDataSource.chat(
  messages: [
    {'role': 'user', 'content': message},
  ],
  taskType: _mapTaskType(taskType),
  conversationId: conversationId,
  tier: _tierString,
  imageBase64: imageBase64,
)) {
  buffer.write(chunk);
  yield chunk;
}
```

**YENİ KOD (yerine konacak):**
```dart
// 2. Tüm geçmişi local DB'den çek (yeni eklenen mesaj dahil)
final history = await _localDataSource.getMessages(conversationId);

// 3. OpenAI chat format'ına çevir
final chatMessages = _buildChatHistory(history, maxMessages: 20);

// 4. Stream from remote — artık TÜM geçmiş gidiyor
final buffer = StringBuffer();
await for (final chunk in _remoteDataSource.chat(
  messages: chatMessages,
  taskType: _mapTaskType(taskType),
  conversationId: conversationId,
  tier: _tierString,
  imageBase64: imageBase64,
)) {
  buffer.write(chunk);
  yield chunk;
}
```

### Adım 1.3 — Image mesajlarında geçmişe image ekleme

**Dosya:** `lib/features/ai/data/repositories/ai_repository_impl.dart`

**Açıklama:** `_buildChatHistory` sadece text content gönderiyor. Image varsa, sadece SON mesajın image'ını eklemek backend'in (`ai-chat/index.ts`) işi — orada zaten `image` parametresi ayrıca gönderiliyor. Bu yapı korunuyor, ek değişiklik gerekmez.

### Doğrulama Kriterleri — Phase 1

- [ ] Bir sohbette "Benim adım Ali" yaz, ardından "Benim adım neydi?" sor → AI "Ali" diye cevap vermeli
- [ ] 20'den fazla mesajlık bir sohbette son 20 mesaj gönderilmeli, eski mesajlar kesilmeli
- [ ] Image gönderilen mesajlarda geçmiş text olarak gitmeli, image sadece son mesajda olmalı
- [ ] Yeni sohbet başlatıldığında geçmiş sıfırlanmalı (zaten yeni conversationId ile çalışıyor)

---

## Phase 2 — DeepSeek Provider Ekleme (Backend)

### Amaç
Edge function'a DeepSeek V3.2 desteği ekle. Premium tier için hazırlık.

### Adım 2.1 — Provider type'ını genişlet

**Dosya:** `supabase/functions/ai-chat/index.ts`

**Değişiklik:** `ModelConfig` interface'indeki provider union type'ına `"deepseek"` ekle.

**ESKİ:**
```typescript
interface ModelConfig {
  provider: "openai" | "google";
  model: string;
  maxTokens: number;
  temperature: number;
}
```

**YENİ:**
```typescript
interface ModelConfig {
  provider: "openai" | "google" | "deepseek";
  model: string;
  maxTokens: number;
  temperature: number;
}
```

### Adım 2.2 — `callDeepSeek` fonksiyonu ekle

**Dosya:** `supabase/functions/ai-chat/index.ts`

**Konum:** `callGemini` fonksiyonunun hemen altına ekle.

```typescript
async function callDeepSeek(
  config: ModelConfig,
  messages: Array<{ role: string; content: any }>,
): Promise<Response> {
  const apiKey = Deno.env.get("DEEPSEEK_API_KEY");
  if (!apiKey) throw new Error("DEEPSEEK_API_KEY not set");

  return fetch("https://api.deepseek.com/chat/completions", {
    method: "POST",
    headers: {
      Authorization: `Bearer ${apiKey}`,
      "Content-Type": "application/json",
    },
    body: JSON.stringify({
      model: config.model,
      messages,
      max_tokens: config.maxTokens,
      temperature: config.temperature,
      stream: true,
    }),
  });
}
```

### Adım 2.3 — Provider routing'e DeepSeek ekle

**Dosya:** `supabase/functions/ai-chat/index.ts`

**Değişiklik:** AI provider çağrısının yapıldığı bölümde (yaklaşık satır 130–145 civarı) `if/else` bloğuna DeepSeek case'i ekle.

**ESKİ:**
```typescript
if (config.provider === "openai") {
  aiResponse = await callOpenAI(config, processedMessages);
  transformer = createOpenAIToSSETransformer();
} else {
  aiResponse = await callGemini(config, processedMessages);
  transformer = createGeminiToSSETransformer();
}
```

**YENİ:**
```typescript
if (config.provider === "openai") {
  aiResponse = await callOpenAI(config, processedMessages);
  transformer = createOpenAIToSSETransformer();
} else if (config.provider === "deepseek") {
  // DeepSeek, OpenAI-compatible API kullanır — aynı SSE format
  aiResponse = await callDeepSeek(config, processedMessages);
  transformer = createOpenAIToSSETransformer();
} else {
  aiResponse = await callGemini(config, processedMessages);
  transformer = createGeminiToSSETransformer();
}
```

### Adım 2.4 — Supabase secrets'a DEEPSEEK_API_KEY ekle

**Komut (terminal):**
```bash
supabase secrets set DEEPSEEK_API_KEY=sk-xxxxxxxxxxxxxxxx
```

**Not:** DeepSeek API key'i https://platform.deepseek.com adresinden alınır.

### Doğrulama Kriterleri — Phase 2

- [ ] `selectModel` fonksiyonunda tier="premium", task="chat" döndüğünde provider "deepseek" olmalı (Phase 3'te güncellenecek ama şimdi manuel test edilebilir)
- [ ] DeepSeek API'ye streaming request atılabilmeli
- [ ] SSE response'u OpenAI transformer ile parse edilebilmeli
- [ ] DEEPSEEK_API_KEY secret olarak set edilmiş olmalı

---

## Phase 3 — Model Routing Güncelleme (selectModel)

### Amaç
Her tier için en uygun modeli task type'a göre route et.

### Adım 3.1 — `selectModel` fonksiyonunu değiştir

**Dosya:** `supabase/functions/ai-chat/index.ts`

**Değişiklik:** Mevcut `selectModel` fonksiyonunun TAMAMINI aşağıdakiyle değiştir.

```typescript
function selectModel(task: TaskType, tier: UserTier): ModelConfig {
  // ─── FREE TIER ────────────────────────────────────
  // Gemini 2.5 Flash-Lite: Ücretsiz, vision destekli, 1M context
  // Maliyet: $0 (free tier limitleri dahilinde)
  if (tier === "free") {
    return {
      provider: "google",
      model: "gemini-2.5-flash-lite",
      maxTokens: task.startsWith("summarize") ? 2048 : 1024,
      temperature: task.includes("math") || task.includes("ocr") ? 0.2 : 0.7,
    };
  }

  // ─── PREMIUM TIER ─────────────────────────────────
  // OCR → Gemini 2.5 Flash (vision gerekli, $0.30/$2.50 per MTok)
  // Text/Math → DeepSeek V3.2 ($0.28/$0.42 per MTok, 97.3% MATH-500)
  if (tier === "premium") {
    if (task.includes("ocr")) {
      return {
        provider: "google",
        model: "gemini-2.5-flash",
        maxTokens: 4096,
        temperature: 0.2,
      };
    }
    return {
      provider: "deepseek",
      model: "deepseek-chat",
      maxTokens: task.includes("math") ? 8192 : 4096,
      temperature: task.includes("math") ? 0.2 : 0.7,
    };
  }

  // ─── PREMIUM PLUS (PRO) TIER ──────────────────────
  // OCR → Gemini 2.5 Flash (Pro'da da Gemini, Qwen opsiyonel)
  // Math → DeepSeek reasoner mode (en iyi matematik performansı)
  // Chat → GPT-5-mini (genel amaçlı, çok dilli)
  if (task.includes("ocr")) {
    return {
      provider: "google",
      model: "gemini-2.5-flash",
      maxTokens: 4096,
      temperature: 0.2,
    };
  }
  if (task.includes("math")) {
    return {
      provider: "deepseek",
      model: "deepseek-reasoner",
      maxTokens: 8192,
      temperature: 0.2,
    };
  }
  // Summarize → Gemini Flash (1M context — uzun dokümanlar için ideal)
  if (task.startsWith("summarize")) {
    return {
      provider: "google",
      model: "gemini-2.5-flash",
      maxTokens: 4096,
      temperature: 0.3,
    };
  }
  // Default chat → GPT-5-mini
  return {
    provider: "openai",
    model: "gpt-5-mini",
    maxTokens: 4096,
    temperature: 0.7,
  };
}
```

### Adım 3.2 — Gemini model adını güncelle (free tier)

**Dosya:** `supabase/functions/ai-chat/index.ts`

**Açıklama:** Gemini API endpoint'inde model adı URL'ye gömülü. `callGemini` fonksiyonundaki URL zaten `config.model` kullanıyor:
```
`https://generativelanguage.googleapis.com/v1beta/models/${config.model}:streamGenerateContent?alt=sse&key=${apiKey}`
```
Bu doğru. `gemini-2.5-flash-lite` ve `gemini-2.5-flash` model string'leri Google API tarafından kabul ediliyor. Ek değişiklik gerekmez.

### Adım 3.3 — Paywall ekranındaki özellikleri güncelle

**Dosya:** `lib/features/premium/presentation/screens/paywall_placeholder_screen.dart`

**Değişiklik:** `_PlanData` kartlarındaki feature listelerini yeni modellere göre güncelle.

**ESKİ (Free kartı):**
```dart
_PlanData(
  title: 'Free',
  features: [
    '15 AI mesaj/gun',
    'Gemini Flash',
    'Temel OCR',
  ],
  ...
),
```

**YENİ:**
```dart
_PlanData(
  title: 'Free',
  features: [
    '15 AI mesaj/gun',
    'Gemini 2.5 Flash-Lite',
    'Temel OCR & gorsel analiz',
  ],
  ...
),
```

**ESKİ (Premium kartı):**
```dart
_PlanData(
  title: 'Premium',
  features: [
    '150 AI mesaj/gun',
    'GPT-4o mini',
    'Gorsel analiz',
    'Matematik cozme',
  ],
  ...
),
```

**YENİ:**
```dart
_PlanData(
  title: 'Premium',
  features: [
    '150 AI mesaj/gun',
    'DeepSeek V3 + Gemini Flash',
    'Gelismis gorsel analiz',
    'Ileri matematik cozme',
  ],
  ...
),
```

**ESKİ (Pro kartı):**
```dart
_PlanData(
  title: 'Pro',
  features: [
    '1000 AI mesaj/gun',
    'GPT-4o',
    'Ileri analiz',
    'Flashcard',
  ],
  ...
),
```

**YENİ:**
```dart
_PlanData(
  title: 'Pro',
  features: [
    '1000 AI mesaj/gun',
    'GPT-5 mini + DeepSeek Reasoner',
    'Premium OCR & analiz',
    'Flashcard olusturma',
  ],
  ...
),
```

### Doğrulama Kriterleri — Phase 3

- [ ] Free kullanıcı mesaj gönderdiğinde Gemini 2.5 Flash-Lite kullanılmalı
- [ ] Premium kullanıcı "chat" gönderdiğinde DeepSeek V3.2 kullanılmalı
- [ ] Premium kullanıcı image gönderdiğinde Gemini 2.5 Flash kullanılmalı
- [ ] Pro kullanıcı matematik sorusu sorduğunda DeepSeek Reasoner kullanılmalı
- [ ] Pro kullanıcı genel sohbet yaptığında GPT-5-mini kullanılmalı
- [ ] Paywall ekranında yeni model isimleri görünmeli

---

## Phase 4 — Groq Fallback Mekanizması (Free Tier)

### Amaç
Gemini free tier rate limit'e ulaştığında otomatik olarak Groq (Llama 4 Scout) üzerinden devam et.

### Adım 4.1 — `callGroq` fonksiyonu ekle

**Dosya:** `supabase/functions/ai-chat/index.ts`

**Konum:** `callDeepSeek` fonksiyonunun altına ekle.

```typescript
async function callGroq(
  config: ModelConfig,
  messages: Array<{ role: string; content: any }>,
): Promise<Response> {
  const apiKey = Deno.env.get("GROQ_API_KEY");
  if (!apiKey) throw new Error("GROQ_API_KEY not set");

  return fetch("https://api.groq.com/openai/v1/chat/completions", {
    method: "POST",
    headers: {
      Authorization: `Bearer ${apiKey}`,
      "Content-Type": "application/json",
    },
    body: JSON.stringify({
      model: config.model,
      messages,
      max_tokens: config.maxTokens,
      temperature: config.temperature,
      stream: true,
    }),
  });
}
```

### Adım 4.2 — ModelConfig'e `"groq"` provider ekle

**Dosya:** `supabase/functions/ai-chat/index.ts`

```typescript
interface ModelConfig {
  provider: "openai" | "google" | "deepseek" | "groq";
  model: string;
  maxTokens: number;
  temperature: number;
}
```

### Adım 4.3 — Fallback config fonksiyonu ekle

**Dosya:** `supabase/functions/ai-chat/index.ts`

**Konum:** `selectModel` fonksiyonunun altına ekle.

```typescript
/// Free tier fallback: Gemini başarısız olursa Groq Llama 4 Scout'a düş.
function getFallbackModel(originalConfig: ModelConfig): ModelConfig | null {
  if (originalConfig.provider === "google") {
    return {
      provider: "groq",
      model: "meta-llama/llama-4-scout-17b-16e-instruct",
      maxTokens: originalConfig.maxTokens,
      temperature: originalConfig.temperature,
    };
  }
  return null; // Diğer provider'lar için fallback yok
}
```

### Adım 4.4 — Provider routing'e fallback mekanizması ekle

**Dosya:** `supabase/functions/ai-chat/index.ts`

**Değişiklik:** AI provider çağrısı yapılan blokta, Gemini 429/5xx döndüğünde fallback'e düşen retry logic ekle.

**Mevcut provider routing bloğunu (Phase 2'de güncellenen) aşağıdakiyle DEĞİŞTİR:**

```typescript
// ─── Provider Call with Fallback ────────────────────
let aiResponse: Response;
let transformer: TransformStream<Uint8Array, Uint8Array>;

async function callProvider(cfg: ModelConfig, msgs: typeof processedMessages) {
  if (cfg.provider === "openai") {
    return { response: await callOpenAI(cfg, msgs), transformer: createOpenAIToSSETransformer() };
  } else if (cfg.provider === "deepseek") {
    return { response: await callDeepSeek(cfg, msgs), transformer: createOpenAIToSSETransformer() };
  } else if (cfg.provider === "groq") {
    return { response: await callGroq(cfg, msgs), transformer: createOpenAIToSSETransformer() };
  } else {
    return { response: await callGemini(cfg, msgs), transformer: createGeminiToSSETransformer() };
  }
}

let result = await callProvider(config, processedMessages);
aiResponse = result.response;
transformer = result.transformer;

// Fallback: Primary provider başarısız olursa
if (!aiResponse.ok) {
  const fallback = getFallbackModel(config);
  if (fallback) {
    console.warn(`Primary provider ${config.provider}/${config.model} failed (${aiResponse.status}), falling back to ${fallback.provider}/${fallback.model}`);
    result = await callProvider(fallback, processedMessages);
    aiResponse = result.response;
    transformer = result.transformer;
  }
}

if (!aiResponse.ok) {
  const errorBody = await aiResponse.text();
  console.error(`AI provider error:`, errorBody);
  return new Response(
    JSON.stringify({ error: "ai_provider_error", details: `Provider returned ${aiResponse.status}` }),
    { status: 502, headers: { ...corsHeaders, "Content-Type": "application/json" } },
  );
}
```

### Adım 4.5 — Supabase secrets'a GROQ_API_KEY ekle

**Komut (terminal):**
```bash
supabase secrets set GROQ_API_KEY=gsk_xxxxxxxxxxxxxxxx
```

**Not:** Groq API key'i https://console.groq.com adresinden alınır. Free tier mevcuttur.

### Doğrulama Kriterleri — Phase 4

- [ ] Gemini rate limit (429) döndüğünde otomatik olarak Groq'a fallback yapılmalı
- [ ] Groq Llama 4 Scout üzerinden streaming response alınmalı
- [ ] Groq response'u OpenAI transformer ile doğru parse edilmeli
- [ ] Fallback yapıldığında console.warn log'u görünmeli
- [ ] Premium/Pro tier'da fallback çalışmamalı (sadece free tier Gemini için)

---

## Phase 5 — Token Optimizasyonu ve Türkçe İyileştirmeler

### Amaç
Token maliyetini düşür, Türkçe yanıt kalitesini artır.

### Adım 5.1 — System prompt'u modele göre özelleştir

**Dosya:** `supabase/functions/ai-chat/index.ts`

**Değişiklik:** Sabit system prompt yerine, modele göre optimize edilmiş prompt kullan.

**Konum:** `const systemPrompt = { ... }` bloğunu aşağıdakiyle değiştir:

```typescript
function buildSystemPrompt(config: ModelConfig, task: TaskType): { role: string; content: string } {
  const base = `Sen Elyanotes yapay zeka asistanısın. Kullanıcılara not alma, çalışma ve öğrenme konularında yardımcı oluyorsun.`;

  const rules = `
Kurallar:
- Kısa ve öz yanıtlar ver
- Matematik sorularında adım adım çözüm göster
- LaTeX formülleri için $...$ (inline) ve $$...$$ (block) kullan
- Türkçe yanıt ver (kullanıcı başka dilde yazarsa o dilde yanıtla)
- Eğitim odaklı ol, sadece cevap verme, açıkla`;

  // DeepSeek math modunda: İngilizce düşün, Türkçe yanıtla
  // (DeepSeek Türkçe'de ~15-20% performans kaybı yaşıyor)
  if (config.provider === "deepseek" && task.includes("math")) {
    return {
      role: "system",
      content: `${base}\n${rules}\n\nÖNEMLİ: Matematik çözümlerinde İNGİLİZCE düşün ve hesapla, ama TÜRKÇE açıkla. Bu doğruluğu artırır.`,
    };
  }

  // OCR modunda: Yapılandırılmış çıktı iste
  if (task.includes("ocr")) {
    return {
      role: "system",
      content: `${base}\n${rules}\n\nGörüntüdeki metni ve formülleri doğru bir şekilde tanı. Matematiksel ifadeleri LaTeX formatında yaz. Tablo varsa markdown tablo olarak yaz.`,
    };
  }

  return { role: "system", content: `${base}\n${rules}` };
}

// Kullanımı (mevcut systemPrompt yerine):
const systemPrompt = buildSystemPrompt(config, taskType as TaskType);
```

### Adım 5.2 — Prompt caching için DeepSeek'te prefix kullan

**Dosya:** `supabase/functions/ai-chat/index.ts`

**Açıklama:** DeepSeek otomatik prefix caching yapıyor (input: $0.028/M cache hit). System prompt sabit olduğu için otomatik olarak cache'leniyor. Ek implementasyon gerekmez, sadece system prompt'un her request'te aynı kalmasını sağla (dynamik content ekleme).

### Adım 5.3 — `_buildChatHistory`'de token limiti ekle

**Dosya:** `lib/features/ai/data/repositories/ai_repository_impl.dart`

**Değişiklik:** Mesaj sayısı yerine tahmini token sayısına göre kes.

**ESKİ (Phase 1'de eklenen):**
```dart
List<Map<String, dynamic>> _buildChatHistory(
  List<AIMessage> messages, {
  int maxMessages = 20,
}) {
  final recent = messages.length > maxMessages
      ? messages.sublist(messages.length - maxMessages)
      : messages;

  return recent.map((msg) {
    return {
      'role': msg.role == MessageRole.user ? 'user' : 'assistant',
      'content': msg.content,
    };
  }).toList();
}
```

**YENİ (token-aware versiyon):**
```dart
/// Conversation geçmişini OpenAI messages formatına çevirir.
/// [maxTokens] tahmini token bütçesi (1 token ≈ 4 karakter Türkçe için ~3).
/// En yeni mesajlardan başlayarak bütçe dolana kadar ekler.
List<Map<String, dynamic>> _buildChatHistory(
  List<AIMessage> messages, {
  int maxMessages = 20,
  int maxTokens = 6000,
}) {
  final result = <Map<String, dynamic>>[];
  int estimatedTokens = 0;

  // En yeni mesajdan geriye doğru git
  for (int i = messages.length - 1; i >= 0 && result.length < maxMessages; i--) {
    final msg = messages[i];
    // Türkçe için yaklaşık token hesabı: karakter / 3
    final msgTokens = (msg.content.length / 3).ceil();

    if (estimatedTokens + msgTokens > maxTokens) break;

    result.insert(0, {
      'role': msg.role == MessageRole.user ? 'user' : 'assistant',
      'content': msg.content,
    });
    estimatedTokens += msgTokens;
  }

  return result;
}
```

### Doğrulama Kriterleri — Phase 5

- [ ] DeepSeek matematik sorularında system prompt'ta "İngilizce düşün" talimatı olmalı
- [ ] OCR modunda system prompt'ta yapılandırılmış çıktı talimatı olmalı
- [ ] Uzun sohbetlerde (50+ mesaj) geçmiş ~6000 token'da kesilmeli
- [ ] Token kesme en eski mesajlardan başlamalı, en yeniler korunmalı

---

## Phase 6 — Qwen2.5-VL OCR Entegrasyonu (Pro Tier — Opsiyonel)

### Amaç
Pro tier kullanıcılar için yapılandırılmış OCR desteği (tablo, formül çıkarma).

### Adım 6.1 — Fireworks AI provider ekle

**Dosya:** `supabase/functions/ai-chat/index.ts`

**Not:** Qwen2.5-VL-32B, Fireworks AI üzerinden sunuluyor. OpenAI-compatible API.

```typescript
// ModelConfig provider type'ına ekle:
provider: "openai" | "google" | "deepseek" | "groq" | "fireworks";

async function callFireworks(
  config: ModelConfig,
  messages: Array<{ role: string; content: any }>,
): Promise<Response> {
  const apiKey = Deno.env.get("FIREWORKS_API_KEY");
  if (!apiKey) throw new Error("FIREWORKS_API_KEY not set");

  return fetch("https://api.fireworks.ai/inference/v1/chat/completions", {
    method: "POST",
    headers: {
      Authorization: `Bearer ${apiKey}`,
      "Content-Type": "application/json",
    },
    body: JSON.stringify({
      model: `accounts/fireworks/models/${config.model}`,
      messages,
      max_tokens: config.maxTokens,
      temperature: config.temperature,
      stream: true,
    }),
  });
}
```

### Adım 6.2 — Pro tier OCR routing'ini güncelle

**Dosya:** `supabase/functions/ai-chat/index.ts`

**Değişiklik:** `selectModel` fonksiyonunda premiumPlus OCR case'ini Qwen'e yönlendir.

```typescript
// Pro tier OCR bloğunu değiştir:
if (task.includes("ocr")) {
  return {
    provider: "fireworks",
    model: "qwen2p5-vl-32b-instruct",
    maxTokens: 4096,
    temperature: 0.2,
  };
}
```

### Adım 6.3 — Provider routing'e Fireworks ekle

**Dosya:** `supabase/functions/ai-chat/index.ts`

`callProvider` fonksiyonuna ekle:
```typescript
} else if (cfg.provider === "fireworks") {
  return { response: await callFireworks(cfg, msgs), transformer: createOpenAIToSSETransformer() };
}
```

### Adım 6.4 — Secret ekle

```bash
supabase secrets set FIREWORKS_API_KEY=fw_xxxxxxxxxxxxxxxx
```

### Doğrulama Kriterleri — Phase 6

- [ ] Pro kullanıcı image gönderdiğinde Qwen2.5-VL kullanılmalı
- [ ] Fireworks streaming response doğru parse edilmeli
- [ ] Matematik formülü içeren image'larda LaTeX çıktısı alınmalı
- [ ] Premium kullanıcılar hâlâ Gemini Flash'a yönlendirilmeli (Qwen sadece Pro)

---

## Özet — Tüm Phase'lerin Bağımlılık Haritası

```
Phase 1 (Context Fix) ←── Bağımsız, hemen yapılabilir
    │
Phase 2 (DeepSeek Provider) ←── Bağımsız, Phase 1 ile paralel yapılabilir
    │
Phase 3 (Model Routing) ←── Phase 2'ye bağlı (DeepSeek provider olmalı)
    │
Phase 4 (Groq Fallback) ←── Phase 3'e bağlı (selectModel güncel olmalı)
    │
Phase 5 (Token Optimizasyon) ←── Phase 1 + 3'e bağlı
    │
Phase 6 (Qwen OCR) ←── Phase 3 + 4'e bağlı, OPSİYONEL
```

## Gerekli API Anahtarları

| Provider | Env Variable | Nereden Alınır | Tier |
|----------|-------------|----------------|------|
| OpenAI | `OPENAI_API_KEY` | platform.openai.com | Mevcut ✅ |
| Google AI | `GOOGLE_AI_API_KEY` | aistudio.google.dev | Mevcut ✅ |
| DeepSeek | `DEEPSEEK_API_KEY` | platform.deepseek.com | Phase 2 |
| Groq | `GROQ_API_KEY` | console.groq.com | Phase 4 |
| Fireworks | `FIREWORKS_API_KEY` | fireworks.ai | Phase 6 |

## Maliyet Karşılaştırması (Kullanıcı başına aylık)

| Tier | Eski Maliyet | Yeni Maliyet | Tasarruf |
|------|-------------|-------------|----------|
| Free | ~$0.50 (GPT-4o-mini) | $0 (Gemini free) | %100 |
| Premium | ~$3–5 (GPT-4o-mini) | ~$1.50–3 (DeepSeek) | %50–70 |
| Pro | ~$8–15 (GPT-4o) | ~$5–10 (mix) | %30–50 |
