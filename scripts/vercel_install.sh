#!/usr/bin/env bash
# Vercel installCommand: fetch the Flutter SDK and resolve pub dependencies.
set -euo pipefail

FLUTTER_VERSION="${FLUTTER_VERSION:-3.32.8}"

if [ -d flutter ]; then
  (cd flutter && git fetch --depth 1 origin "$FLUTTER_VERSION" && git checkout FETCH_HEAD)
else
  git clone https://github.com/flutter/flutter.git -b "$FLUTTER_VERSION" --depth 1
fi

flutter/bin/flutter config --enable-web --no-analytics
flutter/bin/flutter pub get
