#!/usr/bin/env bash
# Usage: ./build_and_deploy.sh /path/to/your/flutter_project
# Optional: APP_KEY=yourkey ./build_and_deploy.sh /path/to/project
set -e
PROJECT="${1:?Pass the path to your Flutter project}"
HERE="$(cd "$(dirname "$0")" && pwd)"

cd "$PROJECT"
flutter config --enable-web >/dev/null
[ -d web ] || flutter create . --platforms=web
if [ -n "$APP_KEY" ]; then
  flutter build web --release --dart-define=APP_KEY="$APP_KEY"
else
  flutter build web --release
fi

rm -rf "$HERE/public"/*
cp -r build/web/* "$HERE/public/"

cd "$HERE"
vercel --prod
