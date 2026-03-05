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
  provider: "openai" | "google" | "deepseek" | "groq";
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

function buildSystemPrompt(config: ModelConfig, task: TaskType): { role: string; content: string } {
  const base = `Sen Elyanotes yapay zeka asistanısın. Kullanıcılara not alma, çalışma ve öğrenme konularında yardımcı oluyorsun.`;

  const rules = `
Kurallar:
- Kısa ve öz yanıtlar ver, gereksiz uzatma
- Türkçe yanıt ver (kullanıcı başka dilde yazarsa o dilde yanıtla)
- Eğitim odaklı ol, sadece cevap verme, açıkla
- Samimi ve anlaşılır bir dil kullan, lise öğrencisine anlatır gibi yaz

Matematik kuralları:
- Sadece karmaşık formüllerde LaTeX kullan (örn: kesirler, karekök, üs)
- Basit işlemleri düz metin yaz: "2x + 5 = 0" gibi, "$2x + 5 = 0$" değil
- Her adımı kısa ve net açıkla, profesör gibi değil arkadaş gibi anlat
- Çözümün sonunda kısa bir özet ver: "Sonuç: x = 3"
- Gereksiz terim kullanma (diskriminant yerine "delta değeri" de)

Takip soruları:
- Her yanıtının EN SONUNA şu formatla 2-3 kısa takip sorusu ekle:
- "---suggestions---" satırından sonra her soruyu yeni satıra yaz
- Sorular kısa olsun (max 60 karakter), kullanıcının tıklayıp sorabileceği türden
- Sorular mevcut konuyla alakalı olsun
- Örnek format:
---suggestions---
Bu konuyu daha detaylı açıklar mısın?
Başka bir yöntemle çözebilir miyiz?
Benzer bir soru çözer misin?`;

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

    // 2. Parse request (need tier before rate limit check)
    const { messages, taskType = "chat", conversationId, image, tier: requestTier } = await req.json();

    // 3. Determine user tier from request (validated client-side via RevenueCat)
    const tier: UserTier = (requestTier === "premium" || requestTier === "premiumPlus")
      ? requestTier
      : "free";

    // 4. Rate limit check (DB-based, no Redis needed for MVP)
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

    if (!messages || !Array.isArray(messages) || messages.length === 0) {
      return new Response(JSON.stringify({ error: "messages array required" }), {
        status: 400,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      });
    }

    // 5. Build messages with system prompt
    const config = selectModel(taskType as TaskType, tier);
    const systemPrompt = buildSystemPrompt(config, taskType as TaskType);
    console.log(`[AI] Request: tier=${tier}, task=${taskType}, model=${config.model}, provider=${config.provider}, messages=${messages.length}, remaining=${remaining}`);

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

    // 6. Call provider with fallback
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

    console.log(`[AI] Calling ${config.provider}/${config.model}...`);
    let result = await callProvider(config, processedMessages);
    aiResponse = result.response;
    transformer = result.transformer;
    console.log(`[AI] Provider response status: ${aiResponse.status}`);

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
