#!/bin/bash
# install.sh — build mole.app, install helper scripts, and set up the `ports` shell alias.
# Usage: ./install.sh
set -euo pipefail
cd "$(dirname "$0")"

./build.sh

echo ">> Installing helper scripts to ~/bin/smartlaunch ..."
mkdir -p ~/bin/smartlaunch
cp bin/smart-launch.sh ~/bin/smartlaunch/smart-launch.sh
cp bin/ports.sh ~/bin/smartlaunch/ports.sh
chmod +x ~/bin/smartlaunch/smart-launch.sh ~/bin/smartlaunch/ports.sh

echo ">> Installing mole.app to ~/Applications ..."
mkdir -p ~/Applications
rm -rf ~/Applications/mole.app
cp -R mole.app ~/Applications/mole.app

SHELL_RC="$HOME/.zshrc"
MARKER="# Smart Launch tools"
if ! grep -q "$MARKER" "$SHELL_RC" 2>/dev/null; then
  echo ">> Adding 'ports' / 'ports-watch' aliases to $SHELL_RC ..."
  {
    echo ""
    echo "$MARKER"
    echo 'export PATH="$HOME/bin/smartlaunch:$PATH"'
    echo 'alias ports="$HOME/bin/smartlaunch/ports.sh"'
    echo 'alias ports-watch="$HOME/bin/smartlaunch/ports.sh --watch"'
  } >> "$SHELL_RC"
else
  echo ">> $SHELL_RC already has Smart Launch aliases, skipping."
fi

echo ""
echo "All set!"
echo "  - Open ~/Applications/mole.app (drag it to your Dock for quick access)"
echo "  - Open a new terminal tab and run 'ports' to see what's listening on localhost"
