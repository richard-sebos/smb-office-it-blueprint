# OPNsense Installation and Configuration Guide

**Project:** SMB Office IT Blueprint
**Last Updated:** 2025-12-27
**VM ID:** 100
**Purpose:** Firewall, router, NAT, DHCP, DNS for internal network

## Overview

This guide walks through installing and configuring OPNsense as the central firewall/router for the SMB Office IT Blueprint project. OPNsense will:

- Route traffic between lab network (vmbr0) and internal network (vmbr1)
- Provide NAT for internal VMs to access internet
- Run DHCP servers for each VLAN
- Provide DNS services
- Enforce firewall rules between VLANs
- Optional: VPN, IDS/IPS, traffic shaping

## Network Architecture

```
Internet/Lab Network (192.168.35.0/24)
          |
       vmbr0 (WAN)
          |
    ┌─────────────┐
    │  OPNsense   │  VM 100
    │  Firewall   │
    └─────────────┘
          |
       vmbr1 (LAN)
          |
    ┌─────────────────────────────────────┐
    │  Internal VLAN Network (vmbr1)      │
    ├─────────────────────────────────────┤
    │ VLAN 10: 192.168.10.0/24 (Mgmt)     │
    │ VLAN 20: 192.168.20.0/24 (Servers)  │
    │ VLAN 30: 192.168.30.0/24 (Workst.)  │
    │ VLAN 40: 192.168.40.0/24 (Guest)    │
    │ VLAN 50: 192.168.50.0/24 (DMZ)      │
    └─────────────────────────────────────┘
```

## Prerequisites

Before starting:

- [x] VM 100 created with `create-opnsense-vm.sh`
- [x] vmbr1 network activated and verified
- [x] Console access to Proxmox (web UI or CLI)
- [ ] Knowledge of your lab network details (gateway, DNS servers)

## Part 1: Install OPNsense

### Step 1: Start the VM

```bash
# On Proxmox host
ssh root@192.168.35.20

# Start OPNsense VM
qm start 100

# Check status
qm status 100
```

**Expected output:** `status: running`

### Step 2: Open Console

**Option A: Proxmox Web UI (Recommended)**
1. Open browser: `https://192.168.35.20:8006`
2. Login to Proxmox
3. Navigate: Datacenter → pve → 100 (opnsense-firewall)
4. Click **Console** button
5. You should see OPNsense boot screen

**Option B: Command Line**
```bash
# On Proxmox host
qm terminal 100
```

Press `Ctrl+O` to exit terminal when done.

### Step 3: OPNsense Installer Login

Wait for the VM to boot (30-60 seconds). You'll see:

```
OPNsense 24.7 - OpenBSD Secure Shell server

console login: _
```

**Login credentials:**
- Username: `installer`
- Password: `opnsense`

### Step 4: Start Installation

After login, you'll see a menu:

```
  ┌─────────────────────────────────────────────────┐
  │ 1. Install (UFS)                                │
  │ 2. Install (ZFS)                                │
  │ 3. Rescue Shell                                 │
  │ 4. Reboot                                       │
  └─────────────────────────────────────────────────┘
```

**Select:** `1` (Install UFS)

Press `Enter`

### Step 5: Keymap Selection

```
Select your keyboard layout:
  >>> Continue with default keymap
      Test keymap
      Select different keymap
```

**Select:** `>>> Continue with default keymap` (or choose your layout)

Press `Enter`

### Step 6: Disk Selection

```
Select target disk:
  [ ] vtbd0 (32 GB)
```

**Select:** `vtbd0` (use Spacebar to select, should show `[x]`)

Press `Enter`

**Warning:** "This will erase all data on vtbd0. Proceed?"

**Select:** `YES`

Press `Enter`

### Step 7: Installation Progress

The installer will:
- Partition the disk
- Extract base system
- Install bootloader
- Configure system

This takes 2-5 minutes. You'll see progress bars.

### Step 8: Set Root Password

```
Set root password:
New Password: _
```

**Enter a strong password** (you'll need this for SSH and web UI access)

**Important:** Write this password down! This is your main administrative password.

Confirm password when prompted.

### Step 9: Complete Installation

```
Installation complete!
Remove installation media and reboot.

  [Reboot] [Shell]
```

**Select:** `Reboot`

The VM will reboot. This takes 30-60 seconds.

### Step 10: Remove Installation Media

While the VM is rebooting:

```bash
# On Proxmox host (in another SSH session or after Ctrl+O from console)
qm set 100 --ide2 none

# Verify CD-ROM is removed
qm config 100 | grep ide2
```

**Expected output:** No ide2 line or `ide2: none`

## Part 2: Initial Interface Configuration

### Step 11: Console Login After Reboot

After reboot, you'll see the OPNsense console menu:

```
*** OPNsense.localdomain: OPNsense 24.7 ***

  WAN (wan) -> vtnet0 -> v4/DHCP4: (not assigned)
  LAN (lan) -> vtnet1 -> v4: 192.168.1.1/24

  0) Logout                              7) Ping host
  1) Assign interfaces                   8) Shell
  2) Set interface IP address            9) pfTop
  3) Reset the root password            10) Firewall log
  4) Reset to factory defaults          11) Reload all services
  5) Power off system                   12) Update from console
  6) Reboot system                      13) Restore a backup

Enter an option: _
```

**Login credentials:**
- Username: `root`
- Password: (the password you set during installation)

### Step 12: Assign Interfaces

**Select:** `1` (Assign interfaces)

Press `Enter`

```
Do you want to configure VLANs now? (y/n): _
```

**Answer:** `n` (we'll configure VLANs later through the web UI)

Press `Enter`

```
Enter the WAN interface name or 'a' for auto-detection: _
```

**Answer:** `vtnet0`

Press `Enter`

```
Enter the LAN interface name or 'a' for auto-detection
(or nothing if finished): _
```

**Answer:** `vtnet1`

Press `Enter`

```
Enter the Optional interface name or 'a' for auto-detection
(or nothing if finished): _
```

**Answer:** (just press `Enter` - no optional interfaces yet)

```
The interfaces will be assigned as follows:

  WAN  -> vtnet0
  LAN  -> vtnet1

Do you want to proceed? (y/n): _
```

**Answer:** `y`

Press `Enter`

The system will apply the interface assignments. This takes 5-10 seconds.

### Step 13: Configure WAN Interface (vtnet0)

**Select:** `2` (Set interface IP address)

Press `Enter`

```
Select an interface to configure:

1 - WAN (vtnet0)
2 - LAN (vtnet1)

Enter an option: _
```

**Select:** `1` (WAN)

Press `Enter`

```
Configure IPv4 address WAN interface via DHCP? (y/n): _
```

**Answer:** `y` (if your lab network provides DHCP)

**Note:** If your lab requires static IP, answer `n` and follow the static IP prompts.

Press `Enter`

```
Configure IPv6 address WAN interface via DHCP6? (y/n): _
```

**Answer:** `n` (unless you use IPv6 in your lab)

Press `Enter`

```
Do you want to revert to HTTP as the web GUI protocol? (y/n): _
```

**Answer:** `n` (keep HTTPS)

Press `Enter`

The WAN interface will be configured. You should see:

```
WAN (wan) -> vtnet0 -> v4/DHCP4: 192.168.35.XXX/24
```

**Note the WAN IP address** - you'll use this temporarily to access the web UI.

### Step 14: Configure LAN Interface (vtnet1)

**Select:** `2` (Set interface IP address)

Press `Enter`

```
Select an interface to configure:

1 - WAN (vtnet0)
2 - LAN (vtnet1)

Enter an option: _
```

**Select:** `2` (LAN)

Press `Enter`

```
Configure IPv4 address LAN interface via DHCP? (y/n): _
```

**Answer:** `n` (LAN needs static IP)

Press `Enter`

```
Enter the new LAN IPv4 address: _
```

**Answer:** `192.168.10.254`

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

**Answer:** (just press `Enter` - LAN has no upstream gateway)

```
Configure IPv6 address LAN interface via DHCP6? (y/n): _
```

**Answer:** `n`

Press `Enter`

```
Do you want to enable the DHCP server on LAN? (y/n): _
```

**Answer:** `y` (we'll configure DHCP for VLAN 10 later)

Press `Enter`

```
Enter the start address of the IPv4 client address range: _
```

**Answer:** `192.168.10.100`

Press `Enter`

```
Enter the end address of the IPv4 client address range: _
```

**Answer:** `192.168.10.200`

Press `Enter`

```
Do you want to revert to HTTP as the web GUI protocol? (y/n): _
```

**Answer:** `n`

Press `Enter`

The LAN interface will be configured. You should now see:

```
*** OPNsense.localdomain: OPNsense 24.7 ***

  WAN (wan) -> vtnet0 -> v4/DHCP4: 192.168.35.XXX/24
  LAN (lan) -> vtnet1 -> v4: 192.168.10.254/24
```

## Part 3: Web UI Access and Initial Configuration

### Step 15: Access Web UI

From your workstation (connected to the lab network 192.168.35.0/24):

**Open browser:** `https://192.168.35.XXX` (use the WAN IP from Step 13)

**Note:** You'll get a certificate warning (self-signed certificate). This is normal.

- **Firefox:** Click "Advanced" → "Accept the Risk and Continue"
- **Chrome:** Click "Advanced" → "Proceed to 192.168.35.XXX (unsafe)"

**Login credentials:**
- Username: `root`
- Password: (the password you set during installation)

### Step 16: Setup Wizard - Welcome

You'll see the OPNsense setup wizard.

Click **Next**

### Step 17: Setup Wizard - General Information

```
Hostname: opnsense
Domain: lab.local
Primary DNS Server: 8.8.8.8
Secondary DNS Server: 8.8.4.4
```

**Note:** Use your lab's DNS servers if you have them. Otherwise, use public DNS (8.8.8.8, 8.8.4.4).

**Uncheck:** "Override DNS" (if you want to use your lab's DNS from DHCP)

Click **Next**

### Step 18: Setup Wizard - Time Server

```
Time server hostname: pool.ntp.org
Timezone: (select your timezone, e.g., America/New_York)
```

Click **Next**

### Step 19: Setup Wizard - WAN Interface

```
IP Address: (should show DHCP or your static IP)
Block RFC1918 Private Networks: ☐ UNCHECK THIS
Block bogon networks: ☑ LEAVE CHECKED
```

**Important:** Uncheck "Block RFC1918" because your lab network is private (192.168.35.0/24).

Click **Next**

### Step 20: Setup Wizard - LAN Interface

```
LAN IP Address: 192.168.10.254
Subnet Mask: 24
```

Click **Next**

### Step 21: Setup Wizard - Root Password

```
Root Password: (confirm your password)
```

Re-enter your root password to confirm.

Click **Next**

### Step 22: Setup Wizard - Reload Configuration

Click **Reload**

Wait 10-20 seconds while OPNsense applies the configuration.

Click **Finish** when done.

You'll be redirected to the OPNsense dashboard.

## Part 4: Configure VLANs and DHCP

### Step 23: Create VLAN Interfaces

Navigate: **Interfaces → Other Types → VLAN**

Click **+ Add**

#### VLAN 10 (Management) - Already configured as LAN
Skip - already configured during initial setup

#### VLAN 20 (Servers)

```
Parent: vtnet1 (LAN)
VLAN tag: 20
VLAN priority: (leave empty)
Description: VLAN20_Servers
```

Click **Save**

#### VLAN 30 (Workstations)

```
Parent: vtnet1 (LAN)
VLAN tag: 30
Description: VLAN30_Workstations
```

Click **Save**

#### VLAN 40 (Guest/IoT)

```
Parent: vtnet1 (LAN)
VLAN tag: 40
Description: VLAN40_Guest
```

Click **Save**

#### VLAN 50 (DMZ)

```
Parent: vtnet1 (LAN)
VLAN tag: 50
Description: VLAN50_DMZ
```

Click **Save**

Click **Apply changes**

### Step 24: Assign VLAN Interfaces

Navigate: **Interfaces → Assignments**

You'll see unassigned VLAN interfaces at the bottom.

#### Assign VLAN 20

Click **+ Add** next to `vtnet1_vlan20`

A new interface `OPT1` will appear.

Click **OPT1**

```
Enable: ☑ Enable interface
Description: VLAN20_Servers
IPv4 Configuration Type: Static IPv4
IPv4 address: 192.168.20.254 / 24
```

Click **Save**

Click **Apply changes**

#### Assign VLAN 30

Click **+ Add** next to `vtnet1_vlan30`

Click **OPT2**

```
Enable: ☑ Enable interface
Description: VLAN30_Workstations
IPv4 Configuration Type: Static IPv4
IPv4 address: 192.168.30.254 / 24
```

Click **Save**

Click **Apply changes**

#### Assign VLAN 40

Click **+ Add** next to `vtnet1_vlan40`

Click **OPT3**

```
Enable: ☑ Enable interface
Description: VLAN40_Guest
IPv4 Configuration Type: Static IPv4
IPv4 address: 192.168.40.254 / 24
```

Click **Save**

Click **Apply changes**

#### Assign VLAN 50

Click **+ Add** next to `vtnet1_vlan50`

Click **OPT4**

```
Enable: ☑ Enable interface
Description: VLAN50_DMZ
IPv4 Configuration Type: Static IPv4
IPv4 address: 192.168.50.254 / 24
```

Click **Save**

Click **Apply changes**

### Step 25: Configure DHCP for VLANs

Navigate: **Services → DHCPv4 → [Interface]**

#### DHCP for LAN (VLAN 10 - Management)

Already configured during initial setup. Verify:

Navigate: **Services → DHCPv4 → LAN**

```
Enable: ☑ Enable DHCP server on LAN
Range: 192.168.10.100 to 192.168.10.200
DNS servers: 192.168.10.254
```

Click **Save** (if you made changes)

#### DHCP for VLAN20_Servers

Navigate: **Services → DHCPv4 → VLAN20_Servers**

```
Enable: ☑ Enable DHCP server on VLAN20_Servers
Range from: 192.168.20.100
Range to: 192.168.20.200
DNS servers: 192.168.20.254
```

Click **Save**

#### DHCP for VLAN30_Workstations

Navigate: **Services → DHCPv4 → VLAN30_Workstations**

```
Enable: ☑ Enable DHCP server on VLAN30_Workstations
Range from: 192.168.30.100
Range to: 192.168.30.200
DNS servers: 192.168.30.254
```

Click **Save**

#### DHCP for VLAN40_Guest

Navigate: **Services → DHCPv4 → VLAN40_Guest**

```
Enable: ☑ Enable DHCP server on VLAN40_Guest
Range from: 192.168.40.100
Range to: 192.168.40.200
DNS servers: 192.168.40.254
```

Click **Save**

#### DHCP for VLAN50_DMZ

Navigate: **Services → DHCPv4 → VLAN50_DMZ**

```
Enable: ☑ Enable DHCP server on VLAN50_DMZ
Range from: 192.168.50.100
Range to: 192.168.50.200
DNS servers: 192.168.50.254
```

Click **Save**

### Step 26: Configure NAT (Outbound)

Navigate: **Firewall → NAT → Outbound**

**Mode:** Select `Automatic outbound NAT rule generation`

This will automatically create NAT rules for all VLANs to access the internet through WAN.

Click **Save**

Click **Apply changes**

### Step 27: Configure Firewall Rules

By default, OPNsense blocks traffic between VLANs. We need to create rules to allow necessary traffic.

#### LAN (VLAN 10) Rules

Navigate: **Firewall → Rules → LAN**

Default rules should allow LAN to everything. Verify:

- Rule: "Default allow LAN to any rule" (green checkmark)

This is fine for the management network.

#### VLAN20_Servers Rules

Navigate: **Firewall → Rules → VLAN20_Servers**

Click **+ Add** (to create a rule at the top)

**Rule 1: Allow all outbound traffic**

```
Action: Pass
Interface: VLAN20_Servers
Direction: in
TCP/IP Version: IPv4
Protocol: any
Source: VLAN20_Servers net
Destination: any
Description: Allow servers outbound access
```

Click **Save**

Click **Apply changes**

#### VLAN30_Workstations Rules

Navigate: **Firewall → Rules → VLAN30_Workstations**

Click **+ Add**

```
Action: Pass
Interface: VLAN30_Workstations
Direction: in
TCP/IP Version: IPv4
Protocol: any
Source: VLAN30_Workstations net
Destination: any
Description: Allow workstations outbound access
```

Click **Save**

Click **Apply changes**

#### VLAN40_Guest Rules

Navigate: **Firewall → Rules → VLAN40_Guest**

Click **+ Add**

```
Action: Pass
Interface: VLAN40_Guest
Direction: in
TCP/IP Version: IPv4
Protocol: any
Source: VLAN40_Guest net
Destination: any
Description: Allow guest outbound access
```

Click **Save**

Click **Apply changes**

**Note:** For production, you should restrict guest network access more tightly.

#### VLAN50_DMZ Rules

Navigate: **Firewall → Rules → VLAN50_DMZ**

Click **+ Add**

```
Action: Pass
Interface: VLAN50_DMZ
Direction: in
TCP/IP Version: IPv4
Protocol: any
Source: VLAN50_DMZ net
Destination: WAN net
Description: Allow DMZ to WAN only
```

Click **Save**

Click **Apply changes**

**Note:** DMZ should NOT have access to internal VLANs by default (which is the current state).

## Part 5: Configure DNS Forwarder

Navigate: **Services → Unbound DNS → General**

```
Enable: ☑ Enable Unbound
Network Interfaces: Select all VLAN interfaces (LAN, VLAN20, VLAN30, VLAN40, VLAN50)
DHCP Registration: ☑ Register DHCP leases
DHCP Static Mappings: ☑ Register DHCP static mappings
```

Click **Save**

Click **Apply**

## Part 6: Verification and Testing

### Step 28: Verify Interfaces

Navigate: **Interfaces → Overview**

You should see:

```
WAN (vtnet0)        - 192.168.35.XXX/24 (up)
LAN (vtnet1)        - 192.168.10.254/24 (up)
VLAN20_Servers      - 192.168.20.254/24 (up)
VLAN30_Workstations - 192.168.30.254/24 (up)
VLAN40_Guest        - 192.168.40.254/24 (up)
VLAN50_DMZ          - 192.168.50.254/24 (up)
```

All should show status "up" with green indicators.

### Step 29: Test from Proxmox Host

```bash
# On Proxmox host
ssh root@192.168.35.20

# Ping OPNsense WAN interface
ping -c 3 192.168.35.XXX  # Use actual WAN IP

# Ping OPNsense LAN interfaces
ping -c 3 192.168.10.254
ping -c 3 192.168.20.254
ping -c 3 192.168.30.254
ping -c 3 192.168.40.254
ping -c 3 192.168.50.254
```

All pings should succeed.

### Step 30: Check NAT Rules

Navigate: **Firewall → NAT → Outbound**

You should see automatic outbound NAT rules for all VLANs:

```
LAN net -> WAN address
VLAN20_Servers net -> WAN address
VLAN30_Workstations net -> WAN address
VLAN40_Guest net -> WAN address
VLAN50_DMZ net -> WAN address
```

### Step 31: Verify DHCP Leases (After VMs Created)

Navigate: **Services → DHCPv4 → Leases**

After you create VMs and they boot, you should see DHCP leases assigned.

## Part 7: Optional Enhancements

### Enable SSH Access

Navigate: **System → Settings → Administration**

```
Secure Shell Server: ☑ Enable Secure Shell
SSH Port: 22
```

Click **Save**

Now you can SSH to OPNsense:

```bash
ssh root@192.168.10.254
# or
ssh root@192.168.35.XXX  # WAN IP
```

### Set Hostname in Proxmox

On Proxmox host:

```bash
# Add DNS entry for easier access (optional)
echo "192.168.35.XXX  opnsense.lab.local opnsense" >> /etc/hosts
```

Replace `XXX` with actual WAN IP.

### Change Web UI to LAN IP

Once you have a VM on the management VLAN (192.168.10.0/24), you can access OPNsense via:

```
https://192.168.10.254
```

This is more secure than accessing via WAN IP.

### Disable Web UI Access on WAN (Recommended)

Navigate: **System → Settings → Administration**

```
Web GUI → Disable web GUI redirect rule: ☑ CHECK THIS
```

This prevents web UI access from WAN interface.

Click **Save**

**Important:** Do this ONLY after you have a way to access OPNsense from LAN (VM on VLAN 10).

## Summary

You now have OPNsense fully configured with:

- ✅ WAN interface on vmbr0 (lab network)
- ✅ LAN interface on vmbr1 (internal network)
- ✅ 5 VLANs configured (10, 20, 30, 40, 50)
- ✅ DHCP servers running on all VLANs
- ✅ NAT configured for internet access
- ✅ Basic firewall rules allowing outbound traffic
- ✅ DNS forwarder (Unbound) running
- ✅ All interfaces up and pingable

## Network Information Quick Reference

| VLAN | Network | Gateway | DHCP Range | Purpose |
|------|---------|---------|------------|---------|
| 10 | 192.168.10.0/24 | 192.168.10.254 | .100-.200 | Management |
| 20 | 192.168.20.0/24 | 192.168.20.254 | .100-.200 | Servers |
| 30 | 192.168.30.0/24 | 192.168.30.254 | .100-.200 | Workstations |
| 40 | 192.168.40.0/24 | 192.168.40.254 | .100-.200 | Guest/IoT |
| 50 | 192.168.50.0/24 | 192.168.50.254 | .100-.200 | DMZ |

**Static IP Reservations:**
- 192.168.10.1 - Proxmox host (vmbr1.10)
- 192.168.10.10 - Project Ansible Server (VM 110)
- 192.168.20.1 - Proxmox host (vmbr1.20)
- 192.168.20.10 - Domain Controller (VM 200)
- (More static IPs as defined in project plan)

## Next Steps

1. **Create VMs from templates** - Clone VMs for infrastructure services
2. **Configure static IPs** - Set static IPs for infrastructure VMs (or use DHCP reservations)
3. **Test inter-VLAN routing** - Verify VMs in different VLANs can communicate through OPNsense
4. **Refine firewall rules** - Create specific rules for inter-VLAN traffic
5. **Set up monitoring** - Configure OPNsense monitoring and alerting

## Troubleshooting

### Cannot access web UI after changing LAN IP

**Solution:** Access via console and change back:
```bash
# Console: Select option 2 (Set interface IP address)
# Select LAN interface
# Set IP back to 192.168.10.254
```

### VMs not getting DHCP addresses

**Checks:**
1. Verify DHCP is enabled for that VLAN: **Services → DHCPv4 → [Interface]**
2. Check firewall rules allow DHCP (UDP ports 67-68)
3. Verify VLAN interface is up: **Interfaces → Overview**
4. Check DHCP logs: **System → Log Files → DHCP**

### Cannot ping between VLANs

**Checks:**
1. Verify firewall rules allow traffic: **Firewall → Rules → [Interface]**
2. Check NAT rules: **Firewall → NAT → Outbound**
3. Verify routing: **System → Routes → Status**
4. Check firewall logs: **Firewall → Log Files → Live View**

### Lost SSH access

**Solution:** Access via web UI console, re-enable SSH:
- **System → Settings → Administration**
- Check "Enable Secure Shell"

### WAN interface not getting DHCP

**Checks:**
1. Verify vmbr0 is connected: Proxmox UI → VM 100 → Hardware → net0
2. Check DHCP server on lab network is working
3. Try static IP: Console → Option 2 → WAN interface → Static IP

## Support and Documentation

- **OPNsense Documentation:** https://docs.opnsense.org/
- **OPNsense Forum:** https://forum.opnsense.org/
- **Project Documentation:** `docs/` directory

---

**Configuration Complete!** Your OPNsense firewall is now ready to route traffic for the SMB Office IT Blueprint infrastructure.
