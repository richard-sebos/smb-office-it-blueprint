# Temporary IP Allocation - Quick Reference

**Status:** TEMPORARY TESTING CONFIGURATION
**Date:** 2026-01-14
**Network:** 192.168.35.0/24 (Flat network, VLAN 1)

## Device IP Addresses

| Device | Primary IP | Management IP | Ansible Target |
|--------|-----------|---------------|----------------|
| **pve** (Proxmox Host) | 192.168.35.20 | - | 192.168.35.20 |
| **dc01** (Primary DC) | 192.168.35.210 | - | 192.168.35.210 |
| **dc02** (Secondary DC) | 192.168.35.211 | - | 192.168.35.211 |
| **ansible-ctrl** | 192.168.35.220 | 192.168.35.221 | 192.168.35.221 |
| **ws-admin01** | 192.168.35.230 | 192.168.35.231 | 192.168.35.231 |
| **ws-reception01** | 192.168.35.200 | 192.168.35.201 | 192.168.35.201 |

## Network Configuration

- **Gateway:** 192.168.35.1
- **Netmask:** 255.255.255.0 (/24)
- **VLAN:** 1 (default, untagged)
- **DNS Primary:** 8.8.8.8 (Google)
- **DNS Secondary:** 192.168.35.210 (dc01)
- **DNS Tertiary:** 192.168.35.211 (dc02)
- **Domain:** corp.company.local

## IP Range Allocation

- **192.168.35.1** - Gateway/Router
- **192.168.35.20** - Proxmox Host (pve)
- **192.168.35.200-209** - Workstations (primary IPs)
- **192.168.35.210-219** - Servers (DCs, file servers, etc.)
- **192.168.35.220-229** - Infrastructure (Ansible, monitoring, etc.)
- **192.168.35.230-240** - Workstations (primary IPs) / Management IPs
- **192.168.35.241-254** - Reserved for future use

## Ansible Connection Details

All devices connect via management interface where available:

```yaml
dc01:           ansible_host: 192.168.35.210
dc02:           ansible_host: 192.168.35.211
ansible-ctrl:   ansible_host: 192.168.35.221  # mgmt interface
ws-admin01:     ansible_host: 192.168.35.231  # mgmt interface
ws-reception01: ansible_host: 192.168.35.201  # mgmt interface
```

## Quick Test Commands

### Ping all devices
```bash
for ip in 192.168.35.{20,200,201,210,211,220,221,230,231}; do
  echo -n "$ip: "
  ping -c 1 -W 1 $ip > /dev/null && echo "UP" || echo "DOWN"
done
```

### Test Ansible connectivity
```bash
cd /home/richard/Documents/claude/projects/smb-office-it-blueprint/ansible/dev
ansible all -m ping
```

### Check inventory
```bash
ansible-inventory --list -i inventory/hosts.yml
```

## Important Notes

⚠️ **This is a TEMPORARY configuration for testing only**

- Management interfaces kept active (`mgmt_remove_after_config: false`)
- Using Google DNS instead of internal DNS for initial testing
- No VLAN segmentation (all devices on VLAN 1)
- Firewall rules still reference old 10.0.x.x IPs (need updating if testing those features)

📄 **Full documentation:** See `NETWORK-SIMPLIFICATION-TEMP.md` for:
- Complete before/after configuration details
- Revert instructions when ready for production VLANs
- Known limitations and what won't work with this setup

## When to Revert

Revert to production VLAN configuration when:
1. Subnet/VLAN issues are resolved
2. Initial testing is complete
3. Ready to implement proper network segmentation
4. Need to test inter-VLAN routing and firewall rules

See `NETWORK-SIMPLIFICATION-TEMP.md` for detailed revert instructions.

---

**Project:** SMB Office IT Blueprint
**Maintained by:** Richard
**Related Files:**
- `NETWORK-SIMPLIFICATION-TEMP.md` - Full documentation
- `inventory/hosts.yml` - Ansible inventory
- `host_vars/*.yml` - Individual host configurations
