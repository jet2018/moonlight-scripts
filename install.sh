#!/usr/bin/env bash
set -Eeuo pipefail

#######################################
# Configuration
#######################################

MOONLIGHT_HOME="$HOME/.moonlight"
MOONLIGHT_SCRIPT="$MOONLIGHT_HOME/moonlight.sh"
RAW_URL="https://raw.githubusercontent.com/jet2018/moonlight-scripts/main/moonlight.sh"
LOCAL_BIN="$HOME/.local/bin"

#######################################
# Utilities
#######################################

log()  { echo "🌕 $*"; }
warn() { echo "⚠️  $*"; }
die()  { echo "❌ $*" >&2; exit 1; }

detect_profile() {
  if [[ "${SHELL:-}" == *zsh* ]]; then
    echo "$HOME/.zshrc"
  else
    echo "$HOME/.bashrc"
  fi
}

#######################################
# Install Script Safely
#######################################

install_script() {
  mkdir -p "$MOONLIGHT_HOME"

  TMP="$(mktemp)"
  log "Downloading Moonlight CLI..."

  curl -fsSL "$RAW_URL" -o "$TMP" || die "Download failed."

  chmod +x "$TMP"
  mv "$TMP" "$MOONLIGHT_SCRIPT"
}

#######################################
# Symlink into ~/.local/bin
#######################################

install_symlink() {
  mkdir -p "$LOCAL_BIN"
  ln -sf "$MOONLIGHT_SCRIPT" "$LOCAL_BIN/moonlight"
}

#######################################
# Ensure PATH contains ~/.local/bin
#######################################

ensure_path() {
  PROFILE="$(detect_profile)"
  touch "$PROFILE"

  if ! echo "$PATH" | grep -q "$LOCAL_BIN"; then
    if ! grep -q "$LOCAL_BIN" "$PROFILE"; then
      log "Adding $LOCAL_BIN to PATH in $PROFILE"
      {
        echo ""
        echo "# Moonlight CLI"
        echo "export PATH=\"$LOCAL_BIN:\$PATH\""
      } >> "$PROFILE"
    fi
    PATH_UPDATED=true
  else
    PATH_UPDATED=false
  fi
}

#######################################
# Force Refresh (Optional but Enabled)
#######################################

refresh_shell() {
  log "Refreshing terminal session..."
  exec "$SHELL" -l
}

#######################################
# Main Flow
#######################################

main() {
  log "Installing Service Cops Moonlight CLI..."

  if [[ -f "$MOONLIGHT_SCRIPT" ]]; then
    log "Existing installation detected. Updating..."
  fi

  install_script
  install_symlink
  ensure_path

  echo ""
  log "Installation complete 🚀"
  echo "------------------------------------------------"

  if [[ "${PATH_UPDATED:-false}" == true ]]; then
    log "~/.local/bin added to PATH."
  fi

  echo ""
  read -rp "Refresh this terminal session now? (y/n): " RESP

  if [[ "$RESP" =~ ^[yY]$ ]]; then
    refresh_shell
  else
    echo ""
    echo "To activate manually:"
    echo "  source $(detect_profile)"
    echo "or restart your terminal."
  fi
}

main
