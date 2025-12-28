# Changing VM Template Mappings

**Project:** SMB Office IT Blueprint
**Last Updated:** 2025-12-28
**Purpose:** Guide for updating VM template references when using custom templates

## Overview

VM template mappings are now externalized from the deployment playbook. This allows you to easily change which template IDs are used without modifying playbook code.

## Template Mapping Location

Template mappings are defined in:

```
inventory/group_vars/all.yml
```

This file contains global variables accessible to all Ansible playbooks and hosts.

## Current Template Mappings

**File:** `inventory/group_vars/all.yml`

```yaml
vm_templates:
  ubuntu: 9000    # Ubuntu 22.04 LTS template
  debian: 9100    # Debian 12 template
  rocky: 9200     # Rocky Linux 9 template
```

## How to Change Template IDs

### Step 1: Create New Templates in Proxmox

Create your custom templates in Proxmox with whatever VMID you prefer:

```bash
# Example: Create templates with different VMIDs
# New Ubuntu template at VMID 8000
# New Debian template at VMID 8100
# New Rocky template at VMID 8200
```

### Step 2: Update Template Mappings

Edit the template mapping file:

```bash
cd ~/smb-office-it-blueprint
nano inventory/group_vars/all.yml
```

Update the template VMIDs:

```yaml
vm_templates:
  ubuntu: 8000    # Your new Ubuntu template
  debian: 8100    # Your new Debian template
  rocky: 8200     # Your new Rocky template
```

Save and exit (Ctrl+O, Enter, Ctrl+X).

### Step 3: Verify Changes

Test that Ansible can read the new template mappings:

```bash
# Check that variables are loaded
ansible localhost -m debug -a "var=vm_templates"
```

**Expected output:**
```json
{
    "vm_templates": {
        "debian": 8100,
        "rocky": 8200,
        "ubuntu": 8000
    }
}
```

### Step 4: Run Deployment

Now when you run the deployment playbook, it will use your new template IDs:

```bash
ansible-playbook playbooks/deploy-all-infrastructure.yml
```

## How It Works

### Old Way (Hardcoded)

Previously, template IDs were hardcoded in the playbook:

```yaml
- name: "ansible-ctrl"
  vmid: 110
  template: 9000  # Hardcoded - had to edit playbook to change
```

### New Way (Variable Reference)

Now, template IDs reference variables:

```yaml
- name: "ansible-ctrl"
  vmid: 110
  template: "{{ vm_templates.ubuntu }}"  # References variable
```

The actual VMID comes from `inventory/group_vars/all.yml`.

## Adding New OS Types

You can add additional OS template mappings:

### Step 1: Add to Template Mapping

Edit `inventory/group_vars/all.yml`:

```yaml
vm_templates:
  ubuntu: 9000
  debian: 9100
  rocky: 9200
  centos: 9300    # New CentOS template
  windows: 9400   # New Windows Server template
```

### Step 2: Use in Playbooks

Reference the new template in your VM definitions:

```yaml
- name: "windows-server"
  vmid: 350
  template: "{{ vm_templates.windows }}"
  # ... rest of VM definition
```

## Common Scenarios

### Scenario 1: Using Different Ubuntu Versions

If you have multiple Ubuntu templates:

```yaml
vm_templates:
  ubuntu22: 9000    # Ubuntu 22.04 LTS
  ubuntu24: 9010    # Ubuntu 24.04 LTS
  debian: 9100
  rocky: 9200
```

Then update VM definitions to use specific version:

```yaml
template: "{{ vm_templates.ubuntu24 }}"
```

### Scenario 2: Different Templates for Different Purposes

```yaml
vm_templates:
  ubuntu_server: 9000    # Ubuntu Server minimal
  ubuntu_desktop: 9005   # Ubuntu Desktop
  debian_server: 9100    # Debian minimal
  debian_full: 9105      # Debian with more packages
```

### Scenario 3: Testing vs Production Templates

```yaml
vm_templates:
  # Production templates
  ubuntu: 9000
  debian: 9100

  # Test/development templates
  ubuntu_test: 8000
  debian_test: 8100
```

## Best Practices

### 1. Document Your Templates

Add comments in `inventory/group_vars/all.yml`:

```yaml
vm_templates:
  ubuntu: 9000    # Ubuntu 22.04 LTS - Created 2025-12-28
  debian: 9100    # Debian 12 - Created 2025-12-28
  rocky: 9200     # Rocky Linux 9 - Created 2025-12-28
```

### 2. Use Descriptive Names

If you have multiple templates of the same OS:

```yaml
vm_templates:
  ubuntu_minimal: 9000      # Minimal Ubuntu install
  ubuntu_standard: 9001     # Standard packages
  ubuntu_full: 9002         # Full desktop environment
```

### 3. Keep Template VMIDs Organized

Use a consistent numbering scheme:

```
9000-9099: Ubuntu templates
9100-9199: Debian templates
9200-9299: Rocky/CentOS templates
9300-9399: Windows templates
9400-9499: Other distributions
```

### 4. Version Control Your Changes

After changing template mappings:

```bash
cd ~/smb-office-it-blueprint
git add inventory/group_vars/all.yml
git commit -m "Updated VM template mappings to use new custom templates"
git push
```

## Troubleshooting

### Problem: Template Not Found

**Error:**
```
TASK [Clone VM from template] ****
fatal: [pve]: FAILED! => {"msg": "Template 9000 does not exist"}
```

**Solution:**
1. Check template exists: `qm list | grep 9000`
2. Verify template VMID in `inventory/group_vars/all.yml`
3. Make sure VMID matches actual template

### Problem: Wrong Template Used

**Issue:** VM created from wrong template

**Solution:**
1. Check which template variable is referenced in playbook
2. Verify `vm_templates` mapping in `inventory/group_vars/all.yml`
3. Ensure no typos in variable names

### Problem: Variables Not Loading

**Error:**
```
The task includes an option with an undefined variable
```

**Solution:**
1. Verify file location: `inventory/group_vars/all.yml`
2. Check YAML syntax: `yamllint inventory/group_vars/all.yml`
3. Ensure ansible.cfg points to correct inventory

## Quick Reference

**View current template mappings:**
```bash
ansible localhost -m debug -a "var=vm_templates"
```

**Edit template mappings:**
```bash
nano inventory/group_vars/all.yml
```

**Check which template a VM will use:**
```bash
ansible-playbook playbooks/deploy-all-infrastructure.yml --list-tasks | grep template
```

**Verify template exists in Proxmox:**
```bash
ssh root@192.168.35.20 "qm list | grep -E '9000|9100|9200'"
```

## Files Modified

The template mapping system affects these files:

1. **inventory/group_vars/all.yml** - Template ID definitions
2. **playbooks/deploy-all-infrastructure.yml** - Uses template variables

No other files need modification when changing template IDs.

---

**Status:** Template mapping system externalized and documented
**Benefit:** Change template IDs without modifying playbook code

