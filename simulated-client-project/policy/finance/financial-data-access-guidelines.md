<!--
███████████████████████████████████████████████████████████████
  🧾 SMB Office IT Blueprint – Project Document
  Doc ID: POLICY-FIN-DATA-ACCESS-001
  Author: IT Security Analyst, Finance Manager
  Created: 2025-12-23
  Updated: 2025-12-23
  Version: v1.0
  Status: Draft
  Confidentiality: Confidential
  Project Phase: Implementation
  Category: Policy – Data Access
  Audience: Finance, IT
  Owners: Finance Manager, IT Security Analyst
  Reviewers: Project Doc Auditor, Project Manager
  Tags: [finance, access control, permissions, samba, security]
  Data Sensitivity: High (Confidential Financial Data)
  Compliance: Internal RBAC + Audit Requirements
  Publish Target: Internal
  Summary: >
    Defines who may access financial data, how access is granted or revoked, and what technical and procedural controls are in place. Supports enforcement of compliance and data protection strategies across the simulated SMB office.
  Read Time: ~5 min
███████████████████████████████████████████████████████████████
-->

# 💰 Financial Data Access Guidelines

---

## 📍 Table of Contents

- [1. Purpose](#1-purpose)
- [2. Scope](#2-scope)
- [3. Access Classification](#3-access-classification)
- [4. Authorized Roles](#4-authorized-roles)
- [5. Request and Approval Process](#5-request-and-approval-process)
- [6. Technical Controls](#6-technical-controls)
- [7. Auditing and Monitoring](#7-auditing-and-monitoring)
- [8. Violations and Enforcement](#8-violations-and-enforcement)
- [9. Related Documents](#9-related-documents)
- [10. Review History](#10-review-history)
- [11. Departmental Approval Checklist](#11-departmental-approval-checklist)

---

## 1. Purpose

To protect sensitive financial records, reports, and systems by restricting access based on role, sensitivity level, and business need. This ensures compliance with internal policies and reduces exposure to unauthorized access or misuse.

---

## 2. Scope

This policy applies to:
- All users accessing files in `\\files01\finance` and subfolders
- Samba AD access groups: `GG-Finance-Staff`, `GG-Finance-Managers`, `GG-Exec`
- Any user accessing budget data, payroll exports, expense reports, or PII

---

## 3. Access Classification

| Classification        | Description                                      | Access Level             |
|------------------------|--------------------------------------------------|--------------------------|
| **Public Finance Data** | Internal reports (read-only) for exec review    | GG-Exec (read-only)      |
| **Departmental Data**  | Working files, forecasts, AP/AR spreadsheets     | GG-Finance-Staff         |
| **Sensitive Financials** | Payroll, client billing, budget allocations     | GG-Finance-Managers only |
| **Audit Logs**         | Access logs, auditd reports, traceability data   | IT Security Analyst      |

---

## 4. Authorized Roles

| Role                | Access Areas                          | Notes                             |
|---------------------|----------------------------------------|------------------------------------|
| Finance Staff        | `/finance/reports`, `/finance/ops`     | Read/write                         |
| Finance Managers     | Full `/finance`, incl. payroll         | Elevated group                     |
| Executive Team       | `/finance/exports`, `/finance/summaries` | Read-only (via GPO mapped drives)  |
| IT Security Analyst  | Audit logs and permission review       | No access to data content          |
| Admin (checkout)     | Temporary via [admin-checkout-policy.md](../admin-checkout-policy.md) | Logged + monitored |

---

## 5. Request and Approval Process

1. **User submits request** to their manager and IT Security via ticket/email
2. **Finance Manager approval required** for all elevated access
3. **IT AD Architect grants membership** to appropriate AD security group
4. **Access logs updated** (manual or Ansible-integrated)
5. **Review every 90 days** as part of access audit cycle

---

## 6. Technical Controls

- All access controlled via **Samba AD security groups**
- Shares hosted on `files01` using **POSIX ACLs**
- Shares defined in `/etc/samba/smb.conf` under `[finance]`
- **auditd rules** applied for all read/write access to `/srv/finance`
- Optional **SELinux enforcement** for `finance_t` context (see `selinux-policy.md`)
- GPO-based drive mapping to control access visibility

---

## 7. Auditing and Monitoring

| Control                      | Description                              |
|------------------------------|------------------------------------------|
| `auditd-finance-rules.md`    | Defines real-time audit for file access  |
| `admin-checkout-policy.md`   | Logs any elevated admin access           |
| `file-permissions-audit.md`  | Reviewed monthly                         |
| `access-control-matrix.md`   | Role-to-resource mapping review          |
| `auditd` log forwarding      | Logs exported to syslog / SIEM endpoint  |

---

## 8. Violations and Enforcement

- Unauthorized access attempts will trigger alerts via auditd
- Incidents reviewed by IT Security and Finance Manager
- Admins violating checkout rules will be reviewed by Project Doc Auditor
- Persistent violations may result in revocation of access privileges

---

## 9. Related Documents

- [admin-checkout-policy.md](../admin-checkout-policy.md)
- [auditd-finance-rules.md](../audit/auditd-finance-rules.md)
- [file-share-permissions.md](../../security/file-share-permissions.md)
- [access-control-matrix.md](../../security/access-control-matrix.md)
- [group-policy-baseline.md](../../policy/group-policy-baseline.md)

---

## 10. Review History

| Version | Date       | Reviewer           | Notes              |
|---------|------------|--------------------|---------------------|
| v1.0    | 2025-12-23 | Finance Manager    | Initial draft       |
|         |            | IT Security Analyst| Policy alignment    |

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

