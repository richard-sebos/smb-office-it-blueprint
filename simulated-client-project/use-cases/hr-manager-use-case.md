<!--
███████████████████████████████████████████████████████████████
  🧾 SMB Office IT Blueprint – Project Document
  Doc ID: USECASE-ROLE-HR-001
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
  Reviewers: IT Security Analyst, IT AD Architect
  Tags: [hr, personnel, onboarding, offboarding, role]
  Data Sensitivity: Simulated PII, HR Records
  Compliance: HIPAA (simulated), Employment Standards
  Publish Target: Internal
  Summary: >
    Documents the HR Manager's responsibilities, IT access needs, and policy enforcement within the simulated small business office environment, including handling of employee records and system onboarding workflows.
  Read Time: ~6 min
███████████████████████████████████████████████████████████████
-->

# 📘 HR Manager Role – Use Case and IT Profile

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
  - [4.5 File and Application Access](#45-file-and-application-access)
  - [4.6 Security and Compliance Considerations](#46-security-and-compliance-considerations)
- [5. Related Files](#5-related-files)
- [6. Review History](#6-review-history)
- [7. Departmental Approval Checklist](#7-departmental-approval-checklist)

---

## 1. Purpose

Define the IT role and responsibilities of the **HR Manager**, including access to personnel records, onboarding tools, and sensitive employee documents.

This document informs the design of file shares, AD groups, and compliance-aligned access controls in the lab.

---

## 2. Background

The HR Manager oversees all aspects of the employee lifecycle, including hiring, offboarding, compliance training, and policy enforcement. These activities involve access to sensitive PII and payroll data and must be tightly controlled and monitored.

---

## 3. Objectives

- Define a secure and productive IT workspace for the HR Manager
- Ensure compliance with employment and privacy standards
- Provide a structure for onboarding automation
- Support integration with audit, file access, and reporting systems

---

## 4. Structure / Body

### 4.1 Job Summary

- **Title:** Human Resources Manager  
- **Department:** HR  
- **Workstation ID:** hr-ws01  
- **Role Type:** Sensitive / Compliance-Critical

---

### 4.2 Business Responsibilities

| Responsibility               | Description                                         |
|------------------------------|-----------------------------------------------------|
| Employee Records Management  | Maintain digital records in secure folders          |
| New Hire Onboarding          | Coordinate account setup and training               |
| Exit Process Management      | Termination, exit interviews, account disablement   |
| Benefits Administration      | Document insurance, PTO, and wellness policies      |
| Policy Enforcement           | Enforce code of conduct, acceptable use, etc.       |
| HR Audits & Reports          | Provide data for compliance reviews                 |

---

### 4.3 IT Access Requirements

| Resource / System             | Access Level   | Notes                                 |
|-------------------------------|----------------|---------------------------------------|
| HR Workstation                | Standard User  | Hardened security profile             |
| HR File Shares                | Read/Write     | HR-only access                        |
| Payroll Folder (Finance)      | Read-Only      | Shared with finance for coordination  |
| Company Policies Folder       | Read/Write     | Shared with all departments           |
| Email                         | Full Access    | DLP and phishing protection enabled   |
| Onboarding Tracker            | Read/Write     | Shared spreadsheet                    |

---

### 4.4 Active Directory Group Memberships

| AD Group Name                  | Purpose                                   |
|--------------------------------|-------------------------------------------|
| `GG-HR`                        | Primary HR group                          |
| `SG-HR-Files-RW`               | Access to HR folder                       |
| `SG-Payroll-ReadOnly`          | Read-only access to payroll               |
| `SG-Policy-Docs`               | Access to company-wide documents          |
| `SG-Onboarding-Access`         | Permission to write to onboarding logs    |

> ⚠️ No direct access to user accounts or password resets without coordination with IT Admin.

---

### 4.5 File and Application Access

| Server     | Path / Application                          | Access Level |
|------------|---------------------------------------------|--------------|
| `files01`  | `\\files01\hr`                              | Read/Write  |
| `files01`  | `\\files01\finance\payroll`                | Read-Only   |
| `files01`  | `\\files01\company\policies`               | Read/Write  |
| `hrapp01`  | HR Self-Service Portal (internal only)      | Admin User  |
| `print01`  | `HR-Printer`                                | Print       |

---

### 4.6 Security and Compliance Considerations

- Subject to **employee data privacy and protection rules**
- Folder access limited via group-based ACLs
- No access to IT administration or privileged systems
- USB storage disabled by policy
- All activity in HR folders is **logged via auditd**
- GPO policies enforce screen lock, antivirus, and patching
- HR account reviewed quarterly with AD Architect

---

## 5. Related Files

- [hr-data-retention-policy.md](../policy/hr-data-retention-policy.md)
- [onboarding-workflow.md](../onboarding/onboarding-workflow.md)
- [file-permissions-audit.md](../../implementation/security/file-permissions-audit.md)

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
