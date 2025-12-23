<!--
███████████████████████████████████████████████████████████████
  🧾 SMB Office IT Blueprint – Project Document
  Doc ID: USECASE-ROLE-ADMIN-001
  Author: IT Business Analyst
  Created: 2025-12-22
  Updated: 2025-12-22
  Version: v1.0
  Status: Draft
  Confidentiality: Internal
  Project Phase: Planning
  Category: Business Policy
  Audience: Mixed
  Owners: SMB Analyst, IT Business Analyst
  Reviewers: IT Security Analyst, AD Architect
  Tags: [admin-assistant, shared-access, support-role]
  Data Sensitivity: Internal Documents, Schedules
  Compliance: Employment Standards
  Publish Target: Internal
  Summary: >
    Defines the IT access and responsibilities of the Admin Assistant role, a multi-departmental support user with limited but sensitive file access, internal tools, and printing capabilities.
  Read Time: ~5 min
███████████████████████████████████████████████████████████████
-->

# 📘 Administrative Assistant – Use Case and IT Profile

---

## 📍 Table of Contents

- [1. Purpose](#1-purpose)
- [2. Background](#2-background)
- [3. Objectives](#3-objectives)
- [4. Structure / Body](#4-structure--body)
  - [4.1 Job Summary](#41-job-summary)
  - [4.2 Responsibilities](#42-responsibilities)
  - [4.3 IT Access Requirements](#43-it-access-requirements)
  - [4.4 Active Directory Group Memberships](#44-active-directory-group-memberships)
  - [4.5 File and Application Access](#45-file-and-application-access)
  - [4.6 Security and Role Constraints](#46-security-and-role-constraints)
- [5. Related Files](#5-related-files)
- [6. Review History](#6-review-history)
- [7. Departmental Approval Checklist](#7-departmental-approval-checklist)

---

## 1. Purpose

To define the system permissions, security boundaries, and digital workspace configuration for the **Admin Assistant**, who supports HR, Finance, and Professional Services teams.

---

## 2. Background

This role supports daily operational tasks such as scheduling, document formatting, printing, and internal communications. Though not considered privileged, the Admin Assistant must have controlled access to **some departmental folders**, without full visibility into sensitive HR or Finance data.

---

## 3. Objectives

- Provide proper access for task coordination and clerical support
- Ensure visibility is limited to only non-sensitive content
- Enable access to shared calendars, printers, and editable templates
- Prevent data leakage or privilege escalation

---

## 4. Structure / Body

### 4.1 Job Summary

- **Title:** Administrative Assistant  
- **Department:** Shared Services  
- **Workstation ID:** assist-ws01, assist-ws02  
- **Role Type:** Multi-departmental Support

---

### 4.2 Responsibilities

| Responsibility              | Description                                             |
|-----------------------------|---------------------------------------------------------|
| Scheduling & Calendars      | Assist departments with internal scheduling             |
| Document Preparation        | Format, review, and distribute internal documents        |
| Communications              | Send memos, follow-up emails, and calendar invites      |
| Printing and Filing         | Responsible for printed policy documents and notices     |
| Meeting Support             | Help facilitate meetings, record minutes                |
| Reception Overflow          | May assist front desk as needed                         |

---

### 4.3 IT Access Requirements

| System / Resource           | Access Level   | Notes                                   |
|-----------------------------|----------------|------------------------------------------|
| Admin Workstation           | Standard User  | Hardened endpoint policy                 |
| Shared Department Files     | Read/Write     | Limited to `Shared` or `Templates` dirs |
| HR Files                    | Read-Only      | Only `HR\Forms\Templates` folder         |
| Finance Files               | No Access      | Protected by ACL                         |
| Scheduling Tools            | Full Access    | Shared calendars, invites, etc.          |
| Internal Documents          | Read/Write     | Office policies, templates               |
| Email                       | Full Access    | With phishing protection and DLP         |

---

### 4.4 Active Directory Group Memberships

| AD Group Name                  | Purpose                                  |
|--------------------------------|------------------------------------------|
| `GG-Shared-Services`           | Primary group for Admin Assistants       |
| `SG-Office-Scheduling`         | Access to calendar and booking systems   |
| `SG-Print-Access`              | Networked printer permissions            |
| `SG-Templates-Write`           | Access to shared document templates      |
| `SG-HR-Forms-Read`             | Limited HR access (templates only)       |

---

### 4.5 File and Application Access

| Server     | Path / Application                        | Access Level |
|------------|-------------------------------------------|--------------|
| `files01`  | `\\files01\shared\templates`              | Read/Write  |
| `files01`  | `\\files01\hr\forms\templates`            | Read-Only   |
| `files01`  | `\\files01\company\policies`              | Read/Write  |
| `print01`  | `Main-Printer`, `Reception-Printer`       | Print       |
| App        | Shared calendar and scheduling tools      | Full Access |

---

### 4.6 Security and Role Constraints

- No access to payroll, billing, or confidential HR documents
- Cannot access or modify user accounts
- Cannot install or modify software
- File access is monitored via **auditd** logging
- USB media access is restricted by policy
- HR and Finance folders protected via **group ACL enforcement**
- Role reviewed semi-annually by Security and AD Architect

---

## 5. Related Files

- [shared-services-policy.md](../policy/shared-services-policy.md)
- [access-control-matrix.md](../../implementation/security/access-control-matrix.md)
- [template-folder-structure.md](../../assets/templates/template-folder-structure.md)

---

## 6. Review History

| Version | Date       | Reviewer            | Notes          |
|---------|------------|---------------------|----------------|
| v1.0    | 2025-12-22 | IT Business Analyst | Initial draft  |

---

## 7. Departmental Approval Checklist

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
