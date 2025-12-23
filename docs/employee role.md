
<!--
███████████████████████████████████████████████████████████████
  🧾 SMB Office IT Blueprint – Project Document
  Doc ID: DOC-SPEC-004
  Author: IT Documentation Wizard
  Created: 2025-12-22
  Updated: 2025-12-22
  Version: v1.0
  Status: Final
  Confidentiality: Internal
  Project Phase: Planning
  Category: Design Spec
  Audience: IT
  Owners: Linux Admin, IT Business Analyst
  Reviewers: AD Architect, Code Auditor
  Tags: infrastructure, samba, users, system-needs
  Data Sensitivity: None
  Compliance: None
  Publish Target: Internal
  Summary: >
    Infrastructure and general application system requirements for common employee roles in a simulated SMB professional office, excluding business-specific applications.
  Read Time: ~7 min
███████████████████████████████████████████████████████████████
-->

# 📘 System Needs by Role – Professional Office Environment (Infrastructure Focus)

---

## 📍 Table of Contents

1. [Purpose](#1-purpose)  
2. [Background](#2-background)  
3. [Objectives](#3-objectives)  
4. [Structure / Body](#4-structure--body)  
5. [Related Files](#5-related-files)  
6. [Review History](#6-review-history)  
7. [Departmental Approval Checklist](#7-departmental-approval-checklist)

---

## 1. Purpose

Define standardized system infrastructure and application needs per employee role in a simulated small-to-mid-sized professional office environment. This supports role-specific provisioning, access control, security monitoring, and infrastructure planning for a Samba AD-based lab.

---

## 2. Background

In the Samba AD Lab Series, a realistic office simulation is essential for modeling proper domain controller roles, file and print services, and group-based access policies. This document focuses exclusively on generic IT needs (infrastructure + general-use applications), leaving industry-specific tools (e.g., legal, accounting) for future scope.

---

## 3. Objectives

- Map typical office roles to infrastructure services and general applications
- Define access control requirements per role for file shares and printing
- Identify monitoring needs (auditd, SELinux) based on data sensitivity
- Inform Active Directory group structure and VM provisioning in the lab

---

## 4. Structure / Body

### 🧩 System Needs Matrix (By Role)

| **Role**                  | **Infrastructure Services**                                                                 | **General Applications**                                         | **Access Controls**                                                                                     | **Monitoring / Security**                                                 |
|---------------------------|----------------------------------------------------------------------------------------------|------------------------------------------------------------------|----------------------------------------------------------------------------------------------------------|---------------------------------------------------------------------------|
| **Managing Partner**      | - AD Auth<br>- Drive Mounts<br>- Remote Access (VPN/SSH)<br>- Color Print Queue             | - Office Suite<br>- PDF Viewer<br>- Email Client                 | - Full read to all folders<br>- Write to Exec & Projects<br>- Member of `GRP_Executive`                 | - Audit read access to HR/Finance<br>- SELinux enforced                 |
| **Senior Professional**   | - AD Join<br>- Project Share Access<br>- Color Printing                                    | - Office Suite<br>- File Browser<br>- Terminal Emulator          | - R/W to project folders<br>- Read-only to templates<br>- `GRP_Professional_Senior`                     | - Monitor file writes<br>- Log group file access                         |
| **Junior Professional**   | - AD Login<br>- File Share Mounts<br>- Print (B&W only)                                     | - Office Suite<br>- PDF Viewer<br>- Terminal (non-sudo)          | - R/W to drafts<br>- Read-only to `/templates`<br>- `GRP_Professional_Junior`                          | - Audit write access<br>- Enforce SELinux separation                     |
| **Admin Assistant**       | - AD Login<br>- File Shares (`/admin`, `/templates`)<br>- Color Printing                    | - Office Suite<br>- Calendar<br>- File Manager                   | - R/W to `/admin`<br>- Read-only to HR/Finance forms<br>- `GRP_Admin`                                  | - Monitor sensitive access<br>- Audit form handling                      |
| **HR Manager**            | - AD Join<br>- Secure HR Share<br>- Private Print Queue                                     | - Office Suite<br>- PDF Tools<br>- GPG Tool                       | - Full R/W to `/hr`<br>- No access to other dept folders<br>- `GRP_HR`                                  | - Strict auditd logging<br>- SELinux enforced                            |
| **Finance Manager**       | - AD Auth<br>- Secure Finance Share<br>- Color Printing                                     | - Spreadsheet Tool<br>- PDF Viewer<br>- Archive Utility          | - Full R/W to `/finance`<br>- No access to `/hr`<br>- `GRP_Finance`                                    | - Audit report generation<br>- SELinux confinement                       |
| **IT Administrator**      | - AD Admin Rights<br>- Sudo Access<br>- Full Server Access (SSH, Proxmox)                   | - Terminal<br>- Ansible<br>- Vim/Nano                             | - Member of `GRP_IT` & `sudo`<br>- Access to all shares and system configs                             | - Full audit logs<br>- SELinux logs<br>- Monitor all admin actions       |
| **Intern / Temp**         | - Temporary AD User<br>- File Share (Interns)<br>- B&W Print Queue                          | - Office Suite (Basic)<br>- File Viewer                          | - R/O or limited R/W to `/projects/interns`<br>- `GRP_Intern`                                          | - Monitor login/logout<br>- Deny access to HR/Finance                    |
| **Receptionist**          | - AD Login<br>- Calendar/Shared Resources<br>- B&W Printing                                 | - Email Client<br>- Office Suite<br>- Calendar App               | - R/W to `/admin/schedules`<br>- No access to HR/Finance<br>- `GRP_Reception`                          | - Minimal audit logging<br>- Login time monitoring                       |

---

### 🔧 Core Infrastructure Services Used

| **Service**              | **Purpose**                                                                 |
|--------------------------|------------------------------------------------------------------------------|
| **Samba AD (SSSD/Kerberos)** | Central authentication and user/group management                         |
| **File Server (Samba)**  | Department-specific shares with ACL-based access                            |
| **CUPS Print Server**    | Group-based print access (color vs. B&W), printer auditing                   |
| **auditd**               | File access auditing, especially for sensitive departments                   |
| **SELinux**              | Enforces additional access restrictions and system hardening                 |
| **Proxmox VE**           | Virtualization platform for lab setup and simulation                         |
| **Ansible (optional)**   | Automation of user creation, permissions, and workstation setup              |

---

## 5. Related Files

- [`ad-ou-group-design.md`](../docs/ad-ou-group-design.md)  
- [`file-server-share-layout.md`](../docs/file-server-share-layout.md)  
- [`print-access-policy.md`](../docs/print-access-policy.md)  
- [`auditd-policy-template.md`](../docs/auditd-policy-template.md)  
- [`selinux-samba-hardening.md`](../docs/selinux-samba-hardening.md)

---

## 6. Review History

```markdown
## 6. Review History

| Version | Date       | Reviewer           | Notes                          |
|---------|------------|--------------------|--------------------------------|
| v1.0    | 2025-12-22 | IT Documentation Wizard | Initial compliant version |
````

---

## 7. Departmental Approval Checklist

```markdown
## 7. Departmental Approval Checklist

| Department / Agent       | Reviewed | Reviewer Notes |
|--------------------------|----------|----------------|
| SMB Analyst              | [ ]      |                |
| IT Business Analyst      | [ ]      |                |
| Project Doc Auditor      | [ ]      |                |
| IT Security Analyst      | [ ]      |                |
| IT AD Architect          | [ ]      |                |
| Linux Admin/Architect    | [ ]      |                |
| Ansible Programmer       | [ ]      |                |
| IT Code Auditor          | [ ]      |                |
| SEO Analyst              | [ ]      |                |
| Content Editor           | [ ]      |                |
| Project Manager          | [ ]      |                |
| Task Assistant           | [ ]      |                |
```

---


