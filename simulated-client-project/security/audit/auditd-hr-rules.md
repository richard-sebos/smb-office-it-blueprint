<!--
███████████████████████████████████████████████████████████████
  🧾 SMB Office IT Blueprint – Project Document
  Doc ID: SECURITY-AUDITD-HR-001
  Author: IT Security Analyst, HR Manager
  Created: 2025-12-23
  Updated: 2025-12-23
  Version: v1.0
  Status: Draft
  Confidentiality: Confidential
  Project Phase: Implementation
  Category: Security – Auditing
  Audience: IT Security, Linux Admins, HR
  Owners: IT Security Analyst, Linux Admin/Architect
  Reviewers: Project Doc Auditor, HR Manager
  Tags: [auditd, hr, security, logging, linux, access-monitoring]
  Data Sensitivity: High (HR Data)
  Compliance: Internal Security Policy
  Publish Target: Internal
  Summary: >
    Defines the `auditd` monitoring rules for HR-related data directories to track access, changes, and deletion of employee records, evaluations, and onboarding documents. Supports compliance and internal investigation capabilities.
  Read Time: ~5 minutes
███████████████████████████████████████████████████████████████
-->

# 🛡️ `auditd` Rules – HR Department Monitoring

---

## 📍 Table of Contents

- [1. Purpose](#1-purpose)
- [2. Scope](#2-scope)
- [3. Targeted Paths](#3-targeted-paths)
- [4. Audit Rule Examples](#4-audit-rule-examples)
- [5. Logging & Reporting](#5-logging--reporting)
- [6. Optional Alerts & Integrations](#6-optional-alerts--integrations)
- [7. Maintenance Tasks](#7-maintenance-tasks)
- [8. Related Documents](#8-related-documents)
- [9. Review History](#9-review-history)
- [10. Departmental Approval Checklist](#10-departmental-approval-checklist)

---

## 1. Purpose

To monitor all access and changes to **sensitive HR files and directories** using `auditd`, enabling traceability and visibility for internal audits, data protection enforcement, and incident response.

---

## 2. Scope

Applies to the following:
- HR Samba share: `/srv/shares/HR/`
- Employee records (PDFs, docs)
- Onboarding checklists
- Disciplinary or performance evaluations
- Access by users in `GG-HR-*` groups or privileged administrators

---

## 3. Targeted Paths

| Target Path                | Description                          |
|----------------------------|--------------------------------------|
| `/srv/shares/HR/`          | Root of HR file share                |
| `/srv/shares/HR/Onboarding/` | New hire and intern documents      |
| `/srv/shares/HR/Evaluations/` | Performance review records        |
| `/srv/shares/HR/Personnel/`   | Employee file archive             |

---

## 4. Audit Rule Examples

Rules should be placed in `/etc/audit/rules.d/hr.rules`.

### 🗂️ Access Tracking

```bash
-w /srv/shares/HR/ -p rwa -k hr_access
-w /srv/shares/HR/Personnel/ -p rwa -k hr_personnel
-w /srv/shares/HR/Evaluations/ -p rwa -k hr_eval
````

### 🧨 File Deletion and Permission Changes

```bash
-a always,exit -F arch=b64 -S unlink -F dir=/srv/shares/HR/ -F auid>=1000 -F auid!=4294967295 -k hr_delete
-a always,exit -F arch=b64 -S chmod -F dir=/srv/shares/HR/ -F auid>=1000 -F auid!=4294967295 -k hr_chmod
-a always,exit -F arch=b64 -S chown -F dir=/srv/shares/HR/ -F auid>=1000 -F auid!=4294967295 -k hr_chown
```

> 🔐 These rules apply to **all users** with UID ≥1000, excluding system accounts.

---

## 5. Logging & Reporting

| Action                   | Frequency | Responsible Agent       |
| ------------------------ | --------- | ----------------------- |
| `ausearch -k hr_access`  | Weekly    | IT Security Analyst     |
| Monthly audit log export | Monthly   | Linux Admin             |
| HR Data Access Report    | Quarterly | HR Manager, IT Security |

### Common Commands

```bash
ausearch -k hr_access
aureport --file --summary | grep HR
ausearch -k hr_delete | aureport -f
```

---

## 6. Optional Alerts & Integrations

* `auditd → rsyslog → Email alert` for unauthorized access
* Consider tying to `fail2ban` or `Wazuh` if integrated
* Threshold alerting: more than 5 file changes in 5 minutes

---

## 7. Maintenance Tasks

| Task                              | Interval  | Responsible  |
| --------------------------------- | --------- | ------------ |
| Verify audit rules loaded at boot | Monthly   | Linux Admin  |
| Test audit rule coverage          | Quarterly | IT Security  |
| Rotate logs via logrotate         | Weekly    | System Cron  |
| Purge logs older than 90 days     | Monthly   | System Admin |

---

## 8. Related Documents

* [hr-data-retention-policy.md](../../policy/hr-data-retention-policy.md)
* [user-access-policy.md](../../policy/user-access-policy.md)
* [file-permissions-audit.md](./file-permissions-audit.md)
* [auditd-finance-rules.md](,,/../auditd-finance-rules.md)

---

## 9. Review History

| Version | Date       | Reviewer    | Notes         |
| ------- | ---------- | ----------- | ------------- |
| v1.0    | 2025-12-23 | HR Manager  | Initial draft |
| v1.0    | 2025-12-23 | IT Security | Added rules   |

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

