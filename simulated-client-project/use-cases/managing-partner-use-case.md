<!--
███████████████████████████████████████████████████████████████
  🧾 SMB Office IT Blueprint – Project Document
  Doc ID: USECASE-ROLE-MANAGING-001
  Author: IT Business Analyst
  Created: 2025-12-22
  Updated: 2025-12-22
  Version: v1.0
  Status: Draft
  Confidentiality: Restricted
  Project Phase: Planning
  Category: Business Policy
  Audience: Mixed
  Owners: SMB Analyst, IT Business Analyst
  Reviewers: IT Security Analyst, AD Architect
  Tags: [executive, managing-partner, leadership, privileged-access]
  Data Sensitivity: Financials, HR Summary, Strategic Plans
  Compliance: Employment Standards, Data Governance
  Publish Target: Internal Executive View Only
  Summary: >
    Defines the responsibilities, permissions, and security boundaries for the Managing Partner role in the simulated business lab, including privileged data access, executive reports, and auditing requirements.
  Read Time: ~5–6 min
███████████████████████████████████████████████████████████████
-->

# 📘 Managing Partner – Use Case and IT Profile

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
  - [4.6 Security and Oversight](#46-security-and-oversight)
- [5. Related Files](#5-related-files)
- [6. Review History](#6-review-history)
- [7. Departmental Approval Checklist](#7-departmental-approval-checklist)

---

## 1. Purpose

To define the systems access, document visibility, and executive permissions for the **Managing Partner**, including privileged access to financial, HR, and performance data with appropriate security controls.

---

## 2. Background

The Managing Partner leads business strategy and operational oversight, requiring access to **confidential reports, performance dashboards, and client summaries**. This access is tightly controlled, audited, and limited to read-only in most shared systems.

---

## 3. Objectives

- Grant secure, view-based access to sensitive organizational content
- Protect executive communication and financials via encryption and audit
- Prevent privilege escalation or inappropriate access
- Ensure access is traceable, compartmentalized, and policy-bound

---

## 4. Structure / Body

### 4.1 Job Summary

- **Title:** Managing Partner  
- **Department:** Executive / Leadership  
- **Workstation ID:** exec-ws01  
- **Role Type:** Strategic Decision Maker  

---

### 4.2 Responsibilities

| Responsibility               | Description                                         |
|------------------------------|-----------------------------------------------------|
| Business Oversight           | Monitor department KPIs, resource utilization       |
| Strategic Planning           | Review roadmaps, security initiatives, operations   |
| Financial Review             | View financial summaries and planning docs          |
| HR Oversight                 | View HR metrics, org structure, headcount           |
| Client Summaries             | Review performance or billing summaries per client  |
| Confidential Communications  | Send and receive secure executive communications    |

---

### 4.3 IT Access Requirements

| Resource / System            | Access Level   | Notes                                     |
|------------------------------|----------------|--------------------------------------------|
| Executive Workstation        | Standard User  | Device hardened and isolated               |
| Financial Summaries          | Read-Only      | Access via encrypted share                 |
| HR Summary Reports           | Read-Only      | No access to detailed personnel records    |
| Client Review Folders        | Read-Only      | Summary-level only, per policy             |
| Strategic Planning Docs      | Read/Write     | Draft/edit strategic plans only            |
| Email + Secure Messaging     | Full Access    | Encrypted communication preferred          |

---

### 4.4 Active Directory Group Memberships

| AD Group Name                          | Purpose                                     |
|----------------------------------------|---------------------------------------------|
| `GG-Exec-Leadership`                   | Primary assignment group                    |
| `SG-Strategic-Docs-RW`                 | Access to strategic documentation drafts    |
| `SG-HR-Summary-Reports`                | Read-only access to HR performance metrics  |
| `SG-Financial-Summary-Access`          | View access to quarterly/yearly summaries   |
| `SG-Client-Summaries-RO`               | Read-only access to high-level client info  |
| `SG-Encrypted-Email-Execs`             | Required for secure email enforcement       |

---

### 4.5 File and Application Access

| Server     | Path / Resource                             | Access Level |
|------------|----------------------------------------------|--------------|
| `files01`  | `\\files01\executive\finance-summaries`      | Read-Only   |
| `files01`  | `\\files01\executive\hr-summary-reports`     | Read-Only   |
| `files01`  | `\\files01\strategic\plans\current`          | Read/Write  |
| `vault01`  | Encrypted file storage (sensitive memos)     | Encrypted   |
| Messaging  | Secure Email / Messaging App (Signal, etc.)  | Full Access |

---

### 4.6 Security and Oversight

- All access to financial and HR summaries is **read-only**  
- Files are stored on **encrypted shares** or with **git-crypt**, if version-controlled  
- Executive workstation protected by full disk encryption (FDE)  
- Access is **audited and reported** quarterly by the IT Security Analyst  
- Role is **excluded from all administrative access**  
- Emails should default to **S/MIME or GPG encryption** where available  
- Any new client access requires **formal IT Security review**  

---

## 5. Related Files

- [executive-security-policy.md](../policy/executive-security-policy.md)
- [financial-data-access-guidelines.md](../../implementation/security/financial-data-access-guidelines.md)
- [secure-email-policy.md](../../implementation/security/secure-email-policy.md)

---

## 6. Review History

| Version | Date       | Reviewer             | Notes         |
|---------|------------|----------------------|---------------|
| v1.0    | 2025-12-22 | IT Business Analyst  | Initial draft |

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
