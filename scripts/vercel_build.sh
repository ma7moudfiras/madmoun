#!/usr/bin/env bash
# Vercel buildCommand: build the Flutter web bundle with Supabase config.
# SUPABASE_URL / SUPABASE_ANON_KEY env vars override the baked-in defaults
# (the anon key is public by design).
set -euo pipefail

SUPABASE_URL="${SUPABASE_URL:-https://dutmsyjwrueyyrdeccol.supabase.co}"
SUPABASE_ANON_KEY="${SUPABASE_ANON_KEY:-eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImR1dG1zeWp3cnVleXlyZGVjY29sIiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODQ0Nzk4NDAsImV4cCI6MjEwMDA1NTg0MH0.wk_Y_1ZXcOKCj_09PNNn5uqDFQ5_hzbFqjUdlhrlXXA}"
# Off until the provider is actually configured in the Supabase dashboard —
# set to "true" in Vercel's project env vars to flip a button on.
ENABLE_GOOGLE_AUTH="${ENABLE_GOOGLE_AUTH:-false}"
ENABLE_APPLE_AUTH="${ENABLE_APPLE_AUTH:-false}"

# --no-web-resources-cdn bundles CanvasKit locally so it is served from the
# same origin (Vercel's edge, brotli) instead of gstatic.com — much faster
# first paint, especially on networks where gstatic is slow to reach.
flutter/bin/flutter build web --release --no-web-resources-cdn \
  --dart-define=SUPABASE_URL="$SUPABASE_URL" \
  --dart-define=SUPABASE_ANON_KEY="$SUPABASE_ANON_KEY" \
  --dart-define=ENABLE_GOOGLE_AUTH="$ENABLE_GOOGLE_AUTH" \
  --dart-define=ENABLE_APPLE_AUTH="$ENABLE_APPLE_AUTH"

node scripts/build_output_api.mjs
