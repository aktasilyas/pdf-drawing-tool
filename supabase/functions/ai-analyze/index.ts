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
