#!/bin/bash
# make-dmg.sh — build mole.app and package it as a distributable .dmg.
# Usage: ./make-dmg.sh
set -euo pipefail
cd "$(dirname "$0")"

VERSION="$(grep -m1 'currentVersion = ' App/main.swift | sed -E 's/.*"([0-9.]+)".*/\1/')"
DMG_NAME="mole-${VERSION}.dmg"

./build.sh

echo ">> Staging DMG contents..."
STAGE="$(mktemp -d)/dmg"
mkdir -p "$STAGE"
cp -R mole.app "$STAGE/mole.app"
ln -s /Applications "$STAGE/Applications"

rm -f "$DMG_NAME"
echo ">> Creating $DMG_NAME..."
hdiutil create -volname "mole" -srcfolder "$STAGE" -ov -format UDZO "$DMG_NAME"

rm -rf "$STAGE"
echo ">> Done: $DMG_NAME"
