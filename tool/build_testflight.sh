#!/bin/sh
set -eu

cd "$(dirname "$0")/.."

if [ ! -f .env.ai.local ]; then
  echo "Missing .env.ai.local. Add GEMINI_API_KEY before creating a TestFlight build." >&2
  exit 1
fi

# Flutter embeds the test-only Gemini configuration in this IPA. The file is
# ignored by Git and is never copied into the source tree. A unique build
# number keeps subsequent TestFlight uploads accepted by App Store Connect.
exec flutter build ipa --release --build-number="$(date +%s)" \
  --dart-define-from-file=.env.ai.local "$@"
