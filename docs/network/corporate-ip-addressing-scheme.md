# Corporate IP Addressing Scheme

**Project:** SMB Office IT Blueprint
**Last Updated:** 2025-12-28
**Address Space:** 10.0.0.0/8 (Corporate Private Network)

## Overview

This document defines the IP addressing scheme for the SMB Office IT Blueprint corporate network. We're using the 10.0.0.0/8 private address space to align with enterprise best practices and provide room for growth.

## Design Principles

1. **Hierarchical Structure** - Site/function-based addressing
2. **Scalability** - Room for growth in each segment
3. **Summarization** - Easier routing and ACLs
4. **Documentation** - Clear, predictable addressing

## Address Space Allocation

### Top-Level Breakdown

```
10.0.0.0/8          - Overall Corporate Network
├── 10.0.0.0/16     - Headquarters/Main Site
├── 10.1.0.0/16     - Branch Office 1 (future)
├── 10.2.0.0/16     - Branch Office 2 (future)
├── 10.10.0.0/16    - Infrastructure Services
├── 10.20.0.0/16    - Data Center / Production
└── 10.100.0.0/16   - Lab/Development/Testing
```

## Main Site (HQ) - 10.0.0.0/16

### VLAN Structure

| VLAN | Network | Subnet | Gateway | DHCP Range | Purpose |
|------|---------|--------|---------|------------|---------|
| 10 | 10.0.10.0/24 | /24 (254 hosts) | 10.0.10.1 | 10.0.10.100-200 | Management |
| 20 | 10.0.20.0/24 | /24 (254 hosts) | 10.0.20.1 | 10.0.20.100-200 | Servers |
| 30 | 10.0.30.0/24 | /24 (254 hosts) | 10.0.30.1 | 10.0.30.100-200 | Workstations |
| 40 | 10.0.40.0/24 | /24 (254 hosts) | 10.0.40.1 | 10.0.40.100-200 | Guest/IoT |
| 50 | 10.0.50.0/24 | /24 (254 hosts) | 10.0.50.1 | 10.0.50.100-200 | DMZ |

### VLAN 10 - Management (10.0.10.0/24)

**Purpose:** Infrastructure management, monitoring, backups, administrative access

**Static IP Assignments:**

| IP | Hostname | Purpose |
|----|----------|---------|
| 10.0.10.1 | gw-mgmt | Default gateway (OPNsense) |
| 10.0.10.2 | pve01 | Proxmox host management interface |
| 10.0.10.10 | ansible-ctrl | Ansible control server |
| 10.0.10.11 | monitoring | Monitoring server (Zabbix/Prometheus) |
| 10.0.10.12 | backup | Backup server |
| 10.0.10.13 | jump-host | Bastion/jump server |
| 10.0.10.20 | switch-core-01 | Core switch (if managed) |
| 10.0.10.21 | switch-dist-01 | Distribution switch |
| 10.0.10.30 | ap-01 | Wireless access point 1 |
| 10.0.10.31 | ap-02 | Wireless access point 2 |
| 10.0.10.100-200 | - | DHCP pool for management devices |
| 10.0.10.254 | fw-mgmt | OPNsense management IP (alternative) |

### VLAN 20 - Servers (10.0.20.0/24)

**Purpose:** Production application servers, databases, file servers

**Static IP Assignments:**

| IP | Hostname | Purpose |
|----|----------|---------|
| 10.0.20.1 | gw-servers | Default gateway (OPNsense) |
| 10.0.20.10 | dc01 | Domain Controller 1 (Primary) |
| 10.0.20.11 | dc02 | Domain Controller 2 (Backup) |
| 10.0.20.20 | fs01 | File Server 1 |
| 10.0.20.21 | fs02 | File Server 2 |
| 10.0.20.30 | db01 | Database Server 1 (PostgreSQL/MySQL) |
| 10.0.20.31 | db02 | Database Server 2 (Secondary/Read replica) |
| 10.0.20.40 | app01 | Application Server 1 |
| 10.0.20.41 | app02 | Application Server 2 |
| 10.0.20.50 | exchange01 | Email Server (Exchange/Zimbra) |
| 10.0.20.60 | print01 | Print Server |
| 10.0.20.70 | rds01 | Remote Desktop Services/Terminal Server |
| 10.0.20.80 | sharepoint01 | SharePoint/Collaboration server |
| 10.0.20.100-200 | - | DHCP pool for additional servers |

### VLAN 30 - Workstations (10.0.30.0/24)

**Purpose:** Employee desktop computers, laptops

**Static IP Assignments:**

| IP | Hostname | Purpose |
|----|----------|---------|
| 10.0.30.1 | gw-workstations | Default gateway (OPNsense) |
| 10.0.30.10 | ws-ceo | CEO workstation (VIP) |
| 10.0.30.11 | ws-cfo | CFO workstation (VIP) |
| 10.0.30.20-50 | ws-exec-* | Executive workstations |
| 10.0.30.100-254 | - | DHCP pool for general workstations |

**Recommended:** Use DHCP reservations for VIP users to ensure consistent IPs

### VLAN 40 - Guest/IoT (10.0.40.0/24)

**Purpose:** Guest WiFi, IoT devices, cameras, printers, non-corporate devices

**Static IP Assignments:**

| IP | Hostname | Purpose |
|----|----------|---------|
| 10.0.40.1 | gw-guest | Default gateway (OPNsense) |
| 10.0.40.10 | camera-01 | Security camera 1 |
| 10.0.40.11 | camera-02 | Security camera 2 |
| 10.0.40.20 | nvr-01 | Network video recorder |
| 10.0.40.30 | iot-hub | IoT device hub |
| 10.0.40.40 | printer-floor1 | Network printer floor 1 |
| 10.0.40.41 | printer-floor2 | Network printer floor 2 |
| 10.0.40.100-254 | - | DHCP pool for guest devices |

### VLAN 50 - DMZ (10.0.50.0/24)

**Purpose:** Public-facing services, external access, web servers

**Static IP Assignments:**

| IP | Hostname | Purpose |
|----|----------|---------|
| 10.0.50.1 | gw-dmz | Default gateway (OPNsense) |
| 10.0.50.10 | web01 | Web server 1 (public site) |
| 10.0.50.11 | web02 | Web server 2 (load balanced) |
| 10.0.50.20 | vpn-gateway | VPN concentrator |
| 10.0.50.30 | mail-relay | Email relay/gateway |
| 10.0.50.40 | ftp-server | FTP/SFTP server (external access) |
| 10.0.50.50 | reverse-proxy | Reverse proxy (nginx/HAProxy) |
| 10.0.50.100-200 | - | DHCP pool for additional DMZ servers |

## Infrastructure Services - 10.10.0.0/16

Reserved for cross-site infrastructure services (future use):

| Network | Purpose |
|---------|---------|
| 10.10.10.0/24 | Core DNS/DHCP infrastructure |
| 10.10.20.0/24 | Active Directory/LDAP |
| 10.10.30.0/24 | Centralized logging |
| 10.10.40.0/24 | Central monitoring |
| 10.10.50.0/24 | Backup infrastructure |

## Data Center / Production - 10.20.0.0/16

Reserved for large production deployments (future use):

| Network | Purpose |
|---------|---------|
| 10.20.10.0/24 | Production web tier |
| 10.20.20.0/24 | Production app tier |
| 10.20.30.0/24 | Production database tier |
| 10.20.40.0/24 | Production cache/queue tier |

## Lab/Development - 10.100.0.0/16

**Current Proxmox Lab Network:**

| Network | Purpose |
|---------|---------|
| 192.168.35.0/24 | **Lab management network (vmbr0)** - Keep as-is |
| 10.100.10.0/24 | Dev/Test Management VLAN |
| 10.100.20.0/24 | Dev/Test Servers |
| 10.100.30.0/24 | Dev/Test Workstations |

**Note:** Your Proxmox host WAN connection (vmbr0) should stay on 192.168.35.0/24 since that's your physical lab network. The 10.x network is for the **virtual internal network** (vmbr1).

## Special Purpose Addresses

### Loopback Addresses (for routing/HA)

| IP | Purpose |
|----|---------|
| 10.255.255.1 | OPNsense loopback |
| 10.255.255.2 | Core router loopback |

### Point-to-Point Links

| Network | Purpose |
|---------|---------|
| 10.254.0.0/16 | Reserved for P2P links between sites |

## Network Topology Summary

```
Internet
    |
[Lab Router: 192.168.35.1]
    |
[Proxmox Host: 192.168.35.20]
    |
    +--- vmbr0 (WAN/Lab): 192.168.35.0/24
    |
    +--- vmbr1 (Corporate Internal Network)
             |
        [OPNsense VM 100]
             |
             +--- VLAN 10: 10.0.10.0/24 (Management)
             +--- VLAN 20: 10.0.20.0/24 (Servers)
             +--- VLAN 30: 10.0.30.0/24 (Workstations)
             +--- VLAN 40: 10.0.40.0/24 (Guest/IoT)
             +--- VLAN 50: 10.0.50.0/24 (DMZ)
```

## Proxmox Host Interface IPs (Updated)

The Proxmox host needs IPs on each VLAN for VM management:

| Interface | IP | Purpose |
|-----------|-----|---------|
| vmbr0 | 192.168.35.20/24 | Lab management (unchanged) |
| vmbr1 | No IP | VLAN-aware bridge |
| vmbr1.10 | 10.0.10.2/24 | Management VLAN access |
| vmbr1.20 | 10.0.20.2/24 | Server VLAN access |
| vmbr1.30 | No IP | (optional) |
| vmbr1.40 | No IP | (optional) |
| vmbr1.50 | No IP | (optional) |

## DNS Configuration

### Internal DNS Zones

| Zone | Purpose |
|------|---------|
| corp.company.local | Internal corporate domain |
| 10.0.10.in-addr.arpa | Reverse DNS for VLAN 10 |
| 20.0.10.in-addr.arpa | Reverse DNS for VLAN 20 |
| 30.0.10.in-addr.arpa | Reverse DNS for VLAN 30 |

### DNS Servers

| IP | Hostname | Role |
|----|----------|------|
| 10.0.20.10 | dc01.corp.company.local | Primary DNS (AD DC) |
| 10.0.20.11 | dc02.corp.company.local | Secondary DNS (AD DC) |
| 10.0.10.254 | fw.corp.company.local | DNS forwarder (OPNsense) |

## Migration Plan

To migrate from 192.168.x.x to 10.0.x.x:

1. **Update Proxmox vmbr1 VLAN IPs** (vmbr1.10, vmbr1.20)
2. **Reconfigure OPNsense VLAN interfaces** (10.0.10.1, 10.0.20.1, etc.)
3. **Update OPNsense DHCP scopes** for each VLAN
4. **Update firewall rules** with new IP ranges
5. **Update documentation** and diagrams
6. **Test connectivity** between VLANs

**Note:** Lab network (vmbr0: 192.168.35.0/24) remains unchanged.

## DHCP Scope Summary

| VLAN | Network | Gateway | DHCP Start | DHCP End | DNS Servers |
|------|---------|---------|------------|----------|-------------|
| 10 | 10.0.10.0/24 | 10.0.10.1 | 10.0.10.100 | 10.0.10.200 | 10.0.20.10, 10.0.20.11 |
| 20 | 10.0.20.0/24 | 10.0.20.1 | 10.0.20.100 | 10.0.20.200 | 10.0.20.10, 10.0.20.11 |
| 30 | 10.0.30.0/24 | 10.0.30.1 | 10.0.30.100 | 10.0.30.254 | 10.0.20.10, 10.0.20.11 |
| 40 | 10.0.40.0/24 | 10.0.40.1 | 10.0.40.100 | 10.0.40.254 | 10.0.10.254 (OPNsense) |
| 50 | 10.0.50.0/24 | 10.0.50.1 | 10.0.50.100 | 10.0.50.200 | 8.8.8.8, 8.8.4.4 |

## Security Zones

| Zone | VLANs | Trust Level | Internet Access | Inter-VLAN Access |
|------|-------|-------------|-----------------|-------------------|
| Trusted | 10, 20 | High | Allowed | Full to all zones |
| User | 30 | Medium | Allowed | Limited (DNS, email, file servers) |
| Untrusted | 40 | Low | Allowed | None (isolated) |
| DMZ | 50 | Medium | Allowed | Limited inbound from Internet |

## Reserved Ranges (Do Not Use)

| Range | Reason |
|-------|--------|
| 10.0.0.0/24 | Network infrastructure |
| 10.0.1.0/24 | Reserved for expansion |
| 10.0.255.0/24 | Broadcast domain |
| 10.255.255.0/24 | Loopback/special use |

## Quick Reference Card

**Management VLAN (10):** 10.0.10.0/24 → Gateway: 10.0.10.1
**Server VLAN (20):** 10.0.20.0/24 → Gateway: 10.0.20.1
**Workstation VLAN (30):** 10.0.30.0/24 → Gateway: 10.0.30.1
**Guest VLAN (40):** 10.0.40.0/24 → Gateway: 10.0.40.1
**DMZ VLAN (50):** 10.0.50.0/24 → Gateway: 10.0.50.1

**Lab Network:** 192.168.35.0/24 → Gateway: 192.168.35.1
**Proxmox Management:** 192.168.35.20

---

## Next Steps

1. Review and approve this addressing scheme
2. Update Proxmox network configuration
3. Reconfigure OPNsense with new IPs
4. Update all documentation
5. Begin deploying VMs with new addressing
