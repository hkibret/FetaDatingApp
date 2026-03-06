#!/bin/bash
set -e

if [ -z "$SUPABASE_URL" ]; then
  echo "Missing SUPABASE_URL"
  exit 1
fi

if [ -z "$SUPABASE_ANON_KEY" ]; then
  echo "Missing SUPABASE_ANON_KEY"
  exit 1
fi

git clone --depth 1 --branch stable https://github.com/flutter/flutter.git
export PATH="$PWD/flutter/bin:$PATH"

flutter --version
flutter config --enable-web
flutter pub get

echo "Building with SUPABASE_URL=$SUPABASE_URL"
echo "SUPABASE_ANON_KEY length=${#SUPABASE_ANON_KEY}"

flutter build web --release \
  --dart-define=SUPABASE_URL="$SUPABASE_URL" \
  --dart-define=SUPABASE_ANON_KEY="$SUPABASE_ANON_KEY"