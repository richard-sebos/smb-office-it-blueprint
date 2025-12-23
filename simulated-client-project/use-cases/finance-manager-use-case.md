<!--
███████████████████████████████████████████████████████████████
  🧾 SMB Office IT Blueprint – Project Document
  Doc ID: USECASE-ROLE-FINANCE-001
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
  Tags: [finance, accounting, privileged-data, role]
  Data Sensitivity: Simulated PII, Financial Records
  Compliance: SOX
  Publish Target: Internal
  Summary: >
    Defines the business responsibilities, IT access requirements, and security controls for the Finance Manager role within the simulated SMB office environment.
  Read Time: ~6 min
███████████████████████████████████████████████████████████████
-->

# 📘 Finance Manager Role – Use Case and IT Profile

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

To define the IT profile, access scope, and security requirements for the **Finance Manager** role in the simulated business environment, ensuring protection of sensitive financial and client data while enabling daily operational efficiency.

---

## 2. Background

The Finance Manager is responsible for **financial oversight, reporting, budgeting, payroll coordination, and compliance**. This role requires elevated access to sensitive financial data but must operate under strict access controls, auditing, and separation of duties.

This use case informs:
- Active Directory group design
- File share permissions
- Audit and logging requirements
- Automation of onboarding/offboarding

---

## 3. Objectives

- Clearly define **what systems and data the Finance Manager can access**
- Enforce **least privilege** while supporting business operations
- Support auditability and compliance requirements (e.g., SOX-like controls)
- Provide a repeatable blueprint for automation and testing

---

## 4. Structure / Body

### 4.1 Job Summary

- **Title:** Finance Manager  
- **Department:** Finance  
- **Location:** Finance Office  
- **Workstation ID:** finance-ws01  
- **Role Type:** Business-Critical / Data-Sensitive

---

### 4.2 Business Responsibilities

| Responsibility                  | Description                                              |
|---------------------------------|----------------------------------------------------------|
| Financial Reporting             | Monthly, quarterly, and annual financial reports         |
| Budget Management               | Forecasting, variance analysis, cost controls            |
| Payroll Oversight               | Review and approval of payroll data                      |
| Accounts Payable/Receivable     | Oversight of invoices and payments                       |
| Client Billing                  | Review of client invoices and billing records            |
| Audit Support                   | Provide data for internal or external audits              |

---

### 4.3 IT Access Requirements

| Resource / System                | Access Level      | Notes                                  |
|----------------------------------|-------------------|----------------------------------------|
| Finance Workstation              | Standard User     | Hardened desktop profile               |
| Finance File Shares              | Read/Write        | Finance-only access                    |
| Client Billing Data              | Read/Write        | Sensitive – audited                    |
| HR Payroll Files                 | Read-Only         | Segregated access                      |
| Email                            | Full Access       | With DLP policies                      |
| Accounting Application           | Full User Access  | Role-based permissions                 |

---

### 4.4 Active Directory Group Memberships

| AD Group Name                    | Purpose                                  |
|----------------------------------|------------------------------------------|
| `GG-Finance`                     | Primary department group                 |
| `SG-Finance-Files-RW`            | Finance file share access                |
| `SG-Client-Billing`              | Client invoice and billing data          |
| `SG-Payroll-ReadOnly`            | Payroll visibility (no modification)     |
| `SG-Printer-Finance`             | Finance printer access                   |

> ❗ Direct permissions must **never** be assigned to the user account.  
> All access is managed via **security groups**.

---

### 4.5 File and Application Access

| Server     | Path / Application                          | Access Level |
|------------|---------------------------------------------|--------------|
| `files01`  | `\\files01\finance`                          | Read/Write  |
| `files01`  | `\\files01\clients\billing`                 | Read/Write  |
| `files01`  | `\\files01\hr\payroll`                      | Read-Only   |
| `print01`  | `Finance-Printer`                           | Print       |
| App Server | Accounting / ERP Application                | Role-Based  |

---

### 4.6 Security and Compliance Considerations

- Subject to **financial data handling policies**
- All file access logged via **auditd**
- No sudo or administrative privileges
- USB storage access disabled
- Screens auto-lock after 10 minutes
- Access reviewed quarterly
- Changes to finance data require **dual control** where applicable
- Included in **SOX-style audit simulations**

---

## 5. Related Files

- [finance-department-policy.md](../policy/finance-department-policy.md)
- [file-share-permissions.md](../policy/file-share-permissions.md)
- [auditd-finance-rules.md](../../implementation/security/auditd-finance-rules.md)

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
| IT Code Auditor
