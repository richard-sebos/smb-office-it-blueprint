<!--
███████████████████████████████████████████████████████████████
  🧾 SMB Office IT Blueprint – Project Document
  Doc ID: POLICY-PRINT-ACCESS-001
  Author: IT AD Architect, IT Business Analyst
  Created: 2025-12-23
  Updated: 2025-12-23
  Version: v1.0
  Status: Draft
  Confidentiality: Internal
  Project Phase: Implementation
  Category: Policy – IT & Infrastructure
  Audience: IT, Department Managers
  Owners: IT AD Architect, Linux Admin/Architect
  Reviewers: Project Doc Auditor, HR Manager
  Tags: [printers, access, cups, samba, group-policy]
  Data Sensitivity: Medium
  Compliance: Internal IT Policy
  Publish Target: Internal
  Summary: >
    Defines group-based access, deployment methods, and audit controls for shared network printers within the simulated office environment using Samba AD and CUPS.
  Read Time: ~3 minutes
███████████████████████████████████████████████████████████████
-->

# 🖨️ Printer Access Policy

---

## 📍 Table of Contents

- [1. Purpose](#1-purpose)
- [2. Scope](#2-scope)
- [3. Access Control Principles](#3-access-control-principles)
- [4. Printer Group Structure](#4-printer-group-structure)
- [5. Deployment Methods](#5-deployment-methods)
- [6. Special Access Cases](#6-special-access-cases)
- [7. Logging & Auditing](#7-logging--auditing)
- [8. Printer Naming Convention](#8-printer-naming-convention)
- [9. Related Documents](#9-related-documents)
- [10. Review History](#10-review-history)
- [11. Departmental Approval Checklist](#11-departmental-approval-checklist)

---

## 1. Purpose

To define standardized access control, deployment, and security for all networked printers managed within the SMB Office environment using **Samba Active Directory** and **CUPS (Common UNIX Printing System)**.

---

## 2. Scope

Applies to:
- All network printers hosted on `print01`
- Printer queues deployed via CUPS and Group Policy
- All AD-integrated workstations
- Department-based printer access

---

## 3. Access Control Principles

- All printer access must be assigned **by group membership**.
- No user may install or access printers manually.
- Printer usage is **restricted to authorized departments**.
- Color printing, scan-to-email, and fax are **disabled by default** unless explicitly approved.

---

## 4. Printer Group Structure

Each department-specific printer is mapped to an AD security group:

| Printer Name       | AD Group                | Access Level |
|--------------------|-------------------------|--------------|
| `hr-printer-01`    | `GG-Print-HR`           | Print Only   |
| `finance-print-01` | `GG-Print-Finance`      | Print/Scan   |
| `common-bw-01`     | `GG-Print-AllStaff`     | Print Only   |

- Group membership is managed by the **IT AD Architect** and **Department Managers**.
- Printers are deployed to users at login via **GPO or script** based on group membership.

---

## 5. Deployment Methods

- Printers are provisioned using **Group Policy Preferences** or Ansible automation.
- End-user systems must not have local admin rights to manually add or remove printers.
- Printer availability is refreshed at logon and enforced via **SSSD (Linux)** or GPO (Windows).

---

## 6. Special Access Cases

| Scenario                        | Policy Requirement                      |
|----------------------------------|------------------------------------------|
| Temporary staff printing         | Add to group via onboarding workflow     |
| Executive assistant printing     | May be added to multiple printer groups  |
| Large print jobs                 | Routed to department-managed print queue |
| Color printing                   | Requires documented business case        |

---

## 7. Logging & Auditing

- Printer logs are enabled on the CUPS server (`/var/log/cups/page_log`)
- Logs include: user, file name, time, page count
- Logs are retained for **180 days**
- Periodic reviews are performed quarterly by the **IT Security Analyst**

---

## 8. Printer Naming Convention

```text
[department]-printer-[NN]
````

* `hr-printer-01`
* `common-bw-01`
* `prof-print-02`

---

## 9. Related Documents

* [group-policy-baseline.md](group-policy-baseline.md)
* [user-access-policy.md](../security/user-access-policy.md)
* [admin-checkout-policy.md](../security/admin-checkout-policy.md)
* [onboarding-workflow.md](../hr/onboarding-workflow.md)

---

## 10. Review History

| Version | Date       | Reviewer        | Notes         |
| ------- | ---------- | --------------- | ------------- |
| v1.0    | 2025-12-23 | IT AD Architect | Initial Draft |

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

