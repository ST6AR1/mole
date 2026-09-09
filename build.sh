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

echo ">> Code-signing (ad-hoc)..."
# On iCloud-synced folders, Finder/fileprovider can re-tag the bundle with
# FinderInfo/xattrs a moment after we strip them, which makes codesign fail
# with "resource fork ... not allowed". Retry a few times to ride out the race.
for attempt in 1 2 3 4 5; do
  xattr -cr "$APP" 2>/dev/null
  xattr -c "$APP" 2>/dev/null
  if codesign --force --deep -s - "$APP" 2>/tmp/smartlaunch-codesign-err.log; then
    break
  fi
  if [ "$attempt" = 5 ]; then
    cat /tmp/smartlaunch-codesign-err.log
    exit 1
  fi
  sleep 0.3
done

echo ">> Done: $APP"
echo "   Move it to /Applications or ~/Applications, or run ./install.sh"
