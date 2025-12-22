# AI Agents Index

**Project:** Samba AD Lab Series - SMB Office IT Blueprint
**Version:** 1.0
**Created:** December 22, 2025

---

## Overview

This index provides a complete reference to all AI agents defined for this project. Each agent has a dedicated statement file that defines its purpose, responsibilities, inputs, outputs, and interaction points.

**Total Agents:** 27
- **Core Agents:** 24 (approved and prioritized)
- **Optional Agents:** 3 (meta-level process agents)

---

## Agent Categories

### 🔷 Business & Strategy Agents (6 agents)
**Focus:** Understanding business needs, planning, and strategic alignment

| Agent | File | Status | Priority |
|-------|------|--------|----------|
| SMB Analyst | `business-strategy/smb-analyst.md` | ✅ Approved | Tier 1 |
| IT Business Analyst | `business-strategy/it-business-analyst.md` | ✅ Approved | Tier 1 |
| Project Manager | `business-strategy/project-manager.md` | ✅ Approved | Tier 1 |
| Task Manager / Assistant | `business-strategy/task-manager.md` | ✅ Approved | Tier 1 |
| Compliance & Risk Analyst | `business-strategy/compliance-risk-analyst.md` | 🆕 New | Tier 4 |
| AI Integration Strategist | `business-strategy/ai-integration-strategist.md` | 🆕 New | Optional |

---

### 🔷 Architecture & Infrastructure Agents (4 agents)
**Focus:** Designing and planning technical infrastructure

| Agent | File | Status | Priority |
|-------|------|--------|----------|
| IT AD Architect | `architecture-infrastructure/it-ad-architect.md` | ✅ Approved | Tier 1 |
| IT Linux Admin/Architect | `architecture-infrastructure/it-linux-admin-architect.md` | ✅ Approved | Tier 1 |
| Cloud/DevOps Advisor | `architecture-infrastructure/cloud-devops-advisor.md` | 🆕 New | Optional |
| Network & Topology Planner | `architecture-infrastructure/network-topology-planner.md` | 🆕 New | Tier 1 |

---

### 🔷 Security Agents (3 agents)
**Focus:** Security analysis, policies, and audit validation

| Agent | File | Status | Priority |
|-------|------|--------|----------|
| IT Security Analyst | `security/it-security-analyst.md` | ✅ Approved | Tier 2 |
| Security Policy Writer | `security/security-policy-writer.md` | 🆕 New | Tier 4 |
| Audit Simulation Agent | `security/audit-simulation-agent.md` | 🆕 New | Tier 4 |

---

### 🔷 Automation & Dev Agents (5 agents)
**Focus:** Writing, testing, and validating automation code

| Agent | File | Status | Priority |
|-------|------|--------|----------|
| IT Ansible Programmer | `automation-dev/it-ansible-programmer.md` | ✅ Approved | Tier 2 |
| Bash Script Assistant | `automation-dev/bash-script-assistant.md` | 🆕 New | Tier 2 |
| IT Code Auditor | `automation-dev/it-code-auditor.md` | ✅ Approved | Tier 2 |
| Test Case Generator | `automation-dev/test-case-generator.md` | 🆕 New | Tier 2 |
| Lab Data Seeder | `automation-dev/lab-data-seeder.md` | 🆕 New | Tier 4 |

---

### 🔷 Content, Documentation & Publishing Agents (6 agents)
**Focus:** Creating, editing, and publishing content

| Agent | File | Status | Priority |
|-------|------|--------|----------|
| Project Doc Auditor | `content-publishing/project-doc-auditor.md` | ✅ Approved | Tier 3 |
| Content Editor | `content-publishing/content-editor.md` | ✅ Approved | Tier 3 |
| SEO Analyst | `content-publishing/seo-analyst.md` | ✅ Approved | Tier 3 |
| Tech-to-Business Translator | `content-publishing/tech-to-business-translator.md` | 🆕 New | Tier 3 |
| Course Designer / LMS Agent | `content-publishing/course-designer.md` | 🆕 New | Tier 3 |
| Publication Coordinator | `content-publishing/publication-coordinator.md` | 🆕 New | Tier 3 |

---

### 🧩 Optional "Meta" Agents (3 agents)
**Focus:** Project process documentation and quality assurance

| Agent | File | Status | Priority |
|-------|------|--------|----------|
| Documentation System Architect | `meta/documentation-system-architect.md` | 🆕 New | Meta |
| Change Tracker Agent | `meta/change-tracker-agent.md` | 🆕 New | Meta |
| Persona Validator | `meta/persona-validator.md` | 🆕 New | Meta |

---

## Agent Tiers

Agents are organized into tiers based on when they're typically activated:

### **Tier 1: Strategy & Planning**
Initial project phases, architecture design, requirements gathering
- SMB Analyst
- IT Business Analyst
- Project Manager
- Task Manager
- IT AD Architect
- IT Linux Admin/Architect
- Network & Topology Planner

### **Tier 2: Implementation & Security**
Building infrastructure, writing automation, security hardening
- IT Ansible Programmer
- Bash Script Assistant
- IT Security Analyst
- IT Code Auditor
- Test Case Generator

### **Tier 3: Content & Delivery**
Writing articles, editing content, publishing materials
- Project Doc Auditor
- Content Editor
- SEO Analyst
- Tech-to-Business Translator
- Course Designer
- Publication Coordinator

### **Tier 4: Simulated Business Needs**
Creating realistic business scenarios, policies, and test data
- Compliance & Risk Analyst
- Security Policy Writer
- Audit Simulation Agent
- Lab Data Seeder

### **Optional: Enhancement & Meta**
Future features, process documentation, quality validation
- AI Integration Strategist
- Cloud/DevOps Advisor
- Documentation System Architect
- Change Tracker Agent
- Persona Validator

---

## Quick Reference: Common Agent Workflows

### Planning a New Feature
1. **SMB Analyst** - Define business need
2. **IT Business Analyst** - Translate to technical requirements
3. **IT AD Architect** / **IT Linux Admin/Architect** - Design solution
4. **IT Security Analyst** - Security review
5. **Project Manager** - Plan implementation

### Implementing Infrastructure
1. **IT Ansible Programmer** - Write automation
2. **IT Code Auditor** - Review code
3. **Test Case Generator** - Create tests
4. **IT Security Analyst** - Validate security

### Publishing Content
1. **Content Editor** - Polish article
2. **SEO Analyst** - Optimize for search
3. **Publication Coordinator** - Schedule release
4. **Tech-to-Business Translator** - Create business-facing version (if needed)

---

## File Structure

```
implementation/agents/
├── AGENTS_INDEX.md (this file)
├── hl_agents.md (original high-level discussion)
├── business-strategy/
│   ├── smb-analyst.md
│   ├── it-business-analyst.md
│   ├── project-manager.md
│   ├── task-manager.md
│   ├── compliance-risk-analyst.md
│   └── ai-integration-strategist.md
├── architecture-infrastructure/
│   ├── it-ad-architect.md
│   ├── it-linux-admin-architect.md
│   ├── cloud-devops-advisor.md
│   └── network-topology-planner.md
├── security/
│   ├── it-security-analyst.md
│   ├── security-policy-writer.md
│   └── audit-simulation-agent.md
├── automation-dev/
│   ├── it-ansible-programmer.md
│   ├── bash-script-assistant.md
│   ├── it-code-auditor.md
│   ├── test-case-generator.md
│   └── lab-data-seeder.md
├── content-publishing/
│   ├── project-doc-auditor.md
│   ├── content-editor.md
│   ├── seo-analyst.md
│   ├── tech-to-business-translator.md
│   ├── course-designer.md
│   └── publication-coordinator.md
└── meta/
    ├── documentation-system-architect.md
    ├── change-tracker-agent.md
    └── persona-validator.md
```

---

## Next Steps

1. **Review** each agent statement file
2. **Prioritize** which agents to implement first
3. **Map** agents to project phases
4. **Define** agent activation triggers for your workflow
5. **Create** agent implementation prompts/templates
6. **Test** agents individually before orchestrating workflows

---

## Version History

| Version | Date | Changes |
|---------|------|---------|
| 1.0 | Dec 22, 2025 | Initial agent index created with 27 agents across 6 categories |

---

*This index is a living document. Update as agents are refined, added, or deprecated.*
