#!/usr/bin/env bash
set -Eeuo pipefail

#######################################
# Moonlight CLI v2
#######################################

VERSION="1.0.1"
TEMPLATE_URL="https://bitbucket.org/servicecops/j2j_spring_boot_starter_kit.git"
RAW_SCRIPT_URL="https://raw.githubusercontent.com/jet2018/moonlight-scripts/main/moonlight.sh"
BASE_GROUP_PATH="com/servicecops"
MOONLIGHT_HOME="$HOME/.moonlight"

COMMAND="${1:-}"
APP_NAME="${2:-}"
TAG_VERSION="${3:-}"

#######################################
# Utilities
#######################################

log()  { echo "🌕 $*"; }
warn() { echo "⚠️  $*" >&2; }
die()  { echo "❌ $*" >&2; exit 1; }

require_cmd() {
  command -v "$1" >/dev/null 2>&1 || die "'$1' is required but not installed."
}

detect_sed() {
  if [[ "$OSTYPE" == "darwin"* ]]; then
    SED_INPLACE=(-i '')
  else
    SED_INPLACE=(-i)
  fi
}

safe_sed() {
  local search="$1"
  local replace="$2"
  local file="$3"
  sed "${SED_INPLACE[@]}" "s|$search|$replace|g" "$file"
}

detect_profile() {
  if [[ "${SHELL:-}" == *zsh* ]]; then
    echo "$HOME/.zshrc"
  else
    echo "$HOME/.bashrc"
  fi
}

#######################################
# Core Actions
#######################################

cmd_new() {
  require_cmd git
  require_cmd curl
  detect_sed

  [[ -n "$APP_NAME" ]] || die "Usage: moonlight new <project-name> [tag]"

  [[ ! -d "$APP_NAME" ]] || die "Directory '$APP_NAME' already exists."

  PACKAGE_NAME="$(echo "$APP_NAME" | tr -cd '[:alnum:]' | tr '[:upper:]' '[:lower:]')"

  log "Fetching remote tags..."
  LATEST_TAG="$(git ls-remote --tags --sort="v:refname" "$TEMPLATE_URL" \
    | grep -v '\^{}' | awk -F/ '{print $3}' | tail -n 1 || true)"

  TARGET_TAG="${TAG_VERSION:-${LATEST_TAG:-main}}"

  log "Using template tag: $TARGET_TAG"

  log "Local development database setup"
  while true; do
    read -rp "Database Name [$APP_NAME]: " DB_NAME
    DB_NAME="${DB_NAME:-$APP_NAME}"
    [[ "$DB_NAME" =~ ^[a-zA-Z_][a-zA-Z0-9_]*$ ]] && break
    warn "Invalid database name."
  done

  read -rp "Database Username [postgres]: " DB_USER
  DB_USER="${DB_USER:-postgres}"
  read -rsp "Database Password (empty for none): " DB_PASS
  echo ""

  if command -v psql >/dev/null 2>&1; then
    log "Checking PostgreSQL database..."
    if PGPASSWORD="$DB_PASS" psql -h localhost -U "$DB_USER" -lqt 2>/dev/null \
      | cut -d\| -f1 | grep -qw "$DB_NAME"; then
      log "Database exists."
    else
      log "Creating database '$DB_NAME'..."
      if ! PGPASSWORD="$DB_PASS" createdb -h localhost -U "$DB_USER" "$DB_NAME" 2>/dev/null; then
        warn "Database creation failed. You may need to create it manually."
      fi
    fi
  else
    warn "psql not found. Skipping database check."
  fi

  log "Cloning template..."
  git clone --depth 1 --branch "$TARGET_TAG" "$TEMPLATE_URL" "$APP_NAME" \
    || die "Failed to clone template."

  cd "$APP_NAME"

  safe_sed "<artifactId>project</artifactId>" "<artifactId>$APP_NAME</artifactId>" pom.xml
  safe_sed "<name>project</name>" "<name>$APP_NAME</name>" pom.xml

  DEV_PROPS="src/main/resources/application-dev.properties"
  if [[ -f "$DEV_PROPS" ]]; then
    safe_sed "{database_name}" "$DB_NAME" "$DEV_PROPS"
    safe_sed "{username}" "$DB_USER" "$DEV_PROPS"
    safe_sed "{password}" "$DB_PASS" "$DEV_PROPS"
  fi

  for dir in src/main/java src/test/java; do
    SRC="$dir/$BASE_GROUP_PATH/project"
    DST="$dir/$BASE_GROUP_PATH/$PACKAGE_NAME"
    if [[ -d "$SRC" ]]; then
      mkdir -p "$DST"
      cp -R "$SRC/"* "$DST/"
      rm -rf "$SRC"
    fi
  done

  find . -type f -name "*.java" \
    -exec sed "${SED_INPLACE[@]}" \
    "s/com.servicecops.project/com.servicecops.$PACKAGE_NAME/g" {} +

  log "Resetting Git history..."
  rm -rf .git
  git init -b main
  git add .
  git commit -m "Initial commit"

  log "Project '$APP_NAME' is ready 🚀"

  echo "Open in:"
  echo "  1) IntelliJ IDEA"
  echo "  2) VS Code"
  echo "  3) Stay here"
  read -rp "Choice [3]: " IDE

  case "$IDE" in
    1) command -v idea >/dev/null && idea . || [[ "$OSTYPE" == "darwin"* ]] && open -a "IntelliJ IDEA" . ;;
    2) command -v code >/dev/null && code . ;;
  esac
}

cmd_update() {
  require_cmd curl
  detect_sed

  log "Checking for updates..."
  TMP="$(mktemp)"
  if ! curl -fsSL "$RAW_SCRIPT_URL" -o "$TMP"; then
    die "Failed to fetch remote script."
  fi

  REMOTE_VERSION="$(grep '^VERSION=' "$TMP" | head -1 | cut -d'"' -f2)"
  [[ -n "$REMOTE_VERSION" ]] || die "Invalid remote script."

  if [[ "$REMOTE_VERSION" != "$VERSION" ]]; then
    log "Updating Moonlight CLI → v$REMOTE_VERSION"
    chmod +x "$TMP"
    mv "$TMP" "$0"
    exec "$SHELL" -l
  else
    log "You are already on the latest version."
  fi
}

cmd_uninstall() {
  read -rp "Uninstall Moonlight CLI? (y/n): " CONFIRM
  [[ "$CONFIRM" =~ ^[yY]$ ]] || exit 0

  PROFILE="$(detect_profile)"
  detect_sed

  rm -rf "$MOONLIGHT_HOME"
  sed "${SED_INPLACE[@]}" '/alias moonlight=/d' "$PROFILE"

  log "Moonlight CLI removed."
  exec "$SHELL" -l
}

#######################################
# Dispatcher
#######################################

case "$COMMAND" in
  new)        cmd_new ;;
  update|-u)  cmd_update ;;
  version|-v|--version) echo "🌕 Moonlight CLI v$VERSION" ;;
  check)      git ls-remote --tags --sort="v:refname" "$TEMPLATE_URL" | tail -n 1 ;;
  uninstall)  cmd_uninstall ;;
  help|"")
    echo "🌕 Moonlight CLI v$VERSION"
    echo "Usage:"
    echo "  moonlight new <name> [tag]"
    echo "  moonlight update"
    echo "  moonlight version"
    echo "  moonlight check"
    echo "  moonlight uninstall"
    ;;
  *) die "Unknown command: $COMMAND" ;;
esac
