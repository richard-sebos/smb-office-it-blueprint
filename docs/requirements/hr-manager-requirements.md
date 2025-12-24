<!--
███████████████████████████████████████████████████████████████
  🔧 SMB Office IT Blueprint – System Requirements Document
  Doc ID: REQ-ROLE-HR-001
  Source: USECASE-ROLE-HR-001
  Author: IT Business Analyst
  Created: 2025-12-23
  Updated: 2025-12-23
  Version: v1.0
  Status: Draft
  Confidentiality: Restricted
  Project Phase: Requirements Analysis
  Category: Technical Requirements
  Audience: Technical
  Owners: IT Business Analyst, IT AD Architect, IT Ansible Programmer
  Reviewers: IT Security Analyst, Compliance & Risk Analyst
  Tags: [hr, personnel, pii, requirements, ansible, hipaa]
  Purpose: Ansible Automation
  Compliance: HIPAA-style Controls, Employment Standards
  Publish Target: Internal
  Summary: >
    Technical system requirements derived from the HR Manager use case
    for implementation via Ansible automation. Defines AD structure, file
    shares, permissions, workstation configuration, security controls, and
    audit logging for HIPAA-style compliance and employee data protection.
  Read Time: ~12 min
███████████████████████████████████████████████████████████████
-->

# 🔧 HR Manager – System Requirements Specification

**Source Use Case:** `USECASE-ROLE-HR-001` (hr-manager-use-case.md)
**Target Implementation:** Ansible Playbooks and Roles
**Related Roles:** Human Resources Department, Sensitive/Compliance-Critical

---

## 📍 Table of Contents

- [1. Overview](#1-overview)
- [2. Active Directory Requirements](#2-active-directory-requirements)
- [3. File Server Requirements](#3-file-server-requirements)
- [4. Workstation Requirements](#4-workstation-requirements)
- [5. Print Server Requirements](#5-print-server-requirements)
- [6. Application Server Requirements](#6-application-server-requirements)
- [7. Security Requirements](#7-security-requirements)
- [8. Monitoring and Audit Requirements](#8-monitoring-and-audit-requirements)
- [9. Compliance Requirements](#9-compliance-requirements)
- [10. Onboarding/Offboarding Automation](#10-onboardingoffboarding-automation)
- [11. Ansible Implementation Notes](#11-ansible-implementation-notes)
- [12. Validation and Testing](#12-validation-and-testing)
- [13. Dependencies](#13-dependencies)

---

## 1. Overview

### 1.1 Purpose

This document translates business requirements from the HR Manager use case into technical specifications for infrastructure automation via Ansible, with emphasis on HIPAA-style privacy controls and employee data protection.

### 1.2 Scope

This specification covers:
- Active Directory organizational units, groups, and user accounts
- HR-specific file server shares and ACL configurations
- Workstation provisioning with privacy-focused security controls
- Print server access configuration
- HR self-service application server
- Audit logging and compliance monitoring
- Security controls for PII and employee records
- Onboarding and offboarding workflow automation

### 1.3 Implementation Priority

**Priority Level:** High (Tier 1 - Business-Critical)
**Security Classification:** Restricted - Sensitive PII and Employee Data
**Compliance Framework:** HIPAA-style controls for employee health data, employment law standards

---

## 2. Active Directory Requirements

### 2.1 Organizational Unit Structure

**Requirement ID:** `REQ-AD-HR-001`

Create the following OU structure:

```
Domain: smboffice.local
└── OU=Users
    └── OU=HR
        ├── OU=HRManagers
        └── OU=HRStaff
```

**Ansible Implementation:**
- Use `community.windows.win_domain_ou` module or Samba AD equivalent
- Create OU hierarchy if not exists (idempotent)
- Apply descriptions:
  - HRManagers: "HR management and oversight roles"
  - HRStaff: "HR department staff and support roles"

---

### 2.2 Security Groups

**Requirement ID:** `REQ-AD-HR-002`

Create the following security groups:

| Group Name | Scope | Type | Description | OU Location |
|------------|-------|------|-------------|-------------|
| `GG-HR-Department` | Global | Security | Primary HR department group | `OU=Groups,OU=HR` |
| `SG-HR-Files-RW` | Domain Local | Security | Read/Write access to HR file shares | `OU=Groups,OU=HR` |
| `SG-Payroll-ReadOnly` | Domain Local | Security | Read-only access to Finance payroll data | `OU=Groups,OU=HR` |
| `SG-Policy-Docs` | Domain Local | Security | Access to company-wide policy documents | `OU=Groups,OU=Shared` |
| `SG-Onboarding-Access` | Domain Local | Security | Permission to write to onboarding logs and tools | `OU=Groups,OU=HR` |
| `SG-Printer-HR` | Domain Local | Security | HR printer access | `OU=Groups,OU=Infrastructure` |
| `SG-HR-Managers` | Global | Security | HR Manager role group (nested in others) | `OU=Groups,OU=HR` |

**Ansible Implementation:**
- Create groups with proper scope and type
- Document group purpose in AD description field
- Establish group nesting per access model

**Group Membership Rules:**
```yaml
# Nested group memberships (HR Manager inherits all HR access)
GG-HR-Department:
  members:
    - SG-HR-Managers

SG-HR-Files-RW:
  members:
    - GG-HR-Department

SG-Payroll-ReadOnly:
  members:
    - SG-HR-Managers  # Only managers access Finance payroll

SG-Policy-Docs:
  members:
    - GG-HR-Department
    - GG-Management
    - GG-Shared-Services

SG-Onboarding-Access:
  members:
    - GG-HR-Department
    - GG-IT-Admins  # IT needs access for account provisioning

SG-Printer-HR:
  members:
    - GG-HR-Department
```

---

### 2.3 User Account Template

**Requirement ID:** `REQ-AD-HR-003`

HR Manager user account specifications:

| Attribute | Value |
|-----------|-------|
| Username Format | `firstname.lastname` (lowercase) |
| Display Name | `FirstName LastName` |
| Email | `firstname.lastname@smboffice.local` |
| Title | `HR Manager` or `Human Resources Manager` |
| Department | `Human Resources` |
| Office | `HR Office` |
| Primary Group | `SG-HR-Managers` |
| Additional Groups | `GG-HR-Department` |
| Home Directory | `\\files01\users\%username%` |
| Profile Path | `\\files01\profiles\%username%` |
| Login Script | `\\files01\netlogon\hr-login.sh` |
| Account Options | User cannot change password expiration, must change at first login |
| Password Policy | 90-day expiration, 14 char minimum, complexity required |

**Example Accounts:**
- `jennifer.adams` (HR Manager, hr-ws01)
- `michael.chen` (HR Coordinator, hr-ws02)

**Ansible Implementation:**
- Use templates for consistent user creation
- Variable-based account provisioning
- Set account flags and password policies via AD attributes
- Add to security groups automatically

---

### 2.4 Group Policy Objects (GPOs)

**Requirement ID:** `REQ-AD-HR-004`

Create and link the following GPO:

**GPO Name:** `GPO-HR-Workstations`
**Linked to:** `OU=HR`

**Policy Settings:**

| Category | Setting | Value |
|----------|---------|-------|
| Password Policy | Minimum password length | 14 characters |
| Password Policy | Password complexity | Enabled |
| Password Policy | Maximum password age | 90 days |
| Password Policy | Password history | 10 passwords |
| Security Options | USB storage access | **Disabled** (PII protection) |
| Security Options | Software installation | Disabled for users |
| Security Options | Screen lock timeout | 10 minutes idle |
| Software Restriction | Prevent execution from Temp/Downloads | Enabled |
| Audit Policy | File access auditing | Success/Failure |
| Audit Policy | Account logon events | Success/Failure |
| Audit Policy | Object access | Success/Failure |
| Desktop | Disable removable media autoplay | Enabled |
| Desktop | Prevent Desktop modifications | Enabled |
| Desktop | Privacy settings enforcement | Enabled |
| Network | Disable Wi-Fi if wired connected | Enabled |

**Ansible Implementation:**
- For Samba AD: Configure via registry policies or samba-tool gpo
- Validate GPO application on test workstation before rollout
- Document all policy settings for audit purposes

---

## 3. File Server Requirements

### 3.1 File Server Infrastructure

**Requirement ID:** `REQ-FILE-HR-001`

**Server:** `files01.smboffice.local`
**Role:** Samba File Server with AD integration and audit logging
**OS:** Oracle Linux 9 (for SELinux support) or Ubuntu Server 22.04

**Additional Requirements:**
- Dedicated storage volume for HR data (encryption at rest **required**)
- Backup schedule: Daily incremental, weekly full
- Snapshot retention: 30 days
- Long-term archive: 7 years for employee records

---

### 3.2 Share Definitions

**Requirement ID:** `REQ-FILE-HR-002`

Create the following SMB shares:

#### Share 1: HR Department Files (Read/Write)

```yaml
share_name: hr
path: /srv/samba/shares/hr
comment: "Human Resources Department - Restricted Access"
valid_users: "@SG-HR-Files-RW"
read_list: "@SG-HR-Files-RW"
write_list: "@SG-HR-Files-RW"
create_mask: "0660"
directory_mask: "0770"
vfs_objects: "acl_xattr full_audit"
full_audit:prefix: "%u|%I|%m|%S"
full_audit:success: "mkdir rmdir write unlink rename"
full_audit:failure: "all"
full_audit:facility: "local5"
full_audit:priority: "notice"
browseable: no  # Hidden from browse lists for privacy
```

#### Share 2: HR Personnel Files (Highly Restricted - Managers Only)

```yaml
share_name: hr-personnel
path: /srv/samba/shares/hr/personnel
comment: "Employee Personnel Records - HR Manager Access Only"
valid_users: "@SG-HR-Managers"
read_list: "@SG-HR-Managers"
write_list: "@SG-HR-Managers"
create_mask: "0660"
directory_mask: "0770"
vfs_objects: "acl_xattr full_audit"
full_audit:prefix: "%u|%I|%m|%S"
full_audit:success: "all"
full_audit:failure: "all"
full_audit:facility: "local5"
full_audit:priority: "notice"
browseable: no  # Hidden from browse lists
```

#### Share 3: Finance Payroll Data (Read-Only Cross-Access)

```yaml
share_name: finance-payroll
path: /srv/samba/shares/finance/payroll
comment: "Finance Payroll Data - HR Manager Read-Only Access"
valid_users: "@GG-Finance", "@SG-Payroll-ReadOnly"
read_list: "@GG-Finance", "@SG-Payroll-ReadOnly"
write_list: "@GG-Finance"
create_mask: "0660"
directory_mask: "0770"
vfs_objects: "acl_xattr full_audit"
full_audit:prefix: "%u|%I|%m|%S"
full_audit:success: "read"
full_audit:failure: "all"
full_audit:facility: "local5"
full_audit:priority: "notice"
```

**Note:** This implements **separation of duties** - HR can view but not modify Finance payroll data.

#### Share 4: Company Policies (Shared Read/Write)

```yaml
share_name: company-policies
path: /srv/samba/shares/company/policies
comment: "Internal company policies and HR documents"
valid_users: "@SG-Policy-Docs"
read_list: "@SG-Policy-Docs"
write_list: "@GG-HR-Department", "@GG-Management"
create_mask: "0664"
directory_mask: "0775"
vfs_objects: "acl_xattr full_audit"
full_audit:prefix: "%u|%I|%m|%S"
full_audit:success: "write unlink rename"
full_audit:failure: "all"
full_audit:facility: "local5"
full_audit:priority: "notice"
```

#### Share 5: Onboarding Resources (Shared Access)

```yaml
share_name: onboarding
path: /srv/samba/shares/hr/onboarding
comment: "New hire onboarding materials and tracker"
valid_users: "@SG-Onboarding-Access"
read_list: "@SG-Onboarding-Access"
write_list: "@GG-HR-Department", "@GG-IT-Admins"
create_mask: "0664"
directory_mask: "0775"
vfs_objects: "acl_xattr full_audit"
full_audit:prefix: "%u|%I|%m|%S"
full_audit:success: "write"
full_audit:failure: "all"
full_audit:facility: "local5"
full_audit:priority: "notice"
```

---

### 3.3 Directory Structure

**Requirement ID:** `REQ-FILE-HR-003`

Create the following directory structure on `files01`:

```
/srv/samba/shares/
├── hr/
│   ├── personnel/                    # HR Managers ONLY
│   │   ├── active-employees/
│   │   │   ├── john-doe/
│   │   │   │   ├── offer-letter.pdf
│   │   │   │   ├── performance-reviews/
│   │   │   │   ├── disciplinary-actions/
│   │   │   │   └── benefits-enrollment.pdf
│   │   │   └── jane-smith/
│   │   ├── terminated-employees/
│   │   │   └── archive-by-year/
│   │   └── applicants/
│   ├── forms/
│   │   └── templates/               # Admin Assistant READ access
│   │       ├── employment-application.docx
│   │       ├── time-off-request.xlsx
│   │       └── employee-info-update.pdf
│   ├── policies/                    # HR maintains, all read
│   │   ├── employee-handbook.pdf
│   │   ├── code-of-conduct.pdf
│   │   └── benefits-guide.pdf
│   ├── onboarding/
│   │   ├── new-hire-checklist.xlsx
│   │   ├── orientation-materials/
│   │   └── training-records/
│   ├── benefits/
│   │   ├── insurance-plans/
│   │   └── 401k-info/
│   └── compliance/
│       ├── i9-forms/
│       ├── eeo-reports/
│       └── safety-training/
├── finance/
│   └── payroll/                     # HR has READ-ONLY access
│       ├── current/
│       └── archive/
├── company/
│   └── policies/                    # HR read/write, others read
│       ├── acceptable-use-policy.pdf
│       ├── remote-work-policy.pdf
│       └── pto-policy.pdf
└── users/
    └── <hr-username>/               # Individual user home directories
```

**Ansible Implementation:**
- Use `file` module to create directories with correct ownership
- Set base permissions: `root:root` with `0750` for HR directories (restrictive)
- Apply SELinux contexts for Samba shares
- Create subdirectories for employee folders (can be automated)

---

### 3.4 File System ACLs

**Requirement ID:** `REQ-FILE-HR-004`

Apply POSIX ACLs to enforce security boundaries:

```bash
# HR department files - Full access for HR group
setfacl -R -m g:SG-HR-Files-RW:rwx /srv/samba/shares/hr
setfacl -R -d -m g:SG-HR-Files-RW:rwx /srv/samba/shares/hr

# Personnel files - HR Managers ONLY
setfacl -R -m g:SG-HR-Managers:rwx /srv/samba/shares/hr/personnel
setfacl -R -d -m g:SG-HR-Managers:rwx /srv/samba/shares/hr/personnel
# Explicitly deny HR staff (if not managers)
setfacl -R -m g:SG-HR-Files-RW:--- /srv/samba/shares/hr/personnel

# HR forms templates - Admin Assistant READ access
setfacl -R -m g:SG-HR-Forms-Read:r-x /srv/samba/shares/hr/forms/templates
setfacl -R -d -m g:SG-HR-Forms-Read:r-x /srv/samba/shares/hr/forms/templates

# Finance Payroll - Read-only for HR Managers, full for Finance
setfacl -R -m g:SG-Payroll-ReadOnly:r-x /srv/samba/shares/finance/payroll
setfacl -R -d -m g:SG-Payroll-ReadOnly:r-x /srv/samba/shares/finance/payroll
setfacl -R -m g:GG-Finance:rwx /srv/samba/shares/finance/payroll
setfacl -R -d -m g:GG-Finance:rwx /srv/samba/shares/finance/payroll

# Company policies - HR write, others read
setfacl -R -m g:GG-HR-Department:rwx /srv/samba/shares/company/policies
setfacl -R -d -m g:GG-HR-Department:rwx /srv/samba/shares/company/policies
setfacl -R -m g:SG-Policy-Docs:r-x /srv/samba/shares/company/policies

# Onboarding - HR and IT write access
setfacl -R -m g:SG-Onboarding-Access:rwx /srv/samba/shares/hr/onboarding
setfacl -R -d -m g:SG-Onboarding-Access:rwx /srv/samba/shares/hr/onboarding
```

**Ansible Implementation:**
- Use `acl` module to set filesystem ACLs
- Apply default ACLs (`-d`) for inheritance
- Explicitly deny non-HR groups to personnel files
- Verify ACLs with `getfacl` in validation tasks

---

### 3.5 Access Restrictions

**Requirement ID:** `REQ-FILE-HR-005`

**DENY Access to the following:**

| Share/Path | HR Manager Access |
|------------|-------------------|
| `\\files01\finance\*` | **DENIED** (except payroll read-only) |
| `\\files01\it\*` | **DENIED** (IT administrative shares) |
| `\\files01\professional-services\*` | **DENIED** (consulting department files) |

**GRANTED Access:**

| Share/Path | HR Manager Access | Notes |
|------------|-------------------|-------|
| `\\files01\hr` | **Read/Write** | Full department access |
| `\\files01\hr-personnel` | **Read/Write** | Managers only - employee records |
| `\\files01\finance-payroll` | **Read-Only** | Separation of duties |
| `\\files01\company-policies` | **Read/Write** | Shared management |
| `\\files01\onboarding` | **Read/Write** | Shared with IT |

**Implementation:**
- Ensure restricted shares have `valid_users` lists that **exclude** `GG-HR-Department`
- Test access denial via validation playbook

---

## 4. Workstation Requirements

### 4.1 Workstation Provisioning

**Requirement ID:** `REQ-WS-HR-001`

HR Manager workstations must meet the following specifications:

| Attribute | Value |
|-----------|-------|
| Hostname Format | `hr-ws##` (e.g., `hr-ws01`, `hr-ws02`) |
| OS | Ubuntu Desktop 22.04 LTS or 24.04 LTS |
| Domain Join | Joined to `smboffice.local` via SSSD |
| RAM | 8GB minimum, 16GB recommended |
| Disk | 80GB minimum (for local caching) |
| CPU | 2 vCPU minimum, 4 recommended |
| Network | Bridged to HR VLAN (VLAN 30 - HR) |
| Encryption | Full disk encryption (LUKS) **required** |

**Ansible Implementation:**
- Provision VMs via Proxmox API or template cloning
- Set hostname via `hostname` module
- Configure LUKS encryption during provisioning
- Join domain using SSSD configuration role

---

### 4.2 Domain Join Configuration (SSSD)

**Requirement ID:** `REQ-WS-HR-002`

Configure SSSD for AD authentication with enhanced security:

```ini
[sssd]
domains = smboffice.local
config_file_version = 2
services = nss, pam

[domain/smboffice.local]
ad_domain = smboffice.local
krb5_realm = SMBOFFICE.LOCAL
realmd_tags = manages-system joined-with-samba
cache_credentials = True
id_provider = ad
krb5_store_password_if_offline = True
default_shell = /bin/bash
ldap_id_mapping = True
use_fully_qualified_names = False
fallback_homedir = /home/%u
access_provider = ad
ad_gpo_access_control = enforcing

# HR-specific settings
ldap_user_search_base = OU=HR,OU=Users,DC=smboffice,DC=local
krb5_renewable_lifetime = 7d
krb5_renew_interval = 3600
```

**Ansible Implementation:**
- Use `template` module to deploy `/etc/sssd/sssd.conf`
- Install required packages: `sssd`, `sssd-ad`, `realmd`, `adcli`, `krb5-workstation`
- Join domain using `realm join` command with HR OU specification
- Enable and start `sssd` service
- Set restrictive permissions on sssd.conf: `chmod 600`

---

### 4.3 Software Installation

**Requirement ID:** `REQ-WS-HR-003`

Install the following software on HR Manager workstations:

| Application | Purpose | Package/Source |
|-------------|---------|----------------|
| LibreOffice Calc | HR spreadsheets, onboarding trackers | `libreoffice-calc` |
| LibreOffice Writer | Employee documents, letters | `libreoffice-writer` |
| Thunderbird | Email client with encryption support | `thunderbird` |
| Firefox ESR | Web browser for HR applications | `firefox-esr` |
| PDF Viewer | View employee documents | `evince` |
| CUPS Client | Network printing | `cups-client` |
| Password Manager | KeePassXC for credential management | `keepassxc` |

**DO NOT INSTALL:**
- Social media applications
- Messaging applications (Slack, Discord, etc.)
- Media players
- Gaming software
- Torrent clients
- Cloud storage sync clients (Dropbox, etc.)

**Ansible Implementation:**
- Use `apt` module for package installation
- Pin Firefox ESR for stability
- Configure default applications via user profile
- Remove unnecessary packages to reduce attack surface

---

### 4.4 Desktop Policy Enforcement

**Requirement ID:** `REQ-WS-HR-004`

Enforce the following desktop policies via dconf/gsettings:

```yaml
desktop_policies:
  # Lockdown settings
  - key: "/org/gnome/desktop/lockdown/disable-user-switching"
    value: true
  - key: "/org/gnome/desktop/lockdown/disable-log-out"
    value: false

  # USB and removable media - DISABLED for HR (PII protection)
  - key: "/org/gnome/desktop/media-handling/automount"
    value: false
  - key: "/org/gnome/desktop/media-handling/automount-open"
    value: false
  - key: "/org/gnome/desktop/removable-media/autorun-never"
    value: true

  # Screen lock settings (stricter for HR)
  - key: "/org/gnome/desktop/screensaver/lock-enabled"
    value: true
  - key: "/org/gnome/desktop/screensaver/lock-delay"
    value: 600  # 10 minutes (per use case)
  - key: "/org/gnome/desktop/screensaver/idle-activation-enabled"
    value: true

  # Privacy settings (critical for PII)
  - key: "/org/gnome/desktop/privacy/remember-recent-files"
    value: false
  - key: "/org/gnome/desktop/privacy/recent-files-max-age"
    value: 1
  - key: "/org/gnome/desktop/privacy/remove-old-trash-files"
    value: true
  - key: "/org/gnome/desktop/privacy/old-files-age"
    value: 7  # 7 days
  - key: "/org/gnome/desktop/privacy/remember-app-usage"
    value: false

  # Disable screenshots (prevent PII leakage)
  - key: "/org/gnome/settings-daemon/plugins/media-keys/screenshot"
    value: ""  # Disable screenshot key
  - key: "/org/gnome/settings-daemon/plugins/media-keys/screenshot-clip"
    value: ""  # Disable screenshot to clipboard
```

**Ansible Implementation:**
- Use `dconf` module to set system-wide policies
- Deploy to `/etc/dconf/db/local.d/`
- Run `dconf update` after changes
- Lock settings to prevent user override

---

### 4.5 Network Segmentation

**Requirement ID:** `REQ-WS-HR-005`

**VLAN Assignment:** VLAN 30 - HR Department

| VLAN | Subnet | Purpose | Allowed Access |
|------|--------|---------|----------------|
| VLAN 30 | 10.10.30.0/24 | HR workstations and servers | - Domain Controllers<br>- File servers<br>- Print servers<br>- Email servers<br>- HR app server |

**Firewall Rules:**
- **DENY** direct access from other VLANs to HR VLAN
- **ALLOW** HR VLAN to shared infrastructure (AD, DNS, file server)
- **DENY** HR workstations from initiating connections to Internet (proxy required)
- **DENY** HR VLAN to Finance VLAN (except Finance payroll read-only via file server)

**Ansible Implementation:**
- Configure firewall rules on Proxmox host or network firewall
- Use `iptables` or `nftables` for host-based filtering
- Document VLAN configuration in network topology

---

## 5. Print Server Requirements

### 5.1 Print Server Infrastructure

**Requirement ID:** `REQ-PRINT-HR-001`

**Server:** `print01.smboffice.local`
**Role:** CUPS Print Server with Samba integration and audit logging

---

### 5.2 Printer Access Control

**Requirement ID:** `REQ-PRINT-HR-002`

HR Managers must have access to the following printers:

| Printer Name | Location | Access Group | Purpose | Security Features |
|--------------|----------|--------------|---------|-------------------|
| `HR-Printer` | HR Office | `SG-Printer-HR` | Confidential HR documents | Secure print release |

**CUPS ACL Configuration:**

```apache
<Printer HR-Printer>
  Info HR Department Secure Printer
  Location HR Office
  DeviceURI ipp://hr-printer.local:631/ipp/print
  State Idle
  StateTime 1234567890
  Type 8425556
  Accepting Yes
  Shared No
  JobSheets none none
  QuotaPeriod 0
  PageLimit 0
  KLimit 0
  AuthType Default
  Require user @SG-Printer-HR
  Order deny,allow
  Deny from all
  Allow from 10.10.30.0/24
</Printer>
```

**Security Features:**
- Secure print release (requires badge/PIN at printer)
- Print job audit logging
- Network restriction to HR VLAN only
- Auto-delete print jobs after 24 hours

**Ansible Implementation:**
- Install CUPS: `cups`, `samba-client`
- Configure `/etc/cups/printers.conf` with ACLs
- Add printer via `lpadmin` command
- Enable audit logging for print jobs
- Configure job retention policy

---

## 6. Application Server Requirements

### 6.1 HR Self-Service Portal

**Requirement ID:** `REQ-APP-HR-001`

**Server:** `hrapp01.smboffice.local`
**Role:** HR Self-Service Web Application (Internal Only)
**OS:** Ubuntu Server 22.04 LTS
**Application Stack:** Apache/Nginx + PHP/Python + MariaDB/PostgreSQL

**Purpose:**
- Employee self-service portal for PTO requests, benefits enrollment
- HR administrative interface for onboarding tracking
- Integration with AD for authentication

**Access Control:**
- HR Managers: Admin access
- All employees: User access (view own data, submit requests)
- Restricted to internal network only (no external access)

**Ansible Implementation:**
- Provision VM in HR VLAN or isolated application VLAN
- Install and configure web server
- Deploy HR application (if custom) or install commercial HRMS
- Configure AD/LDAP authentication integration
- Enable HTTPS with internal CA certificate
- Configure application-level audit logging

---

### 6.2 Database Security

**Requirement ID:** `REQ-APP-HR-002`

**Database Requirements:**
- Encryption at rest for HR database
- Encrypted connections (SSL/TLS)
- Strong database passwords (stored in Ansible Vault)
- Regular automated backups (daily)
- Backup retention: 7 years for employee records

**Ansible Implementation:**
- Install database server (MariaDB or PostgreSQL)
- Enable encryption at rest (LUKS volume or database-level encryption)
- Configure SSL/TLS for client connections
- Create database users with least privilege
- Set up automated backup via cron and Ansible
- Document backup restoration procedures

---

## 7. Security Requirements

### 7.1 Audit Logging

**Requirement ID:** `REQ-SEC-HR-001`

Configure `auditd` to monitor HR Manager file and system access:

**Audit Rules for File Server:**

```bash
# Monitor all HR share access
-w /srv/samba/shares/hr -p rwa -k hr_file_access

# Monitor personnel files (highly sensitive - all operations)
-w /srv/samba/shares/hr/personnel -p rwa -k hr_personnel_access

# Monitor read access to Finance payroll (separation of duties)
-w /srv/samba/shares/finance/payroll -p r -k hr_payroll_read

# Monitor onboarding folder (HR/IT collaboration)
-w /srv/samba/shares/hr/onboarding -p wa -k hr_onboarding_activity

# Monitor HR Samba logs
-w /var/log/samba/ -p wa -k hr_samba_logs
```

**Audit Rules for Workstations:**

```bash
# Monitor USB device attempts (should be blocked)
-w /dev/bus/usb -p rwa -k hr_usb_attempt

# Monitor sudo attempts (should fail - no sudo access)
-a always,exit -F arch=b64 -S execve -F euid=0 -F auid>=1000 -k hr_privilege_escalation

# Monitor file deletions in HR home directories
-a always,exit -F arch=b64 -S unlink -S unlinkat -S rename -S renameat -F auid>=1000 -k hr_file_delete

# Monitor network connections
-a always,exit -F arch=b64 -S connect -F auid>=1000 -k hr_network_connect

# Monitor clipboard usage (PII leakage prevention)
-w /tmp/.X11-unix -p rwa -k hr_clipboard_access
```

**Ansible Implementation:**
- Deploy rules to `/etc/audit/rules.d/hr.rules`
- Restart auditd service
- Configure log rotation in `/etc/audit/auditd.conf`
- Forward audit logs to central SIEM/syslog server

---

### 7.2 USB Storage Restrictions

**Requirement ID:** `REQ-SEC-HR-002`

**Policy:** USB storage devices are **completely disabled** for HR workstations.

**Implementation via udev rules:**

```bash
# /etc/udev/rules.d/99-usb-storage-deny.rules
# Block all USB storage devices for HR users
SUBSYSTEM=="usb", ATTRS{bDeviceClass}=="08", ENV{UDISKS_IGNORE}="1"
SUBSYSTEM=="block", ATTRS{removable}=="1", ENV{UDISKS_IGNORE}="1"
```

**Additional kernel module blacklisting:**

```bash
# /etc/modprobe.d/hr-usb-deny.conf
blacklist usb-storage
blacklist uas
```

**Ansible Implementation:**
- Deploy udev rule via `copy` module
- Reload udev rules: `udevadm control --reload-rules`
- Add kernel module blacklist
- Update initramfs: `update-initramfs -u`
- Reboot workstation or reload modules

---

### 7.3 SELinux / AppArmor Enforcement

**Requirement ID:** `REQ-SEC-HR-003`

**For Oracle Linux (SELinux) - RECOMMENDED:**
- Set SELinux to **enforcing** mode
- Apply Samba-specific contexts to HR share directories:

```bash
semanage fcontext -a -t samba_share_t "/srv/samba/shares/hr(/.*)?"
semanage fcontext -a -t samba_share_t "/srv/samba/shares/company/policies(/.*)?"
restorecon -Rv /srv/samba/shares
```

**Custom SELinux policy for HR:**
```bash
# Allow HR-specific Samba operations
module hr_samba 1.0;

require {
    type samba_t;
    type samba_share_t;
    class file { read write create unlink };
}

# Policy rules here (deployed via Ansible)
```

**For Ubuntu (AppArmor):**
- Ensure AppArmor profiles are enforcing
- No custom modifications needed for standard Samba usage

**Ansible Implementation:**
- Use `selinux` module to set mode
- Use `sefcontext` module for context management
- Deploy custom SELinux policy via `copy` and compile with `checkmodule`/`semodule`

---

### 7.4 Password and Account Security

**Requirement ID:** `REQ-SEC-HR-004`

| Policy | Setting |
|--------|---------|
| Password Complexity | Minimum 14 characters, uppercase, lowercase, number, special char |
| Password Expiration | 90 days |
| Password History | Remember last 10 passwords |
| Account Lockout | 5 failed attempts, 30-minute lockout |
| Session Timeout | 10 minutes idle lock (stricter for HR) |
| Multi-Factor Authentication | **Required** (via OTP or hardware token) |

**Ansible Implementation:**
- Configure via Samba AD password policy commands
- Set PAM settings on workstations (`/etc/pam.d/common-password`)
- Install and configure MFA solution (Google Authenticator or FreeOTP)

---

### 7.5 Data Loss Prevention (DLP)

**Requirement ID:** `REQ-SEC-HR-005`

**Email DLP Policies:**
- Block emails containing keywords: "personnel", "employee", "SSN", "health", "benefits" to external domains
- Require encryption for emails with HR attachments
- Alert on large attachments (>10MB)
- Scan for PII patterns (SSN, DOB, etc.)

**File DLP Policies:**
- Monitor and alert on large file transfers from HR shares
- Block file uploads to cloud storage services (Dropbox, Google Drive, etc.)
- Prevent copy/paste of PII to non-secure applications

**Ansible Implementation:**
- Configure email server (Postfix) with content filtering
- Use browser policies to block cloud storage domains
- Implement file monitoring via auditd and custom scripts
- Deploy clipboard monitoring tools (if required)

---

### 7.6 Privacy Screen Protection

**Requirement ID:** `REQ-SEC-HR-006`

**Policy:** HR workstations must have physical privacy screens installed to prevent visual eavesdropping on employee data.

**Implementation:**
- Procure and install privacy screen filters on all HR monitors
- Document in physical security procedures
- Include in HR workstation provisioning checklist

---

## 8. Monitoring and Audit Requirements

### 8.1 Log Aggregation

**Requirement ID:** `REQ-MON-HR-001`

Forward logs to central syslog/SIEM server:

**Sources:**
- File server auditd logs
- Workstation authentication logs (`/var/log/auth.log`)
- Samba access logs (with full_audit VFS module)
- Print job logs
- Failed login attempts
- HR application logs

**Log Retention:**
- Real-time logs: 90 days
- Archived logs: 7 years (employment law requirement)

**Ansible Implementation:**
- Configure rsyslog to forward to `syslog01.smboffice.local:514`
- Use `template` module for `/etc/rsyslog.d/50-remote.conf`
- Configure log rotation with long retention
- Enable TLS for log transport (security)

---

### 8.2 Access Review Cadence

**Requirement ID:** `REQ-MON-HR-002`

**Policy:** HR Manager role and permissions reviewed **quarterly** by:
- IT Security Analyst
- IT AD Architect
- Managing Partner or CHRO equivalent

**Automated Access Reports:**
- Generate quarterly reports showing:
  - AD group memberships
  - File share access permissions
  - Recent file access patterns (especially personnel files)
  - Failed access attempts
  - Privilege changes
  - Onboarding/offboarding activities

**Ansible Implementation:**
- Create reporting playbook that queries AD and file server
- Generate CSV/PDF reports
- Email to stakeholders automatically
- Store reports in audit archive

---

### 8.3 PII Access Monitoring

**Requirement ID:** `REQ-MON-HR-003`

**HIPAA-Style PII Monitoring:**

| Control | Monitoring Method | Frequency |
|---------|------------------|-----------|
| Personnel File Access | Review audit logs for access patterns | Weekly |
| Payroll Access | Verify read-only access, no modifications | Monthly |
| Onboarding Activity | Track new user account creation | Daily |
| Offboarding Activity | Track account disablement | Daily |
| Separation of Duties | Validate HR cannot modify Finance payroll | Monthly |

**Ansible Implementation:**
- Create compliance validation playbooks
- Schedule via cron for automated checks
- Alert on anomalous access patterns
- Generate PII access dashboards

---

## 9. Compliance Requirements

### 9.1 HIPAA-Style Controls

**Requirement ID:** `REQ-COMP-HR-001`

Implement the following HIPAA-style controls for employee health data:

| Control ID | Control Description | Implementation |
|------------|---------------------|----------------|
| HIPAA-AC-01 | Access to employee health records is restricted to authorized HR personnel only | AD security groups, file ACLs |
| HIPAA-AC-02 | Minimum necessary access - only personnel files needed | Role-based access, personnel folder restricted to managers |
| HIPAA-AU-01 | All access to employee records is logged and monitored | Auditd, Samba full_audit VFS |
| HIPAA-AU-02 | Audit logs are retained for 7 years | Log archival and retention policy |
| HIPAA-EN-01 | Employee data is encrypted at rest and in transit | LUKS encryption, SMB encryption |
| HIPAA-IA-01 | Strong authentication is enforced | 14-char passwords, MFA |

**Ansible Implementation:**
- Document control mappings in playbook variables
- Create validation tasks for each control
- Generate compliance evidence reports

---

### 9.2 Data Retention Policy

**Requirement ID:** `REQ-COMP-HR-002`

**Employee Record Retention:**

| Document Type | Retention Period | Storage Location |
|---------------|------------------|------------------|
| Personnel files (active employees) | Duration of employment + 7 years | `/srv/samba/shares/hr/personnel/active-employees/` |
| Personnel files (terminated employees) | 7 years after termination | `/srv/samba/shares/hr/personnel/terminated-employees/archive-by-year/` |
| I-9 forms | 3 years after hire OR 1 year after termination (whichever is later) | `/srv/samba/shares/hr/compliance/i9-forms/` |
| Payroll records | 7 years | Finance maintains, HR read-only |
| Benefits enrollment | Duration of employment + 7 years | `/srv/samba/shares/hr/benefits/` |

**Ansible Implementation:**
- Implement automated archival scripts
- Move terminated employee files to archive folder
- Set file expiration metadata for automatic cleanup
- Document retention policy in configuration management

---

## 10. Onboarding/Offboarding Automation

### 10.1 Onboarding Workflow

**Requirement ID:** `REQ-AUTO-HR-001`

**Automated Onboarding Tasks:**

1. **HR initiates onboarding** (creates entry in onboarding tracker)
2. **IT provisions AD account** (triggered by onboarding tracker update)
   - Create user in appropriate OU
   - Assign to department groups
   - Set password (temporary, must change)
   - Create home directory
   - Create email account
3. **HR completes documentation**
   - Upload offer letter, I-9, benefits enrollment to personnel folder
   - Update onboarding tracker
4. **IT provisions workstation** (if needed)
5. **HR sends welcome email** with credentials and first-day instructions

**Ansible Playbook:** `onboard-employee.yml`

```yaml
---
- name: Onboard New Employee
  hosts: localhost
  vars_prompt:
    - name: employee_firstname
      prompt: "First Name"
    - name: employee_lastname
      prompt: "Last Name"
    - name: employee_department
      prompt: "Department (HR, Finance, etc.)"
    - name: employee_title
      prompt: "Job Title"
  tasks:
    - name: Create AD user account
      # AD user creation tasks

    - name: Assign to department groups
      # Group membership tasks

    - name: Create personnel folder
      # File system tasks

    - name: Update onboarding tracker
      # Update shared spreadsheet or DB

    - name: Send welcome email
      # Email notification task
```

**Ansible Implementation:**
- Create modular onboarding role
- Support variable input (employee details)
- Integrate with HR onboarding tracker (CSV or database)
- Send notifications at each step

---

### 10.2 Offboarding Workflow

**Requirement ID:** `REQ-AUTO-HR-002`

**Automated Offboarding Tasks:**

1. **HR initiates offboarding** (termination/resignation notification)
2. **IT disables AD account immediately** (prevent access)
   - Disable user account (do not delete)
   - Remove from all groups except "Terminated Users"
   - Reset password
   - Set account expiration date
3. **IT transfers email access** to manager or HR (30-day window)
4. **HR archives personnel files**
   - Move employee folder to terminated-employees archive
   - Timestamp with termination date
5. **IT archives user data** (home directory, email)
6. **Final account deletion** after retention period (7 years)

**Ansible Playbook:** `offboard-employee.yml`

```yaml
---
- name: Offboard Employee
  hosts: localhost
  vars_prompt:
    - name: employee_username
      prompt: "Username to offboard"
    - name: termination_date
      prompt: "Termination Date (YYYY-MM-DD)"
  tasks:
    - name: Disable AD user account
      # AD account disable tasks

    - name: Remove group memberships
      # Group removal tasks

    - name: Archive personnel folder
      # Move to terminated archive

    - name: Backup user data
      # Archive home directory and email

    - name: Update offboarding tracker
      # Log offboarding completion
```

**Ansible Implementation:**
- Create modular offboarding role
- Implement account disable (not delete)
- Automate data archival
- Schedule future deletion task (after retention period)

---

## 11. Ansible Implementation Notes

### 11.1 Playbook Structure

**Recommended Playbook Organization:**

```
ansible/
├── playbooks/
│   ├── hr-manager-setup.yml               # Main orchestration playbook
│   ├── hr-compliance-validation.yml       # HIPAA compliance checking
│   ├── onboard-employee.yml               # Employee onboarding
│   └── offboard-employee.yml              # Employee offboarding
├── roles/
│   ├── ad-hr/
│   │   ├── tasks/
│   │   │   ├── main.yml
│   │   │   ├── create-ou.yml
│   │   │   ├── create-groups.yml
│   │   │   ├── create-users.yml
│   │   │   └── configure-gpo.yml
│   │   ├── templates/
│   │   │   └── hr-user.j2
│   │   └── vars/
│   │       └── main.yml
│   ├── fileserver-hr-shares/
│   │   ├── tasks/
│   │   │   ├── main.yml
│   │   │   ├── create-shares.yml
│   │   │   ├── set-acls.yml
│   │   │   ├── create-personnel-folders.yml
│   │   │   └── configure-audit.yml
│   │   ├── templates/
│   │   │   └── smb-hr.conf.j2
│   │   └── files/
│   │       └── hr-share-structure.sh
│   ├── workstation-hr/
│   │   ├── tasks/
│   │   │   ├── main.yml
│   │   │   ├── provision-vm.yml
│   │   │   ├── configure-encryption.yml
│   │   │   ├── domain-join.yml
│   │   │   ├── install-software.yml
│   │   │   └── lockdown-desktop.yml
│   │   └── templates/
│   │       └── sssd-hr.conf.j2
│   ├── hrapp-server/
│   │   ├── tasks/
│   │   │   ├── main.yml
│   │   │   ├── install-webserver.yml
│   │   │   ├── install-database.yml
│   │   │   ├── deploy-application.yml
│   │   │   └── configure-ssl.yml
│   │   └── templates/
│   │       └── hrapp-config.j2
│   ├── security-hr/
│   │   ├── tasks/
│   │   │   ├── main.yml
│   │   │   ├── auditd-rules.yml
│   │   │   ├── usb-lockdown.yml
│   │   │   ├── selinux-config.yml
│   │   │   ├── dlp-policies.yml
│   │   │   └── privacy-settings.yml
│   │   └── files/
│   │       ├── hr-audit.rules
│   │       └── usb-deny.rules
│   ├── compliance-hr/
│   │   ├── tasks/
│   │   │   ├── main.yml
│   │   │   ├── hipaa-validation.yml
│   │   │   ├── generate-reports.yml
│   │   │   └── data-retention.yml
│   │   └── templates/
│   │       └── compliance-report.j2
│   └── onboarding-automation/
│       ├── tasks/
│       │   ├── onboard.yml
│       │   ├── offboard.yml
│       │   └── archive-employee.yml
│       └── templates/
│           └── personnel-folder.j2
└── inventory/
    └── hosts.yml
```

---

### 11.2 Variables

**Suggested variable file** (`roles/ad-hr/vars/main.yml`):

```yaml
# AD Domain settings
ad_domain: "smboffice.local"
ad_realm: "SMBOFFICE.LOCAL"
ad_base_dn: "DC=smboffice,DC=local"

# OU Structure
hr_ou: "OU=HR,OU=Users,{{ ad_base_dn }}"
hr_managers_ou: "OU=HRManagers,{{ hr_ou }}"

# Security Groups
hr_groups:
  - name: "GG-HR-Department"
    scope: "Global"
    description: "Primary HR department group"
  - name: "SG-HR-Managers"
    scope: "Global"
    description: "HR Manager role group"
  - name: "SG-HR-Files-RW"
    scope: "DomainLocal"
    description: "Read/Write access to HR file shares"
  - name: "SG-Payroll-ReadOnly"
    scope: "DomainLocal"
    description: "Read-only access to Finance payroll data"
  - name: "SG-Policy-Docs"
    scope: "DomainLocal"
    description: "Access to company-wide policy documents"
  - name: "SG-Onboarding-Access"
    scope: "DomainLocal"
    description: "Permission to write to onboarding logs and tools"
  - name: "SG-Printer-HR"
    scope: "DomainLocal"
    description: "HR printer access"

# HR Manager Users
hr_managers:
  - username: "jennifer.adams"
    firstname: "Jennifer"
    lastname: "Adams"
    email: "jennifer.adams@smboffice.local"
    title: "HR Manager"
    workstation: "hr-ws01"
  - username: "michael.chen"
    firstname: "Michael"
    lastname: "Chen"
    email: "michael.chen@smboffice.local"
    title: "HR Coordinator"
    workstation: "hr-ws02"

# File Shares
file_server: "files01.smboffice.local"
share_base: "/srv/samba/shares"

hr_shares:
  - name: "hr"
    path: "{{ share_base }}/hr"
    comment: "Human Resources Department - Restricted Access"
    valid_users: "@SG-HR-Files-RW"
    writable: yes
    browseable: no
    audit: full

  - name: "hr-personnel"
    path: "{{ share_base }}/hr/personnel"
    comment: "Employee Personnel Records - HR Manager Access Only"
    valid_users: "@SG-HR-Managers"
    writable: yes
    browseable: no
    audit: full

  - name: "finance-payroll"
    path: "{{ share_base }}/finance/payroll"
    comment: "Finance Payroll Data - HR Manager Read-Only Access"
    valid_users: "@GG-Finance,@SG-Payroll-ReadOnly"
    read_list: "@GG-Finance,@SG-Payroll-ReadOnly"
    write_list: "@GG-Finance"
    writable: yes
    audit: read

  - name: "company-policies"
    path: "{{ share_base }}/company/policies"
    comment: "Internal company policies and HR documents"
    valid_users: "@SG-Policy-Docs"
    read_list: "@SG-Policy-Docs"
    write_list: "@GG-HR-Department,@GG-Management"
    writable: yes
    audit: write

  - name: "onboarding"
    path: "{{ share_base }}/hr/onboarding"
    comment: "New hire onboarding materials and tracker"
    valid_users: "@SG-Onboarding-Access"
    read_list: "@SG-Onboarding-Access"
    write_list: "@GG-HR-Department,@GG-IT-Admins"
    writable: yes
    audit: write

# Network Configuration
hr_vlan: 30
hr_subnet: "10.10.30.0/24"

# Security Settings
hr_password_length: 14
hr_password_age: 90
hr_password_history: 10
hr_screen_lock_timeout: 600  # 10 minutes
usb_enabled: false
mfa_required: true

# Compliance Settings
hipaa_compliance: true
pii_protection: true
audit_retention_days: 2555  # 7 years
access_review_frequency: "quarterly"

# Data Retention (days)
retention_active_employees: 2555  # 7 years after termination
retention_terminated_employees: 2555  # 7 years
retention_i9_forms: 1095  # 3 years or 1 year after term
```

---

### 11.3 Sensitive Data Handling

**Ansible Vault for Secrets:**
```yaml
# Encrypt sensitive variables
ansible-vault create group_vars/hr/vault.yml

# Contents:
vault_hr_admin_password: "SecureHRPassword123!"
vault_luks_passphrase: "DiskEncryptionKey456!"
vault_mfa_secret: "TOTPSECRET789"
vault_hrapp_db_password: "DatabasePassword321!"
```

**Ansible Implementation:**
- Store passwords in Ansible Vault
- Use `no_log: true` for sensitive tasks
- Rotate secrets regularly
- Never commit unencrypted credentials

---

## 12. Validation and Testing

### 12.1 Test Cases

**Requirement ID:** `REQ-TEST-HR-001`

Create the following test cases:

| Test ID | Test Description | Expected Result |
|---------|------------------|-----------------|
| `TEST-HR-001` | HR Manager can log in to `hr-ws01` with AD credentials | Login successful |
| `TEST-HR-002` | HR Manager can access `\\files01\hr` with read/write | Files readable and writable |
| `TEST-HR-003` | HR Manager can access `\\files01\hr-personnel` with read/write | Personnel files accessible |
| `TEST-HR-004` | HR Staff **cannot** access `\\files01\hr-personnel` | Access denied (managers only) |
| `TEST-HR-005` | HR Manager can access `\\files01\finance-payroll` with **read-only** | Files readable, write **denied** |
| `TEST-HR-006` | HR Manager **cannot** access `\\files01\finance` (except payroll) | Access denied |
| `TEST-HR-007` | HR Manager can access `\\files01\company-policies` with read/write | Files readable and writable |
| `TEST-HR-008` | HR Manager can access `\\files01\onboarding` with read/write | Files readable and writable |
| `TEST-HR-009` | HR Manager can print to `HR-Printer` | Print job successful |
| `TEST-HR-010` | HR Manager **cannot** install software | Installation blocked |
| `TEST-HR-011` | USB storage is **completely blocked** | USB device not recognized |
| `TEST-HR-012` | File access is logged in auditd | Audit log entry created for HR files |
| `TEST-HR-013` | Personnel file access is logged separately | Audit log with `hr_personnel_access` tag |
| `TEST-HR-014` | Screen locks after 10 minutes idle | Screen lock activated |
| `TEST-HR-015` | Separation of duties validated | Read-only access to Finance payroll confirmed |
| `TEST-HR-016` | MFA is required for login | Cannot login without OTP |
| `TEST-HR-017` | Onboarding automation creates user and personnel folder | User created, folder exists |
| `TEST-HR-018` | Offboarding automation disables account and archives files | Account disabled, files moved |

---

### 12.2 Validation Playbook

Create an Ansible validation playbook:

```yaml
# playbooks/validate-hr-manager.yml
---
- name: Validate HR Manager Configuration
  hosts: localhost
  tasks:
    - name: Check if HR AD groups exist
      command: samba-tool group show "{{ item }}"
      loop:
        - GG-HR-Department
        - SG-HR-Managers
        - SG-HR-Files-RW
        - SG-Payroll-ReadOnly
        - SG-Policy-Docs
        - SG-Onboarding-Access
      register: group_check

    - name: Verify HR file shares exist
      stat:
        path: "{{ item }}"
      loop:
        - /srv/samba/shares/hr
        - /srv/samba/shares/hr/personnel
        - /srv/samba/shares/finance/payroll
        - /srv/samba/shares/company/policies
        - /srv/samba/shares/hr/onboarding
      register: share_stat

    - name: Test ACLs on HR directory
      command: getfacl /srv/samba/shares/hr
      register: acl_check

    - name: Test ACLs on personnel directory (managers only)
      command: getfacl /srv/samba/shares/hr/personnel
      register: personnel_acl_check
      failed_when: "'SG-HR-Managers:rwx' not in personnel_acl_check.stdout"

    - name: Verify auditd rules are loaded
      command: auditctl -l
      register: audit_rules
      failed_when: >
        'hr_file_access' not in audit_rules.stdout or
        'hr_personnel_access' not in audit_rules.stdout

    - name: Check USB storage is disabled
      command: lsmod
      register: lsmod_output
      failed_when: "'usb_storage' in lsmod_output.stdout"

    - name: Verify SELinux is enforcing
      command: getenforce
      register: selinux_status
      failed_when: "selinux_status.stdout != 'Enforcing'"

    - name: Test separation of duties (payroll read-only)
      shell: |
        sudo -u jennifer.adams test -w /srv/samba/shares/finance/payroll/test.txt
      register: payroll_write_test
      failed_when: payroll_write_test.rc == 0  # Should fail (no write access)
      ignore_errors: yes

    - name: Test personnel folder access restriction
      shell: |
        sudo -u hr-staff-user test -r /srv/samba/shares/hr/personnel
      register: personnel_staff_test
      failed_when: personnel_staff_test.rc == 0  # Should fail (managers only)
      ignore_errors: yes
```

---

### 12.3 Compliance Validation

**Requirement ID:** `REQ-TEST-HR-002`

Create HIPAA compliance validation playbook:

```yaml
# playbooks/validate-hr-compliance.yml
---
- name: HIPAA-Style Compliance Validation for HR
  hosts: localhost
  tasks:
    - name: HIPAA-AC-01 - Verify access restriction
      # Test that non-HR users cannot access HR shares

    - name: HIPAA-AC-02 - Verify minimum necessary access
      # Test that HR staff cannot access personnel files (managers only)

    - name: HIPAA-AU-01 - Verify audit logging is active
      # Check auditd is running and logging HR access

    - name: HIPAA-AU-02 - Verify audit log retention
      # Check log rotation configured for 7 years

    - name: HIPAA-EN-01 - Verify encryption at rest
      # Check LUKS encryption is active

    - name: HIPAA-IA-01 - Verify strong authentication
      # Check password policy and MFA settings

    - name: Generate compliance report
      template:
        src: hipaa-compliance-report.j2
        dest: /var/reports/hr-hipaa-compliance-{{ ansible_date_time.date }}.pdf
```

---

## 13. Dependencies

### 13.1 Infrastructure Dependencies

| Dependency | Description | Status Required |
|------------|-------------|----------------|
| Samba AD Domain Controller | `dc01.smboffice.local` must be operational | **CRITICAL** |
| File Server | `files01.smboffice.local` must be provisioned with encryption | **CRITICAL** |
| HR App Server | `hrapp01.smboffice.local` for HR self-service portal | **HIGH** |
| Print Server | `print01.smboffice.local` must be configured | **HIGH** |
| Network VLAN | HR VLAN (VLAN 30) must be configured and isolated | **CRITICAL** |
| DNS | Forward/reverse DNS zones configured | **CRITICAL** |
| Syslog/SIEM Server | `syslog01.smboffice.local` for log aggregation | **HIGH** |
| Backup System | HR data backup and retention system (7 years) | **CRITICAL** |

---

### 13.2 Prerequisite Roles

The following roles/configurations must be implemented before HR Manager setup:

1. **Finance Department baseline** (`GG-Finance` group must exist for payroll share dependency)
2. **File server base shares** (`/srv/samba/shares` structure with encryption)
3. **Workstation template** (Ubuntu desktop template with LUKS encryption)
4. **Print server base** (CUPS with secure print capabilities)
5. **Audit infrastructure** (auditd, log forwarding, SIEM integration)
6. **Admin Assistant role** (for HR forms template access)

---

### 13.3 Related Requirements Documents

| Document | Description |
|----------|-------------|
| `finance-manager-requirements.md` | Finance role requirements (for payroll share dependency) |
| `admin-assistant-requirements.md` | Admin Assistant role (for HR forms access) |
| `file-server-baseline-requirements.md` | Core file server setup |
| `ad-baseline-requirements.md` | Core AD infrastructure |
| `network-segmentation-requirements.md` | VLAN and firewall configuration |
| `audit-logging-requirements.md` | Central logging infrastructure |

---

## 📋 Review and Approval

| Role | Reviewer | Status | Date | Notes |
|------|----------|--------|------|-------|
| IT Business Analyst | | [ ] Pending | | Requirements derived from use case |
| IT AD Architect | | [ ] Pending | | AD structure and GPO review |
| IT Linux Admin/Architect | | [ ] Pending | | File server and workstation config |
| IT Security Analyst | | [ ] Pending | | Security controls and audit logging |
| Compliance & Risk Analyst | | [ ] Pending | | HIPAA compliance validation |
| IT Ansible Programmer | | [ ] Pending | | Ansible implementation feasibility |
| IT Code Auditor | | [ ] Pending | | Code quality and best practices |

---

## 📝 Version History

| Version | Date | Author | Changes |
|---------|------|--------|---------|
| v1.0 | 2025-12-23 | IT Business Analyst | Initial requirements specification derived from USECASE-ROLE-HR-001 |

---

## 📎 Appendix

### A.1 Samba Share Configuration Example (HR Personnel - Managers Only)

```ini
[hr-personnel]
path = /srv/samba/shares/hr/personnel
comment = Employee Personnel Records - HR Manager Access Only
valid users = @SG-HR-Managers
read list = @SG-HR-Managers
write list = @SG-HR-Managers
create mask = 0660
directory mask = 0770
vfs objects = acl_xattr full_audit
full_audit:prefix = %u|%I|%m|%S
full_audit:success = all
full_audit:failure = all
full_audit:facility = local5
full_audit:priority = notice
browseable = no
```

### A.2 Employee Onboarding Script Example

```bash
#!/bin/bash
# onboard-employee.sh - Create personnel folder for new hire

EMPLOYEE_USERNAME="$1"
EMPLOYEE_FIRSTNAME="$2"
EMPLOYEE_LASTNAME="$3"

PERSONNEL_BASE="/srv/samba/shares/hr/personnel/active-employees"
EMPLOYEE_FOLDER="${PERSONNEL_BASE}/${EMPLOYEE_USERNAME}"

# Create employee personnel folder
mkdir -p "${EMPLOYEE_FOLDER}"/{documents,performance-reviews,disciplinary-actions,benefits}

# Set ownership and permissions
chown -R root:SG-HR-Managers "${EMPLOYEE_FOLDER}"
chmod -R 0770 "${EMPLOYEE_FOLDER}"

# Set ACLs
setfacl -R -m g:SG-HR-Managers:rwx "${EMPLOYEE_FOLDER}"
setfacl -R -d -m g:SG-HR-Managers:rwx "${EMPLOYEE_FOLDER}"

echo "Personnel folder created for ${EMPLOYEE_FIRSTNAME} ${EMPLOYEE_LASTNAME} (${EMPLOYEE_USERNAME})"
```

### A.3 HIPAA Control Evidence Collection

```bash
# Generate HIPAA compliance evidence package
ansible-playbook playbooks/hr-compliance-validation.yml \
  --extra-vars "output_dir=/var/reports/hipaa-$(date +%Y%m%d)"

# Package includes:
# - AD group membership reports
# - File ACL configurations
# - Audit log samples (personnel file access)
# - Encryption verification
# - Password policy settings
# - Access review logs
# - Data retention policy documentation
```

---

**End of Document**
