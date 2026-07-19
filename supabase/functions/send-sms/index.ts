import { serve } from "https://deno.land/std@0.177.0/http/server.ts";

const INFOBIP_API_KEY = Deno.env.get("INFOBIP_API_KEY")!;
const INFOBIP_BASE_URL = Deno.env.get("INFOBIP_BASE_URL")!;
const INFOBIP_SENDER_ID = Deno.env.get("INFOBIP_SENDER_ID") || "RABT";

interface SmsRequest {
  to: string;
  message?: string;
  otp?: string;
}

serve(async (req: Request) => {
  // Handle CORS
  if (req.method === "OPTIONS") {
    return new Response("ok", {
      headers: {
        "Access-Control-Allow-Origin": "*",
        "Access-Control-Allow-Methods": "POST",
        "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
      },
    });
  }

  try {
    const { to, message, otp }: SmsRequest = await req.json();

    if (!to) {
      return new Response(
        JSON.stringify({ error: "Phone number is required" }),
        { status: 400, headers: { "Content-Type": "application/json" } }
      );
    }

    // Format phone number (remove + prefix for Infobip)
    const formattedPhone = to.startsWith("+") ? to.substring(1) : to;

    // Build SMS message
    const smsMessage = message || `Your RABT verification code is: ${otp}. Valid for 5 minutes.`;

    // Send SMS via Infobip
    const response = await fetch(`${INFOBIP_BASE_URL}/sms/2/text/advanced`, {
      method: "POST",
      headers: {
        "Authorization": `App ${INFOBIP_API_KEY}`,
        "Content-Type": "application/json",
        "Accept": "application/json",
      },
      body: JSON.stringify({
        messages: [
          {
            from: INFOBIP_SENDER_ID,
            destinations: [{ to: formattedPhone }],
            text: smsMessage,
          },
        ],
      }),
    });

    const data = await response.json();

    if (!response.ok) {
      console.error("Infobip error:", data);
      return new Response(
        JSON.stringify({ error: "Failed to send SMS", details: data }),
        { status: response.status, headers: { "Content-Type": "application/json" } }
      );
    }

    return new Response(
      JSON.stringify({ success: true, messageId: data.messages?.[0]?.messageId }),
      { status: 200, headers: { "Content-Type": "application/json" } }
    );
  } catch (error) {
    console.error("Function error:", error);
    return new Response(
      JSON.stringify({ error: "Internal server error" }),
      { status: 500, headers: { "Content-Type": "application/json" } }
    );
  }
});
