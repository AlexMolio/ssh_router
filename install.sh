#!/usr/bin/env bash

set -e

APP_DIR="$HOME/.ssh_router"
SCRIPT_URL="https://raw.githubusercontent.com/AlexMolio/ssh_router/main/app.py"

# 1. Create directory
mkdir -p "$APP_DIR"

# 2. Download script or copy local one
if [ -f "./app.py" ]; then
    echo "Local app.py found. Copying to $APP_DIR..."
    cp ./app.py "$APP_DIR/app.py"
else
    echo "Local app.py not found. Downloading from URL..."
    curl -sSL "$SCRIPT_URL" -o "$APP_DIR/app.py"
fi

# Для отладки: Если нужно, можно добавить дополнительные логи

# 3. Install Python and dependencies
echo "Checking for venv module..."
if ! python3 -c "import venv" 2>/dev/null; then
    echo "Error: venv module not found in Python. Install it (e.g., via 'sudo apt install python3-venv' on Linux)."
    exit 1
fi

echo "Creating virtual environment..."
python3 -m venv "$APP_DIR/venv"
echo "Virtual environment created."
source "$APP_DIR/venv/bin/activate"
pip install --upgrade pip
pip install textual

# 4. Create shortcut
BIN_PATH="$HOME/.local/bin/s"
mkdir -p "$(dirname "$BIN_PATH")"
cat <<EOF > "$BIN_PATH"
#!/usr/bin/env bash
source "$APP_DIR/venv/bin/activate"
python "$APP_DIR/app.py"
EOF
chmod +x "$BIN_PATH"

# Automatically add PATH to ~/.zshrc if not present
if ! grep -q 'export PATH="\$PATH:\$HOME/.local/bin"' ~/.zshrc; then
    echo '# Added for access to s' >> ~/.zshrc
    echo 'export PATH="$PATH:$HOME/.local/bin"' >> ~/.zshrc
    echo "Line added to ~/.zshrc. Run 'source ~/.zshrc' to apply."
fi

echo "Shortcut installed as 's'"
echo "   You can run: s"

echo "Checking PATH for s..."
if ! command -v s &> /dev/null; then
    echo "Command s not found in PATH. Add the following line to your ~/.zshrc:"
    echo 'export PATH="$PATH:$HOME/.local/bin"'
    echo "Then run 'source ~/.zshrc' or restart your terminal."
fi

echo "✅ Script installed as 's'"
echo "   You can run: s"

# 5. Set up hotkey
echo ""
read -p "Do you want to set a global hotkey for launch (only for Linux/macOS)? [y/N] " HOTKEY_OK

if [[ "$HOTKEY_OK" =~ ^[Yy]$ ]]; then
  read -p "Enter your desired key combination (e.g., ctrl+alt+s): " KEY

  OS=$(uname)
  if [[ "$OS" == "Darwin" ]]; then
    echo "Setting up Hammerspoon..."
    mkdir -p "$HOME/.hammerspoon"
    cat <<EOL >> "$HOME/.hammerspoon/init.lua"

-- Added for s
hs.hotkey.bind({"ctrl", "alt"}, "s", function()
  os.execute("open -a Terminal '$BIN_PATH'")
end)
EOL
    echo "✅ Restart Hammerspoon to apply changes."
  elif [[ "$OS" == "Linux" ]]; then
    CONFIG="$HOME/.config/sxhkd/sxhkdrc"
    mkdir -p "$(dirname "$CONFIG")"
    echo -e "\n# SSH Menu\n$KEY\n  $BIN_PATH" >> "$CONFIG"
    echo "✅ Hotkey added to sxhkd. Restart sxhkd to apply."
  else
    echo "⚠️ Hotkeys are not supported on this system automatically."
  fi
fi

echo "🎉 Installation complete!"
