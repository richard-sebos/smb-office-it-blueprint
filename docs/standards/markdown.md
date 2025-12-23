# 📄 Markdown Documentation Standards  
**SMB Office IT Blueprint — Documentation Specification**

**Version:** 1.1  
**Maintained By:** Project Doc Auditor  
**Last Updated:** 2025-12-22  
**Status:** Final

---

## 📘 Purpose

This document defines the required structure, metadata, formatting, and review workflow for all Markdown documents in the **SMB Office IT Blueprint** project — including simulated business planning, lab design, automation, and article publishing.

The standard ensures:
- Consistency across technical and business documents
- Clear ownership and approval responsibilities
- Alignment with documentation quality, security, and reuse goals
- Support for publishing and analytics workflows

---

## 📁 Applies To

| Folder | Applies? | Notes |
|--------|----------|-------|
| `articles/` | ✅ | Public-facing or protected technical articles |
| `implementation/` | ✅ | Encrypted infrastructure docs and scripts |
| `simulated-client-project/` | ✅ | Business requirements and simulation plans |
| `docs/` | ✅ | Meta-docs and style guides |
| `topology/` | ✅ | Network diagrams, plans, and structured docs |

---

## 🧾 Required Metadata Block

All documents must begin with a **standard metadata block** inside an HTML comment (to avoid rendering).

### 🧩 Sample Format

```markdown
<!--
███████████████████████████████████████████████████████████████
  🧾 SMB Office IT Blueprint – Project Document
  Doc ID: DOC-AUTO-003
  Author: Richard Sebos
  Created: 2025-12-22
  Updated: 2025-12-23
  Version: v1.1
  Status: [Draft | In Review | Final | Deprecated]
  Confidentiality: [Public | Internal | Restricted | Confidential]
  Project Phase: [Planning | Lab Build | Implementation | Docs | Review]
  Category: [Lab Guide | Business Policy | Article | Automation | Design Spec]
  Audience: [IT | Business | Mixed]
  Owners: [IT Ansible Programmer, Linux Admin]
  Reviewers: [Code Auditor, Security Analyst]
  Tags: [ansible, samba, domain-controller]
  Data Sensitivity: [None | Simulated PII | Access Credentials | File Paths]
  Compliance: [None | SOX | HIPAA | NIST-CSF | ISO-27001]
  Publish Target: [Internal | Blog | Course | Client Portal]
  Canonical URL: [if public]
  Summary: >
    Ansible playbooks for provisioning and configuring Samba AD domain controllers.
  Read Time: ~8 min
███████████████████████████████████████████████████████████████
-->
````

---

## 📐 Required Document Sections

All documents must contain the following headers in this order:

| Section            | Markdown Heading                        | Purpose                              |
| ------------------ | --------------------------------------- | ------------------------------------ |
| Metadata Block     | *(HTML comment)*                        | Document identity, traceability      |
| Title              | `# 📘 Document Title`                   | Clear, human-readable title          |
| TOC                | `## 📍 Table of Contents`               | Required if >3 sections              |
| Purpose            | `## 1. Purpose`                         | Why this doc exists                  |
| Background         | `## 2. Background`                      | Business or technical context        |
| Objectives         | `## 3. Objectives`                      | What this doc is meant to accomplish |
| Main Body          | `## 4. Structure / Body`                | The full content                     |
| Related Files      | `## 5. Related Files`                   | Links to other assets                |
| Review History     | `## 6. Review History`                  | Human-readable changelog             |
| Approval Checklist | `## 7. Departmental Approval Checklist` | Agent/role sign-off table            |

---

## 🔐 Confidentiality Levels

| Level            | Description                              | Folder Location                                                          |
| ---------------- | ---------------------------------------- | ------------------------------------------------------------------------ |
| **Public**       | Safe for external publication            | `articles/`, `docs/`                                                     |
| **Internal**     | For project team only, no sensitive data | Any non-encrypted folder                                                 |
| **Restricted**   | Simulated IP or business-sensitive       | Must be reviewed                                                         |
| **Confidential** | Contains IP, credentials, deep configs   | Must be in encrypted folders (`implementation/`, `assets/`, `articles/`) |

---

## 👤 Document Ownership by Area

| Area                            | Primary Owners                   | Secondary           |
| ------------------------------- | -------------------------------- | ------------------- |
| Simulated Business Requirements | SMB Analyst, IT Business Analyst | Project Manager     |
| Infrastructure Design           | Linux Admin, AD Architect        | Security Analyst    |
| Active Directory Layout         | AD Architect                     | IT Business Analyst |
| Security Docs                   | Security Analyst, Policy Writer  | Code Auditor        |
| Automation / Scripts            | Ansible Programmer               | Code Auditor        |
| Public Articles                 | Content Editor, SEO Analyst      | Project Doc Auditor |
| Meta-Docs                       | Project Doc Auditor              | Task Assistant      |

Each document must list **Owners** and **Reviewers** in the metadata.

---

## ✅ Departmental Approval Checklist (Required)

```markdown
## 7. Departmental Approval Checklist

| Department / Agent | Reviewed | Reviewer Notes |
|--------------------|----------|----------------|
| SMB Analyst | [ ] | |
| IT Business Analyst | [ ] | |
| Project Doc Auditor | [ ] | |
| IT Security Analyst | [ ] | |
| IT AD Architect | [ ] | |
| Linux Admin/Architect | [ ] | |
| Ansible Programmer | [ ] | |
| IT Code Auditor | [ ] | |
| SEO Analyst | [ ] | |
| Content Editor | [ ] | |
| Project Manager | [ ] | |
| Task Assistant | [ ] | |
```

---

## 📝 Review History Table

```markdown
## 6. Review History

| Version | Date | Reviewer | Notes |
|---------|------|----------|-------|
| v1.0 | 2025-12-22 | Richard Sebos | Initial draft |
| v1.1 | 2025-12-23 | Project Doc Auditor | Format standard applied |
```

---

## 🎨 Formatting Rules

| Element     | Rule                                               |
| ----------- | -------------------------------------------------- |
| Headings    | Use `#`, `##`, `###` in logical order              |
| Lists       | Use `-` or `*` consistently                        |
| Code        | Use fenced code blocks with language (```bash)     |
| Image paths | Use relative paths like `../assets/img.png`        |
| Links       | Use relative links unless external (`https://...`) |
| File naming | `kebab-case.md` (e.g., `ad-design-spec.md`)        |

---

## 📈 Google Analytics (Optional)

If document will be **rendered as HTML**, embed this at the bottom:

```html
<!-- Google Analytics -->
<script async src="https://www.googletagmanager.com/gtag/js?id=G-XXXXXXX"></script>
<script>
  window.dataLayer = window.dataLayer || [];
  function gtag(){dataLayer.push(arguments);}
  gtag('js', new Date());
  gtag('config', 'G-XXXXXXX');
</script>
```

---

## 🚫 Violations & Enforcement

* Documents missing required fields will be flagged during project reviews.
* `Project Doc Auditor` and `Project Manager` can reject pull requests with non-compliant documentation.
* A future **linting tool** or **pre-commit hook** may enforce this standard.

