<!--
███████████████████████████████████████████████████████████████
  🧾 SMB Office IT Blueprint – Project Document
  Doc ID: CHECKLIST-HR-INTERN-001
  Author: HR Manager, IT Business Analyst
  Created: 2025-12-23
  Updated: 2025-12-23
  Version: v1.0
  Status: Final
  Confidentiality: Internal
  Project Phase: Implementation
  Category: Workflow Checklist
  Audience: HR, IT
  Owners: HR Manager, IT Administrator
  Reviewers: Project Doc Auditor, IT Security Analyst
  Tags: [onboarding, interns, checklist, temp-access, HR]
  Data Sensitivity: Simulated Identity Data
  Compliance: Internal Policy
  Publish Target: Internal
  Summary: >
    Standard checklist used by HR and IT to onboard interns or temporary staff, ensuring access is limited, expiring, and auditable in accordance with company policy.
  Read Time: ~4 min
███████████████████████████████████████████████████████████████
-->

# 📝 Intern / Temp Onboarding Checklist

---

## 📍 Table of Contents

- [1. Purpose](#1-purpose)
- [2. Scope](#2-scope)
- [3. Required Actions](#3-required-actions)
- [4. IT Provisioning Tasks](#4-it-provisioning-tasks)
- [5. HR Orientation Tasks](#5-hr-orientation-tasks)
- [6. Security Notes](#6-security-notes)
- [7. Related Documents](#7-related-documents)
- [8. Review History](#8-review-history)
- [9. Departmental Approval Checklist](#9-departmental-approval-checklist)

---

## 1. Purpose

To ensure that all interns and temporary employees are provisioned with appropriate access, receive the necessary orientation, and are properly deprovisioned at the end of their engagement.

---

## 2. Scope

This checklist applies to:
- Interns (seasonal, student)
- Temporary contractors (short-term)
- Support roles requiring limited access
- Applies to remote and in-office hires

---

## 3. Required Actions

| Task Description                            | Responsible | Due Date | Completed |
|---------------------------------------------|-------------|----------|-----------|
| HR receives signed internship agreement      | HR          | -7 days  | [ ]       |
| Confirm start and end dates                  | HR          | -7 days  | [ ]       |
| Create AD account under `OU=Interns`         | IT Admin    | -5 days  | [ ]       |
| Assign to group `GG-Interns`                 | IT Admin    | -5 days  | [ ]       |
| Set account expiration date                  | IT Admin    | -5 days  | [ ]       |
| Configure email account                      | IT Admin    | -4 days  | [ ]       |
| Assign workstation or VDI                    | IT Admin    | -3 days  | [ ]       |
| Provide intern handbook                      | HR          | -2 days  | [ ]       |
| Schedule orientation meeting                 | HR          | -2 days  | [ ]       |
| Notify hiring manager                        | HR          | -2 days  | [ ]       |

---

## 4. IT Provisioning Tasks

| Item                                        | Status  |
|---------------------------------------------|---------|
| Account created in AD (`OU=Interns`)         | [ ]     |
| Group: `GG-Interns` assigned                 | [ ]     |
| Samba share access: `/srv/shares/interns/`  | [ ]     |
| Email / calendar access set up              | [ ]     |
| VPN (if needed) configured                   | [ ]     |
| Expiration policy enforced (90 days max)    | [ ]     |
| Login tested + password policy explained    | [ ]     |

---

## 5. HR Orientation Tasks

| Item                                         | Status  |
|----------------------------------------------|---------|
| Review intern responsibilities               | [ ]     |
| Walkthrough of shared folder structure       | [ ]     |
| Code of conduct acknowledged                 | [ ]     |
| Time tracking process explained              | [ ]     |
| End-of-internship feedback form sent         | [ ]     |
| Exit checklist prepared                      | [ ]     |

---

## 6. Security Notes

- **Access is temporary and automatically expires.**
- **No access to confidential HR or Finance data.**
- **Interns are subject to audit logging via `auditd`.**
- **Violation of access policy results in immediate deactivation.**

---

## 7. Related Documents

- [onboarding-workflow.md](onboarding-workflow.md)
- [user-access-policy.md](../policy/user-access-policy.md)
- [file-share-permissions.md](../security/file-share-permissions.md)
- [intern-use-case.md](../use-cases/intern.md)
- [access-control-matrix.md](../security/access-control-matrix.md)

---

## 8. Review History

| Version | Date       | Reviewer         | Notes             |
|---------|------------|------------------|-------------------|
| v1.0    | 2025-12-23 | HR Manager       | Initial Draft     |

---

## 9. Departmental Approval Checklist

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
