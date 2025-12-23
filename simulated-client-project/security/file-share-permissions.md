<!--
███████████████████████████████████████████████████████████████
  🧾 SMB Office IT Blueprint – Project Document
  Doc ID: SECURITY-FILES-001
  Author: IT AD Architect
  Created: 2025-12-23
  Updated: 2025-12-23
  Version: v1.0
  Status: Draft
  Confidentiality: Restricted
  Project Phase: Lab Build
  Category: Security Policy
  Audience: IT
  Owners: IT AD Architect, IT Security Analyst
  Reviewers: Project Doc Auditor, Linux Admin/Architect
  Tags: [permissions, shares, samba, acl, fileserver, security]
  Data Sensitivity: Simulated Access Rules
  Compliance: Principle of Least Privilege (PoLP)
  Publish Target: Internal
  Summary: >
    This document defines the file share layout and permission model for the simulated business office within the Samba AD lab. Includes group-based access control, naming conventions, and access patterns for departments and roles.
  Read Time: ~6 min
███████████████████████████████████████████████████████████████
-->

# 🗂️ File Share Permissions Policy

---

## 📍 Table of Contents

- [1. Purpose](#1-purpose)
- [2. Fileserver Overview](#2-fileserver-overview)
- [3. Share Layout](#3-share-layout)
- [4. Group-Based Access Control](#4-group-based-access-control)
- [5. Permission Matrix](#5-permission-matrix)
- [6. File Naming Conventions](#6-file-naming-conventions)
- [7. Auditing and Access Logs](#7-auditing-and-access-logs)
- [8. Encryption & Backup](#8-encryption--backup)
- [9. Related Documents](#9-related-documents)
- [10. Review History](#10-review-history)
- [11. Departmental Approval Checklist](#11-departmental-approval-checklist)

---

## 1. Purpose

To standardize and secure the access to departmental and shared file repositories on the internal file server (`files01`) using **Active Directory (AD) groups and Samba ACLs**. This ensures controlled collaboration and regulatory compliance.

---

## 2. Fileserver Overview

| Server Name | OS            | Role        | Domain Joined |
|-------------|---------------|-------------|----------------|
| `files01`   | Oracle Linux 9 | Samba File Server | Yes (LAB.LOCAL) |

Samba is configured with **RFC2307 schema**, **AD integration**, and supports NT-style and POSIX permissions.

---

## 3. Share Layout

| Share Name                     | UNC Path                             | Description                       |
|--------------------------------|--------------------------------------|-----------------------------------|
| Company Shared                 | `\\files01\shared\company`           | General company-wide documents    |
| HR Department                  | `\\files01\department\hr`            | HR policies, employee records     |
| Finance Department             | `\\files01\department\finance`       | Invoices, payroll, budgets        |
| Client Deliverables            | `\\files01\projects\client-deliverables` | Project workspaces             |
| Executive Reports              | `\\files01\admin\executive-reports`  | Strategic plans, board materials  |
| Intern Workspace               | `\\files01\interns\working`          | Temporary staff shared folder     |

---

## 4. Group-Based Access Control

Access is **enforced through AD security groups**. Each share is linked to one or more **read-only** (`RO`) or **read-write** (`RW`) groups:

| AD Group Name         | Access Type | Role Mapping                      |
|-----------------------|-------------|-----------------------------------|
| `GG-HR-Staff`         | RW          | HR Manager                        |
| `GG-Finance-Staff`    | RW          | Finance Manager                   |
| `GG-Finance-Exec`     | RO          | Executives                        |
| `GG-Project-Staff`    | RW          | Sr./Jr. Professionals             |
| `GG-Company-Docs`     | RW          | Admin Assistant, Execs            |
| `GG-Exec-Leadership`  | RW          | Managing Partner                  |
| `GG-Interns`          | RW          | Intern, assigned supervisor       |

Each Samba share uses:
- **`valid users = @<group>`**
- **`read only = no`** (enforced by ACLs, not share flag)

---

## 5. Permission Matrix

| Share                           | Read Access             | Write Access           |
|---------------------------------|--------------------------|-------------------------|
| Company Shared                  | All Staff                | Admin Assistant, Execs  |
| HR Department                   | HR Manager, Execs        | HR Manager              |
| Finance Department              | Finance Manager, Execs   | Finance Manager         |
| Client Deliverables             | Sr. & Jr. Professionals  | Sr. Professionals       |
| Executive Reports               | Managing Partner         | Managing Partner        |
| Intern Workspace                | Interns                  | Interns, Supervisor     |

---

## 6. File Naming Conventions

Standardized file naming improves search, auditability, and automation.

**Pattern:**
```

[yyyy-mm-dd]*[Dept/Client]*[Type]_[v#].ext

```

**Example:**
```

2025-12-15_Finance_BudgetDraft_v2.xlsx
2025-11-20_ClientA_Report_v1.pdf

```

---

## 7. Auditing and Access Logs

- **Auditd** is enabled on `files01` for all share directories.
- Logs are shipped to `log01` weekly.
- Use `ausearch` and `auditctl` to view or define rules.
- Access reports reviewed quarterly by **IT Security Analyst**.

---

## 8. Encryption & Backup

- **Sensitive shares** (HR, Finance, Executive) are backed up using **ZFS snapshots**.
- External backups are encrypted using **restic + s3 backend** (simulated).
- Intern share is excluded from encrypted offsite backups.
- Git-tracked files in `assets/` and `implementation/` are encrypted via `git-crypt`.

---

## 9. Related Documents

- [access-control-matrix.md](./access-control-matrix.md)
- [finance-department-policy.md](../policy/finance-department-policy.md)
- [shared-services-policy.md](../policy/shared-services-policy.md)
- [executive-security-policy.md](../policy/executive-security-policy.md)
- [git-crypt-encryption-policy.md](../../implementation/security/git-crypt-encryption-policy.md)

---

## 10. Review History

| Version | Date       | Reviewer            | Notes            |
|---------|------------|---------------------|------------------|
| v1.0    | 2025-12-23 | IT AD Architect     | Initial Draft    |

---

## 11. Departmental Approval Checklist

| Department / Agent        | Reviewed | Reviewer Notes |
|---------------------------|----------|----------------|
| SMB Analyst               | [ ]      |                |
| IT Business Analyst       | [ ]      |                |
| Project Doc Auditor       | [ ]      |                |
| IT Security Analyst       | [ ]      |                |
| IT AD Architect           | [ ]      |                |
| Linux Admin/Architect     | [ ]      |                |
| Ansible Programmer        | [ ]      |                |
| IT Code Auditor           | [ ]      |                |
| SEO Analyst               | [ ]      |                |
| Content Editor            | [ ]      |                |
| Project Manager           | [ ]      |                |
| Task Assistant            | [ ]      |                |
