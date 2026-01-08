# Article 3: SMB Infrastructure Planning - Designing the Complete 11-VM Environment

## Executive Summary

This article details the architectural design and planning process for a complete small-medium business (SMB) IT infrastructure built on Proxmox virtualization. The design incorporates 11 virtual machines distributed across segmented VLANs, providing enterprise-grade services at SMB scale with emphasis on security, reliability, and maintainability.

**Target Audience:** IT professionals managing small business infrastructure, MSPs, advanced homelab enthusiasts, and anyone transitioning to enterprise-grade Linux infrastructure.

**Key Outcomes:**
- Complete network topology with VLAN segmentation
- Detailed VM roles and resource allocation
- Security architecture and access control
- Automation strategy using Infrastructure-as-Code
- Scalable design that grows with business needs

---

## Table of Contents

1. [Infrastructure Philosophy](#infrastructure-philosophy)
2. [Network Architecture](#network-architecture)
3. [The 11-VM Blueprint](#the-11-vm-blueprint)
4. [Resource Planning](#resource-planning)
5. [Security Architecture](#security-architecture)
6. [Service Dependencies](#service-dependencies)
7. [Automation Strategy](#automation-strategy)
8. [Scalability Considerations](#scalability-considerations)
9. [Cost Analysis](#cost-analysis)
10. [Implementation Roadmap](#implementation-roadmap)

---

## Infrastructure Philosophy

### Why 11 VMs?

The 11-VM design represents the **minimum viable infrastructure** for a professional SMB environment that needs:

- **High Availability**: Redundant domain controllers, no single points of failure for critical services
- **Security Through Segmentation**: Separate networks for management, servers, workstations, and DMZ
- **Separation of Concerns**: Dedicated VMs for specific functions rather than multipurpose servers
- **Room to Grow**: Architecture that scales from 10 to 100+ users without redesign
- **Professional Standards**: Mirrors enterprise best practices at SMB scale

### Design Principles

1. **Security First**: Every design decision prioritizes security over convenience
2. **Infrastructure as Code**: All configurations managed through Ansible for reproducibility
3. **Linux-Centric**: Leverage open-source solutions to reduce licensing costs
4. **Production-Ready**: No "good enough for homelab" shortcuts
5. **Documentation Required**: Every service documented for knowledge transfer

---

## Network Architecture

### VLAN Segmentation Strategy

| VLAN | Name | Subnet | Purpose | Access Level |
|------|------|--------|---------|--------------|
| 110 | Management | 10.0.110.0/24 | Proxmox host management, backup infrastructure | Highly Restricted |
| 120 | Servers | 10.0.120.0/24 | Core infrastructure services (DC, file, print, DNS) | Restricted |
| 130 | Workstations | 10.0.130.0/24 | Standard user workstations and devices | Standard Access |
| 131 | Admin Workstations | 10.0.131.0/24 | IT administrator workstations with elevated access | Restricted |
| 140 | IoT/Devices | 10.0.140.0/24 | Printers, scanners, IP cameras, sensors | Isolated |
| 150 | DMZ | 10.0.150.0/24 | Public-facing services (web, email relay) | Internet-Facing |

### Network Topology Diagram

```
Internet
    |
    v
[pfSense/OPNsense Firewall]
    |
    +--- VLAN 150 (DMZ) -----------> [Web Server] [Email Relay]
    |
    +--- VLAN 110 (Management) ----> [Proxmox Host] [Backup Server]
    |
    +--- VLAN 120 (Servers) -------> [DC01] [DC02] [File Server] [Ansible Control]
    |
    +--- VLAN 130 (Workstations) --> [User Workstations]
    |
    +--- VLAN 131 (Admin) ---------> [ws-admin01] [Jump Box]
    |
    +--- VLAN 140 (IoT) -----------> [Printers] [Cameras]
```

### Inter-VLAN Firewall Rules (Summary)

**Default Stance:** Deny all, permit by exception

| Source VLAN | Destination VLAN | Allowed Traffic | Business Justification |
|-------------|------------------|-----------------|------------------------|
| 131 (Admin) | 120 (Servers) | SSH (22), RDP (3389), Admin tools | IT administration |
| 131 (Admin) | 110 (Management) | SSH (22), Proxmox Web (8006) | Infrastructure management |
| 130 (Workstations) | 120 (Servers) | DNS (53), LDAP (389), SMB (445), Kerberos (88) | Domain services, file access |
| 120 (Servers) | 120 (Servers) | All infrastructure protocols | Service-to-service communication |
| 150 (DMZ) | 120 (Servers) | LDAP-S (636) for auth only | Authentication for public services |
| 140 (IoT) | Any | Outbound only, no inbound | Prevent IoT compromise spreading |

**Critical Security Rules:**
- VLAN 130 (User workstations) **CANNOT** access VLAN 110 (Management) or VLAN 131 (Admin)
- VLAN 150 (DMZ) **CANNOT** initiate connections to internal VLANs (except specific auth)
- VLAN 140 (IoT) is completely isolated - outbound only, no lateral movement

---

## The 11-VM Blueprint

### Core Infrastructure Services (VLAN 120)

#### 1. dc01 - Primary Domain Controller
- **VMID:** 110
- **IP:** 10.0.120.10
- **OS:** Ubuntu 22.04 LTS
- **Resources:** 2 vCPU, 4GB RAM, 100GB disk
- **Services:** Samba AD DC, DNS, NTP, LDAP
- **Role:** Primary authentication authority, DNS master
- **Criticality:** **CRITICAL** - Core authentication service

**Justification:** Active Directory provides centralized user management, Group Policy, and single sign-on. Ubuntu with Samba AD DC offers enterprise AD compatibility without Windows Server licensing costs.

#### 2. dc02 - Secondary Domain Controller
- **VMID:** 111
- **IP:** 10.0.120.11
- **OS:** Ubuntu 22.04 LTS
- **Resources:** 2 vCPU, 4GB RAM, 100GB disk
- **Services:** Samba AD DC, DNS, NTP, LDAP
- **Role:** Redundant DC, DNS replication, failover authentication
- **Criticality:** **HIGH** - Ensures business continuity

**Justification:** Second DC provides high availability. If dc01 fails, users can still authenticate, access files, and work normally. Also provides geographic redundancy for multi-site deployments.

#### 3. file-server01 - File and Print Server
- **VMID:** 200
- **IP:** 10.0.120.20
- **OS:** Ubuntu 22.04 LTS
- **Resources:** 2 vCPU, 8GB RAM, 500GB-2TB disk (scalable)
- **Services:** Samba file shares, CUPS print server, backup agent
- **Role:** Centralized file storage, shared printers, departmental shares
- **Criticality:** **HIGH** - Business data repository

**Justification:** Centralized file storage enables:
- Consistent backups (backup one server, not 50 workstations)
- Permission management through AD groups
- Version control and shadow copies
- Compliance and auditing

#### 4. ansible-ctrl - Automation and Configuration Management
- **VMID:** 310
- **IP:** 10.0.120.50
- **OS:** Rocky Linux 9
- **Resources:** 2 vCPU, 4GB RAM, 100GB disk
- **Services:** Ansible, Git, configuration management tools
- **Role:** Infrastructure automation, configuration deployment, orchestration
- **Criticality:** **MEDIUM** - Operational efficiency

**Justification:** Infrastructure-as-Code approach enables:
- Rapid VM deployment (minutes instead of hours)
- Consistent configurations across all systems
- Disaster recovery through code (rebuild infrastructure from Git)
- Documentation through code (Ansible playbooks are living documentation)

#### 5. monitoring01 - Observability and Alerting
- **VMID:** 320
- **IP:** 10.0.120.60
- **OS:** Rocky Linux 9
- **Resources:** 2 vCPU, 4GB RAM, 200GB disk
- **Services:** Prometheus, Grafana, Alertmanager, node_exporter
- **Role:** Metrics collection, visualization, alerting
- **Criticality:** **MEDIUM** - Proactive issue detection

**Justification:** Monitoring provides:
- Early warning of issues (disk space, performance, service failures)
- Capacity planning data
- Performance trending
- Compliance evidence (uptime SLAs)

#### 6. backup-server - Backup and Disaster Recovery
- **VMID:** 330
- **IP:** 10.0.110.20 (Management VLAN - access to all VLANs)
- **OS:** Rocky Linux 9
- **Resources:** 2 vCPU, 4GB RAM, 2TB+ disk (or NAS mount)
- **Services:** Proxmox Backup Server, rsync, backup scripts
- **Role:** VM backups, file server backups, retention management
- **Criticality:** **CRITICAL** - Data protection

**Justification:** Centralized backups ensure:
- Point-in-time recovery for VMs
- Ransomware protection (immutable backups)
- Compliance with data retention policies
- Business continuity planning

### Workstation Infrastructure

#### 7. ws-admin01 - Primary IT Administration Workstation
- **VMID:** 300
- **IP:** 10.0.131.10 (Admin VLAN)
- **OS:** Rocky Linux 9 Desktop
- **Resources:** 2 vCPU, 4GB RAM, 90GB disk
- **Services:** Ansible client, remote admin tools, Remmina, SSH client
- **Role:** Secure administrative access point
- **Criticality:** **HIGH** - Privileged access control

**Justification:** Separate admin workstation provides:
- Privileged access control (PAM)
- Network segmentation (admin VLAN isolated from user VLAN)
- Audit trail (all admin actions from known system)
- Security hardening (locked down, monitored)

#### 8. jump-box01 - Bastion Host / SSH Gateway
- **VMID:** 301
- **IP:** 10.0.131.20 (Admin VLAN), 192.168.35.100 (Management access)
- **OS:** Ubuntu 22.04 LTS (minimal)
- **Resources:** 1 vCPU, 2GB RAM, 50GB disk
- **Services:** SSH, session logging, 2FA
- **Role:** Secure gateway for SSH access to infrastructure
- **Criticality:** **HIGH** - Security control point

**Justification:** Jump box provides:
- Single point of entry for SSH (easier to monitor/audit)
- Multi-factor authentication enforcement
- Session recording for compliance
- Reduced attack surface (only one system exposed)

### Application and Service Layer

#### 9. app-server01 - Business Application Server
- **VMID:** 210
- **IP:** 10.0.120.30
- **OS:** Ubuntu 22.04 LTS
- **Resources:** 4 vCPU, 8GB RAM, 200GB disk (depends on applications)
- **Services:** Docker, internal web apps, business software
- **Role:** Host line-of-business applications
- **Criticality:** **MEDIUM-HIGH** (depends on applications)

**Justification:** Dedicated application server enables:
- Isolation from core infrastructure
- Resource allocation for business apps
- Containerization for easy deployment
- Scalability (can add more app servers)

#### 10. dev-test01 - Development and Testing Environment
- **VMID:** 211
- **IP:** 10.0.120.31
- **OS:** Ubuntu 22.04 LTS
- **Resources:** 2 vCPU, 4GB RAM, 100GB disk
- **Services:** Docker, Git, test databases
- **Role:** Safe environment for testing changes before production
- **Criticality:** **LOW** - Non-production

**Justification:** Test environment provides:
- Safe space to test updates before production
- Development environment for custom scripts
- Training ground for new technologies
- Reduces risk of breaking production

### DMZ Services (VLAN 150)

#### 11. web-dmz01 - Public Web Server / Reverse Proxy
- **VMID:** 150
- **IP:** 10.0.150.10 (internal), Public IP (NAT/forwarded)
- **OS:** Ubuntu 22.04 LTS
- **Resources:** 2 vCPU, 4GB RAM, 100GB disk
- **Services:** Nginx/Apache, reverse proxy, Let's Encrypt
- **Role:** Public-facing web services, email relay
- **Criticality:** **MEDIUM** - Public presence

**Justification:** DMZ server provides:
- Internet-facing services without exposing internal network
- Reverse proxy for internal web apps
- Email relay for outbound mail
- Attack surface isolation (compromise doesn't affect internal network)

---

## Resource Planning

### Total Infrastructure Requirements

#### Compute Resources

| Resource | Per VM Average | Total (11 VMs) | Recommended Proxmox Host |
|----------|----------------|----------------|--------------------------|
| vCPU | 2.2 cores | 24 vCPUs | 16-core CPU (allowing oversubscription) |
| RAM | 4.7 GB | 52 GB | 64 GB RAM (with headroom) |
| Storage | 180 GB | 2 TB | 2TB SSD for VMs + 4TB HDD for backups |

#### Network Requirements

- **Bandwidth:** Gigabit switching minimum, 10GbE recommended for file server
- **Switch Ports:** Minimum 2 (trunked for VLANs) + management
- **VLAN Support:** Managed switch with 802.1Q VLAN tagging

#### Storage Breakdown

```
Template Storage:      100 GB  (VM templates for rapid deployment)
VM Boot Disks:        800 GB  (OS disks for all 11 VMs)
File Server Data:   1-5 TB    (Scalable based on business needs)
Backup Storage:     2-10 TB   (3x file server capacity for retention)
Monitoring Data:     200 GB   (Time-series metrics retention)
Logs:                 50 GB   (Centralized logging)
```

### Minimum Viable Proxmox Host

**Budget Build (~$2,000-3,000):**
- CPU: AMD Ryzen 9 5900X (12-core/24-thread) or Intel Xeon E-2388G
- RAM: 64GB DDR4 ECC (4x16GB)
- Storage: 1TB NVMe SSD (VMs) + 4TB HDD (backups)
- Network: Dual 1GbE NICs (bonded/LACP) or single 10GbE
- Chassis: Tower or 2U rackmount

**Production Build (~$5,000-8,000):**
- CPU: AMD EPYC 7302P (16-core/32-thread) or dual Intel Xeon Silver
- RAM: 128GB DDR4 ECC (8x16GB)
- Storage: 2x1TB NVMe SSD (RAID1 for VMs) + 4x4TB HDD (RAID10 for backup)
- Network: Dual 10GbE NICs (bonded)
- Chassis: 2U rackmount with IPMI/iLO
- UPS: 1500VA for graceful shutdown

---

## Security Architecture

### Defense in Depth Strategy

The infrastructure implements multiple layers of security:

#### Layer 1: Network Segmentation (VLANs)
- Physical separation of trust zones
- Firewall rules between all VLANs
- No flat network - everything segmented

#### Layer 2: Perimeter Security
- pfSense/OPNsense firewall with IDS/IPS (Suricata)
- NAT for all internal networks
- VPN for remote access (WireGuard/OpenVPN)
- Fail2ban for SSH brute force protection

#### Layer 3: Host-Based Security
- SSH hardening on all Linux systems:
  - Key-only authentication (no passwords)
  - Disabled root login
  - Custom SSH port (non-standard)
  - Network-based access control (AllowUsers)
  - Session timeouts
  - CVE-2024-6387 mitigation
- SELinux/AppArmor enabled
- Automatic security updates
- Minimal package installation (reduce attack surface)

#### Layer 4: Access Control
- Active Directory for centralized authentication
- Role-based access control (RBAC)
- Principle of least privilege
- Privileged Access Management (PAM) via admin workstation
- Multi-factor authentication for admin access

#### Layer 5: Monitoring and Logging
- Centralized logging (rsyslog to monitoring01)
- SIEM alerts for security events
- Failed login monitoring
- Unusual network traffic detection
- Weekly security report generation

#### Layer 6: Data Protection
- Encrypted backups (age/gpg)
- Retention policies (3-2-1 backup rule)
- Immutable backup storage (prevent ransomware encryption)
- Regular restore testing

### SSH Hardening Configuration

All Linux VMs implement modular SSH hardening via Ansible:

**Session Security (`/etc/ssh/sshd_config.d/06-session.conf`):**
```
ClientAliveInterval 300
ClientAliveCountMax 2
LoginGraceTime 60
MaxStartups 10:30:60
MaxSessions 10
```

**Authentication (`/etc/ssh/sshd_config.d/07-authentication.conf`):**
```
PubkeyAuthentication yes
PasswordAuthentication no
PermitRootLogin no
PermitEmptyPasswords no
AllowGroups ssh-users
```

**Network Access Control (`/etc/ssh/sshd_config.d/08-access-control.conf`):**
```
AllowUsers richard@10.0.131.* richard@192.168.35.*
DenyUsers *@*
Match Address 10.0.0.0/8,192.168.0.0/16
    PasswordAuthentication no
```

**Forwarding Disabled (`/etc/ssh/sshd_config.d/10-forwarding.conf`):**
```
AllowTcpForwarding no
X11Forwarding no
AllowStreamLocalForwarding no
GatewayPorts no
PermitTunnel no
```

### Compliance Considerations

This architecture addresses common compliance frameworks:

- **PCI DSS:** Network segmentation, access control, logging
- **HIPAA:** Encryption, access controls, audit trails
- **GDPR:** Data protection, retention policies, right to deletion
- **SOC 2:** Monitoring, change management, disaster recovery
- **NIST Cybersecurity Framework:** All five functions (Identify, Protect, Detect, Respond, Recover)

---

## Service Dependencies

### Boot Order and Dependencies

Understanding dependencies is critical for disaster recovery:

```
Boot Order Priority:

1. Proxmox Host
   └─> Network connectivity established
       └─> VLAN trunking configured

2. dc01 (Primary DC)
   └─> DNS service available
       └─> Authentication available

3. dc02 (Secondary DC) + file-server01 + backup-server
   └─> AD replication begins
       └─> File shares available

4. ansible-ctrl + monitoring01 + jump-box01
   └─> Management infrastructure online

5. app-server01 + ws-admin01
   └─> Business services available

6. dev-test01 + web-dmz01
   └─> Non-critical services online
```

### Critical Dependency Map

```
Domain Authentication (dc01/dc02)
    ↓
    ├─> File Shares (file-server01 requires AD for permissions)
    ├─> Workstations (ws-admin01 requires AD for login)
    ├─> Applications (app-server01 requires AD for auth)
    └─> Monitoring (monitoring01 requires AD for user dashboards)

DNS (dc01/dc02)
    ↓
    ├─> ALL services require DNS resolution
    └─> External internet access requires DNS

Time Sync (NTP on dc01/dc02)
    ↓
    ├─> Kerberos requires time sync within 5 minutes
    └─> Log correlation requires synchronized timestamps
```

### Disaster Recovery Priority

**Recovery Time Objectives (RTO):**

| System | RTO | Recovery Priority | Impact if Down |
|--------|-----|-------------------|----------------|
| dc01 | 1 hour | **P0 - CRITICAL** | No authentication, no file access |
| dc02 | 4 hours | **P1 - HIGH** | Reduced redundancy, single point of failure |
| file-server01 | 2 hours | **P1 - HIGH** | No access to business files |
| backup-server | 8 hours | **P2 - MEDIUM** | Can't restore, but existing backups safe |
| ansible-ctrl | 24 hours | **P3 - MEDIUM** | Manual configuration required |
| monitoring01 | 24 hours | **P3 - MEDIUM** | Reduced visibility, alerts delayed |
| ws-admin01 | 4 hours | **P2 - MEDIUM** | Reduced admin capability |
| app-server01 | 4 hours | **P1-P2** | Depends on applications hosted |
| jump-box01 | 8 hours | **P3 - LOW** | Can SSH directly if needed |
| dev-test01 | 48 hours | **P4 - LOW** | Non-production system |
| web-dmz01 | 8 hours | **P2 - MEDIUM** | External services unavailable |

---

## Automation Strategy

### Infrastructure as Code Philosophy

**Every aspect of this infrastructure is codified in Ansible:**

```
ansible/
├── inventory/
│   └── hosts.yml                    # All 11 VMs defined
├── host_vars/
│   ├── dc01.yml                     # Per-VM configuration
│   ├── dc02.yml
│   ├── file-server01.yml
│   ├── ansible-ctrl.yml
│   ├── monitoring01.yml
│   ├── backup-server.yml
│   ├── ws-admin01.yml
│   ├── jump-box01.yml
│   ├── app-server01.yml
│   ├── dev-test01.yml
│   └── web-dmz01.yml
├── group_vars/
│   └── all.yml                      # Global settings (domain, DNS, VLANs)
├── roles/
│   ├── proxmox_vm_deploy/           # Create VMs on Proxmox
│   ├── network_config/              # Configure static IPs, VLANs
│   ├── hostname_config/             # Set hostname and /etc/hosts
│   ├── system_update/               # OS updates
│   ├── install_packages/            # Install software
│   ├── user_config/                 # Create users, deploy SSH keys
│   ├── ssh_config/                  # Enable SSH service
│   ├── ssh_hardening/               # Apply SSH security policies
│   ├── service_config/              # Enable/disable services
│   ├── samba_ad_dc/                 # Domain controller setup
│   ├── file_server/                 # Samba file shares
│   ├── monitoring/                  # Prometheus/Grafana
│   └── backup/                      # Backup configuration
└── playbooks/
    ├── deploy-domain-controllers.yml      # DC01 + DC02
    ├── deploy-file-server.yml             # File server
    ├── deploy-ansible-ctrl.yml            # Ansible control
    ├── deploy-monitoring.yml              # Monitoring stack
    ├── deploy-backup-server.yml           # Backup infrastructure
    ├── deploy-workstations.yml            # Admin workstations
    ├── deploy-app-server.yml              # Application server
    └── deploy-complete-infrastructure.yml # All 11 VMs
```

### Deployment Workflow

**Phase 1: Core Infrastructure (Day 1)**
```bash
# Deploy domain controllers
ansible-playbook playbooks/deploy-domain-controllers.yml

# Configure Active Directory (separate playbook for AD setup)
ansible-playbook playbooks/configure-active-directory.yml

# Deploy file server (requires AD to be operational)
ansible-playbook playbooks/deploy-file-server.yml
```

**Phase 2: Management Infrastructure (Day 2)**
```bash
# Deploy automation and monitoring
ansible-playbook playbooks/deploy-ansible-ctrl.yml
ansible-playbook playbooks/deploy-monitoring.yml
ansible-playbook playbooks/deploy-backup-server.yml

# Configure backups
ansible-playbook playbooks/configure-backups.yml
```

**Phase 3: User Services (Day 3)**
```bash
# Deploy workstations and applications
ansible-playbook playbooks/deploy-workstations.yml
ansible-playbook playbooks/deploy-app-server.yml
ansible-playbook playbooks/deploy-web-dmz.yml
```

### Benefits of Automation

1. **Rapid Deployment:** Deploy entire infrastructure in hours instead of days
2. **Consistency:** Every VM configured identically (no "snowflake servers")
3. **Documentation:** Ansible playbooks serve as living documentation
4. **Disaster Recovery:** Rebuild infrastructure from code + backups
5. **Testing:** Spin up test environment identical to production
6. **Compliance:** Auditable changes tracked in Git
7. **Knowledge Transfer:** New team members can understand infrastructure through code

---

## Scalability Considerations

### Vertical Scaling (Growing Individual VMs)

Each VM can scale resources as needed:

```yaml
# Before (Small Business - 10 users)
file-server01:
  cores: 2
  memory: 8GB
  disk: 500GB

# After (Growing Business - 50 users)
file-server01:
  cores: 4
  memory: 16GB
  disk: 2TB
```

### Horizontal Scaling (Adding More VMs)

Architecture supports expansion:

**Add Regional File Server:**
```
file-server02 (VMID 201) -> 10.0.120.21
  Role: Branch office file server
  Replication: DFS-R from file-server01
```

**Add Application Servers:**
```
app-server02 (VMID 212) -> 10.0.120.32
app-server03 (VMID 213) -> 10.0.120.33
  Role: Load-balanced application tier
  Load Balancer: HAProxy on web-dmz01
```

**Add Monitoring Nodes:**
```
monitoring02 (VMID 321) -> 10.0.120.61
  Role: Regional monitoring collector
  Federation: Prometheus federation to monitoring01
```

### Multi-Site Expansion

Infrastructure extends to branch offices:

```
Main Office (Current):
  - dc01 (10.0.120.10) - Primary DC
  - dc02 (10.0.120.11) - Secondary DC
  - file-server01 (10.0.120.20)

Branch Office (New):
  - dc03 (10.1.120.10) - Branch DC (AD site replication)
  - file-server02 (10.1.120.20) - Branch file server
  - VPN Site-to-Site: 10.0.0.0/16 <-> 10.1.0.0/16
```

### Cloud Hybrid Expansion

**Hybrid Cloud Integration:**
- VPN to Azure/AWS for cloud resources
- Backup replication to S3/Azure Blob
- Cloud-based email (M365) integrated with on-prem AD (Azure AD Connect)
- Disaster recovery VMs in cloud (cold standby)

---

## Cost Analysis

### Initial Capital Expenditure

| Component | Cost | Notes |
|-----------|------|-------|
| Proxmox Host Hardware | $3,000-8,000 | Server-grade with ECC RAM |
| Managed Switch (24-port) | $300-800 | VLAN support required |
| Firewall Hardware | $300-1,500 | Protectli/mini PC for pfSense |
| UPS (1500VA) | $200-400 | Battery backup for graceful shutdown |
| Backup Storage (NAS) | $500-2,000 | Synology/TrueNAS for backup target |
| Rack/Cabinet (optional) | $200-800 | 12U wall-mount or 42U floor rack |
| **Total Initial Investment** | **$4,500-13,500** | Scales with requirements |

### Operational Costs (Annual)

| Expense | Annual Cost | Notes |
|---------|-------------|-------|
| Electricity (24/7) | $300-600 | ~200W average draw |
| Internet (Business) | $600-1,200 | Static IP, higher upload |
| Domain Registration | $15-30 | .com domain |
| SSL Certificates | $0 | Let's Encrypt (free) |
| Backup Cloud Storage (optional) | $60-300 | Backblaze B2, S3 Glacier |
| Software Licenses | $0 | All open source (Linux, Samba, Proxmox) |
| **Total Annual Operating** | **$975-2,130** | |

### Cost Comparison: SMB Linux vs. Windows Server

**Windows Server Equivalent:**

| Component | Windows Cost | Linux Cost | Savings |
|-----------|--------------|------------|---------|
| 2x Windows Server Standard | $1,800 | $0 | $1,800 |
| 50 CALs (User + Device) | $3,500 | $0 | $3,500 |
| Exchange Server (or M365) | $1,200/yr | $0 | $1,200/yr |
| Backup Software | $500-1,500 | $0 | $1,000 |
| Management Tools | $500 | $0 | $500 |
| **Total Licensing (3 years)** | **$13,400** | **$0** | **$13,400** |

**ROI Analysis:**

Even if Linux infrastructure costs $5,000 more in admin time over 3 years (training, troubleshooting), you're still saving $8,400 compared to Windows licensing. For businesses with existing Linux skills, savings are pure profit.

---

## Implementation Roadmap

### Phase 0: Planning and Preparation (Week 1)

**Tasks:**
- [ ] Document current infrastructure and requirements
- [ ] Purchase hardware (Proxmox host, switch, firewall)
- [ ] Install Proxmox on host hardware
- [ ] Configure VLANs on managed switch
- [ ] Set up pfSense/OPNsense firewall
- [ ] Create VM templates (Ubuntu 22.04, Rocky 9)
- [ ] Set up Git repository for Ansible code
- [ ] Document network diagram and IP allocation

**Deliverables:**
- Proxmox host operational
- Network segmentation configured
- VM templates ready for cloning

---

### Phase 1: Core Identity and Storage (Week 2)

**Day 1-2: Domain Controllers**
```bash
ansible-playbook playbooks/deploy-domain-controllers.yml
ansible-playbook playbooks/configure-active-directory.yml
```

**Validation:**
- [ ] dc01 and dc02 both online
- [ ] Active Directory domain functional
- [ ] DNS resolving internal and external names
- [ ] Time sync operational (NTP)
- [ ] AD replication working between DCs

**Day 3-4: File Server**
```bash
ansible-playbook playbooks/deploy-file-server.yml
ansible-playbook playbooks/configure-file-shares.yml
```

**Validation:**
- [ ] File server joined to domain
- [ ] Shares accessible via SMB
- [ ] Permissions working via AD groups
- [ ] Windows clients can map drives

**Day 5: Initial Backup Configuration**
```bash
ansible-playbook playbooks/deploy-backup-server.yml
```

**Validation:**
- [ ] First backup of DCs completed
- [ ] First backup of file server completed
- [ ] Test restore successful

---

### Phase 2: Management and Observability (Week 3)

**Day 1-2: Automation Infrastructure**
```bash
ansible-playbook playbooks/deploy-ansible-ctrl.yml
```

**Validation:**
- [ ] Ansible control node can reach all VMs
- [ ] SSH key authentication working
- [ ] Git repository cloned
- [ ] Test playbook execution successful

**Day 3-4: Monitoring Stack**
```bash
ansible-playbook playbooks/deploy-monitoring.yml
ansible-playbook playbooks/configure-monitoring-targets.yml
```

**Validation:**
- [ ] Prometheus scraping all node_exporters
- [ ] Grafana dashboards displaying metrics
- [ ] Alertmanager sending test alerts
- [ ] Retention policies configured

**Day 5: Admin Workstation**
```bash
ansible-playbook playbooks/deploy-workstations.yml
```

**Validation:**
- [ ] ws-admin01 accessible on admin VLAN
- [ ] Can authenticate with domain credentials
- [ ] Remote admin tools installed
- [ ] Can access all infrastructure

---

### Phase 3: Application and User Services (Week 4)

**Day 1-2: Application Server**
```bash
ansible-playbook playbooks/deploy-app-server.yml
```

**Validation:**
- [ ] Docker installed and operational
- [ ] Can deploy containerized apps
- [ ] Apps accessible from workstation VLAN

**Day 3: DMZ Web Server**
```bash
ansible-playbook playbooks/deploy-web-dmz.yml
```

**Validation:**
- [ ] Nginx/Apache serving content
- [ ] SSL certificate from Let's Encrypt
- [ ] Accessible from internet (NAT configured)
- [ ] Reverse proxy functional

**Day 4-5: Testing and Documentation**
- [ ] End-to-end user workflow testing
- [ ] Disaster recovery test (restore dc02 from backup)
- [ ] Update network documentation
- [ ] Create user onboarding guide
- [ ] Document troubleshooting procedures

---

### Phase 4: Hardening and Production Readiness (Week 5)

**Security Hardening:**
- [ ] SSH hardening applied to all VMs
- [ ] Firewall rules tested and documented
- [ ] Failed login monitoring configured
- [ ] Security update automation enabled
- [ ] Vulnerability scan with OpenVAS/Nessus

**Performance Tuning:**
- [ ] Resource utilization reviewed (CPU, RAM, disk)
- [ ] Network bandwidth testing
- [ ] File server performance benchmarks
- [ ] Database query optimization (if applicable)

**Backup and DR:**
- [ ] Full infrastructure backup completed
- [ ] Offsite backup replication tested
- [ ] DR runbook documented
- [ ] Recovery time tested for each VM

**Handoff:**
- [ ] Admin training conducted
- [ ] Documentation finalized
- [ ] Credential management (password vault)
- [ ] Escalation procedures defined

---

## Common Pitfalls and How to Avoid Them

### Pitfall 1: Undersized Host Hardware
**Problem:** Buying low-end hardware that can't handle 11 VMs under load
**Solution:** Calculate total resources needed BEFORE purchasing. Plan for 30% overhead. Use proper server hardware with ECC RAM.

### Pitfall 2: Flat Network (No VLANs)
**Problem:** All VMs on same network - IoT device compromise spreads to domain controllers
**Solution:** Implement VLANs from day one. Never skip network segmentation.

### Pitfall 3: Single Domain Controller
**Problem:** "We'll add the second DC later" - DC01 dies, entire business down
**Solution:** Deploy both DCs in Phase 1. High availability isn't optional for authentication.

### Pitfall 4: No Backup Testing
**Problem:** Backups running for months, never tested - restore fails when needed
**Solution:** Quarterly DR drills. Actually restore a DC from backup and verify functionality.

### Pitfall 5: Skipping Automation
**Problem:** "I'll document this manually later" - 6 months later, no one knows the config
**Solution:** If it's not in Ansible, it doesn't exist. Codify everything from the start.

### Pitfall 6: Over-Engineering Too Early
**Problem:** Kubernetes cluster for 5 users, microservices for simple apps
**Solution:** Start simple. This 11-VM design is the baseline. Add complexity when actually needed.

### Pitfall 7: Ignoring Compliance from Start
**Problem:** "We'll worry about compliance later" - PCI audit finds no network segmentation
**Solution:** Build compliance into architecture (network segmentation, logging, access control).

---

## Success Metrics

### Technical Metrics

**Availability:**
- Target: 99.5% uptime (43.8 hours downtime/year)
- Measurement: Uptime monitoring via Prometheus

**Performance:**
- File server response time <100ms for small files
- DC authentication <2 seconds
- Application server page load <3 seconds

**Security:**
- Zero unpatched critical vulnerabilities
- All failed logins logged and alerted
- Backup success rate >99%

### Business Metrics

**Cost Savings:**
- Infrastructure cost <$10,000 initial
- Operating cost <$2,000/year
- License savings >$10,000 over 3 years vs. Windows

**Operational Efficiency:**
- New VM deployment: <30 minutes (vs. 4 hours manual)
- Disaster recovery: <4 hours for critical systems
- Admin time: <10 hours/week for maintenance

---

## Conclusion

This 11-VM infrastructure design represents the **minimum viable enterprise architecture** for a modern small business. It provides:

✅ **High Availability** - Redundant domain controllers, no single points of failure
✅ **Security** - Defense in depth with network segmentation, hardening, monitoring
✅ **Scalability** - Architecture grows from 10 to 100+ users without redesign
✅ **Cost-Effective** - Open source stack saves $10K+ vs. Windows licensing
✅ **Professional** - Mirrors enterprise best practices at SMB scale
✅ **Automated** - Infrastructure-as-Code enables rapid deployment and DR

### Next Steps

1. **Start Small:** Begin with Phase 1 (DCs + file server) - this provides immediate value
2. **Add Gradually:** Implement Phases 2-4 over weeks/months as time permits
3. **Document Everything:** Use Ansible as living documentation
4. **Test Thoroughly:** DR drills, backup restores, failover testing
5. **Share Knowledge:** Contribute to r/LinuxForBusiness, write blog posts, help others

### Additional Resources

**Project Repository:**
- GitHub: `smb-office-it-blueprint` (Ansible playbooks, documentation)

**Community:**
- Reddit: r/LinuxForBusiness
- Discussion: Infrastructure planning, troubleshooting, best practices

**Related Articles:**
- Article 1: Introduction to SMB Infrastructure on Linux
- Article 2: Proxmox Setup and VM Template Creation
- Article 4: Active Directory with Samba (coming next)
- Article 5: Automated Deployment with Ansible

---

**Author's Note:**

This infrastructure design is the result of real-world SMB deployments, homelab experimentation, and enterprise experience distilled into a practical blueprint. It's not theoretical - this exact architecture has been deployed successfully for businesses ranging from 10 to 75 users.

The beauty of Infrastructure-as-Code is that you can deploy this entire environment in a weekend, learn from it, break it, rebuild it, and truly understand each component. That's the power of automation and modern infrastructure.

Start building. Share what you learn. Help others avoid the mistakes you make. That's how we grow the Linux-for-business community.

**Questions? Feedback? Share your deployment experience in r/LinuxForBusiness!**

---

*Document Version: 1.0*
*Last Updated: 2026-01-04*
*License: CC BY-SA 4.0 (Attribution-ShareAlike)*
