# 🏢 Samba AD Lab Series — Simulated Business IT Infrastructure

**Author:** Richard Richard  
**Version:** 1.0  
**Project Status:** Planning & Implementation Phase  
**Last Updated:** December 2025

---

## 📘 Project Overview

Welcome to the **Samba AD Lab Series**, a professional simulation of a real-world IT system deployment for a growing small-to-medium business (SMB).

This project builds a fully functional **office IT infrastructure** using open-source tools like **Proxmox**, **Samba Active Directory**, **Linux workstations**, and **Ansible**. It’s designed to show both **technical engineers** and **business leaders** how secure, scalable systems can be built without expensive commercial software.

Think of this as a **blueprint for a real office IT rollout**—complete with:
- Departments like HR, Finance, and Consulting
- Secure file and print services
- Domain login accounts
- Role-based access controls
- Logging, audit trails, and system hardening
- Automated deployment scripts and full documentation

---

## 💼 Who This Is For

| Audience | Value You'll Get |
|----------|------------------|
| **Business Owners / Executives** | See how IT systems are structured to match business needs |
| **IT Managers** | Learn how to deliver secure, efficient infrastructure using open tools |
| **Sysadmins / Engineers** | Dive into the technical stack with Proxmox, Samba AD, and Ansible |
| **Consultants & MSPs** | Use the lab as a repeatable, client-ready reference environment |
| **Trainers & Course Creators** | Use the project as a teaching tool for IT best practices |

---

## 📌 Business-Focused Design

This project doesn’t just build servers—it **models a real office environment** from the top down.

**Simulated Business Needs Include:**
- Department separation (HR, Finance, Consulting)
- Secure access to sensitive data (e.g., employee files, financial reports)
- Role-based printing (e.g., Finance-only printers)
- Onboarding/offboarding workflows
- Audit logging for compliance (HIPAA, SOX-style practices)
- Cost-effective, license-free technologies

> All business requirements are documented in the `/simulated-client-project/` folder to simulate a real-world engagement between a client and an IT provider.

---

## 🔐 Encrypted Sections — Protecting Intellectual Property

Parts of this repository are **encrypted** to protect sensitive intellectual property and automation assets developed during this project.

| Folder | Why It’s Encrypted |
|--------|---------------------|
| `/implementation/` | Contains detailed scripts, configuration files, and Ansible roles used to deploy the environment. These assets represent advanced automation and hardening techniques. |
| `/articles/` | Holds full-text versions of the published and unpublished technical articles forming a commercial content series and potential training course material. |

These sections are protected to:
- **Preserve commercial value**
- **Prevent premature reuse without context**
- **Support future training/course opportunities**

> ✅ Verified collaborators or paying clients may be granted access upon request or as part of an engagement.

---

## 🗂 Folder Structure Overview

```plaintext
samba-ad-lab/
├── simulated-client-project/      # Simulated business documents (RFPs, policies)
├── implementation/                # 🔐 Encrypted technical implementation (Ansible, Bash, configs)
├── articles/                      # 🔐 Encrypted tutorial articles and educational content
├── topology/                      # Network diagrams and VM resource plans
├── assets/                        # Images, diagrams, and screenshots
└── README.md                      # This file
