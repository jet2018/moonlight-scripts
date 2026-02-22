#!/bin/bash

# --- CONFIGURATION ---
VERSION="1.0.0"
# ✅ SWITCHED TO HTTPS: More reliable for general users than SSH
TEMPLATE_URL="https://bitbucket.org/servicecops/j2j_spring_boot_starter_kit.git"
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

        # 1. Sanitize Package Name (Cleanest cross-platform method)
        # Removes all non-alphanumeric chars and converts to lowercase
        PACKAGE_NAME=$(echo "$APP_NAME" | sed 's/[^a-zA-Z0-9]//g' | tr '[:upper:]' '[:lower:]')

        echo "🔍 Connecting to Bitbucket..."

        # 2. Get Latest Tag (Using git ls-remote on the HTTPS URL)
        # Note: If the repo is private, Git will prompt for credentials here
        LATEST_TAG=$(git ls-remote --tags --sort="v:refname" "$TEMPLATE_URL" | grep -v "\^{}" | cut -d '/' -f 3 | tail -n 1)

        if [ $? -ne 0 ]; then
            echo "❌ ERROR: Could not connect to Bitbucket."
            echo "Make sure you have access to $TEMPLATE_URL"
            exit 1
        fi

        TARGET_TAG=${TAG_VERSION:-${LATEST_TAG:-main}}

        echo "🚀 Creating project '$APP_NAME' using tag: $TARGET_TAG..."

        # 3. Clone Template
        if ! git clone --branch "$TARGET_TAG" --depth 1 "$TEMPLATE_URL" "$APP_NAME"; then
            echo "❌ Failed to clone. Check your Bitbucket credentials."
            exit 1
        fi

        cd "$APP_NAME" || exit

        # 4. Refactor Logic (pom.xml)
        echo "📝 Updating pom.xml..."
        "${SED_CMD[@]}" "s/<artifactId>project<\/artifactId>/<artifactId>$APP_NAME<\/artifactId>/g" pom.xml
        "${SED_CMD[@]}" "s/<name>project<\/name>/<name>$APP_NAME<\/name>/g" pom.xml

        # 5. Database Setup
        DEV_PROPS="src/main/resources/application-dev.properties"
        if [ -f "$DEV_PROPS" ]; then
            "${SED_CMD[@]}" "s|localhost:5432/{database_name}|localhost:5432/$APP_NAME|g" "$DEV_PROPS"
        fi

        # 6. Refactor Java Packages
        echo "📁 Moving packages to com.servicecops.$PACKAGE_NAME..."
        for dir in src/main/java src/test/java; do
            if [ -d "$dir/$BASE_GROUP_PATH/project" ]; then
                mkdir -p "$dir/$BASE_GROUP_PATH/$PACKAGE_NAME"
                cp -R "$dir/$BASE_GROUP_PATH/project/"* "$dir/$BASE_GROUP_PATH/$PACKAGE_NAME/"
                rm -rf "$dir/$BASE_GROUP_PATH/project"
            fi
        done
        find . -type f -name "*.java" -exec "${SED_CMD[@]}" "s/com.servicecops.project/com.servicecops.$PACKAGE_NAME/g" {} +

        # 7. Reset Git History
        rm -rf .git && git init && git add . && git commit -m "Initial commit (Moonlight v$VERSION)"

        echo "------------------------------------------------"
        echo "✅ SUCCESS: $APP_NAME is ready."
        echo "🌕 Moonlight Version: $VERSION"
        echo "------------------------------------------------"
        ;;

    "status")
        LATEST_TAG=$(git ls-remote --tags --sort="v:refname" "$TEMPLATE_URL" | grep -v "\^{}" | cut -d '/' -f 3 | tail -n 1)
        echo "📌 Latest Template Tag: ${LATEST_TAG:-main}"
        echo "🛠️  Current CLI Version: $VERSION"
        ;;

    "version")
        echo "🌕 Moonlight CLI Version: $VERSION"
        ;;

    "update")
        echo "🔄 Checking for updates..."
        REMOTE_VERSION=$(curl -fsSL "$RAW_SCRIPT_URL" | grep '^VERSION=' | head -1 | cut -d '"' -f 2)

        if [ "$REMOTE_VERSION" == "$VERSION" ]; then
            echo "✅ You are already on the latest version ($VERSION)."
        else
            echo "📥 Updating to $REMOTE_VERSION..."
            curl -fsSL "$RAW_SCRIPT_URL" -o "$0.tmp" && mv "$0.tmp" "$0" && chmod +x "$0"
            echo "🚀 Moonlight updated successfully!"
        fi
        ;;

    *)
        echo "🌕 Moonlight CLI"
        echo "Usage: moonlight {new|status|version|update}"
        exit 1
        ;;
esac
