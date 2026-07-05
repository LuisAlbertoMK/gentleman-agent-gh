#!/usr/bin/env bash
# Gentleman Agent — Linux/macOS one-shot machine setup
# Port of scripts/setup-machine.ps1 for POSIX shells.
# Creates global shortcuts, sets env vars, links skills, verifies.
#
# Usage:
#   ./scripts/setup-machine.sh                           # interactive
#   ./scripts/setup-machine.sh --repo-dir /path/to/repo  # from anywhere
#   ./scripts/setup-machine.sh --skip-env-var            # CI/containers
#   ./scripts/setup-machine.sh --skip-shortcuts          # no shell wrappers

if (set -o pipefail 2>/dev/null); then set -euo pipefail; else set -eu; fi
shopt -s nullglob 2>/dev/null || true

# ── Colors ───────────────────────────────────────────────────────────
GREEN='\033[0;32m'; CYAN='\033[0;36m'; YELLOW='\033[1;33m'; RED='\033[0;31m'; DIM='\033[2m'; NC='\033[0m'
info()  { printf "${CYAN}==>${NC} %s\n" "$*"; }
ok()    { printf "${GREEN}[ok]${NC} %s\n" "$*"; }
warn()  { printf "${YELLOW}[warn]${NC} %s\n" "$*"; }
err()   { printf "${RED}[err]${NC} %s\n" "$*"; exit 1; }
skip()  { printf "${DIM}[skip]${NC} %s\n" "$*"; }

# ── Args ─────────────────────────────────────────────────────────────
REPO_DIR=""
SKIP_ENV_VAR=false
SKIP_SHORTCUTS=false
while [ $# -gt 0 ]; do
    case "$1" in
        --repo-dir) REPO_DIR="$2"; shift 2 ;;
        --repo-dir=*) REPO_DIR="${1#*=}"; shift ;;
        --skip-env-var) SKIP_ENV_VAR=true; shift ;;
        --skip-shortcuts) SKIP_SHORTCUTS=true; shift ;;
        --help|-h) echo "Usage: setup-machine.sh [--repo-dir PATH] [--skip-env-var] [--skip-shortcuts]"; exit 0 ;;
        *) echo "Unknown: $1"; exit 1 ;;
    esac
done

if [ -z "$REPO_DIR" ]; then
    REPO_DIR="$(cd "$(dirname "$0")/.." && pwd)"
fi

# ── Validate repo ───────────────────────────────────────────────────
info "Validating repo at ${REPO_DIR}"
for f in "opencode.json" "AGENTS.md" ".agents/skills"; do
    if [ ! -e "${REPO_DIR}/${f}" ]; then
        err "Missing ${f} — is ${REPO_DIR} the gentleman-agent-gh repo?"
    fi
done
ok "Repo structure validated"

# ── Step 1: GENTLEMAN_AGENT_ROOT ────────────────────────────────────
_upsert_env_var() {
    local name="$1" value="$2"
    # Already set in this shell?
    if [ "${!name:-}" = "$value" ]; then
        return 0
    fi
    export "${name}=${value}"
    # Persist in shell rc
    for rc in "${HOME}/.bashrc" "${HOME}/.zshrc"; do
        [ -f "$rc" ] || continue
        if grep -q "export ${name}=" "$rc" 2>/dev/null; then
            # Update existing
            if [ "$(uname)" = "Darwin" ]; then
                sed -i '' "s|export ${name}=.*|export ${name}=\"${value}\"|" "$rc"
            else
                sed -i "s|export ${name}=.*|export ${name}=\"${value}\"|" "$rc"
            fi
        else
            printf '\n# Gentleman Agent\nexport %s="%s"\n' "$name" "$value" >> "$rc"
        fi
    done
    return 1  # was updated
}

if [ "$SKIP_ENV_VAR" = false ]; then
    info "Setting GENTLEMAN_AGENT_ROOT → ${REPO_DIR}"
    if _upsert_env_var "GENTLEMAN_AGENT_ROOT" "$REPO_DIR"; then
        skip "GENTLEMAN_AGENT_ROOT already set correctly"
    else
        ok "GENTLEMAN_AGENT_ROOT set (restart shell or source ~/.bashrc)"
    fi
else
    skip "GENTLEMAN_AGENT_ROOT (via --skip-env-var)"
fi

# ── Step 2: OpenCode env vars ───────────────────────────────────────
if [ "$SKIP_ENV_VAR" = false ]; then
    info "Setting OpenCode environment variables"
    declare -A OC_VARS
    OC_VARS["OPENCODE_CACHE_DIR"]="${REPO_DIR}/.vmk-cache"
    OC_VARS["OPENCODE_CONFIG_DIR"]="${REPO_DIR}/.vmk-config"
    OC_VARS["OPENCODE_DB"]="${REPO_DIR}/.vmk-data/opencode.db"
    OC_VARS["OPENCODE_DISABLE_EMBEDDED_WEB_UI"]="true"
    OC_VARS["OPENCODE_DISABLE_MODELS_FETCH"]="true"
    OC_VARS["OPENCODE_EXPERIMENTAL_DISABLE_FILEWATCHER"]="true"

    for key in "${!OC_VARS[@]}"; do
        if _upsert_env_var "$key" "${OC_VARS[$key]}"; then
            skip "${key} already set"
        else
            ok "${key} set"
        fi
    done
else
    skip "OpenCode env vars (via --skip-env-var)"
fi

# ── Step 3: Global shortcuts ────────────────────────────────────────
if [ "$SKIP_SHORTCUTS" = false ]; then
    info "Creating global shell shortcuts"
    BIN_DIR="${HOME}/.local/bin"
    mkdir -p "$BIN_DIR"

    # gentleman-vmk
    if [ ! -f "${BIN_DIR}/gentleman-vmk" ]; then
        cat > "${BIN_DIR}/gentleman-vmk" << 'SCRIPT'
#!/usr/bin/env bash
exec opencode --agent gentleman-vMK "$@"
SCRIPT
        chmod +x "${BIN_DIR}/gentleman-vmk"
        ok "Created ${BIN_DIR}/gentleman-vmk"
    else
        skip "${BIN_DIR}/gentleman-vmk already exists"
    fi

    # Add ~/.local/bin to PATH if not already
    case ":${PATH}:" in
        *:"${BIN_DIR}":*) ;;
        *)
            warn "${BIN_DIR} not in PATH — add 'export PATH=\"\$HOME/.local/bin:\$PATH\"' to ~/.bashrc"
            ;;
    esac
else
    skip "Global shortcuts (via --skip-shortcuts)"
fi

# ── Step 4: Global opencode config ──────────────────────────────────
info "Syncing global opencode config from repo"
GLOBAL_CONFIG="${HOME}/.config/opencode/opencode.json"
REPO_CONFIG="${REPO_DIR}/opencode.json"

if [ -f "$GLOBAL_CONFIG" ] && [ -f "$REPO_CONFIG" ]; then
    # Use jq if available, otherwise minimal sed approach
    if command -v jq &>/dev/null; then
        local updated=false

        # default_agent
        local current_agent
        current_agent=$(jq -r '.default_agent // ""' "$GLOBAL_CONFIG")
        if [ "$current_agent" != "gentleman-vMK" ]; then
            jq '.default_agent = "gentleman-vMK"' "$GLOBAL_CONFIG" > "${GLOBAL_CONFIG}.tmp" && mv "${GLOBAL_CONFIG}.tmp" "$GLOBAL_CONFIG"
            updated=true
        fi

        # mcp, permission, skills from repo
        for section in mcp permission skills; do
            local repo_val
            repo_val=$(jq ".${section} // empty" "$REPO_CONFIG" 2>/dev/null)
            if [ -n "$repo_val" ]; then
                jq ".${section} = ${repo_val}" "$GLOBAL_CONFIG" > "${GLOBAL_CONFIG}.tmp" && mv "${GLOBAL_CONFIG}.tmp" "$GLOBAL_CONFIG"
                updated=true
            fi
        done

        if [ "$updated" = true ]; then
            ok "Global config synced from repo (default_agent + mcp + permission + skills)"
        else
            skip "Global config already up to date"
        fi
    else
        warn "jq not found — cannot auto-sync opencode.json. Install jq or sync manually."
        warn "  cp ${REPO_CONFIG} ${GLOBAL_CONFIG}"
    fi
else
    warn "Global or repo config not found — sync manually"
fi

# ── Step 5: Global skill config (symlinks) ──────────────────────────
info "Setting up global skill config"
SKILL_DEST="${HOME}/.config/opencode/skills"
SKILL_SRC="${REPO_DIR}/.agents/skills"

if [ ! -d "$SKILL_DEST" ]; then
    mkdir -p "$SKILL_DEST"
fi

# Remove broken symlinks first
for d in "$SKILL_DEST"/*/; do
    [ -L "$d" ] && [ ! -e "$d" ] && rm "$d" && warn "  Removed broken link: $(basename "$d")"
done

# Create symlinks for each skill
if [ ! -L "${SKILL_DEST}/_shared" ]; then
    ln -s "$SKILL_SRC"/*/ "$SKILL_DEST"/ 2>/dev/null || {
        # Fallback: symlink one by one
        for skill_dir in "$SKILL_SRC"/*/; do
            [ -d "$skill_dir" ] || continue
            name="$(basename "$skill_dir")"
            [ -L "${SKILL_DEST}/${name}" ] && continue
            ln -s "$skill_dir" "${SKILL_DEST}/${name}" 2>/dev/null || cp -r "$skill_dir" "${SKILL_DEST}/${name}"
        done
    }
    ok "Skills symlinked to ${SKILL_DEST}"
else
    skip "Skills already configured"
fi

# ── Step 6: Verify ──────────────────────────────────────────────────
info "Verifying setup"
all_ok=true

if [ "${GENTLEMAN_AGENT_ROOT:-}" = "$REPO_DIR" ]; then
    ok "GENTLEMAN_AGENT_ROOT"
else
    warn "GENTLEMAN_AGENT_ROOT — not set in current shell (run 'source ~/.bashrc')"
    all_ok=false
fi

if [ -f "${REPO_DIR}/opencode.json" ]; then
    ok "opencode.json exists"
else
    warn "opencode.json — missing"
    all_ok=false
fi

if command -v gentleman-vmk &>/dev/null; then
    ok "Global shortcut: gentleman-vmk"
else
    warn "Global shortcut: gentleman-vmk — not in PATH"
    all_ok=false
fi

echo ""
if [ "$all_ok" = true ]; then
    printf "${GREEN}✅ Machine setup COMPLETE${NC}\n"
    printf "   ${CYAN}→ Run 'gentleman-vmk' to launch${NC}\n"
else
    printf "${YELLOW}⚠️  Setup PARTIAL — review warnings above${NC}\n"
fi
