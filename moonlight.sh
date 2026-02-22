#!/bin/bash

# --- CONFIGURATION ---
# The URL of your template repository
TEMPLATE_URL="git@bitbucket.org:servicecops/j2j_spring_boot_starter_kit.git"
# IMPORTANT: Replace this with the RAW URL of your jet.sh file on Bitbucket
RAW_SCRIPT_URL="https://bitbucket.org/servicecops/jet-cli/raw/main/jet.sh"
BASE_GROUP_PATH="com/servicecops"

COMMAND=$1
APP_NAME=$2
TAG_VERSION=$3

# OS Detection for sed (Mac vs Linux)
if [[ "$OSTYPE" == "darwin"* ]]; then SED_CMD=(sed -i ''); else SED_CMD=(sed -i); fi

case $COMMAND in
    "new")
        if [ -z "$APP_NAME" ]; then
            echo "❌ Usage: jet new <app_name> [optional_tag_version]"
            exit 1
        fi

        # 1. Sanitize Package Name (e.g., awesome-app becomes awesomeapp)
        PACKAGE_NAME=$(echo "$APP_NAME" | tr -d '-_' | tr '[:upper:]' '[:lower:]')

        # 2. Find Latest Tag
        if [ -z "$TAG_VERSION" ]; then
            echo "🔍 Searching for the latest stable tag..."
            LATEST_TAG=$(git ls-remote --tags --sort="v:refname" "$TEMPLATE_URL" | grep -v "\^{}" | cut -d '/' -f 3 | tail -n 1)
            TARGET_TAG=${LATEST_TAG:-main}
        else
            TARGET_TAG=${TAG_VERSION}
        fi

        # 3. DB Settings Prompts
        echo "🛠️  Local Development Setup"
        read -p "Database Name [$APP_NAME]: " DB_NAME
        read -p "Database Username [postgres]: " DB_USER
        read -p "Database Password (empty for none): " DB_PASS
        DB_NAME=${DB_NAME:-$APP_NAME}; DB_USER=${DB_USER:-postgres}

        echo "🚀 Creating project '$APP_NAME' using tag: $TARGET_TAG..."

        # 4. Clone Template
        git clone --branch "$TARGET_TAG" --depth 1 "$TEMPLATE_URL" "$APP_NAME" || exit 1
        cd "$APP_NAME" || exit

        # 5. Customize POM.xml
        echo "📝 Updating pom.xml..."
        "${SED_CMD[@]}" "s/<artifactId>project<\/artifactId>/<artifactId>$APP_NAME<\/artifactId>/g" pom.xml
        "${SED_CMD[@]}" "s/<name>project<\/name>/<name>$APP_NAME<\/name>/g" pom.xml

        # 6. Update Database Config
        DEV_PROPS="src/main/resources/application-dev.properties"
        if [ -f "$DEV_PROPS" ]; then
            echo "⚙️  Configuring application-dev.properties..."
            "${SED_CMD[@]}" "s|localhost:5432/{database_name}|localhost:5432/$DB_NAME|g" "$DEV_PROPS"
            "${SED_CMD[@]}" "s/{username}/$DB_USER/g" "$DEV_PROPS"
            "${SED_CMD[@]}" "s/{password}/$DB_PASS/g" "$DEV_PROPS"
        fi

        # Enable dev profile by default
        MAIN_PROPS="src/main/resources/application.properties"
        if [ -f "$MAIN_PROPS" ]; then
            grep -q "spring.profiles.active" "$MAIN_PROPS" && "${SED_CMD[@]}" "s/spring.profiles.active=.*/spring.profiles.active=dev/" "$MAIN_PROPS" || echo -e "\nspring.profiles.active=dev" >> "$MAIN_PROPS"
        fi

        # 7. Refactor Java Packages
        echo "📁 Refactoring Java packages to 'com.servicecops.$PACKAGE_NAME'..."
        for dir in src/main/java src/test/java; do
            if [ -d "$dir/$BASE_GROUP_PATH/project" ]; then
                mkdir -p "$dir/$BASE_GROUP_PATH/$PACKAGE_NAME"
                cp -R "$dir/$BASE_GROUP_PATH/project/"* "$dir/$BASE_GROUP_PATH/$PACKAGE_NAME/"
                rm -rf "$dir/$BASE_GROUP_PATH/project"
            fi
        done
        # Replace package declarations in all Java files
        find . -type f -name "*.java" -exec "${SED_CMD[@]}" "s/com.servicecops.project/com.servicecops.$PACKAGE_NAME/g" {} +

        # 8. Fresh Git Initialization
        echo "🧹 Resetting Git history..."
        rm -rf .git && git init && git add . && git commit -m "Initial commit from Jet ($TARGET_TAG)"

        echo "------------------------------------------------"
        echo "✅ SUCCESS: $APP_NAME is ready!"
        echo "📦 Package: com.servicecops.$PACKAGE_NAME"
        echo "🌟 Profile: dev (Active by default)"
        echo "------------------------------------------------"
        ;;

    "update")
        echo "🔄 Updating Jet CLI..."
        # Downloads the raw file to a temporary location, then replaces the current script ($0)
        if curl -s "$RAW_SCRIPT_URL" -o "$0.tmp"; then
            mv "$0.tmp" "$0"
            chmod +x "$0"
            echo "🚀 Jet has been updated successfully!"
        else
            echo "❌ Update failed. Check your internet connection or the RAW_SCRIPT_URL."
            exit 1
        fi
        ;;

    *)
        echo "Jet CLI - Service Cops"
        echo "Usage: jet {new|update}"
        echo "  new <app_name> [tag]  - Scaffolds a new project"
        echo "  update                - Updates this tool to the latest version"
        exit 1
        ;;
esac
