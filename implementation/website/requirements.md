# 📄 Project Requirements Document

**Project Name:** SMB IT Lab Website Transformation
**Version:** 1.0
**Date:** 2025-12-23
**Owner:** Richard Sebos
**Reviewed By:** Project AI Team (Project Manager, IT Architect, Content Editor, Security Analyst)

---

## 1. 📘 Purpose

This document outlines the requirements for transforming the existing private GitHub repository into a **public-facing static website** powered by Astro, serving both **IT professionals** and **business users** through clearly segmented, organized, and policy-driven content.

The goal is to make the project both an educational platform and a simulated small business IT solution showcase.

---

## 2. 🎯 Objectives

* Host a **professional public-facing site** built from a private GitHub repo using Astro
* Maintain **strict content boundaries** between technical, business, and restricted documentation
* Provide **clean navigation** for different user types (Admins, HR, Finance, Executives, etc.)
* Enable future **role-based access** or segmented publishing (e.g., secure downloads)
* Implement **consistent documentation standards**, metadata, and ownership tagging
* Prepare content and structure to support **blog-style content, marketing, and SEO**

---

## 3. 🏗️ Project Scope

### ✅ In Scope

* Transform repo structure for Astro site compatibility
* Add Astro site scaffolding and configuration
* Setup GitHub Actions for automated deployment to GitHub Pages
* Define and implement logical content routing:

  * `/` (Home)
  * `/docs/` (Technical Documentation)
  * `/policies/` (Business/Simulated Policy Documents)
  * `/articles/` (Marketing/Educational Posts)
  * `/use-cases/` (Departmental Profiles & Scenarios)
* Implement and apply **Markdown Standards** including:

  * YAML front matter
  * Confidentiality levels
  * Owner(s) and reviewers
  * Approval checklists
* Integrate consistent branding via Astro layout components
* Protect sensitive or intellectual content using `git-crypt` and `.gitattributes`

### ❌ Out of Scope (for now)

* Full user login/auth systems (will require backend)
* Encrypted file delivery via web interface
* Live document editing or form-based workflows

---

## 4. 👥 Target Audiences

| Audience                 | Needs                                                                     |
| ------------------------ | ------------------------------------------------------------------------- |
| **IT Professionals**     | Clear technical documentation, implementation guidance, security policies |
| **Business Users**       | Policy clarity, org structure, onboarding workflow, compliance docs       |
| **Consultants/Analysts** | Reference implementation, automation, and best practices                  |
| **Students/Learners**    | Simulated office scenarios, hands-on lab deployment                       |
| **Search Engines**       | Indexable, SEO-optimized content for Samba AD, Proxmox, Linux IT          |

---

## 5. 📁 Repository Structure (Post-Transformation)

```bash
repo-root/
├── src/
│   ├── pages/
│   │   ├── index.astro              # Home/landing page
│   │   ├── articles/                # Blog content (public)
│   │   ├── docs/                    # IT documentation (public)
│   │   ├── policies/                # Simulated business policies (public)
│   │   ├── use-cases/               # Departmental profiles (public)
│   │   └── secure/                  # Placeholder for restricted/gated future content
│   ├── layouts/                     # Reusable layouts (header/footer)
│   └── components/                  # UI components (nav, banners, etc.)
├── public/
│   └── assets/                      # Static files, logos, diagrams
├── .gitattributes                   # Defines git-crypt encrypted folders
├── .gitcrypt/                       # Encryption config
├── astro.config.mjs
├── package.json
└── .github/
    └── workflows/deploy.yml        # GitHub Actions for Astro deploy
```

---

## 6. 🧩 Functional Requirements

| ID     | Description                                                                                    |
| ------ | ---------------------------------------------------------------------------------------------- |
| FR-001 | Public homepage must provide access to docs, policies, articles, use cases                     |
| FR-002 | All Markdown content must follow the [Markdown Standards Document](docs/standards/markdown.md) |
| FR-003 | GitHub Actions must build and deploy Astro site to `gh-pages` on push to `main`                |
| FR-004 | Assets, articles, and implementation folders must be encrypted via `git-crypt`                 |
| FR-005 | Each document must contain metadata (owner, type, confidentiality, revision)                   |
| FR-006 | Astro layouts must support banner image, metadata display, and standardized footer             |
| FR-007 | Directory navigation must be clear and persistent across sections                              |
| FR-008 | SEO metadata should be added for all articles (keywords, descriptions)                         |

---

## 7. 🔒 Security Requirements

| ID     | Description                                                                                     |
| ------ | ----------------------------------------------------------------------------------------------- |
| SR-001 | `git-crypt` must be initialized and used to encrypt sensitive folders                           |
| SR-002 | No confidential documents or files are published in `gh-pages`                                  |
| SR-003 | Optional `secure/` route must be excluded from public builds until secured                      |
| SR-004 | Metadata must include confidentiality level: `Public`, `Internal`, `Confidential`, `Restricted` |

---

## 8. 🎨 Branding Requirements

* All pages must include:

  * Project name: **SMB IT Blueprint**
  * Author/maintainer: Richard Chamberlain
  * Visual header/banner
* Layouts must be visually consistent with color scheme, typography, and navigation
* Footer must include:

  * Version info
  * Last updated date
  * Document owner

---

## 9. 🧱 Technical Stack

| Layer                 | Tool                          |
| --------------------- | ----------------------------- |
| Static Site Generator | Astro                         |
| Deployment            | GitHub Actions → GitHub Pages |
| Content Format        | Markdown + YAML Frontmatter   |
| Encryption            | `git-crypt`                   |
| Analytics (optional)  | Google Analytics or Plausible |
| Search (optional)     | Pagefind or Lunr.js           |

---

## 10. ✅ Approval & Review Workflow

Each published document must include a **review checklist** at the bottom (Markdown table), with signoff fields for:

* IT Business Analyst
* Project Manager
* Security Analyst
* Department Owner (e.g., HR, Finance)
* Content Editor

---

## 11. 🧠 AI Agent Integration (Role-to-Document Mapping)

Every document must list its **owning agent(s)** based on type:

| Document Type | Owning Agent(s)                      |
| ------------- | ------------------------------------ |
| IT Design     | IT Linux Architect, AD Architect     |
| Policies      | IT Security Analyst, Project Manager |
| Use Cases     | IT Business Analyst, Department Role |
| Articles      | Content Editor, SEO Analyst          |
| Automation    | IT Ansible Programmer                |
| All           | Project Doc Auditor (final reviewer) |

---

## 12. 📌 Milestones

| Milestone | Description                                | Target |
| --------- | ------------------------------------------ | ------ |
| M1        | Astro framework scaffolded and integrated  | ✅      |
| M2        | GitHub Actions deployed to `gh-pages`      |        |
| M3        | All core folders converted to Astro routes |        |
| M4        | Public homepage + branding complete        |        |
| M5        | 3+ core docs published via Astro           |        |
| M6        | Secure content policy defined              |        |

---

## 13. 🛠️ To Do / Action Items

* [ ] Create Astro scaffold from existing repo
* [ ] Configure GitHub Actions deployment
* [ ] Migrate Markdown files into `/src/pages/`
* [ ] Apply Markdown standards
* [ ] Implement site header, footer, layout
* [ ] Document and enforce folder encryption
* [ ] Write home, about, and roadmap pages

---

## 14. 📎 Attachments & References

* [Markdown Standards Document](docs/standards/markdown.md)
* [Ansible Best Practices](docs/standards/ansible.md)
* [Site Navigation Map (TBD)](docs/design/nav-map.md)
* [Document Ownership Guidelines](docs/process/ownership.md)

---

## 15. 🧾 Change Log

| Version | Date       | Author        | Summary         |
| ------- | ---------- | ------------- | --------------- |
| 1.0     | 2025-12-23 | Richard Sebos | Initial version |

