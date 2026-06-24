#!/usr/bin/env bash
set -euo pipefail
# Gentleman Agent — universal bootstrap entry point
# Usage: curl -fsSL https://gentleman.sh | bash
#        wget -qO- https://gentleman.sh | bash
#        ./scripts/bootstrap.sh [--update] [--repo <url>]
#
# Detects OS, installs dependencies, clones repo, runs installer.

REPO_URL="${GENTLEMAN_REPO:-https://github.com/anomalco/opencode.git}"
INSTALL_DIR="${GENTLEMAN_DIR:-$HOME/.local/share/gentleman-agent}"
BRANCH="${GENTLEMAN_BRANCH:-master}"

# ── Color helpers (no-op if piped) ──────────────────────────────────
if [ -t 1 ]; then
    RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'
    CYAN='\033[0;36m'; BOLD='\033[1m'; NC='\033[0m'
else
    RED=''; GREEN=''; YELLOW=''; CYAN=''; BOLD=''; NC=''
fi
info()  { printf "${CYAN}==>${NC} %s\n" "$*"; }
ok()    { printf "${GREEN}[ok]${NC} %s\n" "$*"; }
warn()  { printf "${YELLOW}[warn]${NC} %s\n" "$*"; }
err()   { printf "${RED}[err]${NC} %s\n" "$*"; exit 1; }

# ── Usage / help ────────────────────────────────────────────────────
show_help() {
    cat <<EOF
Gentleman Agent Bootstrap — ${BOLD}${CYAN}v1.0.0${NC}

Usage:
  curl -fsSL https://gentleman.sh | bash
  ./scripts/bootstrap.sh [options]

Options:
  --repo <url>   Git repository URL (default: $REPO_URL)
  --branch <ref> Git branch/tag (default: $BRANCH)
  --update       Update existing installation
  --help         Show this message

Environment:
  GENTLEMAN_REPO   Override repo URL
  GENTLEMAN_DIR    Override install directory
  GENTLEMAN_BRANCH Override git branch
EOF
    exit 0
}
for arg in "$@"; do case "$arg" in --help|-h) show_help;; esac; done

# ── Safety check: ensure we're not quietly installing ──────────────
if [ ! -t 0 ]; then
    info "Piped install detected (curl | bash). Confirming..."
    printf "Install Gentleman Agent to ${BOLD}${INSTALL_DIR}${NC}? [Y/n] "
    read -r confirm </dev/tty || true
    case "$confirm" in n*|N*) echo "Aborted."; exit 0;; esac
fi

# ── OS & arch detection ─────────────────────────────────────────────
detect_os() {
    case "$(uname -s)" in
        Linux*)  echo "linux";;
        Darwin*) echo "macos";;
        CYGWIN*|MINGW*|MSYS*) echo "windows";;
        *)       err "Unsupported OS: $(uname -s)";;
    esac
}
detect_arch() {
    case "$(uname -m)" in
        x86_64|amd64) echo "x86_64";;
        aarch64|arm64) echo "arm64";;
        *)            echo "$(uname -m)";;
    esac
}
OS=$(detect_os)
ARCH=$(detect_arch)
info "Detected: ${OS} (${ARCH})"

# ── Dependency check ────────────────────────────────────────────────
check_dep() {
    if ! command -v "$1" &>/dev/null; then
        warn "$1 not found. Attempting to install..."
        return 1
    fi
    return 0
}

if ! check_dep git; then
    case "$OS" in
        linux)
            if command -v apt-get &>/dev/null; then
                sudo apt-get update -qq && sudo apt-get install -y -qq git
            elif command -v dnf &>/dev/null; then
                sudo dnf install -y git
            elif command -v pacman &>/dev/null; then
                sudo pacman -S --noconfirm git
            else
                err "No package manager found. Install git manually."
            fi
            ;;
        macos)
            if command -v brew &>/dev/null; then
                brew install git
            else
                err "Install Xcode Command Line Tools: xcode-select --install"
            fi
            ;;
        windows)
            err "Install Git for Windows from https://git-scm.com/download/win"
            ;;
    esac
fi

# ── Locate bash (Windows needs Git Bash) ────────────────────────────
BASH_EXE="bash"
if [ "$OS" = "windows" ]; then
    for candidate in "$PROGRAMFILES/Git/bin/bash.exe" \
                     "$LOCALAPPDATA/Programs/Git/bin/bash.exe" \
                     "$PROGRAMW6432/Git/bin/bash.exe"; do
        if [ -x "$candidate" ]; then
            BASH_EXE="$candidate"
            break
        fi
    done
    if [ ! -x "$BASH_EXE" ]; then
        BASH_EXE=$(command -v bash 2>/dev/null || echo "")
        [ -z "$BASH_EXE" ] && err "Git Bash not found. Install Git for Windows."
    fi
fi

# ── Clone / update repo ─────────────────────────────────────────────
if [ -d "$INSTALL_DIR/.git" ]; then
    if [ "${1:-}" = "--update" ]; then
        info "Updating existing installation at $INSTALL_DIR"
        git -C "$INSTALL_DIR" fetch origin "$BRANCH"
        git -C "$INSTALL_DIR" reset --hard "origin/$BRANCH"
    else
        info "Already installed at $INSTALL_DIR"
        printf "Run with --update to refresh, or skip? [s/U]: "
        read -r action </dev/tty || true
        case "$action" in s*|S*) ok "Skipped"; exit 0;; esac
        git -C "$INSTALL_DIR" pull --ff-only origin "$BRANCH" || {
            warn "Pull failed, re-cloning..."
            rm -rf "$INSTALL_DIR"
            git clone --depth 1 --branch "$BRANCH" "$REPO_URL" "$INSTALL_DIR"
        }
    fi
else
    info "Cloning $REPO_URL (branch: $BRANCH)"
    mkdir -p "$(dirname "$INSTALL_DIR")"
    git clone --depth 1 --branch "$BRANCH" "$REPO_URL" "$INSTALL_DIR"
fi

# ── Run platform installer ──────────────────────────────────────────
cd "$INSTALL_DIR"
case "$OS" in
    linux|macos)
        chmod +x scripts/install.sh
        ./scripts/install.sh
        ;;
    windows)
        if command -v powershell &>/dev/null; then
            powershell -NoProfile -ExecutionPolicy Bypass -File scripts/install.ps1
        elif command -v pwsh &>/dev/null; then
            pwsh -NoProfile -File scripts/install.ps1
        else
            err "PowerShell not found. Run scripts/install.ps1 manually."
        fi
        ;;
esac

# ── Next steps ──────────────────────────────────────────────────────
echo ""
info "${BOLD}Gentleman Agent installed!${NC}"
echo ""
echo "  ${CYAN}Install dir:${NC}  $INSTALL_DIR"
echo "  ${CYAN}Skills:${NC}      ~/.config/opencode/skills/*"
echo "  ${CYAN}Scripts:${NC}     ~/.config/opencode/scripts/*"
echo ""
echo "  Run OpenCode to activate. To verify:"
echo "    ls ~/.config/opencode/skills"
echo ""
echo "  For updates later:"
echo "    cd $INSTALL_DIR && git pull && ./scripts/install.sh"
echo ""
