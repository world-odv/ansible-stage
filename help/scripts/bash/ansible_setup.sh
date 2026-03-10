#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/../../.." && pwd)"
PYTHON_REQUIREMENTS="${REPO_ROOT}/requirements.txt"
COLLECTIONS_REQUIREMENTS="${REPO_ROOT}/collections/requirements.yml"

echo "Install Ansible tooling (Ubuntu 24+)"
sudo apt update
sudo apt install -y python3 python3-pip sshpass

export PATH="${HOME}/.local/bin:${PATH}"

PIP_ARGS=(--user)
if python3 -m pip install --help 2>/dev/null | grep -q -- "--break-system-packages"; then
  PIP_ARGS+=(--break-system-packages)
fi

python3 -m pip install "${PIP_ARGS[@]}" --upgrade pip

if [ -f "${PYTHON_REQUIREMENTS}" ]; then
  echo "Install Python requirements from ${PYTHON_REQUIREMENTS}"
  python3 -m pip install "${PIP_ARGS[@]}" -r "${PYTHON_REQUIREMENTS}"
else
  echo "Skip Python requirements install: file not found ${PYTHON_REQUIREMENTS}"
fi

if [ -f "${COLLECTIONS_REQUIREMENTS}" ]; then
  echo "Install Ansible collections from ${COLLECTIONS_REQUIREMENTS}"
  ansible-galaxy collection install -r "${COLLECTIONS_REQUIREMENTS}"
else
  echo "Skip collections install: file not found ${COLLECTIONS_REQUIREMENTS}"
fi

echo "$(ansible --version | head -n 1)"
echo "$(sshpass --version | head -n 1)"
echo "$(yamllint --version)"
echo "Done."
