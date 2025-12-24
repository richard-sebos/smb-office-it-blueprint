<!--
███████████████████████████████████████████████████████████████
  🧾 SMB Office IT Blueprint – Project Document
  Doc ID: POLICY-ADMIN-CHECKOUT-001
  Author: IT Security Analyst, IT Business Analyst
  Created: 2025-12-23
  Updated: 2025-12-23
  Version: v1.0
  Status: Final
  Confidentiality: Confidential
  Project Phase: Implementation
  Category: Policy – Security & Access Control
  Audience: IT, Project Leads, Department Managers
  Owners: IT Security Analyst, IT AD Architect
  Reviewers: Project Doc Auditor, Project Manager
  Tags: [admin, security, access, policy, checkout, audit, elevated]
  Data Sensitivity: Elevated Privilege Workflow
  Compliance: Internal Role-Based Access Controls (RBAC)
  Publish Target: Internal
  Summary: >
    Defines the administrative access checkout process for accessing restricted systems, sensitive data, or privileged functions in the simulated SMB Office environment. Ensures traceability, accountability, and temporary access enforcement.
  Read Time: ~5 min
███████████████████████████████████████████████████████████████
-->

# 🔐 Admin Access Checkout Policy

---

## 📍 Table of Contents

- [1. Purpose](#1-purpose)
- [2. Scope](#2-scope)
- [3. Access Categories](#3-access-categories)
- [4. Checkout Workflow](#4-checkout-workflow)
- [5. Access Duration & Expiry](#5-access-duration--expiry)
- [6. Logging & Audit](#6-logging--audit)
- [7. Violations & Enforcement](#7-violations--enforcement)
- [8. Related Documents](#8-related-documents)
- [9. Review History](#9-review-history)
- [10. Departmental Approval Checklist](#10-departmental-approval-checklist)

---

## 1. Purpose

To enforce a controlled and auditable process for administrative access to sensitive data and systems, limiting risk and aligning with internal access control policy.

---

## 2. Scope

This policy applies to:
- Access to **executive-level file shares**
- Access to **finance or HR data**
- Changes to **Active Directory groups**
- Temporary **elevated sudo or root permissions**
- Use of **privileged Ansible roles**
- Access to **client deliverables**
- Manual overrides or backdoor access for troubleshooting

---

## 3. Access Categories

| Category                     | Examples                                     |
|------------------------------|----------------------------------------------|
| Admin File Access            | Executive folders, finance exports          |
| Domain-Level Changes         | AD group edits, user moves                  |
| Security Configurations      | auditd, SELinux, AIDE                        |
| Privileged Systems           | `/etc/samba/*`, Ansible vault credentials   |
| Emergency Break-Glass Access | Root shell on DCs or key servers             |

---

## 4. Checkout Workflow

1. **Request Initiation**  
   Submitted via secure form or ticket by authorized user.

2. **Approval**  
   Reviewed and approved by IT Security Analyst or Department Head.

3. **Access Granted**  
   Limited by scope, system, and time window. Logged in `admin-checkout.log`.

4. **Audit Flagging**  
   Access is tagged and monitored by `auditd`.

5. **Access Revoked Automatically**  
   Revoked by Ansible job or cron script at expiration time.

> 🔄 **Emergency Access** requires post-access review and documentation within 24 hours.

---

## 5. Access Duration & Expiry

| Access Type                   | Max Duration   |
|-------------------------------|----------------|
| Standard Admin Checkout       | 4 hours         |
| Client File Review            | 2 hours         |
| Root/Emergency Access         | 1 hour (review) |
| Sudo Role Elevation (via AD)  | Until logout    |

All access is time-limited and should **not persist** beyond operational need.

---

## 6. Logging & Audit

All access grants must be recorded in:

- `admin-checkout.log` (encrypted repo)
- `auditd` event logs
- AD Group modification history (where applicable)

### Required Log Fields:

- Username
- Access type
- Reason for access
- Approver name
- Start and end timestamp
- Systems or folders touched

---

## 7. Violations & Enforcement

- Any access without approval is considered a **security violation**
- IT Security reserves the right to **immediately revoke access**
- Repeat violations may result in disciplinary action (simulated)
- All violations logged and reviewed by Project Doc Auditor

---

## 8. Related Documents

- [user-access-policy.md](user-access-policy.md)
- [file-share-permissions.md](../security/file-share-permissions.md)
- [access-control-matrix.md](../security/access-control-matrix.md)
- [auditd-finance-rules.md](../security/auditd-finance-rules.md)
- [executive-security-policy.md](executive-security-policy.md)

---

## 9. Review History

| Version | Date       | Reviewer             | Notes           |
|---------|------------|----------------------|-----------------|
| v1.0    | 2025-12-23 | IT Security Analyst  | Initial Release |

---

## 10. Departmental Approval Checklist

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
