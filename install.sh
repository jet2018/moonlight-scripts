#!/usr/bin/env bash
set -Eeuo pipefail

#######################################
# Moonlight CLI Installer
# Service Cops Tooling
#######################################

MOONLIGHT_HOME="$HOME/.moonlight"
MOONLIGHT_SCRIPT="$MOONLIGHT_HOME/moonlight.sh"
RAW_URL="https://raw.githubusercontent.com/jet2018/moonlight-scripts/main/moonlight.sh"
LOCAL_BIN="$HOME/.local/bin"

# Colors for polish
RESET='\033[0m'
BOLD='\033[1m'
GREEN='\033[32m'
BLUE='\033[34m'

log()  { echo -e "${BLUE}🌕${RESET} ${BOLD}$*${RESET}"; }
done_log() { echo -e "${GREEN}✅${RESET} ${BOLD}$*${RESET}"; }
die()  { echo -e "❌ $*" >&2; exit 1; }

#######################################
# Pre-flight Checks
#######################################

check_dependencies() {
  for cmd in curl git; do
    command -v "$cmd" >/dev/null 2>&1 || die "$cmd is required. Please install it first."
  done
}

detect_profile() {
  local shell_base
  shell_base=$(basename "${SHELL:-}")
  if [[ "$shell_base" == "zsh" ]]; then
    echo "$HOME/.zshrc"
  else
    echo "$HOME/.bashrc"
  fi
}

#######################################
# Install Core
#######################################

install_script() {
  mkdir -p "$MOONLIGHT_HOME"
  local tmp_file
  tmp_file="$(mktemp)"

  log "Downloading Moonlight CLI..."
  # -# displays a simple progress bar
  curl -fSL# "$RAW_URL" -o "$tmp_file" || die "Download failed."

  chmod +x "$tmp_file"
  mv "$tmp_file" "$MOONLIGHT_SCRIPT"
}

install_symlink() {
  mkdir -p "$LOCAL_BIN"
  if [[ -L "$LOCAL_BIN/moonlight" ]]; then
    rm "$LOCAL_BIN/moonlight"
  fi
  ln -s "$MOONLIGHT_SCRIPT" "$LOCAL_BIN/moonlight"
  done_log "Binary symlinked to $LOCAL_BIN/moonlight"
}

#######################################
# Path Management
#######################################

ensure_path() {
  local profile
  profile="$(detect_profile)"
  touch "$profile"

  # Improved path check: search specifically for the export line
  if ! grep -q "export PATH=.*$LOCAL_BIN" "$profile"; then
    log "Adding $LOCAL_BIN to PATH in $profile"
    {
      echo ""
      echo "# Moonlight CLI"
      echo "export PATH=\"$LOCAL_BIN:\$PATH\""
    } >> "$profile"
    PATH_UPDATED=true
  else
    PATH_UPDATED=false
  fi
}

#######################################
# Main
#######################################

main() {
  clear
  echo -e "${BOLD}Service Cops Moonlight Installer${RESET}"
  echo "------------------------------------------------"

  check_dependencies

  if [[ -f "$MOONLIGHT_SCRIPT" ]]; then
    log "Existing installation detected. Upgrading..."
  fi

  install_script
  install_symlink
  ensure_path

  echo "------------------------------------------------"
  done_log "Installation complete! 🚀"

  if [[ "${PATH_UPDATED:-false}" == true ]]; then
    echo -e "\n${BOLD}Note:${RESET} ~/.local/bin was added to your PATH."
    echo "You need to refresh your session to start using 'moonlight'."

    read -rp "Refresh terminal session now? (y/n): " RESP
    if [[ "$RESP" =~ ^[yY]$ ]]; then
      log "Refreshing..."
      exec "$SHELL" -l
    fi
  else
    done_log "Your PATH is already configured."
    echo -e "\nYou can now run: ${BOLD}moonlight help${RESET}"
  fi
}

main
