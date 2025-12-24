<!--
███████████████████████████████████████████████████████████████
  🔧 SMB Office IT Blueprint – System Requirements Document
  Doc ID: REQ-ROLE-ADMIN-001
  Source: USECASE-ROLE-ADMIN-001
  Author: IT Business Analyst
  Created: 2025-12-23
  Updated: 2025-12-23
  Version: v1.0
  Status: Draft
  Confidentiality: Internal
  Project Phase: Requirements Analysis
  Category: Technical Requirements
  Audience: Technical
  Owners: IT Business Analyst, IT AD Architect, IT Ansible Programmer
  Reviewers: IT Security Analyst, IT Linux Admin/Architect
  Tags: [admin-assistant, requirements, ansible, infrastructure]
  Purpose: Ansible Automation
  Compliance: Employment Standards
  Publish Target: Internal
  Summary: >
    Technical system requirements derived from the Admin Assistant use case
    for implementation via Ansible automation. Defines AD structure, file
    shares, permissions, workstation configuration, and security controls.
  Read Time: ~10 min
███████████████████████████████████████████████████████████████
-->

# 🔧 Admin Assistant – System Requirements Specification

**Source Use Case:** `USECASE-ROLE-ADMIN-001` (admin-assistant-use-case.md)
**Target Implementation:** Ansible Playbooks and Roles
**Related Roles:** Shared Services, Multi-departmental Support

---

## 📍 Table of Contents

- [1. Overview](#1-overview)
- [2. Active Directory Requirements](#2-active-directory-requirements)
- [3. File Server Requirements](#3-file-server-requirements)
- [4. Workstation Requirements](#4-workstation-requirements)
- [5. Print Server Requirements](#5-print-server-requirements)
- [6. Security Requirements](#6-security-requirements)
- [7. Monitoring and Audit Requirements](#7-monitoring-and-audit-requirements)
- [8. Ansible Implementation Notes](#8-ansible-implementation-notes)
- [9. Validation and Testing](#9-validation-and-testing)
- [10. Dependencies](#10-dependencies)

---

## 1. Overview

### 1.1 Purpose

This document translates business requirements from the Admin Assistant use case into technical specifications for infrastructure automation via Ansible.

### 1.2 Scope

This specification covers:
- Active Directory organizational units, groups, and user accounts
- File server shares, directories, and ACL configurations
- Workstation provisioning and policy enforcement
- Print server access configuration
- Security controls and audit logging
- Application access (calendar, scheduling tools)

### 1.3 Implementation Priority

**Priority Level:** Medium (Tier 2 - Multi-departmental support role)
**Dependencies:** Must be implemented after HR and Finance baseline infrastructure

---

## 2. Active Directory Requirements

### 2.1 Organizational Unit Structure

**Requirement ID:** `REQ-AD-ADMIN-001`

Create the following OU structure:

```
Domain: smboffice.local
└── OU=Users
    └── OU=SharedServices
        └── OU=AdminAssistants
```

**Ansible Implementation:**
- Use `community.windows.win_domain_ou` module or Samba AD equivalent
- Create OU hierarchy if not exists (idempotent)
- Apply description: "Administrative Assistant accounts for multi-departmental support"

---

### 2.2 Security Groups

**Requirement ID:** `REQ-AD-ADMIN-002`

Create the following security groups:

| Group Name | Scope | Type | Description | OU Location |
|------------|-------|------|-------------|-------------|
| `GG-Shared-Services` | Global | Security | Primary group for all Admin Assistants | `OU=Groups,OU=SharedServices` |
| `SG-Office-Scheduling` | Domain Local | Security | Access to calendar and booking systems | `OU=Groups,OU=SharedServices` |
| `SG-Print-Access` | Domain Local | Security | Networked printer permissions | `OU=Groups,OU=Infrastructure` |
| `SG-Templates-Write` | Domain Local | Security | Read/Write to shared document templates | `OU=Groups,OU=FileAccess` |
| `SG-HR-Forms-Read` | Domain Local | Security | Read-only HR forms/templates folder | `OU=Groups,OU=FileAccess` |

**Ansible Implementation:**
- Create groups with proper scope and type
- Document group purpose in AD description field
- Establish group nesting: Add `GG-Shared-Services` to relevant `SG-*` groups

**Group Membership Rules:**
```yaml
# Nested group memberships
SG-Office-Scheduling:
  members:
    - GG-Shared-Services

SG-Print-Access:
  members:
    - GG-Shared-Services

SG-Templates-Write:
  members:
    - GG-Shared-Services

SG-HR-Forms-Read:
  members:
    - GG-Shared-Services
```

---

### 2.3 User Account Template

**Requirement ID:** `REQ-AD-ADMIN-003`

Admin Assistant user account specifications:

| Attribute | Value |
|-----------|-------|
| Username Format | `firstname.lastname` (lowercase) |
| Display Name | `FirstName LastName` |
| Email | `firstname.lastname@smboffice.local` |
| Primary Group | `GG-Shared-Services` |
| Home Directory | `\\files01\users\%username%` |
| Profile Path | `\\files01\profiles\%username%` |
| Login Script | `\\files01\netlogon\shared-services-login.sh` |
| Account Options | User cannot change password expiration, must change at first login |
| Password Policy | 90-day expiration, 12 char minimum, complexity required |

**Example Accounts:**
- `emily.chen` (assist-ws01)
- `david.kim` (assist-ws02)

**Ansible Implementation:**
- Use templates for consistent user creation
- Variable-based account provisioning
- Set account flags and password policies via AD attributes

---

### 2.4 Group Policy Objects (GPOs)

**Requirement ID:** `REQ-AD-ADMIN-004`

Create and link the following GPO:

**GPO Name:** `GPO-Shared-Services-Workstations`
**Linked to:** `OU=AdminAssistants`

**Policy Settings:**

| Category | Setting | Value |
|----------|---------|-------|
| Password Policy | Minimum password length | 12 characters |
| Password Policy | Password complexity | Enabled |
| Password Policy | Maximum password age | 90 days |
| Security Options | USB storage access | Read-only (via registry key) |
| Security Options | Software installation | Disabled for users |
| Software Restriction | Prevent execution from Temp/Downloads | Enabled |
| Audit Policy | File access auditing | Success/Failure |
| Desktop | Prevent Desktop modifications | Enabled |
| Network | Disable Wi-Fi if wired connected | Enabled |

**Ansible Implementation:**
- For Samba AD: Configure via registry policies or samba-tool gpo
- Validate GPO application on test workstation before rollout

---

## 3. File Server Requirements

### 3.1 File Server Infrastructure

**Requirement ID:** `REQ-FILE-ADMIN-001`

**Server:** `files01.smboffice.local`
**Role:** Samba File Server with AD integration
**OS:** Oracle Linux 9 or Ubuntu Server 22.04

---

### 3.2 Share Definitions

**Requirement ID:** `REQ-FILE-ADMIN-002`

Create the following SMB shares:

#### Share 1: Templates (Read/Write)

```yaml
share_name: templates
path: /srv/samba/shares/templates
comment: "Shared document templates for office-wide use"
valid_users: "@SG-Templates-Write"
read_list: "@SG-Templates-Write"
write_list: "@SG-Templates-Write"
create_mask: "0664"
directory_mask: "0775"
vfs_objects: "acl_xattr"
```

#### Share 2: HR Forms - Templates Subfolder (Read-Only)

```yaml
share_name: hr-forms
path: /srv/samba/shares/hr/forms
comment: "HR forms and templates (read-only for Admin Assistants)"
valid_users: "@SG-HR-Forms-Read", "@GG-HR-Department"
read_list: "@SG-HR-Forms-Read"
write_list: "@GG-HR-Department"
create_mask: "0664"
directory_mask: "0775"
browseable: yes
```

**Note:** Full HR share will have different ACLs; Admin Assistants only access `/forms/templates` subdirectory.

#### Share 3: Company Policies (Read/Write)

```yaml
share_name: company-policies
path: /srv/samba/shares/company/policies
comment: "Internal company policies and notices"
valid_users: "@GG-Shared-Services", "@GG-Management"
read_list: "@GG-Shared-Services", "@GG-Management"
write_list: "@GG-Shared-Services", "@GG-Management"
create_mask: "0664"
directory_mask: "0775"
```

---

### 3.3 Directory Structure

**Requirement ID:** `REQ-FILE-ADMIN-003`

Create the following directory structure on `files01`:

```
/srv/samba/shares/
├── templates/
│   ├── memos/
│   ├── letters/
│   ├── presentations/
│   └── spreadsheets/
├── hr/
│   └── forms/
│       └── templates/          # Admin Assistant READ access only
│           ├── employment-application.docx
│           ├── time-off-request.xlsx
│           └── employee-info-update.pdf
├── company/
│   └── policies/
│       ├── acceptable-use-policy.pdf
│       ├── dress-code.pdf
│       └── safety-procedures.pdf
└── users/
    └── <username>/             # User home directories
```

**Ansible Implementation:**
- Use `file` module to create directories with correct ownership
- Set base permissions: `root:root` with `0755` for directories
- Samba will overlay AD-based ACLs via `vfs_objects = acl_xattr`

---

### 3.4 File System ACLs

**Requirement ID:** `REQ-FILE-ADMIN-004`

Apply POSIX ACLs to enforce security boundaries:

```bash
# Templates directory
setfacl -R -m g:SG-Templates-Write:rwx /srv/samba/shares/templates
setfacl -R -d -m g:SG-Templates-Write:rwx /srv/samba/shares/templates

# HR forms templates (read-only for Admin Assistants)
setfacl -R -m g:SG-HR-Forms-Read:r-x /srv/samba/shares/hr/forms/templates
setfacl -R -d -m g:SG-HR-Forms-Read:r-x /srv/samba/shares/hr/forms/templates
setfacl -R -m g:GG-HR-Department:rwx /srv/samba/shares/hr/forms

# Company policies
setfacl -R -m g:GG-Shared-Services:rwx /srv/samba/shares/company/policies
setfacl -R -d -m g:GG-Shared-Services:rwx /srv/samba/shares/company/policies
```

**Ansible Implementation:**
- Use `acl` module to set filesystem ACLs
- Apply default ACLs (`-d`) for inheritance
- Verify ACLs with `getfacl` in validation tasks

---

### 3.5 Access Restrictions

**Requirement ID:** `REQ-FILE-ADMIN-005`

**DENY Access to the following:**

| Share/Path | Admin Assistant Access |
|------------|------------------------|
| `\\files01\hr\personnel` | **DENIED** (contains employee records) |
| `\\files01\hr\payroll` | **DENIED** (contains payroll data) |
| `\\files01\finance\*` | **DENIED** (all Finance shares) |
| `\\files01\it\backups` | **DENIED** (IT administrative shares) |

**Implementation:**
- Ensure these shares have `valid_users` lists that **exclude** `GG-Shared-Services`
- Test access denial via validation playbook

---

## 4. Workstation Requirements

### 4.1 Workstation Provisioning

**Requirement ID:** `REQ-WS-ADMIN-001`

Admin Assistant workstations must meet the following specifications:

| Attribute | Value |
|-----------|-------|
| Hostname Format | `assist-ws##` (e.g., `assist-ws01`, `assist-ws02`) |
| OS | Ubuntu Desktop 22.04 LTS or 24.04 LTS |
| Domain Join | Joined to `smboffice.local` via SSSD |
| RAM | Minimum 4GB, Recommended 8GB |
| Disk | 60GB minimum |
| CPU | 2 vCPU |
| Network | Bridged to office VLAN (VLAN 10 - Office) |

**Ansible Implementation:**
- Provision VMs via Proxmox API or template cloning
- Set hostname via `hostname` module
- Join domain using SSSD configuration role

---

### 4.2 Domain Join Configuration (SSSD)

**Requirement ID:** `REQ-WS-ADMIN-002`

Configure SSSD for AD authentication:

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
```

**Ansible Implementation:**
- Use `template` module to deploy `/etc/sssd/sssd.conf`
- Install required packages: `sssd`, `sssd-ad`, `realmd`, `adcli`, `krb5-workstation`
- Join domain using `realm join` command
- Enable and start `sssd` service

---

### 4.3 Software Installation

**Requirement ID:** `REQ-WS-ADMIN-003`

Install the following software on Admin Assistant workstations:

| Application | Purpose | Package/Source |
|-------------|---------|----------------|
| LibreOffice | Document editing (templates, memos) | `libreoffice` |
| Thunderbird | Email client | `thunderbird` |
| Firefox ESR | Web browser (shared calendar access) | `firefox-esr` |
| PDF Viewer | View/print PDFs | `evince` |
| CUPS Client | Network printing | `cups-client` |

**Ansible Implementation:**
- Use `apt` module for package installation
- Pin Firefox ESR for stability
- Configure default applications via user profile

---

### 4.4 Desktop Policy Enforcement

**Requirement ID:** `REQ-WS-ADMIN-004`

Enforce the following desktop policies via dconf/gsettings:

```yaml
desktop_policies:
  - key: "/org/gnome/desktop/lockdown/disable-user-switching"
    value: true
  - key: "/org/gnome/desktop/lockdown/disable-log-out"
    value: false
  - key: "/org/gnome/desktop/media-handling/automount"
    value: false  # Disable USB automount
  - key: "/org/gnome/desktop/screensaver/lock-enabled"
    value: true
  - key: "/org/gnome/desktop/screensaver/lock-delay"
    value: 300  # 5 minutes
```

**Ansible Implementation:**
- Use `dconf` module to set system-wide policies
- Deploy to `/etc/dconf/db/local.d/`
- Run `dconf update` after changes

---

## 5. Print Server Requirements

### 5.1 Print Server Infrastructure

**Requirement ID:** `REQ-PRINT-ADMIN-001`

**Server:** `print01.smboffice.local`
**Role:** CUPS Print Server with Samba integration
**Printer Drivers:** IPP Everywhere or Gutenprint

---

### 5.2 Printer Access Control

**Requirement ID:** `REQ-PRINT-ADMIN-002`

Admin Assistants must have access to the following printers:

| Printer Name | Location | Access Group | Purpose |
|--------------|----------|--------------|---------|
| `Main-Printer` | Office Floor 1 | `SG-Print-Access` | General office printing |
| `Reception-Printer` | Front Desk | `SG-Print-Access` | Reception/visitor documents |

**CUPS ACL Configuration:**

```apache
<Printer Main-Printer>
  AuthType Default
  Require user @SG-Print-Access
  Order deny,allow
</Printer>

<Printer Reception-Printer>
  AuthType Default
  Require user @SG-Print-Access
  Order deny,allow
</Printer>
```

**Ansible Implementation:**
- Install CUPS: `cups`, `samba-client`
- Configure `/etc/cups/printers.conf` with ACLs
- Add printers via `lpadmin` command
- Enable Samba print sharing if needed

---

## 6. Security Requirements

### 6.1 Audit Logging

**Requirement ID:** `REQ-SEC-ADMIN-001`

Configure `auditd` to monitor Admin Assistant file access:

**Audit Rules:**

```bash
# Monitor access to HR forms templates
-w /srv/samba/shares/hr/forms/templates -p r -k admin_hr_access

# Monitor modifications to company policies
-w /srv/samba/shares/company/policies -p w -k admin_policy_write

# Monitor template modifications
-w /srv/samba/shares/templates -p w -k admin_template_write

# Monitor USB device access
-w /dev/bus/usb -p r -k admin_usb_access
```

**Ansible Implementation:**
- Deploy rules to `/etc/audit/rules.d/admin-assistant.rules`
- Restart auditd service
- Configure log rotation in `/etc/audit/auditd.conf`

---

### 6.2 USB Storage Restrictions

**Requirement ID:** `REQ-SEC-ADMIN-002`

**Policy:** USB storage devices must be read-only for Admin Assistants.

**Implementation via udev rules:**

```bash
# /etc/udev/rules.d/99-usb-storage-ro.rules
SUBSYSTEM=="usb", ATTR{authorized}="1"
SUBSYSTEM=="block", ATTRS{removable}=="1", ENV{UDISKS_PRESENTATION_HIDE}="0", ENV{UDISKS_PRESENTATION_RO}="1"
```

**Ansible Implementation:**
- Deploy udev rule via `copy` module
- Reload udev rules: `udevadm control --reload-rules`
- Test with validation task

---

### 6.3 SELinux / AppArmor Enforcement

**Requirement ID:** `REQ-SEC-ADMIN-003`

**For Oracle Linux (SELinux):**
- Set SELinux to enforcing mode
- Apply Samba-specific contexts to share directories:

```bash
semanage fcontext -a -t samba_share_t "/srv/samba/shares(/.*)?"
restorecon -Rv /srv/samba/shares
```

**For Ubuntu (AppArmor):**
- Ensure AppArmor profiles are enforcing for key services
- No modifications needed for standard Samba usage

**Ansible Implementation:**
- Use `selinux` module (Oracle Linux) or `apparmor` module (Ubuntu)
- Set contexts via `sefcontext` and `shell` module for `restorecon`

---

### 6.4 Password and Account Security

**Requirement ID:** `REQ-SEC-ADMIN-004`

| Policy | Setting |
|--------|---------|
| Password Complexity | Minimum 12 characters, uppercase, lowercase, number, special char |
| Password Expiration | 90 days |
| Password History | Remember last 5 passwords |
| Account Lockout | 5 failed attempts, 15-minute lockout |
| Session Timeout | 15 minutes idle lock |

**Ansible Implementation:**
- Configure via Samba AD password policy commands
- Set PAM settings on workstations (`/etc/pam.d/common-password`)

---

## 7. Monitoring and Audit Requirements

### 7.1 Log Aggregation

**Requirement ID:** `REQ-MON-ADMIN-001`

Forward logs to central syslog server (if available):

**Sources:**
- File server auditd logs
- Workstation authentication logs (`/var/log/auth.log`)
- Samba access logs

**Ansible Implementation:**
- Configure rsyslog to forward to `syslog01.smboffice.local:514`
- Use `template` module for `/etc/rsyslog.d/50-remote.conf`

---

### 7.2 Access Review Cadence

**Requirement ID:** `REQ-MON-ADMIN-002`

**Policy:** Admin Assistant role and permissions reviewed **semi-annually** by:
- IT Security Analyst
- IT AD Architect
- HR Manager

**Implementation:**
- Create calendar reminder task
- Generate access report via Ansible playbook (query AD group memberships and file ACLs)

---

## 8. Ansible Implementation Notes

### 8.1 Playbook Structure

**Recommended Playbook Organization:**

```
ansible/
├── playbooks/
│   └── admin-assistant-setup.yml          # Main orchestration playbook
├── roles/
│   ├── ad-admin-assistant/
│   │   ├── tasks/
│   │   │   ├── main.yml
│   │   │   ├── create-ou.yml
│   │   │   ├── create-groups.yml
│   │   │   └── create-users.yml
│   │   ├── templates/
│   │   │   └── user-template.j2
│   │   └── vars/
│   │       └── main.yml
│   ├── fileserver-admin-shares/
│   │   ├── tasks/
│   │   │   ├── main.yml
│   │   │   ├── create-shares.yml
│   │   │   └── set-acls.yml
│   │   └── templates/
│   │       └── smb.conf.j2
│   ├── workstation-admin/
│   │   ├── tasks/
│   │   │   ├── main.yml
│   │   │   ├── domain-join.yml
│   │   │   └── install-software.yml
│   │   └── templates/
│   │       └── sssd.conf.j2
│   └── security-admin-assistant/
│       ├── tasks/
│       │   ├── main.yml
│       │   ├── auditd-rules.yml
│       │   └── usb-restrictions.yml
│       └── files/
│           └── admin-assistant.rules
└── inventory/
    └── hosts.yml
```

---

### 8.2 Variables

**Suggested variable file** (`roles/ad-admin-assistant/vars/main.yml`):

```yaml
# AD Domain settings
ad_domain: "smboffice.local"
ad_realm: "SMBOFFICE.LOCAL"
ad_base_dn: "DC=smboffice,DC=local"

# OU Structure
admin_ou: "OU=AdminAssistants,OU=Users,{{ ad_base_dn }}"

# Security Groups
admin_groups:
  - name: "GG-Shared-Services"
    scope: "Global"
    description: "Primary group for all Admin Assistants"
  - name: "SG-Office-Scheduling"
    scope: "DomainLocal"
    description: "Access to calendar and booking systems"
  - name: "SG-Print-Access"
    scope: "DomainLocal"
    description: "Networked printer permissions"
  - name: "SG-Templates-Write"
    scope: "DomainLocal"
    description: "Read/Write to shared document templates"
  - name: "SG-HR-Forms-Read"
    scope: "DomainLocal"
    description: "Read-only HR forms/templates folder"

# Admin Assistant Users
admin_users:
  - username: "emily.chen"
    firstname: "Emily"
    lastname: "Chen"
    email: "emily.chen@smboffice.local"
    workstation: "assist-ws01"
  - username: "david.kim"
    firstname: "David"
    lastname: "Kim"
    email: "david.kim@smboffice.local"
    workstation: "assist-ws02"

# File Shares
file_server: "files01.smboffice.local"
share_base: "/srv/samba/shares"

shares:
  - name: "templates"
    path: "{{ share_base }}/templates"
    comment: "Shared document templates"
    valid_users: "@SG-Templates-Write"
    writable: yes

  - name: "hr-forms"
    path: "{{ share_base }}/hr/forms"
    comment: "HR forms and templates"
    valid_users: "@SG-HR-Forms-Read,@GG-HR-Department"
    read_list: "@SG-HR-Forms-Read"
    write_list: "@GG-HR-Department"

  - name: "company-policies"
    path: "{{ share_base }}/company/policies"
    comment: "Internal company policies"
    valid_users: "@GG-Shared-Services,@GG-Management"
    writable: yes
```

---

### 8.3 Idempotency Considerations

Ensure all tasks are idempotent:
- Use `state: present` for resources that should exist
- Use `creates:` parameter for commands that shouldn't re-run
- Check for existence before creating (e.g., `stat` module before file creation)
- Use `--check` mode for testing without changes

---

## 9. Validation and Testing

### 9.1 Test Cases

**Requirement ID:** `REQ-TEST-ADMIN-001`

Create the following test cases:

| Test ID | Test Description | Expected Result |
|---------|------------------|-----------------|
| `TEST-ADMIN-001` | Admin Assistant can log in to `assist-ws01` with AD credentials | Login successful |
| `TEST-ADMIN-002` | Admin Assistant can access `\\files01\templates` with read/write | Files readable and writable |
| `TEST-ADMIN-003` | Admin Assistant can access `\\files01\hr-forms` with read-only | Files readable, write denied |
| `TEST-ADMIN-004` | Admin Assistant **cannot** access `\\files01\finance` | Access denied |
| `TEST-ADMIN-005` | Admin Assistant can print to `Main-Printer` | Print job successful |
| `TEST-ADMIN-006` | Admin Assistant cannot install software | Installation blocked |
| `TEST-ADMIN-007` | USB storage is read-only | Can read, cannot write |
| `TEST-ADMIN-008` | File access is logged in auditd | Audit log entry created |

---

### 9.2 Validation Playbook

Create an Ansible validation playbook:

```yaml
# playbooks/validate-admin-assistant.yml
---
- name: Validate Admin Assistant Configuration
  hosts: localhost
  tasks:
    - name: Check if AD groups exist
      command: samba-tool group show "{{ item }}"
      loop:
        - GG-Shared-Services
        - SG-Office-Scheduling
        - SG-Print-Access
      register: group_check

    - name: Verify file share accessibility
      stat:
        path: "/srv/samba/shares/templates"
      register: share_stat

    - name: Test ACLs on templates directory
      command: getfacl /srv/samba/shares/templates
      register: acl_check
```

---

## 10. Dependencies

### 10.1 Infrastructure Dependencies

| Dependency | Description | Status Required |
|------------|-------------|----------------|
| Samba AD Domain Controller | `dc01.smboffice.local` must be operational | **CRITICAL** |
| File Server | `files01.smboffice.local` must be provisioned | **CRITICAL** |
| Print Server | `print01.smboffice.local` must be configured | **HIGH** |
| Network VLAN | Office VLAN (VLAN 10) must be configured | **CRITICAL** |
| DNS | Forward/reverse DNS zones configured | **CRITICAL** |

---

### 10.2 Prerequisite Roles

The following roles/configurations must be implemented before Admin Assistant setup:

1. **HR Department baseline** (`GG-HR-Department` group must exist)
2. **Finance Department baseline** (for access denial validation)
3. **File server base shares** (`/srv/samba/shares` structure)
4. **Workstation template** (Ubuntu desktop template with base software)

---

### 10.3 Related Requirements Documents

| Document | Description |
|----------|-------------|
| `hr-manager-requirements.md` | HR role requirements (dependency) |
| `finance-manager-requirements.md` | Finance role requirements (dependency) |
| `file-server-baseline-requirements.md` | Core file server setup |
| `ad-baseline-requirements.md` | Core AD infrastructure |

---

## 📋 Review and Approval

| Role | Reviewer | Status | Date | Notes |
|------|----------|--------|------|-------|
| IT Business Analyst | | [ ] Pending | | Requirements derived from use case |
| IT AD Architect | | [ ] Pending | | AD structure and GPO review |
| IT Linux Admin/Architect | | [ ] Pending | | File server and workstation config |
| IT Security Analyst | | [ ] Pending | | Security controls and audit logging |
| IT Ansible Programmer | | [ ] Pending | | Ansible implementation feasibility |
| IT Code Auditor | | [ ] Pending | | Code quality and best practices |

---

## 📝 Version History

| Version | Date | Author | Changes |
|---------|------|--------|---------|
| v1.0 | 2025-12-23 | IT Business Analyst | Initial requirements specification derived from USECASE-ROLE-ADMIN-001 |

---

## 📎 Appendix

### A.1 Samba Share Configuration Example

```ini
[templates]
path = /srv/samba/shares/templates
comment = Shared document templates for office-wide use
valid users = @SG-Templates-Write
read list = @SG-Templates-Write
write list = @SG-Templates-Write
create mask = 0664
directory mask = 0775
vfs objects = acl_xattr
browseable = yes
```

### A.2 SSSD Configuration Example

See Section 4.2 for full SSSD configuration.

### A.3 Audit Rule Testing

```bash
# Test audit rule creation
ausearch -k admin_template_write

# View real-time audit events
tail -f /var/log/audit/audit.log | grep admin_
```

---

**End of Document**
