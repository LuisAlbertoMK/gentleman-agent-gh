#!/usr/bin/env bash
if (set -o pipefail 2>/dev/null); then set -euo pipefail; else set -eu; fi
shopt -s nullglob 2>/dev/null || true
# Gentleman Agent — Linux/macOS environment setup
# Configures gentleman-agent-gh:
#   - Copies skills to ~/.config/opencode/skills/
#   - Sets GENTLEMAN_AGENT_ROOT env var
#   - Optionally installs gentle-ai CLI dependency
#
# Usage:
#   ./scripts/install.sh                        # interactive
#   ./scripts/install.sh --yes                  # non-interactive
#   ./scripts/install.sh --install-gentle-ai    # auto-install dep

GREEN='\033[0;32m'; CYAN='\033[0;36m'; YELLOW='\033[1;33m'; DIM='\033[2m'; NC='\033[0m'
info()  { printf "${CYAN}==>${NC} %s\n" "$*"; }
ok()    { printf "${GREEN}[ok]${NC} %s\n" "$*"; }
warn()  { printf "${YELLOW}[warn]${NC} %s\n" "$*"; }

YES=false
INSTALL_GENTLE_AI=false
while [ $# -gt 0 ]; do
    case "$1" in
        --yes) YES=true; shift ;;
        --install-gentle-ai) INSTALL_GENTLE_AI=true; shift ;;
        --help|-h) echo "Usage: install.sh [--yes] [--install-gentle-ai]"; exit 0 ;;
        *) echo "Unknown: $1"; exit 1 ;;
    esac
done

REPO_DIR="$(cd "$(dirname "$0")/.." && pwd)"
info "Gentleman Agent — Linux/macOS setup"
info "Repo: ${REPO_DIR}\n"

# ── Step 1: Link skills to OpenCode config ──────────────────────────
SKILL_SRC="${REPO_DIR}/.agents/skills"
SKILL_DEST="${HOME}/.config/opencode/skills"
info "Linking skills → ${SKILL_DEST}"
mkdir -p "$SKILL_DEST"
for skill_dir in "$SKILL_SRC"/*/; do
    [ -d "$skill_dir" ] || continue
    name="$(basename "$skill_dir")"
    if [ -L "$SKILL_DEST/$name" ] && [ "$(readlink "$SKILL_DEST/$name")" = "$skill_dir" ]; then
        ok "  = ${name} (linked)"
    elif [ -e "$SKILL_DEST/$name" ]; then
        warn "  ~ ${name} (exists, skip)"
    else
        ln -s "$skill_dir" "$SKILL_DEST/$name" 2>/dev/null || cp -r "$skill_dir" "$SKILL_DEST/$name"
        ok "  + ${name}"
    fi
done
ok "Skills ready"

# ── Step 2: Set GENTLEMAN_AGENT_ROOT ────────────────────────────────
_append_ga_root() {
    local rc="$1"
    grep -q "GENTLEMAN_AGENT_ROOT" "$rc" 2>/dev/null && return 0
    printf '\n# Gentleman Agent\nexport GENTLEMAN_AGENT_ROOT="%s"\n' "$REPO_DIR" >> "$rc"
    return 1
}
if _append_ga_root "${HOME}/.bashrc" || _append_ga_root "${HOME}/.zshrc" 2>/dev/null; then
    ok "GENTLEMAN_AGENT_ROOT already configured"
else
    info "GENTLEMAN_AGENT_ROOT added to ~/.bashrc (and ~/.zshrc if exists)"
    export GENTLEMAN_AGENT_ROOT="${REPO_DIR}"
    ok "GENTLEMAN_AGENT_ROOT set (restart shell or 'source ~/.bashrc')"
fi
unset _append_ga_root

# ── Step 3: Optional gentle-ai CLI ──────────────────────────────────
if ! command -v gentle-ai &>/dev/null; then
    if [ "$INSTALL_GENTLE_AI" = true ] || [ "$YES" = true ]; then
        info "Installing gentle-ai CLI..."
        curl -fsSL https://raw.githubusercontent.com/Gentleman-Programming/gentle-ai/main/scripts/install.sh | bash
    else
        warn "gentle-ai CLI not found. Install it? [Y/n]"
        if [ "$YES" = false ] && [ -t 0 ]; then
            read -r resp </dev/tty
            case "$resp" in n|N) ;; *)
                info "Installing gentle-ai CLI..."
                curl -fsSL https://raw.githubusercontent.com/Gentleman-Programming/gentle-ai/main/scripts/install.sh | bash
            ;; esac
        elif [ "$YES" = false ]; then
            warn "Non-interactive shell — use --yes or --install-gentle-ai to auto-install"
            warn "Skipping gentle-ai CLI install. Install manually:"
            warn "  curl -fsSL https://raw.githubusercontent.com/Gentleman-Programming/gentle-ai/main/scripts/install.sh | bash"
        fi
    fi
else
    ok "gentle-ai CLI already installed"
fi

# ── Done ─────────────────────────────────────────────────────────────
echo ""
printf "${GREEN}✅ gentleman-agent-gh setup complete${NC}\n"
echo ""
echo "  Restart your shell or run:"
echo "    source ~/.bashrc"
echo ""
echo "  Verify:"
echo "    ls ~/.config/opencode/skills/"
echo "    echo \$GENTLEMAN_AGENT_ROOT"
