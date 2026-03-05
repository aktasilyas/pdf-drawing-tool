// supabase/functions/revenuecat-webhook/index.ts
// Handles RevenueCat webhook events to sync subscription tier in Supabase.

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
    // Verify webhook authorization header
    const authHeader = req.headers.get("authorization");
    const webhookSecret = Deno.env.get("REVENUECAT_WEBHOOK_SECRET");
    if (webhookSecret && authHeader !== `Bearer ${webhookSecret}`) {
      console.warn("[Webhook] Unauthorized request rejected");
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

    // Determine tier from active entitlements
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

    // Update user tier in Supabase
    const supabase = createClient(
      Deno.env.get("SUPABASE_URL")!,
      Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!,
    );

    const { error } = await supabase
      .from("user_profiles")
      .update({
        subscription_tier: tier,
        subscription_updated_at: new Date().toISOString(),
      })
      .eq("id", appUserId);

    if (error) {
      console.error(`[Webhook] DB update failed for ${appUserId}:`, error);
      return new Response(JSON.stringify({ error: "DB update failed" }), {
        status: 500,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      });
    }

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
