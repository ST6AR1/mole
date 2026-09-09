#!/bin/bash
# build.sh — compile SmartLaunch.app from source.
# Usage: ./build.sh
set -euo pipefail
cd "$(dirname "$0")"

APP="SmartLaunch.app"
rm -rf "$APP"
mkdir -p "$APP/Contents/MacOS" "$APP/Contents/Resources"

echo ">> Compiling Swift source..."
swiftc -O -o "$APP/Contents/MacOS/SmartLaunch" App/main.swift
chmod +x "$APP/Contents/MacOS/SmartLaunch"

echo ">> Copying Info.plist..."
cp App/Info.plist "$APP/Contents/Info.plist"

if [ -f icon/icon-source.png ]; then
  echo ">> Building app icon..."
  ICONSET="$(mktemp -d)/AppIcon.iconset"
  mkdir -p "$ICONSET"
  for sz in 16 32 128 256 512; do
    sips -z $sz $sz icon/icon-source.png --out "$ICONSET/icon_${sz}x${sz}.png" >/dev/null
    dbl=$((sz*2))
    sips -z $dbl $dbl icon/icon-source.png --out "$ICONSET/icon_${sz}x${sz}@2x.png" >/dev/null
  done
  iconutil -c icns "$ICONSET" -o "$APP/Contents/Resources/AppIcon.icns"
fi

echo ">> Stripping extended attributes (avoids codesign 'detritus' errors on iCloud-synced folders)..."
xattr -cr "$APP"
xattr -c "$APP"

echo ">> Code-signing (ad-hoc)..."
codesign --force --deep -s - "$APP"

echo ">> Done: $APP"
echo "   Move it to /Applications or ~/Applications, or run ./install.sh"
