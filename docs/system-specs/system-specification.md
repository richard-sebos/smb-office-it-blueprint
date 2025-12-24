<!--
███████████████████████████████████████████████████████████████
  🧾 SMB Office IT Blueprint – Project Document
  Doc ID: SPEC-SYSTEM-001
  Author: IT Business Analyst, Linux Admin/Architect
  Created: 2025-12-23
  Updated: 2025-12-23
  Version: v1.1
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
  - [4.9 Implementation Standards](#49-implementation-standards)
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

*(To be added in future pass incorporating HR-specific audit requirements)*

**Placeholder:**
- HR personnel file access monitoring
- Onboarding/offboarding activity tracking
- PII access logging

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

### 4.9 Implementation Standards

#### 4.9.1 Ansible Automation Requirements

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

#### 4.9.2 Documentation Standards

**All documentation must follow:** `standards/markdown.md`

**Required Elements:**
- Metadata block with Doc ID, Author, Status
- Table of Contents (if >3 sections)
- Purpose, Background, Objectives sections
- Review History table
- Departmental Approval Checklist

#### 4.9.3 Testing and Validation

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

### Pass v1.1 (Current)
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

**Sections Pending Future Passes:**
- 4.2.1 Active Directory Structure (detailed group policies, GPO settings)
- 4.3.2 HR Department Audit Rules
- 4.5 Network Architecture (detailed VLAN topology, firewall rules)
- 4.7.2 Monitoring Dashboards
- 4.8 Backup and Recovery (detailed backup procedures, restore testing)

### Next Planned Pass: v1.2
**Planned Source Documents:**
- HR audit requirements documents
- Network topology and VLAN specifications
- AD GPO design documents
- Backup and recovery procedures

---

**End of Document**

*This is a living document that will be updated incrementally as additional requirements are incorporated from source documents.*
