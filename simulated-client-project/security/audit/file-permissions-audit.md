<!--
███████████████████████████████████████████████████████████████
  🧾 SMB Office IT Blueprint – Project Document
  Doc ID: AUDIT-FILE-PERMISSIONS-001
  Author: IT Security Analyst
  Created: 2025-12-23
  Updated: 2025-12-23
  Version: v1.0
  Status: Approved
  Confidentiality: Confidential
  Project Phase: Implementation
  Category: Security Audit
  Audience: IT
  Owners: IT Security Analyst, Linux Admin/Architect
  Reviewers: Project Doc Auditor, IT AD Architect
  Tags: [audit, permissions, security, samba, access control]
  Data Sensitivity: Simulated Internal Access Levels
  Compliance: Internal Security Controls
  Publish Target: Internal (Encrypted Repo Area)
  Summary: >
    Outlines the procedure for auditing file share permissions and ACL configurations across key department shares and user directories, ensuring proper role-based access is enforced.
  Read Time: ~6 min
███████████████████████████████████████████████████████████████
-->

# 🛡️ File Share Permissions Audit – Procedure & Report

---

## 📍 Table of Contents

- [1. Purpose](#1-purpose)
- [2. Scope](#2-scope)
- [3. Audit Objectives](#3-audit-objectives)
- [4. Tools Used](#4-tools-used)
- [5. Audit Targets](#5-audit-targets)
- [6. Procedure](#6-procedure)
- [7. Findings Template](#7-findings-template)
- [8. Corrective Action](#8-corrective-action)
- [9. Related Documents](#9-related-documents)
- [10. Review History](#10-review-history)
- [11. Departmental Approval Checklist](#11-departmental-approval-checklist)

---

## 1. Purpose

This document outlines the process for auditing file and folder permissions across all shared SMB resources, validating that only authorized users and groups have access per policy.

---

## 2. Scope

Applies to:
- `\\files01` Samba shares
- `/srv/shares/*` directories
- Users in Finance, HR, Professional Services, and Admin groups
- Public vs restricted folders

---

## 3. Audit Objectives

- Identify misconfigured permissions or overly broad access
- Confirm correct group ownership (e.g., `GG-Finance-Staff`)
- Verify inheritance is properly applied
- Detect unauthorized access to high-sensitivity folders
- Log all manual changes made during the audit

---

## 4. Tools Used

- `getfacl` for Linux filesystem ACLs
- `samba-tool ntacl` for Samba share permissions
- `auditctl` for real-time monitoring
- `find` + `stat` for bulk checks
- `csvkit` or spreadsheet for reporting
- Manual cross-check with [access-control-matrix.md](../access-control-matrix.md)

---

## 5. Audit Targets

| Path                                   | Notes                                |
|----------------------------------------|--------------------------------------|
| `/srv/shares/finance/`                 | Confidential – payroll/reports       |
| `/srv/shares/hr/`                      | Confidential – employee records      |
| `/srv/shares/projects/`               | Restricted – project team only       |
| `/srv/shares/public/`                 | Public – read-only default           |
| `/srv/shares/assistants/`            | Shared – support/admin-only          |

---

## 6. Procedure

### Step 1: Generate ACL Listings

```bash
# Example: export ACLs for finance share
getfacl -R /srv/shares/finance > finance-acl.txt
````

### Step 2: Identify High-Risk Permissions

Look for:

* `other::rwx` (world access)
* Groups outside expected role (e.g., `GG-IT-Admins` on HR shares)
* Manual overrides or removed inheritance

### Step 3: Check Samba Share Access

```bash
samba-tool ntacl get /srv/shares/finance
```

### Step 4: Correlate With Access Matrix

Compare actual ACLs with:

* [file-share-permissions.md](../file-share-permissions.md)
* [access-control-matrix.md](../access-control-matrix.md)


---

## 6. Findings Template

| Path                  | Issue                          | Severity | Fix Required | Notes                |
| --------------------- | ------------------------------ | -------- | ------------ | -------------------- |
| `/srv/shares/finance` | `other::r--` allows world-read | High     | Yes          | Should be `0`        |
| `/srv/shares/hr`      | `GG-Exec` has write access     | Medium   | Yes          | Execs only need read |
| `/srv/shares/public`  | No issues                      | Low      | No           |                      |

---

## 7. Corrective Action

* Adjust ACLs using `setfacl`
* If using Ansible: update ACL tasks in corresponding playbook
* Document remediations in the audit log
* Notify affected department heads if group access changes

---

## 8. Related Documents

* [access-control-matrix.md](../access-control-matrix.md)
* [file-share-permissions.md](../file-share-permissions.md)
* [auditd-finance-rules.md](../../audit/auditd-finance-rules.md)
* [shared-services-policy.md](../../policy/shared-services-policy.md)

---

## 9. Review History

| Version | Date       | Reviewer            | Notes           |
| ------- | ---------- | ------------------- | --------------- |
| v1.0    | 2025-12-23 | IT Security Analyst | Initial Release |

---

## 10. Departmental Approval Checklist

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



