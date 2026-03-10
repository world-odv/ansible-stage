# Ansible Infrastructure Blueprint

Репозиторий автоматизирует обслуживание Linux-хостов через Ansible: базовая ОС-настройка, доступ, сеть, безопасность, обслуживание и дополнительные платформенные компоненты.

## Для чего проект

- Быстро поднимать и стандартизировать новые хосты (`bootstrap`).
- Поддерживать production-конфигурацию через роли и флаги компонентов.
- Хранить секреты централизованно и безопасно (`ansible-vault`).
- Масштабировать окружение через единый inventory-подход.

## Основные сущности

### Группы хостов

- `ingress_gateways`
- `ansible_controllers`

### Главные playbook-и

- `playbooks/bootstrap.yml`: первичная подготовка новых серверов.
- `playbooks/prod/ingress_gateways.yml`: основной стек для шлюзов.
- `playbooks/prod/ansible_controllers.yml`: основной стек для контроллеров.

### Роль-ориентированные playbook-и

Можно запускать отдельно по роли, например:

- `playbooks/prod/common.yml`
- `playbooks/prod/remote.yml`
- `playbooks/prod/observability.yml`

По аналогии доступны остальные (`network`, `backup`, `scan`, `scm`, `platform_edge` и др.).

## Структура (кратко)

```text
.
├── ansible.cfg
├── requirements.txt
├── collections/
│   └── requirements.yml
├── inventories/
│   ├── bootstrap/
│   │   ├── hosts.yml
│   │   ├── template.yml
│   │   └── host_vars/<host>/vault.yml
│   └── prod/
│       ├── hosts.yml
│       ├── template.yml
│       ├── group_vars/
│       └── host_vars/<host>/vault.yml
├── playbooks/
├── roles/
└── help/
```

### Tooling versions

Python tooling (`ansible-core`, `yamllint`) фиксируются в `requirements.txt`.

## Конфигурация Ansible (важно)

Проект использует локальный `ansible.cfg` как часть архитектуры.

- `inventory = ./inventories/prod/hosts.yml`
- `roles_path = ./roles`
- `hash_behaviour = merge`

Почему это критично:

1. Подход в `group_vars`/`host_vars` построен на частичном переопределении словарей.
2. При `hash_behaviour = merge` переопределяются только нужные ключи, а не весь блок.
3. Если переключить поведение обратно на `replace`, часть текущих переопределений сломается.

Пример:

- База задается в `inventories/prod/group_vars/all/main.yml`.
- Точечные изменения дописываются в `group_vars/<group>` или `host_vars/<host>/vault.yml`.
- Благодаря `merge` итоговая конфигурация собирается из нескольких слоев.

## Быстрый старт

### 1. Подготовить контроллер

```bash
chmod +x ./help/scripts/bash/ansible_setup.sh
./help/scripts/bash/ansible_setup.sh
```

Скрипт устанавливает:

1. Python tooling из `requirements.txt` (`ansible-core`, `yamllint`).
2. Ansible collections из `collections/requirements.yml`.

### 2. Подготовить репозиторий

```bash
chmod +x ./help/scripts/bash/preparation.sh
./help/scripts/bash/preparation.sh
```

### 3. Настроить bootstrap inventory

1. Добавьте хосты в `inventories/bootstrap/hosts.yml`.
2. Скопируйте шаблон:

```bash
mkdir -p inventories/bootstrap/host_vars/<host>
cp inventories/bootstrap/template.yml inventories/bootstrap/host_vars/<host>/vault.yml
```

3. Заполните `vault.yml` и зашифруйте его.
4. Выполните bootstrap:

```bash
ansible-playbook -i inventories/bootstrap/hosts.yml playbooks/bootstrap.yml \
  --vault-password-file /data/Vault/Ansible/vault_pass
```

### 4. Настроить prod inventory

1. Добавьте хосты в `inventories/prod/hosts.yml`.
2. Скопируйте шаблон:

```bash
mkdir -p inventories/prod/host_vars/<host>
cp inventories/prod/template.yml inventories/prod/host_vars/<host>/vault.yml
```

3. Заполните и зашифруйте `host_vars/<host>/vault.yml`.
4. Настройте компоненты через:
   - `inventories/prod/group_vars/all/main.yml`
   - `inventories/prod/group_vars/ansible_controllers/main.yml`
   - `inventories/prod/group_vars/ingress_gateways/main.yml`

## Основные примеры запуска

### Групповые прогоны

```bash
ansible-playbook playbooks/prod/ingress_gateways.yml --vault-password-file /data/Vault/Ansible/vault_pass
ansible-playbook playbooks/prod/ansible_controllers.yml --vault-password-file /data/Vault/Ansible/vault_pass
```

### Роль-ориентированные прогоны

```bash
ansible-playbook playbooks/prod/common.yml --vault-password-file /data/Vault/Ansible/vault_pass
ansible-playbook playbooks/prod/remote.yml --vault-password-file /data/Vault/Ansible/vault_pass
```

### Прогон на один хост

```bash
ansible-playbook playbooks/prod/common.yml --vault-password-file /data/Vault/Ansible/vault_pass --limit igw_lv_riga_s1
```

## Секреты (`ansible-vault`)

Рабочие секреты хранятся в:

- `inventories/bootstrap/host_vars/<host>/vault.yml`
- `inventories/prod/host_vars/<host>/vault.yml`

Редактирование:

```bash
EDITOR="code --wait" ansible-vault edit inventories/prod/host_vars/<host>/vault.yml \
  --vault-password-file /data/Vault/Ansible/vault_pass
```

Массовое шифрование (для незашифрованных `vault.yml`):

```bash
VAULT_PASS_FILE=/data/Vault/Ansible/vault_pass ./help/scripts/bash/encrypt_vaults.sh
```

## Как изменять и расширять проект

### Добавить новый хост

1. Добавьте алиас в `inventories/<env>/hosts.yml`.
2. Создайте `inventories/<env>/host_vars/<alias>/vault.yml` из `template.yml`.
3. Проверьте доступ:

```bash
ansible -i inventories/prod/hosts.yml ingress_gateways -m ping \
  --vault-password-file /data/Vault/Ansible/vault_pass -vv
```

### Добавить/изменить компонент

1. Обновите `key_components` (`enabled`, `vars`, `config`).
2. При необходимости обновите `key_catalog` (пакеты/репозитории).
3. Прогоните сначала role-level playbook в `--check`.

### Добавить новую роль

1. Создайте `roles/<new_role>/tasks/main.yml`.
2. Подключите роль в нужный `playbooks/prod/*.yml`.
3. Добавьте нужные переменные в `group_vars`/`host_vars`.

## Проверки перед применением

```bash
ANSIBLE_CONFIG=./ansible.cfg ansible-inventory --graph
ansible-playbook playbooks/prod/common.yml --syntax-check
ansible-playbook playbooks/prod/common.yml --vault-password-file /data/Vault/Ansible/vault_pass --check --diff
```

## Полезные материалы в репозитории

- `help/README.md`
- `help/quick-commands.md`
- `help/variables-precedence.md`
- `CONTRIBUTING.md`
- `SECURITY.md`

## License

Проект распространяется по лицензии MIT. Подробности в файле `LICENSE`.

## CI

В репозитории добавлен GitHub Actions workflow:

- `.github/workflows/ansible-sanity.yml`

Что проверяет workflow:

1. Устанавливает Python-зависимости из `requirements.txt`.
2. Проверяет политику `hash_behaviour = merge`.
3. Проверяет оба inventory (`prod` и `bootstrap`) через `ansible-inventory --graph`.
4. Проверяет YAML-синтаксис через `yamllint` (c исключением зашифрованных `vault.yml`).
5. Выполняет `--syntax-check` для `playbooks/bootstrap.yml` и всех `playbooks/prod/*.yml` (покрывает и роли).

## Чеклист перед публикацией

1. Все рабочие `vault.yml` зашифрованы.
2. Пароль vault не хранится в Git (`.vault_pass` и аналоги).
3. В публичных файлах нет реальных секретов и приватных ключей.
4. Шаблоны для пользователей заполнены (`inventories/*/template.yml`).
