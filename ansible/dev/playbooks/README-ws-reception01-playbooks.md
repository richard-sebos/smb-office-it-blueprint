# ws-reception01 Playbook Structure

## Overview

The receptionist workstation deployment has been split into **two separate playbooks** for better modularity and flexibility:

1. **`deploy-ws-reception01.yml`** - VM deployment only (clone from template)
2. **`configure-ws-reception01.yml`** - System configuration (AD, security, apps)

## Playbook Files

### 1. `deploy-ws-reception01.yml`
**Purpose:** Clone VM from Fedora Silverblue template on Proxmox

**What it does:**
- Loads host variables from `host_vars/ws-reception01.yml`
- Calls `proxmox_vm_deploy` role
- Creates VM with specified VMID, network, and resources
- Does NOT configure the system

**Usage:**
```bash
ansible-playbook playbooks/deploy-ws-reception01.yml
```

**Time:** ~2 minutes

---

### 2. `configure-ws-reception01.yml`
**Purpose:** Configure the workstation with all security features

**What it does:**
- **Base System** - Network, hostname, system updates
- **Security Features** - AD integration, PAM access control, printers, nightly reset
- **Desktop Environment** - GNOME settings, idle timeout, browser bookmarks
- **Firewall** - Whitelist rules for approved services and destinations
- **Finalization** - Remove management interface, create verification script

**Prerequisites:**
- VM must already be deployed (via `deploy-ws-reception01.yml`)
- VM must be booted and accessible via SSH

**Usage:**
```bash
ansible-playbook playbooks/configure-ws-reception01.yml
```

**Time:** ~15-20 minutes (includes potential reboots for rpm-ostree layering)

---

### 3. `deploy-and-configure-ws-reception01.yml` (Convenience Wrapper)
**Purpose:** Run both playbooks in sequence

**What it does:**
1. Runs `deploy-ws-reception01.yml` (clone VM)
2. Waits 60 seconds for VM to boot
3. Runs `configure-ws-reception01.yml` (configure system)

**Usage:**
```bash
ansible-playbook playbooks/deploy-and-configure-ws-reception01.yml
```

**Time:** ~18-22 minutes total

---

## When to Use Which Playbook

### Use `deploy-ws-reception01.yml` when:
- Creating a new VM from scratch
- Rebuilding a destroyed VM
- Testing VM deployment without configuration
- You want to manually configure the system later

### Use `configure-ws-reception01.yml` when:
- VM already exists and is running
- Re-configuring an existing workstation
- Testing configuration changes without redeploying VM
- Updating security settings or roles
- Fixing configuration issues

### Use `deploy-and-configure-ws-reception01.yml` when:
- You want a fully automated end-to-end deployment
- Starting from scratch and want everything configured
- First-time deployment

---

## Workflow Examples

### Example 1: First-Time Deployment (Full Automation)
```bash
# Deploy and configure in one command
ansible-playbook playbooks/deploy-and-configure-ws-reception01.yml
```

### Example 2: Separate Steps (More Control)
```bash
# Step 1: Deploy VM
ansible-playbook playbooks/deploy-ws-reception01.yml

# Step 2: Start VM on Proxmox
ssh root@pve "qm start 320"

# Step 3: Wait for boot
sleep 60

# Step 4: Configure system
ansible-playbook playbooks/configure-ws-reception01.yml
```

### Example 3: Reconfigure Existing VM
```bash
# VM already exists, just reconfigure
ansible-playbook playbooks/configure-ws-reception01.yml
```

### Example 4: Rebuild VM from Scratch
```bash
# Destroy existing VM
ssh root@pve "qm stop 320 && qm destroy 320"

# Deploy new VM
ansible-playbook playbooks/deploy-ws-reception01.yml

# Start and configure
ssh root@pve "qm start 320"
sleep 60
ansible-playbook playbooks/configure-ws-reception01.yml
```

### Example 5: Test Configuration Changes
```bash
# Make changes to host_vars/ws-reception01.yml or roles
# Then re-run configuration only (no VM rebuild needed)
ansible-playbook playbooks/configure-ws-reception01.yml
```

---

## Benefits of Split Playbooks

### ✅ Modularity
- Deploy and configure separately
- Easier to test individual components
- Reuse deployment logic for other workstation types

### ✅ Flexibility
- Reconfigure without rebuilding VM
- Test configuration changes quickly
- Deploy multiple VMs, configure later

### ✅ Faster Iteration
- Configuration changes don't require VM rebuild (~15 min vs ~20 min)
- Can run configuration multiple times on same VM
- Easier debugging (isolate deployment vs configuration issues)

### ✅ Better Error Handling
- If deployment fails, fix and retry just deployment
- If configuration fails, fix and retry just configuration
- Don't have to start from scratch on failures

### ✅ Reusability
- `deploy-ws-reception01.yml` pattern can be reused for:
  - Finance workstation (ws-finance01)
  - HR workstation (ws-hr01)
  - Executive workstation (ws-exec01)
- Just change target_host variable

---

## Configuration Sections

The `configure-ws-reception01.yml` playbook is organized into **5 plays**:

### Play 1: Base System
**Roles:**
- `network_config` - Configure static IP, VLAN, DNS
- `hostname_config` - Set hostname and FQDN
- `system_update` - Update system packages

### Play 2: Silverblue Security Features
**Roles:**
- `silverblue_ad_integration` - SSSD + Kerberos for AD auth
- `silverblue_pam_access` - PAM access control (group restrictions)
- `silverblue_printer_config` - Configure network printers
- `silverblue_nightly_reset` - Automated 2 AM reset script

**Post-tasks:**
- Configure rsyslog for remote logging
- Configure auditd rules for security auditing

### Play 3: Desktop Environment
**Tasks:**
- Configure GNOME idle timeout (3 minutes)
- Configure GNOME screen lock
- Configure GNOME suspend lock
- Create Firefox browser bookmarks

### Play 4: Firewall Rules
**Tasks:**
- Install firewalld (if not already installed)
- Set default zone to workstation
- Allow SSH from management network
- Allow required services (DNS, LDAP, Kerberos, HTTP, IPP, etc.)
- Allow required ports
- Create rich rules for whitelisted destinations

### Play 5: Finalization
**Tasks:**
- Remove temporary management interface
- Create verification script (`/usr/local/bin/verify-workstation.sh`)
- Display final deployment summary

---

## Error Handling

Both playbooks include comprehensive error handling:

- **`any_errors_fatal: false`** on all plays (don't stop on first error)
- **`ignore_errors: yes`** on all tasks (continue even if task fails)
- Ansible will log failures but continue execution
- Final summary shows what succeeded and what failed

This allows:
- ✅ Partial deployments (some features work, some don't)
- ✅ Complete visibility into what failed
- ✅ No need to restart from scratch on single failure
- ✅ Easier troubleshooting (see all errors at once)

---

## Verification

After running `configure-ws-reception01.yml`, verify the deployment:

```bash
# SSH to workstation
ssh ansible-admin@10.0.130.25

# Run verification script
sudo /usr/local/bin/verify-workstation.sh
```

**Expected output:**
```
=========================================
Workstation Verification Script
Hostname: ws-reception01
=========================================

Network Configuration:
inet 10.0.130.25/24 brd 10.0.130.255 scope global ens18

AD Integration:
corp.company.local
  configured: kerberos-member
  server-software: active-directory
  client-software: sssd

SSSD Status:
● sssd.service - System Security Services Daemon
   Active: active (running)

Printer Status:
printer HP-Reception-Printer is idle.  enabled since [date]
system default destination: HP-Reception-Printer

Nightly Reset Timer:
● workstation-nightly-reset.timer
   Active: active (waiting)
   Trigger: *-*-* 02:00:00

OSTree Status:
● fedora:fedora/41/x86_64/silverblue
                  Version: 41.20260110.0 (2026-01-10)
```

---

## Troubleshooting

### VM deployment fails
```bash
# Check Proxmox API connectivity
ansible pve -m ping

# Check template exists
ssh root@pve "qm list | grep 9350"

# Run deployment again
ansible-playbook playbooks/deploy-ws-reception01.yml
```

### Configuration fails
```bash
# Check VM is accessible
ansible ws-reception01 -m ping

# Check specific role that failed
ansible-playbook playbooks/configure-ws-reception01.yml --tags network_config

# Re-run configuration
ansible-playbook playbooks/configure-ws-reception01.yml
```

### Can't connect to VM
```bash
# Check VM is running
ssh root@pve "qm status 320"

# Start VM if stopped
ssh root@pve "qm start 320"

# Wait for boot
sleep 60

# Try connection again
ansible ws-reception01 -m ping
```

---

## Next Steps

### Create additional workstation playbooks:

**Finance Workstation:**
```bash
cp playbooks/deploy-ws-reception01.yml playbooks/deploy-ws-finance01.yml
cp playbooks/configure-ws-reception01.yml playbooks/configure-ws-finance01.yml
# Edit to change target_host from ws-reception01 to ws-finance01
```

**HR Workstation:**
```bash
cp playbooks/deploy-ws-reception01.yml playbooks/deploy-ws-hr01.yml
cp playbooks/configure-ws-reception01.yml playbooks/configure-ws-hr01.yml
# Edit to change target_host from ws-reception01 to ws-hr01
```

### Create generic deployment playbook:
```bash
# Use variable for target_host
ansible-playbook playbooks/deploy-workstation.yml -e target_host=ws-reception01
ansible-playbook playbooks/configure-workstation.yml -e target_host=ws-reception01
```

---

## File Structure

```
playbooks/
├── deploy-ws-reception01.yml                      # VM deployment only
├── configure-ws-reception01.yml                   # System configuration only
├── deploy-and-configure-ws-reception01.yml        # Combined (wrapper)
├── deploy-and-configure-ws-reception01.yml.backup # Old monolithic version
└── README-ws-reception01-playbooks.md             # This file
```

---

**Last Updated:** 2026-01-11
**Author:** Richard
**Project:** SMB Office IT Blueprint
