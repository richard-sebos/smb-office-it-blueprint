<!--
███████████████████████████████████████████████████████████████
  🧾 SMB Office IT Blueprint – Project Document
  Doc ID: ORG-STRUCTURE-001
  Author: SMB Analyst, IT Business Analyst
  Created: 2025-12-23
  Updated: 2025-12-23
  Version: v1.0
  Status: Draft
  Confidentiality: Internal
  Project Phase: Planning
  Category: Organizational Chart
  Audience: IT, HR, Project Management
  Owners: Project Manager, HR Manager
  Reviewers: Project Doc Auditor
  Tags: [org, structure, hierarchy, ou, users, access, simulation]
  Data Sensitivity: Simulated (Non-Production)
  Compliance: Internal Alignment Only
  Publish Target: Internal
  Summary: >
    Defines the organizational structure of the simulated SMB Office. Serves as a basis for AD OU structure, GPO inheritance, security group mapping, and departmental use case design.
  Read Time: ~4 min
███████████████████████████████████████████████████████████████
-->

# 🏢 Simulated Organization Chart

---

## 📍 Table of Contents

- [1. Overview](#1-overview)
- [2. Executive Leadership](#2-executive-leadership)
- [3. Departmental Structure](#3-departmental-structure)
- [4. Role Breakdown](#4-role-breakdown)
- [5. Mapping to Active Directory](#5-mapping-to-active-directory)
- [6. Use Case Alignment](#6-use-case-alignment)
- [7. Review History](#7-review-history)
- [8. Departmental Approval Checklist](#8-departmental-approval-checklist)

---

## 1. Overview

This document outlines the **organizational layout** of the simulated SMB used for the Samba AD Lab project. It defines departments, roles, reporting structures, and will inform:
- AD OU hierarchy
- GPO targeting
- Security group access
- Ansible automation role templates

---

## 2. Executive Leadership

| Role               | Reports To        | Notes                          |
|--------------------|-------------------|---------------------------------|
| Managing Partner   | Board/Investors   | Overall leadership             |
| Finance Manager    | Managing Partner  | Oversees accounting & payroll  |
| HR Manager         | Managing Partner  | Manages personnel & policies   |
| Project Manager    | Managing Partner  | IT Projects, cross-dept. coordination |

---

## 3. Departmental Structure

```text
SMB Office
├── Executive Team
│   ├── Managing Partner
│   ├── Finance Manager
│   ├── HR Manager
│   └── Project Manager
│
├── Finance Department
│   ├── Senior Accountant
│   ├── Junior Accountant
│   └── Intern
│
├── HR Department
│   ├── HR Generalist
│   ├── Admin Assistant
│   └── Intern
│
├── Professional Services
│   ├── Senior Professional
│   ├── Junior Professional
│   └── Project Intern
│
├── IT Department (Simulated)
│   ├── IT Administrator
│   ├── Linux Admin
│   └── Ansible Automation Engineer
````

> Visual org chart diagrams may be added using PlantUML, Draw.io, or ASCII diagrams like the above.

---

## 4. Role Breakdown

| Role                | Department       | Level     | Notes                                     |
| ------------------- | ---------------- | --------- | ----------------------------------------- |
| Managing Partner    | Executive        | Senior    | Full administrative access                |
| Senior Professional | Professional Svc | Senior    | Access to project shares                  |
| Junior Professional | Professional Svc | Mid-Level | Limited access, some sudo via AD          |
| Admin Assistant     | HR               | Support   | Creates shared folders, manages templates |
| IT Administrator    | IT               | Admin     | Needs checkout for sensitive ops          |
| Intern              | Varies           | Entry     | Limited access, tightly scoped            |

---

## 5. Mapping to Active Directory

| Department       | OU Name           | Example Groups                            |
| ---------------- | ----------------- | ----------------------------------------- |
| Executive        | `OU=Executive`    | `GG-Exec`, `GG-Exec-Finance`              |
| Finance          | `OU=Finance`      | `GG-Finance-Staff`, `GG-Finance-Managers` |
| HR               | `OU=HR`           | `GG-HR-Staff`, `GG-HR-Assistants`         |
| Professional Svc | `OU=Professional` | `GG-Prof-Senior`, `GG-Prof-Junior`        |
| IT               | `OU=IT`           | `GG-IT-Admins`, `GG-IT-Automation`        |
| Interns          | Nested per dept.  | `GG-Interns`, `GG-Finance-Interns`        |

---

## 6. Use Case Alignment

Each role in the chart is mapped to:

* 📝 A use case document (`/use-cases/`)
* 🛡️ A security/access policy
* 🖥️ A mapped workstation (`finance-ws01`, `hr-ws01`, etc.)
* 🔐 Group policies inherited via AD OU structure

See:

* [`user-access-policy.md`](../policy/user-access-policy.md)
* [`file-share-permissions.md`](../security/file-share-permissions.md)
* [`group-policy-baseline.md`](../policy/group-policy-baseline.md)

---

## 7. Review History

| Version | Date       | Reviewer        | Notes                 |
| ------- | ---------- | --------------- | --------------------- |
| v1.0    | 2025-12-23 | SMB Analyst     | Initial structure     |
|         |            | Project Manager | Reviewed for accuracy |

---

## 8. Departmental Approval Checklist

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

