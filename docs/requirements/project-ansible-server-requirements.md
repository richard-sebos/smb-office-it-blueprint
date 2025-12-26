<!--
███████████████████████████████████████████████████████████████
  🧾 SMB Office IT Blueprint – Project Document
  Doc ID: REQ-INFRA-ANSIBLE-PROJECT-001
  Author: IT Infrastructure Architect, Linux Admin/Architect
  Created: 2025-12-25
  Updated: 2025-12-25
  Version: v1.0
  Status: Draft
  Confidentiality: Internal
  Project Phase: Planning
  Category: Requirements Specification
  Audience: IT
  Owners: IT Infrastructure Architect, Linux Admin/Architect
  Reviewers: IT Security Analyst, Ansible Programmer, IT Code Auditor, Project Manager
  Tags: [ansible, proxmox, automation, infrastructure, project-management, api, virtualization]
  Data Sensitivity: Access Credentials (Proxmox API tokens)
  Compliance: Internal Security Standards
  Publish Target: Internal
  Summary: >
    Technical and functional requirements for the Project Ansible Server that manages
    Proxmox virtualization infrastructure, VM lifecycle, networking, and automated
    environment provisioning for the SMB Office IT Blueprint project.
  Read Time: ~25 min
███████████████████████████████████████████████████████████████
-->

# 📘 Project Ansible Server Requirements

---

## 🎯 Executive Summary

**For Business Stakeholders:**

This document describes an automation system that can build an entire 11-server IT environment in 15-30 minutes instead of 3-4 hours of manual work. The **Project Ansible Server** acts like a construction foreman, automatically creating virtual machines, configuring networks, and setting up security—all with a single command.

**Key Benefits:**
- ⏱️ **Time Savings:** Reduces deployment from 3-4 hours to 15-30 minutes (85% time reduction)
- 🎯 **Error Elimination:** Automated processes prevent configuration mistakes
- 🔄 **Repeatability:** Every deployment is identical—no variations or "it works on my machine" issues
- 📚 **Knowledge Retention:** Infrastructure is documented in code, not tribal knowledge
- 💰 **Cost Efficiency:** Faster deployments = lower labor costs, enables rapid testing without risk

**What It Does:**
1. Creates 11 virtual machines from templates
2. Configures 3 separate networks for security isolation
3. Sets up automated backups
4. Applies security policies and access controls
5. Can completely tear down and rebuild the environment instantly

**Business Impact:**
This automation demonstrates modern infrastructure-as-code practices used by enterprises worldwide. It reduces deployment time by 85%, eliminates human error, and enables rapid experimentation—making it ideal for training, testing, and educational purposes.

**Target Audience:** This document is written for both business stakeholders (who need to understand the "why") and technical teams (who need to understand the "how"). Business-friendly summaries appear throughout in highlighted boxes.

---

## 📍 Table of Contents

- [1. Purpose](#1-purpose)
- [2. Background](#2-background)
- [3. Objectives](#3-objectives)
- [4. Server Roles and Responsibilities](#4-server-roles-and-responsibilities)
- [5. Technical Specifications](#5-technical-specifications)
- [6. Proxmox Integration](#6-proxmox-integration)
- [7. Network Configuration](#7-network-configuration)
- [8. Storage Management](#8-storage-management)
- [9. Resource Pools and Tagging](#9-resource-pools-and-tagging)
- [10. VM Template Management](#10-vm-template-management)
- [11. VM Cloning and Provisioning](#11-vm-cloning-and-provisioning)
- [12. Firewall and Security](#12-firewall-and-security)
- [13. Backup Configuration](#13-backup-configuration)
- [14. Project Lifecycle Automation](#14-project-lifecycle-automation)
- [15. Security Requirements](#15-security-requirements)
- [16. Documentation Standards](#16-documentation-standards)
- [17. Testing Requirements](#17-testing-requirements)
- [18. Performance Requirements](#18-performance-requirements)
- [19. Maintenance and Updates](#19-maintenance-and-updates)
- [20. Disaster Recovery](#20-disaster-recovery)
- [21. Success Criteria](#21-success-criteria)
- [22. Related Files](#22-related-files)
- [23. Review History](#23-review-history)
- [24. Departmental Approval Checklist](#24-departmental-approval-checklist)

---

## 1. Purpose

### What This Document Is About

This document describes the **Project Ansible Server**—an automation system that builds and manages the entire SMB Office IT environment on the Proxmox virtualization platform.

**Think of it as:** A construction foreman that builds the entire office building (the IT infrastructure), while a different manager (the SMB Ansible Server) handles furnishing and decorating the offices inside.

### Why Do We Need This?

Building an 11-server IT environment manually takes 3-4 hours and is prone to errors. The Project Ansible Server automates this process, reducing deployment time to 15-30 minutes with perfect consistency every time.

### What Does It Do?

The Project Ansible Server automatically:
- ✅ Creates all 11 virtual machines from templates
- ✅ Sets up the network infrastructure (3 separate networks for security)
- ✅ Configures virtual machine resources (CPU, memory, storage)
- ✅ Applies security rules and access controls
- ✅ Configures automated backups
- ✅ Can completely tear down and rebuild the environment on command

### What Doesn't It Do?

This server **does not** configure the business applications inside the virtual machines—that's handled by a different automation system called the SMB Ansible Server (MGMT01) that lives inside the environment itself.

**Scope:**
- Project Ansible Server deployment and configuration
- Proxmox API integration and automation capabilities
- VM template creation and lifecycle management
- Network infrastructure provisioning
- Security and access control implementation
- Complete environment automation (deploy/destroy/reset)

**Out of Scope:**
- SMB business application configuration (handled by SMB Ansible Server/MGMT01)
- End-user workstation management (domain join, desktop policies)
- Production business data management
- Application-layer security (handled within VMs)

---

## 2. Background

### 2.1 Project Context

**What is the SMB Office IT Blueprint?**

This project demonstrates how a 30-person professional services firm can build a complete IT infrastructure using free, open-source software instead of expensive proprietary solutions.

The environment includes:
- **11 Virtual Machines** (servers and workstations) running on Proxmox virtualization platform
- **3 Separate Networks** to isolate management, servers, and workstations for security
- **Organized Resource Groups** to manage different types of systems
- **Complete Automation** so the entire environment can be rebuilt instantly

### 2.2 The Two-Server Automation Strategy

**Why Two Automation Servers?**

We use a **two-layer automation approach** similar to how construction projects have different roles:

**🏗️ Layer 1: Project Ansible Server** (This Document) - **The Construction Foreman**
- **Manages:** The virtualization platform itself (Proxmox)
- **Creates:** Virtual machines, networks, storage
- **Controls:** Building and demolishing the entire environment
- **Location:** Outside the project environment (like a construction office)
- **Real-world analogy:** Builds the office building, installs electrical systems, runs network cables

**🏢 Layer 2: SMB Ansible Server (MGMT01)** - **The Office Manager**
- **Manages:** Applications and services inside the virtual machines
- **Configures:** Active Directory, file shares, user accounts
- **Controls:** Business applications and user settings
- **Location:** Inside the project environment (VM ID 181)
- **Real-world analogy:** Furnishes offices, sets up phones, configures desk computers

**Why Separate Them?**

| Benefit | Explanation |
|---------|-------------|
| **Independence** | The infrastructure can be completely rebuilt without losing application configurations |
| **Clear Responsibilities** | Infrastructure team manages Layer 1, application team manages Layer 2 |
| **Survival** | Project Ansible Server survives environment resets (it's outside the environment) |
| **Flexibility** | The SMB environment can be destroyed and rebuilt without affecting the automation system |

### 2.3 Problem Statement

**Why Manual Management Doesn't Work:**

| Challenge | Manual Approach (Old Way) | Automated Approach (New Way) |
|-----------|---------------------------|------------------------------|
| **Deploy 11 VMs** | 3-4 hours, prone to typos and mistakes | 15-30 minutes, perfect every time |
| **Configure networks** | Manual clicks in web interface, easy to misconfigure | Automated, version-controlled, tested |
| **Apply organization tags** | Tedious, often forgotten or incomplete | Automatic, comprehensive, consistent |
| **Reset environment** | Hours of work, risky, stressful | Single command, minutes to complete |
| **Documentation** | Quickly out of date, requires manual updates | Self-documenting automation code |
| **Team onboarding** | Weeks of knowledge transfer | Run one command, review code |

**Business Impact:**
- **Time Savings:** 2.5-3.5 hours saved per deployment
- **Error Reduction:** Eliminates human configuration errors
- **Consistency:** Every environment is identical
- **Knowledge Retention:** Automation code documents the infrastructure
- **Training Efficiency:** New team members productive faster

---

## 3. Objectives

### 3.1 Primary Goals

**What We're Trying to Achieve:**

1. **🤖 Automate Infrastructure Management**
   - **What:** Replace manual clicks in Proxmox web interface with automated code
   - **Why:** Eliminates human error, saves time, creates documentation
   - **How:** All infrastructure changes are version-controlled scripts
   - **Benefit:** Infrastructure changes can be reviewed, tested, and rolled back like software code

2. **⚡ Enable Fast Environment Lifecycle**
   - **Deploy:** Create complete 11-VM environment with one command
   - **Destroy:** Tear down entire environment safely with one command
   - **Reset:** Return to fresh state instantly (destroy + redeploy)
   - **Benefit:** Supports experimentation, training, and testing without fear

3. **🎯 Ensure Consistency and Repeatability**
   - **What:** Every deployment produces identical results
   - **Why:** Prevents "it works on my machine" problems
   - **How:** Automation code is tested and verified
   - **Benefit:** Reliable, predictable infrastructure

4. **📚 Support Educational Goals**
   - **What:** Demonstrate modern infrastructure-as-code practices
   - **Why:** Shows how enterprises manage infrastructure at scale
   - **How:** Reusable automation patterns and clear documentation
   - **Benefit:** Hands-on learning for students and professionals

### 3.2 Secondary Goals

5. **🔒 Maintain Security Best Practices**
   - **Access Control:** Project Ansible Server has minimum necessary permissions
   - **Credential Security:** All passwords/tokens encrypted and never stored in plain text
   - **Network Isolation:** Firewalls prevent unauthorized cross-network access
   - **Audit Trail:** Every infrastructure change logged in version control
   - **Business Value:** Demonstrates enterprise security standards

6. **🚑 Enable Disaster Recovery**
   - **Documentation:** Clear recovery procedures for common failures
   - **Backup Automation:** Automated backup configuration and testing
   - **Rapid Rebuild:** Infrastructure can be recreated from code within hours
   - **Business Value:** Minimize downtime, reduce recovery costs

7. **⚙️ Optimize Performance**
   - **Parallel Operations:** Deploy multiple VMs simultaneously
   - **Efficient Resource Use:** Minimize API calls, optimize network usage
   - **Performance Target:** Full environment deployment in under 30 minutes
   - **Business Value:** Faster deployment = less waiting, lower labor costs

---

## 4. Server Roles and Responsibilities

> **📋 Business Summary:** This section clarifies what each automation server is responsible for and why we need two separate systems. Understanding these roles helps prevent confusion about which system handles what tasks.

### 4.1 Project Ansible Server vs SMB Ansible Server

**Quick Reference - Who Does What:**

| Aspect | Project Ansible Server | SMB Ansible Server (MGMT01) |
|--------|------------------------|------------------------------|
| **Purpose** | Infrastructure management | Business application management |
| **Manages** | Proxmox host, VMs, networks, storage | Samba AD, file shares, users, workstations |
| **Access Level** | Proxmox root/admin API | SSH to guest VMs |
| **Network Location** | External to project | Inside project (VLAN 10, VM 181) |
| **Lifecycle** | Persistent, survives rebuilds | Part of project, can be destroyed/recreated |
| **Authentication** | Proxmox API tokens | SSH keys to VMs |
| **Scope** | Creates/destroys environment | Configures running VMs |
| **Example Task** | "Clone template to create DC01" | "Install Samba on DC01" |
| **Dependencies** | Proxmox API, Python proxmoxer | SSH access, target OS packages |
| **Failure Impact** | Cannot provision new VMs | Cannot configure applications |

### 4.2 Infrastructure Provisioning Responsibilities

**Network Infrastructure:**
1. Create Linux bridges (vmbr0, vmbr1, vmbr2)
2. Configure VLAN tagging
3. Define IP addressing schemes
4. Configure Proxmox firewall rules

**Storage Management:**
2. Configure LVM-thin storage pools
3. Set thin provisioning parameters
4. Define backup storage locations
5. Manage storage quotas

**Resource Organization:**
6. Create and manage resource pools
7. Apply tags for categorization
8. Document VM purposes (descriptions)
9. Implement naming conventions

### 4.3 VM Lifecycle Management

**Template Operations:**
1. Create base OS templates (Oracle Linux 9, Ubuntu 22.04)
2. Prepare templates (cloud-init, cleanup)
3. Version and update templates
4. Test template validity

**VM Provisioning:**
5. Clone templates to create VMs
6. Configure VM resources (CPU, RAM, disk)
7. Assign to networks and VLANs
8. Apply metadata (tags, descriptions, pools)
9. Start/stop VMs

**Environment Operations:**
10. Deploy complete 11-VM environment
11. Tear down environment cleanly
12. Reset environment (destroy + redeploy)
13. Create snapshots for rollback points

### 4.4 Backup and Recovery

**Backup Management:**
1. Configure automated backup jobs
2. Define retention policies
3. Test backup restore procedures
4. Monitor backup job status

**Disaster Recovery:**
5. Document recovery procedures
6. Maintain infrastructure-as-code repository
7. Test environment rebuild from scratch

---

## 5. Technical Specifications

> **📋 Business Summary:** This section describes the hardware and software needed for the Project Ansible Server. We have two deployment options: running it on a developer's computer (cheaper, simpler) or as a dedicated virtual machine (more professional, always available).

### 5.1 Deployment Options

**Where Should the Project Ansible Server Run?**

#### Option 1: External Development Workstation (Recommended for Development)

| Component | Specification |
|-----------|---------------|
| **Platform** | Developer's laptop/workstation (Linux or macOS) |
| **OS** | Ubuntu 22.04, Fedora 39, Arch Linux, macOS 13+ |
| **Network** | Direct IP access to Proxmox host (port 8006) |
| **Python** | 3.9 or higher |
| **Ansible** | 2.14 or higher |
| **Storage** | 20GB free (for playbooks, roles, logs) |
| **RAM** | 4GB minimum (8GB recommended) |

**Advantages:**
- ✅ No Proxmox VM resources consumed
- ✅ Survives project environment rebuilds
- ✅ Developer's familiar environment and tools
- ✅ Can manage multiple Proxmox hosts

**Disadvantages:**
- ❌ Requires developer workstation always available
- ❌ Potential for configuration drift across developers

#### Option 2: Dedicated Management VM (Recommended for Production)

| Component | Specification |
|-----------|---------------|
| **VM ID** | 90 (reserved management range) |
| **Hostname** | ansible-project.lab.local |
| **IP Address** | 10.0.10.5/24 (Management VLAN, outside SMB range) |
| **OS** | Oracle Linux 9 or Ubuntu 22.04 Server |
| **vCPU** | 2 cores |
| **RAM** | 2GB (lightweight automation workload) |
| **Disk** | 32GB (thin provisioned) |
| **Network** | vmbr0 (Management VLAN 10) |
| **Priority** | HIGH (needed for infrastructure management) |
| **Backup** | Daily (critical for disaster recovery) |
| **Tags** | `project-management`, `ansible-control`, `infrastructure` |

**Advantages:**
- ✅ Always available (runs 24/7)
- ✅ Consistent environment
- ✅ Easy remote access
- ✅ Can run scheduled automation

**Disadvantages:**
- ❌ Consumes Proxmox resources
- ❌ Requires careful bootstrap (chicken-and-egg)

**Recommendation:** Start with Option 1 (developer workstation) during initial development and testing. Migrate to Option 2 for production deployment once playbooks are stable.

### 5.2 Software Requirements

#### Core Components

| Software | Version | Installation | Purpose |
|----------|---------|--------------|---------|
| **Ansible** | 2.14+ | `dnf install ansible-core` or `pip3 install ansible` | Automation engine |
| **Python** | 3.9+ | System package manager | Ansible runtime |
| **proxmoxer** | 2.0+ | `pip3 install proxmoxer` | Proxmox API Python library |
| **requests** | 2.28+ | `pip3 install requests` | HTTP library for API calls |
| **paramiko** | 3.0+ | Included with Ansible | SSH library |
| **jinja2** | 3.1+ | Included with Ansible | Template engine |
| **PyYAML** | 6.0+ | Included with Ansible | YAML parsing |

#### Ansible Collections

Collections must be installed via `ansible-galaxy`:

```yaml
# requirements.yml
collections:
  - name: community.general
    version: ">=7.0.0"
    # Contains proxmox_kvm, proxmox_template, proxmox modules

  - name: ansible.posix
    version: ">=1.5.0"
    # File operations, user management

  - name: community.crypto
    version: ">=2.0.0"
    # Certificate management, SSH key generation
```

**Installation:**
```bash
ansible-galaxy collection install -r requirements.yml
```

#### Additional Tools

| Tool | Purpose |
|------|---------|
| `git` | Version control for playbooks and roles |
| `jq` | JSON parsing for API responses and testing |
| `curl` | Manual API testing and debugging |
| `ssh` | Direct Proxmox host access (if needed) |
| `ansible-lint` | Playbook linting and best practice validation |
| `yamllint` | YAML syntax validation |

---

## 6. Proxmox Integration

> **📋 Business Summary:** This section explains how the Project Ansible Server securely connects to Proxmox (the virtualization platform). We create a dedicated user account with minimal permissions following security best practices—similar to how you wouldn't give a contractor the master key to your entire building, just access to the areas they need to work in.

### 6.1 Proxmox User and Permissions

**Security Approach: Principle of Least Privilege**

Instead of using the powerful "root" administrator account (which has access to everything), we create a dedicated account specifically for the Project Ansible Server with only the permissions it needs to do its job.

#### Create Dedicated Project User

**Execute on Proxmox host:**

```bash
# Create user in Proxmox VE realm
pveum user add ansible-project@pve --comment "Ansible Project Automation User"

# Set password (used for initial setup, then switch to API token)
pveum passwd ansible-project@pve
```

#### Define Custom Role

Standard Proxmox roles are too broad. Create a custom role with minimum required permissions:

```bash
# Create custom role
pveum role add ProjectAutomation \
  --privs "VM.Allocate VM.Audit VM.Config.CDROM VM.Config.CPU VM.Config.Cloudinit \
           VM.Config.Disk VM.Config.HWType VM.Config.Memory VM.Config.Network \
           VM.Config.Options VM.Clone VM.Console VM.PowerMgmt VM.Monitor \
           Datastore.Allocate Datastore.Audit Pool.Allocate Pool.Audit Sys.Audit \
           SDN.Audit SDN.Allocate"
```

**Permission Breakdown:**

| Category | Permission | Justification |
|----------|------------|---------------|
| **VM Management** | `VM.Allocate` | Create new VMs |
| | `VM.Audit` | Read VM configuration |
| | `VM.Config.*` | Modify VM settings (CPU, RAM, disk, network, etc.) |
| | `VM.Clone` | Clone templates to create VMs |
| | `VM.PowerMgmt` | Start, stop, reset VMs |
| | `VM.Monitor` | View VM status and resource usage |
| **Storage** | `Datastore.Allocate` | Allocate disk space for VMs |
| | `Datastore.Audit` | Read storage configuration |
| **Pools** | `Pool.Allocate` | Create and modify resource pools |
| | `Pool.Audit` | Read pool configuration |
| **System** | `Sys.Audit` | Read cluster/node configuration |
| **Network** | `SDN.Audit`, `SDN.Allocate` | Manage software-defined networking |

#### Assign Role to User

```bash
# Grant permissions at root level (access to all resources)
pveum acl modify / --user ansible-project@pve --role ProjectAutomation
```

#### Create API Token (Recommended over Password)

API tokens are more secure than passwords for automation:

```bash
# Create API token for user
pveum user token add ansible-project@pve project-automation --privsep 0

# Output will show token ID and secret (save securely!)
# ┌──────────────┬──────────────────────────────────────┐
# │ key          │ value                                │
# ╞══════════════╪══════════════════════════════════════╡
# │ full-tokenid │ ansible-project@pve!project-automation│
# ├──────────────┼──────────────────────────────────────┤
# │ info         │ {"privsep":0}                        │
# ├──────────────┼──────────────────────────────────────┤
# │ value        │ xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx │
# └──────────────┴──────────────────────────────────────┘
```

**⚠️ Important:** Save the token value immediately. It's only shown once and cannot be retrieved later.

**Store in Ansible Vault:**

```yaml
# group_vars/all/vault.yml (encrypted)
vault_proxmox_api_token_id: "project-automation"
vault_proxmox_api_token_secret: "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx"
```

### 6.2 Proxmox API Access

#### API Endpoint Configuration

| Parameter | Value | Notes |
|-----------|-------|-------|
| **URL** | `https://proxmox-host:8006/api2/json` | Use hostname or IP |
| **Protocol** | HTTPS (TLS/SSL) | Self-signed cert acceptable for lab |
| **Auth Method** | API Token (preferred) or Username/Password | Token is stateless and revocable |
| **Content-Type** | `application/json` | All API calls use JSON |

#### Required API Endpoints

| Operation | API Endpoint | Method | Purpose |
|-----------|-------------|--------|---------|
| **Cluster Info** | `/api2/json/cluster/resources` | GET | List all resources |
| **List VMs** | `/api2/json/nodes/{node}/qemu` | GET | Inventory discovery |
| **Create VM** | `/api2/json/nodes/{node}/qemu` | POST | VM provisioning |
| **Clone VM** | `/api2/json/nodes/{node}/qemu/{vmid}/clone` | POST | Template cloning |
| **Get VM Config** | `/api2/json/nodes/{node}/qemu/{vmid}/config` | GET | Read configuration |
| **Update VM** | `/api2/json/nodes/{node}/qemu/{vmid}/config` | PUT | Modify resources |
| **VM Status** | `/api2/json/nodes/{node}/qemu/{vmid}/status/current` | GET | Check if running |
| **Start VM** | `/api2/json/nodes/{node}/qemu/{vmid}/status/start` | POST | Power on |
| **Stop VM** | `/api2/json/nodes/{node}/qemu/{vmid}/status/stop` | POST | Power off |
| **Delete VM** | `/api2/json/nodes/{node}/qemu/{vmid}` | DELETE | Remove VM |
| **List Pools** | `/api2/json/pools` | GET | Read pools |
| **Create Pool** | `/api2/json/pools` | POST | Create pool |
| **Update Pool** | `/api2/json/pools/{poolid}` | PUT | Add/remove VMs |
| **Network Config** | `/api2/json/nodes/{node}/network` | GET/POST/PUT | Manage bridges/VLANs |
| **Storage Info** | `/api2/json/storage` | GET | List storage pools |

#### SSL Certificate Handling

Proxmox uses self-signed certificates by default in lab environments.

**For Lab/Development (Self-Signed Cert):**

```yaml
# In playbook variables
proxmox_api_validate_certs: false
```

**For Production (Proper CA-Signed Cert):**

```yaml
proxmox_api_validate_certs: true
proxmox_api_ca_cert: /path/to/ca-cert.pem  # Optional custom CA
```

#### Example Ansible Configuration

```yaml
# group_vars/proxmox/vars.yml
proxmox_api_host: "192.168.1.100"
proxmox_api_user: "ansible-project@pve"
proxmox_api_token_id: "{{ vault_proxmox_api_token_id }}"
proxmox_api_token_secret: "{{ vault_proxmox_api_token_secret }}"
proxmox_api_validate_certs: false
proxmox_node: "pve"  # Node name from Proxmox cluster
```

### 6.3 API Error Handling

**Requirements:**

Playbooks must handle common API errors:

| Error Code | Meaning | Ansible Handling |
|------------|---------|------------------|
| 401 | Authentication failed | Fail with clear message about token/credentials |
| 403 | Permission denied | Fail with message about required permissions |
| 404 | Resource not found | Conditionally create or skip |
| 500 | Proxmox internal error | Retry with backoff, then fail |
| 503 | Service unavailable | Retry with backoff, then fail |

**Example Error Handling:**

```yaml
- name: Create VM
  community.general.proxmox_kvm:
    api_user: "{{ proxmox_api_user }}"
    # ... configuration
  register: vm_create
  failed_when:
    - vm_create.failed
    - "'already exists' not in vm_create.msg"
  retries: 3
  delay: 5
```

---

## 7. Network Configuration

> **📋 Business Summary:** This section defines the three separate networks (VLANs) that isolate different types of traffic. Think of it like having separate hallways in a building: one for management/maintenance staff, one for servers, and one for employee workstations. This improves security by preventing unauthorized access between different areas.

### 7.1 VLAN Design

**Network Segmentation Strategy:**

The project requires three isolated network segments:

| VLAN ID | Name | Subnet | Gateway | Purpose | Bridge |
|---------|------|--------|---------|---------|--------|
| **10** | Management | 10.0.10.0/24 | 10.0.10.1 | Proxmox management, Project Ansible, admin SSH | vmbr0 |
| **20** | SMB Servers | 10.0.20.0/24 | 10.0.20.1 | Infrastructure VMs (DC, file, print servers) | vmbr1 |
| **30** | SMB Workstations | 10.0.30.0/24 | 10.0.30.1 | User workstation VMs | vmbr2 |

**IP Allocation:**

| VLAN | Range | Assignment |
|------|-------|------------|
| 10 | .1-.10 | Proxmox host, gateways, infrastructure |
| 10 | .11-.50 | Management VMs (Project Ansible, monitoring) |
| 10 | .51-.99 | Reserved for expansion |
| 20 | .1-.10 | Reserved (gateway, DNS forwarders) |
| 20 | .11-.30 | Infrastructure services (DC01=.11, DC02=.12, FILES01=.21, etc.) |
| 20 | .31-.99 | Reserved for additional services |
| 30 | .1-.10 | Reserved |
| 30 | .11-.99 | Workstation VMs (sequential by department) |

### 7.2 Linux Bridge Configuration

**Requirements:**

Ansible must configure three Linux bridges on Proxmox host:

```bash
# /etc/network/interfaces (target configuration)

# Management Bridge (untagged, Proxmox host access)
auto vmbr0
iface vmbr0 inet static
    address 10.0.10.1/24
    bridge-ports eno1
    bridge-stp off
    bridge-fd 0
    bridge-vlan-aware yes
    # Proxmox host management IP

# Server VLAN Bridge (tagged VLAN 20)
auto vmbr1
iface vmbr1 inet manual
    bridge-ports eno1
    bridge-stp off
    bridge-fd 0
    bridge-vlan-aware yes
    bridge-vids 20
    # VMs on this bridge use VLAN tag 20

# Workstation VLAN Bridge (tagged VLAN 30)
auto vmbr2
iface vmbr2 inet manual
    bridge-ports eno1
    bridge-stp off
    bridge-fd 0
    bridge-vlan-aware yes
    bridge-vids 30
    # VMs on this bridge use VLAN tag 30
```

**Ansible Implementation:**

```yaml
# roles/proxmox_network/tasks/configure_bridges.yml
- name: Configure network bridges
  template:
    src: network_interfaces.j2
    dest: /etc/network/interfaces
    backup: yes
    validate: '/sbin/ifup -n -a -i %s'
  notify: restart networking

# Note: Network restart may disconnect Ansible.
# Consider manual network reload or planned maintenance window.
```

### 7.3 Firewall Rules (Network Isolation)

**VLAN Isolation Requirements:**

| Source VLAN | Destination VLAN | Allowed Services | Blocked Services | Justification |
|-------------|------------------|------------------|------------------|---------------|
| **30 (Workstations)** | **20 (Servers)** | DNS (53), LDAP (389/636), Kerberos (88), SMB (445) | SSH (22), Proxmox API, management ports | Users need services, not admin access |
| **30 (Workstations)** | **10 (Management)** | **DENY ALL** | All traffic | Workstations have no business on management network |
| **20 (Servers)** | **30 (Workstations)** | **DENY ALL** | All traffic | Servers don't initiate connections to workstations |
| **10 (Management)** | **20 (Servers)** | SSH (22), HTTP/HTTPS (for monitoring) | - | Admin access to servers |
| **10 (Management)** | **30 (Workstations)** | SSH (22), VNC (for console access) | - | Admin access to workstations |

**Ansible Configuration:**

```yaml
# group_vars/proxmox/firewall_rules.yml
proxmox_firewall_rules:
  # Block workstation to management
  - name: "Drop VLAN 30 to VLAN 10"
    action: DROP
    source: 10.0.30.0/24
    dest: 10.0.10.0/24
    enabled: yes
    log: yes

  # Block servers to workstations
  - name: "Drop VLAN 20 to VLAN 30"
    action: DROP
    source: 10.0.20.0/24
    dest: 10.0.30.0/24
    enabled: yes

  # Allow workstations to server services
  - name: "Allow DNS from workstations"
    action: ACCEPT
    proto: udp
    dport: 53
    source: 10.0.30.0/24
    dest: 10.0.20.0/24
    enabled: yes

  # ... (additional rules)
```

---

## 8. Storage Management

### 8.1 Storage Pool Configuration

**Required Storage Pools:**

| Pool Name | Type | Path | Size | Content Types | Purpose |
|-----------|------|------|------|---------------|---------|
| `local` | directory | `/var/lib/vz` | 100GB | vztmpl, iso, snippets | ISO images, CT templates |
| `local-lvm` | LVM-thin | `/dev/pve/data` | 400GB | images, rootdir | VM disks (thin provisioned) |
| `smb-backups` | directory | `/mnt/backups` | 200GB | backup | VM backups |

**Ansible Configuration:**

```yaml
# group_vars/proxmox/storage.yml
proxmox_storage_pools:
  - name: local-lvm
    type: lvmthin
    content: ["images", "rootdir"]
    thinpool: data
    vgname: pve

  - name: smb-backups
    type: dir
    path: /mnt/backups
    content: ["backup"]
    maxfiles: 7  # Keep last 7 backups
```

### 8.2 Thin Provisioning Settings

**LVM-Thin Configuration:**

```yaml
lvm_thin_config:
  # Warning threshold (send alert when pool reaches this %)
  warning_threshold: 75

  # Critical threshold (emergency cleanup)
  critical_threshold: 85

  # Autoextend threshold (automatically grow pool)
  autoextend_threshold: 80
  autoextend_percent: 20  # Grow by 20% when threshold reached
```

**Monitoring Requirement:**

Daily check of thin pool usage:

```bash
# /etc/cron.daily/check-thin-pool
#!/bin/bash
USAGE=$(lvs --noheadings -o data_percent pve/data | tr -d ' %')
if [ $USAGE -gt 80 ]; then
  echo "WARNING: Thin pool at ${USAGE}% capacity" | mail -s "Proxmox Storage Alert" admin@example.com
fi
```

---

## 9. Resource Pools and Tagging

### 9.1 Resource Pool Structure

**Pools to Create:**

| Pool ID | Pool Name | Description | Expected VMs | Purpose |
|---------|-----------|-------------|--------------|---------|
| `pool-smb-infra` | SMB Infrastructure | Critical SMB infrastructure services | 111, 112, 121, 122 | DC01, DC02, FILES01, PRINT01 |
| `pool-smb-workstations` | SMB Workstations | Employee workstation VMs | 131, 134, 142, 153, 165, 176 | All 6 workstation VMs |
| `pool-smb-mgmt` | SMB Management | SMB automation and management | 181 | MGMT01 (SMB Ansible Server) |
| `pool-templates` | Project Templates | OS templates for cloning | 100, 101 | OL9, Ubuntu templates |
| `pool-project-test` | Project Testing | Test and development VMs | 900-999 | Ad-hoc testing VMs |

**Ansible Implementation:**

```yaml
# roles/proxmox_pools/tasks/create_pools.yml
- name: Create resource pools
  community.general.proxmox_pool:
    api_user: "{{ proxmox_api_user }}"
    api_token_id: "{{ proxmox_api_token_id }}"
    api_token_secret: "{{ proxmox_api_token_secret }}"
    api_host: "{{ proxmox_api_host }}"
    poolid: "{{ item.id }}"
    comment: "{{ item.description }}"
    state: present
  loop:
    - { id: "pool-smb-infra", description: "SMB Infrastructure Services" }
    - { id: "pool-smb-workstations", description: "SMB Employee Workstations" }
    - { id: "pool-smb-mgmt", description: "SMB Management and Automation" }
    - { id: "pool-templates", description: "OS Templates" }
    - { id: "pool-project-test", description: "Project Testing VMs" }
```

### 9.2 Tagging Strategy

**Tag Categories:**

**By Function:**
- `domain-controller`
- `file-server`
- `print-server`
- `workstation`
- `management`
- `template`

**By Priority:**
- `critical` - Must stay running (DC01, DC02)
- `high` - Important (FILES01, MGMT01, FIN-WS01, EXEC-WS01)
- `medium` - Standard (most workstations, PRINT01)
- `low` - Can be stopped anytime (INTERN-WS01)

**By Environment:**
- `smb-production` - Live SMB environment
- `smb-staging` - Testing environment (if created)
- `project-test` - Project testing VMs

**By Operating System:**
- `oracle-linux-9`
- `ubuntu-22.04`

**By Backup Schedule:**
- `backup-daily`
- `backup-weekly`
- `backup-monthly`
- `no-backup`

**Tag Application:**

```yaml
# Example: DC01 tags
vm_tags: "domain-controller,critical,smb-production,oracle-linux-9,backup-daily"
```

---

## 10. VM Template Management

### 10.1 Template Requirements

**Templates to Create:**

| Template ID | Name | Base OS | Disk Size | Cloud-Init | Purpose |
|-------------|------|---------|-----------|------------|---------|
| 100 | ol9-template | Oracle Linux 9.3 | 32GB | Yes | Infrastructure VMs (DC, file, print, MGMT) |
| 101 | ubuntu2204-template | Ubuntu 22.04 LTS Desktop | 32GB | Yes | Workstation VMs (all 6 workstations) |

### 10.2 Template Preparation Process

**Automated Preparation Steps:**

1. **Base OS Installation** (Manual or scripted)
   - Minimal/server install
   - Single root partition
   - No swap (or small swap)
   - Standard partitioning (not LVM inside VM)

2. **System Updates**
   ```bash
   # Oracle Linux
   dnf update -y

   # Ubuntu
   apt update && apt upgrade -y
   ```

3. **Install Required Packages**
   ```bash
   # Oracle Linux
   dnf install -y cloud-init cloud-utils-growpart qemu-guest-agent

   # Ubuntu
   apt install -y cloud-init cloud-guest-utils qemu-guest-agent
   ```

4. **Configure Cloud-Init**
   ```bash
   # Enable network config via cloud-init
   cat > /etc/cloud/cloud.cfg.d/99_pve.cfg << EOF
   datasource_list: [NoCloud, ConfigDrive]
   EOF

   # Enable qemu-guest-agent
   systemctl enable qemu-guest-agent
   ```

5. **System Cleanup**
   ```bash
   # Remove SSH host keys (regenerated on clone)
   rm -f /etc/ssh/ssh_host_*

   # Clear machine-id (regenerated on clone)
   truncate -s 0 /etc/machine-id
   rm /var/lib/dbus/machine-id
   ln -s /etc/machine-id /var/lib/dbus/machine-id

   # Clean cloud-init state
   cloud-init clean --logs --seed

   # Clean package cache
   # Oracle Linux:
   dnf clean all
   # Ubuntu:
   apt clean

   # Clear logs
   find /var/log -type f -exec truncate -s 0 {} \;

   # Clear bash history
   history -c
   > ~/.bash_history

   # Power off
   poweroff
   ```

6. **Convert to Template**
   ```bash
   # On Proxmox host
   qm template 100  # For OL9 template
   qm template 101  # For Ubuntu template
   ```

**Ansible Automation:**

```yaml
# playbooks/create-templates.yml
- name: Prepare VM as template
  hosts: template_vms
  become: yes
  tasks:
    - name: Update system
      # ... (tasks above)

    - name: Clean up
      # ... (cleanup tasks)

# Then on Proxmox host
- name: Convert to template
  community.general.proxmox_kvm:
    api_user: "{{ proxmox_api_user }}"
    vmid: "{{ item }}"
    template: yes
  loop: [100, 101]
```

### 10.3 Template Updates

**Monthly Update Process:**

1. Clone existing template to temporary VM
2. Start temp VM
3. Apply OS updates
4. Run cleanup scripts
5. Test VM functionality
6. Stop VM
7. Create new versioned template (e.g., `ol9-template-v2`)
8. Test new template with single VM deployment
9. Update inventory to use new template version
10. Archive old template (keep for 1 month before deletion)

**Playbook:** `playbooks/update-templates.yml`

---

## 11. VM Cloning and Provisioning

### 11.1 Clone Requirements

**Per-VM Configuration:**

Each VM must be configured with:
- ✅ Unique VM ID
- ✅ Unique hostname
- ✅ Appropriate resource allocation (CPU, RAM, disk)
- ✅ Correct network assignment (bridge and VLAN)
- ✅ Static IP address (via cloud-init)
- ✅ Pool membership
- ✅ Tags for organization
- ✅ Description/notes

### 11.2 Inventory-Driven Deployment

**VM Inventory Definition:**

```yaml
# inventory/project_vms.yml
project_vms:
  domain_controllers:
    - vm_id: 111
      name: DC01
      hostname: dc01.smboffice.local
      template: ol9-template
      cores: 2
      memory: 2048
      balloon: 0
      disk_size: 32
      vlan: 20
      bridge: vmbr1
      ip: 10.0.20.11/24
      gateway: 10.0.20.1
      nameservers: ["10.0.20.11", "10.0.20.12"]
      pool: pool-smb-infra
      tags: ["domain-controller", "critical", "backup-daily", "oracle-linux-9"]
      description: |
        Primary Samba AD Domain Controller
        Domain: smboffice.local
        Services: AD, DNS, Kerberos
        Priority: CRITICAL

    - vm_id: 112
      name: DC02
      hostname: dc02.smboffice.local
      template: ol9-template
      cores: 2
      memory: 2048
      balloon: 0
      disk_size: 32
      vlan: 20
      bridge: vmbr1
      ip: 10.0.20.12/24
      gateway: 10.0.20.1
      nameservers: ["10.0.20.11", "10.0.20.12"]
      pool: pool-smb-infra
      tags: ["domain-controller", "critical", "backup-daily", "oracle-linux-9"]
      description: |
        Secondary Samba AD Domain Controller (Replica)
        Domain: smboffice.local
        Services: AD, DNS, Kerberos
        Priority: CRITICAL

  # ... (continue for all 11 VMs)
```

### 11.3 Deployment Playbook

**Full Deployment Workflow:**

```yaml
# playbooks/deploy-smb-environment.yml
---
- name: Deploy Complete SMB Environment
  hosts: localhost
  gather_facts: no

  tasks:
    - name: Load VM inventory
      include_vars:
        file: ../inventory/project_vms.yml

    - name: Clone VMs from templates
      community.general.proxmox_kvm:
        api_user: "{{ proxmox_api_user }}"
        api_token_id: "{{ proxmox_api_token_id }}"
        api_token_secret: "{{ proxmox_api_token_secret }}"
        api_host: "{{ proxmox_api_host }}"
        node: "{{ proxmox_node }}"
        clone: "{{ item.template }}"
        vmid: "{{ item.vm_id }}"
        name: "{{ item.name }}"
        full: yes
        pool: "{{ item.pool }}"
        storage: local-lvm
        timeout: 300
      loop: "{{ project_vms | dict2items | map(attribute='value') | flatten }}"
      async: 600
      poll: 0
      register: clone_jobs

    - name: Wait for all clones to complete
      async_status:
        jid: "{{ item.ansible_job_id }}"
      loop: "{{ clone_jobs.results }}"
      register: clone_results
      until: clone_results.finished
      retries: 60
      delay: 10

    - name: Configure VM resources
      community.general.proxmox_kvm:
        api_user: "{{ proxmox_api_user }}"
        api_token_id: "{{ proxmox_api_token_id }}"
        api_token_secret: "{{ proxmox_api_token_secret }}"
        api_host: "{{ proxmox_api_host }}"
        node: "{{ proxmox_node }}"
        vmid: "{{ item.vm_id }}"
        cores: "{{ item.cores }}"
        memory: "{{ item.memory }}"
        balloon: "{{ item.balloon }}"
        tags: "{{ item.tags | join(',') }}"
        description: "{{ item.description }}"
        update: yes
      loop: "{{ project_vms | dict2items | map(attribute='value') | flatten }}"

    - name: Configure VM network
      community.general.proxmox_kvm:
        api_user: "{{ proxmox_api_user }}"
        api_token_id: "{{ proxmox_api_token_id }}"
        api_token_secret: "{{ proxmox_api_token_secret }}"
        api_host: "{{ proxmox_api_host }}"
        node: "{{ proxmox_node }}"
        vmid: "{{ item.vm_id }}"
        net:
          net0: "virtio,bridge={{ item.bridge }},tag={{ item.vlan }}"
        ipconfig:
          ipconfig0: "ip={{ item.ip }},gw={{ item.gateway }}"
        nameserver: "{{ item.nameservers | join(' ') }}"
        update: yes
      loop: "{{ project_vms | dict2items | map(attribute='value') | flatten }}"

    - name: Start infrastructure VMs
      community.general.proxmox_kvm:
        api_user: "{{ proxmox_api_user }}"
        api_token_id: "{{ proxmox_api_token_id }}"
        api_token_secret: "{{ proxmox_api_token_secret }}"
        api_host: "{{ proxmox_api_host }}"
        node: "{{ proxmox_node }}"
        vmid: "{{ item }}"
        state: started
      loop: [111, 112, 121, 122, 181]  # DC01, DC02, FILES01, PRINT01, MGMT01

    - name: Wait for VMs to boot
      wait_for:
        host: "{{ item }}"
        port: 22
        timeout: 300
      loop:
        - 10.0.20.11
        - 10.0.20.12
        - 10.0.20.21
        - 10.0.20.22
        - 10.0.10.20

    - name: Report deployment status
      debug:
        msg: "SMB Environment deployed successfully. Infrastructure VMs are running."
```

---

## 12. Firewall and Security

### 12.1 Proxmox Host Firewall

**Firewall Configuration Requirements:**

```yaml
proxmox_firewall_config:
  # Enable firewall
  enable: yes

  # Default input policy
  policy_in: DROP

  # Default output policy
  policy_out: ACCEPT

  # Enable logging
  log_level_in: info
  log_level_out: info
```

**Management Access Rules:**

```yaml
proxmox_firewall_rules_management:
  - name: "Allow SSH from admin network"
    action: ACCEPT
    proto: tcp
    dport: 22
    source: 10.0.10.0/24
    enabled: yes
    comment: "SSH access for administrators"

  - name: "Allow Proxmox web UI"
    action: ACCEPT
    proto: tcp
    dport: 8006
    source: 10.0.10.0/24
    enabled: yes
    comment: "Proxmox web interface"

  - name: "Allow Proxmox API from Ansible"
    action: ACCEPT
    proto: tcp
    dport: 8006
    source: "{{ ansible_control_ip }}"
    enabled: yes
    comment: "API access for automation"
```

### 12.2 Inter-VLAN Rules

See [Section 7.3](#73-firewall-rules-network-isolation) for complete VLAN isolation rules.

### 12.3 VM-Level Firewall

**Per-VM Firewall Control:**

```yaml
# Infrastructure VMs: Proxmox firewall disabled (use internal firewalld)
- name: Disable Proxmox firewall for infrastructure VMs
  community.general.proxmox_kvm:
    vmid: "{{ item }}"
    firewall: no
  loop: [111, 112, 121, 122, 181]

# Workstation VMs: Proxmox firewall enabled (additional security layer)
- name: Enable Proxmox firewall for workstations
  community.general.proxmox_kvm:
    vmid: "{{ item }}"
    firewall: yes
  loop: [131, 134, 142, 153, 165, 176]
```

---

## 13. Backup Configuration

> **📋 Business Summary:** This section defines automated backup schedules for different types of virtual machines. Critical servers (like domain controllers) are backed up daily, while less critical systems are backed up weekly or monthly. This is similar to how important financial records are backed up more frequently than archived documents.

### 13.1 Backup Jobs

**Backup Strategy: Frequency Based on Criticality**

**Required Backup Schedules:**

| Job Name | VM IDs | Schedule | Mode | Compression | Retention | Storage |
|----------|--------|----------|------|-------------|-----------|---------|
| `backup-critical-daily` | 111, 112, 121, 181 | Daily 02:00 | snapshot | zstd | 7 days | smb-backups |
| `backup-high-weekly` | 122, 134, 153 | Weekly Sun 03:00 | snapshot | zstd | 4 weeks | smb-backups |
| `backup-standard-weekly` | 131, 142, 165 | Weekly Sun 04:00 | snapshot | zstd | 4 weeks | smb-backups |
| `backup-low-monthly` | 176 | Monthly 1st Sun 05:00 | stop | zstd | 3 months | smb-backups |

**Ansible Configuration:**

```yaml
# roles/proxmox_backup/tasks/configure_jobs.yml
- name: Configure backup jobs
  community.general.proxmox_backup:
    api_user: "{{ proxmox_api_user }}"
    api_token_id: "{{ proxmox_api_token_id }}"
    api_token_secret: "{{ proxmox_api_token_secret }}"
    api_host: "{{ proxmox_api_host }}"
    schedule: "{{ item.schedule }}"
    mode: "{{ item.mode }}"
    vmid: "{{ item.vmids }}"
    storage: "{{ item.storage }}"
    compress: "{{ item.compress }}"
    maxfiles: "{{ item.maxfiles }}"
    enabled: yes
    mailto: admin@example.com
  loop:
    - { schedule: "02:00", mode: "snapshot", vmids: [111,112,121,181], storage: "smb-backups", compress: "zstd", maxfiles: 7 }
    - { schedule: "sun 03:00", mode: "snapshot", vmids: [122,134,153], storage: "smb-backups", compress: "zstd", maxfiles: 4 }
    - { schedule: "sun 04:00", mode: "snapshot", vmids: [131,142,165], storage: "smb-backups", compress: "zstd", maxfiles: 4 }
    - { schedule: "sun 05:00 month 1", mode: "stop", vmids: [176], storage: "smb-backups", compress: "zstd", maxfiles: 3 }
```

### 13.2 Backup Validation

**Monthly Backup Test Playbook:**

```yaml
# playbooks/test-backup-restore.yml
- name: Test backup restore procedure
  hosts: localhost
  vars:
    test_vm_id: 999
    backup_source_vm: 111  # DC01

  tasks:
    - name: Find latest backup for VM
      shell: |
        pvesh get /nodes/{{ proxmox_node }}/storage/smb-backups/content \
          --vmid {{ backup_source_vm }} \
          | jq -r '.[] | select(.volid | contains("backup")) | .volid' \
          | sort -r | head -1
      register: latest_backup

    - name: Restore backup to test VM
      community.general.proxmox:
        api_user: "{{ proxmox_api_user }}"
        archive: "{{ latest_backup.stdout }}"
        vmid: "{{ test_vm_id }}"
        storage: local-lvm
        command: restore

    - name: Start restored VM
      community.general.proxmox_kvm:
        vmid: "{{ test_vm_id }}"
        state: started

    - name: Wait for VM to boot
      wait_for:
        host: 10.0.99.99  # Test IP
        port: 22
        timeout: 300

    - name: Verify VM functionality
      shell: ssh root@10.0.99.99 'hostname'
      register: hostname_check

    - name: Assert hostname matches
      assert:
        that: "'dc01' in hostname_check.stdout"
        fail_msg: "Restored VM hostname does not match expected"

    - name: Clean up test VM
      community.general.proxmox_kvm:
        vmid: "{{ test_vm_id }}"
        state: absent
        force: yes
```

---

## 14. Project Lifecycle Automation

> **📋 Business Summary:** This section describes the three main operations: **Deploy** (build the entire environment), **Destroy** (tear it down safely), and **Reset** (destroy and rebuild). These operations enable rapid testing, training, and experimentation without manual work or risk of mistakes.

### 14.1 Full Environment Deployment

**One-Command Deployment:**

**Playbook:** `playbooks/deploy-smb-environment.yml`

**Deployment Steps:**

1. ✅ Verify Proxmox connectivity and authentication
2. ✅ Create/verify network bridges (vmbr0, vmbr1, vmbr2)
3. ✅ Create/verify resource pools
4. ✅ Clone all 11 VMs from templates (parallel execution)
5. ✅ Configure VM resources (CPU, RAM, disk)
6. ✅ Assign networks and IP addresses
7. ✅ Apply tags and descriptions
8. ✅ Configure backup jobs
9. ✅ Start infrastructure VMs (DC01, DC02, FILES01, PRINT01, MGMT01)
10. ✅ Wait for VMs to boot (SSH connectivity check)
11. ✅ Generate inventory file for SMB Ansible Server
12. ✅ Report deployment status

**Expected Runtime:** 15-30 minutes (depending on storage speed and CPU)

**Usage:**

```bash
cd /opt/project-ansible
ansible-playbook playbooks/deploy-smb-environment.yml --vault-password-file ~/.vault_pass

# Dry run (check mode)
ansible-playbook playbooks/deploy-smb-environment.yml --check

# Deploy specific group only
ansible-playbook playbooks/deploy-smb-environment.yml --tags domain_controllers
```

### 14.2 Environment Teardown

**Playbook:** `playbooks/destroy-smb-environment.yml`

**Destruction Steps:**

1. ✅ Interactive confirmation prompt (safety)
2. ✅ Optional: Create final backup snapshot
3. ✅ Stop all SMB VMs gracefully
4. ✅ Wait for clean shutdown
5. ✅ Remove VMs from resource pools
6. ✅ Delete all VMs (except templates)
7. ✅ Clean up orphaned disks
8. ✅ Optionally remove network configuration
9. ✅ Report cleanup status

**Safety Features:**
- Interactive confirmation required
- Dry-run mode (`--check`) shows what would be deleted
- Templates excluded from deletion
- Backup option before destruction

**Usage:**

```bash
# Destroy environment (with confirmation)
ansible-playbook playbooks/destroy-smb-environment.yml

# Dry run (see what would be deleted)
ansible-playbook playbooks/destroy-smb-environment.yml --check

# Backup before destroy
ansible-playbook playbooks/destroy-smb-environment.yml --extra-vars "backup_before_destroy=yes"

# Force destroy (no confirmation, DANGEROUS)
ansible-playbook playbooks/destroy-smb-environment.yml --extra-vars "confirm_destroy=yes"
```

### 14.3 Environment Reset

**Playbook:** `playbooks/reset-smb-environment.yml`

**Reset Workflow:**

```yaml
---
- name: Reset SMB Environment (Destroy + Deploy)
  import_playbook: destroy-smb-environment.yml

- name: Wait for cleanup
  pause:
    seconds: 30

- name: Deploy fresh environment
  import_playbook: deploy-smb-environment.yml
```

**Use Cases:**
- Testing automation changes
- Starting fresh after configuration errors
- Demonstrating deployment process
- Training and education

**Runtime:** ~20-40 minutes (teardown + deployment)

---

## 15. Security Requirements

> **📋 Business Summary:** This section outlines how we protect sensitive information (passwords, API tokens) and control access to systems. All secrets are encrypted, access is logged, and every change is tracked. This demonstrates enterprise-grade security practices.

### 15.1 Credential Management

**How We Protect Passwords and Secrets:**

**Ansible Vault Requirements:**

All sensitive data must be stored in encrypted Ansible Vault files:

```yaml
# group_vars/all/vault.yml (encrypted with ansible-vault)
vault_proxmox_api_user: "ansible-project@pve"
vault_proxmox_api_token_id: "project-automation"
vault_proxmox_api_token_secret: "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx"
vault_proxmox_root_password: "SecureRootPassword123!"  # Only if password auth required
```

**Vault Password Management:**

```bash
# Store vault password in secure file (not in git)
echo "my-vault-password" > ~/.vault_pass
chmod 600 ~/.vault_pass

# Configure Ansible to use vault password file
# In ansible.cfg:
[defaults]
vault_password_file = ~/.vault_pass

# Or use environment variable
export ANSIBLE_VAULT_PASSWORD_FILE=~/.vault_pass

# Or prompt at runtime
ansible-playbook playbook.yml --ask-vault-pass
```

**Creating/Editing Vault:**

```bash
# Create new encrypted file
ansible-vault create group_vars/all/vault.yml

# Edit encrypted file
ansible-vault edit group_vars/all/vault.yml

# View encrypted file
ansible-vault view group_vars/all/vault.yml

# Rekey (change vault password)
ansible-vault rekey group_vars/all/vault.yml
```

### 15.2 Access Control

**Project Ansible Server Access:**

If using dedicated VM (Option 2):
- ✅ SSH key-only authentication (no passwords)
- ✅ Firewall rules limiting SSH to admin IPs
- ✅ Sudo with password required (no NOPASSWD)
- ✅ Minimal installed packages
- ✅ Regular security updates

**Proxmox API Access:**

- ✅ API token preferred over username/password
- ✅ Token scoped to project resources only
- ✅ Regular token rotation (quarterly)
- ✅ Audit logging enabled
- ✅ Firewall rules limiting API access to Ansible server IP

### 15.3 Audit Logging

**Requirements:**

1. **Ansible Execution Logs:**
   - All playbook runs logged to `/var/log/ansible/`
   - Log retention: 90 days
   - Log format: JSON (for parsing)

2. **Proxmox Audit Log:**
   - All API calls logged (Proxmox built-in)
   - Review logs weekly
   - Alert on suspicious activity

3. **Git Commit Log:**
   - Every infrastructure change committed to git
   - Commit messages describe what and why
   - Tag releases/milestones
   - Never force-push to main branch

**Log Review Playbook:**

```yaml
# playbooks/audit-review.yml
- name: Generate audit report
  hosts: localhost
  tasks:
    - name: Collect Ansible logs
      shell: grep -r "ERROR\|FAILED" /var/log/ansible/ | tail -100
      register: ansible_errors

    - name: Query recent Proxmox API calls
      uri:
        url: "https://{{ proxmox_api_host }}:8006/api2/json/cluster/log"
        method: GET
        headers:
          Authorization: "PVEAPIToken={{ proxmox_api_user }}!{{ proxmox_api_token_id }}={{ proxmox_api_token_secret }}"
        validate_certs: no
      register: proxmox_log

    - name: Generate report
      template:
        src: audit-report.j2
        dest: "/tmp/audit-report-{{ ansible_date_time.date }}.html"
```

---

## 16. Documentation Standards

### 16.1 Playbook Documentation

**Every playbook must include header:**

```yaml
---
# Playbook: deploy-smb-environment.yml
# Purpose: Deploy complete SMB office infrastructure on Proxmox
# Author: IT Infrastructure Architect
# Created: 2025-12-25
# Updated: 2025-12-25
# Version: 1.0
#
# Requirements:
#   - Proxmox VE 8.0+
#   - Proxmox API token configured in vault
#   - Templates created (ol9-template, ubuntu2204-template)
#   - Network bridges configured (vmbr0, vmbr1, vmbr2)
#   - Python proxmoxer library installed
#
# Usage:
#   ansible-playbook deploy-smb-environment.yml
#   ansible-playbook deploy-smb-environment.yml --check  # Dry run
#   ansible-playbook deploy-smb-environment.yml --tags domain_controllers
#
# Variables:
#   proxmox_api_host: Proxmox hostname or IP (group_vars/proxmox/vars.yml)
#   proxmox_node: Proxmox node name (default: pve)
#   project_vms: VM inventory (inventory/project_vms.yml)
#
# Tags:
#   - network: Network configuration only
#   - pools: Resource pool creation only
#   - vms: VM deployment only
#   - backup: Backup configuration only
#
# Exit Codes:
#   0: Success
#   1: Proxmox API authentication failure
#   2: VM cloning failure
#   3: Network configuration failure

- name: Deploy SMB Environment
  hosts: localhost
  # ... playbook content
```

### 16.2 Role Documentation

**Each role must have README.md:**

```markdown
# Role: proxmox_network

## Purpose
Configures Linux bridges and VLAN tagging on Proxmox host for SMB environment.

## Requirements
- Proxmox VE 8.0+
- Ansible 2.14+
- Root SSH access to Proxmox host

## Variables

| Variable | Default | Description |
|----------|---------|-------------|
| `proxmox_bridges` | See defaults/main.yml | List of bridges to create |
| `proxmox_network_restart` | `no` | Whether to restart networking |

## Dependencies
None

## Example Playbook
```yaml
- hosts: proxmox_host
  roles:
    - role: proxmox_network
      vars:
        proxmox_network_restart: yes
```

## License
Internal Use Only

## Author
IT Infrastructure Architect
```

### 16.3 Inventory Documentation

**inventory/README.md must explain:**

- How inventory is structured
- VM ID numbering convention
- Network addressing scheme
- Variable precedence
- How to add new VMs

---

## 17. Testing Requirements

### 17.1 Pre-Deployment Testing

**Syntax Validation:**

```bash
# Check playbook syntax
ansible-playbook deploy-smb-environment.yml --syntax-check

# Expected output:
# playbook: deploy-smb-environment.yml
```

**Linting:**

```bash
# Lint all playbooks
ansible-lint playbooks/*.yml

# Lint specific playbook
ansible-lint playbooks/deploy-smb-environment.yml

# Fix auto-fixable issues
ansible-lint --fix playbooks/deploy-smb-environment.yml
```

**Dry Run (Check Mode):**

```bash
# Show what would change (no actual changes)
ansible-playbook deploy-smb-environment.yml --check --diff

# Expected output shows:
# - What would be created
# - What would be modified
# - No actual changes made
```

### 17.2 Post-Deployment Validation

**Validation Playbook:** `playbooks/validate-deployment.yml`

**Validation Checks:**

```yaml
---
- name: Validate SMB Environment Deployment
  hosts: localhost

  tasks:
    - name: Check all VMs exist
      community.general.proxmox_kvm:
        api_user: "{{ proxmox_api_user }}"
        api_token_id: "{{ proxmox_api_token_id }}"
        api_token_secret: "{{ proxmox_api_token_secret }}"
        api_host: "{{ proxmox_api_host }}"
        node: "{{ proxmox_node }}"
        vmid: "{{ item }}"
        state: current
      loop: [111, 112, 121, 122, 131, 134, 142, 153, 165, 176, 181]
      register: vm_status

    - name: Assert all VMs exist
      assert:
        that: vm_status.results | length == 11
        fail_msg: "Not all VMs were created"

    - name: Check infrastructure VMs are running
      assert:
        that: item.status == "running"
        fail_msg: "VM {{ item.vmid }} is not running"
      loop: "{{ vm_status.results[0:5] }}"  # First 5 VMs should be running

    - name: Test network connectivity to infrastructure
      command: "ping -c 1 -W 2 {{ item }}"
      loop:
        - 10.0.20.11  # DC01
        - 10.0.20.12  # DC02
        - 10.0.20.21  # FILES01
        - 10.0.20.22  # PRINT01
        - 10.0.10.20  # MGMT01
      changed_when: false
      failed_when: false
      register: ping_results

    - name: Verify SSH access
      wait_for:
        host: "{{ item }}"
        port: 22
        timeout: 10
      loop:
        - 10.0.20.11
        - 10.0.20.12
        - 10.0.20.21
        - 10.0.10.20

    - name: Check resource pools exist
      uri:
        url: "https://{{ proxmox_api_host }}:8006/api2/json/pools/{{ item }}"
        method: GET
        headers:
          Authorization: "PVEAPIToken={{ proxmox_api_user }}!{{ proxmox_api_token_id }}={{ proxmox_api_token_secret }}"
        validate_certs: no
        status_code: 200
      loop:
        - pool-smb-infra
        - pool-smb-workstations
        - pool-smb-mgmt

    - name: Generate validation report
      template:
        src: templates/validation-report.j2
        dest: "/tmp/deployment-validation-{{ ansible_date_time.date }}.txt"

    - name: Display report
      command: "cat /tmp/deployment-validation-{{ ansible_date_time.date }}.txt"
      changed_when: false
```

### 17.3 Idempotency Testing

**Requirement:** Running playbook multiple times produces same result (no changes on second run)

**Test Procedure:**

```bash
# Run deployment first time
ansible-playbook deploy-smb-environment.yml | tee /tmp/run1.log

# Run deployment second time
ansible-playbook deploy-smb-environment.yml | tee /tmp/run2.log

# Check second run results
grep "changed=" /tmp/run2.log

# Expected output:
# PLAY RECAP *************************************************************
# localhost                  : ok=25   changed=0    unreachable=0    failed=0
#                                      ^^^^^^^^^^
# No changes on second run = idempotent ✓
```

---

## 18. Performance Requirements

### 18.1 Deployment Performance Targets

| Operation | Target Time | Maximum Acceptable | Notes |
|-----------|-------------|--------------------|-------|
| Full environment deployment (11 VMs) | 15 minutes | 30 minutes | Parallel cloning |
| Single VM clone and start | 1 minute | 3 minutes | Depends on template size |
| Template creation from prepared VM | 5 minutes | 10 minutes | Includes conversion |
| Environment teardown | 3 minutes | 10 minutes | Graceful shutdown + cleanup |
| Backup job configuration | 30 seconds | 2 minutes | API calls only |
| Network configuration | 1 minute | 5 minutes | May require network restart |

### 18.2 Optimization Strategies

**Parallel VM Cloning:**

```yaml
# Clone VMs in parallel using async
- name: Clone VMs from templates
  community.general.proxmox_kvm:
    # ... configuration
  loop: "{{ project_vms | flatten }}"
  async: 600        # 10 minute timeout per VM
  poll: 0           # Don't wait, run in parallel
  register: clone_jobs

# Wait for all clones to complete
- name: Wait for clones
  async_status:
    jid: "{{ item.ansible_job_id }}"
  loop: "{{ clone_jobs.results }}"
  register: clone_results
  until: clone_results.finished
  retries: 60
  delay: 10
```

**Efficient API Usage:**

- ✅ Batch operations where possible
- ✅ Reuse API connections
- ✅ Cache Proxmox node information
- ✅ Minimize API calls (get full config once, not per-attribute)

**Resource Efficiency:**

- ✅ Use Ansible `forks` setting for parallelism
- ✅ Limit concurrent API calls to avoid overwhelming Proxmox
- ✅ Use efficient polling intervals

**ansible.cfg optimization:**

```ini
[defaults]
forks = 10              # Parallel task execution
gathering = smart       # Only gather facts when needed
fact_caching = jsonfile # Cache facts to disk
fact_caching_timeout = 3600
```

---

## 19. Maintenance and Updates

### 19.1 Template Update Schedule

**Monthly Template Updates:**

**Process:**

1. Clone existing template to temporary VM (e.g., `ol9-template` → VM 199)
2. Start temporary VM
3. Apply OS updates:
   ```bash
   # Oracle Linux
   dnf update -y

   # Ubuntu
   apt update && apt upgrade -y
   ```
4. Run cleanup script (see Section 10.2)
5. Test VM functionality (boot, network, cloud-init)
6. Stop VM
7. Create new versioned template (e.g., `ol9-template-v2025-01`)
8. Test new template by deploying single VM
9. Update `project_vms.yml` to reference new template version
10. Archive old template (keep for 1 month before deletion)

**Automation:**

```bash
# Monthly cron job (first Sunday of month)
0 2 1-7 * * /opt/project-ansible/scripts/update-templates.sh
```

**Playbook:** `playbooks/update-templates.yml`

### 19.2 Ansible Collection Updates

**Quarterly Collection Updates:**

```bash
# Check for collection updates
ansible-galaxy collection list

# Update specific collection
ansible-galaxy collection install community.general --upgrade

# Update all collections from requirements.yml
ansible-galaxy collection install -r requirements.yml --upgrade

# Test with existing playbooks
ansible-playbook deploy-smb-environment.yml --check
```

**Testing:**

After updates:
1. Run syntax check on all playbooks
2. Run ansible-lint
3. Test deploy in dry-run mode (`--check`)
4. Deploy to test environment
5. Validate deployment
6. Commit changes to git

### 19.3 Playbook Version Control

**Semantic Versioning:**

```bash
# Tag releases
git tag -a v1.0.0 -m "Initial release"
git tag -a v1.1.0 -m "Add workstation deployment"
git tag -a v2.0.0 -m "Major refactor: role-based organization"

git push --tags
```

**Changelog Maintenance:**

```markdown
# CHANGELOG.md

## [1.2.0] - 2025-12-25
### Added
- Backup configuration automation
- VM description/notes setting
- Validation playbook

### Changed
- Parallel VM cloning for faster deployment
- Updated proxmoxer to 2.0.1

### Fixed
- Cloud-init nameserver configuration
- VLAN tagging on vmbr2
```

**Rollback Capability:**

```bash
# Checkout previous version
git checkout v1.1.0

# Run playbook from previous version
ansible-playbook playbooks/deploy-smb-environment.yml

# Return to latest
git checkout main
```

---

## 20. Disaster Recovery

> **📋 Business Summary:** This section explains how we recover from disasters like server failures, accidental deletions, or corrupted configurations. Clear recovery procedures and regular backups ensure we can restore operations quickly with minimal data loss.

### 20.1 Project Ansible Server Backup

**What Gets Backed Up and Why:**

**What to Backup:**

| Path | Content | Frequency | Retention |
|------|---------|-----------|-----------|
| `/opt/project-ansible/` | All playbooks, roles, inventory | Daily | 30 days |
| `~/.ssh/` | SSH keys | Weekly | 90 days |
| `~/.ansible/` | Ansible configuration | Weekly | 30 days |
| `~/.vault_pass` | Vault password | Manually (secure location) | Forever |
| `/var/log/ansible/` | Execution logs | Weekly | 90 days |

**Backup Script:**

```bash
#!/bin/bash
# /opt/project-ansible/scripts/backup-ansible-server.sh

BACKUP_DIR="/backup/project-ansible"
DATE=$(date +%Y%m%d-%H%M%S)
BACKUP_FILE="project-ansible-backup-${DATE}.tar.gz"

mkdir -p ${BACKUP_DIR}

# Create compressed archive
tar czf ${BACKUP_DIR}/${BACKUP_FILE} \
    /opt/project-ansible \
    ~/.ssh \
    ~/.ansible \
    ~/.vault_pass \
    /var/log/ansible

# Encrypt backup
gpg --encrypt --recipient admin@example.com \
    ${BACKUP_DIR}/${BACKUP_FILE}

# Remove unencrypted backup
rm ${BACKUP_DIR}/${BACKUP_FILE}

# Keep only last 30 backups
cd ${BACKUP_DIR}
ls -t *.tar.gz.gpg | tail -n +31 | xargs -r rm

echo "Backup completed: ${BACKUP_FILE}.gpg"

# Optional: Upload to cloud storage
# aws s3 cp ${BACKUP_DIR}/${BACKUP_FILE}.gpg s3://backups/project-ansible/
```

**Automate with Cron:**

```bash
# Daily backup at 1 AM
0 1 * * * /opt/project-ansible/scripts/backup-ansible-server.sh >> /var/log/backup.log 2>&1
```

### 20.2 Recovery Scenarios

#### Scenario 1: Lost Project Ansible Server

**Recovery Steps:**

1. Deploy new server (workstation or VM)
2. Install base requirements:
   ```bash
   # Install Ansible and dependencies
   dnf install -y ansible-core python3-pip git
   pip3 install proxmoxer requests
   ansible-galaxy collection install community.general ansible.posix
   ```
3. Restore backup:
   ```bash
   # Download latest backup
   aws s3 cp s3://backups/project-ansible/latest.tar.gz.gpg /tmp/

   # Decrypt
   gpg --decrypt /tmp/latest.tar.gz.gpg > /tmp/backup.tar.gz

   # Extract
   tar xzf /tmp/backup.tar.gz -C /
   ```
4. Configure Proxmox API access (verify vault password)
5. Test connectivity:
   ```bash
   ansible-playbook playbooks/test-connection.yml
   ```
6. Verify inventory:
   ```bash
   ansible-inventory --graph
   ```
7. Resume operations

**Recovery Time Objective (RTO):** 2 hours

#### Scenario 2: Corrupted Proxmox Network Configuration

**Recovery Steps:**

1. Review Proxmox configuration backups
2. Access Proxmox host console (not via network)
3. Re-run network configuration playbook:
   ```bash
   ansible-playbook playbooks/configure-proxmox-network.yml \
     --extra-vars "proxmox_ansible_connection=local"
   ```
4. Verify VMs still exist:
   ```bash
   ansible-playbook playbooks/validate-deployment.yml
   ```
5. Recreate pools/tags if needed

#### Scenario 3: Accidental VM Deletion

**Recovery Steps:**

1. Check if VM backup exists:
   ```bash
   pvesh get /nodes/pve/storage/smb-backups/content \
     --vmid 111 | grep backup
   ```
2. Restore from backup:
   ```bash
   ansible-playbook playbooks/restore-vm.yml \
     --extra-vars "vmid=111 backup_date=20251224"
   ```
3. If no backup, re-clone from template:
   ```bash
   ansible-playbook playbooks/deploy-smb-environment.yml \
     --tags vms --limit dc01
   ```
4. Reconfigure VM (IP, hostname, etc.)

**Recovery Time Objective (RTO):** 30 minutes

---

## 21. Success Criteria

> **📋 Business Summary:** This section defines what "done" looks like. These are the measurable outcomes we need to achieve for the project to be considered successful. Think of it as the acceptance checklist before signing off on a construction project.

**How Do We Know When We're Done?**

The Project Ansible Server implementation is considered successful when all of the following criteria are met:

### 21.1 Functional Requirements

- ✅ Can deploy complete SMB environment (11 VMs) with single command
- ✅ Can tear down environment cleanly and safely
- ✅ Can reset environment (destroy + redeploy) reliably
- ✅ Can create and update OS templates automatically
- ✅ Can configure Proxmox networks, pools, and tags
- ✅ All playbooks are idempotent (safe to run multiple times)
- ✅ Backup jobs configured and validated
- ✅ Full deployment completes in < 30 minutes

### 21.2 Security Requirements

- ✅ Proxmox API access uses dedicated token (not root password)
- ✅ All secrets stored in Ansible vault (encrypted)
- ✅ Firewall rules configured and tested
- ✅ Network isolation verified (VLAN-to-VLAN traffic blocked)
- ✅ Audit logging enabled and reviewed
- ✅ Least-privilege access implemented

### 21.3 Documentation Requirements

- ✅ All playbooks documented with header comments
- ✅ README files explain project structure
- ✅ Disaster recovery procedures documented
- ✅ Runbooks for common operations created
- ✅ Inventory structure explained
- ✅ Variable precedence documented

### 21.4 Quality Requirements

- ✅ All playbooks pass syntax check (`--syntax-check`)
- ✅ All playbooks pass linting (`ansible-lint`)
- ✅ Playbooks tested in dry-run mode (`--check`)
- ✅ Full deployment tested end-to-end
- ✅ Idempotency verified (second run shows 0 changes)
- ✅ Validation playbook confirms all resources exist

### 21.5 Performance Requirements

- ✅ Full deployment < 30 minutes
- ✅ Single VM clone < 3 minutes
- ✅ Environment teardown < 10 minutes
- ✅ Template creation < 10 minutes

### 21.6 Operational Requirements

- ✅ Backup automation configured
- ✅ Backup restore tested monthly
- ✅ Template update process documented
- ✅ Collection update process documented
- ✅ Disaster recovery tested
- ✅ Version control with git tags

---

## 22. Related Files

| File Path | Description |
|-----------|-------------|
| `/docs/standards/markdown.md` | Documentation standards (this document follows) |
| `/docs/standards/coding/Ansible.md` | Ansible coding standards |
| `/docs/requirements/smb-ansible-server-requirements.md` | MGMT01 (SMB Ansible Server) requirements |
| `/articles/04-ansible-control-server.md` | SMB Ansible Server setup article |
| `/implementation/ansible/` | Ansible playbooks and roles (encrypted) |

---

## 23. Review History

| Version | Date | Reviewer | Notes |
|---------|------|----------|-------|
| v1.0 | 2025-12-25 | IT Infrastructure Architect | Initial requirements draft |

---

## 24. Departmental Approval Checklist

| Department / Agent | Reviewed | Reviewer Notes |
|--------------------|----------|----------------|
| SMB Analyst | [ ] | |
| IT Business Analyst | [ ] | |
| Project Doc Auditor | [ ] | |
| IT Security Analyst | [ ] | |
| IT AD Architect | [ ] | |
| Linux Admin/Architect | [ ] | |
| Ansible Programmer | [ ] | |
| IT Code Auditor | [ ] | |
| SEO Analyst | [ ] | N/A - Internal document |
| Content Editor | [ ] | N/A - Internal document |
| Project Manager | [ ] | |
| Task Assistant | [ ] | |
