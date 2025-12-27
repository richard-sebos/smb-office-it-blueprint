# Network Architecture - SMB Office IT Blueprint

**Last Updated:** 2025-12-27

## Overview

This document describes the network architecture for the SMB Office IT Blueprint Proxmox infrastructure. The design uses an isolated internal network with VLAN segmentation, mimicking a real office environment while keeping your lab network separate and unchanged.

## Network Bridges

### vmbr0 - Lab Network Bridge (Existing - NO CHANGES)

- **Purpose:** Connection to your existing lab network
- **IP Range:** Your existing lab network (e.g., 192.168.35.x)
- **Usage:**
  - Proxmox host management interface
  - Connection to your external lab infrastructure
  - WAN interface for pfSense VM

**IMPORTANT:** This bridge is never modified by our automation. Your existing lab connectivity remains completely intact.

### vmbr1 - Internal Network Bridge (New - Created by Automation)

- **Purpose:** Isolated internal network for VM infrastructure
- **Type:** VLAN-aware Linux bridge
- **Physical Connection:** None (software bridge only)
- **Bridge Ports:** None (internal only)
- **Usage:** All internal VMs connect to VLANs on this bridge

## VLAN Segmentation (on vmbr1)

### VLAN 10 - Management Network
- **Network:** 192.168.10.0/24
- **Proxmox Host IP:** 192.168.10.1
- **Purpose:** Infrastructure management and monitoring services
- **VMs:**
  - pfSense (LAN interface): 192.168.10.254
  - Project Ansible Server: 192.168.10.10
  - Monitoring Server: 192.168.10.20

### VLAN 20 - Server Network
- **Network:** 192.168.20.0/24
- **Proxmox Host IP:** 192.168.20.1
- **Purpose:** Production application servers
- **VMs:**
  - Domain Controller: 192.168.20.10
  - File Server: 192.168.20.20
  - Backup Server: 192.168.20.30
  - Application Server: 192.168.20.40

### VLAN 30 - Workstation Network
- **Network:** 192.168.30.0/24
- **Proxmox Host IP:** None (VM-only network)
- **Purpose:** Employee workstations and devices
- **DHCP:** Provided by pfSense
- **Notes:** In a real office, this would be physical workstations. In the lab, optional test VMs.

### VLAN 40 - Guest/IoT Network
- **Network:** 192.168.40.0/24
- **Proxmox Host IP:** None (VM-only network)
- **Purpose:** Guest WiFi and IoT devices
- **DHCP:** Provided by pfSense
- **Security:** Isolated from other VLANs via pfSense firewall rules

### VLAN 50 - DMZ Network
- **Network:** 192.168.50.0/24
- **Proxmox Host IP:** None (VM-only network)
- **Purpose:** Public-facing services
- **VMs:**
  - Web Server: 192.168.50.10
  - Mail Server: 192.168.50.20
- **Security:** Heavily restricted via pfSense firewall rules

## Network Flow

```
┌─────────────────────────────────────────────────────────────────┐
│                      Your Lab Network                           │
│                    (192.168.35.0/24)                            │
│                                                                 │
│   Lab Router ◄──── vmbr0 ◄──── Proxmox Management             │
│                       │                                         │
│                       │                                         │
│                   [pfSense VM]                                  │
│                  WAN: vmbr0                                     │
│                  LAN: vmbr1.10                                  │
│                       │                                         │
└───────────────────────┼─────────────────────────────────────────┘
                        │
                        ▼
┌─────────────────────────────────────────────────────────────────┐
│                  vmbr1 (Internal Isolated Network)              │
│                                                                 │
│  ┌──────────────┬────────────┬─────────────┬────────┬────────┐ │
│  │   VLAN 10    │  VLAN 20   │  VLAN 30    │ VLAN 40│ VLAN 50│ │
│  │  Management  │  Servers   │ Workstations│ Guest  │  DMZ   │ │
│  │              │            │             │  /IoT  │        │ │
│  ├──────────────┼────────────┼─────────────┼────────┼────────┤ │
│  │ .10.1 (PVE)  │ .20.1 (PVE)│ VM-only     │VM-only │VM-only │ │
│  │ .10.254(pf)  │            │             │        │        │ │
│  │              │            │             │        │        │ │
│  │ Ansible      │ AD Server  │ (Optional)  │(Future)│Web/Mail│ │
│  │ Monitoring   │ File Srv   │             │        │        │ │
│  │              │ Backup Srv │             │        │        │ │
│  └──────────────┴────────────┴─────────────┴────────┴────────┘ │
└─────────────────────────────────────────────────────────────────┘
```

## Routing and NAT

### pfSense Firewall VM

The pfSense VM acts as the central router and firewall for the internal network:

**Interfaces:**
- **WAN (vmbr0):** Connected to your lab network - gets IP via DHCP or static
- **LAN (vmbr1.10):** 192.168.10.254 - Default gateway for management network
- **OPT1-OPT4 (vmbr1.20/30/40/50):** Additional VLAN interfaces as needed

**Functions:**
1. **NAT:** Translates internal IPs (192.168.x.x) to lab network for internet access
2. **Firewall:** Controls traffic between VLANs
3. **DHCP:** Provides DHCP for workstation, guest, and DMZ networks
4. **DNS:** DNS forwarding/caching for internal network
5. **VPN:** (Optional) Remote access to internal networks

### Inter-VLAN Routing

All traffic between VLANs must pass through pfSense:

**Default Rules:**
- Management (VLAN 10) → All other VLANs: ALLOW
- Servers (VLAN 20) → Management (VLAN 10): ALLOW
- Servers (VLAN 20) → Internet: ALLOW
- Workstations (VLAN 30) → Internet: ALLOW
- Workstations (VLAN 30) → Servers (VLAN 20): ALLOW (specific ports)
- Guest/IoT (VLAN 40) → Internet only: ALLOW (isolated from all internal VLANs)
- DMZ (VLAN 50) → Internet: ALLOW (heavily restricted inbound/outbound)

## Proxmox Host Access

The Proxmox host itself has IPs on multiple VLANs to facilitate management and monitoring:

- **vmbr0:** Your lab IP (e.g., 192.168.35.20) - Primary management
- **vmbr1.10:** 192.168.10.1 - Management VLAN access
- **vmbr1.20:** 192.168.20.1 - Server VLAN access

This allows:
- Monitoring tools to reach Proxmox API from inside the network
- Backup systems to access Proxmox storage
- SSH access from management network

## Real Office vs Lab Differences

| Aspect | Real Office | This Lab |
|--------|-------------|----------|
| Physical Network | Multiple switches with VLAN trunking | Single Proxmox host, software VLANs |
| Workstations | Real PCs on VLAN 30 | Optional VMs (or skip this VLAN) |
| Guest WiFi | Access points on VLAN 40 | Optional test VMs |
| Internet | Direct connection via ISP | Lab router provides internet |
| WAN | Direct to ISP modem/router | vmbr0 to your lab network |
| Redundancy | Multiple servers, HA | Single Proxmox host |

**The architecture remains identical** - only the physical implementation differs. This makes it a perfect learning/testing environment for real office deployments.

## Security Zones

### Trusted Zone (Management - VLAN 10)
- Full access to all systems
- Infrastructure management tools
- Monitoring and automation systems

### Internal Zone (Servers - VLAN 20)
- Production services
- Internal applications
- File and backup storage

### User Zone (Workstations - VLAN 30)
- Employee devices
- Restricted access to servers (specific ports only)

### Untrusted Zone (Guest/IoT - VLAN 40)
- No access to internal resources
- Internet access only
- Heavily monitored

### DMZ (Public Services - VLAN 50)
- Public-facing services
- Restricted outbound access
- Heavily firewalled inbound/outbound

## Implementation Steps

1. **Phase 1: Network Configuration** (This playbook)
   - Create vmbr1 bridge on Proxmox host
   - Create VLAN interfaces
   - Configure Proxmox host IPs

2. **Phase 2: pfSense Deployment**
   - Create pfSense VM with two interfaces (vmbr0 + vmbr1)
   - Configure WAN on vmbr0
   - Configure LAN on vmbr1.10 as 192.168.10.254
   - Set up additional VLAN interfaces
   - Configure NAT and basic firewall rules

3. **Phase 3: VM Deployment**
   - Deploy VMs to appropriate VLANs
   - Configure static IPs or DHCP
   - Set default gateway to pfSense

4. **Phase 4: Firewall Hardening**
   - Implement inter-VLAN firewall rules
   - Enable logging and monitoring
   - Configure IDS/IPS (optional)

## Troubleshooting

### VMs Can't Reach Internet
1. Check pfSense WAN interface has connectivity to lab network
2. Verify NAT is enabled on pfSense
3. Check VM default gateway points to pfSense
4. Verify DNS is configured (use 8.8.8.8 or pfSense as DNS server)

### VMs Can't Communicate Between VLANs
1. Verify pfSense has interfaces on both VLANs
2. Check firewall rules allow traffic between VLANs
3. Ensure VMs have correct VLAN tags in Proxmox

### Can't Reach Proxmox Management
1. vmbr0 should remain your primary management interface
2. Verify vmbr0 IP is still accessible from your lab network
3. pfSense should NOT interfere with vmbr0 traffic

### VLANs Not Working
1. Verify vmbr1 has `bridge-vlan-aware yes` set
2. Check `ip link show` to see VLAN interfaces are created
3. Run `ifreload -a` to apply network configuration
4. Check VM network settings have correct VLAN tag

## Next Steps

After network configuration is complete:

1. **Deploy pfSense VM** - Create firewall/router VM
2. **Configure pfSense** - Set up interfaces, NAT, DHCP, firewall rules
3. **Test Connectivity** - Verify all VLANs can reach internet through pfSense
4. **Deploy Infrastructure VMs** - Ansible, monitoring, etc. on VLAN 10
5. **Deploy Server VMs** - AD, file server, etc. on VLAN 20
6. **Harden Security** - Fine-tune firewall rules, enable logging

## References

- [Proxmox VE Network Configuration](https://pve.proxmox.com/wiki/Network_Configuration)
- [pfSense Documentation](https://docs.netgate.com/pfsense/en/latest/)
- [VLAN Best Practices](https://www.cisco.com/c/en/us/support/docs/lan-switching/vlan/10023-29.html)
