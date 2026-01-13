# Role-Based Playbook Architecture

## Overview

The configuration playbook has been refactored from **inline tasks** to a **role-based architecture** for better maintainability, reusability, and organization.

## Before vs After

### Before (450 lines with inline tasks)
```yaml
- name: Configure ws-reception01 - Desktop Environment
  tasks:
    - name: Configure GNOME idle timeout
      command: gsettings set ...
    - name: Configure GNOME screen lock
      command: gsettings set ...
    - name: Create Firefox policies directory
      file: path=/etc/firefox/policies ...
    - name: Create browser bookmarks file
      template: dest=/etc/firefox/policies/policies.json ...
    # 30+ more inline tasks...
```

### After (180 lines with roles)
```yaml
- name: Configure ws-reception01 - Desktop and Firewall
  roles:
    - silverblue_desktop_environment
    - silverblue_firewall
```

## New Roles Created

### 1. **silverblue_desktop_environment**
**Purpose:** Configure GNOME desktop settings

**What it does:**
- GNOME idle timeout configuration
- Screen lock settings
- Lock on suspend settings
- Firefox browser bookmarks

**Files:**
```
roles/silverblue_desktop_environment/
├── defaults/main.yml          # Default timeout values
├── tasks/main.yml             # GNOME configuration tasks
└── templates/
    └── firefox-policies.json.j2
```

**Usage in playbook:**
```yaml
- role: silverblue_desktop_environment
  ignore_errors: yes
```

---

### 2. **silverblue_firewall**
**Purpose:** Configure firewalld with whitelist rules

**What it does:**
- Install firewalld (via rpm-ostree)
- Set default zone
- Allow SSH from management network
- Allow required services (DNS, LDAP, Kerberos, HTTP, IPP)
- Allow required ports
- Create rich rules for whitelisted destinations

**Files:**
```
roles/silverblue_firewall/
├── defaults/main.yml          # Default firewall zone
├── tasks/main.yml             # Firewall configuration
└── handlers/main.yml          # Firewall reload handler
```

**Usage in playbook:**
```yaml
- role: silverblue_firewall
  ignore_errors: yes
```

---

### 3. **silverblue_logging**
**Purpose:** Configure rsyslog and auditd for centralized logging

**What it does:**
- Configure rsyslog for remote logging to monitoring01
- Configure auditd rules for security events
- Enable and start logging services
- Template-based configuration

**Files:**
```
roles/silverblue_logging/
├── defaults/main.yml          # Logging defaults
├── tasks/main.yml             # Logging configuration
├── templates/
│   ├── rsyslog-remote.conf.j2
│   └── auditd-workstation.rules.j2
└── handlers/main.yml          # Service restart handlers
```

**Usage in playbook:**
```yaml
- role: silverblue_logging
  ignore_errors: yes
```

---

### 4. **silverblue_finalize**
**Purpose:** Cleanup and verification script creation

**What it does:**
- Remove temporary management interface
- Reload NetworkManager
- Create workstation verification script (`/usr/local/bin/verify-workstation.sh`)

**Files:**
```
roles/silverblue_finalize/
├── defaults/main.yml          # Finalization options
├── tasks/main.yml             # Cleanup tasks
└── templates/
    └── verify-workstation.sh.j2
```

**Usage in playbook:**
```yaml
- role: silverblue_finalize
  ignore_errors: yes
```

---

## New Playbook Structure

The `configure-ws-reception01.yml` playbook now has **4 clean plays**:

```yaml
# Play 1: Base System (3 roles)
- name: Configure ws-reception01 - Base System
  roles:
    - network_config
    - hostname_config
    - system_update

# Play 2: Security Features (5 roles)
- name: Configure ws-reception01 - Security Features
  roles:
    - silverblue_ad_integration
    - silverblue_pam_access
    - silverblue_logging          # NEW ROLE
    - silverblue_printer_config
    - silverblue_nightly_reset

# Play 3: Desktop and Firewall (2 roles)
- name: Configure ws-reception01 - Desktop and Firewall
  roles:
    - silverblue_desktop_environment  # NEW ROLE
    - silverblue_firewall              # NEW ROLE

# Play 4: Finalization (1 role)
- name: Configure ws-reception01 - Finalization
  roles:
    - silverblue_finalize              # NEW ROLE
```

**Total:** 11 roles, zero inline tasks

---

## Benefits of Role-Based Architecture

### ✅ **Reusability**
```bash
# Use same roles for different workstation types
roles:
  - silverblue_desktop_environment  # Finance workstation
  - silverblue_firewall              # HR workstation
  - silverblue_logging               # Executive workstation
```

### ✅ **Maintainability**
- Each role has single responsibility
- Easy to find and update configuration
- Template files separate from tasks
- Defaults in one place

### ✅ **Testability**
```bash
# Test individual roles
ansible-playbook test-role.yml --tags silverblue_firewall

# Test without AD integration
ansible-playbook configure-ws-reception01.yml --skip-tags ad_integration
```

### ✅ **Readability**
- Playbook is now 180 lines (was 450+)
- Clear role names explain purpose
- No deep nesting of inline tasks
- Self-documenting structure

### ✅ **Modularity**
```yaml
# Finance workstation: stricter logging
- role: silverblue_logging
  vars:
    logging:
      auditd:
        log_file_access: true
        log_user_commands: true

# Receptionist workstation: standard logging
- role: silverblue_logging
  # Uses defaults from role
```

---

## Complete Role List

| Role | Purpose | Created |
|------|---------|---------|
| `network_config` | Configure static IP, VLAN, DNS | Existing |
| `hostname_config` | Set hostname and FQDN | Existing |
| `system_update` | Update system packages | Existing |
| `silverblue_ad_integration` | SSSD + Kerberos for AD auth | Session 1 |
| `silverblue_pam_access` | PAM access control (group restrictions) | Session 1 |
| `silverblue_printer_config` | Configure network printers | Session 1 |
| `silverblue_nightly_reset` | Automated 2 AM reset script | Session 1 |
| **`silverblue_desktop_environment`** | GNOME settings, bookmarks | **NEW** |
| **`silverblue_firewall`** | Firewalld whitelist rules | **NEW** |
| **`silverblue_logging`** | Rsyslog + auditd configuration | **NEW** |
| **`silverblue_finalize`** | Cleanup and verification script | **NEW** |

**Total:** 11 roles

---

## Role Organization Pattern

Each role follows this structure:

```
role_name/
├── defaults/main.yml      # Default variables
├── tasks/main.yml         # Main task list
├── templates/             # Jinja2 templates
│   └── config.j2
└── handlers/main.yml      # Service handlers (if needed)
```

**Example: silverblue_logging**
```
silverblue_logging/
├── defaults/main.yml
│   └── default_rsyslog_enabled: true
├── tasks/main.yml
│   └── Configure rsyslog, auditd
├── templates/
│   ├── rsyslog-remote.conf.j2
│   └── auditd-workstation.rules.j2
└── handlers/main.yml
    ├── restart rsyslog
    └── restart auditd
```

---

## Using Roles for Other Workstations

### Finance Workstation (ws-finance01)

Create `configure-ws-finance01.yml`:
```yaml
- name: Configure ws-finance01 - Security Features
  hosts: ws-finance01
  roles:
    - silverblue_ad_integration
    - silverblue_pam_access
    - role: silverblue_logging
      vars:
        logging:
          auditd:
            log_file_access: true      # Extra logging for finance
            log_user_commands: true
    - silverblue_printer_config
    - silverblue_nightly_reset
    - silverblue_desktop_environment
    - silverblue_firewall
    - silverblue_finalize
```

### HR Workstation (ws-hr01)

Create `configure-ws-hr01.yml`:
```yaml
- name: Configure ws-hr01 - Security Features
  hosts: ws-hr01
  roles:
    # Same roles, different host_vars
    - silverblue_ad_integration
    - silverblue_pam_access
    - silverblue_logging
    - silverblue_printer_config
    - silverblue_nightly_reset
    - silverblue_desktop_environment
    - silverblue_firewall
    - silverblue_finalize
```

Just change the `host_vars/ws-hr01.yml` to customize:
```yaml
access_control:
  allowed_ad_groups:
    - HR-Staff        # Different group
    - GG-HR

session_security:
  idle_timeout_minutes: 10  # Longer timeout for HR
```

---

## Role Variables

### Example: silverblue_desktop_environment

**Defaults (in role):**
```yaml
default_idle_timeout_minutes: 15
default_screen_lock_enabled: true
default_lock_on_suspend: true
```

**Override (in host_vars):**
```yaml
session_security:
  idle_timeout_minutes: 3          # Override for receptionist
  screen_lock_enabled: true
  lock_on_suspend: true

desktop_environment:
  browser_bookmarks:
    - name: "Company Intranet"
      url: "https://intranet.company.local"
```

**Result:** Role uses 3 minutes (from host_vars) instead of 15 minutes (default)

---

## Testing Individual Roles

### Test desktop environment role
```bash
ansible-playbook -i inventory/hosts.yml \
  test-role.yml \
  -e target_role=silverblue_desktop_environment \
  -e target_host=ws-reception01
```

### Test firewall role only
```bash
ansible-playbook playbooks/configure-ws-reception01.yml \
  --tags silverblue_firewall
```

### Skip AD integration (for testing)
```bash
ansible-playbook playbooks/configure-ws-reception01.yml \
  --skip-tags silverblue_ad_integration
```

---

## Comparison: Lines of Code

| Component | Before | After | Reduction |
|-----------|--------|-------|-----------|
| Playbook tasks | 300+ lines | 0 lines | 100% |
| Playbook structure | 450 lines | 180 lines | 60% |
| Role tasks | 0 | 200 lines | N/A |
| Role templates | 0 | 5 files | N/A |

**Net result:**
- Playbook is 60% smaller
- Logic is organized in reusable roles
- Templates separated from tasks
- Much easier to maintain

---

## Migration Path for Future Workstations

### Step 1: Create host_vars
```bash
cp host_vars/ws-reception01.yml host_vars/ws-finance01.yml
# Edit to change VMID, IP, allowed groups, etc.
```

### Step 2: Create deployment playbook
```bash
cp playbooks/deploy-ws-reception01.yml playbooks/deploy-ws-finance01.yml
# Change target_host to ws-finance01
```

### Step 3: Create configuration playbook
```bash
cp playbooks/configure-ws-reception01.yml playbooks/configure-ws-finance01.yml
# Change hosts to ws-finance01
# Add/remove roles as needed
```

### Step 4: Deploy
```bash
ansible-playbook playbooks/deploy-ws-finance01.yml
ansible-playbook playbooks/configure-ws-finance01.yml
```

**Roles are already created** - just reuse them!

---

## Future Enhancements

### Potential New Roles

1. **silverblue_vpn_client** - VPN configuration for remote workers
2. **silverblue_yubikey** - Hardware token authentication
3. **silverblue_disk_encryption** - LUKS full disk encryption
4. **silverblue_usb_control** - USB device whitelisting
5. **silverblue_application_whitelist** - SELinux application control

### Generic Playbook

Create `configure-workstation.yml`:
```yaml
- name: Configure workstation (generic)
  hosts: "{{ target_host }}"
  roles:
    - network_config
    - hostname_config
    - system_update
    - silverblue_ad_integration
    - silverblue_pam_access
    - silverblue_logging
    - silverblue_printer_config
    - silverblue_nightly_reset
    - silverblue_desktop_environment
    - silverblue_firewall
    - silverblue_finalize
```

**Usage:**
```bash
ansible-playbook configure-workstation.yml -e target_host=ws-finance01
ansible-playbook configure-workstation.yml -e target_host=ws-hr01
ansible-playbook configure-workstation.yml -e target_host=ws-exec01
```

---

## Files Created/Modified

### New Roles (4 roles, 15 files)
```
roles/silverblue_desktop_environment/
  ├── defaults/main.yml
  ├── tasks/main.yml
  └── templates/firefox-policies.json.j2

roles/silverblue_firewall/
  ├── defaults/main.yml
  ├── tasks/main.yml
  └── handlers/main.yml

roles/silverblue_logging/
  ├── defaults/main.yml
  ├── tasks/main.yml
  ├── templates/rsyslog-remote.conf.j2
  ├── templates/auditd-workstation.rules.j2
  └── handlers/main.yml

roles/silverblue_finalize/
  ├── defaults/main.yml
  ├── tasks/main.yml
  └── templates/verify-workstation.sh.j2
```

### Modified Playbooks
- `playbooks/configure-ws-reception01.yml` - Refactored to use roles

### Documentation
- `playbooks/README-role-based-playbooks.md` - This file

---

**Last Updated:** 2026-01-11
**Author:** Richard
**Project:** SMB Office IT Blueprint
