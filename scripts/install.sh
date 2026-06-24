#!/usr/bin/env bash
set -euo pipefail
# Gentleman Agent -- Unix skill installer (Linux/macOS)
# Usage: ./scripts/install.sh
# Creates symlinks from repo skills/scripts to ~/.config/opencode/
# NOTE: This installs gentleman-agent-gh, NOT Gentle-AI.
#       For Gentle-AI see https://github.com/Gentleman-Programming/gentle-ai

REPO_DIR="$(cd "$(dirname "$0")/.." && pwd)"
SKILLS_SRC="$REPO_DIR/.agents/skills"
SKILLS_DST="${XDG_CONFIG_HOME:-$HOME/.config}/opencode/skills"
SCRIPTS_SRC="$REPO_DIR/scripts"
SCRIPTS_DST="${XDG_CONFIG_HOME:-$HOME/.config}/opencode/scripts"

echo "==> Gentleman Agent Installer (Unix)"

# Detect package managers for info
if command -v brew &>/dev/null; then
    echo "[info] Homebrew detected at $(brew --prefix)"
fi
if command -v scoop &>/dev/null; then
    echo "[info] Scoop detected at $SCOOP"
fi
if command -v choco &>/dev/null; then
    echo "[info] Chocolatey detected"
fi

mkdir -p "$SKILLS_DST" "$SCRIPTS_DST"

count=0
for skill in "$SKILLS_SRC"/*/; do
    name=$(basename "$skill")
    link="$SKILLS_DST/$name"
    if [ ! -L "$link" ] && [ ! -d "$link" ]; then
        ln -s "$skill" "$link"
        count=$((count + 1))
    fi
done
echo "[ok] $count skill symlinks created"

if [ ! -L "$SCRIPTS_DST" ] && [ ! -d "$SCRIPTS_DST" ]; then
    ln -s "$SCRIPTS_SRC" "$SCRIPTS_DST"
    echo "[ok] Scripts symlink created"
else
    echo "[warn] $SCRIPTS_DST already exists"
fi

echo ""
echo "Done! Run OpenCode to start using the skills."