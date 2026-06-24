#!/usr/bin/env bash
set -euo pipefail
# Gentleman CLI - backup/restore/status
REPO="$(cd "$(dirname "$0")/.." && pwd)"
CFG="${XDG_CONFIG_HOME:-$HOME/.config}/opencode"
if [ -t 1 ]; then R='\033[0;31m'; G='\033[0;32m'; Y='\033[1;33m'; C='\033[0;36m'; B='\033[1m'; N='\033[0m'
else R=''; G=''; Y=''; C=''; B=''; N=''; fi
info() { printf "${C}==>${N} %s\n" "$*"; }
ok() { printf "${G}[ok]${N} %s\n" "$*"; }
warn() { printf "${Y}[warn]${N} %s\n" "$*"; }
err() { printf "${R}[err]${N} %s\n" "$*"; exit 1; }
cmd_backup() {
  if [ ! -d "$CFG/.git" ]; then
    info "Initializing git repo at $CFG"
    git init -q "$CFG"
    printf 'scripts/\nnode_modules/\n' > "$CFG/.gitignore"
    git -C "$CFG" add .gitignore && git -C "$CFG" commit -m "init: backup repo" -q
  fi
  git -C "$CFG" add -A 2>/dev/null || true
  if git -C "$CFG" diff --cached --quiet; then ok "No changes."; return; fi
  ts=$(date "+%Y-%m-%d %H:%M")
  git -C "$CFG" commit -m "backup $ts" -q
  ok "Backup: $ts"
  info "Snapshots: $(git -C "$CFG" rev-list --count HEAD)"
}
cmd_restore() {
  if [ ! -d "$CFG/.git" ]; then err "No backup repo - run 'gentleman backup' first"; fi
  c=$(git -C "$CFG" rev-list --count HEAD)
  echo "=== Snapshots ($c) ==="
  git -C "$CFG" log --oneline --decorate -20
  if [ $# -eq 0 ]; then
    read -p "Revision (or 'q'): " rev
    [ "$rev" = "q" ] && return
  else
    rev="$1"
  fi
  [ "$rev" = "last" ] && rev="HEAD~1"
  git -C "$CFG" rev-parse --verify "${rev}^{commit}" &>/dev/null || err "Unknown: $rev"
  res=$(git -C "$CFG" rev-parse --short "$rev")
  changed=$(git -C "$CFG" diff --name-only "$rev" HEAD)
  if [ -n "$changed" ]; then info "Files:"; echo "$changed" | while IFS= read -r f; do echo "  $f"; done; fi
  read -p "Restore to $rev ($res)? [y/N]: " confirm
  [ "$confirm" != "y" ] && [ "$confirm" != "Y" ] && { echo "Cancelled."; return; }
  git -C "$CFG" checkout "$rev" -- .
  ok "Restored to $rev ($res)"
}
cmd_status() {
  if [ ! -d "$CFG/.git" ]; then warn "No backup repo"; info "Run 'gentleman backup' to init"; return; fi
  c=$(git -C "$CFG" rev-list --count HEAD 2>/dev/null || echo 0)
  s=$(du -sh "$CFG/.git" 2>/dev/null | cut -f1 || echo "-")
  echo "=== Backup Status ==="
  echo "  Config: $CFG"
  echo "  Snapshots: $c"
  echo "  Size: $s"
  if [ "$c" -gt 0 ]; then
    echo ""
    git -C "$CFG" log -1 --oneline 2>/dev/null
    if git -C "$CFG" diff --quiet 2>/dev/null; then ok "Clean"; else warn "Uncommitted:"; git -C "$CFG" status --short; fi
  fi
}
case "${1:-help}" in
  backup|bkp) shift; cmd_backup "$@" ;;
  restore|rst) shift; cmd_restore "$@" ;;
  status|st) cmd_status ;;
  help|-h|--help)
    echo "Gentleman CLI v1.0.0"
    echo "  gentleman backup     Snapshot config to git"
    echo "  gentleman restore    List/restore snapshots"
    echo "  gentleman status     Show backup status"
    ;;
  *) err "Unknown: $1. Use: gentleman help" ;;
esac
