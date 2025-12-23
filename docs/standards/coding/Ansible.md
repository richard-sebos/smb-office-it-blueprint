C
<!--
███████████████████████████████████████████████████████████████
  🧾 SMB Office IT Blueprint – Project Document
  Doc ID: STAND-ANSIBLE-001
  Author: Project Doc Auditor
  Created: 2025-12-22
  Updated: 2025-12-22
  Version: v1.0
  Status: Final
  Confidentiality: Internal
  Project Phase: Implementation
  Category: Automation Standards
  Audience: IT
  Owners: IT Ansible Programmer, Project Doc Auditor
  Reviewers: Code Auditor, Linux Admin
  Tags: [ansible, automation, standards]
  Data Sensitivity: None
  Compliance: None
  Publish Target: Internal
  Summary: >
    Ansible code style and project structure standards used in the SMB Office IT Blueprint project.
  Read Time: ~6 min
███████████████████████████████████████████████████████████████
-->

# 📘 Ansible Best Practice Standards  
**SMB Office IT Blueprint – Automation Guidelines**

---

## 📍 Table of Contents
- [1. Purpose](#1-purpose)
- [2. Background](#2-background)
- [3. Objectives](#3-objectives)
- [4. Structure / Body](#4-structure--body)
  - [4.1 Project Structure](#41-project-structure)
  - [4.2 Roles and Playbooks](#42-roles-and-playbooks)
  - [4.3 Variable Management](#43-variable-management)
  - [4.4 Naming Conventions](#44-naming-conventions)
  - [4.5 Security Practices](#45-security-practices)
  - [4.6 Testing and Linting](#46-testing-and-linting)
- [5. Related Files](#5-related-files)
- [6. Review History](#6-review-history)
- [7. Departmental Approval Checklist](#7-departmental-approval-checklist)

---

## 1. Purpose

To provide consistent, secure, and scalable automation practices using **Ansible** for all contributors working on the **SMB Office IT Blueprint** project. This ensures automation work is reusable, easy to audit, and aligned with business goals.

---

## 2. Background

This project automates the deployment of a simulated business environment, including:
- Samba AD Domain Controllers
- Linux Workstations
- File/Print Services
- Security Hardening (auditd, SELinux, AIDE)

Automation needs to be robust, reusable, and maintainable over time. This standard defines how.

---

## 3. Objectives

- Ensure **consistent Ansible structure and style**
- Define **secure practices for secrets and credentials**
- Align all roles/playbooks with **Samba AD Lab architecture**
- Reduce **technical debt** and **onboarding friction**
- Enforce **linting and test coverage** for automation code

---

## 4. Structure / Body

### 4.1 Project Structure

```bash
implementation/
└── ansible/
    ├── inventories/
    │   ├── lab/
    │   └── production/         # Optional future extension
    ├── group_vars/
    ├── host_vars/
    ├── roles/
    │   ├── common/
    │   ├── domain-controller/
    │   ├── file-server/
    │   └── print-server/
    ├── playbooks/
    │   ├── site.yml
    │   ├── domain.yml
    │   └── clients.yml
    ├── vault/
    ├── .ansible-lint
    └── README.md
````

**Key Practices:**

* Use one **role per service/function**
* Group common configuration in `roles/common/`
* Maintain example inventory files in `inventories/`

---

### 4.2 Roles and Playbooks

* Roles must follow [Ansible Galaxy Role Structure](https://docs.ansible.com/ansible/latest/dev_guide/collections_galaxy_meta.html#role-directory-structure)
* No playbook should exceed **300 lines**
* Avoid deeply nested includes — use `import_tasks:` and `include_tasks:` with descriptive names
* Playbooks should be **idempotent** and **stateless**

---

### 4.3 Variable Management

* Use `group_vars` and `host_vars` for static configuration
* Use **Vault-encrypted** files for:

  * Passwords
  * SSH keys
  * Secret tokens

Example:

```bash
ansible-vault encrypt vault/domain-secrets.yml
```

* Never hard-code passwords in playbooks

---

### 4.4 Naming Conventions

| Element       | Style Example               |
| ------------- | --------------------------- |
| Playbook file | `domain.yml`                |
| Role name     | `domain-controller`         |
| Variable name | `smb_ad_domain_name`        |
| Task name     | `Install required packages` |
| Tags          | `ad`, `firewall`, `audit`   |

* Use **snake_case** for variables
* Use **kebab-case** for file names and role folders

---

### 4.5 Security Practices

* Always **vault** secrets: `ansible-vault encrypt`
* Review all tasks with `become: true` — validate they are needed
* Avoid using `shell:` or `command:` unless absolutely necessary
* Implement **audit logging** where possible (e.g., file changes)

---

### 4.6 Testing and Linting

* Use [`ansible-lint`](https://ansible-lint.readthedocs.io/) on every playbook/role

```bash
ansible-lint playbooks/domain.yml
```

* All roles should support:

  * Dry-run mode (`--check`)
  * Idempotency
* Optional: Add `molecule` tests for roles (future goal)

---

## 5. Related Files

* [Markdown Style Guide](../style/markdown-doc-standards.md)
* [Playbook: Samba AD Domain Setup](../../implementation/ansible/playbooks/domain.yml)
* [Inventory: Lab Environment](../../implementation/ansible/inventories/lab/hosts.yml)

---

## 6. Review History

| Version | Date       | Reviewer            | Notes           |
| ------- | ---------- | ------------------- | --------------- |
| v1.0    | 2025-12-22 | Project Doc Auditor | Initial version |

---

## 7. Departmental Approval Checklist

| Department / Agent    | Reviewed | Reviewer Notes |
| --------------------- | -------- | -------------- |
| SMB Analyst           | [ ]      |                |
| IT Business Analyst   | [ ]      |                |
| Project Doc Auditor   | [ ]      |                |
| IT Security Analyst   | [ ]      |                |
| IT AD Architect       | [ ]      |                |
| Linux Admin/Architect | [ ]      |                |
| Ansible Programmer    | [ ]      |                |
| IT Code Auditor       | [ ]      |                |
| SEO Analyst           | [ ]      |                |
| Content Editor        | [ ]      |                |
| Project Manager       | [ ]      |                |
| Task Assistant        | [ ]      |                |

``
