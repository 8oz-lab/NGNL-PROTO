#!/bin/bash
# Richtet Cloud-Sessions ein: Godot 4.7 (wie im Editor des Nutzers) installieren und das
# Projekt einmal importieren, damit Tests und Testaufnahmen sofort laufen.
set -euo pipefail

if [ "${CLAUDE_CODE_REMOTE:-}" != "true" ]; then
  exit 0
fi

GODOT_VERSION="4.7"
GODOT_DIR="$HOME/.local/godot-$GODOT_VERSION"
GODOT_BIN="$GODOT_DIR/Godot_v${GODOT_VERSION}-stable_linux.x86_64"

if [ ! -x "$GODOT_BIN" ]; then
  mkdir -p "$GODOT_DIR"
  curl -sSL -o "$GODOT_DIR/godot.zip" \
    "https://github.com/godotengine/godot/releases/download/${GODOT_VERSION}-stable/Godot_v${GODOT_VERSION}-stable_linux.x86_64.zip"
  unzip -oq "$GODOT_DIR/godot.zip" -d "$GODOT_DIR"
  rm -f "$GODOT_DIR/godot.zip"
  chmod +x "$GODOT_BIN"
fi
ln -sf "$GODOT_BIN" /usr/local/bin/godot

# Projekt importieren (Modelle, Klassen-Cache); Meldungen des Dummy-Renderers sind harmlos
cd "${CLAUDE_PROJECT_DIR:-$(pwd)}"
timeout 600 godot --headless --path . --import > /tmp/godot-import.log 2>&1 || true

if [ -n "${CLAUDE_ENV_FILE:-}" ]; then
  echo "export GODOT=/usr/local/bin/godot" >> "$CLAUDE_ENV_FILE"
fi
