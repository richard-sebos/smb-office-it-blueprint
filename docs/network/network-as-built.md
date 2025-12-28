# Network Configuration - As Built

**Project:** SMB Office IT Blueprint
**Last Updated:** 2025-12-28
**Status:** Deployed and Operational

## Overview

This document reflects the **actual deployed** network configuration, including modifications made to avoid conflicts with the home lab environment.

## VLAN Numbering

**Modified from original plan to avoid home lab conflicts:**

| Original VLAN | Deployed VLAN | Network | Gateway | Purpose |
|---------------|---------------|---------|---------|---------|
| 10 | **110** | 10.0.110.0/24 | 10.0.110.1 | Management |
| 20 | **120** | 10.0.120.0/24 | 10.0.120.1 | Servers |
| 30 | **130** | 10.0.130.0/24 | 10.0.130.1 | Workstations |
| 40 | **140** | 10.0.140.0/24 | 10.0.140.1 | Guest/IoT |
| 50 | **150** | 10.0.150.0/24 | 10.0.150.1 | DMZ |

**Reason for Change:** VLANs 10-50 are in use by the existing home lab network. Adding 100 to each VLAN ID creates unique VLAN tags that won't conflict.

## Network Topology

```
Internet
    |
[Home Lab Router: 192.168.35.1]
    |
[Proxmox Host: 192.168.35.20]
    |
    +--- vmbr0 (WAN/Lab): 192.168.35.0/24
    |        |
    |        +--- Home Lab VLANs 10-50 (separate network)
    |
    +--- vmbr1 (Corporate Internal Network - VLAN-aware)
             |
        [OPNsense VM 100]
             |
             +--- VLAN 110: 10.0.110.0/24 (Management)
             +--- VLAN 120: 10.0.120.0/24 (Servers)
             +--- VLAN 130: 10.0.130.0/24 (Workstations)
             +--- VLAN 140: 10.0.140.0/24 (Guest/IoT)
             +--- VLAN 150: 10.0.150.0/24 (DMZ)
```

## VLAN Details

### VLAN 110 - Management (10.0.110.0/24)

**Purpose:** Infrastructure management, monitoring, backups, administrative access

**Gateway:** 10.0.110.1 (OPNsense)
**DHCP Range:** 10.0.110.100 - 10.0.110.200
**Proxmox Host IP:** 10.0.110.2

**Static IP Assignments:**

| IP | Hostname | Purpose | Status |
|----|----------|---------|--------|
| 10.0.110.1 | gw-mgmt | Default gateway (OPNsense) | Deployed |
| 10.0.110.2 | pve01 | Proxmox host management interface | Deployed |
| 10.0.110.10 | ansible-ctrl | Ansible control server (VM 110) | Planned |
| 10.0.110.11 | monitoring | Monitoring server (Zabbix/Prometheus) | Planned |
| 10.0.110.12 | backup | Backup server | Planned |
| 10.0.110.13 | jump-host | Bastion/jump server | Planned |
| 10.0.110.100-200 | - | DHCP pool | Configured |

### VLAN 120 - Servers (10.0.120.0/24)

**Purpose:** Production application servers, databases, file servers

**Gateway:** 10.0.120.1 (OPNsense)
**DHCP Range:** 10.0.120.100 - 10.0.120.200
**Proxmox Host IP:** 10.0.120.2

**Static IP Assignments:**

| IP | Hostname | Purpose | Status |
|----|----------|---------|--------|
| 10.0.120.1 | gw-servers | Default gateway (OPNsense) | Deployed |
| 10.0.120.2 | pve01-vlan120 | Proxmox host on server VLAN | Deployed |
| 10.0.120.10 | dc01 | Domain Controller 1 (Primary) | Planned |
| 10.0.120.11 | dc02 | Domain Controller 2 (Backup) | Planned |
| 10.0.120.20 | fs01 | File Server 1 | Planned |
| 10.0.120.30 | db01 | Database Server 1 | Planned |
| 10.0.120.40 | app01 | Application Server 1 | Planned |
| 10.0.120.50 | exchange01 | Email Server | Planned |
| 10.0.120.100-200 | - | DHCP pool | Configured |

### VLAN 130 - Workstations (10.0.130.0/24)

**Purpose:** Employee desktop computers, laptops

**Gateway:** 10.0.130.1 (OPNsense)
**DHCP Range:** 10.0.130.100 - 10.0.130.254
**Proxmox Host IP:** None (VM-only network)

**Static IP Assignments:**

| IP | Hostname | Purpose | Status |
|----|----------|---------|--------|
| 10.0.130.1 | gw-workstations | Default gateway (OPNsense) | Deployed |
| 10.0.130.10-50 | ws-* | VIP workstations | Planned |
| 10.0.130.100-254 | - | DHCP pool | Configured |

### VLAN 140 - Guest/IoT (10.0.140.0/24)

**Purpose:** Guest WiFi, IoT devices, cameras, printers

**Gateway:** 10.0.140.1 (OPNsense)
**DHCP Range:** 10.0.140.100 - 10.0.140.254
**Proxmox Host IP:** None (VM-only network)

**Static IP Assignments:**

| IP | Hostname | Purpose | Status |
|----|----------|---------|--------|
| 10.0.140.1 | gw-guest | Default gateway (OPNsense) | Deployed |
| 10.0.140.10-30 | camera-* / iot-* | IoT devices | Planned |
| 10.0.140.100-254 | - | DHCP pool | Configured |

### VLAN 150 - DMZ (10.0.150.0/24)

**Purpose:** Public-facing services, external access

**Gateway:** 10.0.150.1 (OPNsense)
**DHCP Range:** 10.0.150.100 - 10.0.150.200
**Proxmox Host IP:** None (VM-only network)

**Static IP Assignments:**

| IP | Hostname | Purpose | Status |
|----|----------|---------|--------|
| 10.0.150.1 | gw-dmz | Default gateway (OPNsense) | Deployed |
| 10.0.150.10 | web01 | Web server 1 | Planned |
| 10.0.150.20 | vpn-gateway | VPN concentrator | Planned |
| 10.0.150.30 | mail-relay | Email relay/gateway | Planned |
| 10.0.150.100-200 | - | DHCP pool | Configured |

## Proxmox Network Configuration

### Physical/Virtual Bridges

| Interface | Type | Description | IP Address |
|-----------|------|-------------|------------|
| vmbr0 | Linux Bridge | Lab/WAN network | 192.168.35.20/24 |
| vmbr1 | Linux Bridge (VLAN-aware) | Corporate internal network | No IP |

### VLAN Interfaces on Proxmox

| Interface | VLAN Tag | IP Address | Purpose |
|-----------|----------|------------|---------|
| vmbr1.110 | 110 | 10.0.110.2/24 | Management VLAN access |
| vmbr1.120 | 120 | 10.0.120.2/24 | Server VLAN access |
| vmbr1.130 | 130 | None | Workstation VLAN (VM-only) |
| vmbr1.140 | 140 | None | Guest/IoT VLAN (VM-only) |
| vmbr1.150 | 150 | None | DMZ VLAN (VM-only) |

**Configuration File:** `/etc/network/interfaces`

```bash
# View VLAN configuration
cat /etc/network/interfaces | grep -A 6 "vmbr1"
```

## OPNsense Configuration

**VM ID:** 100
**Hostname:** opnsense-firewall

### Interfaces

| Interface | Physical | VLAN | IP Address | Purpose |
|-----------|----------|------|------------|---------|
| WAN | vtnet0 | - | 192.168.35.XXX/24 (DHCP) | Lab network connection |
| LAN | vtnet1 | 110 | 10.0.110.1/24 | Management network |
| VLAN120_Servers | vtnet1 | 120 | 10.0.120.1/24 | Server network |
| VLAN130_Workstations | vtnet1 | 130 | 10.0.130.1/24 | Workstation network |
| VLAN140_Guest | vtnet1 | 140 | 10.0.140.1/24 | Guest/IoT network |
| VLAN150_DMZ | vtnet1 | 150 | 10.0.150.1/24 | DMZ network |

### DHCP Services

All DHCP services are enabled and operational:

| VLAN | Network | DHCP Range | DNS Servers |
|------|---------|------------|-------------|
| 110 | 10.0.110.0/24 | .100-.200 | 10.0.110.1 |
| 120 | 10.0.120.0/24 | .100-.200 | 10.0.120.1 |
| 130 | 10.0.130.0/24 | .100-.254 | 10.0.120.10, 10.0.120.11* |
| 140 | 10.0.140.0/24 | .100-.254 | 10.0.140.1 |
| 150 | 10.0.150.0/24 | .100-.200 | 8.8.8.8, 8.8.4.4 |

*Once domain controllers are deployed

### Firewall Rules

**Current Configuration:** Basic outbound allow rules on all VLANs

**Status:** Operational (allows all VLANs to access internet via NAT)

**Future:** Will be tightened based on security requirements

### NAT Configuration

**Outbound NAT:** Automatic mode

All internal VLANs (10.0.110.0/24 through 10.0.150.0/24) are NATted to the WAN interface for internet access.

## DNS Configuration

**Primary DNS (Current):** OPNsense Unbound forwarder on each VLAN gateway

**Future DNS (Planned):**
- Primary: 10.0.120.10 (dc01 - Domain Controller)
- Secondary: 10.0.120.11 (dc02 - Domain Controller)

**DNS Domain:** corp.company.local (to be configured)

## VM Templates

**Available Templates:**

| VMID | Template Name | OS | Disk | Purpose |
|------|---------------|----|----- |---------|
| 9000 | ubuntu-2204-template | Ubuntu 22.04 LTS | 10GB | General purpose |
| 9100 | debian-12-template | Debian 12 | 10GB | Debian-based services |
| 9200 | rocky-9-template | Rocky Linux 9 | 10GB | RHEL-compatible services |

**Storage:** vmDrive (ZFS)

## Network Verification

### Connectivity Tests (from Proxmox host)

```bash
# Test VLAN gateways
ping -c 2 10.0.110.1
ping -c 2 10.0.120.1
ping -c 2 10.0.130.1
ping -c 2 10.0.140.1
ping -c 2 10.0.150.1

# Test internet via WAN
ping -c 2 8.8.8.8

# Test DNS resolution
nslookup google.com 10.0.110.1
```

**Status:** All tests passing ✓

### Interface Status

```bash
# Check Proxmox interfaces
ip addr show | grep 'vmbr1\.'

# Check OPNsense interfaces
# Via console: Option 8 (Shell)
ifconfig | grep "inet 10.0"
```

**Status:** All interfaces up and operational ✓

## Security Configuration

### Current Security Posture

**Implemented:**
- Network segmentation via VLANs
- NAT for outbound internet access
- Basic firewall rules (allow outbound per VLAN)
- Separate DNS per security zone
- OPNsense web UI accessible only via WAN (lab network)

**Pending:**
- Inter-VLAN firewall rules (currently all blocked by default)
- IDS/IPS configuration
- VPN access for remote management
- VLAN-specific ACLs
- Traffic monitoring and logging

### Security Zones

| Zone | VLANs | Trust Level | Internet Access | Inter-VLAN Default |
|------|-------|-------------|-----------------|-------------------|
| Trusted | 110, 120 | High | Yes | Blocked |
| User | 130 | Medium | Yes | Blocked |
| Untrusted | 140 | Low | Yes | Blocked |
| DMZ | 150 | Medium | Yes | Blocked |

## Deployment Status

### Infrastructure Components

| Component | Status | VLAN | IP Address | Notes |
|-----------|--------|------|------------|-------|
| Proxmox Host | ✓ Deployed | - | 192.168.35.20 | Physical host |
| OPNsense Firewall | ✓ Deployed | WAN/All | 192.168.35.XXX, 10.0.x.1 | VM 100 |
| VM Templates | ✓ Created | - | - | Ready for cloning |
| Ansible Control | ⧗ Planned | 110 | 10.0.110.10 | VM 110 |
| Domain Controllers | ⧗ Planned | 120 | 10.0.120.10-11 | VMs 200-201 |
| File Server | ⧗ Planned | 120 | 10.0.120.20 | VM 210 |
| Monitoring | ⧗ Planned | 110 | 10.0.110.11 | VM 111 |

**Legend:**
- ✓ Deployed and operational
- ⧗ Planned, not yet deployed
- ✗ Blocked or failed

## Quick Reference

### VLAN Summary

```
VLAN 110 (Management):    10.0.110.0/24 → Gateway: 10.0.110.1
VLAN 120 (Servers):       10.0.120.0/24 → Gateway: 10.0.120.1
VLAN 130 (Workstations):  10.0.130.0/24 → Gateway: 10.0.130.1
VLAN 140 (Guest/IoT):     10.0.140.0/24 → Gateway: 10.0.140.1
VLAN 150 (DMZ):           10.0.150.0/24 → Gateway: 10.0.150.1
```

### Lab Network

```
Lab Management: 192.168.35.0/24 → Gateway: 192.168.35.1
Proxmox Host:   192.168.35.20
OPNsense WAN:   192.168.35.XXX (DHCP)
```

### Access Points

```
Proxmox Web UI:   https://192.168.35.20:8006
OPNsense Web UI:  https://192.168.35.XXX (WAN IP)
                  https://10.0.110.1 (from management VLAN)
```

## Configuration Backups

**Location:** `~/Documents/claude/projects/smb-office-it-blueprint/backups/`

**Latest Backups:**
- Proxmox network config: `backups/network/interfaces.<timestamp>.backup`
- OPNsense config: `opnsense-config-after-migration-<date>.xml`

**Backup Schedule:** Manual (automated backups to be configured)

## Change Log

| Date | Change | Reason |
|------|--------|--------|
| 2025-12-27 | Initial network setup with VLANs 10-50 | Original plan |
| 2025-12-28 | Changed to VLANs 110-150, IPs 10.0.110+ | Avoid home lab conflicts |
| 2025-12-28 | Network deployed and verified | Migration complete |

## Next Steps

1. **Deploy Ansible Control Server** (VM 110) on VLAN 110
2. **Deploy Domain Controllers** (VMs 200-201) on VLAN 120
3. **Configure inter-VLAN firewall rules** based on security requirements
4. **Deploy monitoring server** (VM 111) on VLAN 110
5. **Create VM deployment playbooks** for automated infrastructure rollout
6. **Configure automated backups** for Proxmox and OPNsense
7. **Set up VPN access** for remote management

## Support Documentation

- **Corporate IP Scheme:** `docs/network/corporate-ip-addressing-scheme.md`
- **OPNsense Install Guide:** `docs/guides/install-opnsense.md`
- **Network Migration Guide:** `docs/guides/migrate-to-corporate-ip-scheme.md`
- **Network Activation:** `docs/guides/activate-network-configuration.md`

---

**Document Status:** Current as of 2025-12-28
**Maintained By:** SMB Office IT Blueprint Project
**Last Verified:** 2025-12-28
