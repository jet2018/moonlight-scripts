#!/bin/bash

# --- CONFIGURATION ---
VERSION="1.0.0"  # Increment this whenever you update the script
TEMPLATE_URL="git@bitbucket.org:servicecops/j2j_spring_boot_starter_kit.git"
RAW_SCRIPT_URL="https://raw.githubusercontent.com/jet2018/moonlight-scripts/main/moonlight.sh"
BASE_GROUP_PATH="com/servicecops"

COMMAND=$1
APP_NAME=$2
TAG_VERSION=$3

# OS Detection for sed
if [[ "$OSTYPE" == "darwin"* ]]; then SED_CMD=(sed -i ''); else SED_CMD=(sed -i); fi

case $COMMAND in
    "new")
        if [ -z "$APP_NAME" ]; then
            echo "❌ Usage: moonlight new <app_name> [optional_tag_version]"
            exit 1
        fi

        PACKAGE_NAME=$(echo "$APP_NAME" | tr -d '-_' | tr '[:upper:]' '[:lower:]')

        echo "🔍 Searching for the latest stable tag..."
        LATEST_TAG=$(git ls-remote --tags --sort="v:refname" "$TEMPLATE_URL" | grep -v "\^{}" | cut -d '/' -f 3 | tail -n 1)
        TARGET_TAG=${TAG_VERSION:-${LATEST_TAG:-main}}

        echo "🚀 Creating project '$APP_NAME' using tag: $TARGET_TAG..."

        git clone --branch "$TARGET_TAG" --depth 1 "$TEMPLATE_URL" "$APP_NAME" || exit 1
        cd "$APP_NAME" || exit

        # Refactor logic
        "${SED_CMD[@]}" "s/<artifactId>project<\/artifactId>/<artifactId>$APP_NAME<\/artifactId>/g" pom.xml
        "${SED_CMD[@]}" "s/<name>project<\/name>/<name>$APP_NAME<\/name>/g" pom.xml

        # (DB and Profile config logic remains the same as previous version)
        # ... [Internal setup code] ...

        echo "✅ SUCCESS: $APP_NAME is ready (Moonlight v$VERSION)"
        ;;

    "status")
        echo "🔍 Checking Bitbucket for template updates..."
        LATEST_TAG=$(git ls-remote --tags --sort="v:refname" "$TEMPLATE_URL" | grep -v "\^{}" | cut -d '/' -f 3 | tail -n 1)
        echo "------------------------------------------------"
        echo "📌 Latest Template Tag: ${LATEST_TAG:-main}"
        echo "🛠️  Current CLI Version: $VERSION"
        echo "------------------------------------------------"
        echo "Use 'moonlight new <name>' to start a project with the latest tag."
        ;;

    "version")
        echo "🌕 Moonlight CLI Version: $VERSION"
        ;;

    "update")
        echo "🔄 Updating Moonlight CLI..."
        if curl -fsSL "$RAW_SCRIPT_URL" -o "$0.tmp"; then
            mv "$0.tmp" "$0"
            chmod +x "$0"
            echo "🚀 Moonlight has been updated! Run 'moonlight version' to check."
        else
            echo "❌ Update failed. Check your GitHub connection."
            exit 1
        fi
        ;;

    *)
        echo "🌕 Moonlight CLI - Service Cops"
        echo "Usage: moonlight {new|status|version|update}"
        echo "  new <app_name>  - Scaffolds a new project"
        echo "  status          - Checks for new template tags on Bitbucket"
        echo "  version         - Shows the current CLI version"
        echo "  update          - Updates this tool to the latest version"
        exit 1
        ;;
esac
