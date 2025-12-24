<!--
███████████████████████████████████████████████████████████████
  🧾 SMB Office IT Blueprint – Project Document
  Doc ID: USECASE-ROLE-ITADMIN-001
  Author: IT Business Analyst
  Created: 2025-12-22
  Updated: 2025-12-22
  Version: v1.0
  Status: Draft
  Confidentiality: Internal
  Project Phase: Planning
  Category: Business Policy
  Audience: Mixed
  Owners: IT Business Analyst, Project Doc Auditor
  Reviewers: Linux Admin, Security Analyst
  Tags: [it-admin, privileged-user, admin-checkout, access-control]
  Data Sensitivity: Simulated PII, Internal IT Assets
  Compliance: None
  Publish Target: Internal
  Summary: >
    Defines the IT Administrator role, responsibilities, access scope, and administrative access control workflows (checkout policy) within the Samba AD Lab environment.
  Read Time: ~6 min
███████████████████████████████████████████████████████████████
-->

# 📘 IT Administrator Role – Use Case and IT Profile

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
  - [4.5 Elevated Access via Admin Checkout](#45-elevated-access-via-admin-checkout)
  - [4.6 Security Considerations](#46-security-considerations)
- [5. Related Files](#5-related-files)
- [6. Review History](#6-review-history)
- [7. Departmental Approval Checklist](#7-departmental-approval-checklist)

---

## 1. Purpose

Define the permissions, responsibilities, and **sensitive access control policies** associated with the **IT Administrator** role in the simulated business environment.

---

## 2. Background

The IT Administrator manages **infrastructure**, **identity services**, **security controls**, and **end-user support**. This includes both **privileged operational tasks** and coordination with other departments on access approvals for sensitive data.

To ensure compliance with internal policy, sensitive resources require **Admin Checkout** before access.

---

## 3. Objectives

- Define standard IT administrator access and responsibilities  
- Establish **just-in-time elevated access** workflows (checkout required)  
- Protect client and financial data with controlled access procedures  
- Document required Active Directory group assignments  

---

## 4. Structure / Body

### 4.1 Job Summary

- **Title:** IT Administrator  
- **Department:** IT Services  
- **Workstation ID:** it-ws01  
- **Primary Role Type:** Privileged / Root-capable  
- **Secondary Role Type:** Helpdesk Support / Configuration

### 4.2 Responsibilities

| Responsibility Area          | Description                                          |
|------------------------------|------------------------------------------------------|
| Domain Administration        | AD, DNS, Kerberos, OU delegation                     |
| File and Print Services      | Manage Samba shares and printer queues               |
| Patch Management             | Apply updates via scripts or Ansible                 |
| Security Enforcement         | Implement auditd, SELinux, AIDE                      |
| Backup/Restore Operations    | Schedule and verify VM and file share backups        |
| Helpdesk / User Support      | Reset passwords, join clients to domain              |
| User Provisioning            | Support onboarding and offboarding processes         |

---

### 4.3 IT Access Requirements

| Resource / System            | Access Level          | Access Type     |
|------------------------------|------------------------|-----------------|
| Domain Controllers (`dc01`, `dc02`) | Full Admin (sudo)   | Persistent      |
| File Server (`files01`)      | Read/Write             | Persistent      |
| Print Server (`print01`)     | Manage Queues          | Persistent      |
| All Linux Clients            | Root via SSH (sudo)    | On-Demand       |
| Sensitive Shares (e.g. `HR`, `Finance`, `Clients`) | Read-Only or Full | **Admin Checkout** |

---

### 4.4 Active Directory Group Memberships

| AD Group                     | Purpose                                |
|------------------------------|----------------------------------------|
| `GG-IT-Admins`              | Primary administrative group           |
| `SG-Workstation-Admin`     | Local admin on domain-joined clients   |
| `SG-Domain-Mgmt`           | DNS, user, and group management        |
| `SG-Print-Admin`           | Printer queue configuration            |
| `SG-IT-Support`            | Password resets, group assignments     |
| `SG-Checkout-Privileged`   | Eligible for admin checkout workflow   |

---

### 4.5 Elevated Access via Admin Checkout

Certain systems and data require a **time-limited, auditable checkout** process before access is granted.

#### 🛡️ Admin Checkout Workflow

| Step | Action                                      | Responsible Party         |
|------|---------------------------------------------|----------------------------|
| 1    | Request access to a protected resource      | IT Admin (self-service)   |
| 2    | Approval granted by Security or Project Mgr | AD Architect or Security  |
| 3    | Temporary access granted (1–4 hrs max)      | via script / policy       |
| 4    | Access revoked automatically                | GPO, cron, or Ansible     |
| 5    | Activity logged                              | auditd + access log       |

#### ✅ Applies To:

- `\\files01\shared\HR`
- `\\files01\shared\Finance`
- `\\files01\shared\Clients`
- Any VM snapshot restore process
- Changes to firewall or SELinux rules

---

### 4.6 Security Considerations

- IT Admins operate under **Zero Trust** model
- All sudo actions are **logged and audited**
- Remote root logins are disabled; use `sudo` only
- AD group membership changes are version-controlled
- No unattended scripts may run without approval
- **Admin Checkout** required for high-risk data
- Account must be reviewed quarterly for privilege scope

---

## 5. Related Files

- [admin-checkout-policy.md](../policy/admin-checkout-policy.md)
- [group-policy-baseline.md](../policy/group-policy-baseline.md)

---

## 6. Review History

| Version | Date       | Reviewer         | Notes                 |
|---------|------------|------------------|------------------------|
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
