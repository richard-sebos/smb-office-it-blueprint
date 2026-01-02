# Ansible Roles Reference

## Overview

These roles provide reusable configuration modules that work across both Ubuntu and Rocky Linux systems.

## Available Roles

### network_config
**Purpose:** Configure static network settings

**Supports:**
- Ubuntu: netplan configuration
- Rocky: NetworkManager configuration

**Required Variables:**
```yaml
network:
  interface: ens18
  ip_address: 10.0.131.10
  netmask: 24
  gateway: 10.0.131.1
  dns_servers:
    - 10.0.120.10
    - 10.0.120.11
  search_domain: corp.company.local
os_type: rocky  # or ubuntu
```

---

### hostname_config
**Purpose:** Set system hostname and update /etc/hosts

**Required Variables:**
```yaml
hostname: ws-admin01
fqdn: ws-admin01.corp.company.local
```

---

### system_update
**Purpose:** Update all system packages

**Supports:**
- Ubuntu: apt upgrade
- Rocky: dnf upgrade

**Required Variables:**
```yaml
os_type: rocky  # or ubuntu
```

---

### install_packages
**Purpose:** Install software packages

**Supports:**
- Ubuntu: apt package manager
- Rocky: dnf package manager with EPEL

**Required Variables:**
```yaml
os_type: rocky  # or ubuntu
packages:
  base:
    - vim
    - git
  network_tools:
    - tcpdump
    - wireshark
  admin_tools:
    - ansible
  desktop:
    - firefox
```

**Package Categories:**
- `packages.base` - Base system utilities
- `packages.network_tools` - Network diagnostic tools
- `packages.admin_tools` - System administration tools
- `packages.desktop` - Desktop applications

---

### user_config
**Purpose:** Create admin user with sudo access and deploy SSH keys

**Required Variables:**
```yaml
admin_user:
  username: richard
  groups:
    - sudo  # Ubuntu
    - wheel # Rocky
  shell: /bin/bash
  ssh_public_key_path: ~/.ssh/id_rsa.pub  # Path on control machine
```

**Features:**
- Creates admin user
- Configures NOPASSWD sudo access
- Creates .ssh directory with proper permissions
- Deploys SSH public key to authorized_keys

**Notes:**
- `ssh_public_key_path` is optional - if not defined, key deployment is skipped
- Path is relative to the Ansible control machine (where you run ansible-playbook)
- Supports tilde (~) expansion for home directory

---

### ssh_config
**Purpose:** Configure SSH service

**Features:**
- Enables and starts sshd
- Allows password authentication
- Creates backup of sshd_config

**Handlers:**
- Restart SSH (triggered on config changes)

---

### ssh_hardening
**Purpose:** Apply modular SSH security policies using sshd_config.d

**Features:**
- Session timeout and keepalive settings
- CVE-2024-6387 mitigation (LoginGraceTime 0)
- Brute-force protection (MaxStartups)
- Key-based authentication only (no passwords)
- Group-based access control (ssh-users group)
- Disable all forwarding and tunneling
- Disable user environment variables
- Optional network-based access restrictions

**Required Variables:**
```yaml
admin_user:
  username: richard  # User to add to ssh-users group

ssh_hardening:
  allowed_networks:  # Optional
    - cidr: 10.0.0.0/8
      description: Internal network
    - cidr: 192.168.0.0/16
      description: Private range
```

**Policy Files Created:**
- `06-session.conf` - Session timeouts, keepalives, CVE mitigation
- `07-authentication.conf` - Authentication restrictions, key-only login
- `08-access-control.conf` - Network-based access control (optional)
- `10-forwarding.conf` - Disable all forwarding/tunneling
- `99-hardening.conf` - Environment variable restrictions

**Notes:**
- Creates `ssh-users` group automatically
- Adds admin user to ssh-users group
- Validates all configs before applying
- Backs up main sshd_config before modification
- All policy files are located in `/etc/ssh/sshd_config.d/`
- **IMPORTANT**: Ensure SSH key is deployed before applying this role, as password auth is disabled

---

### service_config
**Purpose:** Enable/disable system services

**Required Variables:**
```yaml
services:
  enabled:
    - ssh
  disabled:
    - bluetooth
```

**Notes:**
- Ignores errors for non-existent services
- Starts enabled services
- Stops disabled services

---

## Using Roles in Playbooks

### Basic Usage

```yaml
---
- name: Configure Server
  hosts: myserver
  become: yes
  gather_facts: yes

  roles:
    - network_config
    - hostname_config
    - system_update
    - install_packages
    - user_config
    - ssh_config
    - ssh_hardening
    - service_config
```

### Selective Role Execution

```bash
# Run only network configuration
ansible-playbook playbook.yml --tags network_config

# Skip package installation
ansible-playbook playbook.yml --skip-tags install_packages
```

### Role Dependencies

Recommended role order:
1. `network_config` - Network must be configured first
2. `hostname_config` - Set hostname
3. `system_update` - Update packages before installing new ones
4. `install_packages` - Install required software
5. `user_config` - Create users and deploy SSH keys
6. `ssh_config` - Basic SSH configuration
7. `ssh_hardening` - Apply security policies (after keys are deployed)
8. `service_config` - Final service configuration

## Adding New Roles

Create role structure:

```bash
mkdir -p roles/my_new_role/{tasks,handlers,templates,files,vars,defaults}
```

Minimum required:
- `tasks/main.yml` - Role tasks
- `handlers/main.yml` - Handlers (if needed)

## OS-Specific Logic

All roles detect OS type using the `os_type` variable:

```yaml
- name: Task for Ubuntu only
  when: os_type == "ubuntu"
  # ... ubuntu-specific task

- name: Task for Rocky only
  when: os_type == "rocky"
  # ... rocky-specific task
```

## Network Tools Reference

**For Rocky Linux:**
- `tcpdump` - Packet capture
- `wireshark` - GUI packet analyzer
- `wireshark-cli` - tshark command-line analyzer
- `nmap` - Network scanner
- `nmap-ncat` - nc (netcat) utility
- `net-tools` - netstat and other tools

**For Ubuntu:**
- `tcpdump` - Packet capture
- `wireshark` - GUI packet analyzer
- `tshark` - Command-line analyzer (separate package)
- `nmap` - Network scanner
- `netcat` or `netcat-openbsd` - nc utility
- `net-tools` - netstat and other tools
