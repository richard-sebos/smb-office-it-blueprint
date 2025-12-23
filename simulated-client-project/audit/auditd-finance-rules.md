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
