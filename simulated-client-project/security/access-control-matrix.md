<!--
███████████████████████████████████████████████████████████████
  🧾 SMB Office IT Blueprint – Project Document
  Doc ID: SECURITY-ACCESS-MATRIX-001
  Author: IT AD Architect
  Created: 2025-12-23
  Updated: 2025-12-23
  Version: v1.0
  Status: Draft
  Confidentiality: Internal
  Project Phase: Planning
  Category: Security Matrix
  Audience: IT
  Owners: IT AD Architect, Linux Admin/Architect
  Reviewers: IT Business Analyst, Project Doc Auditor
  Tags: [access-control, ad-groups, shares, permissions, roles]
  Data Sensitivity: Simulated File Shares and Group Names
  Compliance: Role-Based Access Control (RBAC), Least Privilege
  Publish Target: Internal
  Summary: >
    This matrix outlines role-based access control to systems, file shares, printers, and privileged resources. It serves as a source of truth for permission mapping and enforcement via Active Directory groups and Linux ACLs.
  Read Time: ~8 min
███████████████████████████████████████████████████████████████
-->

# 🔐 Access Control Matrix (RBAC Overview)

---

## 📍 Table of Contents

- [1. Purpose](#1-purpose)
- [2. Roles Defined](#2-roles-defined)
- [3. File Share Access](#3-file-share-access)
- [4. System Access](#4-system-access)
- [5. Application & Service Access](#5-application--service-access)
- [6. Administrative Access](#6-administrative-access)
- [7. Review and Auditing](#7-review-and-auditing)
- [8. Related Files](#8-related-files)
- [9. Review History](#9-review-history)
- [10. Departmental Approval Checklist](#10-departmental-approval-checklist)

---

## 1. Purpose

To provide a definitive source for mapping user roles to access privileges across systems, shares, and applications. Supports RBAC enforcement and access audits.

---

## 2. Roles Defined

| Role                  | Description                                 |
|-----------------------|---------------------------------------------|
| Receptionist          | Front-desk access, general office tools     |
| Admin Assistant       | Broad office access, but no HR/Finance      |
| Junior Professional   | Entry-level contributor                     |
| Senior Professional   | Advanced contributor with project authority |
| Intern / Temp         | Time-limited access, minimal privileges     |
| HR Manager            | Access to HR documents and tools            |
| Finance Manager       | Access to accounting systems and files      |
| IT Administrator      | Full IT support and elevated permissions    |
| Managing Partner      | Strategic access, not administrative        |

---

## 3. File Share Access

| File Share Path                          | RO Roles                          | RW Roles                         | Owner Group         |
|------------------------------------------|-----------------------------------|----------------------------------|---------------------|
| `\\files01\shared\company`               | All staff                         | Admin Assistant, Sr. Pro, Execs  | `SG-Company-Docs`   |
| `\\files01\department\hr`                | Execs, HR Manager                 | HR Manager                       | `GG-HR-Staff`       |
| `\\files01\department\finance`           | Execs, Finance Manager            | Finance Manager                  | `GG-Finance-Staff`  |
| `\\files01\projects\client-deliverables` | Sr. Prof., Jr. Prof.              | Sr. Prof.                        | `GG-Project-Staff`  |
| `\\files01\admin\executive-reports`      | Execs only                        | Managing Partner                 | `GG-Exec-Leadership`|
| `\\files01\interns\working`              | Intern                            | Intern Supervisor                | `GG-Interns`        |

---

## 4. System Access

| System/Workstation      | Role Access                     | Access Level  |
|-------------------------|----------------------------------|---------------|
| `hr-ws01`               | HR Manager                       | Full          |
| `finance-ws01`          | Finance Manager                  | Full          |
| `admin-ws01`            | Admin Assistant                  | Full          |
| `intern-ws01`           | Intern / Temp                    | Full          |
| `exec-ws01`             | Managing Partner                 | Full (isolated)|
| `itadmin-ws01`          | IT Administrator                 | Full Admin    |
| `files01`, `print01`    | All users                        | Networked use |
| `dc01`, `dc02`          | IT Admin, AD Architect           | Admin Only    |

---

## 5. Application & Service Access

| Application / Tool         | Roles With Access              | Notes                             |
|----------------------------|--------------------------------|------------------------------------|
| LibreOffice / Office Suite | All office roles               | General productivity use           |
| Finance System (Simulated) | Finance Manager, Execs         | Authentication via AD              |
| HR Tracker (Simulated)     | HR Manager, Execs              | Web-based access                   |
| CUPS Printer Queue         | All staff                      | Permissions via AD group mappings  |
| Shared Calendar System     | All roles                      | Read/write based on dept group     |
| Git-based Docs (Read-Only) | All staff                      | Deployed via GitHub Pages          |
| Git-based Docs (Encrypted) | Sr. Pro, IT Admin, Editors     | Controlled via `git-crypt`         |

---

## 6. Administrative Access

| Admin Function              | Role / Group                  | Notes                                |
|----------------------------|-------------------------------|---------------------------------------|
| AD User Management         | IT Administrator              | `GG-IT-Admins`                        |
| File Share ACLs            | IT Admin, AD Architect        | Permission via `samba-tool` or ACLs   |
| Git Repository Secrets      | IT Admin, Content Editor      | Encrypted; managed via `git-crypt`    |
| Print Queue Admin          | IT Admin                      | Printer group assignment              |
| Security Logs (auditd)     | Security Analyst, IT Admin    | Reviewed monthly                      |
| Remote Access (SSH)        | IT Admin                      | Key-based only; logged                |
| Server Reboots / Updates   | IT Admin, Linux Architect     | Scheduled maintenance window          |

---

## 7. Review and Auditing

- **Quarterly Access Review** conducted by IT Security Analyst
- **Access Changes** must be requested via IT ticket and approved by department head
- **Scripted Audit Tools** to be developed by Ansible Programmer
- All AD group assignments are **tracked in Git** under:
  - `implementation/roles/ad-groups/*.yml`

---

## 8. Related Files

- [executive-security-policy.md](../policy/executive-security-policy.md)
- [file-share-structure.md](../org/file-share-structure.md)
- [shared-services-policy.md](../policy/shared-services-policy.md)

---

## 9. Review History

| Version | Date       | Reviewer           | Notes             |
|---------|------------|--------------------|-------------------|
| v1.0    | 2025-12-23 | IT AD Architect    | Initial draft     |

---

## 10. Departmental Approval Checklist

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
