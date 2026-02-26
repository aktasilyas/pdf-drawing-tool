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
  // Free tier → GPT-4o-mini (cheap + reliable: $0.15/MTok input, $0.60/MTok output)
  if (tier === "free") {
    return {
      provider: "openai",
      model: "gpt-4o-mini",
      maxTokens: task.startsWith("summarize") ? 2048 : 1024,
      temperature: task.includes("math") || task.includes("ocr") ? 0.2 : 0.7,
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
