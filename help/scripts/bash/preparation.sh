#!/usr/bin/env bash
set -euo pipefail

# Converting new folders and files to the correct permissions
sudo chmod 755 ./help/scripts/bash/fix_permissions.sh
./help/scripts/bash/fix_permissions.sh

# Encrypt vaults
sudo chmod 755 ./help/scripts/bash/encrypt_vaults.sh
VAULT_PASS_FILE=/data/Vault/Ansible/vault_pass ./help/scripts/bash/encrypt_vaults.sh
