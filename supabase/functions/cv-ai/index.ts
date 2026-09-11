import { createClient } from "npm:@supabase/supabase-js@2";

const headers = { "Content-Type": "application/json; charset=utf-8" };
const error = (status: number, code: string) =>
  new Response(JSON.stringify({ error: code }), { status, headers });

Deno.serve(async (req: Request) => {
  if (req.method !== "POST") return error(405, "method_not_allowed");
  const authorization = req.headers.get("Authorization");
  if (!authorization?.startsWith("Bearer ")) return error(401, "unauthorized");
  const client = createClient(
    Deno.env.get("SUPABASE_URL")!,
    Deno.env.get("SUPABASE_ANON_KEY")!,
    { global: { headers: { Authorization: authorization } } },
  );
  const { data, error: authError } = await client.auth.getUser(authorization.slice(7));
  if (authError || !data.user) return error(401, "unauthorized");
  const key = Deno.env.get("GEMINI_API_KEY");
  if (!key) return error(503, "ai_not_configured");
  const { data: allowed, error: limitError } = await client.rpc("consume_ai_request");
  if (limitError) return error(503, "ai_not_configured");
  if (!allowed) return error(429, "rate_limited");

  // Bound uploaded files before allocating their JSON representation.
  const reader = req.body?.getReader();
  if (!reader) return error(400, "empty_body");
  const chunks: Uint8Array[] = [];
  let size = 0;
  while (true) {
    const { done, value } = await reader.read();
    if (done) break;
    size += value.length;
    if (size > 21 * 1024 * 1024) {
      await reader.cancel();
      return error(413, "file_too_large");
    }
    chunks.push(value);
  }
  try {
    const bytes = new Uint8Array(size);
    let offset = 0;
    for (const chunk of chunks) { bytes.set(chunk, offset); offset += chunk.length; }
    const input = JSON.parse(new TextDecoder().decode(bytes));
    if (!Array.isArray(input.contents) || input.contents.length > 4) {
      return error(400, "invalid_contents");
    }
    const model = Deno.env.get("GEMINI_MODEL") || "gemini-flash-latest";
    const response = await fetch(
      `https://generativelanguage.googleapis.com/v1beta/models/${encodeURIComponent(model)}:generateContent`,
      {
        method: "POST",
        headers: { ...headers, "x-goog-api-key": key },
        body: JSON.stringify({
          contents: input.contents,
          systemInstruction: input.systemInstruction,
          generationConfig: {
            ...input.generationConfig,
            candidateCount: 1,
            maxOutputTokens: Math.min(16384, Number(input.generationConfig?.maxOutputTokens) || 8192),
          },
        }),
        signal: AbortSignal.timeout(60000),
      },
    );
    // Do not expose upstream diagnostics, credentials or CV content in logs.
    if (!response.ok) return error(response.status === 429 ? 429 : 502, "ai_request_failed");
    return new Response(await response.text(), { status: 200, headers });
  } catch (_) {
    return error(502, "ai_request_failed");
  }
});
