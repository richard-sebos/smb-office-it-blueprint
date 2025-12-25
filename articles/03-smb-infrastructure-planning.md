---
title: "Planning an SMB Office Infrastructure on Proxmox: 11-VM Architecture"
description: "Detailed planning guide for building a complete small business IT infrastructure on Proxmox - domain controllers, file servers, workstations, and management systems with specific resource allocations."
---

# Planning an SMB Office Infrastructure on Proxmox: 11-VM Architecture

## From Theory to Practice: A Real Office Environment

In the previous article, we covered universal Proxmox best practices. Now we're applying those principles to build something concrete: **a complete small business IT infrastructure**.

This isn't a toy example. We're modeling a realistic 30-person office with:
- **Departments:** HR, Finance, Operations, Executive
- **Real workflows:** Employee onboarding, role-based access, compliance requirements
- **Production patterns:** Redundant domain controllers, departmental file shares, security hardening
- **Business needs:** Cost tracking, audit trails, separation of duties

By the end of this article, you'll have complete specifications for an 11-VM environment that replicates real-world business IT.

## The Business Context

### Simulated Organization Profile

**Company:** Medium-sized professional services firm
**Employees:** 30 people
**Departments:**
- HR (3 people)
- Finance (4 people)
- Operations/Projects (18 people)
- Executive/Management (3 people)
- IT (2 people)

**IT Requirements:**
- Centralized user authentication (like Active Directory)
- Departmental file shares with access controls
- Role-based permissions (HR sees HR files, Finance sees Finance files)
- Audit logging for compliance
- Automated employee onboarding/offboarding
- Cost-effective licensing (no Windows Server fees)

**Technology Choice:** Linux + Samba AD + Proxmox (zero licensing costs)

## The 11-VM Architecture

### Architecture Overview

Our environment consists of four layers:

**1. Directory Services Layer (Critical)**
- DC01 - Primary Samba AD Domain Controller
- DC02 - Secondary Domain Controller (redundancy)

**2. Infrastructure Services Layer (High Priority)**
- FILES01 - File server with departmental shares
- PRINT01 - Print server (CUPS)
- MGMT01 - Management/Ansible control node

**3. Workstation Layer (Department-Specific)**
- ADMIN-WS01 - Admin Assistant workstation
- HR-WS01 - HR Manager workstation
- FIN-WS01 - Finance Manager workstation
- EXEC-WS01 - Executive workstation
- PROJ-WS01 - Project professional workstation
- INTERN-WS01 - Intern/temporary worker workstation

**Why This Architecture?**

✅ **Realistic Complexity** - Represents real business needs, not simplified examples
✅ **Redundancy** - Dual domain controllers prevent single point of failure
✅ **Separation** - Each department has representative workstation
✅ **Scalability** - Easy to add more users to each department
✅ **Security** - Role-based access matches business structure

## Detailed VM Specifications

### Domain Controllers (DC01, DC02)

**Business Purpose:**
- Centralized user authentication (like Active Directory)
- DNS services for the domain
- Kerberos authentication
- Group Policy management

**Why Two Domain Controllers?**
- **Redundancy:** If DC01 fails, DC02 continues authentication
- **Load Balancing:** Users distribute across both DCs
- **Maintenance:** Can update/reboot one while other serves users
- **Best Practice:** Never run a business on single DC

**Technical Specifications:**

| Resource | DC01 | DC02 | Reasoning |
|----------|------|------|-----------|
| VM ID | 111 | 112 | 110-119 range for domain controllers |
| vCPU | 2 cores | 2 cores | AD is mostly single-threaded; 2 handles concurrent auth |
| RAM | 2GB | 2GB | Samba AD + DNS + Kerberos; generous for <100 users |
| Disk | 32GB | 32GB | OS (20GB) + AD database (5GB) + logs (5GB) |
| Network | vmbr1, VLAN 20 | vmbr1, VLAN 20 | Server network segment |
| IP Address | 10.0.20.11 | 10.0.20.12 | Static IPs, sequential |
| OS | Oracle Linux 9 | Oracle Linux 9 | RHEL-compatible, enterprise support |
| Priority | CRITICAL | CRITICAL | Must stay running |
| Backup | Daily | Daily | 7-day retention |

**Configuration Settings:**

```bash
# DC01 creation
qm clone 100 111 --name DC01 --full --pool infrastructure
qm set 111 --cores 2 --memory 2048 --balloon 0
qm set 111 --scsi0 local-lvm:32,cache=none,discard=on,iothread=1,ssd=1
qm set 111 --net0 virtio,bridge=vmbr1,tag=20,queues=2
qm set 111 --cpu host --cpuunits 2048
qm set 111 --tags "domain-controller,critical,backup-daily,oracle-linux-9"
qm set 111 --ipconfig0 ip=10.0.20.11/24,gw=10.0.20.1

# DC02 creation (same settings, different IP)
qm clone 100 112 --name DC02 --full --pool infrastructure
qm set 112 --cores 2 --memory 2048 --balloon 0
qm set 112 --scsi0 local-lvm:32,cache=none,discard=on,iothread=1,ssd=1
qm set 112 --net0 virtio,bridge=vmbr1,tag=20,queues=2
qm set 112 --cpu host --cpuunits 2048
qm set 112 --tags "domain-controller,critical,backup-daily,oracle-linux-9"
qm set 112 --ipconfig0 ip=10.0.20.12/24,gw=10.0.20.1
```

**Services Running:**
- Samba AD (Active Directory)
- DNS (BIND or Samba internal DNS)
- Kerberos (authentication)
- LDAP (directory queries)

**Domain:** smboffice.local

### File Server (FILES01)

**Business Purpose:**
- Departmental file shares (HR, Finance, Projects, Shared)
- Centralized document storage
- Access control by department/role
- Audit logging (who accessed what)

**File Share Structure:**

```
/srv/samba/shares/
├── hr/                    # HR Department only
│   ├── personnel/         # Employee files
│   ├── evaluations/       # Performance reviews
│   └── onboarding/        # New hire docs
├── finance/               # Finance Department only
│   ├── accounting/        # GL, AP, AR
│   ├── payroll/           # Payroll data
│   └── reports/           # Financial reports
├── projects/              # Project team
│   ├── deliverables/      # Client deliverables
│   ├── internal/          # Internal projects
│   └── templates/         # Project templates
├── company/               # All employees (read-only)
│   ├── policies/          # Company policies
│   ├── handbooks/         # Employee handbook
│   └── forms/             # Standard forms
└── executives/            # Executive team only
    ├── board/             # Board documents
    └── strategic/         # Strategic planning
```

**Technical Specifications:**

| Resource | Value | Reasoning |
|----------|-------|-----------|
| VM ID | 121 | 120-129 range for infrastructure services |
| vCPU | 4 cores | Samba benefits from multiple cores for concurrent users |
| RAM | 4GB | 2GB OS, 2GB for Samba + file caching |
| Disk | 100GB | OS (20GB) + shares (60GB) + growth (20GB) |
| Network | vmbr1, VLAN 20 | Server network segment |
| IP Address | 10.0.20.21 | Static IP |
| OS | Oracle Linux 9 | RHEL-compatible |
| Priority | HIGH | Critical for daily operations |
| Backup | Daily | 7-day retention, includes all shares |

**Configuration:**

```bash
qm clone 100 121 --name FILES01 --full --pool infrastructure
qm set 121 --cores 4 --memory 4096 --balloon 0
qm set 121 --scsi0 local-lvm:100,cache=writethrough,discard=on,iothread=1,ssd=1
qm set 121 --net0 virtio,bridge=vmbr1,tag=20,queues=4
qm set 121 --cpu host --cpuunits 1536
qm set 121 --tags "file-server,high,backup-daily,oracle-linux-9"
qm set 121 --ipconfig0 ip=10.0.20.21/24,gw=10.0.20.1
```

**Access Control Example:**
- HR group can read/write /srv/samba/shares/hr/
- Finance group can read/write /srv/samba/shares/finance/
- Everyone can read /srv/samba/shares/company/
- Audit logs track all file access

### Print Server (PRINT01)

**Business Purpose:**
- Centralized print queue management
- Department-specific printers (e.g., Finance-only printer)
- Print job accounting
- Driver management

**Technical Specifications:**

| Resource | Value | Reasoning |
|----------|-------|-----------|
| VM ID | 122 | 120-129 range for infrastructure |
| vCPU | 2 cores | Print spooling is lightweight |
| RAM | 2GB | CUPS + print queue buffers |
| Disk | 32GB | OS (20GB) + spool space (10GB) |
| Network | vmbr1, VLAN 20 | Server network |
| IP Address | 10.0.20.22 | Static IP |
| OS | Oracle Linux 9 | RHEL-compatible |
| Priority | MEDIUM | Important but not critical |
| Backup | Weekly | 4-week retention |

**Configuration:**

```bash
qm clone 100 122 --name PRINT01 --full --pool infrastructure
qm set 122 --cores 2 --memory 2048 --balloon 512
qm set 122 --scsi0 local-lvm:32,cache=writethrough,discard=on,iothread=1,ssd=1
qm set 122 --net0 virtio,bridge=vmbr1,tag=20,queues=2
qm set 122 --cpu host --cpuunits 1024
qm set 122 --tags "print-server,medium,backup-weekly,oracle-linux-9"
qm set 122 --ipconfig0 ip=10.0.20.22/24,gw=10.0.20.1
```

### Management Node (MGMT01)

**Business Purpose:**
- Ansible control node (infrastructure automation)
- Monitoring and alerting
- Backup scripts and validation
- Administrative tools

**Technical Specifications:**

| Resource | Value | Reasoning |
|----------|-------|-----------|
| VM ID | 181 | 180-189 range for management |
| vCPU | 2 cores | Script execution, Ansible playbooks |
| RAM | 3GB | Ansible + monitoring (can increase to 6GB for Prometheus/Grafana) |
| Disk | 40GB | OS (20GB) + Ansible roles (5GB) + logs (15GB) |
| Network | vmbr0, VLAN 10 | Management network |
| IP Address | 10.0.10.20 | Static IP on management VLAN |
| OS | Oracle Linux 9 | Consistency with other servers |
| Priority | HIGH | Needed for automation and monitoring |
| Backup | Daily | Critical for disaster recovery |

**Configuration:**

```bash
qm clone 100 181 --name MGMT01 --full --pool management
qm set 181 --cores 2 --memory 3072 --balloon 0
qm set 181 --scsi0 local-lvm:40,cache=writethrough,discard=on,iothread=1,ssd=1
qm set 181 --net0 virtio,bridge=vmbr0,tag=10,queues=2
qm set 181 --cpu host --cpuunits 1536
qm set 181 --tags "management,high,backup-daily,oracle-linux-9"
qm set 181 --ipconfig0 ip=10.0.10.20/24,gw=10.0.10.1
```

## Workstation VMs

All workstations run **Ubuntu 22.04 LTS Desktop** and are domain-joined via SSSD.

### Admin Assistant Workstation (ADMIN-WS01)

**Business Role:**
- General office administration
- Schedule management
- Document preparation
- Reception duties

**Access Needs:**
- Company shared folder (read)
- Shared services (calendars, printers)
- Email and office applications
- No access to HR/Finance confidential data

**Technical Specifications:**

| Resource | Value |
|----------|-------|
| VM ID | 131 |
| vCPU | 2 cores |
| RAM | 2GB |
| Disk | 32GB |
| Network | vmbr2, VLAN 30 |
| IP | 10.0.30.31 |
| OS | Ubuntu 22.04 Desktop |
| Priority | MEDIUM |
| Backup | Weekly |

**Configuration:**

```bash
qm clone 101 131 --name ADMIN-WS01 --full --pool workstations-admin
qm set 131 --cores 2 --memory 2048 --balloon 1536
qm set 131 --scsi0 local-lvm:32,cache=writethrough,discard=on,iothread=1,ssd=1
qm set 131 --net0 virtio,bridge=vmbr2,tag=30,queues=2
qm set 131 --cpu host --cpuunits 1024
qm set 131 --tags "workstation,dept-admin,medium,backup-weekly,ubuntu-22.04"
qm set 131 --ipconfig0 ip=10.0.30.31/24,gw=10.0.30.1
```

### HR Manager Workstation (HR-WS01)

**Business Role:**
- Human resources management
- Employee records access
- Recruitment and onboarding
- Performance evaluations

**Access Needs:**
- HR file share (read/write)
- Employee database
- Company shared folder (read)
- No access to Finance data

**Technical Specifications:**

| Resource | Value | Notes |
|----------|-------|-------|
| VM ID | 142 | 140-149 range for HR workstations |
| vCPU | 2 cores | Standard office workload |
| RAM | 3GB | HR software + documents |
| Disk | 32GB | Minimal local storage (files on server) |
| Priority | MEDIUM | Important but workstation can be rebuilt |

**Configuration:**

```bash
qm clone 101 142 --name HR-WS01 --full --pool workstations-hr
qm set 142 --cores 2 --memory 3072 --balloon 2048
qm set 142 --scsi0 local-lvm:32,cache=writethrough,discard=on,iothread=1,ssd=1
qm set 142 --net0 virtio,bridge=vmbr2,tag=30,queues=2
qm set 142 --tags "workstation,dept-hr,medium,backup-weekly,ubuntu-22.04"
qm set 142 --ipconfig0 ip=10.0.30.42/24,gw=10.0.30.1
```

### Finance Manager Workstation (FIN-WS01)

**Business Role:**
- Financial management
- Accounting and bookkeeping
- Payroll processing
- Financial reporting

**Access Needs:**
- Finance file share (read/write)
- Accounting software
- Payroll systems
- No access to HR personnel data

**Technical Specifications:**

| Resource | Value | Notes |
|----------|-------|-------|
| VM ID | 153 | 150-159 range for Finance workstations |
| vCPU | 2 cores | Accounting software can be CPU-intensive |
| RAM | 4GB | QuickBooks/accounting apps need RAM |
| Disk | 32GB | Files stored on server |
| Priority | HIGH | Financial operations critical |

**Configuration:**

```bash
qm clone 101 153 --name FIN-WS01 --full --pool workstations-finance
qm set 153 --cores 2 --memory 4096 --balloon 3072
qm set 153 --scsi0 local-lvm:32,cache=writethrough,discard=on,iothread=1,ssd=1
qm set 153 --net0 virtio,bridge=vmbr2,tag=30,queues=2
qm set 153 --cpu host --cpuunits 1536
qm set 153 --tags "workstation,dept-finance,high,backup-weekly,ubuntu-22.04"
qm set 153 --ipconfig0 ip=10.0.30.53/24,gw=10.0.30.1
```

### Executive Workstation (EXEC-WS01)

**Business Role:**
- Executive/managing partner
- Strategic planning
- Board materials
- Company-wide access (with discretion)

**Access Needs:**
- Executive file share (read/write)
- All other shares (read-only for oversight)
- Email, calendar, documents
- Video conferencing

**Technical Specifications:**

| Resource | Value | Notes |
|----------|-------|-------|
| VM ID | 134 | Admin/exec range |
| vCPU | 4 cores | Smooth experience, multiple apps |
| RAM | 4GB | No lag, executive user experience |
| Disk | 40GB | Some local storage for convenience |
| Priority | HIGH | Executive can't tolerate performance issues |

**Configuration:**

```bash
qm clone 101 134 --name EXEC-WS01 --full --pool workstations-admin
qm set 134 --cores 4 --memory 4096 --balloon 0
qm set 134 --scsi0 local-lvm:40,cache=writethrough,discard=on,iothread=1,ssd=1
qm set 134 --net0 virtio,bridge=vmbr2,tag=30,queues=4
qm set 134 --cpu host --cpuunits 2048
qm set 134 --tags "workstation,dept-admin,high,backup-weekly,ubuntu-22.04"
qm set 134 --ipconfig0 ip=10.0.30.34/24,gw=10.0.30.1
```

### Project Professional Workstation (PROJ-WS01)

**Business Role:**
- Consulting/project delivery
- Client documentation
- Project management
- Internal collaboration

**Access Needs:**
- Project file share (read/write)
- Company shared folder (read)
- Project-specific folders (assigned per project)
- No access to HR/Finance confidential data

**Technical Specifications:**

| Resource | Value | Notes |
|----------|-------|-------|
| VM ID | 165 | 160-169 range for project workstations |
| vCPU | 2 cores | Standard professional workload |
| RAM | 3GB | Project tools + documents |
| Disk | 32GB | Files on server |
| Priority | MEDIUM | Important but can tolerate brief downtime |

**Configuration:**

```bash
qm clone 101 165 --name PROJ-WS01 --full --pool workstations-projects
qm set 165 --cores 2 --memory 3072 --balloon 2048
qm set 165 --scsi0 local-lvm:32,cache=writethrough,discard=on,iothread=1,ssd=1
qm set 165 --net0 virtio,bridge=vmbr2,tag=30,queues=2
qm set 165 --tags "workstation,dept-projects,medium,backup-weekly,ubuntu-22.04"
qm set 165 --ipconfig0 ip=10.0.30.65/24,gw=10.0.30.1
```

### Intern Workstation (INTERN-WS01)

**Business Role:**
- Temporary/intern employee
- Limited access
- Training and learning
- Time-limited engagement

**Access Needs:**
- Intern working folder (read/write)
- Company shared folder (read)
- No access to confidential data
- Account expires automatically (90 days)

**Technical Specifications:**

| Resource | Value | Notes |
|----------|-------|-------|
| VM ID | 176 | 170-179 range for temporary workstations |
| vCPU | 2 cores | Minimal but functional |
| RAM | 2GB | Basic office tasks |
| Disk | 32GB | Minimal local storage |
| Priority | LOW | Can be stopped for maintenance |

**Configuration:**

```bash
qm clone 101 176 --name INTERN-WS01 --full --pool workstations-temp
qm set 176 --cores 2 --memory 2048 --balloon 1536
qm set 176 --scsi0 local-lvm:32,cache=writethrough,discard=on,iothread=1,ssd=1
qm set 176 --net0 virtio,bridge=vmbr2,tag=30,queues=2
qm set 176 --cpu host --cpuunits 512
qm set 176 --tags "workstation,dept-temp,low,backup-monthly,ubuntu-22.04"
qm set 176 --ipconfig0 ip=10.0.30.76/24,gw=10.0.30.1
```

## Complete Resource Matrix

### Summary Table

| VM Name | ID | vCPU | RAM | Disk | VLAN | IP | Priority | Backup |
|---------|----|----|-----|------|------|-------|----------|--------|
| **Infrastructure** |
| DC01 | 111 | 2 | 2GB | 32GB | 20 | 10.0.20.11 | CRITICAL | Daily |
| DC02 | 112 | 2 | 2GB | 32GB | 20 | 10.0.20.12 | CRITICAL | Daily |
| FILES01 | 121 | 4 | 4GB | 100GB | 20 | 10.0.20.21 | HIGH | Daily |
| PRINT01 | 122 | 2 | 2GB | 32GB | 20 | 10.0.20.22 | MEDIUM | Weekly |
| MGMT01 | 181 | 2 | 3GB | 40GB | 10 | 10.0.10.20 | HIGH | Daily |
| **Workstations** |
| ADMIN-WS01 | 131 | 2 | 2GB | 32GB | 30 | 10.0.30.31 | MEDIUM | Weekly |
| HR-WS01 | 142 | 2 | 3GB | 32GB | 30 | 10.0.30.42 | MEDIUM | Weekly |
| FIN-WS01 | 153 | 2 | 4GB | 32GB | 30 | 10.0.30.53 | HIGH | Weekly |
| EXEC-WS01 | 134 | 4 | 4GB | 40GB | 30 | 10.0.30.34 | HIGH | Weekly |
| PROJ-WS01 | 165 | 2 | 3GB | 32GB | 30 | 10.0.30.65 | MEDIUM | Weekly |
| INTERN-WS01 | 176 | 2 | 2GB | 32GB | 30 | 10.0.30.76 | LOW | Monthly |
| **TOTALS** | - | **26** | **31GB** | **436GB** | - | - | - | - |

### Host Requirements

**Minimum (Lab/Learning):**
- CPU: 6 cores (12 threads) - 2-3x overcommit
- RAM: 32GB - no overcommit (31GB allocated + 1GB headroom)
- Storage: 500GB SSD - thin provisioned (436GB allocated, ~200GB actual)
- Network: Gigabit NIC with VLAN support
- Cost: ~$800-1,200 (used server or custom build)

**Recommended (Production):**
- CPU: 8 cores (16 threads) - room for growth
- RAM: 64GB ECC - 50% headroom for expansion
- Storage: 1TB NVMe SSD - comfortable space
- Network: Dual gigabit NICs - redundancy and performance
- UPS: 1500VA - graceful shutdown on power loss
- Cost: ~$1,500-2,500

## Network Architecture

### VLAN Design

**VLAN 10 (Management):**
- Proxmox host: 10.0.10.10
- MGMT01: 10.0.10.20
- Purpose: Administrative access, Ansible, monitoring
- Security: Restricted to IT staff

**VLAN 20 (Servers):**
- DC01: 10.0.20.11
- DC02: 10.0.20.12
- FILES01: 10.0.20.21
- PRINT01: 10.0.20.22
- Purpose: Infrastructure services
- Security: Firewalled, audited

**VLAN 30 (Workstations):**
- All workstation VMs: 10.0.30.31-76
- Purpose: User workstations
- Security: Standard corporate policy

### DNS Configuration

**Primary DNS:** 10.0.20.11 (DC01)
**Secondary DNS:** 10.0.20.12 (DC02)

All VMs point to domain controllers for DNS resolution.

**Domain:** smboffice.local

### Firewall Rules (High Level)

**VLAN 30 → VLAN 20:**
- Allow: DNS (53), LDAP (389, 636), Kerberos (88), SMB (445)
- Deny: Direct SSH, management ports

**VLAN 10 → All VLANs:**
- Allow: SSH (22), Ansible, monitoring
- Purpose: Management access

**VLAN 20 → VLAN 30:**
- Deny: Servers don't initiate to workstations
- Exception: Monitoring probes

## Automated Deployment

### Ansible Playbook Structure

This entire environment will be deployed via Ansible:

```yaml
# site.yml - Main playbook
---
- name: Deploy SMB Infrastructure
  hosts: localhost
  roles:
    - proxmox_vm_creation

- name: Configure Domain Controllers
  hosts: domain_controllers
  roles:
    - samba_ad_dc
    - dns_config
    - security_hardening

- name: Configure File Server
  hosts: file_servers
  roles:
    - samba_shares
    - file_permissions
    - audit_logging

- name: Configure Workstations
  hosts: workstations
  roles:
    - domain_join
    - desktop_environment
    - user_policies

- name: Configure Monitoring
  hosts: management
  roles:
    - ansible_control
    - prometheus
    - grafana
```

**Full automation covered in upcoming articles.**

## Deployment Checklist

### Phase 1: Proxmox Preparation
- [ ] Proxmox host installed and configured
- [ ] Storage configured (LVM-thin)
- [ ] Network bridges created (vmbr0, vmbr1, vmbr2)
- [ ] VLANs configured
- [ ] VM templates created (Oracle Linux 9, Ubuntu 22.04)

### Phase 2: Infrastructure VMs
- [ ] DC01 deployed and Samba AD configured
- [ ] DC02 deployed and joined to domain
- [ ] DNS tested from both DCs
- [ ] FILES01 deployed and shares created
- [ ] PRINT01 deployed and CUPS configured
- [ ] MGMT01 deployed and Ansible installed

### Phase 3: Workstation VMs
- [ ] All 6 workstation VMs deployed
- [ ] Domain join configured (SSSD)
- [ ] Desktop environment installed
- [ ] User accounts created in AD
- [ ] Login tested from each workstation

### Phase 4: Security and Monitoring
- [ ] Auditd configured on all VMs
- [ ] SELinux enforcing
- [ ] Backup jobs configured
- [ ] Monitoring deployed (Prometheus/Grafana)
- [ ] Documentation updated

## Cost Analysis: Open Source vs. Proprietary

### Our Solution (Open Source)

| Component | Cost |
|-----------|------|
| Proxmox VE | Free |
| Oracle Linux 9 (11 VMs) | Free |
| Ubuntu 22.04 (6 VMs) | Free |
| Samba AD | Free |
| Ansible automation | Free |
| **Total software cost** | **$0** |
| Hardware (recommended) | $1,500-2,500 (one-time) |
| **First year total** | $1,500-2,500 |

### Equivalent Proprietary Solution

| Component | Cost |
|-----------|------|
| VMware vSphere Essentials | $500/year |
| Windows Server 2022 (2 DCs) | $1,800 (CALs needed) |
| Windows Server CALs (30 users) | $1,200 |
| Windows 10/11 Pro (6 workstations) | $1,200 |
| **Total software cost (year 1)** | **$4,700** |
| Hardware (same) | $1,500-2,500 |
| **First year total** | **$6,200-7,200** |
| **Annual renewal** | ~$2,000/year |

**5-Year Savings:** Open source saves $12,000-15,000

## Next Steps

With complete specifications defined, you're ready to:

1. **Size your hardware** - Use the resource matrix to choose appropriate server
2. **Prepare Proxmox** - Install and configure host (next article)
3. **Create templates** - Build base OS images for cloning
4. **Deploy infrastructure** - Domain controllers, file server, print server
5. **Deploy workstations** - Six workstation VMs
6. **Automate with Ansible** - Full infrastructure-as-code

**In the next article:** Proxmox installation, initial configuration, and creating VM templates.

---

## Quick Reference

### VM ID Ranges
- 100-109: Templates
- 110-119: Domain Controllers
- 120-129: Infrastructure Services
- 130-139: Admin/Exec Workstations
- 140-149: HR Workstations
- 150-159: Finance Workstations
- 160-169: Project Workstations
- 170-179: Temporary Workstations
- 180-189: Management

### Network Subnets
- 10.0.10.0/24: Management (VLAN 10)
- 10.0.20.0/24: Servers (VLAN 20)
- 10.0.30.0/24: Workstations (VLAN 30)

### Backup Schedule
- Daily (2AM): DC01, DC02, FILES01, MGMT01
- Weekly (Sun 3AM): FIN-WS01, EXEC-WS01, PRINT01, HR-WS01, ADMIN-WS01, PROJ-WS01
- Monthly (1st Sun): INTERN-WS01

---

**Author:** Richard Chamberlain
**Series:** SMB Office IT Blueprint
**Last Updated:** December 2025
**Contact:** [info@sebostechnology.com](mailto:info@sebostechnology.com)

---

## Related Articles

- Article 01: Introduction - Why Build IT Infrastructure on Linux
- Article 02: Proxmox Best Practices - Universal virtualization principles
- Article 03: SMB Infrastructure Planning (this article)
- Article 04: Proxmox Installation and Configuration (coming next)
