<!--
███████████████████████████████████████████████████████████████
  🧾 SMB Office IT Blueprint – Project Document
  Doc ID: USECASE-ROLE-RECEP-001
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
  Reviewers: AD Architect, Linux Admin
  Tags: [reception, role, user-profile, use-case]
  Data Sensitivity: Simulated PII
  Compliance: None
  Publish Target: Internal
  Summary: >
    Defines the simulated business use case, permissions, and IT needs for the Receptionist role in the office AD and Linux environment.
  Read Time: ~5 min
███████████████████████████████████████████████████████████████
-->

# 📘 Receptionist Role – Use Case and IT Profile

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
  - [4.5 File and Print Access](#45-file-and-print-access)
  - [4.6 Security Considerations](#46-security-considerations)
- [5. Related Files](#5-related-files)
- [6. Review History](#6-review-history)
- [7. Departmental Approval Checklist](#7-departmental-approval-checklist)

---

## 1. Purpose

To define the IT-related responsibilities, access permissions, and environment setup for the **Receptionist** role as part of the simulated office environment in the Samba AD lab.

---

## 2. Background

The receptionist serves as the **front-facing staff member** responsible for managing visitor interactions, call routing, and basic administrative duties. This user role must have limited system privileges but reliable access to shared resources, printing, and communications tools.

This use case supports directory planning, workstation imaging, group access control, and automation via Ansible.

---

## 3. Objectives

- Document required **IT resources and AD groups** for the receptionist
- Define access scope to ensure **least privilege**
- Enable automation of user provisioning through scripts
- Inform test scenarios for login, group policy, and file access

---

## 4. Structure / Body

### 4.1 Job Summary

- **Title:** Receptionist  
- **Department:** General Admin  
- **Location:** Front Desk, Main Office  
- **Workstation ID:** assist-ws01

### 4.2 Business Responsibilities

| Task                                  | Description                                  |
|---------------------------------------|----------------------------------------------|
| Visitor Intake                        | Log guest entries in digital log             |
| Call Routing                          | Answer phones and redirect calls             |
| Calendar Scheduling                   | Schedule meetings using shared Outlook/CalDAV |
| Mail and Package Logging              | Record incoming deliveries                   |
| Office Supplies Monitoring            | Maintain basic office inventory spreadsheet  |

### 4.3 IT Access Requirements

| Resource Type         | Resource                          | Access Type      |
|-----------------------|-----------------------------------|------------------|
| Shared Folder         | `\\files01\shared\general-admin`  | Read/Write       |
| Printer               | `print01/Reception-Printer`       | Full Access      |
| Internal Website      | `intranet.local/reception`        | View & Edit      |
| Calendar System       | `calendar.domain.local`           | Editor Role      |
| Email System          | IMAP/SMTP + Webmail               | Full User Access |
| Visitor Log App       | Browser-based web app             | Full Access      |

### 4.4 Active Directory Group Memberships

| AD Group Name                  | Purpose                          |
|--------------------------------|----------------------------------|
| `GG-Reception`                | Primary department group         |
| `SG-General-SharedFolder`     | File access via security group   |
| `SG-Calendar-Contributor`     | Calendar permissions             |
| `SG-Printer-Reception`        | Print access group               |

### 4.5 File and Print Access

| Server     | Path / Queue                       | Access Level |
|------------|------------------------------------|--------------|
| `files01`  | `\\files01\shared\general-admin`    | Read/Write   |
| `print01`  | `Reception-Printer`                 | Manage Jobs  |

File access should be managed **via group membership**, not directly at user level.

### 4.6 Security Considerations

- User must be **non-sudoer**
- Group policy will restrict access to **USB drives**
- Access to **internal-only websites** (no admin portals)
- Files stored by receptionist are subject to **auditd logging**
- Role is part of **least privilege** baseline
- No shell access on Linux systems

---

## 5. Related Files

- [simulated-org-chart.md](../org/simulated-org-chart.md)
- [group-policy-baseline.md](../policy/group-policy-baseline.md)

---

## 6. Review History

| Version | Date       | Reviewer         | Notes                 |
|---------|------------|------------------|------------------------|
| v1.0    | 2025-12-22 | IT Business Analyst | Initial draft |

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
