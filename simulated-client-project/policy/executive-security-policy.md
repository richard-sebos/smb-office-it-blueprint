<!--
███████████████████████████████████████████████████████████████
  🧾 SMB Office IT Blueprint – Project Document
  Doc ID: POLICY-SEC-EXEC-001
  Author: IT Security Analyst
  Created: 2025-12-22
  Updated: 2025-12-22
  Version: v1.0
  Status: Draft
  Confidentiality: Restricted
  Project Phase: Planning
  Category: Security Policy
  Audience: IT
  Owners: IT Security Analyst, Project Manager
  Reviewers: Linux Admin/Architect, AD Architect
  Tags: [executive, policy, encryption, access-control, workstation]
  Data Sensitivity: Simulated Executive & Financial Data
  Compliance: ISO-27001, Data Governance
  Publish Target: Internal – Leadership Only
  Summary: >
    Security policy defining acceptable use, encryption requirements, system hardening, and access control for executive-level users (e.g. Managing Partner) in the SMB simulated environment.
  Read Time: ~7 min
███████████████████████████████████████████████████████████████
-->

# 🔐 Executive Security Policy

---

## 📍 Table of Contents

- [1. Purpose](#1-purpose)
- [2. Background](#2-background)
- [3. Objectives](#3-objectives)
- [4. Security Policy Scope](#4-security-policy-scope)
- [5. System Requirements](#5-system-requirements)
- [6. Data Access & Classification](#6-data-access--classification)
- [7. Encryption Requirements](#7-encryption-requirements)
- [8. Communication Policy](#8-communication-policy)
- [9. Auditing & Monitoring](#9-auditing--monitoring)
- [10. Violations & Exceptions](#10-violations--exceptions)
- [11. Related Files](#11-related-files)
- [12. Review History](#12-review-history)
- [13. Departmental Approval Checklist](#13-departmental-approval-checklist)

---

## 1. Purpose

This policy defines the minimum technical, procedural, and physical security controls for executive users (e.g. Managing Partner) to ensure confidentiality and integrity of high-value business information.

---

## 2. Background

Executive workstations, documents, and communications often contain financial summaries, HR data, and strategic plans. These systems must be protected against misuse, leakage, and unauthorized access.

---

## 3. Objectives

- Restrict access to sensitive executive content via encrypted storage
- Enforce system hardening and logging on executive workstations
- Define acceptable communication channels and data handling
- Protect leadership personnel from phishing, spoofing, and exfiltration threats

---

## 4. Security Policy Scope

| Area             | Included? | Notes                                  |
|------------------|-----------|----------------------------------------|
| Executive Devices| ✅         | All executive workstations (`exec-wsXX`) |
| Executive Shares | ✅         | HR summary, financials, strategic docs |
| Email Systems    | ✅         | Email, messaging, and alerting         |
| Access Rights    | ✅         | AD groups, file ACLs, encryption keys  |
| Internet Usage   | ✅         | Restricted to business-only websites   |

---

## 5. System Requirements

| Control                           | Requirement                              |
|----------------------------------|-------------------------------------------|
| Endpoint OS                      | Hardened Oracle Linux 9 (GUI-based)       |
| Local Account                    | No local root login                       |
| Authentication                   | AD-integrated; MFA required               |
| Drive Encryption                 | Full Disk Encryption (LUKS or equivalent) |
| Removable Media                  | Disabled by default                       |
| Screensaver Timeout              | Auto-lock after 5 minutes idle            |
| Updates                          | Weekly via secured internal repo          |

---

## 6. Data Access & Classification

| Data Type               | Access Method      | Notes                                   |
|-------------------------|--------------------|------------------------------------------|
| Financial Summaries     | Encrypted share    | Read-only for Managing Partner           |
| HR Performance Reports  | Encrypted share    | Read-only summary data only              |
| Strategic Documents     | Internal Git repo  | Write access allowed, encryption enabled |
| Client Billing Overview | Encrypted folder   | Read-only                                |

---

## 7. Encryption Requirements

| Asset                        | Encryption Required? | Method / Tool         |
|-----------------------------|----------------------|------------------------|
| Workstation Disk            | ✅                    | LUKS                   |
| File Shares (executive)     | ✅                    | Encrypted ZFS datasets |
| Git Content (impl/articles) | ✅                    | `git-crypt`            |
| Email                       | ✅                    | S/MIME or GPG enforced |
| Messaging                   | ✅                    | Signal / Mattermost E2EE |

---

## 8. Communication Policy

- All outbound executive emails must use **corporate domain**
- Executive emails must be signed and encrypted (GPG or S/MIME)
- No use of personal email for work-related tasks
- Messaging must occur via **approved encrypted platform**
- External document sharing is **prohibited** unless routed through **IT-reviewed process**

---

## 9. Auditing & Monitoring

| Audit Feature              | Status | Frequency         |
|---------------------------|--------|-------------------|
| File Access Logs          | ✅     | Real-time via `auditd` |
| Login Attempt Logging     | ✅     | Daily review       |
| sudo / privilege escalation | ✅     | Alerted            |
| Executive Share Changes   | ✅     | Logged and rotated |
| Email Encryption Failure  | ✅     | Weekly audit       |

---

## 10. Violations & Exceptions

- Any policy violations will be escalated to the **IT Security Officer**
- Exceptions must be documented and approved by both **IT Security** and **Managing Partner**
- All exceptions must have **expiration dates** and re-approval workflows

---

## 11. Related Files

- [managing-partner-use-case.md](../use-cases/managing-partner-use-case.md)
- [secure-email-policy.md](../security/secure-email-policy.md)
- [access-control-matrix.md](../../implementation/security/access-control-matrix.md)

---

## 12. Review History

| Version | Date       | Reviewer            | Notes            |
|---------|------------|---------------------|------------------|
| v1.0    | 2025-12-22 | IT Security Analyst | Initial draft    |

---

## 13. Departmental Approval Checklist

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
