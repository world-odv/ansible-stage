# Quick Commands

## 1. Open first vault for editing

```bash
select f in $(find . -type f -name vault.yml | sort); do
  [ -n "$f" ] && EDITOR="code --wait" ansible-vault edit "$f" --vault-password-file /data/Vault/Ansible/vault_pass
  break
done
```

## 2. Main PROD runs

```bash
# Main groups
ansible-playbook playbooks/prod/ingress_gateways.yml --vault-password-file /data/Vault/Ansible/vault_pass
ansible-playbook playbooks/prod/ansible_controllers.yml --vault-password-file /data/Vault/Ansible/vault_pass

# Role-level playbooks by analogy
ansible-playbook playbooks/prod/common.yml --vault-password-file /data/Vault/Ansible/vault_pass
ansible-playbook playbooks/prod/remote.yml --vault-password-file /data/Vault/Ansible/vault_pass

# Limit to one host
ansible-playbook playbooks/prod/common.yml --vault-password-file /data/Vault/Ansible/vault_pass --limit igw_lv_riga_s1
```

## 3. Bootstrap

```bash
ansible-playbook -i inventories/bootstrap/hosts.yml playbooks/bootstrap.yml \
  --vault-password-file /data/Vault/Ansible/vault_pass

ansible -i inventories/bootstrap/hosts.yml ingress_gateways -m ping \
  --vault-password-file /data/Vault/Ansible/vault_pass -vv
```

## 4. Helper scripts

```bash
sudo chmod +x ./help/scripts/bash/preparation.sh && ./help/scripts/bash/preparation.sh
sudo chmod +x ./help/scripts/bash/fix_permissions.sh && ./help/scripts/bash/fix_permissions.sh
sudo chmod +x ./help/scripts/bash/encrypt_vaults.sh && VAULT_PASS_FILE=/data/Vault/Ansible/vault_pass ./help/scripts/bash/encrypt_vaults.sh
sudo chmod +x ./help/scripts/bash/ansible_setup.sh && ./help/scripts/bash/ansible_setup.sh
```

## 5. Manual checks

```bash
python3 -m pip install -r requirements.txt
ansible-galaxy collection install -r collections/requirements.yml
yamllint -c .yamllint .
ANSIBLE_CONFIG=./ansible.cfg ansible-inventory --graph
ANSIBLE_CONFIG=./ansible.cfg ansible-config dump --only-changed | grep HASH_BEHAVIOUR
ANSIBLE_CONFIG=./ansible.cfg ansible-playbook ./playbooks/bootstrap.yml --syntax-check
ANSIBLE_CONFIG=./ansible.cfg ansible-playbook ./playbooks/prod/common.yml --syntax-check
```
