# 🧩 Project Startup Framework

## **Samba AD Lab Series – High-Level Implementation Document**

**Project Name:** The Complete Samba AD Lab Series
**Subtitle:** Framework for Automating a Secure Proxmox-Based Samba AD Environment
**Author:** Richard Chamerlain
**Version:** 1.0
**Status:** Planning Phase
**Date Initiated:** December 20, 2025
**Next Review:** January 3, 2026

---

## 🔍 Purpose of This Document

This document provides the **foundational framework** for designing, implementing, and automating the **Samba AD Lab** environment using **Proxmox**, **Linux**, **Samba AD**, and associated tools. It serves as the **anchor document** for all sub-projects, scripts, diagrams, playbooks, and documentation produced during this initiative.

It establishes:

* A clear **project charter**
* A structured **development lifecycle**
* Defined **deliverables and milestones**
* **Integration points** for Ansible, Bash, and documentation scripts
* A scalable **documentation hierarchy** for future reuse

All automation (e.g., Ansible roles, Bash utilities) and documentation tasks (e.g., admin guides, setup wikis) will inherit from this plan.

---

## 🧭 Project Overview

### 🎯 Objective

Design and document a **production-ready Samba Active Directory environment** hosted in **Proxmox**, complete with:

* Infrastructure automation via **Ansible**
* Security integration using **auditd**, **SELinux**, and **AIDE**
* Fully scripted lab provisioning workflows
* Reproducible templates for future client/lab use

### 📌 Scope

**In Scope:**

* 11-VM Proxmox Lab Environment
* Proxmox host design + VM resource planning
* Active Directory domain controllers (Samba 4)
* File, print, and authentication services
* Departmental Linux workstation integration (SSSD)
* Security hardening (auditd, SELinux, AIDE)
* End-to-end documentation and automation (Ansible, Bash)

**Out of Scope:**

* Microsoft Windows Server or Windows AD integration
* Non-Linux client environments (e.g., macOS, Windows clients)
* Long-term production support environments

---

## 🧱 Project Architecture Overview

| Component              | Technology                    |
| ---------------------- | ----------------------------- |
| **Hypervisor**         | Proxmox VE                    |
| **OS Templates**       | Oracle Linux 9, Ubuntu Server |
| **Directory Services** | Samba AD (Samba 4.x)          |
| **Authentication**     | Kerberos, LDAP                |
| **File/Print**         | Samba Shares + CUPS           |
| **Client Join**        | SSSD (Linux)                  |
| **Security**           | auditd, SELinux, AIDE         |
| **Automation**         | Ansible + Bash                |
| **Documentation**      | Markdown + Git repo           |

A full **network topology diagram** and **VM resource matrix** will accompany this document.

---

## 🛠 Project Phases (Abstracted)

Each phase is supported by technical deliverables (scripts, playbooks, guides).

| Phase  | Focus                 | Automation Goals           | Documentation Outputs        |
| ------ | --------------------- | -------------------------- | ---------------------------- |
| **P1** | Planning & Prep       | Resource planning scripts  | Article outlines, diagrams   |
| **P2** | Lab Build             | VM provisioning (Ansible)  | Lab build runbooks           |
| **P3** | Domain Setup          | DC configs (Ansible)       | Samba AD setup guide         |
| **P4** | Infra Services        | File/print join scripts    | Share + ACL guides           |
| **P5** | Security Layers       | auditd/SELinux/AIDE roles  | Security hardening documents |
| **P6** | Client Integration    | SSSD domain join playbook  | Workstation onboarding guide |
| **P7** | Automation Capstone   | Full environment playbooks | Ansible role documentation   |
| **P8** | Publication/Promotion | N/A                        | Series index + assets        |

---

## 🔄 Automation Strategy

### Ansible Focus Areas:

* VM Provisioning (Proxmox API or templates)
* Domain Controller setup
* File server share + ACL automation
* Workstation domain joining
* Security policy enforcement (auditd, SELinux)
* Scheduled hardening checks

### Bash Scripting Use Cases:

* Screenshot automation
* Configuration file generation
* Local test validation
* Quick tools (e.g., OU creation, user batch onboarding)

---

## 🎯 Key Deliverables

| Category           | Deliverable                                  |
| ------------------ | -------------------------------------------- |
| **Infrastructure** | 11-VM Proxmox Lab                            |
| **Automation**     | Ansible playbooks + Bash scripts             |
| **Documentation**  | 15 technical articles + guides               |
| **Diagrams**       | Network + VM topology, AD structure          |
| **Templates**      | OS VM templates, config files                |
| **Security**       | auditd rules, SELinux policies, AIDE configs |
| **Promotion**      | Landing page, social engagement tracker      |

---

## 📏 Standards & Conventions

* **Documentation Format:** Markdown (for static docs and exportability)
* **Screenshot Naming:** `phaseX-weekY-step-desc.png`
* **Script Format:** YAML for Ansible, POSIX-compliant Bash
* **Network Schema:** CIDR-based subnets with VLAN consideration
* **Git Branching:** `main` for published docs, `dev` for lab/test drafts

---

## 🧮 Estimation Overview

| Task                   | Time Estimate                   |
| ---------------------- | ------------------------------- |
| Lab Build              | 40-60 hours                     |
| Article Writing        | 120-150 hours                   |
| Automation Scripting   | 60-80 hours                     |
| Promotion & Publishing | 20-30 hours                     |
| **Total**              | **240-320 hours** over 24 weeks |

---

## 🚦 Success Criteria

### Minimum Viable Completion:

* Lab builds with Ansible + manual runbooks
* 15 articles published
* Clients domain-joined and operational
* Security stack active and documented

### Ideal Outcome:

* Fully automated end-to-end lab setup
* Downloadable toolkit (playbooks + scripts)
* High community engagement (Reddit, Proxmox forums)
* Training course or book interest generated

---

## ⚠️ Risks and Mitigations Summary

| Risk                             | Mitigation                                        |
| -------------------------------- | ------------------------------------------------- |
| Time Overrun                     | Built-in 2-week buffer + staggered scripting      |
| Writer Burnout                   | Weekly pacing with optional breaks                |
| Tech blockers (e.g., Samba bugs) | Use content gaps for research or tooling          |
| Hardware limits                  | VM scheduling strategy; minimize concurrent usage |
| Engagement drop                  | Platform-specific promotion strategy              |

---

## 🔌 Dependencies and Prerequisites

| Dependency                            | Status |
| ------------------------------------- | ------ |
| Proxmox Host Ready                    | [ ]    |
| Storage Allocated                     | [ ]    |
| Oracle Linux + Ubuntu ISOs Downloaded | [ ]    |
| Git Repo Initialized                  | [ ]    |
| Network Plan Finalized                | [ ]    |

---

## 📅 High-Level Milestones

| Milestone               | Target Week | Description                   |
| ----------------------- | ----------- | ----------------------------- |
| Final Project Framework | Week 2      | This document approved        |
| Lab Build Completion    | Week 6      | All VMs deployed and working  |
| Article Series Launch   | Week 8      | First article published       |
| Automation Complete     | Week 22     | Ansible/Bash complete         |
| Series Published        | Week 23     | Full content live             |
| 3-Month Review          | Week 36     | Evaluate engagement and leads |

---

## ✅ Immediate Next Actions

| Action                                  | Owner        | Due          |
| --------------------------------------- | ------------ | ------------ |
| Approve Project Startup Framework       | Owner        | Dec 21, 2025 |
| Finalize Article List + Network Diagram | Project Lead | Dec 26, 2025 |
| Document Current Lab State              | Tech Writer  | Dec 26, 2025 |
| Create Repo Structure                   | Engineer     | Dec 26, 2025 |

---

## 🔁 Living Document Notice

This framework is versioned and tracked via Git. Updates should:

* Maintain structure for reuse
* Include changelog notes
* Be reviewed before major phases begin

---

## 📌 Appendix: Framework Usage

### Derived Documents (Examples):

* `lab-build-guide.md`
* `ansible-playbooks/README.md`
* `client-onboarding-checklist.md`
* `selinux-hardening.md`
* `samba-automation-workflows.md`
* `network-topology-diagram.drawio`

---

## 📘 Version History

| Version | Date         | Description                       |
| ------- | ------------ | --------------------------------- |
| 1.0     | Dec 20, 2025 | Initial Project Startup Framework |

---
