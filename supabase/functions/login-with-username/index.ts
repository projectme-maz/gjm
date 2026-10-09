import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const appOrigin = "https://projectme-maz.github.io";
const localOrigins = new Set([
  "http://127.0.0.1:8000",
  "http://localhost:8000",
  "http://127.0.0.1:8080",
  "http://localhost:8080",
]);
const corsHeaders = {
  "Access-Control-Allow-Origin": appOrigin,
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
  "Vary": "Origin",
};

function jsonResponse(status: number, body: Record<string, unknown>, origin: string) {
  return new Response(JSON.stringify(body), {
    status,
    headers: {
      ...corsHeaders,
      "Access-Control-Allow-Origin": origin,
      "Content-Type": "application/json",
    },
  });
}

Deno.serve(async (request: Request) => {
  const origin = request.headers.get("origin") || "";
  const allowedOrigin = origin === appOrigin || localOrigins.has(origin);
  if (request.method === "OPTIONS") {
    if (!allowedOrigin) return new Response(null, { status: 403 });
    return new Response("ok", { headers: { ...corsHeaders, "Access-Control-Allow-Origin": origin } });
  }
  if (!allowedOrigin) return jsonResponse(403, { error: "Origin not allowed." }, appOrigin);
  if (request.method !== "POST") return jsonResponse(405, { error: "Method not allowed." }, origin);

  const supabaseUrl = Deno.env.get("SUPABASE_URL");
  const anonKey = Deno.env.get("SUPABASE_ANON_KEY");
  const serviceRoleKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY");
  if (!supabaseUrl || !anonKey || !serviceRoleKey) {
    console.error("Missing Supabase function environment configuration.");
    return jsonResponse(500, { error: "Login service is not configured." }, origin);
  }

  let input: { action?: string; username?: string; password?: string };
  try {
    input = await request.json();
  } catch {
    return jsonResponse(400, { error: "Invalid request." }, origin);
  }

  const username = String(input.username || "").trim().toLowerCase();
  if (!/^[a-z0-9][a-z0-9._-]{2,29}$/.test(username)) {
    return jsonResponse(400, { error: "Username atau password salah." }, origin);
  }

  const adminClient = createClient(supabaseUrl, serviceRoleKey, {
    auth: { autoRefreshToken: false, persistSession: false },
  });
  const { data: account, error: lookupError } = await adminClient
    .from("stock_opname_usernames")
    .select("email")
    .eq("username", username)
    .maybeSingle();

  if (lookupError) {
    console.error("Username lookup failed:", lookupError.message);
    return jsonResponse(503, { error: "Login service is temporarily unavailable." }, origin);
  }
  if (!account) {
    if (input.action === "reset-password") {
      return jsonResponse(200, {
        message: "Jika username terdaftar, tautan pengaturan password telah dikirim ke email akun.",
      }, origin);
    }
    return jsonResponse(401, { error: "Username atau password salah." }, origin);
  }

  const authClient = createClient(supabaseUrl, anonKey, {
    auth: { autoRefreshToken: false, persistSession: false },
  });

  if (input.action === "reset-password") {
    const { error } = await authClient.auth.resetPasswordForEmail(account.email, {
      redirectTo: `${appOrigin}/gjm/`,
    });
    if (error) {
      console.error("Password reset request failed:", error.message);
      return jsonResponse(503, { error: "Tautan reset password gagal dikirim. Coba lagi nanti." }, origin);
    }
    return jsonResponse(200, {
      message: "Jika username terdaftar, tautan pengaturan password telah dikirim ke email akun.",
    }, origin);
  }

  if (input.action !== "sign-in" || typeof input.password !== "string" || !input.password) {
    return jsonResponse(400, { error: "Username atau password salah." }, origin);
  }

  const { data, error } = await authClient.auth.signInWithPassword({
    email: account.email,
    password: input.password,
  });
  if (error || !data.session) {
    return jsonResponse(401, { error: "Username atau password salah." }, origin);
  }

  return jsonResponse(200, {
    access_token: data.session.access_token,
    refresh_token: data.session.refresh_token,
  }, origin);
});
