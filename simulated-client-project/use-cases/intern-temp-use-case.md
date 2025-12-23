<!--
███████████████████████████████████████████████████████████████
  🧾 SMB Office IT Blueprint – Project Document
  Doc ID: USECASE-ROLE-INTERN-001
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
  Reviewers: AD Architect, Security Analyst
  Tags: [intern, temporary-user, restricted-access, role]
  Data Sensitivity: Simulated PII
  Compliance: None
  Publish Target: Internal
  Summary: >
    Defines the IT profile, usage restrictions, and temporary access controls for Intern and Temporary Worker accounts in the Samba AD Lab simulation.
  Read Time: ~5 min
███████████████████████████████████████████████████████████████
-->

# 📘 Intern / Temporary Worker Role – Use Case and IT Profile

---

## 📍 Table of Contents

- [1. Purpose](#1-purpose)
- [2. Background](#2-background)
- [3. Objectives](#3-objectives)
- [4. Structure / Body](#4-structure--body)
  - [4.1 Job Summary](#41-job-summary)
  - [4.2 Business Responsibilities](#42-business-responsibilities)
  - [4.3 IT Access Requirements](#43-it-access-requirements)
  - [4.4 Active Directory Group Memberships](#44-active-directory-group-memberships)
  - [4.5 Temporary Account Controls](#45-temporary-account-controls)
  - [4.6 Security Considerations](#46-security-considerations)
- [5. Related Files](#5-related-files)
- [6. Review History](#6-review-history)
- [7. Departmental Approval Checklist](#7-departmental-approval-checklist)

---

## 1. Purpose

To define and document the limitations, access scope, and IT environment for **Interns** and **Temporary Workers** participating in short-term assignments within the simulated office structure.

---

## 2. Background

Interns and temps are provided **time-limited**, **least-privilege accounts** to support departmental projects or seasonal workloads. They must have enough access to contribute productively while maintaining strict boundaries from sensitive systems or data.

This use case supports automation rules, AD object creation, and policy testing in the Samba AD Lab.

---

## 3. Objectives

- Outline a safe, standardized IT experience for interns/temps
- Automate onboarding/offboarding through AD/Ansible
- Enable AD group policy enforcement for temporary roles
- Define security zones and separation from privileged users

---

## 4. Structure / Body

### 4.1 Job Summary

- **Title:** Intern / Temp Worker  
- **Department:** Varies (assigned per project)  
- **Location:** Shared Workstation or Assigned Laptop  
- **Workstation ID:** assist-ws02 or intern-ws01 (dynamic)

### 4.2 Business Responsibilities

| Task                                  | Description                                     |
|---------------------------------------|-------------------------------------------------|
| Document Preparation                  | Help with data entry, scanning, or formatting   |
| Spreadsheet Updates                   | Fill in reports using templates                 |
| Printing Support Materials            | Access approved documents for printing          |
| Shadowing / Observing Tasks           | Non-interactive learning in live environments   |
| Basic Research                        | Assigned research via intranet or web           |

### 4.3 IT Access Requirements

| Resource Type         | Resource                            | Access Type      |
|-----------------------|-------------------------------------|------------------|
| Shared Folder         | `\\files01\shared\interns`          | Read/Write       |
| Printer               | `print01/Shared-Printer`            | Print-Only       |
| Intranet              | `intranet.local/intern-portal`      | View Only        |
| Internet              | Web browser with filtering          | Limited Access   |
| E-mail (optional)     | Internal email only                 | If requested     |

All access is **logged**, and all shared resources must use **intern-specific AD groups**.

---

### 4.4 Active Directory Group Memberships

| AD Group Name                  | Purpose                          |
|--------------------------------|----------------------------------|
| `GG-Interns`                  | Primary access group             |
| `SG-Shared-InternFolder`      | Folder permission enforcement    |
| `SG-Printer-Shared`           | Assigned printer queue           |
| `SG-Web-Filtered`             | Internet access via proxy rules  |

---

### 4.5 Temporary Account Controls

| Control                     | Description                                          |
|-----------------------------|------------------------------------------------------|
| Account Expiration          | Default set to **30 days** from creation             |
| Workstation Logon Restriction | Only allowed on `assist-ws02`, `intern-ws01`       |
| No Email (default)          | E-mail accounts disabled unless authorized           |
| Login Hours Policy          | 8:00 AM – 6:00 PM weekdays                           |
| Group Policy Template       | `GPO-Interns` restricts control panel, USB, CMD      |

Accounts are created via script or Ansible with these controls enforced.

---

### 4.6 Security Considerations

- **Non-sudo**, no shell access on Linux hosts
- USB storage access disabled by policy
- Access logs reviewed weekly for intern activity
- No access to HR, Finance, or IT folders
- Auto-logout after 15 minutes of inactivity (via GPO)
- Must complete digital acceptable-use training prior to access

---

## 5. Related Files

- [user-access-policy.md](../policy/user-access-policy.md)
- [intern-onboarding-checklist.md](../onboarding/intern-onboarding-checklist.md)
- [automation-script-create-temp-user.sh](../../implementation/scripts/user-creation/create-temp-user.sh)

---

## 6. Review History

| Version | Date       | Reviewer             | Notes             |
|---------|------------|----------------------|--------------------|
| v1.0    | 2025-12-22 | IT Business Analyst  | Initial draft      |

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
