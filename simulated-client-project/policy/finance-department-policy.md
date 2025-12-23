<!--
███████████████████████████████████████████████████████████████
  🧾 SMB Office IT Blueprint – Project Document
  Doc ID: POLICY-FINANCE-001
  Author: IT Business Analyst
  Created: 2025-12-23
  Updated: 2025-12-23
  Version: v1.0
  Status: Draft
  Confidentiality: Restricted
  Project Phase: Planning
  Category: Departmental Policy
  Audience: Mixed
  Owners: Finance Manager, IT Business Analyst
  Reviewers: IT Security Analyst, Project Doc Auditor
  Tags: [finance, policy, access-control, compliance, roles]
  Data Sensitivity: Moderate (Simulated Access Only)
  Compliance: Internal Governance / Simulated SMB Standards
  Publish Target: Internal (Simulated)
  Summary: >
    This document outlines the access, operational standards, and compliance controls for the Finance Department within the SMB Office IT Blueprint project. It includes data handling rules, IT system dependencies, and department-specific procedures.
  Read Time: ~6 min
███████████████████████████████████████████████████████████████
-->

# 💰 Finance Department Policy

---

## 📍 Table of Contents

- [1. Purpose](#1-purpose)
- [2. Scope](#2-scope)
- [3. Responsibilities](#3-responsibilities)
- [4. Information Sensitivity](#4-information-sensitivity)
- [5. System Access Requirements](#5-system-access-requirements)
- [6. File Share Usage](#6-file-share-usage)
- [7. Print Access and Controls](#7-print-access-and-controls)
- [8. Data Backup and Recovery](#8-data-backup-and-recovery)
- [9. Acceptable Use](#9-acceptable-use)
- [10. Review & Audit Controls](#10-review--audit-controls)
- [11. Related Documents](#11-related-documents)
- [12. Review History](#12-review-history)
- [13. Departmental Approval Checklist](#13-departmental-approval-checklist)

---

## 1. Purpose

The purpose of this policy is to govern the handling of financial information, systems access, and operational procedures for the Finance Department, ensuring confidentiality, integrity, and compliance with internal controls.

---

## 2. Scope

This policy applies to:
- All simulated Finance staff (e.g., Finance Manager, assistants)
- IT systems used to access or store financial data
- Any file shares or documents classified as “financial” or “restricted”

---

## 3. Responsibilities

| Role             | Responsibility                                      |
|------------------|------------------------------------------------------|
| Finance Manager  | Oversee department operations, approve access       |
| Admin Assistant  | Prepare expense documents, with limited access      |
| IT Admin         | Manage permissions to Finance resources             |
| Security Analyst | Monitor access logs and conduct audits              |

---

## 4. Information Sensitivity

All finance data is classified at minimum as **“Restricted”**.

| Data Type                  | Classification | Notes                             |
|----------------------------|----------------|-----------------------------------|
| Expense Reports            | Restricted     | May contain employee info         |
| Payroll Summaries          | Confidential   | Controlled by HR/Finance          |
| Client Invoices            | Restricted     | Stored on `\\files01\finance`     |
| Budget Forecasts           | Confidential   | Access by Finance & Execs only    |
| General Ledger Snapshots   | Restricted     | Regularly reviewed                |

---

## 5. System Access Requirements

| System/Service            | Required Role         | Authentication Type    |
|---------------------------|------------------------|--------------------------|
| `finance-ws01`            | Finance Manager        | AD Domain Account        |
| Shared File Server        | Finance Group          | AD + ACL                 |
| Internal Print Server     | Finance Print Group    | AD Print Policy          |
| Simulated ERP/Finance App | Finance Manager        | AD + App Account (local) |

> 🔐 Access to sensitive exports (e.g., Excel with client billing) requires **Admin IT Checkout** logged via support ticket.

---

## 6. File Share Usage

| Share Location                  | Access Group           | Permissions  |
|---------------------------------|------------------------|--------------|
| `\\files01\finance\invoices`    | `GG-Finance-Staff`     | RW           |
| `\\files01\finance\payroll`     | `GG-Finance-Exec`      | RO           |
| `\\files01\finance\budgets`     | `GG-Finance-Exec`      | RW           |
| `\\files01\shared\company`      | All Staff              | RO           |

Files must be stored in **Excel or PDF** formats with naming conventions:
