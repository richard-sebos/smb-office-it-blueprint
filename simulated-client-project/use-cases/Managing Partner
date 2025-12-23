<!--
███████████████████████████████████████████████████████████████
  🧾 SMB Office IT Blueprint – Project Document
  Doc ID: USECASE-ROLE-SRPRO-001
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
  Reviewers: IT Security Analyst, AD Architect, Linux Admin
  Tags: [senior-staff, project-lead, professional-services]
  Data Sensitivity: Internal + Limited Client Data (Simulated)
  Compliance: Employment Standards
  Publish Target: Internal
  Summary: >
    Defines the use case and IT profile for Senior Professionals in client service or technical delivery roles, including system access, leadership responsibilities, and collaboration needs across teams and with external stakeholders.
  Read Time: ~6 min
███████████████████████████████████████████████████████████████
-->

# 📘 Senior Professional – Use Case and IT Profile

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
  - [4.6 Security and Accountability Measures](#46-security-and-accountability-measures)
- [5. Related Files](#5-related-files)
- [6. Review History](#6-review-history)
- [7. Departmental Approval Checklist](#7-departmental-approval-checklist)

---

## 1. Purpose

To define the digital workspace, access levels, and collaboration expectations for **Senior Professionals**, who lead projects, mentor junior staff, and interface with clients and stakeholders in a technical, service, or consultative capacity.

---

## 2. Background

Senior Professionals work cross-functionally across internal and external teams. Their roles require elevated access to shared resources, responsibility for deliverables, and oversight of technical documentation and collaboration tools.

---

## 3. Objectives

- Ensure that senior-level staff have efficient access to the tools and data needed to lead and execute project work
- Define security constraints around client data and internal confidentiality
- Establish audit and accountability frameworks for sensitive file access
- Support automation of account provisioning and access elevation where appropriate

---

## 4. Structure / Body

### 4.1 Job Summary

- **Title:** Senior Professional / Team Lead  
- **Department:** Professional Services / Engineering  
- **Workstation ID:** prof-ws03, prof-ws04  
- **Role Type:** Trusted Technical Contributor

---

### 4.2 Responsibilities

| Responsibility               | Description                                      |
|------------------------------|--------------------------------------------------|
| Project Leadership           | Own deliverables, timelines, and documentation  |
| Mentorship                   | Support Junior Professionals and Interns        |
| Client Collaboration         | Interface with client IT or PM counterparts     |
| Report Writing               | Author reports, diagrams, and audit materials   |
| Knowledge Contributions      | Add to internal wiki, templates, and playbooks  |
| Escalation Support           | Triage and respond to high-level issues         |

---

### 4.3 IT Access Requirements

| Resource / System             | Access Level   | Notes                                 |
|-------------------------------|----------------|----------------------------------------|
| Workstation                   | Standard User  | No admin rights by default            |
| Shared Project Repos          | Full RW        | Git, Markdown, Ansible                |
| Client Folders (Limited)      | Read/Write     | Must be assigned via project group    |
| Internal Wiki / KB            | Contributor    | Can author and edit                   |
| Report Templates              | Read/Write     | Can update shared reports             |
| Email, Calendar               | Full Access    | Internal + client communication       |

> 🔐 Access to simulated client data requires group-based assignment and **audit logging**.

---

### 4.4 Active Directory Group Memberships

| AD Group Name                        | Purpose                                      |
|--------------------------------------|----------------------------------------------|
| `GG-ProfessionalServices-Senior`     | Primary group                                |
| `SG-Projects-Shared-RW`              | Project folders access                       |
| `SG-Client-ProjectX-RW`              | Only if assigned to specific client work     |
| `SG-Wiki-Contributors`               | Internal wiki documentation                  |
| `SG-Print-Access`                    | Network printer access                       |

---

### 4.5 File and Application Access

| Server     | Path / Application                           | Access Level |
|------------|----------------------------------------------|--------------|
| `files01`  | `\\files01\projects\team-shared`             | Read/Write  |
| `files01`  | `\\files01\clients\project-x`                | Conditional Read/Write |
| Git Repo   | `/repo/samba-ad-lab/implementation`          | Read/Write (if assigned) |
| Wiki       | Internal KB or documentation system          | Contributor |
| `print01`  | `Team-Printer`, `Engineering-Printer`        | Print       |

---

### 4.6 Security and Accountability Measures

- No default access to all client data — must be **explicitly assigned**
- Activities in client folders are **monitored via auditd**
- No elevated shell or system access unless assigned temporarily
- USB media access is **restricted**
- Elevated access can be requested and approved per project phase
- Expected to **report/document escalated issues**
- Quarterly review by IT Security and Department Manager

---

## 5. Related Files

- [access-control-matrix.md](../../implementation/security/access-control-matrix.md)
- [project-onboarding-template.md](../templates/project-onboarding-template.md)
- [client-access-policy.md](../policy/client-access-policy.md)

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
