<!--
███████████████████████████████████████████████████████████████
  🧾 SMB Office IT Blueprint – Project Document
  Doc ID: INFRA-FS-STRUCTURE-001
  Author: IT Linux Admin/Architect
  Created: 2025-12-23
  Updated: 2025-12-23
  Version: v1.0
  Status: Draft
  Confidentiality: Internal
  Project Phase: Implementation
  Category: Infrastructure – File Shares
  Audience: IT Team, Department Managers
  Owners: IT Linux Admin/Architect, IT AD Architect
  Reviewers: Project Doc Auditor, HR Manager
  Tags: [samba, file-server, shares, folders, groups]
  Data Sensitivity: Medium
  Compliance: Internal Policy
  Publish Target: Internal
  Summary: >
    Defines the design, naming standards, access control, and organizational layout of Samba file shares across departments, enabling secure and logical access for users.
  Read Time: ~4 minutes
███████████████████████████████████████████████████████████████
-->

# 🗂️ File Share Structure & Layout

---

## 📍 Table of Contents

- [1. Purpose](#1-purpose)
- [2. Scope](#2-scope)
- [3. Share Design Principles](#3-share-design-principles)
- [4. Directory Structure](#4-directory-structure)
- [5. Share Configuration Table](#5-share-configuration-table)
- [6. Naming Conventions](#6-naming-conventions)
- [7. Access Control & Ownership](#7-access-control--ownership)
- [8. Security Notes](#8-security-notes)
- [9. Related Documents](#9-related-documents)
- [10. Review History](#10-review-history)
- [11. Departmental Approval Checklist](#11-departmental-approval-checklist)

---

## 1. Purpose

To define a consistent, department-based directory structure for the Samba file server that is easy to manage, secure, and aligned with AD group ownership and access policies.

---

## 2. Scope

This structure applies to:
- Primary file server: `files01`
- Samba shares managed under `/srv/shares/`
- Users accessing via Windows or Linux systems joined to the domain
- Mounted automatically via login scripts or policies

---

## 3. Share Design Principles

- Organized by department and function
- Controlled via AD Security Groups (e.g., `GG-Finance`)
- Subfolders with limited access defined clearly
- Read-only or write-restricted folders documented per group
- Use of **access-based enumeration (ABE)** is supported

---

## 4. Directory Structure

```text
/srv/shares/
├── Common/
│   ├── CompanyDocs/
│   └── Templates/
├── HR/
│   ├── Personnel/
│   ├── Onboarding/
│   └── Policies/
├── Finance/
│   ├── Payroll/
│   ├── Reporting/
│   └── Invoices/
├── Professional/
│   ├── Clients/
│   └── Projects/
├── IT/
│   ├── Installers/
│   └── Configs/
└── Temp/
    └── Uploads/
````

---

## 5. Share Configuration Table

| Share Name     | Path                        | AD Group      | Access     | Notes                        |
| -------------- | --------------------------- | ------------- | ---------- | ---------------------------- |
| `common`       | `/srv/shares/Common/`       | `GG-AllStaff` | Read/Write | General templates and docs   |
| `hr`           | `/srv/shares/HR/`           | `GG-HR`       | Full       | Personnel records (secure)   |
| `finance`      | `/srv/shares/Finance/`      | `GG-Finance`  | Full       | Financial data and reports   |
| `professional` | `/srv/shares/Professional/` | `GG-Prof`     | Full       | Client data and projects     |
| `it`           | `/srv/shares/IT/`           | `GG-IT`       | Full       | IT-only shares               |
| `temp`         | `/srv/shares/Temp/`         | `GG-AllStaff` | Write Only | For uploads, deleted nightly |

---

## 6. Naming Conventions

* **Top-level shares:** lowercase, department-aligned
* **Subfolders:** CamelCase or underscore (HR_Policies, Payroll_Reports)
* **Avoid spaces** in directory names
* **Client folders:** `clientname_projectname_YYYYMM` (e.g., `acmecorp_redesign_202512`)

---

## 7. Access Control & Ownership

* Controlled via **AD security groups only**
* No individual user-based permissions
* Folder permissions enforced via:

  * POSIX ACLs
  * `smb.conf` share config
  * `auditd` monitoring on HR/Finance
* Group write access minimized where possible
* Ownership:

  * Folder owner: `root`
  * Group owner: matching `GG-*` group
  * Permissions: `770` or more restrictive

---

## 8. Security Notes

* Sensitive folders (e.g., `/HR/Personnel`, `/Finance/Payroll`) are:

  * Audit-logged (`auditd`)
  * Backed up separately
  * Reviewed monthly for access compliance
* Temp uploads are automatically purged every 24h via cron job
* Shared folders are not available over public/VPN unless explicitly whitelisted

---

## 9. Related Documents

* [file-share-permissions.md](file-share-permissions.md)
* [auditd-hr-rules.md](auditd-hr-rules.md)
* [auditd-finance-rules.md](auditd-finance-rules.md)
* [user-access-policy.md](../security/user-access-policy.md)
* [admin-checkout-policy.md](../security/admin-checkout-policy.md)

---

## 10. Review History

| Version | Date       | Reviewer            | Notes         |
| ------- | ---------- | ------------------- | ------------- |
| v1.0    | 2025-12-23 | IT Security Analyst | Initial Draft |

---

## 11. Departmental Approval Checklist

| Department / Agent    | Reviewed | Reviewer Notes |
| --------------------- | -------- | -------------- |
| SMB Analyst           | [ ]      |                |
| IT Business Analyst   | [ ]      |                |
| Project Doc Auditor   | [ ]      |                |
| IT Security Analyst   | [ ]      |                |
| IT AD Architect       | [ ]      |                |
| Linux Admin/Architect | [ ]      |                |
| Ansible Programmer    | [ ]      |                |
| IT Code Auditor       | [ ]      |                |
| SEO Analyst           | [ ]      |                |
| Content Editor        | [ ]      |                |
| Project Manager       | [ ]      |                |
| Task Assistant        | [ ]      |                |

