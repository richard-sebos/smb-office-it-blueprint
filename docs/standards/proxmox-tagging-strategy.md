# Proxmox VM Tagging Strategy

**Project:** SMB Office IT Blueprint
**Last Updated:** 2025-12-28
**Purpose:** Standardized tagging system for VM organization and management

## Overview

Proxmox tags provide a powerful way to organize, filter, and manage VMs. This document defines the standard tagging strategy for the SMB Office IT Blueprint project.

## Tag Format

**Format:** Tags are separated by semicolons (`;`)

**Example:** `production;web-server;linux;vlan-120`

**Rules:**
- Use lowercase
- Use hyphens for multi-word tags (not underscores or spaces)
- Be consistent and descriptive
- Maximum 5-7 tags per VM (keep it manageable)

## Tag Categories

### 1. Environment Tags

Identifies the VM's operational environment:

| Tag | Description | Usage |
|-----|-------------|-------|
| `production` | Production workloads | Critical services |
| `development` | Development/testing | Dev/test environments |
| `staging` | Pre-production testing | QA, UAT |
| `infrastructure` | Core infrastructure | DNS, DHCP, monitoring |
| `lab` | Lab/experimental | Testing, learning |

**Example:** `production;web-server`

### 2. Function Tags

Describes what the VM does:

| Tag | Description | VMs |
|-----|-------------|-----|
| `domain-controller` | Active Directory DC | dc01, dc02 |
| `file-server` | File/storage server | fs01 |
| `database` | Database server | db01, db02 |
| `web-server` | Web server | web01, web02 |
| `app-server` | Application server | app01 |
| `automation` | Automation/orchestration | ansible-ctrl |
| `monitoring` | Monitoring/alerting | monitoring |
| `backup` | Backup server | backup |
| `dns` | DNS server | dc01, dc02 |
| `dhcp` | DHCP server | dc01, dc02 |
| `mail-server` | Email server | exchange01 |
| `vpn` | VPN gateway | vpn-gateway |
| `proxy` | Reverse proxy | reverse-proxy |
| `firewall` | Firewall VM | opnsense |

**Example:** `production;domain-controller;dns;dhcp`

### 3. Operating System Tags

Identifies the OS family:

| Tag | Description |
|-----|-------------|
| `linux` | Any Linux distribution |
| `ubuntu` | Ubuntu |
| `debian` | Debian |
| `rocky` | Rocky Linux |
| `centos` | CentOS |
| `rhel` | Red Hat Enterprise Linux |
| `windows` | Windows Server |
| `bsd` | FreeBSD/OpenBSD |

**Example:** `production;web-server;debian`

### 4. Network/VLAN Tags

Identifies which VLAN the VM is on:

| Tag | Description | Network |
|-----|-------------|---------|
| `vlan-110` | Management VLAN | 10.0.110.0/24 |
| `vlan-120` | Server VLAN | 10.0.120.0/24 |
| `vlan-130` | Workstation VLAN | 10.0.130.0/24 |
| `vlan-140` | Guest/IoT VLAN | 10.0.140.0/24 |
| `vlan-150` | DMZ VLAN | 10.0.150.0/24 |

**Example:** `production;web-server;vlan-150`

### 5. Role Tags

Identifies primary vs backup/replica:

| Tag | Description |
|-----|-------------|
| `primary` | Primary/master role |
| `replica` | Replica/backup role |
| `standby` | Hot standby |
| `cluster-member` | Part of a cluster |

**Example:** `production;domain-controller;primary`

### 6. Service Tags

Identifies specific services running:

| Tag | Description |
|-----|-------------|
| `dns` | DNS service |
| `dhcp` | DHCP service |
| `ntp` | NTP time service |
| `ldap` | LDAP directory |
| `active-directory` | AD domain services |
| `postgresql` | PostgreSQL database |
| `mysql` | MySQL database |
| `nginx` | Nginx web server |
| `apache` | Apache web server |

**Example:** `production;database;postgresql`

### 7. Compliance/Security Tags

For compliance and security classification:

| Tag | Description |
|-----|-------------|
| `pci-dss` | PCI DSS compliance required |
| `hipaa` | HIPAA compliance required |
| `gdpr` | GDPR compliance required |
| `sensitive-data` | Contains sensitive data |
| `public-facing` | Internet-accessible |
| `isolated` | Network isolated |

**Example:** `production;database;sensitive-data;pci-dss`

### 8. Maintenance Tags

For operational management:

| Tag | Description |
|-----|-------------|
| `auto-backup` | Automated backups enabled |
| `monitored` | Under monitoring |
| `auto-update` | Automatic updates enabled |
| `manual-update` | Manual updates only |
| `high-availability` | HA configured |

**Example:** `production;database;auto-backup;monitored`

## Standard Tag Combinations by VM Type

### Infrastructure VMs

**Ansible Control Server:**
```
infrastructure;automation;management;ubuntu;vlan-110
```

**Monitoring Server:**
```
infrastructure;monitoring;management;ubuntu;vlan-110;auto-backup
```

**Backup Server:**
```
infrastructure;backup;storage;debian;vlan-110;auto-backup
```

**Jump/Bastion Host:**
```
infrastructure;bastion;security;ubuntu;vlan-110;monitored
```

### Production Servers

**Primary Domain Controller:**
```
production;domain-controller;dns;dhcp;active-directory;primary;debian;vlan-120;auto-backup;monitored
```

**Replica Domain Controller:**
```
production;domain-controller;dns;dhcp;active-directory;replica;debian;vlan-120;auto-backup;monitored
```

**File Server:**
```
production;file-server;storage;ubuntu;vlan-120;auto-backup;monitored
```

**Database Server (Primary):**
```
production;database;postgresql;primary;debian;vlan-120;auto-backup;monitored;sensitive-data
```

**Database Server (Replica):**
```
production;database;postgresql;replica;debian;vlan-120;auto-backup;monitored;sensitive-data
```

**Application Server:**
```
production;app-server;web-server;nginx;ubuntu;vlan-120;monitored
```

**Email Server:**
```
production;mail-server;ubuntu;vlan-120;auto-backup;monitored
```

### DMZ Servers

**Web Server (Public):**
```
production;web-server;nginx;public-facing;ubuntu;vlan-150;monitored;auto-update
```

**VPN Gateway:**
```
infrastructure;vpn;security;debian;vlan-150;monitored
```

**Mail Relay:**
```
production;mail-relay;public-facing;ubuntu;vlan-150;monitored
```

### Workstation VMs

**Standard Workstation:**
```
workstation;end-user;windows;vlan-130;auto-update
```

**Admin Workstation:**
```
workstation;admin;privileged-access;windows;vlan-110;monitored
```

## Tag Usage in Proxmox

### Setting Tags via CLI

```bash
# Set tags on a VM
qm set 110 --tags "infrastructure;automation;management"

# Add to existing tags (append)
qm set 110 --tags "infrastructure;automation;management;ubuntu"

# View VM tags
qm config 110 | grep tags
```

### Setting Tags via Ansible

```yaml
- name: Apply Proxmox tags
  shell: |
    qm set {{ item.vmid }} --tags "{{ item.proxmox_tags }}"
  loop: "{{ vms }}"
```

### Viewing Tags in Proxmox Web UI

1. Navigate: **Datacenter → pve → VM**
2. Tags appear in the VM list
3. Click on a tag to filter VMs by that tag
4. Use tag colors for quick visual identification

## Tag Filtering and Search

### Via Web UI

**Filter by tag:**
1. Click any tag in VM list
2. All VMs with that tag are shown

**Search by tag:**
1. Use search box at top
2. Type tag name
3. Results filtered automatically

### Via CLI

```bash
# List all VMs with a specific tag
pvesh get /cluster/resources --type vm | grep -i "production"

# Using qm list with filtering
qm list | grep "110\|120\|130"
```

## Best Practices

### 1. Consistency

- Always use lowercase
- Use hyphens, not underscores
- Use same terminology across all VMs

### 2. Meaningful Tags

- Tags should describe the VM clearly
- Avoid cryptic abbreviations
- Think about how you'll search/filter

### 3. Tag Limit

- Use 5-7 tags maximum per VM
- Too many tags = harder to manage
- Focus on the most important characteristics

### 4. Update Tags

- Update tags when VM role changes
- Remove obsolete tags
- Keep tags current with VM's actual state

### 5. Document Custom Tags

- If you create new tags, document them here
- Share tagging conventions with team
- Review and standardize periodically

## Tag Hierarchy Example

For a production database server:

```
Priority 1 (Must Have):
  - production         (Environment)
  - database          (Function)
  - postgresql        (Service)

Priority 2 (Should Have):
  - vlan-120          (Network)
  - debian            (OS)
  - primary           (Role)

Priority 3 (Nice to Have):
  - auto-backup       (Maintenance)
  - monitored         (Maintenance)
  - sensitive-data    (Security)
```

**Final tag string:**
```
production;database;postgresql;primary;debian;vlan-120;auto-backup;monitored
```

## Tag Color Coding (Proxmox Web UI)

Proxmox displays tags with different colors for visual identification:

- **Blue:** Infrastructure tags
- **Green:** Production tags
- **Orange:** Development/staging tags
- **Red:** Security/compliance tags
- **Gray:** Operational tags

**Note:** Colors are auto-assigned by Proxmox based on tag hash.

## Automation Examples

### Backup All Production VMs

```bash
#!/bin/bash
# Backup all VMs tagged with 'production'

for vmid in $(pvesh get /cluster/resources --type vm --output-format json | jq -r '.[] | select(.tags | contains("production")) | .vmid'); do
    vzdump $vmid --mode snapshot --compress zstd
done
```

### Stop All Development VMs

```bash
#!/bin/bash
# Stop all VMs tagged with 'development'

for vmid in $(pvesh get /cluster/resources --type vm --output-format json | jq -r '.[] | select(.tags | contains("development")) | .vmid'); do
    qm stop $vmid
done
```

### Generate Report of VMs by VLAN

```bash
#!/bin/bash
# List all VMs on VLAN 120

pvesh get /cluster/resources --type vm --output-format json | \
  jq -r '.[] | select(.tags | contains("vlan-120")) | "\(.vmid) \(.name) \(.tags)"'
```

## Tag Migration

If you need to update tags across many VMs:

```bash
#!/bin/bash
# Example: Add 'monitored' tag to all production VMs

for vmid in $(pvesh get /cluster/resources --type vm --output-format json | jq -r '.[] | select(.tags | contains("production")) | .vmid'); do
    current_tags=$(qm config $vmid | grep "^tags:" | cut -d' ' -f2)
    new_tags="${current_tags};monitored"
    qm set $vmid --tags "$new_tags"
    echo "Updated VM $vmid: $new_tags"
done
```

## Quick Reference

**Common Tag Patterns:**

| VM Type | Tags |
|---------|------|
| Infrastructure | `infrastructure;[function];[os];vlan-110` |
| Production Server | `production;[function];[service];[os];vlan-120` |
| Workstation | `workstation;[role];[os];vlan-130` |
| Guest/IoT | `guest;[device-type];vlan-140` |
| DMZ | `production;[function];public-facing;vlan-150` |

---

**Tagging Strategy Version:** 1.0
**Last Review:** 2025-12-28
**Next Review:** Quarterly or as needed
