#!/usr/bin/env bash
set -euo pipefail

# Назначение: привести права/владельца файлов проекта к предсказуемому виду
# Не трогает vault-файлы (создание/шифрование делается отдельным скриптом)

DIR="${1:-$(pwd)}"

cd "$DIR"

echo "[1/4] Set owner to current user (may ask sudo password)"
sudo chown -R "$USER:$USER" "$DIR"

echo "[2/4] Set default permissions: dirs=755, files=644"
find "$DIR" -type d -exec chmod 755 {} \;
find "$DIR" -type f -exec chmod 644 {} \;

echo "[3/4] Make scripts executable (*.sh in ./help/scripts/bash)"
if [ -d "$DIR/help/scripts/bash" ]; then
  find "$DIR/help/scripts/bash" -type f -name "*.sh" -exec chmod 755 {} \;
fi

# Если существует локальный файл пароля vault_pass — защитить его правами 600
echo "[4/4] Set permissions for vault_pass file: mode=600"
if [ -f "$DIR/.vault_pass" ]; then
  chmod 600 "$DIR/.vault_pass"
fi

echo "Done."
