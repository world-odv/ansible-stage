#!/usr/bin/env bash
set -euo pipefail

DIR="${1:-$(pwd)}"
VAULT_PASS_FILE="${VAULT_PASS_FILE:-$DIR/.vault_pass}"

cd "$DIR"

echo "[0/3] Pre-check"
if ! command -v ansible-vault >/dev/null 2>&1; then
  echo "ERROR: ansible-vault not found. Install Ansible first."
  exit 1
fi

if [ ! -f "$VAULT_PASS_FILE" ]; then
  echo "ERROR: vault password file not found: $VAULT_PASS_FILE"
  echo "Hint: create $DIR/.vault_pass (chmod 600)"
  exit 1
fi

chmod 600 "$VAULT_PASS_FILE" || true

echo "[1/3] Find vault.yml files"
mapfile -t VAULT_FILES < <(find "$DIR" -type f -name "vault.yml" 2>/dev/null | sort)

if [ "${#VAULT_FILES[@]}" -eq 0 ]; then
  echo "No vault.yml files found. Nothing to do."
  exit 0
fi

echo "Found ${#VAULT_FILES[@]} vault.yml file(s)."

echo "[2/3] Encrypt only non-encrypted vault.yml"
encrypted=0
skipped=0

for vf in "${VAULT_FILES[@]}"; do
  # Проверка: зашифрован ли файл (первой строкой идёт $ANSIBLE_VAULT;...)
  if head -n 1 "$vf" | grep -q "ANSIBLE_VAULT"; then
    echo "SKIP (already encrypted): $vf"
    ((skipped+=1))
    continue
  fi

  echo "ENCRYPT: $vf"
  ansible-vault encrypt "$vf" --vault-password-file "$VAULT_PASS_FILE"
  ((encrypted+=1))
done

echo "[3/3] Summary"
echo "Encrypted: $encrypted"
echo "Skipped:   $skipped"
echo "Done."