<!--
███████████████████████████████████████████████████████████████
  🧾 SMB Office IT Blueprint – Project Document
  Doc ID: GUIDE-PROXMOX-API-001
  Author: SMB Office IT Blueprint Project
  Created: 2025-12-26
  Updated: 2025-12-26
  Version: v1.0
  Status: Final
  Confidentiality: Internal
  Project Phase: Implementation
  Category: Configuration Guide
  Audience: IT
  Owners: Linux Admin/Architect, Ansible Programmer
  Reviewers: IT Security Analyst, IT Code Auditor
  Tags: [proxmox, api, authentication, security, ansible]
  Data Sensitivity: Access Credentials (API tokens, passwords)
  Compliance: Internal Security Standards
  Publish Target: Internal
  Summary: >
    Step-by-step guide for creating Proxmox API tokens and configuring
    authentication for the Project Ansible Server. Covers both token-based
    authentication (Proxmox 7.0+) and password authentication (Proxmox 6.x).
  Read Time: ~10 min
███████████████████████████████████████████████████████████████
-->

# 🔐 Proxmox API Token Setup Guide

Complete guide for configuring secure API access between the Project Ansible Server and Proxmox VE.

---

## 📍 Table of Contents

- [1. Overview](#1-overview)
- [2. Prerequisites](#2-prerequisites)
- [3. Token Authentication (Proxmox 7.0+)](#3-token-authentication-proxmox-70)
- [4. Password Authentication (Proxmox 6.x)](#4-password-authentication-proxmox-6x)
- [5. Ansible Configuration](#5-ansible-configuration)
- [6. Testing API Connectivity](#6-testing-api-connectivity)
- [7. Troubleshooting](#7-troubleshooting)
- [8. Security Considerations](#8-security-considerations)
- [9. Related Files](#9-related-files)

---

## 1. Overview

### Purpose

This guide walks through creating a dedicated Proxmox user with API access for the Project Ansible Server. This enables secure, automated management of the Proxmox virtualization infrastructure.

### Authentication Methods

| Proxmox Version | Authentication Method | Security Level | Recommended |
|----------------|----------------------|----------------|-------------|
| **8.0+** | API Token | High (revocable, scoped) | ✅ Yes |
| **7.0 - 7.4** | API Token | High (revocable, scoped) | ✅ Yes |
| **6.x** | Password | Medium (requires password storage) | ⚠️ Upgrade recommended |

### Why Not Use Root?

**Never use the `root@pam` account for automation:**
- ❌ Violates principle of least privilege
- ❌ No audit trail for automation vs. manual actions
- ❌ Cannot be easily revoked without locking out all access
- ❌ If credentials leak, entire Proxmox host is compromised

**Instead, we create a dedicated user with minimal required permissions.**

---

## 2. Prerequisites

### On Proxmox Host

- ✅ Proxmox VE 6.0 or higher installed
- ✅ Root or administrator access to Proxmox web UI
- ✅ Network connectivity on port 8006 (HTTPS)

### On Project Ansible Server

- ✅ Ansible 2.14+ installed
- ✅ Python `proxmoxer` library installed
- ✅ Ansible vault configured (`~/.vault_pass` exists)
- ✅ Project directory structure created (`/opt/project-ansible`)

### Check Your Proxmox Version

**Via Web UI:**
- Log into Proxmox web interface
- Version shown in bottom-right corner (e.g., "Virtual Environment 8.4-1")

**Via SSH:**
```bash
ssh root@proxmox-host
pveversion
```

Output example:
```
pve-manager/8.4.1/4b06efb5db453f29 (running kernel: 6.8.12-4-pve)
```

---

## 3. Token Authentication (Proxmox 7.0+)

### Recommended Method for Modern Proxmox

API tokens provide better security than passwords:
- ✅ Can be revoked without changing passwords
- ✅ No password stored in Ansible vault
- ✅ Granular permission control
- ✅ Audit trail shows token usage

### Step 1: Access Proxmox Web Interface

1. Open browser to: `https://your-proxmox-ip:8006`
2. Log in with root credentials
3. Accept SSL certificate warning (if self-signed)

### Step 2: Create Dedicated User

1. Click **Datacenter** in left sidebar
2. Expand **Permissions**
3. Click **Users**
4. Click **Add** button

**User Configuration:**
- **User name:** `ansible-project`
- **Realm:** `Proxmox VE authentication server` (shows as `@pve`)
- **Enabled:** ✓ (checked)
- **Comment:** `Ansible Project Automation User`
- **Email:** (optional)
- **Group:** (leave empty)

5. Click **Add**

![Create User Screenshot](../assets/proxmox-create-user.png)

### Step 3: Create Custom Role

Standard Proxmox roles (Administrator, PVEAdmin) are too broad. We create a custom role with minimum required permissions.

1. Click **Permissions** → **Roles**
2. Click **Create** button
3. **Name:** `ProjectAutomation`

**Select These Privileges:**

| Category | Privilege | Purpose |
|----------|-----------|---------|
| **VM** | `VM.Allocate` | Create new VMs |
| | `VM.Audit` | Read VM configuration |
| | `VM.Clone` | Clone VMs from templates |
| | `VM.Config.CDROM` | Modify CD-ROM settings |
| | `VM.Config.CPU` | Modify CPU settings |
| | `VM.Config.Cloudinit` | Configure cloud-init |
| | `VM.Config.Disk` | Modify disk settings |
| | `VM.Config.HWType` | Modify hardware type |
| | `VM.Config.Memory` | Modify memory settings |
| | `VM.Config.Network` | Modify network settings |
| | `VM.Config.Options` | Modify VM options |
| | `VM.Console` | Access VM console |
| | `VM.Monitor` | View VM status |
| | `VM.PowerMgmt` | Start/stop/reset VMs |
| **Datastore** | `Datastore.Allocate` | Allocate disk space |
| | `Datastore.AllocateSpace` | Use storage |
| | `Datastore.Audit` | Read storage info |
| **Pool** | `Pool.Allocate` | Create resource pools |
| | `Pool.Audit` | Read pool info |
| **System** | `Sys.Audit` | Read system info |
| **SDN** | `SDN.Allocate` | Manage networks (if available) |
| | `SDN.Audit` | Read network info |

4. Click **Create**

### Step 4: Assign Role to User

1. Click **Permissions** (at the root level)
2. Click **Add** → **User Permission**

**Permission Configuration:**
- **Path:** `/` (root - access to all resources)
- **User:** `ansible-project@pve`
- **Role:** `ProjectAutomation`
- **Propagate:** ✓ (checked - inherit to child objects)

3. Click **Add**

### Step 5: Create API Token

1. Click **Permissions** → **API Tokens**
2. Click **Add** button

**Token Configuration:**
- **User:** `ansible-project@pve` (select from dropdown)
- **Token ID:** `project-automation`
- **Privilege Separation:** ⬜ **UNCHECK THIS BOX!** ⚠️ Critical!
- **Comment:** `Project Ansible Server API Token`
- **Expire:** (leave empty for no expiration)

3. Click **Add**

### Step 6: Save Token Secret

⚠️ **CRITICAL:** A popup window will display the token information:

```
Token ID: ansible-project@pve!project-automation
Secret: xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx
```

**IMMEDIATELY COPY THE SECRET VALUE!**

- You cannot retrieve it later
- Store it securely (password manager recommended)
- You'll add it to Ansible vault in the next section

### Why "Privilege Separation" Must Be Disabled

**Privilege Separation = No:**
- Token inherits all permissions from the user (`ansible-project@pve`)
- Token can use the `ProjectAutomation` role permissions we configured
- ✅ **This is what we want**

**Privilege Separation = Yes:**
- Token has NO permissions by default
- Would need separate permission assignment for the token
- More complex, unnecessary for our use case
- ❌ **Don't use this**

---

## 4. Password Authentication (Proxmox 6.x)

### For Older Proxmox Versions

Proxmox 6.x does not support API tokens. Use password authentication instead.

⚠️ **Security Note:** Password authentication is less secure than tokens. Consider upgrading Proxmox to 7.0+ for production use.

### Step 1: Create User (SSH to Proxmox)

```bash
# SSH to Proxmox host
ssh root@your-proxmox-ip

# Create user
pveum user add ansible-project@pve --comment "Ansible Project Automation User"

# Set password (you'll be prompted)
pveum passwd ansible-project@pve
```

Choose a strong password (16+ characters, mixed case, numbers, symbols).

### Step 2: Create Custom Role

```bash
# Create role with required permissions
pveum role add ProjectAutomation \
  --privs "VM.Allocate VM.Audit VM.Config.CDROM VM.Config.CPU VM.Config.Cloudinit \
           VM.Config.Disk VM.Config.HWType VM.Config.Memory VM.Config.Network \
           VM.Config.Options VM.Clone VM.Console VM.PowerMgmt VM.Monitor \
           Datastore.Allocate Datastore.Audit Pool.Allocate Pool.Audit Sys.Audit \
           SDN.Audit SDN.Allocate"
```

### Step 3: Assign Role to User

```bash
# Grant permissions at root level (access to all resources)
pveum acl modify / --user ansible-project@pve --role ProjectAutomation
```

### Step 4: Verify Configuration

```bash
# List users
pveum user list

# List user permissions
pveum acl list | grep ansible-project
```

Expected output:
```
/                        ansible-project@pve    ProjectAutomation
```

---

## 5. Ansible Configuration

### For Token Authentication (Proxmox 7.0+)

#### Edit Ansible Vault

```bash
cd /opt/project-ansible

# Edit encrypted vault (you'll be prompted for vault password)
ansible-vault edit group_vars/all/vault.yml
```

**Vault content (`group_vars/all/vault.yml`):**
```yaml
---
# Proxmox API Credentials (Token Authentication)
vault_proxmox_api_token_id: "project-automation"
vault_proxmox_api_token_secret: "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx"  # Your actual token
```

Replace `xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx` with the secret you copied in Step 6.

#### Edit Variables File

```bash
vim group_vars/all/vars.yml
```

**Vars content (`group_vars/all/vars.yml`):**
```yaml
---
# Proxmox API Configuration (Token Authentication)
proxmox_api_user: "ansible-project@pve"
proxmox_api_token_id: "{{ vault_proxmox_api_token_id }}"
proxmox_api_token_secret: "{{ vault_proxmox_api_token_secret }}"
```

### For Password Authentication (Proxmox 6.x)

#### Edit Ansible Vault

```bash
ansible-vault edit group_vars/all/vault.yml
```

**Vault content:**
```yaml
---
# Proxmox API Credentials (Password Authentication)
vault_proxmox_api_user: "ansible-project@pve"
vault_proxmox_api_password: "YourSecurePasswordHere"
```

#### Edit Variables File

```bash
vim group_vars/all/vars.yml
```

**Vars content:**
```yaml
---
# Proxmox API Configuration (Password Authentication)
proxmox_api_user: "{{ vault_proxmox_api_user }}"
proxmox_api_password: "{{ vault_proxmox_api_password }}"
```

---

## 6. Testing API Connectivity

### Test Playbook (Token Auth)

```bash
cd /opt/project-ansible
ansible-playbook playbooks/test-proxmox-api.yml
```

### Test Playbook (Password Auth)

```bash
ansible-playbook playbooks/test-proxmox-api-password.yml
```

### Expected Output

```
TASK [Display connection information]
ok: [localhost] => {
    "msg": [
        "Testing connection to Proxmox API",
        "Host: 192.168.1.100",
        "User: ansible-project@pve",
        "Node: pve",
        "SSL Validation: False"
    ]
}

TASK [Display Proxmox version]
ok: [localhost] => {
    "msg": [
        "✓ Proxmox VE Version: 8.4.1",
        "  Release: 8.4",
        "  Repo ID: 4b06efb5db453f29"
    ]
}

TASK [Display cluster summary]
ok: [localhost] => {
    "msg": [
        "✓ Cluster Resources Retrieved",
        "  Total resources: 12"
    ]
}

...

TASK [=== FINAL TEST RESULTS ===]
ok: [localhost] => {
    "msg": [
        "",
        "╔════════════════════════════════════════════════════════════╗",
        "║           PROXMOX API CONNECTION TEST RESULTS             ║",
        "╚════════════════════════════════════════════════════════════╝",
        "",
        "✓ PASS - API Version Retrieval",
        "✓ PASS - Cluster Resources Query",
        "✓ PASS - Node Information Query",
        "✓ PASS - VM List Query",
        "✓ PASS - Storage Query",
        "✓ PASS - Resource Pools Query",
        "",
        "STATUS: ✓ ALL TESTS PASSED - API connectivity verified!",
        ""
    ]
}
```

---

## 7. Troubleshooting

### Common Issues

#### 1. Authentication Failed (401 Unauthorized)

**Symptoms:**
```
HTTP Error 401: Unauthorized
```

**Possible Causes:**
- Incorrect token secret in vault
- Token ID mismatch
- User password incorrect (password auth)

**Solution:**
```bash
# Verify vault contents
ansible-vault view group_vars/all/vault.yml

# Token Auth: Check token exists in Proxmox
# Web UI → Datacenter → Permissions → API Tokens
# Should show: ansible-project@pve!project-automation

# Password Auth: Reset password on Proxmox
ssh root@proxmox-host
pveum passwd ansible-project@pve
```

#### 2. Permission Denied (403 Forbidden)

**Symptoms:**
```
HTTP Error 403: Forbidden
```

**Possible Causes:**
- User lacks required permissions
- Role not assigned to user
- Privilege Separation enabled on token

**Solution:**
```bash
# Check user permissions on Proxmox
ssh root@proxmox-host
pveum acl list | grep ansible-project

# Should show:
# /    ansible-project@pve    ProjectAutomation

# Check token privilege separation (Web UI)
# Datacenter → Permissions → API Tokens
# Privilege Separation should be "No"

# Fix: Recreate token with Privilege Separation disabled
```

#### 3. Connection Refused

**Symptoms:**
```
Failed to connect to host:8006: Connection refused
```

**Possible Causes:**
- Wrong Proxmox IP in inventory
- Firewall blocking port 8006
- Proxmox web interface not running

**Solution:**
```bash
# Test basic connectivity
ping your-proxmox-ip

# Test port 8006
telnet your-proxmox-ip 8006
# OR
nc -zv your-proxmox-ip 8006

# Check Proxmox web service
ssh root@proxmox-host
systemctl status pveproxy
```

#### 4. SSL Certificate Errors

**Symptoms:**
```
SSL: CERTIFICATE_VERIFY_FAILED
```

**Solution:**

For lab/development environments with self-signed certificates:

```yaml
# In inventory/hosts.yml or group_vars/all/vars.yml
proxmox_api_validate_certs: false
```

For production with proper CA-signed certificates:
```yaml
proxmox_api_validate_certs: true
```

### Manual API Testing with curl

Test API connectivity directly without Ansible:

**Token Authentication:**
```bash
PROXMOX_IP="192.168.1.100"
TOKEN_SECRET="your-token-secret"

curl -k "https://${PROXMOX_IP}:8006/api2/json/version" \
  -H "Authorization: PVEAPIToken=ansible-project@pve!project-automation=${TOKEN_SECRET}"
```

**Password Authentication:**
```bash
PROXMOX_IP="192.168.1.100"
USERNAME="ansible-project@pve"
PASSWORD="your-password"

curl -k "https://${PROXMOX_IP}:8006/api2/json/version" \
  -u "${USERNAME}:${PASSWORD}"
```

**Expected Response:**
```json
{
  "data": {
    "release": "8.4",
    "repoid": "4b06efb5db453f29",
    "version": "8.4.1"
  }
}
```

### Verify Ansible Can Decrypt Vault

```bash
# View vault contents
ansible-vault view group_vars/all/vault.yml

# If you get "ERROR! Decryption failed"
# Your vault password is incorrect or vault password file is wrong
```

---

## 8. Security Considerations

### Token Security

✅ **Best Practices:**
- Store tokens only in encrypted Ansible vault
- Use unique tokens per automation system
- Set token expiration dates for production
- Rotate tokens quarterly
- Never commit tokens to git (even encrypted)

❌ **Avoid:**
- Storing tokens in plain text files
- Sharing tokens between systems
- Using tokens in URLs or logs
- Hardcoding tokens in playbooks

### Password Security

✅ **Best Practices:**
- Use strong passwords (16+ characters)
- Store passwords only in encrypted Ansible vault
- Rotate passwords regularly
- Use token authentication instead (when possible)

❌ **Avoid:**
- Storing passwords in plain text
- Using simple/guessable passwords
- Sharing passwords between systems

### Vault Security

✅ **Best Practices:**
```bash
# Vault password file permissions (only you can read)
chmod 600 ~/.vault_pass

# Vault file permissions (group can read if needed)
chmod 640 /opt/project-ansible/group_vars/all/vault.yml

# Backup vault password securely
# Store in password manager, not plain text file
```

❌ **Avoid:**
```bash
# Don't make vault password world-readable
chmod 644 ~/.vault_pass  # WRONG!

# Don't commit vault password to git
git add .vault_pass  # WRONG!
```

### Network Security

For production deployments:

1. **Use proper SSL certificates** (not self-signed)
2. **Restrict API access by IP:**
   ```bash
   # On Proxmox host firewall
   iptables -A INPUT -p tcp --dport 8006 -s 10.0.10.20 -j ACCEPT
   iptables -A INPUT -p tcp --dport 8006 -j DROP
   ```
3. **Use VPN** for remote Ansible server access
4. **Enable two-factor authentication** for Proxmox web UI (doesn't affect API)

### Audit Logging

Monitor API usage:

```bash
# On Proxmox host, view API access logs
tail -f /var/log/pveproxy/access.log

# Filter for ansible-project user
grep "ansible-project" /var/log/pveproxy/access.log
```

---

## 9. Related Files

| File Path | Description |
|-----------|-------------|
| `/opt/project-ansible/group_vars/all/vault.yml` | Encrypted credentials |
| `/opt/project-ansible/group_vars/all/vars.yml` | Unencrypted variables |
| `/opt/project-ansible/inventory/hosts.yml` | Proxmox host IP configuration |
| `/opt/project-ansible/playbooks/test-proxmox-api.yml` | Token auth test playbook |
| `/opt/project-ansible/playbooks/test-proxmox-api-password.yml` | Password auth test playbook |
| `/opt/project-ansible/scripts/first-time-setup-checklist.sh` | Interactive setup wizard |
| `~/.vault_pass` | Vault password file (NOT in git) |

---

## Quick Reference

### Create Token (Web UI Summary)

1. **Datacenter** → **Permissions** → **Users** → **Add**
   - User: `ansible-project@pve`
2. **Datacenter** → **Permissions** → **Roles** → **Create**
   - Role: `ProjectAutomation` (select privileges)
3. **Datacenter** → **Permissions** → **Add User Permission**
   - Path: `/`, User: `ansible-project@pve`, Role: `ProjectAutomation`
4. **Datacenter** → **Permissions** → **API Tokens** → **Add**
   - User: `ansible-project@pve`, Token: `project-automation`, Privilege Sep: **No**
5. **Copy token secret immediately!**

### Test Commands

```bash
# Test API connectivity
cd /opt/project-ansible
ansible-playbook playbooks/test-proxmox-api.yml

# View vault contents
ansible-vault view group_vars/all/vault.yml

# Edit vault
ansible-vault edit group_vars/all/vault.yml

# Manual curl test
curl -k "https://PROXMOX_IP:8006/api2/json/version" \
  -H "Authorization: PVEAPIToken=ansible-project@pve!project-automation=TOKEN_SECRET"
```

---

**Document Status:** Complete and ready for use
**Next Steps:** Once API connectivity is verified, proceed to inventory discovery and resource pool configuration
