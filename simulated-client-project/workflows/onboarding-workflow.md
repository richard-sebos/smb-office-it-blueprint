<!--
███████████████████████████████████████████████████████████████
  🧾 SMB Office IT Blueprint – Project Document
  Doc ID: WORKFLOW-HR-ONBOARDING-001
  Author: HR Manager, IT Business Analyst
  Created: 2025-12-23
  Updated: 2025-12-23
  Version: v1.0
  Status: Approved
  Confidentiality: Restricted
  Project Phase: Implementation
  Category: Workflow Procedure
  Audience: Mixed
  Owners: HR Manager, IT Administrator
  Reviewers: Project Doc Auditor, IT Security Analyst
  Tags: [onboarding, hr, workflow, user-setup, automation]
  Data Sensitivity: Simulated Identity Data
  Compliance: Internal Policy + Data Privacy Best Practices
  Publish Target: Internal
  Summary: >
    Defines the complete onboarding workflow for new employees in the SMB Office environment, including HR steps, IT setup, AD group mapping, permissions provisioning, and first-day readiness checks.
  Read Time: ~7 min
███████████████████████████████████████████████████████████████
-->

# 👤 Employee Onboarding Workflow

---

## 📍 Table of Contents

- [1. Purpose](#1-purpose)
- [2. Scope](#2-scope)
- [3. Pre-Start Checklist](#3-pre-start-checklist)
- [4. Workflow Diagram](#4-workflow-diagram)
- [5. Departmental Responsibilities](#5-departmental-responsibilities)
- [6. Access Provisioning](#6-access-provisioning)
- [7. First-Day IT Readiness](#7-first-day-it-readiness)
- [8. Related Documents](#8-related-documents)
- [9. Review History](#9-review-history)
- [10. Departmental Approval Checklist](#10-departmental-approval-checklist)

---

## 1. Purpose

This document provides a structured onboarding process for new hires, ensuring each employee has the correct accounts, equipment, workspace, and access levels on Day 1. It aligns HR procedures with IT provisioning and documentation standards.

---

## 2. Scope

Applies to:
- All new employees, interns, temps, and contractors
- All departments
- Initial provisioning (first 14 days)
- Both physical and virtual onboarding

---

## 3. Pre-Start Checklist

| Task                              | Owner           | Due By     |
|----------------------------------|------------------|------------|
| Offer letter signed              | HR               | -7 days    |
| Start date confirmed             | HR               | -7 days    |
| AD user account created          | IT Admin         | -5 days    |
| Workstation assigned/prepped     | IT Admin         | -3 days    |
| Share & group access mapped      | IT + HR          | -2 days    |
| Email account configured         | IT Admin         | -2 days    |
| Office keycard / security badge  | HR / Facilities  | -1 day     |
| Welcome letter & HR packet       | HR               | -1 day     |

---

## 4. Workflow Diagram

```text
[HR: New Hire Form]
     ↓
[IT: User Created in AD + Email Setup]
     ↓
[IT: Assign Group Access + Folder Permissions]
     ↓
[IT: Configure Workstation + Login Test]
     ↓
[HR: Orientation Scheduled]
     ↓
[New Hire: Day 1 Checklist]
````

---

## 5. Departmental Responsibilities

### 🧑‍💼 HR Department

* Collects new hire data
* Completes onboarding form
* Coordinates with IT
* Delivers policy training and employee handbook

### 🖥️ IT Department

* Creates AD and email accounts
* Assigns role-based groups (HR, Finance, Projects)
* Prepares workstation or VDI
* Tests login, mapped drives, printer access

### 👨‍💼 Hiring Manager

* Defines role-based access needs
* Reviews first-day readiness
* Mentors new hire through first week

---

## 6. Access Provisioning

| Role             | Default Groups                | Shared Folders                    | Notes                             |
| ---------------- | ----------------------------- | --------------------------------- | --------------------------------- |
| Finance Manager  | `GG-Finance-Staff`, `GG-Exec` | `\\files01\department\finance`    | Payroll and reporting access      |
| HR Manager       | `GG-HR-Staff`, `GG-Exec`      | `\\files01\department\hr`         | Access to personnel records       |
| Admin Assistant  | `GG-Company-Docs`             | `\\files01\shared\company`        | Calendar + support duties         |
| Jr. Professional | `GG-Project-Staff`            | `\\files01\projects\deliverables` | Assigned per project              |
| Intern / Temp    | `GG-Interns`                  | `\\files01\interns\working`       | Time-limited access (auto expire) |

> 🔐 For access to **client files** or **executive content**, an **IT Admin checkout process** is required (see: [access-control-matrix.md](../security/access-control-matrix.md)).

---

## 7. First-Day IT Readiness

| Task                                   | Completed By |
| -------------------------------------- | ------------ |
| Login to workstation                   | IT Support   |
| Test mapped network drives             | IT Support   |
| Access to email + calendar             | New Hire     |
| Shared printer access                  | IT Support   |
| VPN or remote access setup (if needed) | IT Support   |
| Password policy & MFA reviewed         | HR / IT      |

---

## 8. Related Documents

* [file-share-permissions.md](../security/file-share-permissions.md)
* [access-control-matrix.md](../security/access-control-matrix.md)
* [hr-data-retention-policy.md](../policy/hr-data-retention-policy.md)

---

## 9. Review History

| Version | Date       | Reviewer   | Notes         |
| ------- | ---------- | ---------- | ------------- |
| v1.0    | 2025-12-23 | HR Manager | Initial Draft |

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

