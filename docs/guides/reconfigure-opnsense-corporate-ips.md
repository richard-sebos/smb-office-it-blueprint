# Reconfigure OPNsense for Corporate IP Addressing

**Project:** SMB Office IT Blueprint
**Last Updated:** 2025-12-28
**Purpose:** Migrate OPNsense from 192.168.x.x to 10.0.x.x corporate addressing

## Overview

This guide walks you through reconfiguring OPNsense to use the new corporate IP addressing scheme (10.0.x.x instead of 192.168.x.x).

**What's Changing:**

| VLAN | Old Network | New Network | Old Gateway | New Gateway |
|------|-------------|-------------|-------------|-------------|
| 10 (Mgmt) | 192.168.10.0/24 | 10.0.10.0/24 | 192.168.10.254 | 10.0.10.1 |
| 20 (Servers) | 192.168.20.0/24 | 10.0.20.0/24 | 192.168.20.254 | 10.0.20.1 |
| 30 (Workstations) | 192.168.30.0/24 | 10.0.30.0/24 | 192.168.30.254 | 10.0.30.1 |
| 40 (Guest/IoT) | 192.168.40.0/24 | 10.0.40.0/24 | 192.168.40.254 | 10.0.40.1 |
| 50 (DMZ) | 192.168.50.0/24 | 10.0.50.0/24 | 192.168.50.254 | 10.0.50.1 |

**What's NOT Changing:**
- WAN interface (still on lab network 192.168.35.x)
- VLAN tags (still 10, 20, 30, 40, 50)
- VLAN parent interface (still vtnet1)

## Prerequisites

- [x] Proxmox network configuration updated to new IPs
- [x] Proxmox network reloaded (`ifreload -a`)
- [x] Console access to OPNsense (Proxmox web UI or `qm terminal 100`)
- [x] Backup of OPNsense configuration

## Part 1: Backup Current Configuration

### Step 1: Download Configuration Backup

**Via Web UI:**

1. Access OPNsense web UI: `https://192.168.35.XXX` (WAN IP)
2. Login as `root`
3. Navigate: **System → Configuration → Backups**
4. Click **Download configuration**
5. Save file: `config-YYYYMMDD-before-ip-migration.xml`
6. Keep this file safe!

**Via Console:**

```bash
# Access console
qm terminal 100

# Login as root
# Select option 8 (Shell)

# Create backup
cd /conf
cp config.xml config.xml.backup-$(date +%Y%m%d)

# Verify backup
ls -lh config.xml*
```

## Part 2: Update LAN Interface (VLAN 10 - Management)

### Step 2: Change LAN IP via Console

**Access Console:**

```bash
# On Proxmox host
qm terminal 100
```

**Login as root** (if not already logged in)

From the console menu:

```
*** OPNsense.localdomain: OPNsense 24.7 ***

  WAN (wan) -> vtnet0 -> v4/DHCP4: 192.168.35.XXX/24
  LAN (lan) -> vtnet1 -> v4: 192.168.10.254/24

Enter an option: _
```

**Select:** `2` (Set interface IP address)

**Select:** `2` (LAN)

```
Configure IPv4 address LAN interface via DHCP? (y/n): _
```

**Answer:** `n`

```
Enter the new LAN IPv4 address: _
```

**Answer:** `10.0.10.1`

Press `Enter`

```
Enter the new LAN IPv4 subnet bit count (1 to 31): _
```

**Answer:** `24`

Press `Enter`

```
For a WAN, enter the new LAN IPv4 upstream gateway address.
For a LAN, press <ENTER> for none: _
```

**Answer:** (just press `Enter`)

```
Configure IPv6 address LAN interface via DHCP6? (y/n): _
```

**Answer:** `n`

```
Do you want to enable the DHCP server on LAN? (y/n): _
```

**Answer:** `y`

```
Enter the start address of the IPv4 client address range: _
```

**Answer:** `10.0.10.100`

Press `Enter`

```
Enter the end address of the IPv4 client address range: _
```

**Answer:** `10.0.10.200`

Press `Enter`

```
Do you want to revert to HTTP as the web GUI protocol? (y/n): _
```

**Answer:** `n`

Press `Enter`

**Wait 5-10 seconds** for the interface to reconfigure.

You should now see:

```
  LAN (lan) -> vtnet1 -> v4: 10.0.10.1/24
```

### Step 3: Access Web UI on New IP

**Important:** You can no longer access the web UI via `https://192.168.10.254`. The new IP is:

```
https://10.0.10.1
```

**From where?**

Since your workstation is on the lab network (192.168.35.x), you **cannot directly** access 10.0.10.1 yet. You have two options:

**Option A: Continue using WAN IP**

Continue accessing via: `https://192.168.35.XXX` (WAN IP - unchanged)

**Option B: Access via Proxmox host**

```bash
# On Proxmox host
curl -k https://10.0.10.1

# Or use SSH tunnel
ssh -L 8443:10.0.10.1:443 root@192.168.35.20

# Then access from your workstation:
https://localhost:8443
```

**Recommendation:** Use WAN IP for now, we'll configure VLANs through the web UI.

## Part 3: Update VLAN Interfaces via Web UI

### Step 4: Access Web UI

Access OPNsense web UI via WAN IP:

```
https://192.168.35.XXX
```

Login as `root`

### Step 5: Update VLAN 20 (Servers)

Navigate: **Interfaces → Assignments**

Click on **VLAN20_Servers** (or OPT1)

Update the following:

```
IPv4 address: 10.0.20.1 / 24
```

**Remove old IP if shown:** Delete `192.168.20.254`

Click **Save**

Click **Apply changes**

### Step 6: Update VLAN 30 (Workstations)

Navigate: **Interfaces → Assignments**

Click on **VLAN30_Workstations** (or OPT2)

Update:

```
IPv4 address: 10.0.30.1 / 24
```

Click **Save**

Click **Apply changes**

### Step 7: Update VLAN 40 (Guest/IoT)

Navigate: **Interfaces → Assignments**

Click on **VLAN40_Guest** (or OPT3)

Update:

```
IPv4 address: 10.0.40.1 / 24
```

Click **Save**

Click **Apply changes**

### Step 8: Update VLAN 50 (DMZ)

Navigate: **Interfaces → Assignments**

Click on **VLAN50_DMZ** (or OPT4)

Update:

```
IPv4 address: 10.0.50.1 / 24
```

Click **Save**

Click **Apply changes**

## Part 4: Update DHCP Services

### Step 9: Update DHCP for LAN (VLAN 10)

Navigate: **Services → DHCPv4 → LAN**

**This was already updated in Step 2 via console.** Verify:

```
Range from: 10.0.10.100
Range to: 10.0.10.200
DNS servers: 10.0.10.1
```

If not correct, update and click **Save**

### Step 10: Update DHCP for VLAN 20 (Servers)

Navigate: **Services → DHCPv4 → VLAN20_Servers**

Update:

```
Range from: 10.0.20.100
Range to: 10.0.20.200
DNS servers: 10.0.20.1
```

Click **Save**

### Step 11: Update DHCP for VLAN 30 (Workstations)

Navigate: **Services → DHCPv4 → VLAN30_Workstations**

Update:

```
Range from: 10.0.30.100
Range to: 10.0.30.254
DNS servers: 10.0.20.10, 10.0.20.11
```

**Note:** DNS servers point to domain controllers (when deployed)

Click **Save**

### Step 12: Update DHCP for VLAN 40 (Guest/IoT)

Navigate: **Services → DHCPv4 → VLAN40_Guest**

Update:

```
Range from: 10.0.40.100
Range to: 10.0.40.254
DNS servers: 10.0.40.1
```

Click **Save**

### Step 13: Update DHCP for VLAN 50 (DMZ)

Navigate: **Services → DHCPv4 → VLAN50_DMZ**

Update:

```
Range from: 10.0.50.100
Range to: 10.0.50.200
DNS servers: 8.8.8.8, 8.8.4.4
```

**Note:** DMZ uses public DNS servers

Click **Save**

## Part 5: Update Firewall Rules

### Step 14: Review and Update Firewall Rules

Navigate: **Firewall → Rules → LAN**

Your existing rules should still work, but verify the source/destination addresses are set to "LAN net" (not hardcoded IPs).

If you have any rules with hardcoded 192.168.x.x addresses, update them to 10.0.x.x

#### Update Rules for Each VLAN

**For VLAN20_Servers, VLAN30_Workstations, VLAN40_Guest, VLAN50_DMZ:**

Navigate to each interface and verify rules use:
- **Source:** `VLAN20_Servers net` (not hardcoded IPs)
- **Destination:** `any` or specific networks

If you have hardcoded IPs, edit and update them.

### Step 15: Update NAT Rules

Navigate: **Firewall → NAT → Outbound**

If you're using **Automatic outbound NAT**, the rules should auto-update.

If you're using **Manual outbound NAT**, update each rule:

**Old:**
```
Source: 192.168.10.0/24
Source: 192.168.20.0/24
Source: 192.168.30.0/24
etc.
```

**New:**
```
Source: 10.0.10.0/24
Source: 10.0.20.0/24
Source: 10.0.30.0/24
etc.
```

## Part 6: Update DNS Configuration

### Step 16: Update DNS Forwarder (Unbound)

Navigate: **Services → Unbound DNS → General**

Verify the DNS forwarder is listening on all new VLAN interfaces:

```
Network Interfaces:
  ☑ LAN (10.0.10.1)
  ☑ VLAN20_Servers (10.0.20.1)
  ☑ VLAN30_Workstations (10.0.30.1)
  ☑ VLAN40_Guest (10.0.40.1)
  ☑ VLAN50_DMZ (10.0.50.1)
```

Click **Save**

Click **Apply**

### Step 17: Update Host Overrides (if any)

Navigate: **Services → Unbound DNS → Overrides**

If you have any host overrides with old 192.168.x.x IPs, update them to 10.0.x.x

## Part 7: Verification

### Step 18: Verify Interfaces

Navigate: **Interfaces → Overview**

You should see:

```
WAN (vtnet0)        - 192.168.35.XXX/24 (up)
LAN (vtnet1)        - 10.0.10.1/24 (up)
VLAN20_Servers      - 10.0.20.1/24 (up)
VLAN30_Workstations - 10.0.30.1/24 (up)
VLAN40_Guest        - 10.0.40.1/24 (up)
VLAN50_DMZ          - 10.0.50.1/24 (up)
```

All should show status "up" with green indicators.

### Step 19: Test from Proxmox Host

```bash
# On Proxmox host
ssh root@192.168.35.20

# Ping new OPNsense IPs
ping -c 3 10.0.10.1
ping -c 3 10.0.20.1
ping -c 3 10.0.30.1
ping -c 3 10.0.40.1
ping -c 3 10.0.50.1
```

**All pings should succeed.**

### Step 20: Check Routing Table

From Proxmox host:

```bash
# View routing table
ip route

# You should see routes to new networks
route -n | grep 10.0
```

**Expected output:**
```
10.0.10.0/24 dev vmbr1.10 proto kernel scope link src 10.0.10.2
10.0.20.0/24 dev vmbr1.20 proto kernel scope link src 10.0.20.2
```

### Step 21: Test DNS Resolution

From OPNsense console (option 8 - Shell):

```bash
# Test DNS from OPNsense
dig @10.0.10.1 google.com
nslookup google.com 10.0.10.1
```

Should return valid DNS responses.

## Part 8: Update Documentation

### Step 22: Update Local Documentation

Update any local documentation, scripts, or playbooks that reference the old IPs:

**Files to check:**
- `docs/network/network-architecture.md`
- `playbooks/*.yml`
- Any VM deployment scripts
- Monitoring configurations
- Backup scripts

**Search for old IPs:**
```bash
cd ~/Documents/claude/projects/smb-office-it-blueprint

# Find files with old IPs
grep -r "192.168.10\." --exclude-dir=backups
grep -r "192.168.20\." --exclude-dir=backups
grep -r "192.168.30\." --exclude-dir=backups
```

## Part 9: Optional - Secure Web UI Access

### Step 23: Disable Web UI on WAN (Recommended)

Once you have VMs deployed on VLAN 10, you should disable web UI access from WAN for security.

Navigate: **System → Settings → Administration**

```
Disable web GUI redirect rule: ☑ CHECK THIS
```

Click **Save**

**Important:** Only do this after you can access the web UI from a VM on VLAN 10 (10.0.10.1).

## Troubleshooting

### Cannot access web UI after changing LAN IP

**Problem:** Lost access to web UI after changing LAN IP

**Solution 1:** Access via WAN IP (192.168.35.XXX)

**Solution 2:** Reset via console
```bash
qm terminal 100
# Login as root
# Option 2 (Set interface IP)
# Option 2 (LAN)
# Re-enter: 10.0.10.1
```

### Pings fail from Proxmox host

**Problem:** Cannot ping 10.0.10.1 from Proxmox

**Check 1:** Proxmox VLAN IPs updated?
```bash
ip addr show vmbr1.10
# Should show: inet 10.0.10.2/24
```

**Check 2:** Network reloaded?
```bash
ifreload -a
```

**Check 3:** OPNsense interface up?
```bash
# On OPNsense console
ifconfig vtnet1 | grep inet
# Should show: inet 10.0.10.1
```

### VMs not getting DHCP addresses

**Problem:** VMs on new networks not getting IPs

**Check 1:** DHCP enabled for that VLAN?
- **Services → DHCPv4 → [Interface]**
- Enable checkbox should be checked

**Check 2:** DHCP range correct?
- Should be 10.0.X.100 - 10.0.X.200

**Check 3:** Firewall allowing DHCP?
- DHCP uses UDP ports 67-68
- Check **Firewall → Rules → [Interface]**

**Check 4:** VM on correct VLAN?
- Check VM network settings in Proxmox
- Should be on vmbr1 with correct VLAN tag

### NAT not working

**Problem:** VMs can't access internet

**Check 1:** Outbound NAT rules
- **Firewall → NAT → Outbound**
- Should have rules for all 10.0.x.x networks

**Check 2:** WAN interface still working?
- **Interfaces → Overview**
- WAN should still have lab network IP

**Check 3:** Default gateway on VMs
- VMs should have gateway 10.0.X.1

## Summary Checklist

After completing all steps:

- [ ] LAN interface IP: 10.0.10.1/24
- [ ] VLAN 20 IP: 10.0.20.1/24
- [ ] VLAN 30 IP: 10.0.30.1/24
- [ ] VLAN 40 IP: 10.0.40.1/24
- [ ] VLAN 50 IP: 10.0.50.1/24
- [ ] DHCP scopes updated for all VLANs
- [ ] Firewall rules reviewed and updated
- [ ] NAT rules updated (if manual)
- [ ] DNS forwarder listening on new IPs
- [ ] All interfaces show "up" in Overview
- [ ] Can ping all VLAN gateways from Proxmox
- [ ] DNS resolution working
- [ ] Configuration backed up

## Next Steps

1. **Deploy VMs from templates** with new IP addressing
2. **Test inter-VLAN connectivity** through OPNsense
3. **Configure static IP reservations** for infrastructure VMs
4. **Set up monitoring** for new network ranges
5. **Update firewall rules** for inter-VLAN access as needed

## Configuration Backup

**Current backup location:**
- Console backup: `/conf/config.xml.backup-YYYYMMDD`
- Web UI backup: `config-YYYYMMDD-before-ip-migration.xml`

**To restore from backup:**

Navigate: **System → Configuration → Backups**
- Click **Browse**
- Select backup file
- Click **Restore configuration**

## Quick Reference

**New Network Summary:**

| VLAN | Network | Gateway | DHCP Range | Proxmox Host |
|------|---------|---------|------------|--------------|
| 10 | 10.0.10.0/24 | 10.0.10.1 | .100-.200 | 10.0.10.2 |
| 20 | 10.0.20.0/24 | 10.0.20.1 | .100-.200 | 10.0.20.2 |
| 30 | 10.0.30.0/24 | 10.0.30.1 | .100-.254 | - |
| 40 | 10.0.40.0/24 | 10.0.40.1 | .100-.254 | - |
| 50 | 10.0.50.0/24 | 10.0.50.1 | .100-.200 | - |

**Lab Network (Unchanged):**
- vmbr0: 192.168.35.20/24
- OPNsense WAN: 192.168.35.XXX/24

---

**Configuration complete!** Your OPNsense firewall is now using corporate IP addressing (10.0.x.x).
