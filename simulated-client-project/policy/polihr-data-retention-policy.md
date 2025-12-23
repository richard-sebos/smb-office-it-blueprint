<!--
███████████████████████████████████████████████████████████████
  🧾 SMB Office IT Blueprint – Project Document
  Doc ID: POLICY-HR-RETENTION-001
  Author: IT Business Analyst
  Created: 2025-12-23
  Updated: 2025-12-23
  Version: v1.0
  Status: Draft
  Confidentiality: Restricted
  Project Phase: Planning
  Category: Data Retention Policy
  Audience: Mixed
  Owners: HR Manager, IT Security Analyst
  Reviewers: Project Doc Auditor, Linux Admin/Architect
  Tags: [hr, data retention, policy, compliance, legal]
  Data Sensitivity: High – Contains Personal & Employment Records
  Compliance: Internal HR Policy (Simulated); US SMB Best Practices
  Publish Target: Internal (Simulated Environment)
  Summary: >
    Defines the data retention standards for HR-related records in the SMB Office IT Blueprint simulation, covering hiring documents, employee records, compliance documents, and deletion policies.
  Read Time: ~6 min
███████████████████████████████████████████████████████████████
-->

# 🧑‍💼 HR Data Retention Policy

---

## 📍 Table of Contents

- [1. Purpose](#1-purpose)
- [2. Scope](#2-scope)
- [3. Classification of HR Records](#3-classification-of-hr-records)
- [4. Retention Schedule](#4-retention-schedule)
- [5. Data Storage Locations](#5-data-storage-locations)
- [6. Secure Deletion Procedures](#6-secure-deletion-procedures)
- [7. Backup Policy](#7-backup-policy)
- [8. Roles & Responsibilities](#8-roles--responsibilities)
- [9. Related Documents](#9-related-documents)
- [10. Review History](#10-review-history)
- [11. Departmental Approval Checklist](#11-departmental-approval-checklist)

---

## 1. Purpose

This policy outlines how HR-related data is retained, archived, and securely deleted in compliance with simulated business requirements. The goal is to reduce liability, meet legal expectations, and minimize exposure of personal employee information.

---

## 2. Scope

Applies to all HR-related files, both physical and digital, including:
- Personnel records
- Employment contracts
- Performance reviews
- Disciplinary actions
- Interview documentation
- Payroll records (co-owned with Finance)

---

## 3. Classification of HR Records

| Record Type                 | Sensitivity Level | Access Group         |
|----------------------------|-------------------|----------------------|
| Employment Agreements      | Confidential      | HR Manager           |
| Resumes & Interview Notes  | Restricted        | HR Staff             |
| Performance Reviews        | Confidential      | HR Manager, Execs    |
| Disciplinary Records       | Confidential      | HR Manager, Legal    |
| Exit Interviews            | Restricted        | HR Staff             |
| Background Checks          | Confidential      | HR Manager           |

---

## 4. Retention Schedule

| Record Type                 | Retention Period   | Final Action           |
|----------------------------|--------------------|------------------------|
| Employment Agreements      | 7 years post-exit  | Secure Delete          |
| Payroll Records            | 7 years            | Archival (Finance)     |
| Resumes (Unhired)          | 1 year             | Auto-purge             |
| Interview Notes            | 1 year             | Secure Delete          |
| Performance Reviews        | 3 years post-exit  | Secure Archive         |
| Disciplinary Records       | 5 years post-exit  | Secure Delete          |
| Exit Interviews            | 3 years            | Secure Delete          |

Retention periods are based on **simulated US SMB practices** and can be adapted for regulatory jurisdictions.

---

## 5. Data Storage Locations

| Record Type               | File Share Location              | Notes                             |
|---------------------------|----------------------------------|-----------------------------------|
| General HR Records        | `\\files01\department\hr`        | ACL-controlled, encrypted backup  |
| Performance Reviews       | `\\files01\department\hr\reviews`| Separate folder, limited access   |
| Payroll Coordination      | `\\files01\department\finance`   | Shared with Finance via ACL       |
| Archived HR Data          | `/srv/hr/archives` (on `files01`)| Mounted, encrypted ZFS volume     |

---

## 6. Secure Deletion Procedures

All deletions of sensitive data must be handled using secure deletion methods.

- CLI Secure Delete: `shred -u -n 3 -z <filename>`
- GUI interface for Windows domain users must use **“Secure Remove”** shortcut (simulated)
- Auditd will track delete operations under `/srv/shares/department/hr/*`

Automated retention cleanup is scheduled monthly via cron.

---

## 7. Backup Policy

| Backup Type      | Frequency | Retention | Location     |
|------------------|-----------|-----------|--------------|
| HR Shares        | Daily     | 30 Days   | ZFS snapshots|
| Offsite Archives | Weekly    | 12 Weeks  | Encrypted S3 |
| Payroll Data     | Shared    | Per Finance Policy |

Backups are encrypted using **restic** and stored in the **encrypted backup vault**. Access restricted to **Linux Admins** and the **HR Manager**.

---

## 8. Roles & Responsibilities

| Role             | Responsibility                             |
|------------------|---------------------------------------------|
| HR Manager       | Enforces retention, signs off on deletions  |
| IT Security Analyst | Audits logs and deletion compliance      |
| Linux Admin      | Maintains automated cleanup and backups     |
| Project Doc Auditor | Ensures policy documents are aligned     |

---

## 9. Related Documents

- [hr-manager-use-case.md](../use-cases/hr-manager.md)
- [file-share-permissions.md](../security/file-share-permissions.md)
- [auditd-hr-rules.md](../../implementation/security/auditd/auditd-hr-rules.md)
- [shared-services-policy.md](./shared-services-policy.md)
- [access-control-matrix.md](../security/access-control-matrix.md)

---

## 10. Review History

| Version | Date       | Reviewer        | Notes            |
|---------|------------|------------------|------------------|
| v1.0    | 2025-12-23 | IT Business Analyst | Initial Draft |

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

