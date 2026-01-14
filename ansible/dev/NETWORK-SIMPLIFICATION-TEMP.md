# Temporary Network Configuration Simplification

## Status: TEMPORARY CONFIGURATION FOR TESTING

This document tracks the temporary network simplification made to resolve subnet issues during initial deployment testing.

## Date: 2026-01-14

## Changes Made

### ws-reception01 Network Configuration

**Original VLAN Configuration:**
```yaml
network:
  ip_address: 10.0.130.25        # Workstation VLAN 130
  netmask: 24
  gateway: 10.0.130.1
  vlan: 130
  dns_servers:
    - 10.0.120.10                # dc01.corp.company.local
    - 10.0.120.11                # dc02.corp.company.local
  mgmt_interface: ens19
  mgmt_ip: 192.168.35.135        # Old management IP
  mgmt_remove_after_config: true
```

**Temporary Simplified Configuration:**
```yaml
network:
  ip_address: 192.168.35.200     # Flat network for testing
  netmask: 24
  gateway: 192.168.35.1
  vlan: 1                        # Default VLAN
  dns_servers:
    - 8.8.8.8                    # Google DNS for testing
    - 8.8.4.4                    # Google DNS secondary
  mgmt_interface: ens19
  mgmt_ip: 192.168.35.201        # New management IP
  mgmt_remove_after_config: false  # Keep for testing
```

### Inventory File Changes

**File:** `inventory/hosts.yml`

```yaml
# Before:
ws-reception01:
  ansible_host: 192.168.35.135
  vm_role: admin_workstation

# After:
ws-reception01:
  ansible_host: 192.168.35.201  # Management interface for Ansible
  vm_role: receptionist_workstation
```

## IP Address Allocation (Testing Range)

Allocated from: **192.168.35.200 - 192.168.35.240**

| IP Address | Hostname | Purpose |
|------------|----------|---------|
| 192.168.35.200 | ws-reception01 | Primary IP (ens18) |
| 192.168.35.201 | ws-reception01 | Management interface (ens19) for Ansible |
| 192.168.35.202-240 | - | Reserved for additional workstations/testing |

## Files Modified

1. **`host_vars/ws-reception01.yml`** - Network configuration
2. **`inventory/hosts.yml`** - Ansible connection IP

## Known Limitations with Temporary Configuration

⚠️ **Security considerations:**
- Using Google DNS instead of internal domain controllers
- Flat network without VLAN isolation
- Management interface remains active (normally removed after deployment)

⚠️ **Active Directory integration:**
- DNS may need to be changed to domain controllers for AD join to work
- Kerberos requires proper DNS resolution to domain controllers

⚠️ **Firewall rules:**
- Firewall whitelist still references old 10.0.x.x addresses in `host_vars/ws-reception01.yml`
- May need to update `firewall.allowed_destinations` for testing

## Firewall Destinations Still Using Old IPs

**In `host_vars/ws-reception01.yml` lines 276-284:**
```yaml
allowed_destinations:
  - 10.0.120.10  # dc01 - OLD
  - 10.0.120.11  # dc02 - OLD
  - 10.0.120.50  # files01 - OLD
  - 10.0.120.60  # monitoring01 - OLD
  - 10.0.140.55  # HP-Reception-Printer - OLD
  - 10.0.140.56  # HP-Reception-Fax - OLD
```

**These may need updating if testing requires access to these services.**

## Logging Configuration Still Using Old IPs

**In `host_vars/ws-reception01.yml` lines 210-212:**
```yaml
rsyslog:
  enabled: true
  target: 10.0.120.60  # monitoring01 - OLD IP
  protocol: tcp
  port: 514
```

**This will need updating if you want logs forwarded during testing.**

## Printer Configuration Still Using Old IPs

**In `host_vars/ws-reception01.yml` lines 161-177:**
```yaml
printers:
  - name: HP-Reception-Printer
    ip: 10.0.140.55  # OLD IP
  - name: HP-Reception-Fax
    ip: 10.0.140.56  # OLD IP
```

**These will need updating if you want to test printing.**

## File Share Configuration Still Using Old IPs

**In `host_vars/ws-reception01.yml` lines 189-194:**
```yaml
home_directory:
  server: files01.corp.company.local  # May not resolve with Google DNS

shared_folders:
  - server: files01.corp.company.local  # May not resolve with Google DNS
```

**These may not resolve properly with Google DNS instead of internal DNS.**

## Reverting to Production VLAN Configuration

When testing is complete and subnet issues are resolved, revert by:

1. **Restore original IPs in `host_vars/ws-reception01.yml`:**
   - Change `ip_address: 192.168.35.200` back to `10.0.130.25`
   - Change `gateway: 192.168.35.1` back to `10.0.130.1`
   - Change `vlan: 1` back to `130`
   - Change DNS servers back to domain controllers
   - Change management IP back to `192.168.35.135`
   - Set `mgmt_remove_after_config: true`

2. **Update inventory file `inventory/hosts.yml`:**
   - Change `ansible_host: 192.168.35.201` back to `192.168.35.135`

3. **Test AD integration** with proper domain controller DNS

4. **Verify VLAN tagging** on Proxmox switch configuration

5. **Test connectivity** to all services (DC, file server, monitoring, printers)

## Documentation Files with Old IPs (Not Updated)

The following documentation files still reference the original VLAN subnet design:
- `docs/Receptionist-Workstation-Security-Flow.md`
- `playbooks/README-ws-reception01.md`
- `playbooks/README-ws-reception01-playbooks.md`
- `docs/Receptionist-Workstation-Deployment-Guide.md`
- Various other security flow documents

**These are intentionally not updated** as they document the production design. This temporary configuration is only for troubleshooting.

## Next Steps After Testing

Once the simplified network configuration is working:
1. Identify root cause of original subnet issues
2. Plan proper VLAN implementation
3. Revert to production network design
4. Update firewall rules for proper segmentation
5. Test all services with production IPs

---

**Maintained by:** Richard
**Project:** SMB Office IT Blueprint
**Purpose:** Track temporary network simplification for debugging
**Status:** Active - Revert after testing complete
