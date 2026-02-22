#!/bin/bash

# --- CONFIGURATION ---
VERSION="1.0.0"
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
        if [ -z "$APP_NAME" ]; then
            echo "❌ Error: Project name is required."
            echo "Usage: moonlight new <project-name> [tag]"
            exit 1
        fi
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

    "update"|"-u")
        echo "🔄 Checking for CLI updates..."
        CACHE_BUSTER=$(date +%s)
        REMOTE_VERSION=$(curl -fsSL "${RAW_SCRIPT_URL}?v=${CACHE_BUSTER}" | grep '^VERSION=' | head -1 | cut -d '"' -f 2)

        if [ "$REMOTE_VERSION" == "$VERSION" ]; then
            echo "✅ Already on latest CLI version ($VERSION)."
        else
            echo "📥 Updating: v$VERSION -> v$REMOTE_VERSION..."
            curl -fsSL "${RAW_SCRIPT_URL}?v=${CACHE_BUSTER}" -o "$0.tmp" && mv "$0.tmp" "$0" && chmod +x "$0"
            echo "🚀 Update successful! Refreshing shell..."
            exec $SHELL -l
        fi
        ;;

    "version"|"-v"|"--version")
        echo "🌕 Moonlight CLI Information"
        echo "------------------------------------------------"
        echo "💻 CLI Local Version:  $VERSION"
        LATEST_TAG=$(git ls-remote --tags --sort="v:refname" "$TEMPLATE_URL" | grep -v "\^{}" | cut -d '/' -f 3 | tail -n 1)
        echo "📦 Latest Template Tag: ${LATEST_TAG:-main}"
        echo "------------------------------------------------"
        ;;

    "uninstall")
        echo "⚠️  Uninstalling Moonlight CLI..."
        read -p "Are you sure? (y/n): " confirm
        if [[ $confirm == [yY] ]]; then
            rm -rf "$MOONLIGHT_HOME"
            [[ "$OSTYPE" == "darwin"* ]] || [[ "$SHELL" == *"zsh"* ]] && PROFILE="$HOME/.zshrc" || PROFILE="$HOME/.bashrc"
            if [ -f "$PROFILE" ]; then
                "${SED_CMD[@]}" "/alias moonlight=/d" "$PROFILE"
            fi
            echo "✅ Moonlight uninstalled. Refreshing session..."
            exec $SHELL -l
        fi
        ;;

    "help"|*)
        echo "🌕 Moonlight CLI - Service Cops Project Scaffolder"
        echo "--------------------------------------------------------"
        echo "Usage: moonlight <command> [arguments]"
        echo ""
        echo "COMMANDS:"
        echo "  new <name> [tag]  Scaffold a new Spring Boot project."
        echo "                    - Sanitizes <name> for Java packages."
        echo "                    - Clones the latest Bitbucket tag by default."
        echo "                    - Re-initializes a fresh Git repository."
        echo ""
        echo "  update, -u        Check GitHub for a newer version of this CLI."
        echo "                    - Automatically downloads and replaces the script."
        echo "                    - Restarts your shell session to apply changes."
        echo ""
        echo "  version, -v       Display local CLI version and the latest"
        echo "                    available project template tag from Bitbucket."
        echo ""
        echo "  uninstall         Completely remove the CLI and its terminal alias."
        echo ""
        echo "EXAMPLES:"
        echo "  moonlight new schoolpay-ug"
        echo "  moonlight new my-service v1.2.0"
        echo "--------------------------------------------------------"
        exit 0
        ;;
esac
