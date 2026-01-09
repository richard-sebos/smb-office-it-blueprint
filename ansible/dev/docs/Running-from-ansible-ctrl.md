# Running Ansible Playbooks from ansible-ctrl

## Overview

All Ansible playbooks are now executed from the **ansible-ctrl** server (10.0.120.50) on VLAN 120 (Servers network). This centralizes infrastructure automation and provides secure, auditable configuration management.

## Prerequisites

### 1. SSH Access Setup

The ansible-ctrl server needs SSH access to all managed hosts. Ensure SSH keys are deployed:

```bash
# On ansible-ctrl (10.0.120.50)
# SSH keys should already be deployed during ansible-ctrl setup

# Verify access to DCs
ssh richard@10.0.120.10  # dc01
ssh richard@10.0.120.11  # dc02

# Verify access to Proxmox
ssh root@192.168.35.20   # pve
```

### 2. Ansible Code Repository

The Ansible code should be present on ansible-ctrl:

```bash
# Clone or copy the repository to ansible-ctrl
cd /opt
sudo git clone <your-repo> smb-ansible
cd smb-ansible/ansible/dev

# Or copy files via scp/rsync
```

### 3. Verify Inventory

Check that the inventory is configured correctly:

```bash
cd /opt/smb-ansible/ansible/dev
cat inventory/hosts.yml

# Should show:
# - pve (192.168.35.20)
# - domain_controllers (dc01, dc02)
# - servers (ansible-ctrl)
# - workstations (ws-admin01)
```

## Network Architecture

```
ansible-ctrl (10.0.120.50) on VLAN 120
    |
    ├─> dc01 (10.0.120.10) - Same VLAN, direct access
    ├─> dc02 (10.0.120.11) - Same VLAN, direct access
    ├─> ws-admin01 (10.0.131.10) - Different VLAN, routed access
    └─> pve (192.168.35.20) - Management network, routed access
```

**Key Points:**
- ansible-ctrl can reach all VMs on VLAN 120 directly (same subnet)
- ansible-ctrl can reach other VLANs through routing
- ansible-ctrl can reach Proxmox management interface (192.168.35.20)
- No temporary management interfaces needed - all connections are production IPs

## Deployment Workflows

### Workflow 1: Deploy New Domain Controllers

```bash
# SSH to ansible-ctrl
ssh richard@10.0.120.50

# Navigate to Ansible directory
cd /opt/smb-ansible/ansible/dev

# Step 1: Deploy VMs on Proxmox
ansible-playbook playbooks/deploy-domain-controllers.yml

# What this does:
# - Connects to Proxmox (192.168.35.20)
# - Creates dc01 (VMID 110) and dc02 (VMID 111)
# - Configures production networking (10.0.120.10/11)
# - Installs base packages
# - Creates admin user (richard)
# - Deploys SSH keys
# - Applies SSH hardening

# Step 2: Configure Active Directory
ansible-playbook playbooks/configure-active-directory.yml

# What this does:
# - Connects to dc01 (10.0.120.10)
# - Installs Samba AD DC
# - Provisions domain (corp.company.local)
# - Connects to dc02 (10.0.120.11)
# - Joins dc02 as secondary DC
# - Configures replication
# - Runs verification tests
```

### Workflow 2: Deploy Workstation

```bash
# SSH to ansible-ctrl
ssh richard@10.0.120.50

cd /opt/smb-ansible/ansible/dev

# Deploy and configure workstation
ansible-playbook playbooks/deploy-and-configure-ws-admin01.yml

# What this does:
# - Creates VM on Proxmox
# - Configures network (VLAN 131)
# - Installs packages
# - Creates user and deploys keys
# - Applies SSH hardening
```

### Workflow 3: Ad-hoc Commands

```bash
# Check if all DCs are reachable
ansible domain_controllers -m ping

# Run command on all DCs
ansible domain_controllers -a "uptime"

# Update packages on all DCs
ansible domain_controllers -m apt -a "upgrade=dist" --become

# Check Samba status on dc01
ansible dc01 -a "systemctl status samba-ad-dc" --become

# Gather facts from all hosts
ansible all -m setup
```

### Workflow 4: Check Domain Replication

```bash
# Create a quick playbook to check replication
cat > /tmp/check-replication.yml << 'EOF'
---
- name: Check AD Replication
  hosts: domain_controllers
  become: yes
  tasks:
    - name: Check replication status
      command: samba-tool drs showrepl
      register: repl_output

    - name: Display replication status
      debug:
        var: repl_output.stdout_lines
EOF

# Run it
ansible-playbook /tmp/check-replication.yml
```

## Common Operations

### Check Ansible Connectivity

```bash
# Test connection to all hosts
ansible all -m ping

# Test with verbose output
ansible all -m ping -vvv

# Test specific group
ansible domain_controllers -m ping
ansible servers -m ping
ansible workstations -m ping
```

### Run Specific Roles

```bash
# Run only network configuration on DCs
ansible-playbook playbooks/deploy-domain-controllers.yml --tags network_config

# Run only SSH hardening
ansible-playbook playbooks/deploy-domain-controllers.yml --tags ssh_hardening

# Skip certain roles
ansible-playbook playbooks/deploy-domain-controllers.yml --skip-tags system_update
```

### Limit Execution to Specific Hosts

```bash
# Only deploy dc01
ansible-playbook playbooks/deploy-domain-controllers.yml --limit dc01

# Only configure dc02
ansible-playbook playbooks/configure-active-directory.yml --limit dc02

# Multiple hosts
ansible-playbook playbooks/deploy-domain-controllers.yml --limit dc01,dc02
```

### Dry Run (Check Mode)

```bash
# See what would change without actually making changes
ansible-playbook playbooks/configure-active-directory.yml --check

# With diff output
ansible-playbook playbooks/configure-active-directory.yml --check --diff
```

## Troubleshooting

### Issue: SSH Connection Refused

```bash
# Check if target host is up
ansible dc01 -m ping

# Try direct SSH
ssh richard@10.0.120.10

# Check SSH service on target
ansible dc01 -a "systemctl status sshd" --become
```

### Issue: Permission Denied

```bash
# Check if SSH key is deployed
ssh richard@10.0.120.10 "cat ~/.ssh/authorized_keys"

# Verify become (sudo) works
ansible dc01 -a "whoami" --become

# Check sudo configuration
ansible dc01 -a "sudo -l" --become
```

### Issue: Host Not Found in Inventory

```bash
# Check inventory
ansible-inventory --list

# Check specific host
ansible-inventory --host dc01

# Validate inventory syntax
ansible-inventory --list --yaml
```

### Issue: Module Not Found

```bash
# Check Ansible version
ansible --version

# Check installed collections
ansible-galaxy collection list

# Install missing collections
ansible-galaxy collection install community.general
```

## Security Best Practices

### 1. SSH Key Management

```bash
# Store SSH private key securely (should already be done)
chmod 600 ~/.ssh/id_ed25519

# Use SSH agent for password-protected keys
eval $(ssh-agent)
ssh-add ~/.ssh/id_ed25519
```

### 2. Ansible Vault for Secrets

```bash
# Create vault for sensitive variables
ansible-vault create group_vars/domain_controllers/vault.yml

# Edit vault
ansible-vault edit group_vars/domain_controllers/vault.yml

# Run playbook with vault
ansible-playbook playbooks/configure-active-directory.yml --ask-vault-pass
```

### 3. Audit Logging

```bash
# Enable detailed logging in ansible.cfg
[defaults]
log_path = /var/log/ansible/ansible.log

# Create log directory
sudo mkdir -p /var/log/ansible
sudo chown richard:richard /var/log/ansible

# Review logs
tail -f /var/log/ansible/ansible.log
```

### 4. Use Privilege Escalation Carefully

```bash
# Only use --become when necessary
ansible dc01 -a "ls /home/richard"  # No sudo needed

# Use sudo only when required
ansible dc01 -a "systemctl status samba-ad-dc" --become
```

## Maintenance

### Update Ansible Code

```bash
# Pull latest changes from Git
cd /opt/smb-ansible
sudo git pull origin main

# Or copy updated files
scp -r user@dev-machine:/path/to/ansible/* /opt/smb-ansible/
```

### Backup Ansible Configuration

```bash
# Backup entire Ansible directory
sudo tar czf /backup/ansible-backup-$(date +%Y%m%d).tar.gz /opt/smb-ansible

# Backup just host_vars and playbooks
cd /opt/smb-ansible/ansible/dev
tar czf ~/ansible-config-$(date +%Y%m%d).tar.gz host_vars/ playbooks/ inventory/
```

### Update Ansible and Dependencies

```bash
# Update Ansible (on ansible-ctrl)
sudo dnf update ansible-core

# Update Python dependencies
sudo pip3 install --upgrade ansible

# Update collections
ansible-galaxy collection install --upgrade community.general
```

## Performance Tips

### 1. Use SSH Multiplexing

Already configured in `ansible.cfg`:
```ini
[ssh_connection]
pipelining = True
ssh_args = -o ControlMaster=auto -o ControlPersist=60s
```

### 2. Parallel Execution

```bash
# Run on multiple hosts in parallel (default is 5)
ansible-playbook playbooks/deploy-domain-controllers.yml --forks 10

# Configure in ansible.cfg
[defaults]
forks = 10
```

### 3. Fact Caching

Already configured in `ansible.cfg`:
```ini
[defaults]
gathering = smart
fact_caching = jsonfile
fact_caching_connection = /tmp/ansible_facts
fact_caching_timeout = 3600
```

## Reference

### Key Files on ansible-ctrl

```
/opt/smb-ansible/ansible/dev/
├── ansible.cfg                          # Ansible configuration
├── inventory/
│   └── hosts.yml                        # Inventory file
├── host_vars/
│   ├── dc01.yml                         # DC01 configuration
│   ├── dc02.yml                         # DC02 configuration
│   └── ...                              # Other host configs
├── playbooks/
│   ├── deploy-domain-controllers.yml    # Deploy DCs
│   ├── configure-active-directory.yml   # Configure AD
│   └── ...                              # Other playbooks
└── roles/
    ├── samba_ad_dc/                     # AD DC role
    ├── network_config/                  # Network configuration
    └── ...                              # Other roles
```

### Useful Ansible Commands

```bash
# List all hosts
ansible all --list-hosts

# List hosts in group
ansible domain_controllers --list-hosts

# Show facts for host
ansible dc01 -m setup

# Test playbook syntax
ansible-playbook playbooks/deploy-domain-controllers.yml --syntax-check

# List tasks in playbook
ansible-playbook playbooks/deploy-domain-controllers.yml --list-tasks

# List tags
ansible-playbook playbooks/deploy-domain-controllers.yml --list-tags
```

---

**Document Version:** 1.0
**Last Updated:** 2026-01-04
**For:** ansible-ctrl (10.0.120.50)
