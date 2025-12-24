<!--
███████████████████████████████████████████████████████████████
  🧾 SMB Office IT Blueprint – Project Document
  Doc ID: POLICY-GPO-BASELINE-001
  Author: IT AD Architect, IT Security Analyst
  Created: 2025-12-23
  Updated: 2025-12-23
  Version: v1.0
  Status: Final
  Confidentiality: Internal
  Project Phase: Implementation
  Category: Policy – Group Policy
  Audience: IT
  Owners: IT AD Architect, Linux Admin/Architect
  Reviewers: Project Doc Auditor, Project Manager
  Tags: [group policy, GPO, samba, baseline, domain, security]
  Data Sensitivity: Simulated Domain Controls
  Compliance: Internal Security Standards
  Publish Target: Internal
  Summary: >
    Defines the baseline Group Policy Objects (GPOs) to be applied in the Samba Active Directory environment to enforce standard security, login behavior, and user experience across all departments and systems.
  Read Time: ~7 min
███████████████████████████████████████████████████████████████
-->

# 🛡️ Group Policy Baseline – Samba AD Domain

---

## 📍 Table of Contents

- [1. Purpose](#1-purpose)
- [2. Scope](#2-scope)
- [3. GPO Strategy](#3-gpo-strategy)
- [4. Default Domain Policy](#4-default-domain-policy)
- [5. Department-Specific Policies](#5-department-specific-policies)
- [6. Security Settings](#6-security-settings)
- [7. Login & UX Settings](#7-login--ux-settings)
- [8. USB & Device Control](#8-usb--device-control)
- [9. Policy Deployment Plan](#9-policy-deployment-plan)
- [10. Related Documents](#10-related-documents)
- [11. Review History](#11-review-history)
- [12. Departmental Approval Checklist](#12-departmental-approval-checklist)

---

## 1. Purpose

To standardize system behavior, security configuration, and desktop experience for users in the simulated SMB Office by defining a consistent set of Group Policy Objects (GPOs) across departments.

---

## 2. Scope

Applies to:
- All domain-joined workstations and users
- Policies implemented via Samba Active Directory (`dc01`, `dc02`)
- Oracle Linux and Windows-compatible clients (via `sssd`, `winbind`, or GPO-compatible login scripts)

---

## 3. GPO Strategy

- Use **Default Domain Policy** for global settings (security, password policy)
- Create **OU-specific GPOs** for HR, Finance, Professional Services, etc.
- Apply **filtered GPOs** via group membership (e.g., `GG-HR-Staff`)
- Avoid setting user-specific GPOs unless required
- GPO configurations stored in version-controlled directory (encrypted)

---

## 4. Default Domain Policy

| Setting                                 | Value                       |
|-----------------------------------------|-----------------------------|
| Minimum password length                 | 12 characters               |
| Maximum password age                    | 90 days                     |
| Account lockout threshold               | 5 failed attempts           |
| Lockout duration                        | 15 minutes                  |
| Enforce password history                | 10 previous passwords       |
| Require complex passwords               | Yes                         |
| Allow log on locally                    | Domain Users, GG-IT-Admins  |
| Audit logon events                      | Success and failure         |
| Time synchronization policy             | Enabled                     |

---

## 5. Department-Specific Policies

### HR Department (OU=HR)
- Home drives mapped to `\\files01\hr\$USERNAME`
- Desktop wallpaper with HR branding
- Shared drive: Read/Write for `GG-HR-Staff` only

### Finance Department (OU=Finance)
- Auto-mount finance reports share
- Enhanced logging (auditd + GPO)
- Disable non-approved applications (AppLocker)

### Professional Services (OU=Professional)
- Shared templates auto-loaded
- Sudo via AD group `GG-Prof-Sudo`
- Allow access to project share and printers

---

## 6. Security Settings

| Feature                           | Enabled | Notes                                |
|-----------------------------------|---------|--------------------------------------|
| Interactive logon message         | ✅      | Legal notice shown to all users      |
| USB storage blocking              | ✅      | Except for `GG-Exec` and IT          |
| Remote desktop restrictions       | ✅      | Allowed only for IT/Managers         |
| Disable guest accounts            | ✅      |                                      |
| Require screensaver after idle   | ✅      | 10-minute timeout                    |
| Samba log level (domain logons)   | 3       | Auditing domain logons               |

---

## 7. Login & UX Settings

- Standard login script mounts department shares
- Login banner reflects company branding
- Printers auto-installed based on AD group
- Office templates preloaded (per department)
- Desktop shortcuts: Shared drives, company handbook

---

## 8. USB & Device Control

| Group/Role           | USB Access | Notes                               |
|----------------------|------------|-------------------------------------|
| `GG-Exec`, IT Admins | ✅         | Full access                         |
| HR/Finance Staff     | ❌         | Blocked by default                  |
| Interns              | ❌         | Blocked entirely                    |
| Controlled via       | `udev` + GPO Login Scripts |

---

## 9. Policy Deployment Plan

| Phase | Task                                      | Tool          | Owner             |
|-------|-------------------------------------------|---------------|--------------------|
| 1     | Define GPO structure in Samba AD          | `samba-tool`  | IT AD Architect    |
| 2     | Map GPOs to OUs and security groups       | GPO editor    | IT Security Analyst|
| 3     | Test in lab environment                   | Virtual DCs   | Linux Admin        |
| 4     | Rollout in production lab                 | GPO replication| AD Architect       |
| 5     | Monitor with audit logs                   | auditd        | Security Analyst   |
| 6     | Version changes in encrypted repo         | Git-crypt     | Project Manager    |

---

## 10. Related Documents

- [user-access-policy.md](user-access-policy.md)
- [admin-checkout-policy.md](admin-checkout-policy.md)
- [auditd-finance-rules.md](../security/auditd-finance-rules.md)
- [access-control-matrix.md](../security/access-control-matrix.md)
- [file-share-permissions.md](../security/file-share-permissions.md)

---

## 11. Review History

| Version | Date       | Reviewer           | Notes                 |
|---------|------------|--------------------|------------------------|
| v1.0    | 2025-12-23 | IT AD Architect    | Initial Baseline Draft |

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
