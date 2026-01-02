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
**Purpose:** Create admin user with sudo access

**Required Variables:**
```yaml
admin_user:
  username: richard
  groups:
    - sudo  # Ubuntu
    - wheel # Rocky
  shell: /bin/bash
```

**Notes:**
- Configures NOPASSWD sudo access
- Creates sudoers.d file for the user

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
5. `user_config` - Create users
6. `ssh_config` - Configure remote access
7. `service_config` - Final service configuration

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
