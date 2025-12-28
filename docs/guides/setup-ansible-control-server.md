# Ansible Control Server Setup Guide

## Overview

This guide walks through configuring VM 110 (ansible-ctrl) as the central automation and configuration management server for the SMB Office IT infrastructure.

**VM Details:**
- **VMID:** 110
- **Hostname:** ansible-ctrl
- **IP Address:** 10.0.110.10/24
- **Gateway:** 10.0.110.1
- **VLAN:** 110 (Management)
- **OS:** Ubuntu 22.04 LTS
- **Resources:** 2 cores, 4GB RAM, 100GB disk

**Purpose:**
- Central automation server for infrastructure management
- Configuration management using Ansible
- Infrastructure as Code (IaC) repository
- Automated deployment and updates
- Service orchestration

---

## Prerequisites

- VM 300 (ws-admin01) configured and accessible
- SSH access to VM 110 from admin workstation
- Internet connectivity from VM 110
- Git repository access (GitHub/GitLab)

---

## Phase 1: Initial System Setup

### 1.1 Start the VM

From Proxmox host or admin workstation:

```bash
# Start VM 110
qm start 110

# Wait 30 seconds for boot
sleep 30

# Check VM status
qm status 110

# Test connectivity
ping -c 3 10.0.110.10
```

### 1.2 Initial SSH Access

From your admin workstation (VM 300):

```bash
# SSH to Ansible control server
ssh ubuntu@10.0.110.10

# Update hostname
sudo hostnamectl set-hostname ansible-ctrl

# Update /etc/hosts
sudo tee -a /etc/hosts <<EOF

# SMB Office IT Infrastructure
10.0.110.10   ansible-ctrl
10.0.110.11   monitoring
10.0.110.12   backup
10.0.110.13   jump-host

10.0.120.10   dc01
10.0.120.11   dc02
10.0.120.20   fs01
10.0.120.30   db01
10.0.120.40   app01
10.0.120.50   mail01

10.0.130.10   ws-admin01

10.0.150.10   web01
10.0.150.20   vpn-gw
10.0.150.30   mail-relay
EOF

# Verify hostname
hostnamectl
```

### 1.3 System Updates

```bash
# Update package list
sudo apt update

# Upgrade all packages
sudo apt upgrade -y

# Install essential packages
sudo apt install -y \
  vim \
  git \
  curl \
  wget \
  htop \
  net-tools \
  dnsutils \
  python3 \
  python3-pip \
  python3-venv \
  software-properties-common \
  apt-transport-https \
  ca-certificates \
  gnupg \
  lsb-release

# Clean up
sudo apt autoremove -y
sudo apt autoclean
```

---

## Phase 2: Ansible Installation

### 2.1 Install Ansible via PPA

```bash
# Add Ansible PPA
sudo add-apt-repository --yes --update ppa:ansible/ansible

# Install Ansible
sudo apt install -y ansible

# Verify installation
ansible --version

# Expected output:
# ansible [core 2.16.x]
#   config file = /etc/ansible/ansible.cfg
#   python version = 3.10.x
```

### 2.2 Install Additional Ansible Tools

```bash
# Install ansible-lint for playbook validation
sudo apt install -y ansible-lint

# Install Python packages for Ansible modules
pip3 install --user \
  ansible-core \
  jmespath \
  netaddr \
  dnspython \
  requests \
  pywinrm

# Add pip bin to PATH
echo 'export PATH=$PATH:~/.local/bin' >> ~/.bashrc
source ~/.bashrc
```

### 2.3 Configure Ansible

```bash
# Create custom Ansible configuration directory
sudo mkdir -p /etc/ansible
sudo chown ubuntu:ubuntu /etc/ansible

# Create ansible.cfg
cat > /etc/ansible/ansible.cfg <<'EOF'
[defaults]
# Inventory location
inventory = /etc/ansible/hosts

# Disable host key checking (for lab environment)
host_key_checking = False

# Use sudo for privilege escalation
become = True
become_method = sudo
become_user = root
become_ask_pass = False

# SSH connection settings
timeout = 30
remote_user = ubuntu

# Output settings
stdout_callback = yaml
bin_ansible_callbacks = True

# Logging
log_path = /var/log/ansible/ansible.log

# Performance
forks = 10
gathering = smart
fact_caching = jsonfile
fact_caching_connection = /tmp/ansible_facts
fact_caching_timeout = 86400

# Retry settings
retry_files_enabled = True
retry_files_save_path = /var/log/ansible/retry

[privilege_escalation]
become = True
become_method = sudo
become_user = root
become_ask_pass = False

[ssh_connection]
pipelining = True
ssh_args = -o ControlMaster=auto -o ControlPersist=60s
control_path = /tmp/ansible-ssh-%%h-%%p-%%r
EOF

# Create log directory
sudo mkdir -p /var/log/ansible
sudo chown ubuntu:ubuntu /var/log/ansible
```

---

## Phase 3: Project Repository Setup

### 3.1 Clone Project Repository

```bash
# Create project directory
mkdir -p ~/projects
cd ~/projects

# Clone the SMB Office IT Blueprint repository
# Option 1: If using Git repository
git clone https://github.com/yourusername/smb-office-it-blueprint.git
cd smb-office-it-blueprint

# Option 2: Copy from admin workstation
# From admin workstation (VM 300):
# scp -r ~/smb-office-it-blueprint ubuntu@10.0.110.10:~/projects/

# Option 3: Create fresh structure
mkdir -p smb-office-it-blueprint
cd smb-office-it-blueprint

# Create project structure
mkdir -p {playbooks,roles,inventory/{group_vars,host_vars},scripts,docs}
mkdir -p playbooks/{infrastructure,services,workstations,security}
mkdir -p roles/{common,domain-controller,file-server,database,webserver}
```

### 3.2 Initialize Git Repository

```bash
cd ~/projects/smb-office-it-blueprint

# Initialize git
git init

# Create .gitignore
cat > .gitignore <<'EOF'
# Ansible
*.retry
*.log
.vault_pass

# Python
__pycache__/
*.py[cod]
*$py.class
.venv/
venv/

# Secrets
secrets/
*.vault
*_vault.yml
credentials.yml

# Temporary files
*.tmp
*.swp
*~

# OS files
.DS_Store
Thumbs.db
EOF

# Set Git user
git config user.name "Ansible Automation"
git config user.email "ansible@corp.company.local"

# Initial commit
git add .
git commit -m "Initial commit: SMB Office IT Blueprint structure"
```

---

## Phase 4: SSH Key Setup

### 4.1 Generate SSH Key for Ansible

```bash
# Generate SSH key pair (no passphrase for automation)
ssh-keygen -t ed25519 -C "ansible@ansible-ctrl" -f ~/.ssh/ansible_ed25519 -N ""

# Set correct permissions
chmod 600 ~/.ssh/ansible_ed25519
chmod 644 ~/.ssh/ansible_ed25519.pub

# Display public key
cat ~/.ssh/ansible_ed25519.pub
```

### 4.2 Distribute SSH Keys to Managed Hosts

```bash
# Create script to distribute SSH keys
cat > ~/scripts/distribute-ssh-keys.sh <<'EOF'
#!/bin/bash
################################################################################
# Script: distribute-ssh-keys.sh
# Purpose: Distribute Ansible SSH public key to all managed hosts
################################################################################

set -e

# SSH public key
PUBKEY=$(cat ~/.ssh/ansible_ed25519.pub)

# Managed hosts
HOSTS=(
  "ubuntu@10.0.110.11"  # monitoring
  "ubuntu@10.0.110.12"  # backup
  "ubuntu@10.0.110.13"  # jump-host
  "debian@10.0.120.10"  # dc01
  "debian@10.0.120.11"  # dc02
  "ubuntu@10.0.120.20"  # fs01
  "debian@10.0.120.30"  # db01
  "ubuntu@10.0.120.40"  # app01
  "debian@10.0.120.50"  # mail01
  "ubuntu@10.0.130.10"  # ws-admin01
  "ubuntu@10.0.150.10"  # web01
  "debian@10.0.150.20"  # vpn-gw
  "debian@10.0.150.30"  # mail-relay
)

echo "Distributing SSH key to managed hosts..."
echo ""

for host in "${HOSTS[@]}"; do
  echo "Copying key to $host..."
  ssh-copy-id -i ~/.ssh/ansible_ed25519.pub "$host" || echo "Failed to copy to $host"
done

echo ""
echo "SSH key distribution complete!"
EOF

chmod +x ~/scripts/distribute-ssh-keys.sh

# Run the script (will prompt for passwords)
# ~/scripts/distribute-ssh-keys.sh
```

**Note:** You'll need to enter the password for each host. After this completes, Ansible will have passwordless SSH access.

---

## Phase 5: Ansible Inventory Configuration

### 5.1 Create Dynamic Inventory

```bash
# Create inventory file
cat > /etc/ansible/hosts <<'EOF'
# SMB Office IT Blueprint - Ansible Inventory
# Updated: 2025-12-28

################################################################################
# Management Infrastructure (VLAN 110)
################################################################################

[management]
ansible-ctrl   ansible_host=10.0.110.10  ansible_user=ubuntu
monitoring     ansible_host=10.0.110.11  ansible_user=ubuntu
backup         ansible_host=10.0.110.12  ansible_user=ubuntu
jump-host      ansible_host=10.0.110.13  ansible_user=ubuntu

[management:vars]
vlan_id=110
vlan_network=10.0.110.0/24
vlan_gateway=10.0.110.1

################################################################################
# Production Servers (VLAN 120)
################################################################################

[domain_controllers]
dc01           ansible_host=10.0.120.10  ansible_user=debian  dc_role=primary
dc02           ansible_host=10.0.120.11  ansible_user=debian  dc_role=replica

[file_servers]
fs01           ansible_host=10.0.120.20  ansible_user=ubuntu

[database_servers]
db01           ansible_host=10.0.120.30  ansible_user=debian  db_type=postgresql

[app_servers]
app01          ansible_host=10.0.120.40  ansible_user=ubuntu

[mail_servers]
mail01         ansible_host=10.0.120.50  ansible_user=debian

[production:children]
domain_controllers
file_servers
database_servers
app_servers
mail_servers

[production:vars]
vlan_id=120
vlan_network=10.0.120.0/24
vlan_gateway=10.0.120.1

################################################################################
# Workstations (VLAN 130)
################################################################################

[workstations]
ws-admin01     ansible_host=10.0.130.10  ansible_user=ubuntu  workstation_type=admin

[workstations:vars]
vlan_id=130
vlan_network=10.0.130.0/24
vlan_gateway=10.0.130.1

################################################################################
# DMZ Services (VLAN 150)
################################################################################

[dmz]
web01          ansible_host=10.0.150.10  ansible_user=ubuntu
vpn-gw         ansible_host=10.0.150.20  ansible_user=debian
mail-relay     ansible_host=10.0.150.30  ansible_user=debian

[dmz:vars]
vlan_id=150
vlan_network=10.0.150.0/24
vlan_gateway=10.0.150.1

################################################################################
# Logical Groupings
################################################################################

[debian_hosts]
dc01
dc02
db01
mail01
vpn-gw
mail-relay

[ubuntu_hosts]
ansible-ctrl
monitoring
backup
jump-host
fs01
app01
ws-admin01
web01

[all:vars]
# Global variables
domain=corp.company.local
dns_servers=10.0.120.10,10.0.120.11
ntp_server=pool.ntp.org
timezone=America/New_York

# SSH settings
ansible_ssh_private_key_file=~/.ssh/ansible_ed25519
ansible_ssh_common_args='-o StrictHostKeyChecking=no'

# Python interpreter
ansible_python_interpreter=/usr/bin/python3
EOF
```

### 5.2 Create Group Variables

```bash
# Create group_vars directory structure
mkdir -p ~/projects/smb-office-it-blueprint/inventory/group_vars

# All hosts variables
cat > ~/projects/smb-office-it-blueprint/inventory/group_vars/all.yml <<'EOF'
---
################################################################################
# Global Variables - Apply to All Hosts
################################################################################

# Domain and DNS
domain_name: corp.company.local
search_domains:
  - corp.company.local

dns_servers:
  - 10.0.120.10  # dc01
  - 10.0.120.11  # dc02

# NTP Configuration
ntp_servers:
  - pool.ntp.org
  - time.nist.gov

# Timezone
system_timezone: America/New_York

# SSH Configuration
ssh_port: 22
ssh_permit_root_login: "no"
ssh_password_authentication: "no"
ssh_pubkey_authentication: "yes"

# Security
firewall_enabled: yes
fail2ban_enabled: yes

# Monitoring
monitoring_server: 10.0.110.11
syslog_server: 10.0.110.11

# Backup
backup_server: 10.0.110.12

# Package management
auto_updates: yes
auto_update_time: "03:00"
EOF

# Ubuntu hosts variables
cat > ~/projects/smb-office-it-blueprint/inventory/group_vars/ubuntu_hosts.yml <<'EOF'
---
################################################################################
# Ubuntu Hosts Variables
################################################################################

ansible_user: ubuntu
ansible_become: yes
ansible_become_method: sudo

# Package manager
package_manager: apt

# Common packages
common_packages:
  - vim
  - git
  - curl
  - wget
  - htop
  - net-tools
  - dnsutils
  - python3
  - python3-pip

# Services
services_to_enable:
  - ssh
  - systemd-resolved
  - systemd-timesyncd
EOF

# Debian hosts variables
cat > ~/projects/smb-office-it-blueprint/inventory/group_vars/debian_hosts.yml <<'EOF'
---
################################################################################
# Debian Hosts Variables
################################################################################

ansible_user: debian
ansible_become: yes
ansible_become_method: sudo

# Package manager
package_manager: apt

# Common packages
common_packages:
  - vim
  - git
  - curl
  - wget
  - htop
  - net-tools
  - dnsutils
  - python3
  - python3-pip

# Services
services_to_enable:
  - ssh
  - systemd-resolved
  - systemd-timesyncd
EOF
```

---

## Phase 6: Test Ansible Connectivity

### 6.1 Ping All Hosts

```bash
# Test connectivity to all hosts
ansible all -m ping

# Expected output:
# ansible-ctrl | SUCCESS => {
#     "changed": false,
#     "ping": "pong"
# }
# [... more hosts ...]

# Test specific groups
ansible management -m ping
ansible production -m ping
ansible domain_controllers -m ping
```

### 6.2 Gather Facts

```bash
# Gather facts from all hosts
ansible all -m setup --tree /tmp/facts

# View facts for specific host
ansible dc01 -m setup | less

# Get specific facts
ansible all -m setup -a "filter=ansible_distribution*"
ansible all -m setup -a "filter=ansible_memtotal_mb"
```

### 6.3 Run Ad-Hoc Commands

```bash
# Check uptime
ansible all -a "uptime"

# Check disk space
ansible all -a "df -h"

# Check memory
ansible all -a "free -h"

# Update package lists
ansible all -m apt -a "update_cache=yes" --become

# Check OS version
ansible all -m shell -a "cat /etc/os-release | head -n 2"
```

---

## Phase 7: Create Essential Playbooks

### 7.1 System Update Playbook

```bash
cd ~/projects/smb-office-it-blueprint/playbooks

cat > update-all-systems.yml <<'EOF'
---
################################################################################
# Playbook: update-all-systems.yml
# Purpose: Update all systems (apt update && apt upgrade)
# Usage: ansible-playbook playbooks/update-all-systems.yml
################################################################################

- name: Update All Systems
  hosts: all
  become: yes
  gather_facts: yes

  tasks:
    - name: Update apt cache (Ubuntu/Debian)
      apt:
        update_cache: yes
        cache_valid_time: 3600
      when: ansible_os_family == "Debian"

    - name: Upgrade all packages
      apt:
        upgrade: dist
        autoremove: yes
        autoclean: yes
      when: ansible_os_family == "Debian"
      register: upgrade_result

    - name: Display upgrade results
      debug:
        msg: "{{ inventory_hostname }}: {{ upgrade_result.changed | ternary('Packages upgraded', 'No upgrades available') }}"

    - name: Check if reboot required
      stat:
        path: /var/run/reboot-required
      register: reboot_required

    - name: Display reboot requirement
      debug:
        msg: "{{ inventory_hostname }} requires reboot!"
      when: reboot_required.stat.exists

    - name: Reboot if required
      reboot:
        msg: "Rebooting after system updates"
        reboot_timeout: 300
      when:
        - reboot_required.stat.exists
        - auto_reboot | default(false) | bool
EOF
```

### 7.2 Configure Common Settings Playbook

```bash
cat > configure-common-settings.yml <<'EOF'
---
################################################################################
# Playbook: configure-common-settings.yml
# Purpose: Apply common configuration to all systems
# Usage: ansible-playbook playbooks/configure-common-settings.yml
################################################################################

- name: Configure Common Settings
  hosts: all
  become: yes
  gather_facts: yes

  tasks:
    - name: Set timezone
      timezone:
        name: "{{ system_timezone }}"

    - name: Configure /etc/hosts
      lineinfile:
        path: /etc/hosts
        line: "{{ item }}"
        state: present
      loop:
        - "10.0.110.10   ansible-ctrl"
        - "10.0.110.11   monitoring"
        - "10.0.120.10   dc01"
        - "10.0.120.11   dc02"

    - name: Install common packages
      apt:
        name: "{{ common_packages }}"
        state: present
        update_cache: yes

    - name: Configure SSH server
      lineinfile:
        path: /etc/ssh/sshd_config
        regexp: "{{ item.regexp }}"
        line: "{{ item.line }}"
        state: present
      loop:
        - { regexp: '^#?PermitRootLogin', line: 'PermitRootLogin no' }
        - { regexp: '^#?PubkeyAuthentication', line: 'PubkeyAuthentication yes' }
        - { regexp: '^#?PasswordAuthentication', line: 'PasswordAuthentication no' }
      notify: Restart SSH

    - name: Enable and start SSH
      systemd:
        name: ssh
        enabled: yes
        state: started

  handlers:
    - name: Restart SSH
      systemd:
        name: ssh
        state: restarted
EOF
```

### 7.3 Health Check Playbook

```bash
cat > health-check.yml <<'EOF'
---
################################################################################
# Playbook: health-check.yml
# Purpose: Run health checks on all infrastructure
# Usage: ansible-playbook playbooks/health-check.yml
################################################################################

- name: Infrastructure Health Check
  hosts: all
  gather_facts: yes
  become: yes

  tasks:
    - name: Check system uptime
      command: uptime -p
      register: uptime
      changed_when: false

    - name: Check disk usage
      shell: df -h / | tail -1 | awk '{print $5}' | sed 's/%//'
      register: disk_usage
      changed_when: false

    - name: Check memory usage
      shell: free | grep Mem | awk '{printf "%.0f", ($3/$2) * 100}'
      register: mem_usage
      changed_when: false

    - name: Check if services are running
      systemd:
        name: "{{ item }}"
      register: service_status
      loop:
        - ssh
      failed_when: false
      changed_when: false

    - name: Create health report
      debug:
        msg:
          - "Host: {{ inventory_hostname }}"
          - "IP: {{ ansible_host }}"
          - "OS: {{ ansible_distribution }} {{ ansible_distribution_version }}"
          - "Uptime: {{ uptime.stdout }}"
          - "Disk Usage: {{ disk_usage.stdout }}%"
          - "Memory Usage: {{ mem_usage.stdout }}%"
          - "SSH: {{ service_status.results[0].status.ActiveState | default('unknown') }}"

    - name: Warn if disk usage is high
      debug:
        msg: "WARNING: {{ inventory_hostname }} disk usage is {{ disk_usage.stdout }}%"
      when: disk_usage.stdout | int > 80

    - name: Warn if memory usage is high
      debug:
        msg: "WARNING: {{ inventory_hostname }} memory usage is {{ mem_usage.stdout }}%"
      when: mem_usage.stdout | int > 90
EOF
```

---

## Phase 8: Useful Scripts and Aliases

### 8.1 Create Helper Scripts

```bash
mkdir -p ~/scripts

# Quick playbook runner
cat > ~/scripts/run-playbook.sh <<'EOF'
#!/bin/bash
################################################################################
# Script: run-playbook.sh
# Purpose: Quick playbook execution with common options
################################################################################

PLAYBOOK_DIR="$HOME/projects/smb-office-it-blueprint/playbooks"

if [ $# -eq 0 ]; then
    echo "Usage: $0 <playbook-name> [ansible-playbook options]"
    echo ""
    echo "Available playbooks:"
    ls -1 "$PLAYBOOK_DIR"/*.yml | xargs -n1 basename
    exit 1
fi

PLAYBOOK="$1"
shift

# Add .yml extension if not present
if [[ ! "$PLAYBOOK" =~ \.yml$ ]]; then
    PLAYBOOK="${PLAYBOOK}.yml"
fi

cd "$PLAYBOOK_DIR" || exit 1
ansible-playbook "$PLAYBOOK" "$@"
EOF

chmod +x ~/scripts/run-playbook.sh

# Infrastructure status check
cat > ~/scripts/infra-status.sh <<'EOF'
#!/bin/bash
################################################################################
# Script: infra-status.sh
# Purpose: Quick infrastructure status overview
################################################################################

echo "SMB Office IT Infrastructure Status"
echo "===================================="
echo ""

echo "Pinging all hosts..."
ansible all -m ping -o

echo ""
echo "Running health check..."
ansible-playbook ~/projects/smb-office-it-blueprint/playbooks/health-check.yml
EOF

chmod +x ~/scripts/infra-status.sh
```

### 8.2 Add Bash Aliases

```bash
# Add to ~/.bashrc
cat >> ~/.bashrc <<'EOF'

# Ansible aliases
alias ans='ansible'
alias ap='ansible-playbook'
alias ag='ansible-galaxy'
alias av='ansible-vault'
alias ai='ansible-inventory'

# Project shortcuts
alias infra='cd ~/projects/smb-office-it-blueprint'
alias playbooks='cd ~/projects/smb-office-it-blueprint/playbooks'
alias roles='cd ~/projects/smb-office-it-blueprint/roles'

# Quick commands
alias ping-all='ansible all -m ping -o'
alias update-all='ansible-playbook ~/projects/smb-office-it-blueprint/playbooks/update-all-systems.yml'
alias health-check='~/scripts/infra-status.sh'

# Logs
alias ansible-log='tail -f /var/log/ansible/ansible.log'
EOF

# Reload bashrc
source ~/.bashrc
```

---

## Phase 9: Documentation and Best Practices

### 9.1 Create README for Project

```bash
cd ~/projects/smb-office-it-blueprint

cat > README.md <<'EOF'
# SMB Office IT Blueprint - Ansible Automation

## Overview

This repository contains Ansible playbooks and roles for managing the SMB Office IT infrastructure.

## Infrastructure

- **Management VLAN (110):** Ansible, Monitoring, Backup, Jump Host
- **Production VLAN (120):** Domain Controllers, File Server, Database, App Server, Mail Server
- **Workstations VLAN (130):** Admin Workstations
- **DMZ VLAN (150):** Web Server, VPN Gateway, Mail Relay

## Quick Start

```bash
# Test connectivity
ansible all -m ping

# Run health check
ansible-playbook playbooks/health-check.yml

# Update all systems
ansible-playbook playbooks/update-all-systems.yml

# Configure common settings
ansible-playbook playbooks/configure-common-settings.yml
```

## Directory Structure

```
.
├── inventory/
│   ├── group_vars/
│   └── host_vars/
├── playbooks/
│   ├── infrastructure/
│   ├── services/
│   ├── workstations/
│   └── security/
├── roles/
├── scripts/
└── docs/
```

## Playbook Naming Convention

- `deploy-*.yml` - Deployment playbooks
- `configure-*.yml` - Configuration playbooks
- `update-*.yml` - Update playbooks
- `health-check.yml` - Health and status checks

## Variables

Global variables are defined in `inventory/group_vars/all.yml`

## Security

- SSH keys used for authentication
- No password authentication
- Ansible Vault for secrets (when needed)

## Support

For issues, check `/var/log/ansible/ansible.log`
EOF
```

---

## Phase 10: Verification and Testing

### 10.1 Final Verification Checklist

```bash
# 1. Check Ansible version
ansible --version

# 2. Verify inventory
ansible-inventory --list

# 3. Ping all hosts
ansible all -m ping

# 4. Check connectivity by group
ansible management -m ping
ansible production -m ping
ansible workstations -m ping
ansible dmz -m ping

# 5. Gather facts
ansible all -m setup -a "filter=ansible_distribution*"

# 6. Test playbook syntax
cd ~/projects/smb-office-it-blueprint/playbooks
ansible-playbook health-check.yml --syntax-check
ansible-playbook update-all-systems.yml --syntax-check
ansible-playbook configure-common-settings.yml --syntax-check

# 7. Run health check
ansible-playbook health-check.yml

# 8. Check Ansible log
tail -20 /var/log/ansible/ansible.log
```

### 10.2 Test Ad-Hoc Commands

```bash
# System information
ansible all -a "hostname"
ansible all -a "uptime"
ansible all -a "df -h"
ansible all -a "free -h"

# Network information
ansible all -a "ip addr show"
ansible all -m setup -a "filter=ansible_default_ipv4"

# Service status
ansible all -m systemd -a "name=ssh state=started"

# Package management
ansible ubuntu_hosts -m apt -a "name=vim state=present" --become
ansible debian_hosts -m apt -a "name=vim state=present" --become
```

---

## Next Steps

### Immediate Tasks

1. **Distribute SSH keys** to all managed hosts:
   ```bash
   ~/scripts/distribute-ssh-keys.sh
   ```

2. **Run initial configuration**:
   ```bash
   ansible-playbook playbooks/configure-common-settings.yml
   ```

3. **Perform system updates**:
   ```bash
   ansible-playbook playbooks/update-all-systems.yml
   ```

### Service Configuration

Now that Ansible is configured, proceed with service deployment:

1. Configure Domain Controllers (dc01, dc02)
2. Configure File Server (fs01)
3. Configure Database Server (db01)
4. Configure Application Server (app01)
5. Configure Mail Server (mail01)
6. Configure DMZ services (web01, vpn-gw, mail-relay)
7. Configure Monitoring (monitoring server)
8. Configure Backup (backup server)

### Recommended Reading

- `/home/ubuntu/projects/smb-office-it-blueprint/docs/guides/post-deployment-checklist.md`
- Ansible documentation: https://docs.ansible.com
- Best practices: https://docs.ansible.com/ansible/latest/user_guide/playbooks_best_practices.html

---

## Troubleshooting

### SSH Connection Issues

```bash
# Test SSH manually
ssh -i ~/.ssh/ansible_ed25519 ubuntu@10.0.110.11

# Check SSH config
ansible all -m ping -vvv

# Regenerate host keys if needed
ansible all -a "ssh-keygen -A" --become
```

### Playbook Failures

```bash
# Run with verbose output
ansible-playbook playbooks/health-check.yml -v
ansible-playbook playbooks/health-check.yml -vv
ansible-playbook playbooks/health-check.yml -vvv

# Check syntax
ansible-playbook playbooks/health-check.yml --syntax-check

# Dry run
ansible-playbook playbooks/health-check.yml --check

# Check specific task
ansible-playbook playbooks/health-check.yml --start-at-task="task name"
```

### Permission Issues

```bash
# Verify sudo access
ansible all -m shell -a "whoami" --become

# Check sudoers configuration
ansible all -a "sudo -l" --become
```

---

## Maintenance

### Regular Tasks

```bash
# Weekly: Update all systems
ansible-playbook playbooks/update-all-systems.yml

# Daily: Health check
ansible-playbook playbooks/health-check.yml

# Monthly: Full fact gathering and inventory audit
ansible all -m setup --tree /var/log/ansible/facts/$(date +%Y%m%d)
```

### Backup

```bash
# Backup Ansible configuration and project
tar -czf ~/ansible-backup-$(date +%Y%m%d).tar.gz \
  /etc/ansible \
  ~/.ssh/ansible_ed25519* \
  ~/projects/smb-office-it-blueprint

# Copy to backup server
scp ~/ansible-backup-*.tar.gz ubuntu@10.0.110.12:/backup/ansible/
```

---

## Security Considerations

- Ansible SSH keys are unencrypted for automation (stored in `~/.ssh/ansible_ed25519`)
- Store sensitive data in Ansible Vault (see Ansible Vault documentation)
- Limit Ansible control server access via firewall rules
- Regularly rotate SSH keys
- Review Ansible logs for unauthorized access attempts
- Keep Ansible and Python packages updated

---

**Setup Complete!**

Your Ansible Control Server is now ready to manage the SMB Office IT infrastructure.
EOF
