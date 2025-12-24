<!--
███████████████████████████████████████████████████████████████
  🧾 SMB Office IT Blueprint – Project Document
  Doc ID: SPEC-SYSTEM-001
  Author: IT Business Analyst, Linux Admin/Architect
  Created: 2025-12-23
  Updated: 2025-12-23
  Version: v1.3
  Status: Draft
  Confidentiality: Internal
  Project Phase: Implementation
  Category: Design Spec
  Audience: IT
  Owners: IT Business Analyst, Linux Admin/Architect, IT AD Architect
  Reviewers: IT Security Analyst, Project Doc Auditor, Ansible Programmer
  Tags: [system-specification, infrastructure, security, audit, compliance]
  Data Sensitivity: Simulated – Infrastructure Design
  Compliance: SOX, HIPAA (simulated), Internal Security Controls
  Publish Target: Internal
  Summary: >
    Comprehensive system specification for the SMB Office IT infrastructure.
    This document consolidates requirements from multiple business and security
    documents into a unified technical specification for implementation via
    Ansible automation. Built incrementally from audit, security, and
    departmental requirements.
  Read Time: ~25 min
███████████████████████████████████████████████████████████████
-->

# 📘 SMB Office IT Infrastructure – System Specification

**Project:** Samba AD Lab Series - SMB Office IT Blueprint
**Purpose:** Unified Technical Specification for Infrastructure Implementation
**Target Implementation:** Ansible Playbooks and Roles

---

## 📍 Table of Contents

- [1. Purpose](#1-purpose)
- [2. Background](#2-background)
- [3. Objectives](#3-objectives)
- [4. Structure / Body](#4-structure--body)
  - [4.0 Organizational Structure](#40-organizational-structure)
  - [4.1 System Overview](#41-system-overview)
  - [4.2 Infrastructure Architecture](#42-infrastructure-architecture)
  - [4.3 Security and Audit Requirements](#43-security-and-audit-requirements)
  - [4.4 Departmental Access Controls](#44-departmental-access-controls)
  - [4.5 Network Architecture](#45-network-architecture)
  - [4.6 Compliance Framework](#46-compliance-framework)
  - [4.7 Monitoring and Logging](#47-monitoring-and-logging)
  - [4.8 Backup and Recovery](#48-backup-and-recovery)
  - [4.9 Operational Policies](#49-operational-policies)
  - [4.10 Implementation Standards](#410-implementation-standards)
- [5. Related Files](#5-related-files)
- [6. Review History](#6-review-history)
- [7. Departmental Approval Checklist](#7-departmental-approval-checklist)

---

## 1. Purpose

This document serves as the **master system specification** for the SMB Office IT infrastructure. It consolidates requirements from multiple sources including:

- Business use cases (Finance, HR, Admin Assistant roles)
- Security policies and audit requirements
- Compliance frameworks (SOX, HIPAA-style controls)
- Network topology and access control requirements
- Monitoring and logging standards

The specification provides a **single source of truth** for infrastructure implementation, ensuring consistency across all Ansible automation, documentation, and testing activities.

---

## 2. Background

The SMB Office IT Blueprint project simulates a real-world small-to-medium business IT infrastructure deployment. The system must support:

- **Multiple departments** with distinct access requirements (HR, Finance, Professional Services, Shared Services)
- **Compliance frameworks** including SOX-style financial controls and HIPAA-style employee data protection
- **Separation of duties** between departments and roles
- **Comprehensive audit logging** for all sensitive data access
- **Automated provisioning** via Infrastructure-as-Code (Ansible)

This specification is built incrementally, with each pass adding requirements from additional source documents. The current version incorporates:

1. **Audit and logging requirements** (Finance department monitoring)
2. **Organizational structure** (Departments, roles, reporting hierarchy)
3. **File share structure** (Directory layout, naming conventions, access control)
4. **Policy frameworks** (Access control, GPO baseline, data retention, checkout procedures)
5. **Security frameworks** (HR audit rules, access control matrix, file permissions, secure communications)

---

## 3. Objectives

### 3.1 Primary Objectives

- Provide a unified technical specification for all infrastructure components
- Ensure consistency between requirements, implementation, and validation
- Support automated infrastructure deployment via Ansible
- Document security controls and compliance mappings
- Enable systematic testing and validation

### 3.2 Success Criteria

- All infrastructure components are specified with sufficient detail for implementation
- Security controls are mapped to compliance frameworks
- Audit logging meets retention and alerting requirements
- Specifications are testable and verifiable
- Documentation supports both implementation and operation

---

## 4. Structure / Body

### 4.0 Organizational Structure

**Source Document:** `ORG-STRUCTURE-001` (simulated-org-chart.md)

#### 4.0.1 Business Overview

The simulated SMB Office represents a professional services firm with the following characteristics:

- **Company Type:** Professional Services / Consulting Firm
- **Employee Count:** 15-20 employees (simulated)
- **Departments:** Executive, Finance, HR, Professional Services, IT
- **Business Model:** Client project delivery, billable hours, fixed-fee consulting

#### 4.0.2 Executive Leadership

| Role | Reports To | Responsibilities | Workstation |
|------|------------|------------------|-------------|
| Managing Partner | Board/Investors | Overall leadership, strategic direction | `exec-ws01` |
| Finance Manager | Managing Partner | Accounting, payroll oversight, budgeting | `finance-ws01` |
| HR Manager | Managing Partner | Personnel management, policies, compliance | `hr-ws01` |
| Project Manager | Managing Partner | IT projects, cross-departmental coordination | `pm-ws01` |

**Access Level:** Executive team has elevated access to cross-departmental resources while maintaining separation of duties for sensitive data (Finance/HR).

#### 4.0.3 Departmental Structure

```text
SMB Office
├── Executive Team
│   ├── Managing Partner (full administrative oversight)
│   ├── Finance Manager (financial oversight)
│   ├── HR Manager (personnel management)
│   └── Project Manager (IT/project coordination)
│
├── Finance Department
│   ├── Senior Accountant
│   ├── Junior Accountant
│   └── Finance Intern
│
├── HR Department
│   ├── HR Generalist
│   ├── Admin Assistant (multi-departmental support)
│   └── HR Intern
│
├── Professional Services
│   ├── Senior Professional (client-facing consultant)
│   ├── Junior Professional (project support)
│   └── Project Intern
│
└── IT Department (Simulated - Project Implementation)
    ├── IT Administrator
    ├── Linux Admin
    └── Ansible Automation Engineer
```

#### 4.0.4 Role Definitions and Access Levels

| Role | Department | Seniority | Primary Access Needs | Security Level |
|------|------------|-----------|----------------------|----------------|
| Managing Partner | Executive | Senior | Cross-departmental visibility (read), strategic reports | **High** |
| Senior Professional | Professional Svc | Senior | Client project shares, billing visibility | Medium |
| Junior Professional | Professional Svc | Mid-Level | Limited project access, supervised work | Low-Medium |
| Admin Assistant | HR | Support | Shared templates, HR forms (read-only), scheduling | Low |
| Finance Staff | Finance | Entry-Mid | Finance shares, invoice processing | **High** |
| HR Staff | HR | Entry-Mid | HR shares (excluding personnel files) | **High** |
| IT Administrator | IT | Admin | Infrastructure access, requires checkout for sensitive ops | **Critical** |
| Intern | Varies | Entry | Minimal access, tightly scoped to training | Low |

#### 4.0.5 Active Directory Organizational Unit Mapping

**Domain:** `smboffice.local`

**OU Structure Derived from Org Chart:**

```
smboffice.local
├── OU=Users
│   ├── OU=Executive
│   │   ├── CN=Managing Partner
│   │   ├── CN=Finance Manager
│   │   ├── CN=HR Manager
│   │   └── CN=Project Manager
│   ├── OU=Finance
│   │   ├── OU=FinanceManagers (Finance Manager)
│   │   ├── OU=FinanceStaff (Senior/Junior Accountants)
│   │   └── OU=FinanceInterns
│   ├── OU=HR
│   │   ├── OU=HRManagers (HR Manager)
│   │   ├── OU=HRStaff (HR Generalist, Admin Assistant)
│   │   └── OU=HRInterns
│   ├── OU=ProfessionalServices
│   │   ├── OU=SeniorProfessionals
│   │   ├── OU=JuniorProfessionals
│   │   └── OU=ProjectInterns
│   └── OU=IT
│       ├── OU=ITAdmins
│       └── OU=ITAutomation
├── OU=Groups
│   ├── OU=Executive
│   ├── OU=Finance
│   ├── OU=HR
│   ├── OU=ProfessionalServices
│   ├── OU=SharedServices
│   └── OU=Infrastructure
└── OU=Computers
    ├── OU=Workstations
    │   ├── OU=Executive
    │   ├── OU=Finance
    │   ├── OU=HR
    │   └── OU=ProfessionalServices
    └── OU=Servers
```

#### 4.0.6 Security Group Mapping

**Global Groups (GG-) by Department:**

| Department | Global Group | Nested In | Purpose |
|------------|--------------|-----------|---------|
| Executive | `GG-Executive` | Various read-only groups | Executive cross-department visibility |
| Finance | `GG-Finance` | `SG-Finance-Files-RW` | Finance department access |
| Finance | `GG-Finance-Managers` | `GG-Finance`, `SG-Client-Billing` | Finance manager elevated access |
| HR | `GG-HR-Department` | `SG-HR-Files-RW` | HR department access |
| HR | `GG-HR-Managers` | `GG-HR-Department` | HR manager personnel file access |
| HR | `GG-HR-Assistants` | Shared resources | Admin Assistant multi-dept support |
| Professional | `GG-Prof-Senior` | Project shares | Senior consultant access |
| Professional | `GG-Prof-Junior` | Limited project shares | Junior consultant access |
| IT | `GG-IT-Admins` | Infrastructure groups | IT administrative access |
| All | `GG-AllStaff` | Company-wide resources | Company-wide shared resources |

**Domain Local Groups (SG-) for Resources:**

| Resource Group | Purpose | Members |
|----------------|---------|---------|
| `SG-Finance-Files-RW` | Finance share access | `GG-Finance` |
| `SG-HR-Files-RW` | HR share access | `GG-HR-Department` |
| `SG-Policy-Docs` | Company policy documents | `GG-AllStaff`, `GG-Executive` |
| `SG-Onboarding-Access` | Onboarding materials | `GG-HR-Department`, `GG-IT-Admins` |
| `SG-Templates-Write` | Shared templates | `GG-HR-Assistants`, `GG-AllStaff` |

#### 4.0.7 Reporting Hierarchy and Approval Workflows

**Financial Approvals:**
- Invoice approvals: Finance Manager → Managing Partner (over $10k)
- Budget changes: Finance Manager → Managing Partner
- Payroll changes: Finance Manager (with HR Manager coordination)

**HR Approvals:**
- New hires: HR Manager → Managing Partner
- Terminations: HR Manager → Managing Partner (notify Finance)
- Policy changes: HR Manager → Managing Partner

**IT Changes:**
- Infrastructure changes: IT Admin → Project Manager → Managing Partner
- User account changes: Requestor → HR Manager → IT Admin (via onboarding workflow)

#### 4.0.8 Alignment with Use Cases

Each organizational role maps to documented use cases:

| Role | Use Case Document | Security Profile | Workstation |
|------|-------------------|------------------|-------------|
| Finance Manager | `finance-manager-use-case.md` | **High** - SOX controls | `finance-ws01` |
| HR Manager | `hr-manager-use-case.md` | **High** - HIPAA-style controls | `hr-ws01` |
| Admin Assistant | `admin-assistant-use-case.md` | Medium - Multi-dept support | `assist-ws01` |
| Senior Professional | `senior-professional-use-case.md` | Medium - Client data | `prof-ws01` |
| Junior Professional | `junior-professional-use-case.md` | Low-Medium - Supervised | `prof-ws02` |
| Managing Partner | `managing-partner-use-case.md` | **Critical** - Full visibility | `exec-ws01` |
| IT Administrator | `it-admin-use-case.md` | **Critical** - Infrastructure | `it-ws01` |
| Intern/Temp | `intern-temp-use-case.md` | Low - Restricted training | `temp-ws##` |

---

### 4.1 System Overview

#### 4.1.1 Infrastructure Components

The SMB Office IT infrastructure consists of the following core components:

| Component | Hostname(s) | Role | OS | Priority |
|-----------|-------------|------|-----|----------|
| Domain Controller | `dc01.smboffice.local` | Samba AD, DNS, LDAP | Oracle Linux 9 / Ubuntu 22.04 | **CRITICAL** |
| File Server | `files01.smboffice.local` | Samba file shares, ACLs, audit | Oracle Linux 9 / Ubuntu 22.04 | **CRITICAL** |
| Print Server | `print01.smboffice.local` | CUPS, secure print | Ubuntu 22.04 | **HIGH** |
| Log Server | `log01.smboffice.local` | Syslog, audit aggregation | Ubuntu 22.04 | **HIGH** |
| HR App Server | `hrapp01.smboffice.local` | HR self-service portal | Ubuntu 22.04 | **HIGH** |
| Finance Workstations | `finance-ws01`, `finance-ws02` | Finance user endpoints | Ubuntu Desktop 22.04 | **HIGH** |
| HR Workstations | `hr-ws01`, `hr-ws02` | HR user endpoints | Ubuntu Desktop 22.04 | **HIGH** |
| Admin Workstations | `assist-ws01`, `assist-ws02` | Admin Assistant endpoints | Ubuntu Desktop 22.04 | **MEDIUM** |

#### 4.1.2 System Capacity Planning

| Resource | Specification | Notes |
|----------|--------------|-------|
| Total VMs | 11-15 | Depends on departmental expansion |
| Storage (File Server) | 500GB minimum | With expansion capacity |
| Network Throughput | 1Gbps | Internal VLAN traffic |
| Backup Storage | 1TB | 7-year retention for compliance |

---

### 4.2 Infrastructure Architecture

#### 4.2.1 Active Directory Structure

**Domain:** `smboffice.local`
**Forest Functional Level:** Samba AD equivalent (Windows Server 2016+ compatible)

**OU Hierarchy:**

```
smboffice.local
├── OU=Users
│   ├── OU=Finance
│   │   ├── OU=FinanceManagers
│   │   └── OU=FinanceStaff
│   ├── OU=HR
│   │   ├── OU=HRManagers
│   │   └── OU=HRStaff
│   ├── OU=SharedServices
│   │   └── OU=AdminAssistants
│   └── OU=ProfessionalServices
│       ├── OU=Partners
│       ├── OU=SeniorConsultants
│       └── OU=Consultants
├── OU=Groups
│   ├── OU=Finance
│   ├── OU=HR
│   ├── OU=SharedServices
│   └── OU=Infrastructure
├── OU=Computers
│   ├── OU=Workstations
│   │   ├── OU=Finance
│   │   ├── OU=HR
│   │   └── OU=SharedServices
│   └── OU=Servers
└── OU=ServiceAccounts
```

#### 4.2.2 File Server Architecture

**Source Documents:**
- `INFRA-FS-STRUCTURE-001` (file-share-structure.md)
- Role requirements documents (Finance, HR, Admin Assistant)

**Server:** `files01.smboffice.local`
**Storage Backend:** `/srv/shares` (primary path), symlinked to `/srv/samba/shares` (LUKS encrypted volume)
**File System:** ext4 or XFS with ACL support
**Share Management:** Samba 4.x with VFS modules (acl_xattr, full_audit)

##### 4.2.2.1 Share Design Principles

The file share structure follows these key principles:

1. **Department-Based Organization:** Shares organized by department and function
2. **AD Group Access Control:** All access controlled via AD Security Groups (no individual user permissions)
3. **Subfolder Granularity:** Restricted folders clearly documented with specific group access
4. **Access-Based Enumeration:** Users only see shares/folders they have permission to access
5. **Audit Logging:** Sensitive shares (Finance, HR) have full audit logging via VFS modules
6. **Naming Consistency:** Standardized naming conventions for shares and folders

##### 4.2.2.2 Top-Level Directory Structure

**Physical Path:** `/srv/shares/` (or `/srv/samba/shares/`)

```text
/srv/shares/
├── Common/                    # Company-wide shared resources
│   ├── CompanyDocs/          # General company documentation
│   └── Templates/            # Shared document templates
├── HR/                        # Human Resources department
│   ├── Personnel/            # Employee records (HR Managers ONLY)
│   ├── Onboarding/           # New hire materials (HR + IT)
│   ├── Policies/             # HR policies and handbooks
│   ├── Forms/
│   │   └── Templates/        # HR form templates (Admin Assistant read access)
│   ├── Benefits/             # Benefits information
│   └── Compliance/           # I-9, EEO, safety training
├── Finance/                   # Finance department
│   ├── Payroll/              # Payroll data (Finance RW, HR read-only)
│   ├── Reporting/            # Financial reports
│   ├── Invoices/             # Client invoices (audit target)
│   ├── Budgets/              # Budget documents (audit target)
│   └── Exports/              # Sensitive data exports (audit target)
├── Professional/              # Professional Services department
│   ├── Clients/              # Client project folders
│   └── Projects/             # Internal project data
├── IT/                        # IT department
│   ├── Installers/           # Software installation packages
│   ├── Configs/              # Configuration backups
│   └── Documentation/        # IT documentation
├── Temp/                      # Temporary uploads
│   └── Uploads/              # Auto-purged every 24 hours
├── Clients/                   # Client-specific data (cross-department)
│   └── Billing/              # Client billing records (Finance Managers)
├── Company/                   # Company-wide resources
│   └── Policies/             # Company policies (HR RW, others read)
└── Users/                     # User home directories
    └── <username>/           # Individual user storage
```

##### 4.2.2.3 Share Configuration Table

| Share Name | Physical Path | AD Group | Access Level | Browseable | Audit Level | Notes |
|------------|---------------|----------|--------------|------------|-------------|-------|
| `common` | `/srv/shares/Common/` | `GG-AllStaff` | Read/Write | Yes | Standard | Company-wide templates and docs |
| `hr` | `/srv/shares/HR/` | `GG-HR-Department` | Full | **No** | **Full** | HR department files (hidden) |
| `hr-personnel` | `/srv/shares/HR/Personnel/` | `SG-HR-Managers` | Full | **No** | **Full** | Personnel records (managers only) |
| `finance` | `/srv/shares/Finance/` | `GG-Finance` | Full | **No** | **Full** | Finance department files (hidden) |
| `finance-payroll` | `/srv/shares/Finance/Payroll/` | `GG-Finance`, `SG-Payroll-ReadOnly` | Finance: RW, HR: RO | **No** | **Full** | Payroll data (separation of duties) |
| `professional` | `/srv/shares/Professional/` | `GG-Prof-Senior`, `GG-Prof-Junior` | Tiered | Yes | Standard | Professional services projects |
| `it` | `/srv/shares/IT/` | `GG-IT-Admins` | Full | **No** | Standard | IT administrative files |
| `temp` | `/srv/shares/Temp/` | `GG-AllStaff` | Write-Only | Yes | Standard | Temporary uploads (auto-purge 24h) |
| `clients` | `/srv/shares/Clients/` | Various | Varies | **No** | **Full** | Client-specific data |
| `company-policies` | `/srv/shares/Company/Policies/` | `SG-Policy-Docs` | HR/Mgmt: RW, Others: RO | Yes | Write | Company policies |
| `users` | `/srv/shares/Users/` | Individual users | Per-user | **No** | Standard | User home directories |

**Key:**
- **RW** = Read/Write
- **RO** = Read-Only
- **Full** = Complete access (read, write, delete, modify ACLs)
- **Standard** = Basic file access logging
- **Full** = Comprehensive audit logging (VFS full_audit module)

##### 4.2.2.4 Naming Conventions

**Top-Level Shares:**
- Lowercase, department-aligned (e.g., `finance`, `hr`, `professional`)
- Hyphenated for multi-word (e.g., `company-policies`)

**Subfolders:**
- CamelCase preferred (e.g., `CompanyDocs`, `OnboardingMaterials`)
- Underscores allowed for clarity (e.g., `Payroll_Reports`, `HR_Policies`)
- **Avoid spaces** in directory names to prevent escaping issues

**Client Project Folders:**
- Format: `clientname_projectname_YYYYMM`
- Example: `acmecorp_redesign_202512`
- Keeps chronological ordering and clear identification

**Employee Personnel Folders:**
- Format: `lastname_firstname` or `username`
- Example: `adams_jennifer` or `jennifer.adams`
- Nested under `/HR/Personnel/active-employees/` or `/HR/Personnel/terminated-employees/`

##### 4.2.2.5 Access Control and Ownership

**Access Control Method:**
- **Primary:** AD Security Groups (LDAP/Kerberos integration)
- **Secondary:** POSIX ACLs for filesystem-level enforcement
- **Tertiary:** Samba share-level permissions (`valid users`, `read list`, `write list`)

**No Individual User Permissions:**
- All access granted via group membership
- Simplifies management and audit trail
- Changes made at group level only

**Folder Ownership Standards:**
- **Owner:** `root` (system)
- **Group Owner:** Matching AD group (e.g., `GG-Finance` for finance folders)
- **Base Permissions:** `770` (owner/group full, others none) or more restrictive
- **ACLs Applied:** Extended POSIX ACLs via `setfacl` for fine-grained control

**Example ACL Configuration:**

```bash
# Finance share - Full access for Finance group
setfacl -R -m g:GG-Finance:rwx /srv/shares/Finance
setfacl -R -d -m g:GG-Finance:rwx /srv/shares/Finance

# HR Personnel - Managers only
setfacl -R -m g:SG-HR-Managers:rwx /srv/shares/HR/Personnel
setfacl -R -d -m g:SG-HR-Managers:rwx /srv/shares/HR/Personnel
setfacl -R -m g:GG-HR-Department:--- /srv/shares/HR/Personnel  # Explicit deny

# Payroll - Finance RW, HR RO (separation of duties)
setfacl -R -m g:GG-Finance:rwx /srv/shares/Finance/Payroll
setfacl -R -m g:SG-Payroll-ReadOnly:r-x /srv/shares/Finance/Payroll
setfacl -R -d -m g:GG-Finance:rwx /srv/shares/Finance/Payroll
setfacl -R -d -m g:SG-Payroll-ReadOnly:r-x /srv/shares/Finance/Payroll
```

##### 4.2.2.6 Security and Compliance Notes

**Sensitive Folders with Enhanced Controls:**

| Folder | Security Measures | Compliance |
|--------|------------------|------------|
| `/HR/Personnel` | - HR Managers only<br>- Full audit logging<br>- Separate backup<br>- Monthly access review | HIPAA-style (employee health data) |
| `/Finance/Payroll` | - Full audit logging<br>- Separation of duties (HR read-only)<br>- Backup encryption<br>- Quarterly access review | SOX (financial data) |
| `/Finance/Invoices` | - Full audit logging<br>- Manager approval for exports<br>- Backup retention (7 years) | SOX |
| `/Finance/Budgets` | - Full audit logging<br>- Version control<br>- Change tracking | SOX |

**Automated Maintenance:**

```bash
# Temp folder auto-purge (cron job)
0 2 * * * find /srv/shares/Temp/Uploads -type f -mtime +1 -delete

# Access review reminders (quarterly)
0 9 1 */3 * /usr/local/bin/generate-access-review-report.sh

# Backup verification (weekly)
0 3 * * 0 /usr/local/bin/verify-share-backups.sh
```

##### 4.2.2.7 Samba Share Configuration Examples

**Common Share (Company-Wide):**

```ini
[common]
path = /srv/shares/Common
comment = Company-wide shared templates and documents
valid users = @GG-AllStaff
read list = @GG-AllStaff
write list = @GG-AllStaff
create mask = 0664
directory mask = 0775
vfs objects = acl_xattr
browseable = yes
```

**Finance Share (Department-Specific, Full Audit):**

```ini
[finance]
path = /srv/shares/Finance
comment = Finance Department - Restricted Access
valid users = @GG-Finance
read list = @GG-Finance
write list = @GG-Finance
create mask = 0660
directory mask = 0770
vfs objects = acl_xattr full_audit
full_audit:prefix = %u|%I|%m|%S
full_audit:success = mkdir rmdir write unlink rename
full_audit:failure = all
full_audit:facility = local5
full_audit:priority = notice
browseable = no
```

**HR Personnel Share (Managers Only, Full Audit):**

```ini
[hr-personnel]
path = /srv/shares/HR/Personnel
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

**Temp Share (Write-Only Upload):**

```ini
[temp]
path = /srv/shares/Temp
comment = Temporary uploads - Auto-purged every 24 hours
valid users = @GG-AllStaff
write list = @GG-AllStaff
read list = @GG-IT-Admins
create mask = 0666
directory mask = 0777
browseable = yes
guest ok = no
```

##### 4.2.2.8 Integration with Organizational Structure

**Department-to-Share Mapping:**

| Department | Primary Share | Secondary Shares | Notes |
|------------|--------------|------------------|-------|
| Executive | Read access to most | `common`, departmental read-only | Strategic visibility |
| Finance | `finance` | `clients` (billing), `hr` (payroll read) | Separation of duties with HR |
| HR | `hr`, `hr-personnel` | `finance` (payroll read), `company-policies` | Separation of duties with Finance |
| Professional Services | `professional` | `clients`, `common` | Client project work |
| Admin Assistant | `common`, `company-policies` | `hr` (forms read-only) | Multi-department support |
| IT | `it` | All (read-only for audit) | Infrastructure management |

##### 4.2.2.9 Future Enhancements

**Planned Additions:**
- Versioning integration (e.g., shadow copies for Finance/HR)
- Quota management per department
- DFS namespace for distributed file access
- Offline file sync for remote workers
- Encryption-at-rest validation and key management

---

#### 4.2.3 Group Policy Configuration

**Source Document:** `POLICY-GPO-BASELINE-001` (group-policy-baseline.md)

Group Policy Objects (GPOs) are implemented via Samba Active Directory to standardize security configuration, desktop experience, and system behavior across all domain-joined workstations.

##### 4.2.3.1 GPO Strategy

- **Default Domain Policy** applied globally for security and password policy
- **OU-specific GPOs** for department-specific requirements (HR, Finance, Professional Services)
- **Group-filtered GPOs** for role-based configuration (e.g., `GG-HR-Staff`)
- **Version Control:** All GPO configurations stored in encrypted repository
- **Testing:** All GPO changes tested in lab environment before production deployment

##### 4.2.3.2 Default Domain Policy

Applied to all domain users and computers:

| Setting | Value | Purpose |
|---------|-------|---------|
| Minimum password length | 12 characters | Password complexity baseline |
| Maximum password age | 90 days | Regular password rotation |
| Account lockout threshold | 5 failed attempts | Brute-force protection |
| Lockout duration | 15 minutes | Auto-unlock after lockout |
| Enforce password history | 10 previous passwords | Prevent password reuse |
| Require complex passwords | Yes | Mixed character requirements |
| Allow log on locally | Domain Users, GG-IT-Admins | Workstation access control |
| Audit logon events | Success and failure | Security event logging |
| Time synchronization policy | Enabled (via NTP) | Ensure accurate timestamps |

##### 4.2.3.3 Department-Specific GPOs

**HR Department (OU=HR):**
- **Home Drive Mapping:** `\\files01\hr\$USERNAME` (H: drive)
- **Desktop Wallpaper:** HR branding and compliance reminders
- **Shared Drive Access:** Read/Write for `GG-HR-Staff` only
- **USB Device Control:** Disabled (per security policy)
- **Screensaver Timeout:** 10 minutes with password lock

**Finance Department (OU=Finance):**
- **Home Drive Mapping:** `\\files01\finance\$USERNAME` (H: drive)
- **Shared Drive:** Auto-mount finance reports share (F: drive)
- **Enhanced Logging:** auditd + GPO event logging enabled
- **AppLocker:** Disable non-approved applications
- **USB Device Control:** Completely disabled (highest security)
- **Password Requirements:** Enhanced (14+ characters, MFA required)

**Professional Services (OU=Professional):**
- **Shared Templates:** Auto-loaded from `\\files01\templates`
- **Sudo Access:** Via AD group `GG-Prof-Sudo` (Linux systems)
- **Project Share Access:** Based on project assignment groups
- **Printer Access:** Department-specific printer auto-installation

##### 4.2.3.4 Security Settings (GPO-Enforced)

| Feature | Status | Implementation | Notes |
|---------|--------|----------------|-------|
| Interactive logon message | ✅ Enabled | Legal notice banner | Displayed to all users at login |
| USB storage blocking | ✅ Enabled | udev rules + GPO | Exception: `GG-Exec`, IT Admins |
| Remote desktop restrictions | ✅ Enabled | RDP access policy | Allowed only for IT/Managers |
| Disable guest accounts | ✅ Enabled | Domain policy | No guest access permitted |
| Require screensaver lock | ✅ Enabled | 10-minute timeout | Auto-lock after idle period |
| Samba log level | 3 | smb.conf + GPO | Audit domain logons |
| BitLocker enforcement | ✅ Enabled | Finance/HR workstations | Full disk encryption required |

##### 4.2.3.5 Login & UX Settings

**Login Scripts:**
- **Department Share Mounting:** Automatic at logon based on AD group membership
- **Printer Installation:** Auto-install department printers via GPO
- **Template Preloading:** Office templates loaded per department

**Desktop Configuration:**
- **Login Banner:** Company branding and acceptable use policy
- **Desktop Shortcuts:** Shared drives, company handbook, IT support portal
- **Folder Redirection:** Documents folder redirected to user home directory on `files01`

##### 4.2.3.6 USB and Device Control

| Group/Role | USB Access | Control Method | Notes |
|------------|------------|----------------|-------|
| `GG-Exec`, IT Admins | ✅ Full Access | Exemption via GPO filter | Executives and IT only |
| HR/Finance Staff | ❌ Blocked | udev rules + GPO | High-security departments |
| Interns/Temps | ❌ Blocked | GPO + OU policy | No removable media access |
| Professional Services | ⚠️ Conditional | Manager approval required | Case-by-case via ticket |

**Technical Implementation:**
- **Windows Workstations:** GPO device installation restrictions
- **Linux Workstations:** udev rules + SSSD integration
- **Enforcement:** Monitored via auditd logs

##### 4.2.3.7 GPO Deployment Plan

| Phase | Task | Tool | Owner | Status |
|-------|------|------|-------|--------|
| 1 | Define GPO structure in Samba AD | `samba-tool gpo` | IT AD Architect | Planned |
| 2 | Map GPOs to OUs and security groups | GPO editor / ADSI | IT Security Analyst | Planned |
| 3 | Test GPOs in lab environment | Virtual DCs | Linux Admin | Planned |
| 4 | Deploy to production lab | GPO replication | IT AD Architect | Planned |
| 5 | Monitor with audit logs | auditd + Samba logs | IT Security Analyst | Planned |
| 6 | Version control GPO changes | Git-crypt repository | Project Manager | Planned |

---

### 4.3 Security and Audit Requirements

#### 4.3.1 Audit Logging Framework

**Source Document:** `SECURITY-AUDITD-FIN-001` (auditd-finance-rules.md)

##### 4.3.1.1 Finance Department Audit Rules

**Implementation Location:** `/etc/audit/rules.d/finance.rules` on `files01.smboffice.local`

**Directory Watch Rules:**

```bash
# Finance Share Directory Access
-w /srv/samba/shares/finance/invoices     -p rwa -k finance_invoices
-w /srv/samba/shares/finance/payroll      -p rwa -k finance_payroll
-w /srv/samba/shares/finance/budgets      -p rwa -k finance_budgets
-w /srv/samba/shares/finance/exports      -p rwa -k finance_exports
```

**Purpose:**
- Monitor all read, write, and attribute changes to Finance file shares
- Track invoice access for financial reporting compliance
- Monitor payroll report access (cross-department with HR)
- Watch budget documents for unauthorized changes
- Track sensitive Excel exports that may contain financial data

**Audit Keys:**

| Key | Description | Alert Threshold |
|-----|-------------|-----------------|
| `finance_invoices` | Invoice reads/writes | Unauthorized group access |
| `finance_payroll` | Payroll report access | Non-Finance/HR access |
| `finance_budgets` | Budget document changes | After-hours modifications |
| `finance_exports` | Sensitive data exports | Any access by non-managers |

##### 4.3.1.2 Executable Monitoring (Finance)

**Data Transfer Tool Monitoring:**

```bash
# Monitor Data Transfer Utilities
-a always,exit -F path=/usr/bin/scp -F perm=x -F auid>=1000 -F auid!=unset -k finance_tools
-a always,exit -F path=/usr/bin/rsync -F perm=x -F auid>=1000 -F auid!=unset -k finance_tools
-a always,exit -F path=/bin/cp    -F perm=x -F auid>=1000 -F auid!=unset -k finance_tools
```

**Purpose:**
- Track use of copy/transfer tools by domain users
- Detect potential data exfiltration attempts
- Ignore system/background tasks (UID < 1000)
- Alert on use of `scp` by non-technical roles

##### 4.3.1.3 User-Level Audit Rules (Finance)

**Finance Manager Login Tracking:**

```bash
# Track login events for finance manager
-a always,exit -F arch=b64 -S execve -F uid=10010 -k finance_login
```

**Notes:**
- Replace `10010` with actual UID of Finance Manager (from `id finance.mgr`)
- Tracks all executed commands by Finance Manager
- Supports after-hours access detection

**PAM TTY Auditing (Optional Enhancement):**

```bash
session required pam_tty_audit.so enable=always
```

##### 4.3.1.4 Log Retention and Rotation

**Configuration:**

| Parameter | Value | Notes |
|-----------|-------|-------|
| Log Location | `/var/log/audit/audit.log` | Local storage on `files01` |
| Rotation Method | `logrotate.d/audit` | Weekly rotation |
| Local Retention | 90 days | Disk storage |
| Remote Forwarding | `log01.smboffice.local` | Via rsyslog |
| Archive Retention | 7 years | SOX compliance requirement |
| Log Formats | RAW + JSON | JSON for SIEM/Splunk-style search |

**Logrotate Configuration:**

```bash
/var/log/audit/audit.log {
    weekly
    rotate 12
    compress
    delaycompress
    notifempty
    create 0600 root root
    postrotate
        /sbin/service auditd restart > /dev/null 2>&1 || true
    endscript
}
```

##### 4.3.1.5 Alerting and Incident Escalation

**Alert Triggers:**

| Event | Condition | Response |
|-------|-----------|----------|
| Unauthorized Payroll Access | Access to payroll folder by non-Finance/HR group | Immediate alert to Security Analyst |
| Data Transfer Tool Usage | Use of `scp` by non-technical roles | Email alert, log review |
| After-Hours File Access | File access outside business hours (20:00–06:00) | Next-day review by Security Analyst |
| Failed Access Attempts | 5+ failed attempts to Finance shares | Lock account, alert Security Analyst |

**Escalation Path:**

1. **Level 1:** Automated alert generated (Email/Syslog to `log01`)
2. **Level 2:** Reviewed by **IT Security Analyst** (within 4 business hours)
3. **Level 3:** Escalated to **Finance Manager** and **Managing Partner** (if incident confirmed)

**Ansible Implementation:**
- Deploy alerting scripts to monitor audit logs
- Configure email notifications via `postfix` or `sendmail`
- Integrate with rsyslog for centralized monitoring

#### 4.3.2 HR Department Audit Rules

**Source Document:** `SECURITY-AUDITD-HR-001` (auditd-hr-rules.md)

This section defines auditd monitoring rules for HR-related data directories to track access, changes, and deletion of employee records, evaluations, and onboarding documents.

##### 4.3.2.1 HR Audit Scope

Monitoring applies to:
- HR Samba share: `/srv/shares/HR/`
- Employee records (PDFs, docs)
- Onboarding checklists
- Disciplinary or performance evaluations
- Access by users in `GG-HR-*` groups or privileged administrators

##### 4.3.2.2 Targeted HR Paths

| Target Path | Description |
|-------------|-------------|
| `/srv/shares/HR/` | Root of HR file share |
| `/srv/shares/HR/Onboarding/` | New hire and intern documents |
| `/srv/shares/HR/Evaluations/` | Performance review records |
| `/srv/shares/HR/Personnel/` | Employee file archive |

##### 4.3.2.3 HR Audit Rule Examples

**Implementation Location:** `/etc/audit/rules.d/hr.rules` on `files01.smboffice.local`

**Access Tracking:**

```bash
# HR Share Directory Access
-w /srv/shares/HR/ -p rwa -k hr_access
-w /srv/shares/HR/Personnel/ -p rwa -k hr_personnel
-w /srv/shares/HR/Evaluations/ -p rwa -k hr_eval
-w /srv/shares/HR/Onboarding/ -p rwa -k hr_onboarding
```

**File Deletion and Permission Changes:**

```bash
# Track file deletions in HR directories
-a always,exit -F arch=b64 -S unlink -F dir=/srv/shares/HR/ -F auid>=1000 -F auid!=4294967295 -k hr_delete
-a always,exit -F arch=b64 -S unlinkat -F dir=/srv/shares/HR/ -F auid>=1000 -F auid!=4294967295 -k hr_delete

# Track permission changes
-a always,exit -F arch=b64 -S chmod -F dir=/srv/shares/HR/ -F auid>=1000 -F auid!=4294967295 -k hr_chmod
-a always,exit -F arch=b64 -S fchmod -F dir=/srv/shares/HR/ -F auid>=1000 -F auid!=4294967295 -k hr_chmod
-a always,exit -F arch=b64 -S fchmodat -F dir=/srv/shares/HR/ -F auid>=1000 -F auid!=4294967295 -k hr_chmod

# Track ownership changes
-a always,exit -F arch=b64 -S chown -F dir=/srv/shares/HR/ -F auid>=1000 -F auid!=4294967295 -k hr_chown
-a always,exit -F arch=b64 -S fchown -F dir=/srv/shares/HR/ -F auid>=1000 -F auid!=4294967295 -k hr_chown
-a always,exit -F arch=b64 -S lchown -F dir=/srv/shares/HR/ -F auid>=1000 -F auid!=4294967295 -k hr_chown
```

> 🔐 These rules apply to **all users** with UID ≥1000, excluding system accounts

##### 4.3.2.4 HR Log Reporting and Review

| Action | Frequency | Responsible Agent |
|--------|-----------|-------------------|
| `ausearch -k hr_access` | Weekly | IT Security Analyst |
| Monthly audit log export | Monthly | Linux Admin |
| HR Data Access Report | Quarterly | HR Manager, IT Security |

**Common Commands:**

```bash
# Search HR access events
ausearch -k hr_access

# Generate file access report
aureport --file --summary | grep HR

# Review deletion events
ausearch -k hr_delete | aureport -f

# Check permission changes
ausearch -k hr_chmod -ts recent
```

##### 4.3.2.5 Optional Alerts and Integrations

- **auditd → rsyslog → Email alert** for unauthorized HR folder access
- Integration with `fail2ban` or `Wazuh` if SIEM implemented
- **Threshold alerting:** More than 5 file changes in HR folders within 5 minutes triggers alert

##### 4.3.2.6 HR Audit Maintenance Tasks

| Task | Interval | Responsible |
|------|----------|-------------|
| Verify HR audit rules loaded at boot | Monthly | Linux Admin |
| Test audit rule coverage | Quarterly | IT Security |
| Rotate HR logs via logrotate | Weekly | System Cron |
| Purge HR logs older than 180 days | Monthly | System Admin |

---

#### 4.3.3 General Security Controls

##### 4.3.3.1 SELinux Enforcement

**Policy:** SELinux must be set to **enforcing** mode on all servers

**Implementation:**

```bash
# Set SELinux to enforcing
setenforce 1

# Make permanent
sed -i 's/^SELINUX=.*/SELINUX=enforcing/' /etc/selinux/config

# Apply Samba contexts
semanage fcontext -a -t samba_share_t "/srv/samba/shares(/.*)?"
restorecon -Rv /srv/samba/shares
```

##### 4.3.3.2 Firewall Rules

**Server-Level Firewall (firewalld):**

```bash
# File Server (files01)
firewall-cmd --permanent --add-service=samba
firewall-cmd --permanent --add-port=445/tcp
firewall-cmd --permanent --add-port=139/tcp
firewall-cmd --reload

# Restrict to internal VLANs only
firewall-cmd --permanent --zone=trusted --add-source=10.10.0.0/16
```

##### 4.3.3.3 USB Storage Restrictions

**Policy:** USB storage is **completely disabled** on Finance and HR workstations

**Implementation via udev rules:**

```bash
# /etc/udev/rules.d/99-usb-storage-deny.rules
SUBSYSTEM=="usb", ATTRS{bDeviceClass}=="08", ENV{UDISKS_IGNORE}="1"
SUBSYSTEM=="block", ATTRS{removable}=="1", ENV{UDISKS_IGNORE}="1"
```

**Kernel Module Blacklist:**

```bash
# /etc/modprobe.d/usb-deny.conf
blacklist usb-storage
blacklist uas
```

---

#### 4.3.4 Audit Log Policy and Retention

**Source Document:** `POLICY-AUDIT-LOG-001` (audit-log-policy.md)

This section defines the collection, retention, protection, and review requirements for system and application audit logs used to support forensic investigation, compliance, and operational security.

##### 4.3.4.1 Log Types and Sources

All systems must generate logs related to security, authentication, access, and system events:

| Log Source | Purpose | Tool/Path | Criticality |
|------------|---------|-----------|-------------|
| `auditd` | Security and file access | `/var/log/audit/` | **CRITICAL** |
| `rsyslog/syslog` | System events | `/var/log/syslog` | HIGH |
| `samba` | AD and file access | `/var/log/samba/` | **CRITICAL** |
| `cups` | Print job tracking | `/var/log/cups/` | MEDIUM |
| `sshd` | Remote access events | `/var/log/auth.log` | **CRITICAL** |
| `ansible` | Automation run history | `/var/log/ansible/` | HIGH |
| Application Logs | Custom apps (as required) | App-defined locations | VARIES |

##### 4.3.4.2 Log Retention Requirements

| Log Type | Retention Period | Rotation Tool | Archive Location |
|----------|------------------|---------------|------------------|
| `auditd` | 180 days | `logrotate.d` | `/var/log/archive/` |
| `syslog` | 90 days | `logrotate.d` | `/var/log/archive/` |
| Samba & CUPS | 90 days | `logrotate.d` | `/var/log/archive/` |
| SSHD | 180 days | `logrotate.d` | `/var/log/archive/` |
| Ansible Runs | 60 days | Custom rotation | `/var/log/ansible/archive/` |

**Implementation Details:**
- Compressed archives stored under `/var/log/archive/`
- Retention automatically enforced via cron and logrotate
- Backups of logs included in weekly backup plans
- Log storage monitored to prevent disk space exhaustion

##### 4.3.4.3 Log Access and Protection

- Logs are **read-only** for non-admin users
- **Authorized Groups:**
  - `GG-Security` - IT Security Analyst access
  - `GG-Audit` - Project Doc Auditor access
  - `GG-IT-Admins` - Infrastructure administration
- All access to logs is **logged and reviewed**
- Logs must be **excluded from user-writable partitions**
- Logs must **not be stored on removable devices**
- Logs must **not be modified or deleted** outside of automated retention policies

##### 4.3.4.4 Log Time Synchronization

- All systems **time-synchronized using NTP**
- **UTC timestamps** used for all log entries
- NTP server: `infra01.smboffice.local` (internal)
- External NTP fallback: `pool.ntp.org` (if external access available)

##### 4.3.4.5 Log Review and Monitoring Schedule

| Review Task | Frequency | Reviewer | Tool |
|-------------|-----------|----------|------|
| Auditd rule hits (`ausearch`) | Weekly | IT Security Analyst | `ausearch`, custom scripts |
| Log space usage | Weekly | Linux Admin | `df`, monitoring dashboard |
| Access to audit logs | Monthly | IT Security Analyst | Samba logs, auditd |
| Integrity check (via AIDE) | Weekly | Security + Auditor | AIDE file integrity monitoring |
| Failed login attempts | Daily | IT Security Analyst | Auth log analysis |

##### 4.3.4.6 Policy Enforcement

Violations of audit log policy may result in:
- Immediate revocation of access to log systems
- Incident response initiation
- Notification to HR (if employee-related)
- Project-wide security review

---

#### 4.3.5 Data Retention Policies

**Source Documents:**
- `POLICY-HR-RETENTION-001` (hr-data-retention-policy.md)
- `POLICY-FIN-DATA-ACCESS-001` (financial-data-access-guidelines.md)

##### 4.3.5.1 HR Data Retention Requirements

All HR-related data must be retained according to these schedules to reduce liability, meet legal expectations, and minimize exposure of personal employee information:

| Record Type | Retention Period | Final Action | Storage Location |
|-------------|------------------|--------------|------------------|
| Employment Agreements | 7 years post-exit | Secure Delete | `\\files01\hr\personnel` |
| Payroll Records | 7 years | Archival (Finance) | `\\files01\finance\payroll` |
| Resumes (Unhired) | 1 year | Auto-purge | `\\files01\hr\recruiting` |
| Interview Notes | 1 year | Secure Delete | `\\files01\hr\recruiting` |
| Performance Reviews | 3 years post-exit | Secure Archive | `\\files01\hr\reviews` |
| Disciplinary Records | 5 years post-exit | Secure Delete | `\\files01\hr\personnel` |
| Exit Interviews | 3 years | Secure Delete | `\\files01\hr\offboarding` |

##### 4.3.5.2 Secure Deletion Procedures

All deletions of sensitive HR and Finance data must use secure deletion methods:

**Linux/CLI Secure Delete:**
```bash
shred -u -n 3 -z <filename>
```

**Windows Domain Users:**
- Use "Secure Remove" shortcut (simulated via script)
- Automated via PowerShell or custom tool

**Audit Tracking:**
- auditd tracks all delete operations under `/srv/shares/department/hr/*` and `/srv/shares/department/finance/*`
- Monthly automated retention cleanup via cron

##### 4.3.5.3 Data Backup and Retention Policy

| Backup Type | Frequency | Retention | Location | Encryption |
|-------------|-----------|-----------|----------|------------|
| HR Shares | Daily | 30 Days | ZFS snapshots | ✅ Enabled |
| Offsite Archives | Weekly | 12 Weeks | Encrypted S3 / External | ✅ Required |
| Payroll Data | Daily | Per Finance Policy (7 years) | Finance share backup | ✅ Required |
| Audit Logs | Daily | 180 days | `/var/log/archive/` | ✅ Enabled |

**Backup Tool:** `restic` (encrypted backup vault)

**Access Restrictions:**
- Linux Admins (backup restoration only)
- HR Manager (approval required for restoration)
- Finance Manager (payroll data restoration approval)

##### 4.3.5.4 Roles and Responsibilities (Data Retention)

| Role | Responsibility |
|------|----------------|
| HR Manager | Enforces HR retention, signs off on deletions |
| Finance Manager | Enforces financial retention, coordinates with HR on payroll |
| IT Security Analyst | Audits logs and deletion compliance |
| Linux Admin | Maintains automated cleanup and backups |
| Project Doc Auditor | Ensures policy documents are aligned |

---

#### 4.3.6 File Permissions Audit Procedure

**Source Document:** `AUDIT-FILE-PERMISSIONS-001` (file-permissions-audit.md)

This section outlines the procedure for auditing file share permissions and ACL configurations across department shares to ensure proper role-based access enforcement.

##### 4.3.6.1 Audit Objectives

- Identify misconfigured permissions or overly broad access
- Confirm correct group ownership (e.g., `GG-Finance-Staff`)
- Verify ACL inheritance is properly applied
- Detect unauthorized access to high-sensitivity folders
- Log all manual changes made during audit

##### 4.3.6.2 Audit Tools

| Tool | Purpose |
|------|---------|
| `getfacl` | Linux filesystem ACL inspection |
| `samba-tool ntacl` | Samba share permission inspection |
| `auditctl` | Real-time monitoring |
| `find` + `stat` | Bulk permission checks |
| `csvkit` or spreadsheet | Reporting and analysis |

**Cross-Reference:** Manual validation against [access-control-matrix.md](../../simulated-client-project/security/access-control-matrix.md)

##### 4.3.6.3 Audit Targets

| Path | Classification | Audit Priority |
|------|----------------|----------------|
| `/srv/shares/finance/` | Confidential – payroll/reports | **HIGH** |
| `/srv/shares/hr/` | Confidential – employee records | **HIGH** |
| `/srv/shares/projects/` | Restricted – project team only | MEDIUM |
| `/srv/shares/public/` | Public – read-only default | LOW |
| `/srv/shares/assistants/` | Shared – support/admin-only | MEDIUM |

##### 4.3.6.4 Audit Procedure

**Step 1: Generate ACL Listings**

```bash
# Export ACLs for each sensitive share
getfacl -R /srv/shares/finance > /tmp/audit/finance-acl.txt
getfacl -R /srv/shares/hr > /tmp/audit/hr-acl.txt
getfacl -R /srv/shares/projects > /tmp/audit/projects-acl.txt
```

**Step 2: Identify High-Risk Permissions**

Look for:
- `other::rwx` (world access - **CRITICAL**)
- Groups outside expected role (e.g., `GG-IT-Admins` on HR shares)
- Manual ACL overrides or removed inheritance
- Executable permissions on non-script files

**Step 3: Check Samba Share Access**

```bash
# Verify Samba NT ACLs match POSIX ACLs
samba-tool ntacl get /srv/shares/finance
samba-tool ntacl get /srv/shares/hr
```

**Step 4: Correlate With Access Control Matrix**

Compare actual ACLs with documented access policies in:
- Section 4.4.4.3 (Financial Data Access Authorization)
- Section 4.3.7 (Access Control Matrix - below)
- File share permissions specification

##### 4.3.6.5 Findings Report Template

| Path | Issue | Severity | Fix Required | Assigned To | Notes |
|------|-------|----------|--------------|-------------|-------|
| `/srv/shares/finance` | `other::r--` allows world-read | **HIGH** | Yes | Linux Admin | Remove other perms |
| `/srv/shares/hr` | `GG-Exec` has write access | MEDIUM | Yes | AD Architect | Execs only need read |
| `/srv/shares/public` | No issues | LOW | No | N/A | Compliant |

##### 4.3.6.6 Corrective Actions

- Adjust ACLs using `setfacl` for immediate remediation
- If using Ansible: update ACL tasks in file server playbook
- Document all remediations in audit log with timestamp
- Notify affected department heads if group access changes impact users
- Re-run audit after 48 hours to verify corrections

##### 4.3.6.7 Audit Schedule

| Audit Type | Frequency | Owner |
|-----------|-----------|-------|
| Full permission audit | Quarterly | IT Security Analyst |
| Sensitive share spot check | Monthly | Linux Admin |
| Post-migration audit | After any AD or file server change | IT Security Analyst |

---

#### 4.3.7 Access Control Matrix (RBAC)

**Source Document:** `SECURITY-ACCESS-MATRIX-001` (access-control-matrix.md)

This matrix provides the definitive source for mapping user roles to access privileges across systems, shares, and applications, supporting RBAC enforcement and access audits.

##### 4.3.7.1 Role Definitions

| Role | Description | Security Level |
|------|-------------|----------------|
| Receptionist | Front-desk access, general office tools | LOW |
| Admin Assistant | Broad office access, but no HR/Finance personnel data | MEDIUM |
| Junior Professional | Entry-level contributor | LOW-MEDIUM |
| Senior Professional | Advanced contributor with project authority | MEDIUM |
| Intern / Temp | Time-limited access, minimal privileges | LOW |
| HR Manager | Access to HR documents and tools | **HIGH** |
| Finance Manager | Access to accounting systems and files | **HIGH** |
| IT Administrator | Full IT support and elevated permissions | **CRITICAL** |
| Managing Partner | Strategic access, not administrative | **CRITICAL** |

##### 4.3.7.2 File Share Access Matrix

| File Share Path | Read-Only Roles | Read-Write Roles | Owner Group |
|-----------------|-----------------|------------------|-------------|
| `\\files01\shared\company` | All staff | Admin Assistant, Sr. Professional, Execs | `SG-Company-Docs` |
| `\\files01\department\hr` | Execs, HR Manager | HR Manager | `GG-HR-Staff` |
| `\\files01\department\finance` | Execs, Finance Manager | Finance Manager | `GG-Finance-Staff` |
| `\\files01\projects\client-deliverables` | Sr. Prof., Jr. Prof. | Sr. Professional | `GG-Project-Staff` |
| `\\files01\admin\executive-reports` | Execs only | Managing Partner | `GG-Exec-Leadership` |
| `\\files01\interns\working` | Intern | Intern Supervisor | `GG-Interns` |

##### 4.3.7.3 System Access Matrix

| System/Workstation | Role Access | Access Level | Notes |
|--------------------|-------------|--------------|-------|
| `hr-ws01` | HR Manager | Full | Hardened workstation |
| `finance-ws01` | Finance Manager | Full | LUKS encrypted, MFA required |
| `admin-ws01` | Admin Assistant | Full | Standard security profile |
| `intern-ws01` | Intern / Temp | Full | Auto-disable after contract period |
| `exec-ws01` | Managing Partner | Full (isolated) | Enhanced encryption, air-gapped backups |
| `itadmin-ws01` | IT Administrator | Full Admin | Checkout required for sensitive ops |
| `files01`, `print01` | All users | Networked use | AD authentication required |
| `dc01`, `dc02` | IT Admin, AD Architect | Admin Only | Bastion access, 2FA required |

##### 4.3.7.4 Application and Service Access

| Application / Tool | Roles With Access | Authentication Method | Notes |
|--------------------|-------------------|----------------------|-------|
| LibreOffice / Office Suite | All office roles | AD integrated | General productivity |
| Finance System (Simulated) | Finance Manager, Execs | AD + SAML | Web-based access |
| HR Tracker (Simulated) | HR Manager, Execs | AD + SAML | Internal portal |
| CUPS Printer Queue | All staff | AD group mappings | See section 4.4.4.5 |
| Shared Calendar System | All roles | AD credentials | Read/write based on dept group |
| Git-based Docs (Public) | All staff | Read-only, no auth | Deployed via GitHub Pages |
| Git-based Docs (Encrypted) | Sr. Pro, IT Admin, Editors | SSH key + git-crypt | Controlled repo access |

##### 4.3.7.5 Administrative Access Controls

| Admin Function | Role / Group | Approval Required | Notes |
|----------------|--------------|-------------------|-------|
| AD User Management | IT Administrator (`GG-IT-Admins`) | Department Head | Account creation/modification |
| File Share ACLs | IT Admin, AD Architect | IT Security | Permission changes logged |
| Git Repository Secrets | IT Admin, Content Editor | Project Manager | Encrypted via git-crypt |
| Print Queue Admin | IT Admin | None (routine ops) | Printer group assignment |
| Security Logs (auditd) | Security Analyst, IT Admin | None (read-only) | Reviewed monthly |
| Remote Access (SSH) | IT Admin | None (routine) | Key-based only, logged |
| Server Reboots / Updates | IT Admin, Linux Architect | Change ticket | Scheduled maintenance window |

##### 4.3.7.6 Access Review and Auditing

- **Quarterly Access Review:** IT Security Analyst validates all group memberships
- **Access Change Requests:** Via IT ticket system, approved by department head
- **Scripted Audit Tools:** Ansible playbook to validate AD group assignments
- **Change Tracking:** All AD group assignments tracked in Git under `implementation/roles/ad-groups/*.yml`
- **Anomaly Detection:** Automated scripts flag unauthorized group memberships weekly

---

#### 4.3.8 Secure Email Policy

**Source Document:** `POLICY-EMAIL-SECURE-001` (secure-email-policy.md)

This policy defines secure email usage within the SMB office environment, including encryption, sensitive data handling, and third-party communication requirements.

##### 4.3.8.1 Email Usage Guidelines

- Use email only for **official business communication**
- Avoid using personal email accounts for company matters
- Do not share login credentials or allow unauthorized access
- Use department-specific signatures and branding

##### 4.3.8.2 Encryption and Transmission Requirements

| Email Type | Encryption Requirement |
|------------|------------------------|
| Internal emails (staff → staff) | TLS enforced (server-level) |
| External emails (staff → client) | S/MIME or PGP if sensitive data |
| Attachments with PII/financials | Encrypted (ZIP+passphrase or secure link) |
| Webmail access | HTTPS + MFA enforced |

**Supported Encryption Tools:**
- GPG/PGP for user-level encryption
- Thunderbird or Evolution mail clients with OpenPGP support
- Nextcloud Mail integration with secure portal links

##### 4.3.8.3 Sensitive Data Handling

**Never send via unencrypted email:**
- Social Security numbers or national ID numbers
- Banking or credit card information
- Login credentials or API keys
- Internal financial reports (unless cleared by Finance Manager)

**If email transmission required:**
1. Encrypt the attachment using password-protected ZIP or GPG
2. Send password via separate channel (SMS, phone call, Signal)
3. CC `it-security@smboffice.local` for audit trail
4. Use email classification tags (see section 4.3.8.5)

##### 4.3.8.4 External Communication Policy

| Recipient Type | Policy Enforcement |
|----------------|-------------------|
| Clients | May receive secure attachments or portal links |
| Vendors | Email allowed with signed NDA on file |
| Job applicants | PII protection applies, use secure forms |
| Legal/Government | Use encrypted channels only, no standard email |

**Required Email Footer:**
> **CONFIDENTIAL:** This message may contain sensitive information intended for the recipient only. If you received this in error, please delete and notify sender immediately.

##### 4.3.8.5 Email Classification Rules

| Classification | Email Permissions | Handling Requirement |
|----------------|-------------------|----------------------|
| Public | Open distribution allowed | No encryption required |
| Internal Use Only | Internal users only | TLS enforced |
| Confidential | Role-restricted | Encrypted attachment or secure portal |
| Restricted | Executives/IT only | PGP or platform-based secure channel |

**Implementation:** Email classification tags added via mail client plugins or server-side filters

##### 4.3.8.6 Monitoring and Logging

- Outbound emails logged via mail server (`postfix` logs on `mail01`)
- **DLP (Data Loss Prevention):** Flagged keywords auto-scanned (SSNs, credit cards, "confidential")
- Weekly reports reviewed by IT Security Analyst
- Alert triggers for suspicious file types: `.xls`, `.csv`, `.sql` with financial keywords
- Retention: Email logs retained for 180 days

##### 4.3.8.7 Violations and Enforcement

**Violations include:**
- Sending unencrypted confidential data
- Forwarding sensitive information to personal accounts
- Repeated misuse of external email for unauthorized purposes

**Disciplinary Action:**
- First violation: Warning + security awareness retraining
- Repeated violations: Account restriction, access review by IT Security
- Serious breach: Escalated to HR and Security Committee, potential termination

---

### 4.4 Departmental Access Controls

#### 4.4.1 Finance Department Access Matrix

| Resource | Finance Manager | Finance Staff | HR Manager | Admin Assistant | IT Admin |
|----------|----------------|---------------|------------|-----------------|----------|
| `\\files01\finance` | Read/Write | Read/Write | Denied | Denied | Read (audit) |
| `\\files01\finance\payroll` | Read/Write | Read/Write | **Read-Only** | Denied | Denied |
| `\\files01\clients\billing` | Read/Write | Read-Only | Denied | Denied | Denied |
| `\\files01\hr\payroll` | **Read-Only** | Denied | Read/Write | Denied | Denied |

**Key Security Principles:**
- **Separation of Duties:** Finance can view but not modify HR payroll; HR can view but not modify Finance payroll
- **Least Privilege:** Finance Staff have reduced access to billing data (read-only)
- **Audit Trail:** All access is logged via auditd and Samba VFS full_audit

#### 4.4.2 HR Department Access Matrix

| Resource | HR Manager | HR Staff | Finance Manager | Admin Assistant | IT Admin |
|----------|------------|----------|-----------------|-----------------|----------|
| `\\files01\hr` | Read/Write | Read/Write | Denied | Denied | Read (audit) |
| `\\files01\hr\personnel` | Read/Write | **Denied** | Denied | Denied | Denied |
| `\\files01\hr\forms\templates` | Read/Write | Read/Write | Denied | **Read-Only** | Denied |
| `\\files01\finance\payroll` | **Read-Only** | Denied | Read/Write | Denied | Denied |
| `\\files01\company\policies` | Read/Write | Read/Write | Read | Read/Write | Read |

**Key Security Principles:**
- **Role-Based Access:** HR Staff cannot access personnel files (managers only)
- **Cross-Department Coordination:** Admin Assistant can read HR form templates
- **PII Protection:** Personnel files restricted to HR Managers only

#### 4.4.3 Admin Assistant Access Matrix

| Resource | Admin Assistant | HR Manager | Finance Manager | IT Admin |
|----------|-----------------|------------|-----------------|----------|
| `\\files01\shared\templates` | Read/Write | Read | Read | Read |
| `\\files01\hr\forms\templates` | **Read-Only** | Read/Write | Denied | Denied |
| `\\files01\company\policies` | Read/Write | Read/Write | Read | Read |
| `\\files01\finance` | Denied | Denied | Read/Write | Read (audit) |
| `\\files01\hr\personnel` | Denied | Read/Write | Denied | Denied |

**Key Security Principles:**
- **Multi-Department Support:** Access to shared resources across departments
- **Limited Sensitive Access:** No access to Finance or HR personnel data
- **Template Management:** Can modify shared templates, read HR form templates

---

#### 4.4.4 Access Control Principles and Policies

**Source Documents:**
- `POLICY-USER-ACCESS-001` (user-access-policy.md)
- `POLICY-FIN-DATA-ACCESS-001` (financial-data-access-guidelines.md)
- `POLICY-CLIENT-ACCESS-001` (client-access-policy.md)

##### 4.4.4.1 Core Access Management Principles

All user access to systems, file shares, and resources follows these principles:

1. **Least Privilege:** Access granted only to what is strictly needed for job function
2. **Role-Based Access Control (RBAC):** Access mapped to employee's role and department
3. **Auditable:** All access changes must be logged and traceable
4. **Revocable:** All access can be removed promptly upon exit or role change
5. **Time-Bound:** Interns, temps, and contractors have automatic expiration timers

##### 4.4.4.2 User Account Lifecycle Management

| Stage | Action | Timeline | Workflow Document |
|-------|--------|----------|-------------------|
| **Onboarding** | Account created, groups assigned | Day 1 | `onboarding-workflow.md` |
| **Role Transfer** | Access re-evaluated, groups updated | Within 24 hours | IT change request |
| **Termination** | AD account disabled, access revoked | Within 2 hours | Offboarding checklist |
| **Temp/Intern Expiry** | Auto-disable after access period | Automatic | GPO + scheduled task |
| **Quarterly Audit** | Access rights reviewed | Every 90 days | IT Security Analyst |

##### 4.4.4.3 Financial Data Access Authorization

| Access Classification | Description | Required Approval | Access Duration |
|----------------------|-------------|-------------------|-----------------|
| **Public Finance Data** | Internal reports for exec review | Finance Manager | Permanent |
| **Departmental Data** | Working files, forecasts, AP/AR | Finance Manager | Permanent |
| **Sensitive Financials** | Payroll, client billing, budgets | Finance Manager + IT Security | Permanent (with quarterly review) |
| **Audit Logs** | Access logs, auditd reports | IT Security Analyst only | Permanent |

**Access Request Process (Finance):**
1. User submits request to manager and IT Security via ticket/email
2. Finance Manager approval required for all elevated access
3. IT AD Architect grants membership to appropriate AD security group
4. Access logs updated (manual or Ansible-integrated)
5. Review every 90 days as part of access audit cycle

##### 4.4.4.4 Client Access Policy (External Users)

External clients requiring temporary access to shared files or portals must follow this policy:

**Approved Access Types:**
| Access Type | Description | Default Expiry | Max Expiry |
|-------------|-------------|----------------|------------|
| Shared File Access | Read/download from approved shares | 7 days | 30 days |
| Secure Folder Upload | Write access for document submission | 3 days | 7 days |
| Portal Login | Client-specific portal credentials | 14 days | 60 days |

**Client Access Workflow:**
1. **Request:** Internal staff (relationship owner) initiates request
2. **Approval:** Department Manager **AND** IT Security Analyst approval required
3. **Provision:** IT or automation script creates access, logged in `client-access.log`
4. **Expiration:** Auto-disabled at expiry; re-request required for extension

**Authentication Requirements:**
- Email-based tokens (preferred for portals)
- Temporary AD-linked account with strong password
- MFA required for high-sensitivity data (e.g., finance files)
- Email domain must match verified client identity

**File Sharing Rules for Clients:**
- Files stored in designated client folders: `\\files01\Clients\<ClientName>`
- Default permissions: Clients → Read, Internal Staff → Full Control
- Confidential docs: Encrypted ZIP or Nextcloud link with separate password delivery (SMS/phone)
- All client access logged via auditd and Samba logs
- Monthly review by IT Security required

##### 4.4.4.5 Printer Access Policy

**Source Document:** `POLICY-PRINT-ACCESS-001` (printer-access-policy.md)

Printer access is controlled by AD security group membership. No manual printer installation permitted.

**Printer-to-Group Mapping:**
| Printer Name | AD Group | Access Level | Notes |
|--------------|----------|--------------|-------|
| `hr-printer-01` | `GG-Print-HR` | Print Only | HR department only |
| `finance-print-01` | `GG-Print-Finance` | Print/Scan | Finance department, enhanced logging |
| `common-bw-01` | `GG-Print-AllStaff` | Print Only | General office use |
| `exec-color-01` | `GG-Print-Executive` | Print/Scan/Color | Executive team only |

**Printer Deployment:**
- Auto-deployed via Group Policy Preferences or Ansible
- Refreshed at user logon via SSSD (Linux) or GPO (Windows)
- No local admin rights to manually add/remove printers

**Printer Logging:**
- CUPS logs enabled: `/var/log/cups/page_log`
- Logs include: username, file name, timestamp, page count
- Retention: 180 days
- Quarterly review by IT Security Analyst

**Special Cases:**
- Temporary staff: Added to printer groups via onboarding workflow
- Color printing: Requires documented business case approval
- Large print jobs: Routed to department-managed queue

---

### 4.5 Network Architecture

#### 4.5.1 VLAN Segmentation

*(Detailed network topology to be added in future pass)*

**Planned VLANs:**

| VLAN ID | Subnet | Purpose | Isolation Level |
|---------|--------|---------|-----------------|
| VLAN 10 | 10.10.10.0/24 | General Office / Shared Services | Low |
| VLAN 20 | 10.10.20.0/24 | Finance Department | **High** |
| VLAN 30 | 10.10.30.0/24 | HR Department | **High** |
| VLAN 40 | 10.10.40.0/24 | Professional Services | Medium |
| VLAN 50 | 10.10.50.0/24 | Infrastructure (Servers) | **High** |
| VLAN 99 | 10.10.99.0/24 | Management / IT Admin | **Critical** |

**Inter-VLAN Routing:**
- Finance and HR VLANs are **isolated** from each other
- Shared Services VLAN can access file server via ACL enforcement
- All VLANs can access Domain Controller and DNS

#### 4.5.2 Firewall Policies

*(To be detailed in future pass)*

---

### 4.6 Compliance Framework

#### 4.6.1 SOX-Style Controls (Finance)

| Control ID | Control Description | Implementation | Audit Evidence |
|------------|---------------------|----------------|----------------|
| SOX-AC-01 | Access to financial data restricted to authorized personnel | AD security groups, file ACLs | Group membership reports |
| SOX-AC-02 | Separation of duties between Finance and HR payroll | Read-only cross-access | ACL configuration, audit logs |
| SOX-AU-01 | All access to financial records logged and monitored | Auditd, Samba full_audit VFS | Audit log samples |
| SOX-AU-02 | Audit logs retained for 7 years | Log archival policy | Backup verification reports |
| SOX-PW-01 | Strong password policies enforced | 14-char minimum, 90-day expiration | Password policy dumps |
| SOX-DC-01 | Critical financial changes require dual control | GPO settings, file monitoring | Change approval logs |

#### 4.6.2 HIPAA-Style Controls (HR)

| Control ID | Control Description | Implementation | Audit Evidence |
|------------|---------------------|----------------|----------------|
| HIPAA-AC-01 | Access to employee health records restricted | AD security groups, file ACLs | Group membership reports |
| HIPAA-AC-02 | Minimum necessary access enforced | Personnel files: managers only | ACL configuration |
| HIPAA-AU-01 | All access to employee records logged | Auditd, Samba full_audit VFS | Audit log samples |
| HIPAA-AU-02 | Audit logs retained for 7 years | Log archival policy | Backup verification reports |
| HIPAA-EN-01 | Employee data encrypted at rest and in transit | LUKS encryption, SMB encryption | Encryption verification |
| HIPAA-IA-01 | Strong authentication enforced | 14-char passwords, MFA | Authentication policy dumps |

#### 4.6.3 Compliance Validation

**Quarterly Compliance Checks:**
- Automated playbook generates compliance evidence package
- Reviews group memberships, ACLs, audit logs, password policies
- Output: PDF compliance report for stakeholder review

**Ansible Playbook:** `validate-compliance.yml`

---

### 4.7 Monitoring and Logging

#### 4.7.1 Log Aggregation Architecture

**Central Log Server:** `log01.smboffice.local`

**Log Sources:**

| Source | Log Type | Transport | Retention |
|--------|----------|-----------|-----------|
| `files01` | Auditd logs | rsyslog (TCP 514) | 7 years |
| `files01` | Samba access logs | rsyslog (TCP 514) | 90 days |
| `dc01` | AD authentication logs | rsyslog (TCP 514) | 1 year |
| Finance workstations | Auth logs, failed logins | rsyslog (TCP 514) | 90 days |
| HR workstations | Auth logs, failed logins | rsyslog (TCP 514) | 90 days |
| `print01` | Print job logs | rsyslog (TCP 514) | 90 days |

**Rsyslog Configuration (Client):**

```bash
# /etc/rsyslog.d/50-remote.conf
*.* @@log01.smboffice.local:514
```

**Rsyslog Configuration (Server - log01):**

```bash
# /etc/rsyslog.conf
module(load="imtcp")
input(type="imtcp" port="514")

# Finance audit logs
:programname, isequal, "auditd" /var/log/remote/finance/audit.log
& stop

# Samba logs
:programname, isequal, "smbd" /var/log/remote/samba/access.log
& stop
```

#### 4.7.2 Monitoring Dashboards

*(To be specified in future pass with SIEM/monitoring tool selection)*

**Planned Metrics:**
- Failed login attempts by department
- After-hours file access patterns
- Data transfer tool usage
- Audit rule violation counts
- Storage capacity trends

---

### 4.8 Backup and Recovery

#### 4.8.1 Backup Strategy

**Backup Server:** `backup01.smboffice.local` (or NAS device)

**Backup Schedule:**

| Data Type | Frequency | Retention | Method |
|-----------|-----------|-----------|--------|
| Finance files | Daily incremental, Weekly full | 7 years | rsync, tar |
| HR personnel files | Daily incremental, Weekly full | 7 years | rsync, tar |
| AD database | Daily | 90 days | samba-tool domain backup |
| System configurations | Weekly | 1 year | Ansible pull, git |
| Audit logs | Daily | 7 years | rsync to archive |

**Backup Verification:**
- Monthly restore tests
- Quarterly disaster recovery drill
- Annual full recovery simulation

#### 4.8.2 Recovery Time Objectives (RTO)

| Service | RTO | RPO | Priority |
|---------|-----|-----|----------|
| Domain Controller | 4 hours | 24 hours | **CRITICAL** |
| File Server | 8 hours | 24 hours | **CRITICAL** |
| Finance Data | 4 hours | 24 hours | **HIGH** |
| HR Data | 8 hours | 24 hours | **HIGH** |
| Print Server | 24 hours | 1 week | **MEDIUM** |

---

### 4.9 Operational Policies

This section consolidates operational policies governing day-to-day access, infrastructure usage, and administrative procedures.

#### 4.9.1 Administrative Access Checkout Policy

**Source Document:** `POLICY-ADMIN-CHECKOUT-001` (admin-checkout-policy.md)

This policy enforces controlled and auditable access to sensitive data and systems, limiting risk through time-bound, logged administrative access.

##### 4.9.1.1 Policy Scope

Administrative access checkout applies to:
- Access to **executive-level file shares**
- Access to **finance or HR data** (by non-department staff)
- Changes to **Active Directory groups**
- Temporary **elevated sudo or root permissions**
- Use of **privileged Ansible roles**
- Access to **client deliverables**
- Manual overrides or backdoor access for troubleshooting

##### 4.9.1.2 Access Categories

| Category | Examples | Max Duration |
|----------|----------|--------------|
| Admin File Access | Executive folders, finance exports | 4 hours |
| Domain-Level Changes | AD group edits, user moves | 4 hours |
| Security Configurations | auditd, SELinux, AIDE config changes | 4 hours |
| Privileged Systems | `/etc/samba/*`, Ansible vault credentials | 4 hours |
| Emergency Break-Glass Access | Root shell on DCs or key servers | 1 hour (with post-access review) |
| Client File Review | Temporary access to client deliverables | 2 hours |

##### 4.9.1.3 Checkout Workflow

1. **Request Initiation**
   - Submitted via secure form or IT ticket by authorized user
   - Must include: reason, systems/data needed, duration requested

2. **Approval**
   - Reviewed and approved by IT Security Analyst or Department Head
   - Finance/HR data requires department manager approval

3. **Access Granted**
   - Limited by scope, system, and time window
   - Logged in `admin-checkout.log` (encrypted repository)
   - Access credentials or group membership granted

4. **Audit Flagging**
   - Access tagged and monitored by `auditd`
   - Real-time alerts for sensitive operations

5. **Access Revoked Automatically**
   - Revoked by Ansible job or cron script at expiration time
   - No manual intervention required for revocation

> **Emergency Access:** Requires post-access review and documentation within 24 hours

##### 4.9.1.4 Required Log Fields

All administrative access checkout must log:
- Username (requestor)
- Access type (category from table above)
- Reason for access (business justification)
- Approver name
- Start timestamp
- End timestamp (actual)
- Systems or folders touched
- Actions performed (high-level summary)

**Log Locations:**
- `admin-checkout.log` (encrypted Git repository)
- `auditd` event logs (system-level)
- AD Group modification history (if applicable)

##### 4.9.1.5 Violations and Enforcement

- Any access without approval is a **security violation**
- IT Security reserves the right to **immediately revoke access**
- Repeat violations may result in disciplinary action
- All violations logged and reviewed by Project Doc Auditor

---

#### 4.9.2 Shared Services Policy

**Source Document:** `POLICY-INFRA-SSP-001` (shared-services-policy.md)

##### 4.9.2.1 Scope of Shared Services

Centralized IT services supporting multiple departments:

| Service | Hostname | Protocol/Stack | Purpose |
|---------|----------|----------------|---------|
| File Services | `files01` | Samba / SMB | Department file shares |
| Print Services | `print01` | CUPS / IPP / Samba | Shared network printers (AD-aware) |
| DNS | `dc01`, `dc02` | BIND / Samba Internal DNS | AD and name resolution |
| DHCP | `infra01` | ISC-DHCP | Client IP assignment (optional) |
| LDAP/Kerberos | `dc01`, `dc02` | Samba 4 (AD compatible) | Authentication |
| NTP | `infra01` | chrony | Time synchronization for domain |

##### 4.9.2.2 Usage Guidelines

- **File shares:** Business content only; no personal or unlicensed files
- **Shared printers:** Departmental use only; color printing restricted by GPO
- **DNS/DHCP modification:** IT Admin rights required
- **NTP configuration:** All clients must use internal servers
- **Obsolete content cleanup:** Departments responsible for regular cleanup

##### 4.9.2.3 Maintenance and Updates

- **Owners:** Linux Admin and IT AD Architect
- **Patching Schedule:** Bi-weekly unless critical vulnerabilities emerge
- **Monitoring:** `checkmk` or `Prometheus` for uptime and anomalies
- **Change Management:** All infrastructure changes via IT ticket

##### 4.9.2.4 Incident Handling

- **Suspected Misuse:** Report to IT Security Analyst
- **Data Recovery:** Best-effort using nightly ZFS snapshots
- **Printing Abuse:** Account review for wasteful or restricted content
- **Log Review:** Monthly review in response to any breach or data access concern

---

#### 4.9.3 Executive Security Requirements

**Source Document:** `POLICY-SEC-EXEC-001` (executive-security-policy.md)

##### 4.9.3.1 Executive Workstation Requirements

| Control | Requirement | Enforcement |
|---------|-------------|-------------|
| Endpoint OS | Hardened Oracle Linux 9 (GUI) | Ansible deployment |
| Local Account | No local root login | PAM configuration |
| Authentication | AD-integrated with MFA | SSSD + 2FA token |
| Drive Encryption | Full Disk Encryption (LUKS) | Automated via kickstart |
| Removable Media | Disabled by default | udev rules + GPO |
| Screensaver Timeout | Auto-lock after 5 minutes idle | GPO enforcement |
| Updates | Weekly via secured internal repo | Ansible automation |

##### 4.9.3.2 Executive Data Access and Classification

| Data Type | Access Method | Access Level |
|-----------|---------------|--------------|
| Financial Summaries | Encrypted share (`\\files01\executive\finance`) | Read-Only |
| HR Performance Reports | Encrypted share (`\\files01\executive\hr`) | Read-Only (summary only) |
| Strategic Documents | Internal Git repo (git-crypt) | Read/Write |
| Client Billing Overview | Encrypted folder | Read-Only |

##### 4.9.3.3 Executive Communication Policy

- All outbound executive emails must use **corporate domain**
- Executive emails must be **signed and encrypted** (GPG or S/MIME)
- No use of personal email for work-related tasks
- Messaging via **approved encrypted platform** (Signal / Mattermost E2EE)
- External document sharing **prohibited** unless routed through IT-reviewed process

##### 4.9.3.4 Executive Audit and Monitoring

| Audit Feature | Status | Review Frequency |
|---------------|--------|------------------|
| File Access Logs | ✅ Enabled (auditd) | Real-time monitoring |
| Login Attempt Logging | ✅ Enabled | Daily review |
| sudo / privilege escalation | ✅ Enabled | Immediate alert |
| Executive Share Changes | ✅ Enabled | Logged and rotated |
| Email Encryption Failure | ✅ Enabled | Weekly audit |

---

### 4.10 Implementation Standards

#### 4.10.1 Ansible Automation Requirements

**Playbook Organization:**

```
ansible/
├── playbooks/
│   ├── site.yml                    # Master orchestration
│   ├── deploy-infrastructure.yml   # Infrastructure deployment
│   ├── deploy-security.yml         # Security hardening
│   ├── validate-compliance.yml     # Compliance validation
│   └── backup-systems.yml          # Backup configuration
├── roles/
│   ├── common/
│   ├── samba-ad-dc/
│   ├── samba-fileserver/
│   ├── auditd/
│   ├── selinux/
│   ├── workstation/
│   └── monitoring/
├── inventory/
│   └── hosts.yml
└── group_vars/
    ├── all.yml
    ├── servers.yml
    └── workstations.yml
```

**Coding Standards:**
- All playbooks must be idempotent
- Use `check` mode for dry-run validation
- Implement tags for selective execution
- Document all variables in role README files
- Use Ansible Vault for secrets

#### 4.10.2 Documentation Standards

**All documentation must follow:** `standards/markdown.md`

**Required Elements:**
- Metadata block with Doc ID, Author, Status
- Table of Contents (if >3 sections)
- Purpose, Background, Objectives sections
- Review History table
- Departmental Approval Checklist

#### 4.10.3 Testing and Validation

**Test Levels:**

1. **Unit Tests:** Individual role validation
2. **Integration Tests:** Cross-system functionality
3. **Compliance Tests:** SOX/HIPAA control validation
4. **Security Tests:** Penetration testing, access control validation
5. **User Acceptance Tests:** Department-specific workflows

**Test Documentation:** All tests documented in `tests/` directory with results logged

---

## 5. Related Files

### Source Documents (Requirements)

**Organizational Structure:**
- [simulated-org-chart.md](../../simulated-client-project/org/simulated-org-chart.md) - `ORG-STRUCTURE-001`
- [file-share-structure.md](../../simulated-client-project/org/file-share-structure.md) - `INFRA-FS-STRUCTURE-001`

**Use Cases:**
- [admin-assistant-use-case.md](../../simulated-client-project/use-cases/admin-assistant-use-case.md)
- [finance-manager-use-case.md](../../simulated-client-project/use-cases/finance-manager-use-case.md)
- [hr-manager-use-case.md](../../simulated-client-project/use-cases/hr-manager-use-case.md)

**Requirements Documents:**
- [admin-assistant-requirements.md](../requirements/admin-assistant-requirements.md)
- [finance-manager-requirements.md](../requirements/finance-manager-requirements.md)
- [hr-manager-requirements.md](../requirements/hr-manager-requirements.md)

**Audit and Security:**
- [auditd-finance-rules.md](../../simulated-client-project/audit/auditd-finance-rules.md) - `SECURITY-AUDITD-FIN-001`

**Policy Documents:**
- [user-access-policy.md](../../simulated-client-project/policy/user-access-policy.md) - `POLICY-USER-ACCESS-001`
- [group-policy-baseline.md](../../simulated-client-project/policy/group-policy-baseline.md) - `POLICY-GPO-BASELINE-001`
- [admin-checkout-policy.md](../../simulated-client-project/policy/admin-checkout-policy.md) - `POLICY-ADMIN-CHECKOUT-001`
- [audit-log-policy.md](../../simulated-client-project/policy/security/audit-log-policy.md) - `POLICY-AUDIT-LOG-001`
- [hr-data-retention-policy.md](../../simulated-client-project/policy/hr-data-retention-policy.md) - `POLICY-HR-RETENTION-001`
- [financial-data-access-guidelines.md](../../simulated-client-project/policy/finance/financial-data-access-guidelines.md) - `POLICY-FIN-DATA-ACCESS-001`
- [executive-security-policy.md](../../simulated-client-project/policy/executive-security-policy.md) - `POLICY-SEC-EXEC-001`
- [client-access-policy.md](../../simulated-client-project/policy/client-access-policy.md) - `POLICY-CLIENT-ACCESS-001`
- [printer-access-policy.md](../../simulated-client-project/policy/printer-access-policy.md) - `POLICY-PRINT-ACCESS-001`
- [shared-services-policy.md](../../simulated-client-project/policy/shared-services-policy.md) - `POLICY-INFRA-SSP-001`
- [finance-department-policy.md](../../simulated-client-project/policy/finance-department-policy.md) - `POLICY-FINANCE-001`

**Security Documents:**
- [auditd-hr-rules.md](../../simulated-client-project/security/audit/auditd-hr-rules.md) - `SECURITY-AUDITD-HR-001`
- [file-permissions-audit.md](../../simulated-client-project/security/audit/file-permissions-audit.md) - `AUDIT-FILE-PERMISSIONS-001`
- [access-control-matrix.md](../../simulated-client-project/security/access-control-matrix.md) - `SECURITY-ACCESS-MATRIX-001`
- [file-share-permissions.md](../../simulated-client-project/security/file-share-permissions.md) - `SECURITY-FILES-001`
- [secure-email-policy.md](../../simulated-client-project/security/secure-email-policy.md) - `POLICY-EMAIL-SECURE-001`

**Standards:**
- [markdown.md](../../standards/markdown.md)

### Related Specifications

*(To be added as specification grows)*
- Network topology specification
- AD design specification
- Security baseline specification
- Disaster recovery specification

---

## 6. Review History

| Version | Date | Reviewer | Notes |
|---------|------|----------|-------|
| v1.0 | 2025-12-23 | IT Business Analyst | Initial system specification created from audit requirements (Finance) |
| v1.1 | 2025-12-23 | IT Business Analyst, SMB Analyst | Added organizational structure and file share structure from org documents |
| v1.2 | 2025-12-23 | IT Security Analyst, IT Business Analyst | Added policy frameworks: GPO baseline, access control, data retention, administrative checkout procedures |
| v1.3 | 2025-12-23 | IT Security Analyst, Linux Admin/Architect | Added security frameworks: HR audit rules, file permissions audit, access control matrix, secure email policy |

---

## 7. Departmental Approval Checklist

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
| SEO Analyst | [ ] | |
| Content Editor | [ ] | |
| Project Manager | [ ] | |
| Task Assistant | [ ] | |

---

## 📝 Document Build Notes

### Pass v1.0 (Initial)
**Source Documents Incorporated:**
- `SECURITY-AUDITD-FIN-001` - Finance department auditd rules and monitoring

**Sections Completed:**
- 4.3.1 Audit Logging Framework (Finance Department)
- 4.6.1 SOX-Style Controls (Finance)
- 4.7.1 Log Aggregation Architecture

### Pass v1.1
**Source Documents Incorporated:**
- `ORG-STRUCTURE-001` - Simulated organization chart
- `INFRA-FS-STRUCTURE-001` - File share structure and layout

**Sections Completed:**
- 4.0 Organizational Structure (all subsections)
- 4.2.2 File Server Architecture (comprehensive expansion)
  - Share design principles
  - Directory structure
  - Share configuration table
  - Naming conventions
  - Access control and ownership
  - Security and compliance notes
  - Samba configuration examples
  - Integration with organizational structure

**Sections Enhanced:**
- 4.0.5 Active Directory OU mapping (aligned with org chart)
- 4.0.6 Security group mapping (comprehensive department groupings)
- 4.2.2.8 Department-to-share mapping

### Pass v1.2
**Source Documents Incorporated:**
- `POLICY-USER-ACCESS-001` - User access control policy
- `POLICY-GPO-BASELINE-001` - Group policy baseline
- `POLICY-ADMIN-CHECKOUT-001` - Administrative access checkout policy
- `POLICY-AUDIT-LOG-001` - Audit log policy and retention
- `POLICY-HR-RETENTION-001` - HR data retention policy
- `POLICY-FIN-DATA-ACCESS-001` - Financial data access guidelines
- `POLICY-SEC-EXEC-001` - Executive security policy
- `POLICY-CLIENT-ACCESS-001` - Client access policy
- `POLICY-PRINT-ACCESS-001` - Printer access policy
- `POLICY-INFRA-SSP-001` - Shared services policy
- `POLICY-FINANCE-001` - Finance department policy

**Sections Completed:**
- **4.2.3 Group Policy Configuration** (NEW)
  - GPO strategy and deployment plan
  - Default Domain Policy settings
  - Department-specific GPOs (HR, Finance, Professional Services)
  - Security settings (USB control, screensaver, device restrictions)
  - Login and UX settings
  - USB and device control matrix
- **4.3.4 Audit Log Policy and Retention** (NEW)
  - Log types and sources
  - Retention requirements
  - Log access and protection
  - Time synchronization requirements
  - Review and monitoring schedule
- **4.3.5 Data Retention Policies** (NEW)
  - HR data retention schedules
  - Secure deletion procedures
  - Data backup and retention policy
  - Roles and responsibilities
- **4.4.4 Access Control Principles and Policies** (NEW)
  - Core access management principles
  - User account lifecycle management
  - Financial data access authorization
  - Client access policy (external users)
  - Printer access policy
- **4.9 Operational Policies** (NEW SECTION)
  - 4.9.1 Administrative Access Checkout Policy
  - 4.9.2 Shared Services Policy
  - 4.9.3 Executive Security Requirements

**Sections Enhanced:**
- 4.4 Departmental Access Controls (added comprehensive policy framework)

**Sections Renumbered:**
- Previous 4.9 Implementation Standards → 4.10 Implementation Standards
  - All subsections renumbered from 4.9.x to 4.10.x

### Pass v1.3 (Current)
**Source Documents Incorporated:**
- `SECURITY-AUDITD-HR-001` - HR department auditd monitoring rules
- `AUDIT-FILE-PERMISSIONS-001` - File share permissions audit procedure
- `SECURITY-ACCESS-MATRIX-001` - Access control matrix (RBAC overview)
- `SECURITY-FILES-001` - File share permissions policy
- `POLICY-EMAIL-SECURE-001` - Secure email policy

**Sections Completed:**
- **4.3.2 HR Department Audit Rules** (EXPANDED from placeholder)
  - HR audit scope and targeted paths
  - Comprehensive audit rule examples (access tracking, file deletion, permission changes)
  - HR log reporting and review procedures
  - Optional alerts and integrations
  - Maintenance tasks schedule
- **4.3.6 File Permissions Audit Procedure** (NEW)
  - Audit objectives and tools
  - Audit targets by classification
  - Step-by-step audit procedure
  - Findings report template
  - Corrective actions and audit schedule
- **4.3.7 Access Control Matrix (RBAC)** (NEW)
  - Role definitions with security levels
  - File share access matrix
  - System access matrix
  - Application and service access
  - Administrative access controls
  - Access review and auditing procedures
- **4.3.8 Secure Email Policy** (NEW)
  - Email usage guidelines
  - Encryption and transmission requirements
  - Sensitive data handling procedures
  - External communication policy
  - Email classification rules
  - Monitoring, logging, and enforcement

**Sections Enhanced:**
- 4.3 Security and Audit Requirements (comprehensive expansion with HR audit rules, file permissions, and access matrix)

**Sections Pending Future Passes:**
- 4.5 Network Architecture (detailed VLAN topology, firewall rules)
- 4.6 Compliance Framework (expand SOX and HIPAA-style controls)
- 4.7.2 Monitoring Dashboards (Prometheus/Grafana configuration)
- 4.8 Backup and Recovery (detailed backup procedures, restore testing)

### Next Planned Pass: v1.4
**Planned Source Documents:**
- Network topology and VLAN specifications
- Workstation hardening and deployment configurations
- Monitoring and alerting configurations
- Additional workflow and process documents

---

**End of Document**

*This is a living document that will be updated incrementally as additional requirements are incorporated from source documents.*
