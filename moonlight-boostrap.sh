#!/bin/bash

JET_HOME="$HOME/.jet"
JET_SCRIPT="$JET_HOME/jet.sh"
# IMPORTANT: Replace this with the RAW URL of your jet.sh file on Bitbucket
RAW_URL="https://bitbucket.org/servicecops/jet-cli/raw/main/jet.sh"

echo "🛠️  Installing Service Cops Jet CLI..."

# Create directory
mkdir -p "$JET_HOME"

# Download the script
echo "📥 Downloading tool..."
curl -s "$RAW_URL" -o "$JET_SCRIPT"
chmod +x "$JET_SCRIPT"

# Detect Shell Profile (zsh for Mac, bash for Linux)
[[ "$OSTYPE" == "darwin"* ]] || [[ "$SHELL" == *"zsh"* ]] && PROFILE="$HOME/.zshrc" || PROFILE="$HOME/.bashrc"

# Add alias to the profile if it doesn't exist
if ! grep -q "alias jet=" "$PROFILE"; then
    echo -e "\n# Service Cops Tooling\nalias jet='$JET_SCRIPT'" >> "$PROFILE"
    echo "✅ Alias 'jet' added to $PROFILE"
else
    echo "ℹ️  Alias 'jet' already exists."
fi

echo "------------------------------------------------"
echo "🎉 Done! Please run: source $PROFILE"
echo "Then create your first project with: jet new my-app"
echo "------------------------------------------------"
