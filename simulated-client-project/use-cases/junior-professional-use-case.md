<!--
███████████████████████████████████████████████████████████████
  🧾 SMB Office IT Blueprint – Project Document
  Doc ID: USECASE-ROLE-JRPRO-001
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
  Tags: [junior-staff, professional-services, onboarding, limited-access]
  Data Sensitivity: Internal Use Only
  Compliance: Employment Standards
  Publish Target: Internal
  Summary: >
    Defines the IT access scope and operational responsibilities for the Junior Professional role, including onboarding, departmental permissions, and security limitations in the simulated SMB office lab environment.
  Read Time: ~5 min
███████████████████████████████████████████████████████████████
-->

# 📘 Junior Professional – Use Case and IT Profile

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

To define the system access, responsibilities, and onboarding expectations for the **Junior Professional**, a full-time entry-level employee in a technical or service-oriented department.

---

## 2. Background

Junior Professionals support project-based teams or internal operations. Their access is limited by design under **least privilege** principles, with potential to escalate permissions after training or role progression.

---

## 3. Objectives

- Establish a minimal but functional IT profile for early-career staff
- Define secure access boundaries with auditability
- Support department-specific workflows without exposing sensitive data
- Enable consistent and automated onboarding through scripts or playbooks

---

## 4. Structure / Body

### 4.1 Job Summary

- **Title:** Junior Professional  
- **Department:** Professional Services / Engineering / IT  
- **Workstation ID:** prof-ws01, prof-ws02  
- **Role Type:** Entry-Level Contributor

---

### 4.2 Responsibilities

| Responsibility               | Description                                     |
|------------------------------|-------------------------------------------------|
| Task Support                 | Assist with internal or external project tasks  |
| Documentation                | Write/update internal docs or client notes      |
| Technical Research           | Conduct research to assist senior staff         |
| Collaboration                | Participate in department meetings and updates  |
| Training & Development       | Complete required internal training modules     |

---

### 4.3 IT Access Requirements

| Resource / System            | Access Level   | Notes                                 |
|------------------------------|----------------|----------------------------------------|
| Departmental Workstation     | Standard User  | Hardened image, no admin rights        |
| Shared Project Files         | Read/Write     | Access limited by group                |
| HR, Finance Folders          | No Access      | Enforced by group ACLs                 |
| Email and Calendar           | Full Access    | Internal communications only           |
| Company Handbook             | Read-Only      | Access to shared policies              |
| Internal Wiki / KB           | Read/Write     | With contributor permissions           |

---

### 4.4 Active Directory Group Memberships

| AD Group Name                      | Purpose                                      |
|------------------------------------|----------------------------------------------|
| `GG-ProfessionalServices`          | Primary group for team assignment            |
| `SG-Projects-Shared-RW`            | Access to team project folders               |
| `SG-Wiki-Contributors`             | Permission to edit internal documentation    |
| `SG-Company-Handbook`              | Read-only access to company-wide policies    |
| `SG-Department-Printer`            | Printer permissions                          |

---

### 4.5 File and Application Access

| Server     | Path / Application                          | Access Level |
|------------|---------------------------------------------|--------------|
| `files01`  | `\\files01\projects\team-shared`            | Read/Write  |
| `files01`  | `\\files01\company\handbook`                | Read-Only   |
| Wiki       | Internal Knowledge Base (Confluence or MD)  | Contributor |
| `print01`  | `Team-Printer`                              | Print       |

---

### 4.6 Security and Role Constraints

- No access to privileged or administrative tools
- USB storage disabled on endpoint
- Access reviewed quarterly by department manager
- No access to HR or Finance systems
- Activity in shared project folders is logged via **auditd**
- Role escalations require formal request and approval

---

## 5. Related Files

- [onboarding-workflow.md](../workflows/onboarding-workflow.md)
- [group-policy-baseline.md](../policy/group-policy-baseline.md)
- [access-control-matrix.md](../security/access-control-matrix.md)

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
