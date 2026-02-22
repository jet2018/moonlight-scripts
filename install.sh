#!/bin/bash

MOONLIGHT_HOME="$HOME/.moonlight"
MOONLIGHT_SCRIPT="$MOONLIGHT_HOME/moonlight.sh"
# ✅ GitHub Raw URL
RAW_URL="https://raw.githubusercontent.com/jet2018/moonlight-scripts/main/moonlight.sh"

echo "🛠️  Installing Service Cops Moonlight CLI..."

mkdir -p "$MOONLIGHT_HOME"

echo "📥 Downloading tool..."
if curl -fsSL "$RAW_URL" -o "$MOONLIGHT_SCRIPT" ; then
    chmod +x "$MOONLIGHT_SCRIPT"
else
    echo "❌ Error: Could not download moonlight.sh"
    exit 1
fi

# Detect Shell Profile
[[ "$OSTYPE" == "darwin"* ]] || [[ "$SHELL" == *"zsh"* ]] && PROFILE="$HOME/.zshrc" || PROFILE="$HOME/.bashrc"

touch "$PROFILE"

# Add alias if missing
if ! grep -q "alias moonlight=" "$PROFILE"; then
    echo -e "\n# Service Cops Tooling\nalias moonlight='$MOONLIGHT_SCRIPT'" >> "$PROFILE"
    echo "✅ Alias 'moonlight' added to $PROFILE"
else
    echo "ℹ️  Alias 'moonlight' already exists."
fi

echo "------------------------------------------------"
echo "🎉 Done! Please run: source $PROFILE"
echo "Then create your project with: moonlight new my-app"
echo "------------------------------------------------"
