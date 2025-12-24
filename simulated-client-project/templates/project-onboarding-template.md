<!--
███████████████████████████████████████████████████████████████
  🧾 SMB Office IT Blueprint – Project Document
  Doc ID: TEMPLATE-ONBOARDING-PROJECT-001
  Author: Project Manager, Task Assistant
  Created: 2025-12-23
  Updated: 2025-12-23
  Version: v1.0
  Status: Template
  Confidentiality: Internal
  Project Phase: Any
  Category: Template – Onboarding
  Audience: Internal Project Contributors
  Owners: Project Manager
  Reviewers: Project Doc Auditor
  Tags: [onboarding, access, tasks, setup, documentation, project]
  Data Sensitivity: Low
  Compliance: Internal Only
  Publish Target: Internal
  Summary: >
    Use this template to onboard new team members, agents, or contributors to a specific project, lab phase, or submodule. Defines responsibilities, initial tasks, communication channels, and security expectations.
  Read Time: ~3 minutes
███████████████████████████████████████████████████████████████
-->

# 🚀 Project Onboarding Template

---

## 🧾 Project Overview

**Project Name:**  
> _[Insert full project or sub-project name here]_

**Phase or Subsystem:**  
> _[e.g., Lab Build, Ansible Automation, Finance Use Cases]_

**Assigned Department(s):**  
> _[e.g., IT, HR, Content, Security]_

**Primary Contact(s):**  
> _[Project Manager, Role Owner, SME]_

---

## 🎯 Objectives

Briefly describe the purpose of this project or phase and what the new team member will be contributing toward.

```markdown
- Understand and contribute to [module or scope]
- Review related documentation (linked below)
- Complete access request and credential setup
- Begin first assigned task or investigation
````

---

## 📚 Required Reading & Documents

| Document                          | Link                                                                    |
| --------------------------------- | ----------------------------------------------------------------------- |
| Project Overview                  | `../project-overview.md`                                                |
| Org Chart / Departmental Contacts | `../../simulated-client-project/org/simulated-org-chart.md`             |
| Access Policy                     | `../../simulated-client-project/policy/security/user-access-policy.md`  |
| Confidentiality Guidelines        | `../../docs/standards/markdown-doc-standards.md`                        |
| Relevant Use Cases                | *[List use case documents if applicable]*                               |
| Security/Compliance Requirements  | `../../simulated-client-project/policy/security/secure-email-policy.md` |

---

## 🔐 Access Checklist

| Item                     | Required?     | Status | Notes                          |
| ------------------------ | ------------- | ------ | ------------------------------ |
| Git Repository Access    | ✅             | [ ]    | SSH key required               |
| Encrypted Folder Access  | ✅ (if needed) | [ ]    | Request to Project Manager     |
| Samba AD Account         | ✅             | [ ]    | `smb-lab.local` domain         |
| VPN or Remote Lab Access | ✅             | [ ]    | Check onboarding instructions  |
| Email (internal/project) | Optional      | [ ]    | For document reviews or GitHub |

---

## ✅ First Tasks

1. **Review Required Reading**
2. **Join Team Communication Channels**
   *Slack, Matrix, or email list as defined by the team*
3. **Confirm Access Works (Git, VPN, File Shares)**
4. **Open First Task in `task-tracker.md` or GitHub Issues**
5. **Check In with Assigned Supervisor or SME**

---

## 🧭 Tools and Systems Used

| Tool/Platform   | Purpose                      | Notes                                                                                             |
| --------------- | ---------------------------- | ------------------------------------------------------------------------------------------------- |
| Git + git-crypt | Version control & encryption | Setup required                                                                                    |
| Proxmox         | Virtual lab infrastructure   | Read-only access or deploy VMs                                                                    |
| Ansible         | Automation scripting         | Optional for IT agents                                                                            |
| Samba AD        | User/group management        | Review [group-policy-baseline.md](../../simulated-client-project/policy/group-policy-baseline.md) |
| Markdown Docs   | Documentation writing        | Follow [markdown-doc-standards.md](../../docs/standards/markdown-doc-standards.md)                |

---

## 🧩 Assigned Agent Roles

> *List who owns this document, and what chat or AI agents are expected to help this user:*

* Primary Owner: `Project Manager`
* Secondary Owners: `_Specify if needed_`
* Supporting Agents:

  * 🧠 Task Assistant (for schedule + knowledge base)
  * 🛠️ IT Business Analyst (for documentation expectations)
  * 🔐 IT Security Analyst (for secure practices)
  * 👩‍💼 HR Manager (for org role guidance)

---

## 📅 Milestones & Check-ins

| Milestone                | Target Date | Responsible Party |
| ------------------------ | ----------- | ----------------- |
| Access Confirmed         | [ ]         | Contributor       |
| First Task Completed     | [ ]         | Assigned Agent    |
| Initial Review Submitted | [ ]         | Project Manager   |
| Integration Completed    | [ ]         | All Stakeholders  |

---

## 〽️ Status Tracker

| Task                           | Owner           | Status | Last Updated |
| ------------------------------ | --------------- | ------ | ------------ |
| Onboarding Initiated           | Project Manager | [ ]    |              |
| Access Verified                | Contributor     | [ ]    |              |
| First Submission Made          | Contributor     | [ ]    |              |
| Departmental Approval Complete | All Reviewers   | [ ]    |              |

---

## ✅ Departmental Approval Checklist

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

