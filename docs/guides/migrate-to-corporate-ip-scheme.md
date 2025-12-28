# Migration Guide: 192.168.x.x to 10.0.x.x Corporate IP Scheme

**Project:** SMB Office IT Blueprint
**Last Updated:** 2025-12-28
**Estimated Time:** 30-45 minutes
**Difficulty:** Intermediate

## Overview

This guide walks you through the complete migration from the test 192.168.x.x addressing to the enterprise 10.0.x.x corporate addressing scheme.

## Migration Summary

**What's Changing:**
- Proxmox VLAN IPs: 192.168.10.1 → 10.0.10.2, 192.168.20.1 → 10.0.20.2
- OPNsense VLAN IPs: All VLANs move to 10.0.x.1
- All DHCP scopes updated to 10.0.x.x ranges
- Firewall rules and NAT rules updated

**What's NOT Changing:**
- Lab network (vmbr0): Still 192.168.35.0/24
- VLAN tags: Still 10, 20, 30, 40, 50
- Network topology: Same structure, just new IPs

## Pre-Migration Checklist

Before starting, ensure:

- [ ] No critical VMs running (or plan for brief downtime)
- [ ] Console access to Proxmox host available
- [ ] Console access to OPNsense VM available
- [ ] You can SSH to Proxmox: `ssh root@192.168.35.20`
- [ ] Ansible environment configured and tested
- [ ] OPNsense web UI accessible via WAN IP
- [ ] You have backups of both Proxmox and OPNsense configs

## Migration Steps

### Phase 1: Preparation (5 minutes)

#### Step 1: Verify Current State

```bash
# On your workstation
cd ~/Documents/claude/projects/smb-office-it-blueprint

# Verify Ansible connectivity
ansible pve -m ping

# Check current Proxmox VLAN IPs
ssh root@192.168.35.20 "ip addr show | grep 'vmbr1\\.'"
```

**Expected output:**
```
inet 192.168.10.1/24 brd 192.168.10.255 scope global vmbr1.10
inet 192.168.20.1/24 brd 192.168.20.255 scope global vmbr1.20
```

#### Step 2: Access OPNsense Web UI

```
https://192.168.35.XXX
```

Note the WAN IP address (you'll need this throughout the migration).

Verify current LAN IP:

Navigate: **Interfaces → Overview**
- LAN should show: 192.168.10.254/24

#### Step 3: Review Migration Plan

Review these documents:
- `docs/network/corporate-ip-addressing-scheme.md` - New IP scheme
- `playbooks/update-network-to-corporate-ips.yml` - Proxmox update playbook
- `docs/guides/reconfigure-opnsense-corporate-ips.md` - OPNsense reconfiguration

### Phase 2: Backup Everything (5 minutes)

#### Step 4: Backup OPNsense Configuration

**Via Web UI:**
1. Navigate: **System → Configuration → Backups**
2. Click **Download configuration**
3. Save as: `opnsense-config-before-migration-$(date +%Y%m%d).xml`

**Via Console (Optional):**
```bash
ssh root@192.168.35.20
qm terminal 100
# Login as root
# Option 8 (Shell)
cd /conf
cp config.xml config.xml.before-migration-$(date +%Y%m%d)
exit
# Ctrl+O to exit console
```

#### Step 5: Backup Proxmox Network Config

```bash
# On Proxmox host
ssh root@192.168.35.20

# Manual backup
cp /etc/network/interfaces /etc/network/interfaces.before-migration-$(date +%Y%m%d)

# Verify backup
ls -lh /etc/network/interfaces*
```

The Ansible playbook will also create a backup automatically.

### Phase 3: Update Proxmox Network (10 minutes)

#### Step 6: Run Ansible Playbook (Dry Run)

```bash
# On your workstation
cd ~/Documents/claude/projects/smb-office-it-blueprint

# Dry run first to see what will change
ansible-playbook playbooks/update-network-to-corporate-ips.yml --check
```

Review the output carefully. It should show:
- Backup will be created
- VLAN 10 IP will change to 10.0.10.2
- VLAN 20 IP will change to 10.0.20.2

#### Step 7: Execute Ansible Playbook

```bash
# Execute the playbook
ansible-playbook playbooks/update-network-to-corporate-ips.yml
```

**Expected output:**
```
TASK [Display migration information]
...
TASK [Create backup directory]
...
TASK [Backup current network configuration]
...
TASK [Update VLAN 10 IP address]
changed: [pve]
...
TASK [Update VLAN 20 IP address]
changed: [pve]
...
PLAY RECAP
pve: ok=X changed=Y
```

#### Step 8: Apply Network Changes on Proxmox

```bash
# SSH to Proxmox
ssh root@192.168.35.20

# Review the updated configuration
cat /etc/network/interfaces | grep -A 6 "VLAN 10"
cat /etc/network/interfaces | grep -A 6 "VLAN 20"

# Apply the new network configuration
ifreload -a

# Verify new IPs are active
ip addr show vmbr1.10
ip addr show vmbr1.20
```

**Expected output:**
```
vmbr1.10: inet 10.0.10.2/24
vmbr1.20: inet 10.0.20.2/24
```

#### Step 9: Test Connectivity (Partial)

```bash
# Still on Proxmox host

# These will FAIL (OPNsense not updated yet)
ping -c 2 10.0.10.1
ping -c 2 10.0.20.1

# This should SUCCEED (old OPNsense IP)
ping -c 2 192.168.10.254

# Lab network should still work
ping -c 2 192.168.35.1
ping -c 2 8.8.8.8
```

### Phase 4: Update OPNsense (15-20 minutes)

#### Step 10: Update LAN Interface via Console

```bash
# On Proxmox host
qm terminal 100
```

**Login as root**

**At the console menu:**

**Select:** `2` (Set interface IP address)

**Select:** `2` (LAN - might be labeled as vtnet1)

Answer the prompts:

```
Configure IPv4 address LAN interface via DHCP? n
Enter the new LAN IPv4 address: 10.0.10.1
Enter the new LAN IPv4 subnet bit count: 24
Gateway: (press Enter for none)
Configure IPv6: n
Enable DHCP server on LAN? y
Start address: 10.0.10.100
End address: 10.0.10.200
Revert to HTTP? n
```

**Wait 5-10 seconds** for interface to reconfigure.

Console should now show:
```
LAN (lan) -> vtnet1 -> v4: 10.0.10.1/24
```

**Exit console:** Press `Ctrl+O`

#### Step 11: Test Connectivity from Proxmox

```bash
# On Proxmox host

# These should now SUCCEED
ping -c 3 10.0.10.1
ping -c 3 10.0.10.2

# Old IPs should FAIL
ping -c 2 192.168.10.254 || echo "Expected - old IP no longer exists"

# Lab network still works
ping -c 3 8.8.8.8
```

#### Step 12: Update Remaining VLANs via Web UI

**Access OPNsense Web UI:**

```
https://192.168.35.XXX
```

**Note:** You can no longer access via `https://192.168.10.254` - it's now `https://10.0.10.1` (but only from Proxmox or VMs on VLAN 10).

**Update VLAN 20 (Servers):**

Navigate: **Interfaces → Assignments** → **VLAN20_Servers**

```
IPv4 address: 10.0.20.1 / 24
```

Click **Save** → **Apply changes**

**Update VLAN 30 (Workstations):**

Navigate: **Interfaces → Assignments** → **VLAN30_Workstations**

```
IPv4 address: 10.0.30.1 / 24
```

Click **Save** → **Apply changes**

**Update VLAN 40 (Guest):**

Navigate: **Interfaces → Assignments** → **VLAN40_Guest**

```
IPv4 address: 10.0.40.1 / 24
```

Click **Save** → **Apply changes**

**Update VLAN 50 (DMZ):**

Navigate: **Interfaces → Assignments** → **VLAN50_DMZ**

```
IPv4 address: 10.0.50.1 / 24
```

Click **Save** → **Apply changes**

#### Step 13: Update DHCP Scopes

For each VLAN, update the DHCP scope:

Navigate: **Services → DHCPv4 → [Interface]**

**VLAN20_Servers:**
```
Range from: 10.0.20.100
Range to: 10.0.20.200
DNS servers: 10.0.20.1
```
Click **Save**

**VLAN30_Workstations:**
```
Range from: 10.0.30.100
Range to: 10.0.30.254
DNS servers: 10.0.20.10, 10.0.20.11
```
Click **Save**

**VLAN40_Guest:**
```
Range from: 10.0.40.100
Range to: 10.0.40.254
DNS servers: 10.0.40.1
```
Click **Save**

**VLAN50_DMZ:**
```
Range from: 10.0.50.100
Range to: 10.0.50.200
DNS servers: 8.8.8.8, 8.8.4.4
```
Click **Save**

#### Step 14: Update Firewall Rules (If Needed)

Navigate: **Firewall → Rules → LAN**

Check if any rules have hardcoded 192.168.x.x IPs. If they use "LAN net", "VLAN20_Servers net", etc., they should auto-update.

If you find hardcoded IPs, edit those rules and update to 10.0.x.x

**Repeat for:** VLAN20_Servers, VLAN30_Workstations, VLAN40_Guest, VLAN50_DMZ

#### Step 15: Verify NAT Rules

Navigate: **Firewall → NAT → Outbound**

If using **Automatic outbound NAT** (recommended): Rules should auto-update.

If using **Manual NAT**: Update each rule's source network from 192.168.x.x to 10.0.x.x

#### Step 16: Update DNS Forwarder

Navigate: **Services → Unbound DNS → General**

Verify listening interfaces:

```
Network Interfaces:
  ☑ LAN (10.0.10.1)
  ☑ VLAN20_Servers (10.0.20.1)
  ☑ VLAN30_Workstations (10.0.30.1)
  ☑ VLAN40_Guest (10.0.40.1)
  ☑ VLAN50_DMZ (10.0.50.1)
```

Click **Save** → **Apply**

### Phase 5: Verification (5 minutes)

#### Step 17: Verify OPNsense Interfaces

Navigate: **Interfaces → Overview**

All interfaces should show "up":

```
WAN: 192.168.35.XXX/24 (up)
LAN: 10.0.10.1/24 (up)
VLAN20_Servers: 10.0.20.1/24 (up)
VLAN30_Workstations: 10.0.30.1/24 (up)
VLAN40_Guest: 10.0.40.1/24 (up)
VLAN50_DMZ: 10.0.50.1/24 (up)
```

#### Step 18: Test from Proxmox Host

```bash
# On Proxmox host
ssh root@192.168.35.20

# Ping all OPNsense VLAN gateways
for vlan in 10 20 30 40 50; do
    echo "Testing VLAN $vlan..."
    ping -c 2 10.0.${vlan}.1
done

# Test DNS resolution
nslookup google.com 10.0.10.1

# Test internet connectivity (through NAT)
ping -c 3 8.8.8.8
```

All tests should succeed.

#### Step 19: Verify Routing

```bash
# On Proxmox host

# Check routing table
ip route | grep 10.0

# Should see routes like:
# 10.0.10.0/24 dev vmbr1.10 proto kernel scope link src 10.0.10.2
# 10.0.20.0/24 dev vmbr1.20 proto kernel scope link src 10.0.20.2
```

#### Step 20: Final OPNsense Backup

Download a fresh backup with the new configuration:

Navigate: **System → Configuration → Backups**

Click **Download configuration**

Save as: `opnsense-config-after-migration-$(date +%Y%m%d).xml`

### Phase 6: Documentation Update (5 minutes)

#### Step 21: Update Project Documentation

Search for references to old IPs:

```bash
cd ~/Documents/claude/projects/smb-office-it-blueprint

# Find files that might reference old IPs
grep -r "192.168.10\." docs/ --exclude-dir=backups | grep -v migration | grep -v backup
grep -r "192.168.20\." docs/ --exclude-dir=backups | grep -v migration | grep -v backup
```

Update any found files with new IPs.

**Key files to check:**
- `docs/network/network-architecture.md`
- Any VM deployment scripts
- Monitoring configurations

#### Step 22: Create Migration Summary

Create a summary file:

```bash
cat > ~/Documents/claude/projects/smb-office-it-blueprint/MIGRATION-COMPLETED.txt << EOF
Network Migration to Corporate IP Scheme
Completed: $(date)

Old Scheme: 192.168.x.x
New Scheme: 10.0.x.x

Changes:
- Proxmox vmbr1.10: 192.168.10.1 → 10.0.10.2
- Proxmox vmbr1.20: 192.168.20.1 → 10.0.20.2
- OPNsense LAN: 192.168.10.254 → 10.0.10.1
- OPNsense VLAN20: 192.168.20.254 → 10.0.20.1
- OPNsense VLAN30: 192.168.30.254 → 10.0.30.1
- OPNsense VLAN40: 192.168.40.254 → 10.0.40.1
- OPNsense VLAN50: 192.168.50.254 → 10.0.50.1

Backups:
- Proxmox: /etc/network/interfaces.before-migration-*
- OPNsense: opnsense-config-before-migration-*.xml

Status: ✓ SUCCESSFUL
EOF

cat ~/Documents/claude/projects/smb-office-it-blueprint/MIGRATION-COMPLETED.txt
```

## Post-Migration Checklist

Verify:

- [x] Proxmox vmbr1.10 has IP 10.0.10.2/24
- [x] Proxmox vmbr1.20 has IP 10.0.20.2/24
- [x] OPNsense LAN has IP 10.0.10.1/24
- [x] All 5 OPNsense VLANs have new 10.0.x.1 IPs
- [x] All DHCP scopes updated to 10.0.x.x ranges
- [x] Firewall rules reviewed/updated
- [x] NAT rules functional
- [x] DNS forwarder listening on new IPs
- [x] Can ping all VLAN gateways from Proxmox
- [x] Internet connectivity works through NAT
- [x] Configuration backups saved (before and after)
- [x] Documentation updated

## Rollback Procedure

If something goes wrong, you can rollback:

### Rollback Proxmox

```bash
# On your workstation
cd ~/Documents/claude/projects/smb-office-it-blueprint

# Find the restore script
ls -lt backups/network/restore-network-*.sh | head -1

# Run the restore script
bash backups/network/restore-network-<timestamp>.sh
```

### Rollback OPNsense

**Via Web UI:**

1. Access: `https://192.168.35.XXX` (WAN IP - unchanged)
2. Navigate: **System → Configuration → Backups**
3. Click **Browse**
4. Select: `opnsense-config-before-migration-*.xml`
5. Click **Restore configuration**
6. Reboot OPNsense: **Power → Reboot**

**Via Console:**

```bash
qm terminal 100
# Login as root
# Option 8 (Shell)
cd /conf
cp config.xml config.xml.broken
cp config.xml.before-migration-* config.xml
/usr/local/etc/rc.reload_all
```

## Troubleshooting

### Lost OPNsense web UI access

**Solution:** Access via WAN IP: `https://192.168.35.XXX`

### Cannot ping new IPs from Proxmox

**Check:**
```bash
# Verify IPs are assigned
ip addr show vmbr1.10
ip addr show vmbr1.20

# Reload network if needed
ifreload -a
```

### OPNsense interfaces down

**Check:**

Navigate: **Interfaces → Overview**

If any interface is down, click on it and ensure "Enable interface" is checked.

### VMs not getting DHCP

This is expected - no VMs have been deployed yet. After deploying VMs, they should get IPs from the new DHCP ranges.

## Next Steps

Now that your network is on the corporate IP scheme:

1. **Deploy infrastructure VMs** - Create VMs from templates
2. **Assign static IPs** - Configure infrastructure VMs with static IPs
3. **Configure DNS** - Set up internal DNS on domain controllers
4. **Deploy monitoring** - Set up monitoring for new network ranges
5. **Test inter-VLAN routing** - Deploy VMs on multiple VLANs and test connectivity

## Summary

You have successfully migrated from the test 192.168.x.x addressing to the enterprise 10.0.x.x corporate addressing scheme!

**Network Summary:**

| VLAN | Network | Gateway | Proxmox IP | Purpose |
|------|---------|---------|------------|---------|
| 10 | 10.0.10.0/24 | 10.0.10.1 | 10.0.10.2 | Management |
| 20 | 10.0.20.0/24 | 10.0.20.1 | 10.0.20.2 | Servers |
| 30 | 10.0.30.0/24 | 10.0.30.1 | - | Workstations |
| 40 | 10.0.40.0/24 | 10.0.40.1 | - | Guest/IoT |
| 50 | 10.0.50.0/24 | 10.0.50.1 | - | DMZ |

**Lab Network:** 192.168.35.0/24 (unchanged)

---

**Migration Complete!** You're now ready to deploy your corporate infrastructure.
