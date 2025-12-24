<!--
███████████████████████████████████████████████████████████████
  🔧 SMB Office IT Blueprint – System Requirements Document
  Doc ID: REQ-ROLE-FINANCE-001
  Source: USECASE-ROLE-FINANCE-001
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
  Tags: [finance, privileged-data, requirements, ansible, sox]
  Purpose: Ansible Automation
  Compliance: SOX-style Controls
  Publish Target: Internal
  Summary: >
    Technical system requirements derived from the Finance Manager use case
    for implementation via Ansible automation. Defines AD structure, file
    shares, permissions, workstation configuration, security controls, and
    audit logging for SOX-style compliance.
  Read Time: ~12 min
███████████████████████████████████████████████████████████████
-->

# 🔧 Finance Manager – System Requirements Specification

**Source Use Case:** `USECASE-ROLE-FINANCE-001` (finance-manager-use-case.md)
**Target Implementation:** Ansible Playbooks and Roles
**Related Roles:** Finance Department, Business-Critical/Data-Sensitive

---

## 📍 Table of Contents

- [1. Overview](#1-overview)
- [2. Active Directory Requirements](#2-active-directory-requirements)
- [3. File Server Requirements](#3-file-server-requirements)
- [4. Workstation Requirements](#4-workstation-requirements)
- [5. Print Server Requirements](#5-print-server-requirements)
- [6. Security Requirements](#6-security-requirements)
- [7. Monitoring and Audit Requirements](#7-monitoring-and-audit-requirements)
- [8. Compliance Requirements](#8-compliance-requirements)
- [9. Ansible Implementation Notes](#9-ansible-implementation-notes)
- [10. Validation and Testing](#10-validation-and-testing)
- [11. Dependencies](#11-dependencies)

---

## 1. Overview

### 1.1 Purpose

This document translates business requirements from the Finance Manager use case into technical specifications for infrastructure automation via Ansible, with emphasis on SOX-style compliance controls.

### 1.2 Scope

This specification covers:
- Active Directory organizational units, groups, and user accounts
- Finance-specific file server shares and ACL configurations
- Workstation provisioning with enhanced security controls
- Print server access configuration
- Audit logging and compliance monitoring
- Security controls including data loss prevention (DLP)
- Separation of duties enforcement

### 1.3 Implementation Priority

**Priority Level:** High (Tier 1 - Business-Critical)
**Security Classification:** Restricted - Sensitive Financial Data
**Compliance Framework:** SOX-style controls for financial data protection

---

## 2. Active Directory Requirements

### 2.1 Organizational Unit Structure

**Requirement ID:** `REQ-AD-FINANCE-001`

Create the following OU structure:

```
Domain: smboffice.local
└── OU=Users
    └── OU=Finance
        ├── OU=FinanceManagers
        └── OU=FinanceStaff
```

**Ansible Implementation:**
- Use `community.windows.win_domain_ou` module or Samba AD equivalent
- Create OU hierarchy if not exists (idempotent)
- Apply descriptions:
  - FinanceManagers: "Finance management and oversight roles"
  - FinanceStaff: "Finance department staff and support roles"

---

### 2.2 Security Groups

**Requirement ID:** `REQ-AD-FINANCE-002`

Create the following security groups:

| Group Name | Scope | Type | Description | OU Location |
|------------|-------|------|-------------|-------------|
| `GG-Finance` | Global | Security | Primary Finance department group | `OU=Groups,OU=Finance` |
| `SG-Finance-Files-RW` | Domain Local | Security | Read/Write access to Finance file shares | `OU=Groups,OU=Finance` |
| `SG-Client-Billing` | Domain Local | Security | Access to client invoice and billing data | `OU=Groups,OU=Finance` |
| `SG-Payroll-ReadOnly` | Domain Local | Security | Read-only access to payroll data | `OU=Groups,OU=Finance` |
| `SG-Printer-Finance` | Domain Local | Security | Finance printer access | `OU=Groups,OU=Infrastructure` |
| `SG-Finance-Managers` | Global | Security | Finance Manager role group (nested in others) | `OU=Groups,OU=Finance` |

**Ansible Implementation:**
- Create groups with proper scope and type
- Document group purpose in AD description field
- Establish group nesting per access model

**Group Membership Rules:**
```yaml
# Nested group memberships (Finance Manager inherits all Finance access)
GG-Finance:
  members:
    - SG-Finance-Managers

SG-Finance-Files-RW:
  members:
    - GG-Finance

SG-Client-Billing:
  members:
    - SG-Finance-Managers  # Only managers access billing

SG-Payroll-ReadOnly:
  members:
    - SG-Finance-Managers  # Read-only cross-department access

SG-Printer-Finance:
  members:
    - GG-Finance
```

---

### 2.3 User Account Template

**Requirement ID:** `REQ-AD-FINANCE-003`

Finance Manager user account specifications:

| Attribute | Value |
|-----------|-------|
| Username Format | `firstname.lastname` (lowercase) |
| Display Name | `FirstName LastName` |
| Email | `firstname.lastname@smboffice.local` |
| Title | `Finance Manager` |
| Department | `Finance` |
| Office | `Finance Office` |
| Primary Group | `SG-Finance-Managers` |
| Additional Groups | `GG-Finance` |
| Home Directory | `\\files01\users\%username%` |
| Profile Path | `\\files01\profiles\%username%` |
| Login Script | `\\files01\netlogon\finance-login.sh` |
| Account Options | User cannot change password expiration, must change at first login |
| Password Policy | 90-day expiration, 14 char minimum, complexity required |

**Example Accounts:**
- `sarah.mitchell` (Finance Manager, finance-ws01)
- `james.rodriguez` (Finance Manager, finance-ws02)

**Ansible Implementation:**
- Use templates for consistent user creation
- Variable-based account provisioning
- Set account flags and password policies via AD attributes
- Add to security groups automatically

---

### 2.4 Group Policy Objects (GPOs)

**Requirement ID:** `REQ-AD-FINANCE-004`

Create and link the following GPO:

**GPO Name:** `GPO-Finance-Workstations`
**Linked to:** `OU=Finance`

**Policy Settings:**

| Category | Setting | Value |
|----------|---------|-------|
| Password Policy | Minimum password length | 14 characters |
| Password Policy | Password complexity | Enabled |
| Password Policy | Maximum password age | 90 days |
| Password Policy | Password history | 10 passwords |
| Security Options | USB storage access | **Disabled** (Finance data protection) |
| Security Options | Software installation | Disabled for users |
| Security Options | Screen lock timeout | 10 minutes idle |
| Software Restriction | Prevent execution from Temp/Downloads | Enabled |
| Audit Policy | File access auditing | Success/Failure |
| Audit Policy | Account logon events | Success/Failure |
| Audit Policy | Object access | Success/Failure |
| Desktop | Disable removable media autoplay | Enabled |
| Desktop | Prevent Desktop modifications | Enabled |
| Network | Disable Wi-Fi if wired connected | Enabled |

**Ansible Implementation:**
- For Samba AD: Configure via registry policies or samba-tool gpo
- Validate GPO application on test workstation before rollout
- Document all policy settings for audit purposes

---

## 3. File Server Requirements

### 3.1 File Server Infrastructure

**Requirement ID:** `REQ-FILE-FINANCE-001`

**Server:** `files01.smboffice.local`
**Role:** Samba File Server with AD integration and audit logging
**OS:** Oracle Linux 9 (for SELinux support) or Ubuntu Server 22.04

**Additional Requirements:**
- Dedicated storage volume for Finance data (encryption at rest recommended)
- Backup schedule: Daily incremental, weekly full
- Snapshot retention: 30 days

---

### 3.2 Share Definitions

**Requirement ID:** `REQ-FILE-FINANCE-002`

Create the following SMB shares:

#### Share 1: Finance Department Files (Read/Write)

```yaml
share_name: finance
path: /srv/samba/shares/finance
comment: "Finance Department - Restricted Access"
valid_users: "@SG-Finance-Files-RW"
read_list: "@SG-Finance-Files-RW"
write_list: "@SG-Finance-Files-RW"
create_mask: "0660"
directory_mask: "0770"
vfs_objects: "acl_xattr full_audit"
full_audit:prefix: "%u|%I|%m|%S"
full_audit:success: "mkdir rmdir write unlink rename"
full_audit:failure: "all"
full_audit:facility: "local5"
full_audit:priority: "notice"
```

#### Share 2: Client Billing Data (Managers Only - Read/Write)

```yaml
share_name: client-billing
path: /srv/samba/shares/clients/billing
comment: "Client Invoices and Billing Records - Manager Access Only"
valid_users: "@SG-Client-Billing"
read_list: "@SG-Client-Billing"
write_list: "@SG-Client-Billing"
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

#### Share 3: HR Payroll Data (Read-Only Cross-Access)

```yaml
share_name: hr-payroll
path: /srv/samba/shares/hr/payroll
comment: "HR Payroll Data - Finance Manager Read-Only Access"
valid_users: "@GG-HR-Department", "@SG-Payroll-ReadOnly"
read_list: "@GG-HR-Department", "@SG-Payroll-ReadOnly"
write_list: "@GG-HR-Department"
create_mask: "0660"
directory_mask: "0770"
vfs_objects: "acl_xattr full_audit"
full_audit:prefix: "%u|%I|%m|%S"
full_audit:success: "read"
full_audit:failure: "all"
full_audit:facility: "local5"
full_audit:priority: "notice"
```

**Note:** This implements **separation of duties** - Finance can view but not modify payroll data.

---

### 3.3 Directory Structure

**Requirement ID:** `REQ-FILE-FINANCE-003`

Create the following directory structure on `files01`:

```
/srv/samba/shares/
├── finance/
│   ├── reports/
│   │   ├── monthly/
│   │   ├── quarterly/
│   │   └── annual/
│   ├── budgets/
│   │   ├── FY2025/
│   │   └── FY2026/
│   ├── accounts-payable/
│   ├── accounts-receivable/
│   ├── audit-support/
│   └── templates/
│       ├── budget-templates/
│       └── report-templates/
├── clients/
│   └── billing/
│       ├── invoices/
│       │   ├── 2025/
│       │   └── 2024/
│       └── statements/
├── hr/
│   └── payroll/                # Finance has READ-ONLY access
│       ├── current/
│       └── archive/
└── users/
    └── <finance-username>/     # Individual user home directories
```

**Ansible Implementation:**
- Use `file` module to create directories with correct ownership
- Set base permissions: `root:root` with `0750` for Finance directories (more restrictive)
- Apply SELinux contexts for Samba shares

---

### 3.4 File System ACLs

**Requirement ID:** `REQ-FILE-FINANCE-004`

Apply POSIX ACLs to enforce security boundaries:

```bash
# Finance department files - Full access for Finance group
setfacl -R -m g:SG-Finance-Files-RW:rwx /srv/samba/shares/finance
setfacl -R -d -m g:SG-Finance-Files-RW:rwx /srv/samba/shares/finance

# Client billing - Managers only
setfacl -R -m g:SG-Client-Billing:rwx /srv/samba/shares/clients/billing
setfacl -R -d -m g:SG-Client-Billing:rwx /srv/samba/shares/clients/billing

# HR Payroll - Read-only for Finance Managers, full for HR
setfacl -R -m g:SG-Payroll-ReadOnly:r-x /srv/samba/shares/hr/payroll
setfacl -R -d -m g:SG-Payroll-ReadOnly:r-x /srv/samba/shares/hr/payroll
setfacl -R -m g:GG-HR-Department:rwx /srv/samba/shares/hr/payroll
setfacl -R -d -m g:GG-HR-Department:rwx /srv/samba/shares/hr/payroll

# Deny access to other departments
setfacl -R -m g:GG-IT:--- /srv/samba/shares/finance
setfacl -R -m g:GG-Shared-Services:--- /srv/samba/shares/finance
```

**Ansible Implementation:**
- Use `acl` module to set filesystem ACLs
- Apply default ACLs (`-d`) for inheritance
- Explicitly deny non-Finance groups
- Verify ACLs with `getfacl` in validation tasks

---

### 3.5 Access Restrictions

**Requirement ID:** `REQ-FILE-FINANCE-005`

**DENY Access to the following:**

| Share/Path | Finance Manager Access |
|------------|------------------------|
| `\\files01\hr\personnel` | **DENIED** (employee records - HR only) |
| `\\files01\it\*` | **DENIED** (IT administrative shares) |
| `\\files01\professional-services\*` | **DENIED** (consulting department files) |

**GRANTED Access:**

| Share/Path | Finance Manager Access | Notes |
|------------|------------------------|-------|
| `\\files01\finance` | **Read/Write** | Full department access |
| `\\files01\client-billing` | **Read/Write** | Billing and invoice access |
| `\\files01\hr-payroll` | **Read-Only** | Separation of duties |

**Implementation:**
- Ensure restricted shares have `valid_users` lists that **exclude** `GG-Finance`
- Test access denial via validation playbook

---

## 4. Workstation Requirements

### 4.1 Workstation Provisioning

**Requirement ID:** `REQ-WS-FINANCE-001`

Finance Manager workstations must meet the following specifications:

| Attribute | Value |
|-----------|-------|
| Hostname Format | `finance-ws##` (e.g., `finance-ws01`, `finance-ws02`) |
| OS | Ubuntu Desktop 22.04 LTS or 24.04 LTS |
| Domain Join | Joined to `smboffice.local` via SSSD |
| RAM | 8GB minimum, 16GB recommended |
| Disk | 80GB minimum (for local caching) |
| CPU | 2 vCPU minimum, 4 recommended |
| Network | Bridged to Finance VLAN (VLAN 20 - Finance) |
| Encryption | Full disk encryption (LUKS) **required** |

**Ansible Implementation:**
- Provision VMs via Proxmox API or template cloning
- Set hostname via `hostname` module
- Configure LUKS encryption during provisioning
- Join domain using SSSD configuration role

---

### 4.2 Domain Join Configuration (SSSD)

**Requirement ID:** `REQ-WS-FINANCE-002`

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

# Finance-specific settings
ldap_user_search_base = OU=Finance,OU=Users,DC=smboffice,DC=local
krb5_renewable_lifetime = 7d
krb5_renew_interval = 3600
```

**Ansible Implementation:**
- Use `template` module to deploy `/etc/sssd/sssd.conf`
- Install required packages: `sssd`, `sssd-ad`, `realmd`, `adcli`, `krb5-workstation`
- Join domain using `realm join` command with Finance OU specification
- Enable and start `sssd` service
- Set restrictive permissions on sssd.conf: `chmod 600`

---

### 4.3 Software Installation

**Requirement ID:** `REQ-WS-FINANCE-003`

Install the following software on Finance Manager workstations:

| Application | Purpose | Package/Source |
|-------------|---------|----------------|
| LibreOffice Calc | Spreadsheet analysis, budgets | `libreoffice-calc` |
| LibreOffice Writer | Reports and documentation | `libreoffice-writer` |
| Thunderbird | Email client with encryption support | `thunderbird` |
| Firefox ESR | Web browser for accounting applications | `firefox-esr` |
| PDF Viewer | View financial reports | `evince` |
| CUPS Client | Network printing | `cups-client` |
| GnuCash (Optional) | Local accounting software | `gnucash` |
| Password Manager | KeePassXC for credential management | `keepassxc` |

**DO NOT INSTALL:**
- Messaging applications (Slack, Discord, etc.)
- Media players
- Gaming software
- Torrent clients

**Ansible Implementation:**
- Use `apt` module for package installation
- Pin Firefox ESR for stability
- Configure default applications via user profile
- Remove unnecessary packages to reduce attack surface

---

### 4.4 Desktop Policy Enforcement

**Requirement ID:** `REQ-WS-FINANCE-004`

Enforce the following desktop policies via dconf/gsettings:

```yaml
desktop_policies:
  # Lockdown settings
  - key: "/org/gnome/desktop/lockdown/disable-user-switching"
    value: true
  - key: "/org/gnome/desktop/lockdown/disable-log-out"
    value: false

  # USB and removable media - DISABLED for Finance
  - key: "/org/gnome/desktop/media-handling/automount"
    value: false
  - key: "/org/gnome/desktop/media-handling/automount-open"
    value: false
  - key: "/org/gnome/desktop/removable-media/autorun-never"
    value: true

  # Screen lock settings (stricter for Finance)
  - key: "/org/gnome/desktop/screensaver/lock-enabled"
    value: true
  - key: "/org/gnome/desktop/screensaver/lock-delay"
    value: 600  # 10 minutes (per use case)
  - key: "/org/gnome/desktop/screensaver/idle-activation-enabled"
    value: true

  # Privacy settings
  - key: "/org/gnome/desktop/privacy/remember-recent-files"
    value: false
  - key: "/org/gnome/desktop/privacy/remove-old-trash-files"
    value: true
  - key: "/org/gnome/desktop/privacy/old-files-age"
    value: 7  # 7 days
```

**Ansible Implementation:**
- Use `dconf` module to set system-wide policies
- Deploy to `/etc/dconf/db/local.d/`
- Run `dconf update` after changes
- Lock settings to prevent user override

---

### 4.5 Network Segmentation

**Requirement ID:** `REQ-WS-FINANCE-005`

**VLAN Assignment:** VLAN 20 - Finance Department

| VLAN | Subnet | Purpose | Allowed Access |
|------|--------|---------|----------------|
| VLAN 20 | 10.10.20.0/24 | Finance workstations and servers | - Domain Controllers<br>- File servers<br>- Print servers<br>- Email servers |

**Firewall Rules:**
- **DENY** direct access from other VLANs to Finance VLAN
- **ALLOW** Finance VLAN to shared infrastructure (AD, DNS, file server)
- **DENY** Finance workstations from initiating connections to Internet (proxy required)

**Ansible Implementation:**
- Configure firewall rules on Proxmox host or network firewall
- Use `iptables` or `nftables` for host-based filtering
- Document VLAN configuration in network topology

---

## 5. Print Server Requirements

### 5.1 Print Server Infrastructure

**Requirement ID:** `REQ-PRINT-FINANCE-001`

**Server:** `print01.smboffice.local`
**Role:** CUPS Print Server with Samba integration and audit logging

---

### 5.2 Printer Access Control

**Requirement ID:** `REQ-PRINT-FINANCE-002`

Finance Managers must have access to the following printers:

| Printer Name | Location | Access Group | Purpose | Security Features |
|--------------|----------|--------------|---------|-------------------|
| `Finance-Printer` | Finance Office | `SG-Printer-Finance` | Confidential financial documents | Secure print release |

**CUPS ACL Configuration:**

```apache
<Printer Finance-Printer>
  Info Finance Department Secure Printer
  Location Finance Office
  DeviceURI ipp://finance-printer.local:631/ipp/print
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
  Require user @SG-Printer-Finance
  Order deny,allow
  Deny from all
  Allow from 10.10.20.0/24
</Printer>
```

**Security Features:**
- Secure print release (requires badge/PIN at printer)
- Print job audit logging
- Network restriction to Finance VLAN only

**Ansible Implementation:**
- Install CUPS: `cups`, `samba-client`
- Configure `/etc/cups/printers.conf` with ACLs
- Add printer via `lpadmin` command
- Enable audit logging for print jobs

---

## 6. Security Requirements

### 6.1 Audit Logging

**Requirement ID:** `REQ-SEC-FINANCE-001`

Configure `auditd` to monitor Finance Manager file and system access:

**Audit Rules for File Server:**

```bash
# Monitor all Finance share access
-w /srv/samba/shares/finance -p rwa -k finance_file_access

# Monitor client billing data (high sensitivity)
-w /srv/samba/shares/clients/billing -p rwa -k finance_billing_access

# Monitor read access to HR payroll (separation of duties)
-w /srv/samba/shares/hr/payroll -p r -k finance_payroll_read

# Monitor Finance user account changes
-w /var/log/samba/ -p wa -k finance_samba_logs
```

**Audit Rules for Workstations:**

```bash
# Monitor USB device attempts (should be blocked)
-w /dev/bus/usb -p rwa -k finance_usb_attempt

# Monitor sudo attempts (should fail - no sudo access)
-a always,exit -F arch=b64 -S execve -F euid=0 -F auid>=1000 -k finance_privilege_escalation

# Monitor file deletions in Finance home directories
-a always,exit -F arch=b64 -S unlink -S unlinkat -S rename -S renameat -F auid>=1000 -k finance_file_delete

# Monitor network connections
-a always,exit -F arch=b64 -S connect -F auid>=1000 -k finance_network_connect
```

**Ansible Implementation:**
- Deploy rules to `/etc/audit/rules.d/finance.rules`
- Restart auditd service
- Configure log rotation in `/etc/audit/auditd.conf`
- Forward audit logs to central SIEM/syslog server

---

### 6.2 USB Storage Restrictions

**Requirement ID:** `REQ-SEC-FINANCE-002`

**Policy:** USB storage devices are **completely disabled** for Finance workstations.

**Implementation via udev rules:**

```bash
# /etc/udev/rules.d/99-usb-storage-deny.rules
# Block all USB storage devices for Finance users
SUBSYSTEM=="usb", ATTRS{bDeviceClass}=="08", ENV{UDISKS_IGNORE}="1"
SUBSYSTEM=="block", ATTRS{removable}=="1", ENV{UDISKS_IGNORE}="1"
```

**Additional kernel module blacklisting:**

```bash
# /etc/modprobe.d/finance-usb-deny.conf
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

### 6.3 SELinux / AppArmor Enforcement

**Requirement ID:** `REQ-SEC-FINANCE-003`

**For Oracle Linux (SELinux) - RECOMMENDED:**
- Set SELinux to **enforcing** mode
- Apply Samba-specific contexts to Finance share directories:

```bash
semanage fcontext -a -t samba_share_t "/srv/samba/shares/finance(/.*)?"
semanage fcontext -a -t samba_share_t "/srv/samba/shares/clients/billing(/.*)?"
restorecon -Rv /srv/samba/shares
```

**Custom SELinux policy for Finance:**
```bash
# Allow Finance-specific Samba operations
module finance_samba 1.0;

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

### 6.4 Password and Account Security

**Requirement ID:** `REQ-SEC-FINANCE-004`

| Policy | Setting |
|--------|---------|
| Password Complexity | Minimum 14 characters, uppercase, lowercase, number, special char |
| Password Expiration | 90 days |
| Password History | Remember last 10 passwords |
| Account Lockout | 5 failed attempts, 30-minute lockout |
| Session Timeout | 10 minutes idle lock (stricter for Finance) |
| Multi-Factor Authentication | **Required** (via OTP or hardware token) |

**Ansible Implementation:**
- Configure via Samba AD password policy commands
- Set PAM settings on workstations (`/etc/pam.d/common-password`)
- Install and configure MFA solution (Google Authenticator or FreeOTP)

---

### 6.5 Data Loss Prevention (DLP)

**Requirement ID:** `REQ-SEC-FINANCE-005`

**Email DLP Policies:**
- Block emails containing keywords: "payroll", "salary", "confidential", "invoice" to external domains
- Require encryption for emails with financial attachments
- Alert on large attachments (>10MB)

**File DLP Policies:**
- Monitor and alert on large file transfers from Finance shares
- Block file uploads to cloud storage services (Dropbox, Google Drive, etc.)

**Ansible Implementation:**
- Configure email server (Postfix) with content filtering
- Use browser policies to block cloud storage domains
- Implement file monitoring via auditd and custom scripts

---

## 7. Monitoring and Audit Requirements

### 7.1 Log Aggregation

**Requirement ID:** `REQ-MON-FINANCE-001`

Forward logs to central syslog/SIEM server:

**Sources:**
- File server auditd logs
- Workstation authentication logs (`/var/log/auth.log`)
- Samba access logs (with full_audit VFS module)
- Print job logs
- Failed login attempts

**Log Retention:**
- Real-time logs: 90 days
- Archived logs: 7 years (SOX compliance requirement)

**Ansible Implementation:**
- Configure rsyslog to forward to `syslog01.smboffice.local:514`
- Use `template` module for `/etc/rsyslog.d/50-remote.conf`
- Configure log rotation with long retention
- Enable TLS for log transport (security)

---

### 7.2 Access Review Cadence

**Requirement ID:** `REQ-MON-FINANCE-002`

**Policy:** Finance Manager role and permissions reviewed **quarterly** by:
- IT Security Analyst
- Compliance & Risk Analyst
- Managing Partner or CFO equivalent

**Automated Access Reports:**
- Generate quarterly reports showing:
  - AD group memberships
  - File share access permissions
  - Recent file access patterns
  - Failed access attempts
  - Privilege changes

**Ansible Implementation:**
- Create reporting playbook that queries AD and file server
- Generate CSV/PDF reports
- Email to stakeholders automatically
- Store reports in audit archive

---

### 7.3 Compliance Monitoring

**Requirement ID:** `REQ-MON-FINANCE-003`

**SOX-Style Control Monitoring:**

| Control | Monitoring Method | Frequency |
|---------|------------------|-----------|
| Separation of Duties | Validate Finance cannot modify payroll | Monthly |
| Access Control | Review Finance group memberships | Quarterly |
| Audit Logging | Verify auditd is active and forwarding logs | Daily |
| Dual Control | Review file change logs for dual-approval workflows | Weekly |
| Password Policy | Validate password age and complexity | Monthly |

**Ansible Implementation:**
- Create compliance validation playbooks
- Schedule via cron for automated checks
- Alert on compliance failures
- Generate compliance dashboards

---

## 8. Compliance Requirements

### 8.1 SOX-Style Controls

**Requirement ID:** `REQ-COMP-FINANCE-001`

Implement the following SOX-style controls:

| Control ID | Control Description | Implementation |
|------------|---------------------|----------------|
| SOX-AC-01 | Access to financial data is restricted to authorized personnel only | AD security groups, file ACLs |
| SOX-AC-02 | Separation of duties between Finance and HR payroll functions | Read-only access to payroll share |
| SOX-AU-01 | All access to financial records is logged and monitored | Auditd, Samba full_audit VFS |
| SOX-AU-02 | Audit logs are retained for 7 years | Log archival and retention policy |
| SOX-PW-01 | Strong password policies are enforced | 14-char minimum, 90-day expiration |
| SOX-DC-01 | Critical financial changes require dual control | GPO settings, file change monitoring |

**Ansible Implementation:**
- Document control mappings in playbook variables
- Create validation tasks for each control
- Generate compliance evidence reports

---

### 8.2 Audit Simulation Support

**Requirement ID:** `REQ-COMP-FINANCE-002`

**Support for simulated SOX audits:**

Provide the following capabilities for audit simulation:
- Generate audit evidence reports (access logs, group memberships, policy settings)
- Demonstrate separation of duties controls
- Show audit trail for financial data access
- Validate that changes are logged and reviewed
- Prove password policy enforcement
- Document data retention practices

**Ansible Implementation:**
- Create audit evidence collection playbook
- Generate audit-ready reports in PDF format
- Include screenshots of policy enforcement
- Document control effectiveness

---

## 9. Ansible Implementation Notes

### 9.1 Playbook Structure

**Recommended Playbook Organization:**

```
ansible/
├── playbooks/
│   ├── finance-manager-setup.yml          # Main orchestration playbook
│   └── finance-compliance-validation.yml  # Compliance checking
├── roles/
│   ├── ad-finance/
│   │   ├── tasks/
│   │   │   ├── main.yml
│   │   │   ├── create-ou.yml
│   │   │   ├── create-groups.yml
│   │   │   ├── create-users.yml
│   │   │   └── configure-gpo.yml
│   │   ├── templates/
│   │   │   └── finance-user.j2
│   │   └── vars/
│   │       └── main.yml
│   ├── fileserver-finance-shares/
│   │   ├── tasks/
│   │   │   ├── main.yml
│   │   │   ├── create-shares.yml
│   │   │   ├── set-acls.yml
│   │   │   └── configure-audit.yml
│   │   ├── templates/
│   │   │   └── smb-finance.conf.j2
│   │   └── files/
│   │       └── finance-share-structure.sh
│   ├── workstation-finance/
│   │   ├── tasks/
│   │   │   ├── main.yml
│   │   │   ├── provision-vm.yml
│   │   │   ├── configure-encryption.yml
│   │   │   ├── domain-join.yml
│   │   │   ├── install-software.yml
│   │   │   └── lockdown-desktop.yml
│   │   └── templates/
│   │       └── sssd-finance.conf.j2
│   ├── security-finance/
│   │   ├── tasks/
│   │   │   ├── main.yml
│   │   │   ├── auditd-rules.yml
│   │   │   ├── usb-lockdown.yml
│   │   │   ├── selinux-config.yml
│   │   │   └── dlp-policies.yml
│   │   └── files/
│   │       ├── finance-audit.rules
│   │       └── usb-deny.rules
│   └── compliance-finance/
│       ├── tasks/
│       │   ├── main.yml
│       │   ├── sox-validation.yml
│       │   └── generate-reports.yml
│       └── templates/
│           └── compliance-report.j2
└── inventory/
    └── hosts.yml
```

---

### 9.2 Variables

**Suggested variable file** (`roles/ad-finance/vars/main.yml`):

```yaml
# AD Domain settings
ad_domain: "smboffice.local"
ad_realm: "SMBOFFICE.LOCAL"
ad_base_dn: "DC=smboffice,DC=local"

# OU Structure
finance_ou: "OU=Finance,OU=Users,{{ ad_base_dn }}"
finance_managers_ou: "OU=FinanceManagers,{{ finance_ou }}"

# Security Groups
finance_groups:
  - name: "GG-Finance"
    scope: "Global"
    description: "Primary Finance department group"
  - name: "SG-Finance-Managers"
    scope: "Global"
    description: "Finance Manager role group"
  - name: "SG-Finance-Files-RW"
    scope: "DomainLocal"
    description: "Read/Write access to Finance file shares"
  - name: "SG-Client-Billing"
    scope: "DomainLocal"
    description: "Access to client invoice and billing data"
  - name: "SG-Payroll-ReadOnly"
    scope: "DomainLocal"
    description: "Read-only access to payroll data"
  - name: "SG-Printer-Finance"
    scope: "DomainLocal"
    description: "Finance printer access"

# Finance Manager Users
finance_managers:
  - username: "sarah.mitchell"
    firstname: "Sarah"
    lastname: "Mitchell"
    email: "sarah.mitchell@smboffice.local"
    title: "Finance Manager"
    workstation: "finance-ws01"
  - username: "james.rodriguez"
    firstname: "James"
    lastname: "Rodriguez"
    email: "james.rodriguez@smboffice.local"
    title: "Finance Manager"
    workstation: "finance-ws02"

# File Shares
file_server: "files01.smboffice.local"
share_base: "/srv/samba/shares"

finance_shares:
  - name: "finance"
    path: "{{ share_base }}/finance"
    comment: "Finance Department - Restricted Access"
    valid_users: "@SG-Finance-Files-RW"
    writable: yes
    audit: full

  - name: "client-billing"
    path: "{{ share_base }}/clients/billing"
    comment: "Client Invoices and Billing Records - Manager Access Only"
    valid_users: "@SG-Client-Billing"
    writable: yes
    browseable: no
    audit: full

  - name: "hr-payroll"
    path: "{{ share_base }}/hr/payroll"
    comment: "HR Payroll Data - Finance Manager Read-Only Access"
    valid_users: "@GG-HR-Department,@SG-Payroll-ReadOnly"
    read_list: "@GG-HR-Department,@SG-Payroll-ReadOnly"
    write_list: "@GG-HR-Department"
    writable: yes
    audit: read

# Network Configuration
finance_vlan: 20
finance_subnet: "10.10.20.0/24"

# Security Settings
finance_password_length: 14
finance_password_age: 90
finance_password_history: 10
finance_screen_lock_timeout: 600  # 10 minutes
usb_enabled: false
mfa_required: true

# Compliance Settings
sox_compliance: true
audit_retention_days: 2555  # 7 years
access_review_frequency: "quarterly"
```

---

### 9.3 Idempotency Considerations

Ensure all tasks are idempotent:
- Use `state: present` for resources that should exist
- Check for resource existence before creation
- Use `--check` mode for testing without changes
- Handle encrypted volumes gracefully (don't re-encrypt)
- Validate group memberships before adding/removing

---

### 9.4 Sensitive Data Handling

**Ansible Vault for Secrets:**
```yaml
# Encrypt sensitive variables
ansible-vault create group_vars/finance/vault.yml

# Contents:
vault_finance_admin_password: "SecurePassword123!"
vault_luks_passphrase: "DiskEncryptionKey456!"
vault_mfa_secret: "TOTPSECRET789"
```

**Ansible Implementation:**
- Store passwords in Ansible Vault
- Use `no_log: true` for sensitive tasks
- Rotate secrets regularly
- Never commit unencrypted credentials

---

## 10. Validation and Testing

### 10.1 Test Cases

**Requirement ID:** `REQ-TEST-FINANCE-001`

Create the following test cases:

| Test ID | Test Description | Expected Result |
|---------|------------------|-----------------|
| `TEST-FIN-001` | Finance Manager can log in to `finance-ws01` with AD credentials | Login successful |
| `TEST-FIN-002` | Finance Manager can access `\\files01\finance` with read/write | Files readable and writable |
| `TEST-FIN-003` | Finance Manager can access `\\files01\client-billing` with read/write | Files readable and writable |
| `TEST-FIN-004` | Finance Manager can access `\\files01\hr-payroll` with **read-only** | Files readable, write **denied** |
| `TEST-FIN-005` | Finance Manager **cannot** access `\\files01\hr\personnel` | Access denied |
| `TEST-FIN-006` | Finance Manager **cannot** access `\\files01\it` | Access denied |
| `TEST-FIN-007` | Finance Manager can print to `Finance-Printer` | Print job successful |
| `TEST-FIN-008` | Finance Manager **cannot** install software | Installation blocked |
| `TEST-FIN-009` | USB storage is **completely blocked** | USB device not recognized |
| `TEST-FIN-010` | File access is logged in auditd | Audit log entry created |
| `TEST-FIN-011` | Screen locks after 10 minutes idle | Screen lock activated |
| `TEST-FIN-012` | Separation of duties validated | Read-only access to payroll confirmed |
| `TEST-FIN-013` | Audit logs are forwarded to syslog server | Logs received at syslog01 |
| `TEST-FIN-014` | MFA is required for login | Cannot login without OTP |

---

### 10.2 Validation Playbook

Create an Ansible validation playbook:

```yaml
# playbooks/validate-finance-manager.yml
---
- name: Validate Finance Manager Configuration
  hosts: localhost
  tasks:
    - name: Check if Finance AD groups exist
      command: samba-tool group show "{{ item }}"
      loop:
        - GG-Finance
        - SG-Finance-Managers
        - SG-Finance-Files-RW
        - SG-Client-Billing
        - SG-Payroll-ReadOnly
      register: group_check

    - name: Verify Finance file shares exist
      stat:
        path: "{{ item }}"
      loop:
        - /srv/samba/shares/finance
        - /srv/samba/shares/clients/billing
        - /srv/samba/shares/hr/payroll
      register: share_stat

    - name: Test ACLs on Finance directory
      command: getfacl /srv/samba/shares/finance
      register: acl_check

    - name: Verify auditd rules are loaded
      command: auditctl -l
      register: audit_rules
      failed_when: "'finance_file_access' not in audit_rules.stdout"

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
        sudo -u sarah.mitchell test -w /srv/samba/shares/hr/payroll/test.txt
      register: payroll_write_test
      failed_when: payroll_write_test.rc == 0  # Should fail (no write access)
      ignore_errors: yes
```

---

### 10.3 Compliance Validation

**Requirement ID:** `REQ-TEST-FINANCE-002`

Create compliance validation playbook:

```yaml
# playbooks/validate-finance-compliance.yml
---
- name: SOX-Style Compliance Validation for Finance
  hosts: localhost
  tasks:
    - name: SOX-AC-01 - Verify access restriction
      # Test that non-Finance users cannot access Finance shares

    - name: SOX-AC-02 - Verify separation of duties
      # Test Finance has read-only access to HR payroll

    - name: SOX-AU-01 - Verify audit logging is active
      # Check auditd is running and logging Finance access

    - name: SOX-AU-02 - Verify audit log retention
      # Check log rotation configured for 7 years

    - name: SOX-PW-01 - Verify password policy
      # Check password policy meets 14-char, 90-day requirements

    - name: Generate compliance report
      template:
        src: compliance-report.j2
        dest: /var/reports/finance-compliance-{{ ansible_date_time.date }}.pdf
```

---

## 11. Dependencies

### 11.1 Infrastructure Dependencies

| Dependency | Description | Status Required |
|------------|-------------|----------------|
| Samba AD Domain Controller | `dc01.smboffice.local` must be operational | **CRITICAL** |
| File Server | `files01.smboffice.local` must be provisioned with encryption | **CRITICAL** |
| Print Server | `print01.smboffice.local` must be configured | **HIGH** |
| Network VLAN | Finance VLAN (VLAN 20) must be configured and isolated | **CRITICAL** |
| DNS | Forward/reverse DNS zones configured | **CRITICAL** |
| Syslog/SIEM Server | `syslog01.smboffice.local` for log aggregation | **HIGH** |
| Backup System | Finance data backup and retention system | **CRITICAL** |

---

### 11.2 Prerequisite Roles

The following roles/configurations must be implemented before Finance Manager setup:

1. **HR Department baseline** (`GG-HR-Department` group must exist for payroll access)
2. **File server base shares** (`/srv/samba/shares` structure with encryption)
3. **Workstation template** (Ubuntu desktop template with LUKS encryption)
4. **Print server base** (CUPS with secure print capabilities)
5. **Audit infrastructure** (auditd, log forwarding, SIEM integration)

---

### 11.3 Related Requirements Documents

| Document | Description |
|----------|-------------|
| `hr-manager-requirements.md` | HR role requirements (for payroll share dependency) |
| `admin-assistant-requirements.md` | Admin Assistant role (cross-reference) |
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
| Compliance & Risk Analyst | | [ ] Pending | | SOX compliance validation |
| IT Ansible Programmer | | [ ] Pending | | Ansible implementation feasibility |
| IT Code Auditor | | [ ] Pending | | Code quality and best practices |

---

## 📝 Version History

| Version | Date | Author | Changes |
|---------|------|--------|---------|
| v1.0 | 2025-12-23 | IT Business Analyst | Initial requirements specification derived from USECASE-ROLE-FINANCE-001 |

---

## 📎 Appendix

### A.1 Samba Share Configuration Example (with Full Audit)

```ini
[finance]
path = /srv/samba/shares/finance
comment = Finance Department - Restricted Access
valid users = @SG-Finance-Files-RW
read list = @SG-Finance-Files-RW
write list = @SG-Finance-Files-RW
create mask = 0660
directory mask = 0770
vfs objects = acl_xattr full_audit
full_audit:prefix = %u|%I|%m|%S
full_audit:success = open close read write rename unlink mkdir rmdir
full_audit:failure = all
full_audit:facility = local5
full_audit:priority = notice
browseable = yes
```

### A.2 SSSD Configuration Example (Finance-Specific)

See Section 4.2 for full SSSD configuration.

### A.3 Audit Rule Testing

```bash
# Test Finance audit rule creation
ausearch -k finance_file_access

# View real-time Finance audit events
tail -f /var/log/audit/audit.log | grep finance_

# Generate audit report for compliance
aureport -f -i --summary | grep finance
```

### A.4 SOX Control Evidence Collection

```bash
# Generate SOX compliance evidence package
ansible-playbook playbooks/finance-compliance-validation.yml \
  --extra-vars "output_dir=/var/reports/sox-$(date +%Y%m%d)"

# Package includes:
# - AD group membership reports
# - File ACL configurations
# - Audit log samples
# - Password policy settings
# - Access review logs
```

---

**End of Document**
