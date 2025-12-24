<!--
███████████████████████████████████████████████████████████████
  🧾 SMB Office IT Blueprint – Project Document
  Doc ID: POLICY-USER-ACCESS-001
  Author: IT Business Analyst, IT AD Architect
  Created: 2025-12-23
  Updated: 2025-12-23
  Version: v1.0
  Status: Draft
  Confidentiality: Internal
  Project Phase: Implementation
  Category: Policy – Security & Identity
  Audience: IT, HR, Department Managers
  Owners: IT AD Architect, Project Manager
  Reviewers: Project Doc Auditor, IT Security Analyst
  Tags: [access-control, user-accounts, ad-groups, roles]
  Data Sensitivity: High
  Compliance: Internal Security Policy
  Publish Target: Internal
  Summary: >
    This policy governs how user accounts are created, authorized, managed, and reviewed across the SMB Office environment. Access is assigned based on department, job function, and compliance with onboarding/offboarding procedures.
  Read Time: ~4 minutes
███████████████████████████████████████████████████████████████
-->

# 👤 User Access Policy

---

## 📍 Table of Contents

- [1. Purpose](#1-purpose)
- [2. Scope](#2-scope)
- [3. Access Control Principles](#3-access-control-principles)
- [4. Account Creation Workflow](#4-account-creation-workflow)
- [5. Group Membership Rules](#5-group-membership-rules)
- [6. Privileged Access Checkout](#6-privileged-access-checkout)
- [7. Account Review & Termination](#7-account-review--termination)
- [8. Policy Enforcement](#8-policy-enforcement)
- [9. Related Documents](#9-related-documents)
- [10. Review History](#10-review-history)
- [11. Departmental Approval Checklist](#11-departmental-approval-checklist)

---

## 1. Purpose

To define a consistent, secure, and auditable method of managing user access to systems, file shares, applications, and administrative functions within the simulated SMB office IT environment.

---

## 2. Scope

This policy applies to:
- All employees, interns, temps, and contractors
- Samba AD accounts and group assignments
- Linux system and application-level access
- Privileged access to secure or sensitive data (e.g., HR, Finance)

---

## 3. Access Control Principles

- Access is assigned **based on role**, not individual user discretion
- Access is **the minimum necessary** to perform job duties (least privilege)
- Departmental roles are tied to AD security groups (`GG-*`)
- No manual access assignment outside of standard workflows
- Shared accounts are prohibited unless explicitly documented

---

## 4. Account Creation Workflow

| Step | Owner         | Action                                                |
|------|---------------|--------------------------------------------------------|
| 1    | HR            | Submit onboarding request form                         |
| 2    | IT Admin      | Create user in Samba AD with unique UID                |
| 3    | IT Admin      | Assign to correct groups based on role and department  |
| 4    | System Script | Provision workstation access, printers, drives         |
| 5    | Manager       | Confirm access during onboarding day                   |

- Interns and Temps are assigned temporary accounts with **expiration dates**
- Executives and Managers receive an additional review from IT Security

---

## 5. Group Membership Rules

| Group Name         | Role Assigned         | Notes                          |
|--------------------|-----------------------|--------------------------------|
| `GG-HR`            | HR Staff              | Access to HR share and tools   |
| `GG-Finance`       | Finance Staff         | Access to payroll, invoices    |
| `GG-Prof`          | Professionals         | Client projects, shared tools  |
| `GG-IT`            | IT Administrators     | Admin tools, shell access      |
| `GG-AllStaff`      | All employees         | Common folders and printers    |
| `GG-Temp`          | Interns/Temps         | Time-limited access only       |

- Membership is reviewed monthly by the **IT AD Architect** and **HR**
- Changes outside of the onboarding workflow require **justification + audit**

---

## 6. Privileged Access Checkout

For certain protected resources (e.g., `finance-share`, `client legal docs`, admin utilities), a **privileged access checkout** is required:

- Admins must request time-limited access via the `admin-checkout-policy`
- Access is audited by `auditd`
- All elevation requests must be approved by the **Project Manager** or **IT Security Analyst**

---

## 7. Account Review & Termination

| Scenario         | Action Taken                                    |
|------------------|--------------------------------------------------|
| Employee leaves  | Account disabled within 1 business day          |
| Intern ends      | Auto-expire account + cleanup scripts           |
| Temp expires     | Manual review + access removal                  |
| Role change      | Old groups removed, new groups applied          |
| Audit trigger    | Immediate access review by Security             |

- Termination checklist must be completed by HR and IT
- File ownership and mailbox delegation handled per **offboarding policy**

---

## 8. Policy Enforcement

Violations include:
- Access without approval or documentation
- Group membership not matching job role
- Delayed account removals

⚠️ Violations may result in:
- Temporary access suspension
- Security incident escalation
- Managerial review and retraining

---

## 9. Related Documents

- [onboarding-workflow.md](../workflows/onboarding-workflow.md)
- [admin-checkout-policy.md](../policy/admin-checkout-policy.md)
- [access-control-matrix.md](access-control-matrix.md)
- [audit-log-policy.md](policy/security/audit-log-policy.md)

---

## 10. Review History

| Version | Date       | Reviewer            | Notes         |
|---------|------------|---------------------|---------------|
| v1.0    | 2025-12-23 | IT Security Analyst | Initial Draft |

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
