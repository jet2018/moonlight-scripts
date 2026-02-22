#!/bin/bash

MOONLIGHT_HOME="$HOME/.moonlight"
MOONLIGHT_SCRIPT="$MOONLIGHT_HOME/moonlight.sh"
RAW_URL="https://raw.githubusercontent.com/jet2018/moonlight-scripts/main/moonlight.sh"

echo "🛠️  Installing Service Cops Moonlight CLI..."

mkdir -p "$MOONLIGHT_HOME"

if curl -fsSL "$RAW_URL" -o "$MOONLIGHT_SCRIPT" ; then
    chmod +x "$MOONLIGHT_SCRIPT"
else
    echo "❌ Error: Could not download moonlight.sh"
    exit 1
fi

# Detect Profile
[[ "$OSTYPE" == "darwin"* ]] || [[ "$SHELL" == *"zsh"* ]] && PROFILE="$HOME/.zshrc" || PROFILE="$HOME/.bashrc"
touch "$PROFILE"

# Add alias
if ! grep -q "alias moonlight=" "$PROFILE"; then
    echo -e "\n# Service Cops Tooling\nalias moonlight='$MOONLIGHT_SCRIPT'" >> "$PROFILE"
    echo "✅ Alias 'moonlight' added to $PROFILE"
fi

echo "------------------------------------------------"
echo "🎉 Installation finished!"
echo "🔄 Refreshing session... You can use 'moonlight' now."
echo "------------------------------------------------"

# The magic step: Replace the current shell with a login shell to load the alias
exec $SHELL -l
