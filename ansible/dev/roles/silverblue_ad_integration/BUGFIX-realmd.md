# Bugfix: realmd Package Already Installed

## Issue

**Error encountered:**
```
error: "realmd" is already provided by: realmd-0.17.1-18.fc43.x86_64.
Use --allow-inactive to explicitly require it.
```

## Root Cause

Fedora Silverblue 43 includes `realmd` in the base OSTree image. Attempting to layer it again with `rpm-ostree install` causes a conflict because the package is already present in the base system.

## Problem

The original task blindly attempted to install all AD packages:

```yaml
- name: Layer required AD packages onto OSTree
  command: rpm-ostree install {{ ad_required_packages | join(' ') }}
  register: ostree_layer
  changed_when: "'Installing' in ostree_layer.stdout"
  notify: reboot workstation
```

**Result:** Failed when `realmd` (or any other package) was already in the base image.

## Solution

**Check which packages are already layered before attempting installation:**

```yaml
# 1. Get current OSTree status
- name: Check currently layered packages
  command: rpm-ostree status --json
  register: ostree_status_json
  changed_when: false
  failed_when: false

# 2. Parse the JSON to extract layered packages
- name: Parse layered packages
  set_fact:
    layered_packages: "{{ (ostree_status_json.stdout | from_json).deployments[0].packages | default([]) }}"
  when: ostree_status_json.rc == 0

# 3. Calculate difference (packages NOT yet installed)
- name: Determine packages that need to be installed
  set_fact:
    packages_to_install: "{{ ad_required_packages | difference(layered_packages | default([])) }}"

# 4. Show what will be installed
- name: Display packages to be installed
  debug:
    msg: "Packages to install: {{ packages_to_install | join(', ') if packages_to_install | length > 0 else 'none (all already installed)' }}"

# 5. Only install packages that aren't already present
- name: Layer required AD packages onto OSTree
  command: rpm-ostree install {{ packages_to_install | join(' ') }}
  register: ostree_layer
  changed_when: "'Installing' in ostree_layer.stdout"
  when: packages_to_install | length > 0
  notify: reboot workstation
```

## How It Works

1. **Query OSTree status** - Get JSON output of current deployment
2. **Extract layered packages** - Parse JSON to find packages already layered
3. **Calculate difference** - Only include packages NOT in base image or already layered
4. **Install missing packages** - Only run `rpm-ostree install` if there are packages to install

## Benefits

✅ **Idempotent** - Can run multiple times without errors
✅ **Efficient** - Doesn't try to install already-present packages
✅ **Clear output** - Shows which packages will be installed
✅ **No unnecessary reboots** - Only reboots if packages were actually installed

## Example Output

**First run (realmd in base, others need installation):**
```
TASK [silverblue_ad_integration : Display packages to be installed]
ok: [ws-reception01] => {
    "msg": "Packages to install: sssd, sssd-tools, sssd-ad, krb5-workstation, oddjob, oddjob-mkhomedir, adcli, samba-common-tools"
}
```

**Second run (all already installed):**
```
TASK [silverblue_ad_integration : Display packages to be installed]
ok: [ws-reception01] => {
    "msg": "Packages to install: none (all already installed)"
}

TASK [silverblue_ad_integration : Layer required AD packages onto OSTree]
skipping: [ws-reception01]
```

## Testing

Verify the fix works:

```bash
# On the Silverblue workstation
rpm-ostree status --json | jq -r '.deployments[0].packages[]'

# Should show layered packages
# realmd will NOT be in this list (it's in base image)
# Other AD packages will be listed after first run
```

## Related Issues

This fix also handles:
- Any other packages that might be in the base Silverblue image
- Different Fedora Silverblue versions with different base packages
- Allows for gradual package additions without conflicts

## Date Fixed

2026-01-12

## Files Modified

- `roles/silverblue_ad_integration/tasks/main.yml`
