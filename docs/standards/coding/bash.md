<!--
███████████████████████████████████████████████████████████████
  🧾 SMB Office IT Blueprint – Project Document
  Doc ID: STAND-BASH-001
  Author: Project Doc Auditor
  Created: 2025-12-22
  Updated: 2025-12-22
  Version: v1.0
  Status: Final
  Confidentiality: Internal
  Project Phase: Implementation
  Category: Script Standards
  Audience: IT
  Owners: Linux Admin/Architect
  Reviewers: Code Auditor, Security Analyst
  Tags: [bash, standards, scripting]
  Data Sensitivity: [None | Simulated PII | File Paths]
  Compliance: [None | NIST-CSF | ISO-27001]
  Publish Target: Internal
  Summary: >
    Standards for writing secure, maintainable Bash scripts in the SMB Office IT Blueprint project.
  Read Time: ~5 min
███████████████████████████████████████████████████████████████
-->

# 📘 Bash Scripting Standards  
**SMB Office IT Blueprint – Implementation Script Guidelines**

---

## 📍 Table of Contents
- [1. Purpose](#1-purpose)
- [2. Background](#2-background)
- [3. Objectives](#3-objectives)
- [4. Structure / Body](#4-structure--body)
  - [4.1 Script Layout](#41-script-layout)
  - [4.2 Naming & Location](#42-naming--location)
  - [4.3 Best Practices](#43-best-practices)
  - [4.4 Security Guidelines](#44-security-guidelines)
  - [4.5 Script Metadata Header](#45-script-metadata-header)
  - [4.6 Linting & Testing](#46-linting--testing)
- [5. Related Files](#5-related-files)
- [6. Review History](#6-review-history)
- [7. Departmental Approval Checklist](#7-departmental-approval-checklist)

---

## 1. Purpose

Define project-wide standards for Bash script quality, security, readability, and file structure used in deployment, troubleshooting, and system automation.

---

## 2. Background

Bash scripts are used for:
- Local setup tasks (e.g., user creation, log setup)
- System-level config prior to Ansible deployment
- Testing, diagnostics, and rollback automation

To maintain long-term viability, scripts must follow project coding and security standards.

---

## 3. Objectives

- Ensure all scripts are **documented, secure, and portable**
- Prevent hard-coded values and data leaks
- Use consistent headers, formatting, and directory layout
- Prepare scripts for future integration into Ansible or CI/CD

---

## 4. Structure / Body

### 4.1 Script Layout

Use this standard file structure:

```bash
implementation/
└── scripts/
    ├── bootstrap/
    │   └── init-network.sh
    ├── diagnostics/
    │   └── check-dc-status.sh
    ├── rollback/
    │   └── revert-dns-config.sh
    ├── utils/
    │   └── generate-password.sh
    └── README.md
````

---

### 4.2 Naming & Location

| Element         | Convention                |
| --------------- | ------------------------- |
| File names      | `kebab-case.sh`           |
| Shebang         | `#!/usr/bin/env bash`     |
| File encoding   | UTF-8                     |
| Permissions     | `chmod 755` for scripts   |
| Folder location | `implementation/scripts/` |

---

### 4.3 Best Practices

* Use `set -euo pipefail` at top of every script
* Comment logic-heavy sections with `#`
* Use functions for modularity
* Validate all user input
* Default to read-only mode (dry-run) where applicable
* Output logs using `logger` or `tee` to `/var/log/` or console

Example startup:

```bash
#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'

main() {
    echo "Bootstrapping network..."
    # logic goes here
}

main "$@"
```

---

### 4.4 Security Guidelines

* No plaintext secrets or passwords — fetch from `vault/` or env vars
* Avoid `eval` or `source` unless controlled
* Escape all user-supplied arguments
* Don’t write to `/tmp/` without safe naming (use `mktemp`)
* Run as non-root whenever possible

---

### 4.5 Script Metadata Header

Every script must begin with this header block:

```bash
#!/usr/bin/env bash
# ============================================================
# 📄 SMB Office IT Blueprint – Bash Script
# Script Name   : init-network.sh
# Author        : [Your Name]
# Created       : 2025-12-22
# Updated       : 2025-12-22
# Description   : Initializes VLAN and bridge networking
# Confidentiality: Internal
# Tags          : networking, bootstrap
# Phase         : Lab Build
# Lint Status   : Passed (shellcheck)
# ============================================================

set -euo pipefail
```

---

### 4.6 Linting & Testing

All scripts must pass [`shellcheck`](https://www.shellcheck.net/) before commit:

```bash
shellcheck init-network.sh
```

Optional (for future use): Write test scripts in `tests/` and check basic output.

---

## 5. Related Files

* [Ansible Standards](ansible-best-practices.md)
* [Markdown Documentation Standards](markdown-doc-standards.md)
* [Pre-commit Hooks](../../.githooks/validate-scripts.sh)

---

## 6. Review History

| Version | Date       | Reviewer            | Notes         |
| ------- | ---------- | ------------------- | ------------- |
| v1.0    | 2025-12-22 | Project Doc Auditor | Initial draft |

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


