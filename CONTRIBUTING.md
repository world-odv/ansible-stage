# Contributing

## 1. Before changes

1. Используйте отдельную ветку.
2. Проверьте, что рабочие `vault.yml` остаются зашифрованными.
3. Не коммитьте `.vault_pass`, ключи и пароли.

## 2. Code style for this repo

1. Поддерживайте текущую структуру `inventories/`, `playbooks/`, `roles/`.
2. Новые компоненты добавляйте через `key_components` и `key_catalog`.
3. Для документации обновляйте `README.md` и при необходимости `help/*`.

## 3. Validation before pull requests

```bash
python3 -m pip install -r requirements.txt
ansible-galaxy collection install -r collections/requirements.yml
yamllint -c .yamllint .
ANSIBLE_CONFIG=./ansible.cfg ansible-inventory --graph
ANSIBLE_CONFIG=./ansible.cfg ansible-inventory -i inventories/bootstrap/hosts.yml --graph > /dev/null
ANSIBLE_CONFIG=./ansible.cfg ansible-inventory -i inventories/prod/hosts.yml --graph > /dev/null
ansible-playbook playbooks/prod/common.yml --syntax-check
ansible-playbook playbooks/prod/common.yml --vault-password-file /data/Vault/Ansible/vault_pass --check --diff
```

## 4. Pull request checklist

1. Описана цель и область изменений.
2. Добавлены/обновлены инструкции для новых переменных.
3. Нет незашифрованных секретов в diff.
4. CI (`Ansible Sanity`) проходит успешно.
