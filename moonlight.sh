#!/bin/bash

# --- CONFIGURATION ---
VERSION="1.0.2"
TEMPLATE_URL="https://bitbucket.org/servicecops/j2j_spring_boot_starter_kit.git"
RAW_SCRIPT_URL="https://raw.githubusercontent.com/jet2018/moonlight-scripts/main/moonlight.sh"
BASE_GROUP_PATH="com/servicecops"
MOONLIGHT_HOME="$HOME/.moonlight"

COMMAND=$1
APP_NAME=$2
TAG_VERSION=$3

# OS Detection for sed compatibility
if [[ "$OSTYPE" == "darwin"* ]]; then SED_CMD=(sed -i ''); else SED_CMD=(sed -i); fi

case $COMMAND in
    "new")
        if [ -z "$APP_NAME" ]; then echo "❌ Usage: moonlight new <app_name>"; exit 1; fi
        PACKAGE_NAME=$(echo "$APP_NAME" | sed 's/[^a-zA-Z0-9]//g' | tr '[:upper:]' '[:lower:]')

        echo "🔍 Connecting to Bitbucket..."
        LATEST_TAG=$(git ls-remote --tags --sort="v:refname" "$TEMPLATE_URL" | grep -v "\^{}" | cut -d '/' -f 3 | tail -n 1)
        TARGET_TAG=${TAG_VERSION:-${LATEST_TAG:-main}}

        echo "🚀 Creating project '$APP_NAME' using tag: $TARGET_TAG..."
        if ! git clone --branch "$TARGET_TAG" --depth 1 "$TEMPLATE_URL" "$APP_NAME"; then
            echo "❌ Clone failed. Verify Bitbucket access."
            exit 1
        fi

        cd "$APP_NAME" || exit
        "${SED_CMD[@]}" "s/<artifactId>project<\/artifactId>/<artifactId>$APP_NAME<\/artifactId>/g" pom.xml
        "${SED_CMD[@]}" "s/<name>project<\/name>/<name>$APP_NAME<\/name>/g" pom.xml

        # Package Refactoring
        for dir in src/main/java src/test/java; do
            if [ -d "$dir/$BASE_GROUP_PATH/project" ]; then
                mkdir -p "$dir/$BASE_GROUP_PATH/$PACKAGE_NAME"
                cp -R "$dir/$BASE_GROUP_PATH/project/"* "$dir/$BASE_GROUP_PATH/$PACKAGE_NAME/"
                rm -rf "$dir/$BASE_GROUP_PATH/project"
            fi
        done
        find . -type f -name "*.java" -exec "${SED_CMD[@]}" "s/com.servicecops.project/com.servicecops.$PACKAGE_NAME/g" {} +
        rm -rf .git && git init && git add . && git commit -m "Initial commit (Moonlight v$VERSION)"
        echo "✅ SUCCESS: $APP_NAME is ready."
        ;;

    "update")
        echo "🔄 Checking for updates..."
        CACHE_BUSTER=$(date +%s)
        REMOTE_VERSION=$(curl -fsSL "${RAW_SCRIPT_URL}?v=${CACHE_BUSTER}" | grep '^VERSION=' | head -1 | cut -d '"' -f 2)

        if [ "$REMOTE_VERSION" == "$VERSION" ]; then
            echo "✅ You are already on the latest version ($VERSION)."
        else
            echo "📥 Updating: v$VERSION -> v$REMOTE_VERSION..."
            curl -fsSL "${RAW_SCRIPT_URL}?v=${CACHE_BUSTER}" -o "$0.tmp" && mv "$0.tmp" "$0" && chmod +x "$0"
            echo "🚀 Moonlight updated successfully!"
        fi
        ;;

    "uninstall")
        echo "⚠️  Uninstalling Moonlight CLI..."
        read -p "Are you sure? (y/n): " confirm
        if [[ $confirm == [yY] ]]; then
            rm -rf "$MOONLIGHT_HOME"
            [[ "$OSTYPE" == "darwin"* ]] || [[ "$SHELL" == *"zsh"* ]] && PROFILE="$HOME/.zshrc" || PROFILE="$HOME/.bashrc"
            [ -f "$PROFILE" ] && "${SED_CMD[@]}" "/alias moonlight=/d" "$PROFILE"
            echo "✅ Moonlight uninstalled. Please restart your terminal."
        fi
        ;;

    "version") echo "🌕 Moonlight CLI Version: $VERSION" ;;
    *) echo "🌕 Moonlight CLI | Usage: moonlight {new|update|version|uninstall}"; exit 1 ;;
esac
