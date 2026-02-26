# PHASE 5 — STEP 1: AI Backend Altyapısı (Supabase + Flutter Remote Layer)

## ÖZET
AI entegrasyonunun temelini kur: Supabase'de AI tabloları oluştur, Edge Functions yaz (ai-chat proxy), Flutter tarafında remote datasource + domain entities hazırla. Bu step sonunda Flutter'dan Edge Function'a istek atıp streaming cevap alınabilir durumda olacağız.

## BRANCH
```bash
git checkout -b feature/ai-integration-step1
```

---

## MİMARİ KARARLAR

1. **AI kodu tamamen example_app/ içinde yaşar** — drawing_core ve drawing_ui'ya AI bağımlılığı eklenmez
2. **Tüm AI API çağrıları Supabase Edge Functions üzerinden geçer** — API key'ler asla client'ta olmaz
3. **Multi-model routing** — Task tipine ve user tier'ına göre farklı model seçilir
4. **Mevcut SubscriptionTier kullanılır** — `free → Gemini Flash`, `premium → GPT-4o-mini`, `premiumPlus → GPT-4o`
5. **Streaming response** — SSE ile token-by-token UI güncelleme
6. **Clean Architecture** — domain/data/presentation ayrımı, mevcut proje yapısına uygun

---

## İLYAS'IN YAPMASI GEREKENLER (Supabase Dashboard)

### 1) Supabase SQL Editor'da bu migration'ı çalıştır:

```sql
-- =====================================================
-- AI Integration Tables
-- =====================================================

-- AI Conversations
CREATE TABLE IF NOT EXISTS ai_conversations (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  title TEXT NOT NULL DEFAULT 'Yeni Sohbet',
  document_id UUID DEFAULT NULL,
  task_type TEXT NOT NULL DEFAULT 'chat',
  total_input_tokens INTEGER DEFAULT 0,
  total_output_tokens INTEGER DEFAULT 0,
  message_count INTEGER DEFAULT 0,
  is_pinned BOOLEAN DEFAULT FALSE,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- AI Messages
CREATE TABLE IF NOT EXISTS ai_messages (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  conversation_id UUID NOT NULL REFERENCES ai_conversations(id) ON DELETE CASCADE,
  role TEXT NOT NULL CHECK (role IN ('user', 'assistant', 'system')),
  content TEXT NOT NULL,
  model TEXT,
  provider TEXT,
  input_tokens INTEGER DEFAULT 0,
  output_tokens INTEGER DEFAULT 0,
  has_image BOOLEAN DEFAULT FALSE,
  image_path TEXT,
  metadata JSONB DEFAULT '{}',
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Token Usage (daily aggregates)
CREATE TABLE IF NOT EXISTS ai_token_usage_daily (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  date DATE NOT NULL,
  model TEXT NOT NULL,
  provider TEXT NOT NULL,
  input_tokens INTEGER DEFAULT 0,
  output_tokens INTEGER DEFAULT 0,
  request_count INTEGER DEFAULT 0,
  estimated_cost_usd NUMERIC(10, 6) DEFAULT 0,
  UNIQUE(user_id, date, model, provider)
);

-- Indexes
CREATE INDEX IF NOT EXISTS idx_ai_conversations_user 
  ON ai_conversations(user_id, updated_at DESC);
CREATE INDEX IF NOT EXISTS idx_ai_messages_conversation 
  ON ai_messages(conversation_id, created_at);
CREATE INDEX IF NOT EXISTS idx_ai_token_usage_user_date 
  ON ai_token_usage_daily(user_id, date);

-- RLS
ALTER TABLE ai_conversations ENABLE ROW LEVEL SECURITY;
ALTER TABLE ai_messages ENABLE ROW LEVEL SECURITY;
ALTER TABLE ai_token_usage_daily ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can CRUD own conversations"
  ON ai_conversations FOR ALL USING (auth.uid() = user_id);

CREATE POLICY "Users can CRUD messages in own conversations"
  ON ai_messages FOR ALL USING (
    conversation_id IN (SELECT id FROM ai_conversations WHERE user_id = auth.uid())
  );

CREATE POLICY "Users can read own usage"
  ON ai_token_usage_daily FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "System can insert usage"
  ON ai_token_usage_daily FOR INSERT WITH CHECK (auth.uid() = user_id);

-- Upsert function for token tracking
CREATE OR REPLACE FUNCTION increment_token_usage(
  p_user_id UUID,
  p_date DATE,
  p_model TEXT,
  p_provider TEXT,
  p_input_tokens INTEGER,
  p_output_tokens INTEGER,
  p_request_count INTEGER,
  p_estimated_cost NUMERIC DEFAULT 0
) RETURNS VOID AS $$
BEGIN
  INSERT INTO ai_token_usage_daily (user_id, date, model, provider, input_tokens, output_tokens, request_count, estimated_cost_usd)
  VALUES (p_user_id, p_date, p_model, p_provider, p_input_tokens, p_output_tokens, p_request_count, p_estimated_cost)
  ON CONFLICT (user_id, date, model, provider)
  DO UPDATE SET
    input_tokens = ai_token_usage_daily.input_tokens + p_input_tokens,
    output_tokens = ai_token_usage_daily.output_tokens + p_output_tokens,
    request_count = ai_token_usage_daily.request_count + p_request_count,
    estimated_cost_usd = ai_token_usage_daily.estimated_cost_usd + p_estimated_cost;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Auto-update updated_at trigger
CREATE OR REPLACE FUNCTION update_ai_conversation_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_ai_conversation_updated_at
  BEFORE UPDATE ON ai_conversations
  FOR EACH ROW
  EXECUTE FUNCTION update_ai_conversation_updated_at();

-- Helper: get daily message count for rate limiting
CREATE OR REPLACE FUNCTION get_daily_ai_message_count(p_user_id UUID)
RETURNS INTEGER AS $$
  SELECT COALESCE(SUM(request_count), 0)::INTEGER
  FROM ai_token_usage_daily
  WHERE user_id = p_user_id AND date = CURRENT_DATE;
$$ LANGUAGE sql SECURITY DEFINER;
```

### 2) Supabase Edge Functions — Secrets ekle:

Dashboard → Settings → Edge Functions → Secrets:
```
OPENAI_API_KEY=sk-...
GOOGLE_AI_API_KEY=AIza...
```

### 3) Edge Functions deploy:

Projede `supabase/functions/` altında dosyaları oluşturduktan sonra:
```bash
supabase functions deploy ai-chat
```

---

## @flutter-developer — İMPLEMENTASYON

### BÖLÜM A: Supabase Edge Function (TypeScript)

**Görev:** `supabase/functions/ai-chat/index.ts` dosyasını oluştur.

Bu dosya ilk MVP — sadece OpenAI ve Google Gemini destekli, streaming response ile. Anthropic ileride eklenir.

**1) OLUŞTUR: `supabase/functions/ai-chat/index.ts`**

```typescript
// supabase/functions/ai-chat/index.ts
// AI Chat Proxy — validates JWT, checks rate limits, routes to optimal model, streams response

import "jsr:@supabase/functions-js/edge-runtime.d.ts";
import { createClient } from "jsr:@supabase/supabase-js@2";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
};

// ─── Model Routing Config ───────────────────────────────
interface ModelConfig {
  provider: "openai" | "google";
  model: string;
  maxTokens: number;
  temperature: number;
}

type TaskType = "chat" | "math_simple" | "math_advanced" | "ocr_simple" | "ocr_complex" | "summarize_short" | "summarize_long";
type UserTier = "free" | "premium" | "premiumPlus";

// Rate limits: messages per day
const RATE_LIMITS: Record<UserTier, number> = {
  free: 15,
  premium: 150,
  premiumPlus: 1000,
};

function selectModel(task: TaskType, tier: UserTier): ModelConfig {
  // Free tier → always Gemini Flash (cheapest multimodal: $0.10/MTok input)
  if (tier === "free") {
    return {
      provider: "google",
      model: "gemini-2.0-flash",
      maxTokens: task.startsWith("summarize") ? 2048 : 1024,
      temperature: task.includes("math") || task.includes("ocr") ? 0.1 : 0.7,
    };
  }

  // Premium → GPT-4o-mini default, GPT-4o for advanced
  if (tier === "premium") {
    const advancedTasks = ["math_advanced", "ocr_complex"];
    if (advancedTasks.includes(task)) {
      return { provider: "openai", model: "gpt-4o", maxTokens: 4096, temperature: 0.2 };
    }
    return {
      provider: "openai",
      model: "gpt-4o-mini",
      maxTokens: 2048,
      temperature: task.includes("math") || task.includes("ocr") ? 0.2 : 0.7,
    };
  }

  // PremiumPlus → GPT-4o default, o4-mini for competition math
  if (task === "math_advanced") {
    return { provider: "openai", model: "gpt-4o", maxTokens: 8192, temperature: 0.2 };
  }
  return {
    provider: "openai",
    model: "gpt-4o",
    maxTokens: 4096,
    temperature: task.includes("math") || task.includes("ocr") ? 0.2 : 0.7,
  };
}

// ─── Provider Callers ──────────────────────────────────

async function callOpenAI(
  config: ModelConfig,
  messages: Array<{ role: string; content: any }>,
): Promise<Response> {
  const apiKey = Deno.env.get("OPENAI_API_KEY");
  if (!apiKey) throw new Error("OPENAI_API_KEY not set");

  return fetch("https://api.openai.com/v1/chat/completions", {
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

async function callGemini(
  config: ModelConfig,
  messages: Array<{ role: string; content: any }>,
): Promise<Response> {
  const apiKey = Deno.env.get("GOOGLE_AI_API_KEY");
  if (!apiKey) throw new Error("GOOGLE_AI_API_KEY not set");

  // Convert OpenAI format to Gemini format
  const geminiContents = messages
    .filter((m) => m.role !== "system")
    .map((m) => ({
      role: m.role === "assistant" ? "model" : "user",
      parts: typeof m.content === "string"
        ? [{ text: m.content }]
        : m.content.map((c: any) => {
            if (c.type === "text") return { text: c.text };
            if (c.type === "image_url") {
              // Extract base64 from data:image/png;base64,... format
              const base64Match = c.image_url.url.match(/^data:([^;]+);base64,(.+)$/);
              if (base64Match) {
                return {
                  inlineData: {
                    mimeType: base64Match[1],
                    data: base64Match[2],
                  },
                };
              }
            }
            return { text: JSON.stringify(c) };
          }),
    }));

  const systemInstruction = messages.find((m) => m.role === "system");

  const body: any = {
    contents: geminiContents,
    generationConfig: {
      maxOutputTokens: config.maxTokens,
      temperature: config.temperature,
    },
  };

  if (systemInstruction) {
    body.systemInstruction = {
      parts: [{ text: typeof systemInstruction.content === "string" 
        ? systemInstruction.content 
        : systemInstruction.content[0]?.text || "" }],
    };
  }

  // Gemini streaming endpoint
  return fetch(
    `https://generativelanguage.googleapis.com/v1beta/models/${config.model}:streamGenerateContent?alt=sse&key=${apiKey}`,
    {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify(body),
    },
  );
}

// ─── SSE Transformer ───────────────────────────────────

function createOpenAIToSSETransformer(): TransformStream<Uint8Array, Uint8Array> {
  const encoder = new TextEncoder();
  const decoder = new TextDecoder();
  let buffer = "";
  let totalOutputTokens = 0;

  return new TransformStream({
    transform(chunk, controller) {
      buffer += decoder.decode(chunk, { stream: true });
      const lines = buffer.split("\n");
      buffer = lines.pop() || "";

      for (const line of lines) {
        if (!line.startsWith("data: ")) continue;
        const data = line.slice(6).trim();
        if (data === "[DONE]") {
          controller.enqueue(encoder.encode(`data: {"done":true,"usage":{"output_tokens":${totalOutputTokens}}}\n\n`));
          return;
        }
        try {
          const parsed = JSON.parse(data);
          const content = parsed.choices?.[0]?.delta?.content;
          if (content) {
            totalOutputTokens += 1; // Approximate
            controller.enqueue(encoder.encode(`data: {"content":${JSON.stringify(content)}}\n\n`));
          }
        } catch { /* skip malformed */ }
      }
    },
  });
}

function createGeminiToSSETransformer(): TransformStream<Uint8Array, Uint8Array> {
  const encoder = new TextEncoder();
  const decoder = new TextDecoder();
  let buffer = "";
  let totalOutputTokens = 0;

  return new TransformStream({
    transform(chunk, controller) {
      buffer += decoder.decode(chunk, { stream: true });
      const lines = buffer.split("\n");
      buffer = lines.pop() || "";

      for (const line of lines) {
        if (!line.startsWith("data: ")) continue;
        const data = line.slice(6).trim();
        try {
          const parsed = JSON.parse(data);
          const text = parsed.candidates?.[0]?.content?.parts?.[0]?.text;
          if (text) {
            totalOutputTokens += Math.ceil(text.length / 4); // Rough estimate
            controller.enqueue(encoder.encode(`data: {"content":${JSON.stringify(text)}}\n\n`));
          }
          // Check if done
          if (parsed.candidates?.[0]?.finishReason) {
            const usage = parsed.usageMetadata;
            controller.enqueue(encoder.encode(
              `data: {"done":true,"usage":{"input_tokens":${usage?.promptTokenCount || 0},"output_tokens":${usage?.candidatesTokenCount || totalOutputTokens}}}\n\n`
            ));
          }
        } catch { /* skip malformed */ }
      }
    },
  });
}

// ─── Main Handler ──────────────────────────────────────

Deno.serve(async (req) => {
  // CORS preflight
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  try {
    // 1. Auth
    const authHeader = req.headers.get("Authorization");
    if (!authHeader) {
      return new Response(JSON.stringify({ error: "unauthorized" }), {
        status: 401,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      });
    }

    const supabase = createClient(
      Deno.env.get("SUPABASE_URL")!,
      Deno.env.get("SUPABASE_ANON_KEY")!,
      { global: { headers: { Authorization: authHeader } } },
    );

    const { data: { user }, error: authError } = await supabase.auth.getUser();
    if (authError || !user) {
      return new Response(JSON.stringify({ error: "unauthorized" }), {
        status: 401,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      });
    }

    // 2. Get user tier from subscription (profiles or subscription table)
    // For now, check if premium entitlement exists
    // TODO: İlyas — profiles tablosuna subscription_tier kolonu ekle veya
    // mevcut subscription entity'den tier bilgisini çek
    const tier: UserTier = "free"; // Default — will be updated with real tier lookup

    // 3. Rate limit check (DB-based, no Redis needed for MVP)
    const { data: dailyCount } = await supabase.rpc("get_daily_ai_message_count", {
      p_user_id: user.id,
    });
    const limit = RATE_LIMITS[tier];
    const remaining = Math.max(0, limit - (dailyCount || 0));

    if (remaining <= 0) {
      return new Response(
        JSON.stringify({
          error: "rate_limit_exceeded",
          message: "Günlük AI mesaj limitinize ulaştınız",
          limit,
          remaining: 0,
          resetAt: new Date(new Date().setHours(24, 0, 0, 0)).toISOString(),
        }),
        {
          status: 429,
          headers: { ...corsHeaders, "Content-Type": "application/json" },
        },
      );
    }

    // 4. Parse request
    const { messages, taskType = "chat", conversationId, image } = await req.json();

    if (!messages || !Array.isArray(messages) || messages.length === 0) {
      return new Response(JSON.stringify({ error: "messages array required" }), {
        status: 400,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      });
    }

    // 5. Build messages with system prompt
    const systemPrompt = {
      role: "system",
      content: `Sen StarNote yapay zeka asistanısın. Kullanıcılara not alma, çalışma ve öğrenme konularında yardımcı oluyorsun.

Kurallar:
- Kısa ve öz yanıtlar ver
- Matematik sorularında adım adım çözüm göster
- LaTeX formülleri için $...$ (inline) ve $$...$$ (block) kullan
- Türkçe yanıt ver (kullanıcı başka dilde yazarsa o dilde yanıtla)
- Eğitim odaklı ol, sadece cevap verme, açıkla`,
    };

    // If image is provided, add it to the last user message
    const processedMessages = [systemPrompt, ...messages];
    if (image) {
      const lastUserMsg = processedMessages.findLast((m: any) => m.role === "user");
      if (lastUserMsg) {
        lastUserMsg.content = [
          { type: "text", text: typeof lastUserMsg.content === "string" ? lastUserMsg.content : lastUserMsg.content[0]?.text || "" },
          { type: "image_url", image_url: { url: `data:image/png;base64,${image}` } },
        ];
      }
    }

    // 6. Select model and call provider
    const config = selectModel(taskType as TaskType, tier);
    let aiResponse: Response;
    let transformer: TransformStream<Uint8Array, Uint8Array>;

    if (config.provider === "openai") {
      aiResponse = await callOpenAI(config, processedMessages);
      transformer = createOpenAIToSSETransformer();
    } else {
      aiResponse = await callGemini(config, processedMessages);
      transformer = createGeminiToSSETransformer();
    }

    if (!aiResponse.ok) {
      const errorBody = await aiResponse.text();
      console.error(`AI provider error (${config.provider}/${config.model}):`, errorBody);
      return new Response(
        JSON.stringify({ error: "ai_provider_error", details: `${config.provider} returned ${aiResponse.status}` }),
        { status: 502, headers: { ...corsHeaders, "Content-Type": "application/json" } },
      );
    }

    // 7. Log usage (fire and forget — don't block streaming)
    const logUsage = async (inputTokens: number, outputTokens: number) => {
      try {
        await supabase.rpc("increment_token_usage", {
          p_user_id: user.id,
          p_date: new Date().toISOString().split("T")[0],
          p_model: config.model,
          p_provider: config.provider,
          p_input_tokens: inputTokens,
          p_output_tokens: outputTokens,
          p_request_count: 1,
          p_estimated_cost: 0, // TODO: calculate based on model pricing
        });
      } catch (e) {
        console.error("Failed to log token usage:", e);
      }
    };

    // Start usage logging with estimates (will be refined)
    const estimatedInputTokens = JSON.stringify(processedMessages).length / 4;
    logUsage(Math.ceil(estimatedInputTokens), 0);

    // 8. Stream response
    const stream = aiResponse.body!.pipeThrough(transformer);

    return new Response(stream, {
      headers: {
        ...corsHeaders,
        "Content-Type": "text/event-stream",
        "Cache-Control": "no-cache",
        "Connection": "keep-alive",
        "X-Model": config.model,
        "X-Provider": config.provider,
        "X-RateLimit-Remaining": remaining.toString(),
        "X-RateLimit-Limit": limit.toString(),
      },
    });
  } catch (error) {
    console.error("AI chat error:", error);
    return new Response(
      JSON.stringify({ error: "internal_error", message: (error as Error).message }),
      { status: 500, headers: { ...corsHeaders, "Content-Type": "application/json" } },
    );
  }
});
```

**2) OLUŞTUR: `supabase/functions/ai-analyze/index.ts`**

Şimdilik `ai-chat` ile aynı — sadece default taskType farklı. İleriki adımlarda Mathpix entegrasyonu eklenecek.

```typescript
// supabase/functions/ai-analyze/index.ts
// Multimodal analysis — delegates to ai-chat with image-specific defaults
// For MVP, this is a thin wrapper. Will diverge when Mathpix is added.

import "jsr:@supabase/functions-js/edge-runtime.d.ts";

Deno.serve(async (req) => {
  // Forward to ai-chat with taskType override
  const url = new URL(req.url);
  const chatUrl = url.origin.replace("ai-analyze", "ai-chat");
  
  if (req.method === "OPTIONS") {
    return new Response("ok", {
      headers: {
        "Access-Control-Allow-Origin": "*",
        "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
      },
    });
  }

  const body = await req.json();
  // Auto-detect task type from image content
  if (!body.taskType) {
    body.taskType = body.image ? "ocr_simple" : "chat";
  }

  // For now, call ai-chat Edge Function internally
  // In production, this will have its own Mathpix + model logic
  const response = await fetch(`${Deno.env.get("SUPABASE_URL")}/functions/v1/ai-chat`, {
    method: "POST",
    headers: {
      Authorization: req.headers.get("Authorization") || "",
      "Content-Type": "application/json",
    },
    body: JSON.stringify(body),
  });

  return new Response(response.body, {
    status: response.status,
    headers: response.headers,
  });
});
```

---

### BÖLÜM B: Flutter Domain Entities

**Görev:** AI feature'ın domain entity'lerini oluştur. Freezed kullan.

**3) OLUŞTUR: `example_app/lib/features/ai/domain/entities/ai_message.dart`**

```dart
import 'package:freezed_annotation/freezed_annotation.dart';

part 'ai_message.freezed.dart';
part 'ai_message.g.dart';

/// AI chat message role.
enum MessageRole {
  user,
  assistant,
  system,
}

/// Domain entity for a single AI chat message.
@freezed
class AIMessage with _$AIMessage {
  const factory AIMessage({
    required String id,
    required String conversationId,
    required MessageRole role,
    required String content,
    String? model,
    String? provider,
    @Default(0) int inputTokens,
    @Default(0) int outputTokens,
    @Default(false) bool hasImage,
    String? imagePath,
    @Default({}) Map<String, dynamic> metadata,
    required DateTime createdAt,
  }) = _AIMessage;

  factory AIMessage.fromJson(Map<String, dynamic> json) =>
      _$AIMessageFromJson(json);
}
```

**4) OLUŞTUR: `example_app/lib/features/ai/domain/entities/ai_conversation.dart`**

```dart
import 'package:freezed_annotation/freezed_annotation.dart';

part 'ai_conversation.freezed.dart';
part 'ai_conversation.g.dart';

/// Domain entity for an AI conversation (chat session).
@freezed
class AIConversation with _$AIConversation {
  const factory AIConversation({
    required String id,
    required String userId,
    @Default('Yeni Sohbet') String title,
    String? documentId,
    @Default('chat') String taskType,
    @Default(0) int totalInputTokens,
    @Default(0) int totalOutputTokens,
    @Default(0) int messageCount,
    @Default(false) bool isPinned,
    required DateTime createdAt,
    required DateTime updatedAt,
  }) = _AIConversation;

  factory AIConversation.fromJson(Map<String, dynamic> json) =>
      _$AIConversationFromJson(json);
}
```

**5) OLUŞTUR: `example_app/lib/features/ai/domain/entities/ai_model_config.dart`**

```dart
/// AI provider identifier.
enum AIProvider { openai, google, anthropic }

/// Task types that determine which AI model to use.
enum AITaskType {
  chat,
  mathSimple,
  mathAdvanced,
  ocrSimple,
  ocrComplex,
  summarizeShort,
  summarizeLong,
}

/// Configuration for an AI model selection.
class AIModelConfig {
  final AIProvider provider;
  final String model;
  final int maxTokens;
  final double temperature;

  const AIModelConfig({
    required this.provider,
    required this.model,
    this.maxTokens = 2048,
    this.temperature = 0.7,
  });
}
```

**6) OLUŞTUR: `example_app/lib/features/ai/domain/entities/ai_usage.dart`**

```dart
/// Domain entity for AI usage tracking and quota management.
class AIUsage {
  final int dailyMessagesUsed;
  final int dailyMessagesLimit;
  final int monthlyTokensUsed;
  final int monthlyTokensLimit;

  const AIUsage({
    required this.dailyMessagesUsed,
    required this.dailyMessagesLimit,
    required this.monthlyTokensUsed,
    required this.monthlyTokensLimit,
  });

  double get dailyUsagePercent =>
      dailyMessagesLimit > 0 ? dailyMessagesUsed / dailyMessagesLimit : 0;

  bool get isOverDailyLimit => dailyMessagesUsed >= dailyMessagesLimit;
  bool get isOverMonthlyLimit => monthlyTokensUsed >= monthlyTokensLimit;
  int get remainingDaily =>
      (dailyMessagesLimit - dailyMessagesUsed).clamp(0, dailyMessagesLimit);

  /// Free tier defaults.
  static const AIUsage freeDefault = AIUsage(
    dailyMessagesUsed: 0,
    dailyMessagesLimit: 15,
    monthlyTokensUsed: 0,
    monthlyTokensLimit: 50000,
  );
}
```

**7) OLUŞTUR: `example_app/lib/features/ai/domain/entities/ai_entities.dart`** (barrel)

```dart
/// AI domain entities barrel export.
library;

export 'ai_conversation.dart';
export 'ai_message.dart';
export 'ai_model_config.dart';
export 'ai_usage.dart';
```

---

### BÖLÜM C: Abstract Repository

**8) OLUŞTUR: `example_app/lib/features/ai/domain/repositories/ai_repository.dart`**

```dart
import 'package:example_app/features/ai/domain/entities/ai_entities.dart';

/// Contract for AI data operations.
abstract class AIRepository {
  /// Send a message and receive streaming response chunks.
  Stream<String> sendMessage({
    required String conversationId,
    required String message,
    required AITaskType taskType,
    String? imageBase64,
  });

  /// Get all conversations for current user.
  Future<List<AIConversation>> getConversations();

  /// Get messages for a specific conversation.
  Future<List<AIMessage>> getMessages(String conversationId);

  /// Create a new conversation.
  Future<AIConversation> createConversation({
    String? documentId,
    String taskType = 'chat',
  });

  /// Delete a conversation and all its messages.
  Future<void> deleteConversation(String conversationId);

  /// Get current user's AI usage statistics.
  Future<AIUsage> getUsage();

  /// Update conversation title.
  Future<void> updateConversationTitle(String conversationId, String title);
}
```

---

### BÖLÜM D: Remote Data Source (Supabase Edge Function Client)

**9) OLUŞTUR: `example_app/lib/features/ai/data/datasources/ai_remote_datasource.dart`**

```dart
import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:example_app/features/ai/domain/entities/ai_entities.dart';

/// Remote data source for AI operations via Supabase Edge Functions.
class AIRemoteDataSource {
  final SupabaseClient _supabase;

  AIRemoteDataSource(this._supabase);

  /// Sends a chat message and returns streaming response chunks.
  ///
  /// Uses SSE (Server-Sent Events) to stream AI responses token by token.
  /// Each yielded String is a text delta to append to the UI.
  Stream<String> chat({
    required List<Map<String, dynamic>> messages,
    required String taskType,
    required String conversationId,
    String? imageBase64,
  }) async* {
    final session = _supabase.auth.currentSession;
    if (session == null) throw Exception('Not authenticated');

    final uri = Uri.parse(
      '${_supabase.supabaseUrl}/functions/v1/ai-chat',
    );

    final body = jsonEncode({
      'messages': messages,
      'taskType': taskType,
      'conversationId': conversationId,
      if (imageBase64 != null) 'image': imageBase64,
    });

    final request = http.Request('POST', uri)
      ..headers.addAll({
        'Authorization': 'Bearer ${session.accessToken}',
        'Content-Type': 'application/json',
        'apikey': _supabase.supabaseKey,
      })
      ..body = body;

    final client = http.Client();
    try {
      final response = await client.send(request);

      if (response.statusCode == 429) {
        // Rate limited
        final errorBody = await response.stream.bytesToString();
        final errorJson = jsonDecode(errorBody);
        throw AIRateLimitException(
          message: errorJson['message'] ?? 'Rate limit exceeded',
          remaining: errorJson['remaining'] ?? 0,
          resetAt: errorJson['resetAt'] != null
              ? DateTime.parse(errorJson['resetAt'])
              : null,
        );
      }

      if (response.statusCode != 200) {
        final errorBody = await response.stream.bytesToString();
        throw AIProviderException(
          'AI service error (${response.statusCode}): $errorBody',
        );
      }

      // Parse SSE stream
      await for (final chunk in response.stream.transform(utf8.decoder)) {
        for (final line in chunk.split('\n')) {
          if (!line.startsWith('data: ')) continue;
          final data = line.substring(6).trim();
          if (data.isEmpty) continue;

          try {
            final json = jsonDecode(data) as Map<String, dynamic>;

            // Check if done
            if (json['done'] == true) {
              // Usage info available in json['usage']
              return;
            }

            final content = json['content'] as String?;
            if (content != null && content.isNotEmpty) {
              yield content;
            }
          } catch (_) {
            // Skip malformed SSE lines
          }
        }
      }
    } finally {
      client.close();
    }
  }

  /// Create a new conversation in Supabase.
  Future<Map<String, dynamic>> createConversation({
    String? documentId,
    String taskType = 'chat',
  }) async {
    final user = _supabase.auth.currentUser;
    if (user == null) throw Exception('Not authenticated');

    final response = await _supabase.from('ai_conversations').insert({
      'user_id': user.id,
      'document_id': documentId,
      'task_type': taskType,
    }).select().single();

    return response;
  }

  /// Get conversations for current user.
  Future<List<Map<String, dynamic>>> getConversations() async {
    final user = _supabase.auth.currentUser;
    if (user == null) throw Exception('Not authenticated');

    return _supabase
        .from('ai_conversations')
        .select()
        .eq('user_id', user.id)
        .order('updated_at', ascending: false);
  }

  /// Get messages for a conversation.
  Future<List<Map<String, dynamic>>> getMessages(
    String conversationId,
  ) async {
    return _supabase
        .from('ai_messages')
        .select()
        .eq('conversation_id', conversationId)
        .order('created_at');
  }

  /// Save a message to Supabase.
  Future<Map<String, dynamic>> saveMessage({
    required String conversationId,
    required String role,
    required String content,
    String? model,
    String? provider,
    int inputTokens = 0,
    int outputTokens = 0,
    bool hasImage = false,
    String? imagePath,
  }) async {
    final response = await _supabase.from('ai_messages').insert({
      'conversation_id': conversationId,
      'role': role,
      'content': content,
      'model': model,
      'provider': provider,
      'input_tokens': inputTokens,
      'output_tokens': outputTokens,
      'has_image': hasImage,
      'image_path': imagePath,
    }).select().single();

    // Update conversation message count
    await _supabase.rpc('increment_token_usage', params: {
      'p_user_id': _supabase.auth.currentUser!.id,
      'p_date': DateTime.now().toIso8601String().split('T')[0],
      'p_model': model ?? 'unknown',
      'p_provider': provider ?? 'unknown',
      'p_input_tokens': inputTokens,
      'p_output_tokens': outputTokens,
      'p_request_count': 1,
    });

    return response;
  }

  /// Delete a conversation.
  Future<void> deleteConversation(String conversationId) async {
    await _supabase
        .from('ai_conversations')
        .delete()
        .eq('id', conversationId);
  }

  /// Get daily message count for current user.
  Future<int> getDailyMessageCount() async {
    final user = _supabase.auth.currentUser;
    if (user == null) return 0;

    final result = await _supabase.rpc('get_daily_ai_message_count', params: {
      'p_user_id': user.id,
    });

    return (result as int?) ?? 0;
  }

  /// Get monthly token usage.
  Future<Map<String, int>> getMonthlyTokenUsage() async {
    final user = _supabase.auth.currentUser;
    if (user == null) return {'input': 0, 'output': 0};

    final now = DateTime.now();
    final monthStart = DateTime(now.year, now.month, 1);

    final result = await _supabase
        .from('ai_token_usage_daily')
        .select('input_tokens, output_tokens')
        .eq('user_id', user.id)
        .gte('date', monthStart.toIso8601String().split('T')[0]);

    int totalInput = 0;
    int totalOutput = 0;
    for (final row in result) {
      totalInput += (row['input_tokens'] as int?) ?? 0;
      totalOutput += (row['output_tokens'] as int?) ?? 0;
    }

    return {'input': totalInput, 'output': totalOutput};
  }
}

/// Exception for rate limit errors.
class AIRateLimitException implements Exception {
  final String message;
  final int remaining;
  final DateTime? resetAt;

  AIRateLimitException({
    required this.message,
    this.remaining = 0,
    this.resetAt,
  });

  @override
  String toString() => 'AIRateLimitException: $message';
}

/// Exception for AI provider errors.
class AIProviderException implements Exception {
  final String message;
  AIProviderException(this.message);

  @override
  String toString() => 'AIProviderException: $message';
}
```

---

### BÖLÜM E: Repository Implementation

**10) OLUŞTUR: `example_app/lib/features/ai/data/repositories/ai_repository_impl.dart`**

```dart
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:example_app/features/ai/data/datasources/ai_remote_datasource.dart';
import 'package:example_app/features/ai/domain/entities/ai_entities.dart';
import 'package:example_app/features/ai/domain/repositories/ai_repository.dart';
import 'package:example_app/features/premium/domain/entities/subscription.dart';

/// AI Repository implementation using Supabase Edge Functions.
class AIRepositoryImpl implements AIRepository {
  final AIRemoteDataSource _remoteDataSource;
  final SubscriptionTier _userTier;

  AIRepositoryImpl({
    required AIRemoteDataSource remoteDataSource,
    required SubscriptionTier userTier,
  })  : _remoteDataSource = remoteDataSource,
        _userTier = userTier;

  @override
  Stream<String> sendMessage({
    required String conversationId,
    required String message,
    required AITaskType taskType,
    String? imageBase64,
  }) {
    return _remoteDataSource.chat(
      messages: [
        {'role': 'user', 'content': message},
      ],
      taskType: _mapTaskType(taskType),
      conversationId: conversationId,
      imageBase64: imageBase64,
    );
  }

  @override
  Future<List<AIConversation>> getConversations() async {
    final data = await _remoteDataSource.getConversations();
    return data.map((json) => AIConversation.fromJson(_mapKeys(json))).toList();
  }

  @override
  Future<List<AIMessage>> getMessages(String conversationId) async {
    final data = await _remoteDataSource.getMessages(conversationId);
    return data.map((json) => AIMessage.fromJson(_mapKeys(json))).toList();
  }

  @override
  Future<AIConversation> createConversation({
    String? documentId,
    String taskType = 'chat',
  }) async {
    final data = await _remoteDataSource.createConversation(
      documentId: documentId,
      taskType: taskType,
    );
    return AIConversation.fromJson(_mapKeys(data));
  }

  @override
  Future<void> deleteConversation(String conversationId) async {
    await _remoteDataSource.deleteConversation(conversationId);
  }

  @override
  Future<AIUsage> getUsage() async {
    final dailyCount = await _remoteDataSource.getDailyMessageCount();
    final monthlyTokens = await _remoteDataSource.getMonthlyTokenUsage();

    final limits = _getTierLimits();

    return AIUsage(
      dailyMessagesUsed: dailyCount,
      dailyMessagesLimit: limits['dailyMessages']!,
      monthlyTokensUsed: monthlyTokens['input']! + monthlyTokens['output']!,
      monthlyTokensLimit: limits['monthlyTokens']!,
    );
  }

  @override
  Future<void> updateConversationTitle(
    String conversationId,
    String title,
  ) async {
    // Direct Supabase call — no Edge Function needed
    await Supabase.instance.client
        .from('ai_conversations')
        .update({'title': title})
        .eq('id', conversationId);
  }

  Map<String, int> _getTierLimits() {
    switch (_userTier) {
      case SubscriptionTier.free:
        return {'dailyMessages': 15, 'monthlyTokens': 50000};
      case SubscriptionTier.premium:
        return {'dailyMessages': 150, 'monthlyTokens': 500000};
      case SubscriptionTier.premiumPlus:
        return {'dailyMessages': 1000, 'monthlyTokens': 5000000};
    }
  }

  String _mapTaskType(AITaskType type) {
    return switch (type) {
      AITaskType.chat => 'chat',
      AITaskType.mathSimple => 'math_simple',
      AITaskType.mathAdvanced => 'math_advanced',
      AITaskType.ocrSimple => 'ocr_simple',
      AITaskType.ocrComplex => 'ocr_complex',
      AITaskType.summarizeShort => 'summarize_short',
      AITaskType.summarizeLong => 'summarize_long',
    };
  }

  /// Convert snake_case Supabase keys to camelCase for freezed.
  Map<String, dynamic> _mapKeys(Map<String, dynamic> json) {
    return json.map((key, value) {
      final camelKey = key.replaceAllMapped(
        RegExp(r'_([a-z])'),
        (m) => m.group(1)!.toUpperCase(),
      );
      return MapEntry(camelKey, value);
    });
  }
}
```

---

### BÖLÜM F: Code Generation & Verify

**11) Build runner çalıştır:**
```bash
cd example_app
dart run build_runner build --delete-conflicting-outputs
```

**12) Analiz:**
```bash
cd example_app && flutter analyze
```

**13) Dosya yapısını doğrula:**
```
example_app/lib/features/ai/
├── data/
│   ├── datasources/
│   │   └── ai_remote_datasource.dart
│   └── repositories/
│       └── ai_repository_impl.dart
├── domain/
│   ├── entities/
│   │   ├── ai_conversation.dart
│   │   ├── ai_entities.dart  (barrel)
│   │   ├── ai_message.dart
│   │   ├── ai_model_config.dart
│   │   └── ai_usage.dart
│   └── repositories/
│       └── ai_repository.dart

supabase/functions/
├── ai-chat/
│   └── index.ts
└── ai-analyze/
    └── index.ts
```

---

## KURALLAR
- Her dosya max 300 satır
- Barrel exports zorunlu
- drawing_core ve drawing_ui'ya AI import'u YASAK — sadece example_app
- Freezed entity'ler için `dart run build_runner build` çalıştır
- Supabase snake_case → Dart camelCase dönüşümü repository'de yapılır
- API key'ler asla Flutter kodunda olmaz
- Hardcoded string'ler (hata mesajları) kabul edilebilir şimdilik — localization ileride
- http paketi zaten pubspec.yaml'da yoksa ekle

## TEST KRİTERLERİ
- [ ] `flutter analyze` temiz (zero errors)
- [ ] `build_runner` başarılı (freezed dosyaları generated)
- [ ] AIMessage ve AIConversation fromJson/toJson çalışıyor
- [ ] AIUsage hesaplamaları doğru (unit test)
- [ ] AIRemoteDataSource compile oluyor (runtime test Step 2'de)
- [ ] Edge Function curl ile test edildi (İlyas deploy ettikten sonra)
- [ ] Dosya yapısı yukarıdaki tree ile eşleşiyor

## COMMIT
```
feat(ai): add AI backend infrastructure — Edge Functions + domain layer

- Add Supabase Edge Function: ai-chat (OpenAI + Gemini streaming proxy)
- Add Supabase Edge Function: ai-analyze (multimodal thin wrapper)
- Add AI domain entities: AIMessage, AIConversation, AIUsage, AIModelConfig
- Add AIRepository abstract + AIRepositoryImpl
- Add AIRemoteDataSource with SSE streaming support
- Add SQL migration for ai_conversations, ai_messages, ai_token_usage_daily
- Smart model routing based on task type and subscription tier
- Rate limiting via DB-based daily message count
```

## SONRAKİ ADIM
Step 2: Canvas Capture Service + Riverpod Providers + AI Chat Modal UI
