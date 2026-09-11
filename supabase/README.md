# AI server deployment

Deployment is pending. Do not publish a build with AI_USE_SUPABASE=true until
the function, migration, and secrets are deployed and tested against this project.

1. Apply migrations/202609100001_ai_rate_limit.sql to the selected project.
2. Deploy functions/cv-ai with JWT verification enabled.
3. Set GEMINI_API_KEY in Edge Function Secrets, never in an application-readable
   database table. Optionally set GEMINI_MODEL (default gemini-flash-latest).
4. Test a real authenticated session with summary text and a CV image/PDF.
5. Build with tool/build_testflight.sh or tool/build_android_release.sh. These
   scripts enable the proxy and no longer embed .env.ai.local in release builds.

The proxy requires a real Supabase session; local/demo-only login is insufficient.
Requests are limited to 30 per user per hour. No CV contents or provider errors
are logged. Both direct Gemini development mode and proxy mode preserve the
existing source-language prompts and response schema.

# Remaining release blockers

- Store receipt verification and authoritative expiry/renewal/refund handling
  are not implemented by the existing InAppPurchaseService. Its local PRO grant
  and restore flow must not be treated as server-verified subscriptions.
- Confirm weekly/monthly/yearly product IDs in both stores and sandbox purchases.
- Android release currently uses a debug signing configuration. Configure the
  actual upload key before publishing to Play.
- Validate device camera, microphone, gallery, converter outputs and PDF glyphs
  visually on iOS and Android; widget tests do not establish hardware parity.
