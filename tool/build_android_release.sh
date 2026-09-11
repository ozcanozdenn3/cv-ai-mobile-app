#!/bin/sh
set -eu

cd "$(dirname "$0")/.."

# Deploy cv-ai and configure its secrets before using this release.
exec flutter build appbundle --release --dart-define=AI_USE_SUPABASE=true "$@"
