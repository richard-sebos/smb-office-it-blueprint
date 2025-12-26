# Technical System Specification

## Project Ansible Control Server (Layer 1)

**Document Type:** System Specification
**Audience:** Infrastructure Engineers, Platform Architects, Security Reviewers
**Scope:** Infrastructure Control Plane Only
**Out of Scope:** Application configuration, in-guest services, business workloads

---

## 1. System Overview

### 1.1 Purpose

The **Project Ansible Control Server** is a dedicated **infrastructure automation control plane** responsible for provisioning, managing, and rebuilding virtual infrastructure hosted on **Proxmox VE**.

It enables deterministic, repeatable creation of a complete SMB IT environment through Infrastructure-as-Code (IaC) practices.

---

### 1.2 System Role

The Project Ansible Control Server functions as:

* The **single authoritative automation system** for Proxmox
* The **source of truth** for infrastructure state
* A **persistent orchestration layer** that survives environment rebuilds

> Conceptually, it is the *construction foreman*: it builds and demolishes the structure but does not manage what runs inside it.

---

## 2. Architectural Scope

### 2.1 In Scope

The Project Ansible Control Server is responsible for:

* Proxmox API integration
* Virtual machine lifecycle management
* Network bridge and VLAN provisioning
* Storage pool and backup configuration
* Resource pools and tagging
* Infrastructure security enforcement
* Environment deployment, destruction, and reset

---

### 2.2 Explicitly Out of Scope

The system **does not**:

* Configure operating systems beyond base templates
* Install or manage applications inside VMs
* Manage users, directories, or business data
* Act as a bastion or jump host for production access

This separation is intentional and enforced.

---

## 3. Deployment Models

### 3.1 Supported Deployment Options

#### Option A: External Control Workstation

**Use Case:** Development, testing, early iteration

* Linux or macOS workstation
* Direct API access to Proxmox
* No dependency on managed infrastructure

**Characteristics**

* Stateless
* Developer-controlled
* Survives full environment teardown

---

#### Option B: Dedicated Management VM (Recommended for Production)

* Always-on VM
* Management VLAN placement
* Dedicated hostname and IP
* Backed up as critical infrastructure

**Characteristics**

* Predictable availability
* Centralized execution
* Requires bootstrap planning

---

### 3.2 Deployment Constraints

* Must not depend on the environment it provisions
* Must have uninterrupted access to Proxmox API
* Must remain operational during environment destruction

---

## 4. Software Architecture

### 4.1 Core Components

| Component           | Purpose                    |
| ------------------- | -------------------------- |
| Ansible             | Automation engine          |
| Python 3.9+         | Runtime                    |
| Proxmoxer           | Proxmox API client         |
| Ansible Collections | Proxmox and system modules |
| Git                 | Source control             |
| Ansible Vault       | Secret management          |

---

### 4.2 Automation Model

* Declarative, inventory-driven
* Idempotent execution
* Version-controlled
* Fully auditable

The system treats **code as the authoritative description of infrastructure**.

---

## 5. Security Model

### 5.1 Authentication

* Dedicated Proxmox service account
* API token authentication (no passwords)
* Tokens scoped to required privileges only

---

### 5.2 Authorization

* Custom Proxmox role
* Least-privilege permissions
* No root or cluster-admin usage

---

### 5.3 Secret Handling

* All secrets encrypted at rest
* Vaulted credentials only
* Secrets never committed to version control
* Rotation supported without code changes

---

### 5.4 Network Security

* API access restricted by firewall
* Management network isolation
* No inbound access from workload VLANs

---

## 6. Infrastructure Responsibilities

### 6.1 Network Management

The control server enforces:

* VLAN segmentation
* Bridge creation
* IP schema enforcement
* Firewall isolation rules

Network configuration is **defined in code and reproducible**.

---

### 6.2 Storage Management

Responsibilities include:

* LVM-thin pool usage
* Backup storage definition
* Retention enforcement
* Capacity monitoring thresholds

Storage exhaustion is treated as a **critical fault condition**.

---

### 6.3 Resource Governance

The system manages:

* Resource pools
* VM metadata
* Tag taxonomy
* Naming conventions

Governance prevents accidental modification of critical systems.

---

## 7. VM Lifecycle Control

### 7.1 Template Management

Templates are:

* Minimal
* Cloud-init enabled
* Guest-agent enabled
* Versioned
* Immutable once published

---

### 7.2 Provisioning Model

VM creation is:

* Inventory-defined
* Fully automated
* Parallelized where safe
* Metadata-complete

Manual VM creation is considered a policy violation.

---

### 7.3 Environment Operations

Supported operations:

* **Deploy:** Build full environment
* **Destroy:** Safe teardown
* **Reset:** Destroy + redeploy

All operations are explicit, logged, and reversible via backups.

---

## 8. Backup and Recovery

### 8.1 Backup Policy

* Snapshot-based where supported
* Compression enabled
* Retention enforced
* Stored on dedicated backup storage

Backup frequency is determined by VM criticality.

---

### 8.2 Validation Requirement

* Backups must be test-restored
* Tests occur in isolation
* Results documented

Untested backups are considered **non-compliant**.

---

## 9. Performance Characteristics

### 9.1 Performance Targets

| Operation               | Target | Max    |
| ----------------------- | ------ | ------ |
| Full environment deploy | 15 min | 30 min |
| Single VM provision     | 1 min  | 3 min  |
| Environment teardown    | 3 min  | 10 min |

---

### 9.2 Optimization Principles

* Parallel execution
* Minimal API calls
* Controlled concurrency
* Observable execution

Performance regressions are defects.

---

## 10. Maintenance Policy

### 10.1 Template Updates

* Scheduled cadence
* Versioned artifacts
* Rollback supported
* Tested before promotion

---

### 10.2 Dependency Updates

* Version-pinned collections
* Quarterly updates
* Dry-run validation required

---

### 10.3 Version Control

* Semantic versioning
* Tagged releases
* Immutable history
* Clear commit intent

Git is the **system change log**.

---

## 11. Disaster Recovery

### 11.1 Recovery Philosophy

* Rebuild, don’t repair
* Automation is the recovery mechanism
* Backups are encrypted
* Restoration is documented and tested

---

### 11.2 Recovery Objectives

| Scenario                 | RTO                |
| ------------------------ | ------------------ |
| Loss of control server   | ≤ 2 hours          |
| Accidental VM deletion   | ≤ 30 minutes       |
| Network misconfiguration | Automation restore |

---

## 12. Testing and Validation

### 12.1 Pre-Execution

* Syntax validation
* Linting
* Dry-run execution

---

### 12.2 Post-Execution

* Resource existence validation
* Network reachability
* Pool and tag verification

---

### 12.3 Idempotency

Running automation repeatedly must result in **zero changes**.

Idempotency failures block acceptance.

---

## 13. Acceptance Criteria

The Project Ansible Control Server is considered complete when it:

* Deploys infrastructure reliably
* Enforces security boundaries
* Is fully reproducible
* Meets performance targets
* Is auditable end-to-end
* Can be recovered from backup

---

## 14. Non-Normative Artifacts

The following are **implementation details**, not part of the specification:

* Playbooks
* Scripts
* CLI commands
* Inventory examples

These belong in `/implementation/` or `/appendices/`.

---

## 15. Summary

The Project Ansible Control Server is a **purpose-built infrastructure control plane** that:

* Treats infrastructure as disposable
* Enforces security by design
* Encodes operational knowledge as code
* Enables rapid recovery and iteration
* Aligns with enterprise automation practices


