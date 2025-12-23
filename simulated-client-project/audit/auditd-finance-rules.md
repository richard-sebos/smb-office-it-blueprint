<!--
███████████████████████████████████████████████████████████████
  🧾 SMB Office IT Blueprint – Project Document
  Doc ID: SECURITY-AUDITD-FIN-001
  Author: IT Security Analyst
  Created: 2025-12-23
  Updated: 2025-12-23
  Version: v1.0
  Status: Draft
  Confidentiality: Confidential
  Project Phase: Implementation
  Category: Security Policy
  Audience: IT
  Owners: IT Security Analyst, Linux Admin/Architect
  Reviewers: Project Doc Auditor, IT AD Architect
  Tags: [auditd, finance, monitoring, security, logging, compliance]
  Data Sensitivity: Simulated – Treat as Sensitive
  Compliance: Internal Security Controls
  Publish Target: Internal (Encrypted Repo Area)
  Summary: >
    Defines the Linux auditd rules applied to file shares, logs, and resources used by the Finance Department. Ensures file access is monitored, logged, and alertable under internal compliance policies.
  Read Time: ~7 min
███████████████████████████████████████████████████████████████
-->

# 🧾 `auditd` Rules – Finance Department Monitoring

---

## 📍 Table of Contents

- [1. Purpose](#1-purpose)
- [2. Scope](#2-scope)
- [3. Audit Strategy Overview](#3-audit-strategy-overview)
- [4. Directory Watch Rules](#4-directory-watch-rules)
- [5. Executable Monitoring](#5-executable-monitoring)
- [6. User-Level Audit Rules](#6-user-level-audit-rules)
- [7. Log Retention & Rotation](#7-log-retention--rotation)
- [8. Alerting & Incident Escalation](#8-alerting--incident-escalation)
- [9. Related Files](#9-related-files)
- [10. Review History](#10-review-history)
- [11. Departmental Approval Checklist](#11-departmental-approval-checklist)

---

## 1. Purpose

This document defines the `auditd` configuration used to monitor file access, permission changes, and executable usage in Finance-controlled file shares and systems. It supports internal compliance and potential incident investigation.

---

## 2. Scope

Applies to:
- `files01` – Samba file server
- `finance-ws01` – Finance Manager workstation
- `log01` – Remote syslog/audit collector

---

## 3. Audit Strategy Overview

| Audit Target             | Method               | Goal                          |
|--------------------------|----------------------|-------------------------------|
| Finance file shares      | `-w` directory watch | Monitor access attempts       |
| Key executables (scp, cp)| `-a` syscall audit   | Log data exfil/infil tools    |
| User logins (finance)    | `-a` login tracking  | Detect off-hours access       |

Audit logs are forwarded to `log01` via `rsyslog` and rotated weekly.

---

## 4. Directory Watch Rules

Located in: `/etc/audit/rules.d/finance.rules`

```bash
# Finance Share Directory Access
-w /srv/shares/finance/invoices     -p rwa -k finance_invoices
-w /srv/shares/finance/payroll      -p rwa -k finance_payroll
-w /srv/shares/finance/budgets      -p rwa -k finance_budgets
-w /srv/shares/finance/exports      -p rwa -k finance_exports
````

| Key Name           | Description                       |
| ------------------ | --------------------------------- |
| `finance_invoices` | Track invoice reads/writes        |
| `finance_payroll`  | Monitor payroll report access     |
| `finance_budgets`  | Watch budget docs for changes     |
| `finance_exports`  | Watch for sensitive Excel exports |

---

## 5. Executable Monitoring

```bash
# Monitor Data Transfer Utilities
-a always,exit -F path=/usr/bin/scp -F perm=x -F auid>=1000 -F auid!=unset -k finance_tools
-a always,exit -F path=/usr/bin/rsync -F perm=x -F auid>=1000 -F auid!=unset -k finance_tools
-a always,exit -F path=/bin/cp    -F perm=x -F auid>=1000 -F auid!=unset -k finance_tools
```

These rules:

* Track use of copy/transfer tools by domain users
* Ignore system/background (UID < 1000) tasks

---

## 6. User-Level Audit Rules

### Finance Manager Login Tracking

```bash
# Track login events for finance manager
-a always,exit -F arch=b64 -S execve -F uid=10010 -k finance_login
```

> Replace `10010` with the actual UID of the Finance Manager (e.g., from `id finance.mgr`)

You may also configure PAM module tracking with:

```bash
session required pam_tty_audit.so enable=always
```

---

## 7. Log Retention & Rotation

* Audit logs: `/var/log/audit/audit.log`
* Rotated via: `logrotate.d/audit`
* Retention: 90 days (disk) + offloaded to `log01` weekly
* Format: RAW and JSON (simulated for Splunk-style search)

---

## 8. Alerting & Incident Escalation

Alerts are triggered on:

* Access to payroll folder by unauthorized group
* Use of `scp` by non-technical roles
* After-hours file access (simulated time window: 20:00–06:00)

Escalation:

1. Alert generated (Email/Syslog)
2. Reviewed by **IT Security Analyst**
3. Escalated to **Finance Manager** and **Managing Partner** (if needed)

---

## 9. Related Files

* [file-share-permissions.md](../../simulated-client-project/security/file-share-permissions.md)
* [finance-department-policy.md](../../simulated-client-project/policy/finance-department-policy.md)
* [auditd-general-config.md](./auditd-general-config.md)
* [git-crypt-encryption-policy.md](../encryption/git-crypt-encryption-policy.md)

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


