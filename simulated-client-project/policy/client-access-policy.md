<!--
███████████████████████████████████████████████████████████████
  🧾 SMB Office IT Blueprint – Project Document
  Doc ID: POLICY-CLIENT-ACCESS-001
  Author: IT Security Analyst, Project Manager
  Created: 2025-12-23
  Updated: 2025-12-23
  Version: v1.0
  Status: Draft
  Confidentiality: Internal
  Project Phase: Implementation
  Category: Policy – Security & Client Interaction
  Audience: IT, Department Managers, Executive Team
  Owners: Project Manager, IT Security Analyst
  Reviewers: Project Doc Auditor
  Tags: [client, access, security, permissions, shares, external]
  Data Sensitivity: High (External Interfaces)
  Compliance: Internal Policy + Simulated Security Standards
  Publish Target: Internal
  Summary: >
    Defines secure, temporary, and auditable access rules for external clients who need to interact with the SMB Office environment. Covers file sharing, authentication, expiration, logging, and approval flows.
  Read Time: ~4 minutes
███████████████████████████████████████████████████████████████
-->

# 🌐 Client Access Policy

---

## 📍 Table of Contents

- [1. Purpose](#1-purpose)
- [2. Scope](#2-scope)
- [3. Approved Access Types](#3-approved-access-types)
- [4. Authentication & Identity](#4-authentication--identity)
- [5. Approval Workflow](#5-approval-workflow)
- [6. Time Limits & Expiration](#6-time-limits--expiration)
- [7. File Sharing Rules](#7-file-sharing-rules)
- [8. Logging & Auditing](#8-logging--auditing)
- [9. Violations](#9-violations)
- [10. Related Documents](#10-related-documents)
- [11. Review History](#11-review-history)
- [12. Departmental Approval Checklist](#12-departmental-approval-checklist)

---

## 1. Purpose

To ensure **secure, limited, and purpose-specific access** is granted to clients while maintaining the confidentiality and integrity of internal systems, files, and communication.

---

## 2. Scope

Applies to:
- All **external clients** accessing shared files or folders
- Any **temporary user accounts** created for client access
- Access to **client-facing platforms**, such as secure portals or shared folders
- Users external to `smb-lab.local` Active Directory domain

---

## 3. Approved Access Types

| Access Type            | Description                                        |
|------------------------|----------------------------------------------------|
| Shared File Access     | Read/download access to approved file shares       |
| Secure Folder Upload   | Temporary write access for document submission     |
| Portal Login           | Client-specific portal credentials (if used)       |
| Video/Meeting Invites  | Teams/Zoom integration with access controls        |

> 🔐 Direct access to internal infrastructure (e.g., Proxmox, Samba shares) is **not permitted** without an approved exception.

---

## 4. Authentication & Identity

- All client access must be **authenticated**
  - Email-based tokens (preferred for portals)
  - Temporary AD-linked account with strong password
  - MFA required for high-sensitivity data (e.g., finance files)
- Email domain must match verified client identity
- All credentials auto-expire (see Section 6)

---

## 5. Approval Workflow

1. **Initiate Access Request**
   - Requested by internal staff (owner of client relationship)

2. **Approval Review**
   - Approved by:
     - Department Manager **AND**
     - IT Security Analyst

3. **Access Provisioned**
   - Handled by IT or automation script
   - Entry logged in `client-access.log`

4. **Expiration Defined**
   - Based on use case (1–30 days max)

---

## 6. Time Limits & Expiration

| Access Type         | Default Expiry | Max Expiry |
|---------------------|----------------|------------|
| File Share Access   | 7 days         | 30 days    |
| Portal Credentials  | 14 days        | 60 days    |
| Upload Folder       | 3 days         | 7 days     |

Access must be **re-requested** if extended use is needed. Expired accounts are **deactivated automatically**.

---

## 7. File Sharing Rules

- Files must be stored in **designated client folders**
  - Example: `\\files01\Clients\AcmeCorp`
- Permissions:
  - Clients → `Read` (default)
  - Internal Staff → `Full Control`
- For confidential docs:
  - Use encrypted ZIP or Nextcloud link
  - Passwords sent separately (SMS or phone call)
- Clients **must not forward** shared links without written approval

---

## 8. Logging & Auditing

All client access is logged in:
- `client-access.log` (Git-encrypted)
- auditd logs (if access is server-authenticated)
- File access timestamps (if Samba logging enabled)

> All logs must be reviewed **monthly** by IT Security.

---

## 9. Violations

The following are policy violations:
- Sharing access without approval
- Sending unencrypted financial or HR data
- Clients accessing unauthorized folders
- Failure to revoke or review expired access

Violations will result in internal follow-up and access review.

---

## 10. Related Documents

- [admin-checkout-policy.md](admin-checkout-policy.md)
- [file-share-permissions.md](file-share-permissions.md)
- [financial-data-access-guidelines.md](../finance/financial-data-access-guidelines.md)
- [secure-email-policy.md](secure-email-policy.md)

---

## 11. Review History

| Version | Date       | Reviewer           | Notes            |
|---------|------------|--------------------|------------------|
| v1.0    | 2025-12-23 | Project Manager    | Initial Draft    |

---

## 12. Departmental Approval Checklist

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
