<!--
███████████████████████████████████████████████████████████████
  🧾 SMB Office IT Blueprint – Project Document
  Doc ID: POLICY-USER-ACCESS-001
  Author: IT Security Analyst, IT Business Analyst
  Created: 2025-12-23
  Updated: 2025-12-23
  Version: v1.0
  Status: Final
  Confidentiality: Internal
  Project Phase: Implementation
  Category: Policy – Access Control
  Audience: Mixed
  Owners: IT Security Analyst, IT AD Architect
  Reviewers: Project Doc Auditor, Project Manager
  Tags: [access, permissions, roles, AD, security, policy]
  Data Sensitivity: Simulated Access Control Framework
  Compliance: Internal Policy, Role-Based Access Control (RBAC)
  Publish Target: Internal
  Summary: >
    This document defines the access control policy for user accounts, roles, and data access within the simulated SMB Office environment. It outlines user role tiers, approval workflows, and privileged access rules.
  Read Time: ~6 min
███████████████████████████████████████████████████████████████
-->

# 🔐 User Access Control Policy

---

## 📍 Table of Contents

- [1. Purpose](#1-purpose)
- [2. Scope](#2-scope)
- [3. Access Management Principles](#3-access-management-principles)
- [4. Role-Based Access Matrix](#4-role-based-access-matrix)
- [5. Privileged Access & Checkout Process](#5-privileged-access--checkout-process)
- [6. User Account Lifecycle](#6-user-account-lifecycle)
- [7. Responsibilities](#7-responsibilities)
- [8. Enforcement](#8-enforcement)
- [9. Related Documents](#9-related-documents)
- [10. Review History](#10-review-history)
- [11. Departmental Approval Checklist](#11-departmental-approval-checklist)

---

## 1. Purpose

To establish consistent and secure user access control practices across all departments, systems, and file shares. This policy defines how access is granted, reviewed, modified, and revoked.

---

## 2. Scope

Covers:
- Active Directory accounts
- Samba file shares and ACLs
- Local Linux system access
- Shared printers, folders, and admin consoles
- All permanent, contract, and temporary staff

---

## 3. Access Management Principles

- **Least Privilege:** Access is granted only to what is strictly needed.
- **Role-Based:** Mapped to the employee’s job function.
- **Auditable:** Access changes must be logged.
- **Revocable:** All access can be removed promptly upon exit.
- **Time-bound:** Interns and temps have expiration timers on access.

---

## 4. Role-Based Access Matrix (Summary)

| Role                  | AD Groups                | Access Areas                                  |
|-----------------------|--------------------------|-----------------------------------------------|
| HR Manager            | `GG-HR-Staff`            | HR folders, Onboarding forms, Performance data |
| Finance Manager       | `GG-Finance-Staff`       | Finance share, Payroll, Reporting tools       |
| Admin Assistant       | `GG-Company-Docs`        | Shared documents, Printer group               |
| Junior Professional   | `GG-Project-Staff`       | Project folders, department templates         |
| Senior Professional   | `GG-Project-Leads`       | All project folders, reports, escalation tools |
| IT Administrator      | `GG-IT-Admins`           | All systems (monitored + logged)              |
| Intern / Temp         | `GG-Interns`             | Intern share (auto-expire in 90 days)         |

📄 Full mapping: [access-control-matrix.md](../security/access-control-matrix.md)

---

## 5. Privileged Access & Checkout Process

Access to **sensitive resources** (e.g., executive files, client deliverables, finance exports) must follow a **checkout process**:

### Request Flow:
1. Request submitted by department lead via ticket or form
2. Reviewed by IT Admin or Security Analyst
3. Time-bound access is granted (typically 24–72 hrs)
4. Access logged in audit system
5. Auto-revoke script runs hourly (Ansible or cron-based)

---

## 6. User Account Lifecycle

| Stage          | Action                                             |
|----------------|----------------------------------------------------|
| Onboarding     | Created via [onboarding-workflow.md](../workflows/onboarding-workflow.md) |
| Transfers      | Role updated, access re-evaluated                  |
| Termination    | AD account disabled, access revoked within 2 hrs   |
| Temp Expiry    | Auto-disabling after predefined access period      |
| Audit          | Access rights reviewed quarterly (by IT Security) |

---

## 7. Responsibilities

| Role              | Responsibility                                       |
|-------------------|------------------------------------------------------|
| HR Manager        | Ensure job role is clear for access mapping          |
| Hiring Manager    | Specify data/resource access on Day 1                |
| IT Administrator  | Implement AD, file, and system access policies       |
| Security Analyst  | Log access changes, monitor privileged access        |
| Project Doc Auditor | Confirm documentation exists for special cases     |

---

## 8. Enforcement

- All unauthorized access attempts are logged via **auditd**
- Violations may result in disciplinary review (simulated)
- Access is disabled immediately in the event of a security concern
- IT reserves the right to temporarily suspend access pending review

---

## 9. Related Documents

- [file-share-permissions.md](../security/file-share-permissions.md)
- [access-control-matrix.md](../security/access-control-matrix.md)
- [onboarding-workflow.md](../workflows/onboarding-workflow.md)
- [hr-data-retention-policy.md](../policy/hr-data-retention-policy.md)
- [executive-security-policy.md](../policy/executive-security-policy.md)

---

## 10. Review History

| Version | Date       | Reviewer          | Notes               |
|---------|------------|-------------------|---------------------|
| v1.0    | 2025-12-23 | IT Business Analyst | Initial Release    |

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
