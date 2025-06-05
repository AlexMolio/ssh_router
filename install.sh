#!/usr/bin/env bash

set -e

APP_DIR="$HOME/.ssh_router"
SCRIPT_URL="https://raw.githubusercontent.com/YOU/ssh-router/main/ssh_menu.py"

# 1. Создание директории
mkdir -p "$APP_DIR"

# 2. Загрузка скрипта или копирование локального
if [ -f "./app.py" ]; then
    echo "Локальный app.py найден. Копируем в $APP_DIR..."
    cp ./app.py "$APP_DIR/app.py"
else
    echo "Локальный app.py не найден. Загружаем из URL..."
    curl -sSL "$SCRIPT_URL" -o "$APP_DIR/app.py"
fi

# Для отладки: Если нужно, можно добавить дополнительные логи

# 3. Установка Python + зависимостей
python3 -m venv "$APP_DIR/venv"  # Проверяем наличие модуля venv
echo "Проверка наличия модуля venv..."
if ! python3 -c "import venv" 2>/dev/null; then
    echo "Ошибка: модуль venv не найден в Python. Установите его (например, через 'sudo apt install python3-venv' на Linux)."
    exit 1
fi

echo "Создание виртуального окружения..."
python3 -m venv "$APP_DIR/venv"
echo "Виртуальное окружение создано."
source "$APP_DIR/venv/bin/activate"
pip install --upgrade pip
pip install textual

# 4. Создание ярлыка
BIN_PATH="$HOME/.local/bin/s"
mkdir -p "$(dirname "$BIN_PATH")"
cat <<EOF > "$BIN_PATH"
#!/usr/bin/env bash
source "$APP_DIR/venv/bin/activate"
python "$APP_DIR/app.py"
EOF
chmod +x "$BIN_PATH"

# Автоматически добавляем PATH в ~/.zshrc, если его нет
if ! grep -q 'export PATH="\$PATH:\$HOME/.local/bin"' ~/.zshrc; then
    echo '# Добавлено для доступа к ssh-menu' >> ~/.zshrc
    echo 'export PATH="$PATH:$HOME/.local/bin"' >> ~/.zshrc
    echo "Строка добавлена в ~/.zshrc. Выполните 'source ~/.zshrc' для применения."
    # source ~/.zshrc
fi

echo "Проверка PATH для ssh-menu..."
if ! command -v ssh-menu &> /dev/null; then
    echo "Команда ssh-menu не найдена в PATH. Добавьте следующую строку в ваш ~/.zshrc:"
    echo 'export PATH="$PATH:$HOME/.local/bin"'
    echo "Затем выполните 'source ~/.zshrc' или перезапустите терминал."
fi

echo "✅ Скрипт установлен как 's'"
echo "   Можешь запустить: s"

# 5. Настройка хоткея
echo ""
read -p "🔧 Хочешь назначить глобальный хоткей для запуска (только для Linux/macOS)? [y/N] " HOTKEY_OK

if [[ "$HOTKEY_OK" =~ ^[Yy]$ ]]; then
  read -p "Введите желаемую комбинацию клавиш (например, ctrl+alt+s): " KEY

  OS=$(uname)
  if [[ "$OS" == "Darwin" ]]; then
    echo "Настраиваю Hammerspoon..."
    mkdir -p "$HOME/.hammerspoon"
    cat <<EOL >> "$HOME/.hammerspoon/init.lua"

-- Добавлено ssh-menu
hs.hotkey.bind({"ctrl", "alt"}, "s", function()
  os.execute("open -a Terminal '$BIN_PATH'")
end)
EOL
    echo "✅ Перезапусти Hammerspoon для применения."
  elif [[ "$OS" == "Linux" ]]; then
    CONFIG="$HOME/.config/sxhkd/sxhkdrc"
    mkdir -p "$(dirname "$CONFIG")"
    echo -e "\n# SSH Menu\n$KEY\n  $BIN_PATH" >> "$CONFIG"
    echo "✅ Добавлен хоткей в sxhkd. Перезапусти sxhkd."
  else
    echo "⚠️ Хоткеи пока не поддерживаются на этой системе автоматически."
  fi
fi

echo "🎉 Установка завершена!"
