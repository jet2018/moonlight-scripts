#!/usr/bin/env bash
set -Eeuo pipefail

#######################################
# Moonlight CLI Installer (Auto-Refresh)
# Service Cops Tooling
#######################################

MOONLIGHT_HOME="$HOME/.moonlight"
MOONLIGHT_SCRIPT="$MOONLIGHT_HOME/moonlight.sh"
RAW_URL="https://raw.githubusercontent.com/jet2018/moonlight-scripts/main/moonlight.sh"
LOCAL_BIN="$HOME/.local/bin"

RESET='\033[0m'
BOLD='\033[1m'
GREEN='\033[32m'
BLUE='\033[34m'

log()  { echo -e "${BLUE}🌕${RESET} ${BOLD}$*${RESET}"; }
done_log() { echo -e "${GREEN}✅${RESET} ${BOLD}$*${RESET}"; }
die()  { echo -e "❌ $*" >&2; exit 1; }

check_dependencies() {
  for cmd in curl git; do
    command -v "$cmd" >/dev/null 2>&1 || die "$cmd is required."
  done
}

detect_profile() {
  [[ "${SHELL:-}" == *zsh* ]] && echo "$HOME/.zshrc" || echo "$HOME/.bashrc"
}

install_script() {
  mkdir -p "$MOONLIGHT_HOME"
  local tmp_file=$(mktemp)
  log "Downloading Moonlight CLI..."
  curl -fSL# "$RAW_URL" -o "$tmp_file" || die "Download failed."
  chmod +x "$tmp_file"
  mv "$tmp_file" "$MOONLIGHT_SCRIPT"
}

install_symlink() {
  mkdir -p "$LOCAL_BIN"
  rm -f "$LOCAL_BIN/moonlight"
  ln -s "$MOONLIGHT_SCRIPT" "$LOCAL_BIN/moonlight"
  done_log "Symlinked to $LOCAL_BIN/moonlight"
}

ensure_path() {
  local profile=$(detect_profile)
  touch "$profile"
  if ! grep -q "export PATH=.*$LOCAL_BIN" "$profile"; then
    log "Adding $LOCAL_BIN to PATH in $profile"
    echo -e "\n# Moonlight CLI\nexport PATH=\"$LOCAL_BIN:\$PATH\"" >> "$profile"
  fi
}

main() {
  clear
  echo -e "${BOLD}Service Cops Moonlight Installer${RESET}"
  echo "------------------------------------------------"

  check_dependencies
  install_script
  install_symlink
  ensure_path

  done_log "Installation complete! 🚀"
  log "Restarting shell to activate 'moonlight'..."

  # The 'hash -r' clears the command location cache
  hash -r 2>/dev/null || true

  # Auto-refresh: Replace current process with a new login shell
  exec "$SHELL" -l
}

main
