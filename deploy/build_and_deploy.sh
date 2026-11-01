#!/usr/bin/env bash
# ./build_and_deploy.sh stage   -> build the app and upload a PREVIEW (staging)
# ./build_and_deploy.sh prod    -> publish what is currently in public/ to PRODUCTION
set -e
HERE="$(cd "$(dirname "$0")" && pwd)"
PROJECT="$HERE/.."
MODE="${1:-}"

if [ "$MODE" = "stage" ]; then
  cd "$PROJECT"
  flutter config --enable-web >/dev/null
  flutter build web --release
  rm -rf "$HERE/public"/*
  cp -r build/web/* "$HERE/public/"
  rm -f "$HERE/public/vercel.json"
  cd "$HERE"
  vercel
elif [ "$MODE" = "prod" ]; then
  cd "$HERE"
  vercel --prod
else
  echo "Use: ./build_and_deploy.sh stage   or   ./build_and_deploy.sh prod"
  exit 1
fi