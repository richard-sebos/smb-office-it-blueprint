---
title: "Setting Up Your Ansible Control Server: The Foundation for Infrastructure Automation"
description: "Complete guide to deploying and configuring an Ansible control node (MGMT01) for automated infrastructure management - from VM deployment to inventory structure and first playbooks."
---

# Setting Up Your Ansible Control Server: The Foundation for Infrastructure Automation

## Why Automation Matters (And Why Manual Won't Scale)

Here's a scenario I've seen too many times:

**Manual Deployment:**
- Deploy 11 VMs manually (3-4 hours)
- SSH into each one individually
- Run `apt update && apt upgrade` on each (copy-paste-wait-repeat)
- Configure network settings (typo on VM 7, troubleshoot for 30 minutes)
- Install packages (remember: which packages did I install on DC01?)
- Edit config files (was it `/etc/samba/smb.conf` or `/etc/samba/smbd.conf`?)
- Realize you made a mistake on VM 3... start over
- **Total time:** 8-12 hours, inconsistent configurations, high error rate

**Automated Deployment:**
- Write Ansible playbook once (2-3 hours, reusable)
- Run `ansible-playbook site.yml` (30 minutes, all 11 VMs)
- Configurations guaranteed identical
- Mistake in playbook? Fix once, rerun on all VMs
- Need to rebuild VM 3? `ansible-playbook site.yml --limit vm3` (3 minutes)
- **Total time:** 3 hours initial + 30 minutes per deployment, zero errors

**This article sets up the Ansible control server that makes automation possible.**

## What is MGMT01?

**MGMT01** is our **management and automation hub**—a dedicated VM that:

- Runs Ansible (infrastructure-as-code automation)
- Stores all playbooks, roles, and inventory
- Has SSH access to every VM in the environment
- Runs monitoring and alerting (optional: Prometheus, Grafana)
- Acts as a jump box for administrative access
- Stores scripts, backups, and operational tools

**Why a dedicated VM instead of running from your laptop?**

✅ **Always available** - Doesn't depend on your laptop being on
✅ **Consistent environment** - Same Ansible version, same Python packages
✅ **Network proximity** - Fast access to all VMs on same network
✅ **Security** - SSH keys never leave the server network
✅ **Team access** - Multiple admins can access the same control node
✅ **Documentation** - The VM itself is documentation of your infrastructure

## Architecture Reminder

**MGMT01 Specifications:**

| Attribute | Value |
|-----------|-------|
| VM ID | 181 |
| Hostname | mgmt01.smboffice.local |
| IP Address | 10.0.10.20 (Management VLAN) |
| OS | Oracle Linux 9 |
| vCPU | 2 cores |
| RAM | 3GB (expandable to 6GB if adding monitoring) |
| Disk | 40GB |
| Network | VLAN 10 (isolated management network) |
| Priority | HIGH (needed for automation and recovery) |
| Backup | Daily |

**Network Access:**
- VLAN 10 (Management): Direct access
- VLAN 20 (Servers): SSH to infrastructure VMs
- VLAN 30 (Workstations): SSH to workstation VMs
- Internet: Package downloads, updates

## Deploying MGMT01 on Proxmox

### Step 1: Clone from Template

We created an Oracle Linux 9 template in Article 02. Now we'll clone it:

```bash
# SSH into Proxmox host
ssh root@proxmox-host

# Clone template (ID 100) to create MGMT01 (ID 181)
qm clone 100 181 --name mgmt01 --full --pool management --storage local-lvm

# Set resources
qm set 181 --cores 2 --memory 3072 --balloon 0

# Configure disk
qm set 181 --scsi0 local-lvm:40,cache=writethrough,discard=on,iothread=1,ssd=1

# Set network (Management VLAN 10)
qm set 181 --net0 virtio,bridge=vmbr0,tag=10,queues=2

# Set CPU type and priority
qm set 181 --cpu host --cpuunits 1536

# Add tags
qm set 181 --tags "management,high,backup-daily,oracle-linux-9,ansible-control"

# Configure cloud-init (network and credentials)
qm set 181 --ipconfig0 ip=10.0.10.20/24,gw=10.0.10.1
qm set 181 --nameserver "10.0.20.11 10.0.20.12"
qm set 181 --searchdomain "smboffice.local"
qm set 181 --ciuser ansible
qm set 181 --cipassword "TempPassword123!"  # Change after first login

# Optional: Add your SSH key for immediate access
qm set 181 --sshkeys /root/.ssh/id_rsa.pub

# Enable QEMU guest agent
qm set 181 --agent enabled=1

# Set boot order
qm set 181 --boot order=scsi0

# Add description
qm set 181 --description "Management and Ansible Control Node
IP: 10.0.10.20
Services: Ansible, monitoring, scripts
Priority: HIGH
Backup: Daily
Owner: IT Administrator
Purpose: Infrastructure automation and management"
```

### Step 2: Start the VM

```bash
# Start MGMT01
qm start 181

# Wait for boot (30-60 seconds)
sleep 60

# Check status
qm status 181
```

### Step 3: Initial Connection

```bash
# SSH to MGMT01 (using cloud-init user)
ssh ansible@10.0.10.20

# You should see Oracle Linux login
# First login: change password
passwd
```

### Step 4: Basic System Configuration

```bash
# Update system
sudo dnf update -y

# Set hostname
sudo hostnamectl set-hostname mgmt01.smboffice.local

# Install essential tools
sudo dnf install -y \
    vim \
    wget \
    curl \
    git \
    tmux \
    htop \
    net-tools \
    bind-utils \
    tree \
    jq

# Install Python 3 (required for Ansible)
sudo dnf install -y python3 python3-pip

# Verify Python version
python3 --version  # Should be Python 3.9+
```

## Installing Ansible

### Method 1: DNF Package Manager (Recommended for Oracle Linux)

```bash
# Install Ansible from Oracle repos
sudo dnf install -y ansible-core

# Verify installation
ansible --version

# Expected output:
# ansible [core 2.14.x]
#   config file = /etc/ansible/ansible.cfg
#   configured module search path = ['/home/ansible/.ansible/plugins/modules', ...]
#   ansible python module location = /usr/lib/python3.9/site-packages/ansible
#   python version = 3.9.x
```

### Method 2: pip (Latest Version)

If you need the latest Ansible version:

```bash
# Install via pip
sudo pip3 install ansible

# Verify
ansible --version
```

### Install Ansible Collections

Ansible collections provide additional modules. Install commonly needed ones:

```bash
# Install Proxmox collection (for VM automation)
ansible-galaxy collection install community.general

# Install POSIX collection (file operations, user management)
ansible-galaxy collection install ansible.posix

# List installed collections
ansible-galaxy collection list
```

### Configure Ansible

Create global Ansible configuration:

```bash
# Create Ansible config directory
sudo mkdir -p /etc/ansible

# Create ansible.cfg
sudo vim /etc/ansible/ansible.cfg
```

**Ansible Configuration (`/etc/ansible/ansible.cfg`):**

```ini
[defaults]
# Inventory file location
inventory = /etc/ansible/hosts

# Disable host key checking (for lab environments)
# IMPORTANT: In production, use proper SSH key verification
host_key_checking = False

# Use Python 3
interpreter_python = auto_silent

# Increase forks for parallel execution
forks = 10

# Timeout for connections
timeout = 30

# Retry SSH connections
ssh_args = -o ControlMaster=auto -o ControlPersist=60s -o StrictHostKeyChecking=no

# Logging
log_path = /var/log/ansible/ansible.log

# Colorize output
force_color = True

# Show task timing
callback_whitelist = timer, profile_tasks

[privilege_escalation]
# Use sudo for privilege escalation
become = True
become_method = sudo
become_user = root
become_ask_pass = False

[ssh_connection]
# SSH pipelining for performance
pipelining = True

# Connection retry
retries = 3
```

**Create log directory:**

```bash
sudo mkdir -p /var/log/ansible
sudo chown ansible:ansible /var/log/ansible
```

## SSH Key Setup: The Foundation of Ansible

Ansible uses SSH to connect to managed hosts. Proper SSH key setup is critical.

### Generate SSH Key Pair

```bash
# Generate SSH key (on MGMT01 as ansible user)
ssh-keygen -t ed25519 -C "ansible@mgmt01.smboffice.local"

# Press Enter for default location (~/.ssh/id_ed25519)
# Set a strong passphrase (or empty for automation)

# Verify keys created
ls -la ~/.ssh/
# Should see: id_ed25519 (private key) and id_ed25519.pub (public key)
```

**Why Ed25519?**
- Faster than RSA
- More secure
- Smaller key size
- Modern standard

### Distribute Public Key to Managed Hosts

**Option 1: Manual Distribution (First-Time Setup)**

For each VM you want to manage:

```bash
# Copy public key to target host
ssh-copy-id root@10.0.20.11  # DC01
ssh-copy-id root@10.0.20.12  # DC02
ssh-copy-id root@10.0.20.21  # FILES01
# ... repeat for all VMs

# Test passwordless access
ssh root@10.0.20.11 'hostname'
# Should return: dc01.smboffice.local (no password prompt)
```

**Option 2: Cloud-Init (During VM Creation)**

When deploying VMs with cloud-init:

```bash
# Add Ansible public key during VM clone
qm set 111 --sshkeys /home/ansible/.ssh/id_ed25519.pub
```

**Option 3: Ansible Playbook (Once You Have Access to One VM)**

```yaml
# bootstrap-ssh.yml
---
- name: Distribute SSH keys to all hosts
  hosts: all
  gather_facts: no
  tasks:
    - name: Add Ansible public key
      authorized_key:
        user: root
        key: "{{ lookup('file', '~/.ssh/id_ed25519.pub') }}"
        state: present
```

Run:
```bash
ansible-playbook bootstrap-ssh.yml --ask-pass  # Enter password once
```

### Test SSH Access

```bash
# Test connectivity to all hosts
ansible all -m ping

# Expected output:
# 10.0.20.11 | SUCCESS => {
#     "changed": false,
#     "ping": "pong"
# }
```

## Creating the Ansible Project Structure

Organize your Ansible code professionally from day one.

### Recommended Directory Structure

```bash
# Create main Ansible directory
sudo mkdir -p /opt/ansible
sudo chown ansible:ansible /opt/ansible
cd /opt/ansible

# Create project structure
mkdir -p {inventory,playbooks,roles,group_vars,host_vars,files,templates,scripts}

# Create subdirectories
mkdir -p playbooks/{infrastructure,workstations,security,testing}
mkdir -p inventory/{production,development}
```

**Final structure:**

```
/opt/ansible/
├── ansible.cfg              # Project-specific config
├── inventory/               # Inventory files
│   ├── production/
│   │   └── hosts.yml        # Production inventory
│   └── development/
│       └── hosts.yml        # Dev/test inventory
├── playbooks/               # Playbooks organized by category
│   ├── infrastructure/
│   │   ├── deploy-domain-controllers.yml
│   │   ├── deploy-file-server.yml
│   │   └── deploy-print-server.yml
│   ├── workstations/
│   │   └── deploy-workstations.yml
│   ├── security/
│   │   └── security-hardening.yml
│   └── site.yml             # Main playbook (runs all)
├── roles/                   # Ansible roles
│   ├── samba_ad_dc/
│   ├── file_server/
│   ├── workstation_config/
│   └── security_baseline/
├── group_vars/              # Variables for groups
│   ├── all.yml              # Global variables
│   ├── domain_controllers.yml
│   ├── file_servers.yml
│   └── workstations.yml
├── host_vars/               # Variables for specific hosts
│   ├── dc01.yml
│   ├── dc02.yml
│   └── files01.yml
├── files/                   # Static files
│   ├── ssh_configs/
│   └── certificates/
├── templates/               # Jinja2 templates
│   ├── smb.conf.j2
│   └── sssd.conf.j2
└── scripts/                 # Helper scripts
    ├── backup.sh
    └── validate-deployment.sh
```

### Create Project ansible.cfg

```bash
# Create project-specific config
cat > /opt/ansible/ansible.cfg << 'EOF'
[defaults]
inventory = ./inventory/production/hosts.yml
roles_path = ./roles
host_key_checking = False
interpreter_python = auto_silent
forks = 10
timeout = 30
log_path = /var/log/ansible/ansible.log
force_color = True
callback_whitelist = timer, profile_tasks

[privilege_escalation]
become = True
become_method = sudo
become_user = root
become_ask_pass = False

[ssh_connection]
pipelining = True
retries = 3
EOF
```

## Creating the Inventory

The inventory defines **what** hosts Ansible manages and **how** they're grouped.

### Basic Inventory Concepts

**Groups:** Logical collections of hosts
- `domain_controllers` - DC01, DC02
- `file_servers` - FILES01
- `workstations` - All workstation VMs

**Variables:** Configuration specific to hosts/groups
- IP addresses
- VM IDs
- Department assignments
- Backup schedules

### Production Inventory

**Create `/opt/ansible/inventory/production/hosts.yml`:**

```yaml
---
# SMB Office Infrastructure Inventory
# Production Environment

all:
  vars:
    # Global variables
    domain_name: smboffice.local
    domain_realm: SMBOFFICE.LOCAL
    admin_email: admin@smboffice.local
    timezone: America/New_York

  children:
    # Infrastructure Services
    infrastructure:
      children:
        domain_controllers:
          hosts:
            dc01:
              ansible_host: 10.0.20.11
              vm_id: 111
              role: primary_dc

            dc02:
              ansible_host: 10.0.20.12
              vm_id: 112
              role: secondary_dc

          vars:
            samba_role: dc
            dns_forwarders:
              - 8.8.8.8
              - 8.8.4.4

        file_servers:
          hosts:
            files01:
              ansible_host: 10.0.20.21
              vm_id: 121

          vars:
            samba_role: member

        print_servers:
          hosts:
            print01:
              ansible_host: 10.0.20.22
              vm_id: 122

    # Workstations by Department
    workstations:
      vars:
        desktop_environment: gnome

      children:
        admin_workstations:
          hosts:
            admin_ws01:
              ansible_host: 10.0.30.31
              vm_id: 131
              department: admin
              assigned_user: emily.chen

            exec_ws01:
              ansible_host: 10.0.30.34
              vm_id: 134
              department: executive
              assigned_user: james.mitchell

        hr_workstations:
          hosts:
            hr_ws01:
              ansible_host: 10.0.30.42
              vm_id: 142
              department: hr
              assigned_user: sarah.johnson

        finance_workstations:
          hosts:
            fin_ws01:
              ansible_host: 10.0.30.53
              vm_id: 153
              department: finance
              assigned_user: michael.torres

        project_workstations:
          hosts:
            proj_ws01:
              ansible_host: 10.0.30.65
              vm_id: 165
              department: projects
              assigned_user: alex.rodriguez

        temp_workstations:
          hosts:
            intern_ws01:
              ansible_host: 10.0.30.76
              vm_id: 176
              department: temporary
              assigned_user: intern.user

    # Management
    management:
      hosts:
        mgmt01:
          ansible_host: 10.0.10.20
          vm_id: 181
          ansible_connection: local  # Running on itself
```

### Test Inventory

```bash
# List all hosts
ansible all --list-hosts

# List hosts in specific group
ansible domain_controllers --list-hosts

# Show inventory in graph format
ansible-inventory --graph

# Output:
# @all:
#   |--@infrastructure:
#   |  |--@domain_controllers:
#   |  |  |--dc01
#   |  |  |--dc02
#   |  |--@file_servers:
#   |  |  |--files01
#   ...
```

## Testing Ansible Connectivity

### Ping Test

```bash
# Test connectivity to all hosts
ansible all -m ping

# Test specific group
ansible domain_controllers -m ping

# Test single host
ansible dc01 -m ping
```

**Expected output:**
```
dc01 | SUCCESS => {
    "changed": false,
    "ping": "pong"
}
```

### Gather Facts

```bash
# Gather system information from all hosts
ansible all -m setup --tree /tmp/facts

# View collected facts
cat /tmp/facts/dc01

# Get specific fact
ansible dc01 -m setup -a 'filter=ansible_distribution*'
```

### Run Ad-Hoc Commands

```bash
# Check uptime
ansible all -m command -a 'uptime'

# Check disk space
ansible all -m command -a 'df -h'

# Get hostname
ansible all -m command -a 'hostname'

# Check Ansible can escalate privileges
ansible all -m command -a 'whoami' --become
# Should return: root
```

## Creating Your First Playbook

Let's create a simple playbook to test automation.

### Playbook 1: System Update

**Create `/opt/ansible/playbooks/system-update.yml`:**

```yaml
---
- name: Update all systems
  hosts: all
  become: yes

  tasks:
    - name: Update package cache (Debian/Ubuntu)
      apt:
        update_cache: yes
      when: ansible_os_family == "Debian"

    - name: Update package cache (RedHat/Oracle Linux)
      dnf:
        update_cache: yes
      when: ansible_os_family == "RedHat"

    - name: Upgrade all packages (Debian/Ubuntu)
      apt:
        upgrade: dist
        autoremove: yes
      when: ansible_os_family == "Debian"

    - name: Upgrade all packages (RedHat/Oracle Linux)
      dnf:
        name: "*"
        state: latest
      when: ansible_os_family == "RedHat"

    - name: Check if reboot is required (Debian/Ubuntu)
      stat:
        path: /var/run/reboot-required
      register: reboot_required
      when: ansible_os_family == "Debian"

    - name: Report reboot requirement
      debug:
        msg: "System {{ inventory_hostname }} requires reboot"
      when:
        - ansible_os_family == "Debian"
        - reboot_required.stat.exists
```

**Run the playbook:**

```bash
cd /opt/ansible
ansible-playbook playbooks/system-update.yml

# Run on specific group only
ansible-playbook playbooks/system-update.yml --limit domain_controllers

# Dry run (check mode)
ansible-playbook playbooks/system-update.yml --check
```

### Playbook 2: User Management

**Create `/opt/ansible/playbooks/create-admin-users.yml`:**

```yaml
---
- name: Create administrative users
  hosts: all
  become: yes

  vars:
    admin_users:
      - username: itadmin
        comment: "IT Administrator"
        shell: /bin/bash
        groups: wheel,sudo

      - username: ansible
        comment: "Ansible Automation User"
        shell: /bin/bash
        groups: wheel

  tasks:
    - name: Create admin user accounts
      user:
        name: "{{ item.username }}"
        comment: "{{ item.comment }}"
        shell: "{{ item.shell }}"
        groups: "{{ item.groups }}"
        append: yes
        create_home: yes
        state: present
      loop: "{{ admin_users }}"

    - name: Add Ansible SSH public key
      authorized_key:
        user: "{{ item.username }}"
        key: "{{ lookup('file', '~/.ssh/id_ed25519.pub') }}"
        state: present
      loop: "{{ admin_users }}"

    - name: Configure passwordless sudo
      lineinfile:
        path: /etc/sudoers.d/ansible
        line: "ansible ALL=(ALL) NOPASSWD: ALL"
        create: yes
        mode: '0440'
        validate: '/usr/sbin/visudo -cf %s'
```

**Run:**
```bash
ansible-playbook playbooks/create-admin-users.yml
```

### Playbook 3: Security Baseline

**Create `/opt/ansible/playbooks/security-baseline.yml`:**

```yaml
---
- name: Apply security baseline
  hosts: all
  become: yes

  tasks:
    - name: Disable root SSH login
      lineinfile:
        path: /etc/ssh/sshd_config
        regexp: '^PermitRootLogin'
        line: 'PermitRootLogin no'
        state: present
      notify: restart sshd

    - name: Disable password authentication
      lineinfile:
        path: /etc/ssh/sshd_config
        regexp: '^PasswordAuthentication'
        line: 'PasswordAuthentication no'
        state: present
      notify: restart sshd

    - name: Install firewalld
      package:
        name: firewalld
        state: present

    - name: Start and enable firewalld
      service:
        name: firewalld
        state: started
        enabled: yes

    - name: Configure fail2ban (if available)
      package:
        name: fail2ban
        state: present
      ignore_errors: yes

  handlers:
    - name: restart sshd
      service:
        name: sshd
        state: restarted
```

**Run with verification:**
```bash
# Dry run first
ansible-playbook playbooks/security-baseline.yml --check

# Apply
ansible-playbook playbooks/security-baseline.yml

# Verify SSH config
ansible all -m command -a 'grep "PermitRootLogin" /etc/ssh/sshd_config'
```

## Best Practices for Ansible Organization

### 1. Use Variables for Everything

**Bad:**
```yaml
- name: Install Samba
  dnf:
    name: samba
```

**Good:**
```yaml
# In group_vars/domain_controllers.yml
samba_version: "4.18.8"

# In playbook
- name: Install Samba
  dnf:
    name: "samba-{{ samba_version }}"
```

### 2. Use Roles for Reusability

Instead of long playbooks, create roles:

```bash
# Create role structure
ansible-galaxy init roles/samba_ad_dc

# Generates:
# roles/samba_ad_dc/
# ├── tasks/
# ├── handlers/
# ├── templates/
# ├── files/
# ├── vars/
# ├── defaults/
# └── meta/
```

### 3. Use Tags for Selective Execution

```yaml
- name: Install packages
  dnf:
    name: "{{ item }}"
  loop: "{{ packages }}"
  tags: packages

- name: Configure services
  template:
    src: config.j2
    dest: /etc/service/config
  tags: config
```

Run specific tags:
```bash
# Only run package installation
ansible-playbook site.yml --tags packages

# Skip configuration
ansible-playbook site.yml --skip-tags config
```

### 4. Use Handlers for Service Restarts

```yaml
tasks:
  - name: Update config file
    template:
      src: app.conf.j2
      dest: /etc/app/app.conf
    notify: restart application

handlers:
  - name: restart application
    service:
      name: application
      state: restarted
```

Handler only runs if config actually changed.

### 5. Use Ansible Vault for Secrets

```bash
# Create encrypted variable file
ansible-vault create group_vars/all/vault.yml

# Edit encrypted file
ansible-vault edit group_vars/all/vault.yml

# Store sensitive data:
# vault_domain_admin_password: "SecurePass123!"
# vault_db_password: "DatabasePass456!"
```

Use in playbooks:
```yaml
- name: Create domain admin
  user:
    name: administrator
    password: "{{ vault_domain_admin_password | password_hash('sha512') }}"
```

Run with vault password:
```bash
ansible-playbook site.yml --ask-vault-pass
```

### 6. Version Control Everything

```bash
cd /opt/ansible
git init
git add .
git commit -m "Initial Ansible infrastructure"

# Create .gitignore
cat > .gitignore << EOF
*.retry
*.log
.vault_pass
host_vars/*/vault.yml
group_vars/*/vault.yml
EOF
```

## Monitoring and Logging

### Enable Detailed Logging

Already configured in `ansible.cfg`:
```ini
log_path = /var/log/ansible/ansible.log
```

**View logs:**
```bash
# Tail live log
tail -f /var/log/ansible/ansible.log

# Search for errors
grep ERROR /var/log/ansible/ansible.log

# View last 100 lines
tail -n 100 /var/log/ansible/ansible.log
```

### Playbook Output Options

```bash
# Verbose output (debug info)
ansible-playbook site.yml -v    # Level 1
ansible-playbook site.yml -vv   # Level 2
ansible-playbook site.yml -vvv  # Level 3 (very verbose)

# Diff mode (show file changes)
ansible-playbook site.yml --diff

# Step mode (confirm each task)
ansible-playbook site.yml --step

# Start at specific task
ansible-playbook site.yml --start-at-task="Install Samba"
```

## Backing Up MGMT01

Your Ansible control node is critical infrastructure. Back it up properly.

### What to Backup

**Essential:**
- `/opt/ansible/` - All playbooks, roles, inventory
- `/home/ansible/.ssh/` - SSH keys
- `/etc/ansible/` - Configuration files
- `/var/log/ansible/` - Logs (for troubleshooting)

**Nice to Have:**
- `/root/` - Root user scripts
- System configuration files

### Manual Backup

```bash
# Create backup archive
sudo tar czf /tmp/mgmt01-backup-$(date +%Y%m%d).tar.gz \
    /opt/ansible \
    /home/ansible/.ssh \
    /etc/ansible \
    /var/log/ansible

# Copy to backup location
scp /tmp/mgmt01-backup-*.tar.gz backup-server:/backups/mgmt01/
```

### Automated Backup Script

**Create `/opt/ansible/scripts/backup.sh`:**

```bash
#!/bin/bash
# MGMT01 Backup Script

BACKUP_DIR="/backup/mgmt01"
DATE=$(date +%Y%m%d-%H%M%S)
BACKUP_FILE="mgmt01-backup-${DATE}.tar.gz"

# Create backup
tar czf ${BACKUP_DIR}/${BACKUP_FILE} \
    /opt/ansible \
    /home/ansible/.ssh \
    /etc/ansible \
    /var/log/ansible

# Keep only last 7 backups
cd ${BACKUP_DIR}
ls -t mgmt01-backup-*.tar.gz | tail -n +8 | xargs -r rm

echo "Backup completed: ${BACKUP_FILE}"
```

**Automate with cron:**
```bash
# Edit crontab
crontab -e

# Add daily backup at 1 AM
0 1 * * * /opt/ansible/scripts/backup.sh
```

### Proxmox VM Backup

Already configured in Article 03:
- MGMT01 included in daily backup job
- 7-day retention
- Snapshot mode (no downtime)

## Troubleshooting Common Issues

### SSH Connection Failures

**Problem:** `UNREACHABLE! => {"changed": false, "msg": "Failed to connect to the host via ssh"}`

**Solutions:**
```bash
# 1. Test SSH manually
ssh root@10.0.20.11

# 2. Check SSH key is distributed
ssh-copy-id root@10.0.20.11

# 3. Verify host is reachable
ping 10.0.20.11

# 4. Check firewall
ansible dc01 -m command -a 'firewall-cmd --list-all'

# 5. Increase verbosity
ansible dc01 -m ping -vvv
```

### Python Not Found

**Problem:** `/usr/bin/python: not found`

**Solution:**
```bash
# Set Python interpreter in inventory
# In hosts.yml:
dc01:
  ansible_host: 10.0.20.11
  ansible_python_interpreter: /usr/bin/python3
```

### Permission Denied (Sudo)

**Problem:** `ERROR! Timeout (12s) waiting for privilege escalation prompt`

**Solution:**
```bash
# Verify sudo access
ansible dc01 -m command -a 'whoami' --become

# Configure passwordless sudo (on target host)
echo "ansible ALL=(ALL) NOPASSWD: ALL" | sudo tee /etc/sudoers.d/ansible
```

### Playbook Syntax Errors

**Problem:** `ERROR! Syntax Error while loading YAML`

**Solution:**
```bash
# Validate playbook syntax
ansible-playbook playbooks/site.yml --syntax-check

# Lint playbook
ansible-lint playbooks/site.yml
```

## Next Steps: Building the Infrastructure

With MGMT01 configured and Ansible working, you're ready to automate the entire infrastructure deployment:

**Coming in future articles:**

1. **Domain Controller Deployment** - Automated Samba AD setup
2. **File Server Configuration** - Shares, permissions, audit logging
3. **Workstation Provisioning** - Desktop environment, domain join
4. **Security Hardening** - Auditd, SELinux, firewall rules
5. **Complete Site Playbook** - One-button infrastructure deployment

**Current capabilities:**
- ✅ Ansible control server running
- ✅ SSH access to all VMs
- ✅ Inventory defined
- ✅ Basic playbooks tested
- ✅ Version control initialized

**Next article preview:** We'll create the first major playbook—deploying and configuring dual Samba AD domain controllers with DNS and Kerberos.

---

## Quick Reference

### Common Ansible Commands

```bash
# Ping all hosts
ansible all -m ping

# Run ad-hoc command
ansible all -m command -a 'uptime'

# Run playbook
ansible-playbook playbooks/site.yml

# Run on specific group
ansible-playbook site.yml --limit domain_controllers

# Dry run
ansible-playbook site.yml --check

# Show what would change
ansible-playbook site.yml --check --diff

# Verbose output
ansible-playbook site.yml -vvv

# List hosts
ansible all --list-hosts

# List tasks
ansible-playbook site.yml --list-tasks

# List tags
ansible-playbook site.yml --list-tags
```

### Directory Structure Summary

```
/opt/ansible/
├── ansible.cfg              # Configuration
├── inventory/
│   └── production/
│       └── hosts.yml        # Inventory
├── playbooks/               # Playbooks
│   └── site.yml
├── roles/                   # Roles
├── group_vars/              # Group variables
├── host_vars/               # Host variables
└── scripts/                 # Helper scripts
```

### Key Files

- **Inventory:** `/opt/ansible/inventory/production/hosts.yml`
- **Config:** `/opt/ansible/ansible.cfg`
- **Logs:** `/var/log/ansible/ansible.log`
- **SSH Keys:** `/home/ansible/.ssh/id_ed25519`

---

**Author:** Richard Chamberlain
**Series:** SMB Office IT Blueprint
**Last Updated:** December 2025
**Contact:** [info@sebostechnology.com](mailto:info@sebostechnology.com)

---

## Related Articles

- Article 01: Introduction - Building Professional IT Infrastructure
- Article 02: Proxmox Best Practices - Universal virtualization principles
- Article 03: SMB Infrastructure Planning - 11-VM architecture design
- Article 04: Ansible Control Server Setup (this article)
- Article 05: Deploying Samba AD Domain Controllers (coming next)
