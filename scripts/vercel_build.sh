#!/usr/bin/env bash
# Vercel buildCommand: build the Flutter web bundle with Supabase config.
# SUPABASE_URL / SUPABASE_ANON_KEY env vars override the baked-in defaults
# (the anon key is public by design).
set -euo pipefail

SUPABASE_URL="${SUPABASE_URL:-https://dutmsyjwrueyyrdeccol.supabase.co}"
SUPABASE_ANON_KEY="${SUPABASE_ANON_KEY:-eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImR1dG1zeWp3cnVleXlyZGVjY29sIiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODQ0Nzk4NDAsImV4cCI6MjEwMDA1NTg0MH0.wk_Y_1ZXcOKCj_09PNNn5uqDFQ5_hzbFqjUdlhrlXXA}"

flutter/bin/flutter build web --release \
  --dart-define=SUPABASE_URL="$SUPABASE_URL" \
  --dart-define=SUPABASE_ANON_KEY="$SUPABASE_ANON_KEY"
