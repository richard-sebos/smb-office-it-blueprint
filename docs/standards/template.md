### ✅ Standard Markdown Document Template


<!--
███████████████████████████████████████████████████████████████
  🧾 SMB Office IT Blueprint – Project Document
  Doc ID: DOC-XXX-000
  Author: [Your Name]
  Created: [YYYY-MM-DD]
  Updated: [YYYY-MM-DD]
  Version: v0.1
  Status: [Draft | In Review | Final | Deprecated]
  Confidentiality: [Public | Internal | Restricted | Confidential]
  Project Phase: [Planning | Lab Build | Implementation | Docs | Review]
  Category: [Lab Guide | Business Policy | Article | Automation | Design Spec]
  Audience: [IT | Business | Mixed]
  Owners: [e.g., IT Business Analyst, Ansible Programmer]
  Reviewers: [e.g., Project Doc Auditor, Code Auditor]
  Tags: [keyword1, keyword2, keyword3]
  Data Sensitivity: [None | Simulated PII | Access Credentials | File Paths]
  Compliance: [None | SOX | HIPAA | NIST-CSF | ISO-27001]
  Publish Target: [Internal | Blog | Course | Client Portal]
  Canonical URL: [if public]
  Summary: >
    [1–2 sentence summary of what this document covers.]
  Read Time: ~[X] min
███████████████████████████████████████████████████████████████
-->

# 📘 [Document Title]

## 📍 Table of Contents
- [1. Purpose](#1-purpose)
- [2. Background](#2-background)
- [3. Objectives](#3-objectives)
- [4. Structure / Body](#4-structure--body)
- [5. Related Files](#5-related-files)
- [6. Review History](#6-review-history)
- [7. Departmental Approval Checklist](#7-departmental-approval-checklist)

---

## 1. Purpose

Briefly describe the reason this document exists.  
What need, issue, or goal does it address?

---

## 2. Background

Provide business or technical context:
- Project background
- Departmental needs
- Technology landscape
- Relevant prior documents (if any)

---

## 3. Objectives

List the goals and outcomes this document aims to achieve:
- What decisions does it support?
- What processes does it define or describe?

---

## 4. Structure / Body

Use as many subsections as needed to describe:
- Systems
- Policies
- Configurations
- Workflows
- Diagrams
- Commands
- Examples

### 4.1 Example Subsection

Use code fences and relative image paths when needed:

```bash
# Example: Create an AD user
samba-tool user add jdoe --random-password
````

![Sample diagram](../assets/sample-diagram.png)

---

## 5. Related Files

* [Lab Topology Diagram](../topology/proxmox-lab-overview.png)
* [Test Case: DC Join Validation](../tests/dc-join.md)
* [Ansible Role: Domain Controller Setup](../implementation/roles/dc-setup/README.md)

---

## 6. Review History

| Version | Date       | Reviewer      | Notes         |
| ------- | ---------- | ------------- | ------------- |
| v0.1    | 2025-12-22 | [Author Name] | Initial draft |
|         |            |               |               |

---

## 7. Departmental Approval Checklist

> ✅ Required for all non-trivial documents

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

---

<!-- Optional: Google Analytics if rendered to HTML -->

<!--
<script async src="https://www.googletagmanager.com/gtag/js?id=G-XXXXXXX"></script>
<script>
  window.dataLayer = window.dataLayer || [];
  function gtag(){dataLayer.push(arguments);}
  gtag('js', new Date());
  gtag('config', 'G-XXXXXXX');
</script>
-->



