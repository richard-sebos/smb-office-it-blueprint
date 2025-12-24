<!--
███████████████████████████████████████████████████████████████
  🧾 SMB Office IT Blueprint – Project Document
  Doc ID: POLICY-INFRA-SSP-001
  Author: IT Business Analyst
  Created: 2025-12-23
  Updated: 2025-12-23
  Version: v1.0
  Status: Draft
  Confidentiality: Internal
  Project Phase: Planning
  Category: Infrastructure Policy
  Audience: Mixed
  Owners: IT Business Analyst, Linux Admin
  Reviewers: IT Security Analyst, Project Doc Auditor
  Tags: [shared-services, file-server, print, dns, dhcp, ldap]
  Data Sensitivity: Low to Moderate (Simulated Access Paths)
  Compliance: Internal Governance
  Publish Target: Internal
  Summary: >
    This policy defines acceptable usage, access control, and administration standards for shared IT infrastructure services within the simulated SMB environment, including Samba-based file shares, printing, name resolution, and identity systems.
  Read Time: ~6 min
███████████████████████████████████████████████████████████████
-->

# 🖧 Shared Services Policy

---

## 📍 Table of Contents

- [1. Purpose](#1-purpose)
- [2. Background](#2-background)
- [3. Objectives](#3-objectives)
- [4. Scope of Shared Services](#4-scope-of-shared-services)
- [5. Usage Guidelines](#5-usage-guidelines)
- [6. Access Control](#6-access-control)
- [7. Maintenance and Updates](#7-maintenance-and-updates)
- [8. Monitoring and Logging](#8-monitoring-and-logging)
- [9. Incident Handling](#9-incident-handling)
- [10. Related Files](#10-related-files)
- [11. Review History](#11-review-history)
- [12. Departmental Approval Checklist](#12-departmental-approval-checklist)

---

## 1. Purpose

To define operational standards and usage policy for centralized IT services including **file sharing**, **printing**, **name services**, and **identity authentication**, ensuring reliability, security, and consistent user experience.

---

## 2. Background

Shared IT services are foundational to business operations and must support multiple departments securely and efficiently. This policy helps standardize access patterns, reduce risk, and simplify troubleshooting and automation efforts.

---

## 3. Objectives

- Provide clear rules for how shared IT services are accessed and maintained
- Ensure least-privilege access and departmental isolation where required
- Promote accountability for usage and misuse
- Define ownership and support models for core services

---

## 4. Scope of Shared Services

| Service        | Hostname     | Protocol / Stack          | Notes                        |
|----------------|--------------|----------------------------|------------------------------|
| File Services  | `files01`    | Samba / SMB                | Department shares            |
| Print Services | `print01`    | CUPS / IPP / Samba         | Shared printers (AD aware)   |
| DNS            | `dc01`, `dc02` | BIND / Samba Internal DNS | Used for AD and resolution   |
| DHCP           | `infra01`    | ISC-DHCP                   | Optional, for client IPs     |
| LDAP/Kerberos  | `dc01`, `dc02` | Samba 4 (AD compatible)    | Used for authentication      |
| NTP            | `infra01`    | chrony                     | Time sync for domain clients |

---

## 5. Usage Guidelines

- File shares must only be used for **business content**. No personal or unlicensed files allowed.
- Shared printers are for **departmental use** only; color printing is restricted by group policy.
- No user may modify DNS or DHCP without IT Admin rights.
- NTP must be configured on all clients using internal servers.
- All departments are responsible for cleaning up obsolete documents or print jobs.

---

## 6. Access Control

| Resource / Share                      | Access Group                  | Permissions     |
|---------------------------------------|-------------------------------|-----------------|
| `\\files01\finance`                   | `GG-Finance-Staff`            | Read/Write      |
| `\\files01\hr`                        | `GG-HR-Staff`                 | Read/Write      |
| `\\files01\shared\executive`          | `GG-Exec-Leadership`          | Read-Only       |
| `\\files01\projects\shared`           | `SG-Projects-Shared-RW`       | Read/Write      |
| CUPS Printer `HR-Printer`             | `SG-HR-Print-Access`          | Print           |
| Print Server Admin                    | `GG-IT-Print-Admin`           | Admin           |
| DNS Admin                             | `GG-IT-Infra-Admin`           | Admin           |

> 🔐 Admin-level access to shared infrastructure must be requested via IT ticket and reviewed quarterly.

---

## 7. Maintenance and Updates

- All shared infrastructure is managed by the **Linux Admin** and **IT AD Architect**
- Patching and updates will occur **bi-weekly** unless critical vulnerabilities emerge
- Services are monitored via `checkmk` or `Prometheus` for uptime and anomalies

---

## 8. Monitoring and Logging

| Service         | Logging Enabled | Review Schedule     |
|-----------------|------------------|---------------------|
| File Access     | ✅ (via `auditd`) | Monthly             |
| Print Queue     | ✅ (via CUPS logs) | Weekly              |
| DNS/DHCP Logs   | ✅                | Quarterly           |
| Login Attempts  | ✅ (Kerberos logs) | Monthly             |

---

## 9. Incident Handling

- Suspected misuse of file shares or printers should be reported to IT Security Analyst
- Log files will be reviewed in response to any breach or data access concern
- Data recovery is only available on a **best-effort** basis using nightly snapshots
- Printing abuse (e.g., wasteful or restricted content) will result in account review

---

## 10. Related Files

- [file-share-structure.md](../implementation/filesystem/file-share-structure.md)
- [printer-access-policy.md](./printer-access-policy.md)
- [audit-log-policy.md](../policy/security/audit-log-policy.md)

---

## 11. Review History

| Version | Date       | Reviewer             | Notes               |
|---------|------------|----------------------|---------------------|
| v1.0    | 2025-12-23 | IT Business Analyst  | Initial draft       |

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
