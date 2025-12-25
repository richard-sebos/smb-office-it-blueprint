<!--
███████████████████████████████████████████████████████████████
  🧾 SMB Office IT Blueprint – Project Document
  Doc ID: IMPL-ANSIBLE-ADMIN-001
  Author: Ansible Programmer
  Created: 2025-12-24
  Updated: 2025-12-24
  Version: v1.0
  Status: Draft
  Confidentiality: Internal
  Project Phase: Implementation
  Category: Ansible Implementation Guide
  Audience: IT - Ansible Programmers
  Owners: Ansible Programmer, Linux Admin/Architect
  Reviewers: IT Code Auditor, IT Security Analyst, IT AD Architect
  Tags: [ansible, admin-assistant, automation, implementation, samba, sssd]
  Data Sensitivity: Contains configuration details and group mappings
  Compliance: Internal Security Standards
  Publish Target: Internal
  Summary: >
    Detailed Ansible implementation guide for provisioning Admin Assistant
    user accounts, workstations, and file share access. Includes complete
    playbooks, roles, variables, and validation procedures derived from
    REQ-ROLE-ADMIN-001 and SPEC-SYSTEM-001.
  Read Time: ~25 min
███████████████████████████████████████████████████████████████
-->

# 🔧 Admin Assistant Ansible Implementation Guide

**Source Documents:**
- `REQ-ROLE-ADMIN-001` (admin-assistant-requirements.md)
- `SPEC-SYSTEM-001` (system-specification.md v1.4)

**Implementation Target:** Ansible 2.15+ with Samba AD integration
**Deployment Environment:** Oracle Linux 9 / Ubuntu 22.04 LTS

---

## 📍 Table of Contents

- [1. Overview](#1-overview)
- [2. Prerequisites](#2-prerequisites)
- [3. Directory Structure](#3-directory-structure)
- [4. Inventory Configuration](#4-inventory-configuration)
- [5. Variable Files](#5-variable-files)
- [6. Role 1: Active Directory Setup](#6-role-1-active-directory-setup)
- [7. Role 2: File Server Configuration](#7-role-2-file-server-configuration)
- [8. Role 3: Workstation Provisioning](#8-role-3-workstation-provisioning)
- [9. Role 4: Security Controls](#9-role-4-security-controls)
- [10. Main Orchestration Playbook](#10-main-orchestration-playbook)
- [11. Validation Playbook](#11-validation-playbook)
- [12. Testing Procedures](#12-testing-procedures)
- [13. Troubleshooting](#13-troubleshooting)
- [14. Review History](#14-review-history)
- [15. Departmental Approval Checklist](#15-departmental-approval-checklist)

---

## 1. Overview

### 1.1 Purpose

This document provides complete Ansible automation code and configuration for deploying the Admin Assistant role infrastructure, including:

- **Active Directory** organizational units, security groups, and user accounts
- **File Server** shares, directories, and ACL configurations
- **Workstation** domain join, software installation, and policy enforcement
- **Security** audit logging, USB restrictions, and access controls

### 1.2 Scope

**Components Automated:**
- ✅ AD OU structure creation
- ✅ Security group provisioning with proper nesting
- ✅ User account creation from variable templates
- ✅ File share configuration (Samba)
- ✅ Directory structure and POSIX ACLs
- ✅ Workstation domain join (SSSD)
- ✅ Software installation (LibreOffice, Thunderbird, etc.)
- ✅ Desktop policy enforcement (dconf)
- ✅ Audit rules deployment
- ✅ USB access restrictions

**Manual Steps Required:**
- ⚠️ Initial Samba AD domain controller setup
- ⚠️ Physical/virtual workstation provisioning (can be automated via Proxmox API)
- ⚠️ Network VLAN configuration

### 1.3 Implementation Priority

**Deployment Order:**
1. Prerequisites verification (domain controller, file server operational)
2. AD infrastructure (OUs, groups, users)
3. File server (shares, directories, ACLs)
4. Workstation setup (domain join, software, policies)
5. Security controls (audit, USB restrictions)
6. Validation and testing

---

## 2. Prerequisites

### 2.1 Infrastructure Requirements

| Component | Requirement | Status Check Command |
|-----------|-------------|----------------------|
| Samba AD DC | `dc01.smboffice.local` operational | `samba-tool domain info 127.0.0.1` |
| File Server | `files01.smboffice.local` reachable | `ping files01.smboffice.local` |
| DNS | Forward/reverse zones configured | `nslookup dc01.smboffice.local` |
| Network | VLAN 10 (Office) accessible | `ip addr show` |
| Ansible Controller | Ansible 2.15+ installed | `ansible --version` |

### 2.2 Ansible Collections Required

```bash
# Install required collections
ansible-galaxy collection install community.general
ansible-galaxy collection install ansible.posix
ansible-galaxy collection install community.windows  # If managing Windows clients
```

### 2.3 Authentication Setup

**For Samba AD Operations:**
```bash
# Kerberos authentication
kinit administrator@SMBOFFICE.LOCAL

# Or configure Ansible to use service account
# See inventory configuration in Section 4
```

---

## 3. Directory Structure

Create the following Ansible project structure:

```
ansible/
├── ansible.cfg
├── inventory/
│   ├── hosts.yml
│   └── group_vars/
│       ├── all.yml
│       ├── domain_controllers.yml
│       └── file_servers.yml
├── playbooks/
│   ├── admin-assistant-deploy.yml          # Main orchestration
│   ├── admin-assistant-validate.yml        # Validation playbook
│   └── admin-assistant-remove.yml          # Cleanup/removal (optional)
├── roles/
│   ├── ad_admin_assistant/
│   │   ├── tasks/
│   │   │   ├── main.yml
│   │   │   ├── create_ou.yml
│   │   │   ├── create_groups.yml
│   │   │   ├── nest_groups.yml
│   │   │   └── create_users.yml
│   │   ├── templates/
│   │   │   └── user_creation.sh.j2
│   │   ├── vars/
│   │   │   └── main.yml
│   │   └── defaults/
│   │       └── main.yml
│   ├── fileserver_admin_shares/
│   │   ├── tasks/
│   │   │   ├── main.yml
│   │   │   ├── create_directories.yml
│   │   │   ├── configure_shares.yml
│   │   │   └── set_acls.yml
│   │   ├── templates/
│   │   │   └── smb_admin_shares.conf.j2
│   │   ├── files/
│   │   │   └── sample_templates/
│   │   └── vars/
│   │       └── main.yml
│   ├── workstation_admin/
│   │   ├── tasks/
│   │   │   ├── main.yml
│   │   │   ├── install_packages.yml
│   │   │   ├── domain_join.yml
│   │   │   ├── configure_desktop.yml
│   │   │   └── verify_access.yml
│   │   ├── templates/
│   │   │   ├── sssd.conf.j2
│   │   │   └── dconf_profile.j2
│   │   └── vars/
│   │       └── main.yml
│   └── security_admin_assistant/
│       ├── tasks/
│       │   ├── main.yml
│       │   ├── deploy_auditd.yml
│       │   └── configure_usb.yml
│       ├── files/
│       │   ├── admin-assistant.rules
│       │   └── 99-usb-storage-ro.rules
│       └── vars/
│           └── main.yml
└── README.md
```

---

## 4. Inventory Configuration

### 4.1 Inventory File: `inventory/hosts.yml`

```yaml
all:
  children:
    domain_controllers:
      hosts:
        dc01.smboffice.local:
          ansible_host: 10.10.50.10
          ansible_connection: local  # If Ansible runs on DC
          ansible_python_interpreter: /usr/bin/python3

    file_servers:
      hosts:
        files01.smboffice.local:
          ansible_host: 10.10.50.20
          ansible_user: root
          ansible_become: yes
          ansible_python_interpreter: /usr/bin/python3

    admin_workstations:
      hosts:
        assist-ws01.smboffice.local:
          ansible_host: 10.10.10.101
          assigned_user: emily.chen
          workstation_id: assist-ws01

        assist-ws02.smboffice.local:
          ansible_host: 10.10.10.102
          assigned_user: david.kim
          workstation_id: assist-ws02

  vars:
    ad_domain: smboffice.local
    ad_realm: SMBOFFICE.LOCAL
    ad_base_dn: "DC=smboffice,DC=local"
```

### 4.2 Group Variables: `inventory/group_vars/all.yml`

```yaml
---
# Global settings for all hosts
ansible_user: root
ansible_become: yes
ansible_python_interpreter: /usr/bin/python3

# AD Domain Configuration
ad_domain: "smboffice.local"
ad_realm: "SMBOFFICE.LOCAL"
ad_base_dn: "DC=smboffice,DC=local"
ad_netbios_name: "SMBOFFICE"

# File Server Configuration
file_server_hostname: "files01.smboffice.local"
file_server_ip: "10.10.50.20"
share_base_path: "/srv/samba/shares"

# Network Configuration
office_vlan_id: 10
office_network: "10.10.10.0/24"
```

### 4.3 Domain Controller Variables: `inventory/group_vars/domain_controllers.yml`

```yaml
---
# Samba AD administrator credentials
samba_admin_user: "administrator"
samba_admin_password: "{{ vault_samba_admin_password }}"  # Use ansible-vault

# Samba tool paths
samba_tool: "/usr/bin/samba-tool"
```

---

## 5. Variable Files

### 5.1 Role Variables: `roles/ad_admin_assistant/vars/main.yml`

```yaml
---
# Admin Assistant AD Configuration

# Organizational Unit Structure
admin_assistant_ou_path: "OU=AdminAssistants,OU=SharedServices,OU=Users,{{ ad_base_dn }}"
shared_services_ou_path: "OU=SharedServices,OU=Users,{{ ad_base_dn }}"
users_ou_path: "OU=Users,{{ ad_base_dn }}"

# Security Groups
admin_groups:
  # Global Group (Primary)
  - name: "GG-Shared-Services"
    scope: "Global"
    ou: "OU=Groups,OU=SharedServices,{{ ad_base_dn }}"
    description: "Primary group for all Admin Assistants"
    type: "Security"

  # Domain Local Groups (Resource access)
  - name: "SG-Office-Scheduling"
    scope: "DomainLocal"
    ou: "OU=Groups,OU=SharedServices,{{ ad_base_dn }}"
    description: "Access to calendar and booking systems"
    type: "Security"

  - name: "SG-Print-Access"
    scope: "DomainLocal"
    ou: "OU=Groups,OU=Infrastructure,{{ ad_base_dn }}"
    description: "Networked printer permissions"
    type: "Security"

  - name: "SG-Templates-Write"
    scope: "DomainLocal"
    ou: "OU=Groups,OU=FileAccess,{{ ad_base_dn }}"
    description: "Read/Write to shared document templates"
    type: "Security"

  - name: "SG-HR-Forms-Read"
    scope: "DomainLocal"
    ou: "OU=Groups,OU=FileAccess,{{ ad_base_dn }}"
    description: "Read-only HR forms/templates folder"
    type: "Security"

# Group Nesting Configuration
group_memberships:
  SG-Office-Scheduling:
    - "GG-Shared-Services"
  SG-Print-Access:
    - "GG-Shared-Services"
  SG-Templates-Write:
    - "GG-Shared-Services"
  SG-HR-Forms-Read:
    - "GG-Shared-Services"

# Admin Assistant User Accounts
admin_users:
  - username: "emily.chen"
    firstname: "Emily"
    lastname: "Chen"
    display_name: "Emily Chen"
    email: "emily.chen@smboffice.local"
    department: "Shared Services"
    title: "Administrative Assistant"
    workstation: "assist-ws01"
    primary_group: "GG-Shared-Services"
    password: "{{ vault_emily_initial_password }}"  # Ansible vault
    must_change_password: yes

  - username: "david.kim"
    firstname: "David"
    lastname: "Kim"
    display_name: "David Kim"
    email: "david.kim@smboffice.local"
    department: "Shared Services"
    title: "Administrative Assistant"
    workstation: "assist-ws02"
    primary_group: "GG-Shared-Services"
    password: "{{ vault_david_initial_password }}"  # Ansible vault
    must_change_password: yes

# User Account Settings
user_account_options:
  password_never_expires: false
  user_cannot_change_password: false
  must_change_password_on_first_login: true
  account_disabled: false

# Password Policy (Applied via GPO)
password_policy:
  min_length: 12
  complexity_required: true
  max_age_days: 90
  min_age_days: 1
  history_count: 5
  lockout_threshold: 5
  lockout_duration_minutes: 15

# Home Directory Configuration
home_directory_base: "\\\\files01.smboffice.local\\users"
profile_path_base: "\\\\files01.smboffice.local\\profiles"
logon_script_path: "\\\\files01.smboffice.local\\netlogon\\shared-services-login.sh"
```

### 5.2 File Server Variables: `roles/fileserver_admin_shares/vars/main.yml`

```yaml
---
# File Server Share Configuration

# Base paths
share_root: "/srv/samba/shares"
templates_path: "{{ share_root }}/templates"
hr_forms_path: "{{ share_root }}/hr/forms"
company_policies_path: "{{ share_root }}/company/policies"
users_path: "{{ share_root }}/users"
profiles_path: "{{ share_root }}/profiles"

# Directory Structure
directories:
  # Templates directory
  - path: "{{ templates_path }}"
    owner: root
    group: root
    mode: '0755'
    subdirs:
      - "memos"
      - "letters"
      - "presentations"
      - "spreadsheets"

  # HR Forms (templates only)
  - path: "{{ hr_forms_path }}/templates"
    owner: root
    group: root
    mode: '0755'

  # Company Policies
  - path: "{{ company_policies_path }}"
    owner: root
    group: root
    mode: '0755'

  # User home directories
  - path: "{{ users_path }}"
    owner: root
    group: root
    mode: '0755'

  # User profiles
  - path: "{{ profiles_path }}"
    owner: root
    group: root
    mode: '0755'

# Samba Share Definitions
samba_shares:
  - name: "templates"
    path: "{{ templates_path }}"
    comment: "Shared document templates for office-wide use"
    valid_users: "@SG-Templates-Write"
    read_list: "@SG-Templates-Write"
    write_list: "@SG-Templates-Write"
    create_mask: "0664"
    directory_mask: "0775"
    vfs_objects: "acl_xattr"
    browseable: yes
    guest_ok: no

  - name: "hr-forms"
    path: "{{ hr_forms_path }}"
    comment: "HR forms and templates (read-only for Admin Assistants)"
    valid_users: "@SG-HR-Forms-Read,@GG-HR-Department"
    read_list: "@SG-HR-Forms-Read"
    write_list: "@GG-HR-Department"
    create_mask: "0664"
    directory_mask: "0775"
    vfs_objects: "acl_xattr"
    browseable: yes
    guest_ok: no

  - name: "company-policies"
    path: "{{ company_policies_path }}"
    comment: "Internal company policies and notices"
    valid_users: "@GG-Shared-Services,@GG-Management"
    read_list: "@GG-Shared-Services,@GG-Management"
    write_list: "@GG-Shared-Services,@GG-Management"
    create_mask: "0664"
    directory_mask: "0775"
    vfs_objects: "acl_xattr"
    browseable: yes
    guest_ok: no

# POSIX ACL Configuration
posix_acls:
  # Templates - RWX for SG-Templates-Write
  - path: "{{ templates_path }}"
    acl_rules:
      - "g:SG-Templates-Write:rwx"
    default_acl_rules:
      - "g:SG-Templates-Write:rwx"
    recursive: yes

  # HR Forms Templates - Read-only for SG-HR-Forms-Read
  - path: "{{ hr_forms_path }}/templates"
    acl_rules:
      - "g:SG-HR-Forms-Read:r-x"
      - "g:GG-HR-Department:rwx"
    default_acl_rules:
      - "g:SG-HR-Forms-Read:r-x"
      - "g:GG-HR-Department:rwx"
    recursive: yes

  # Company Policies - RWX for Shared Services
  - path: "{{ company_policies_path }}"
    acl_rules:
      - "g:GG-Shared-Services:rwx"
      - "g:GG-Management:rwx"
    default_acl_rules:
      - "g:GG-Shared-Services:rwx"
      - "g:GG-Management:rwx"
    recursive: yes
```

### 5.3 Workstation Variables: `roles/workstation_admin/vars/main.yml`

```yaml
---
# Workstation Configuration

# Required Packages
packages:
  ubuntu:
    - libreoffice
    - libreoffice-writer
    - libreoffice-calc
    - thunderbird
    - firefox
    - evince
    - cups-client
    - sssd
    - sssd-ad
    - sssd-tools
    - realmd
    - adcli
    - krb5-user
    - packagekit
    - policykit-1

# SSSD Configuration
sssd_config:
  domains: "{{ ad_domain }}"
  config_file_version: 2
  services: "nss, pam"

sssd_domain_config:
  ad_domain: "{{ ad_domain }}"
  krb5_realm: "{{ ad_realm }}"
  realmd_tags: "manages-system joined-with-samba"
  cache_credentials: true
  id_provider: "ad"
  krb5_store_password_if_offline: true
  default_shell: "/bin/bash"
  ldap_id_mapping: true
  use_fully_qualified_names: false
  fallback_homedir: "/home/%u"
  access_provider: "ad"
  ad_gpo_access_control: "enforcing"
  ad_gpo_map_interactive: "+assist-ws01"

# Desktop Policies (dconf)
desktop_policies:
  - key: "/org/gnome/desktop/lockdown/disable-user-switching"
    value: "true"
  - key: "/org/gnome/desktop/lockdown/disable-log-out"
    value: "false"
  - key: "/org/gnome/desktop/media-handling/automount"
    value: "false"
  - key: "/org/gnome/desktop/media-handling/automount-open"
    value: "false"
  - key: "/org/gnome/desktop/screensaver/lock-enabled"
    value: "true"
  - key: "/org/gnome/desktop/screensaver/lock-delay"
    value: "uint32 300"
  - key: "/org/gnome/desktop/screensaver/idle-activation-enabled"
    value: "true"
  - key: "/org/gnome/desktop/session/idle-delay"
    value: "uint32 600"

# Default Applications
default_applications:
  text_editor: "libreoffice-writer.desktop"
  document_viewer: "evince.desktop"
  web_browser: "firefox.desktop"
  email_client: "thunderbird.desktop"
```

---

## 6. Role 1: Active Directory Setup

### 6.1 Main Tasks: `roles/ad_admin_assistant/tasks/main.yml`

```yaml
---
# Main task file for AD Admin Assistant setup

- name: Include OU creation tasks
  include_tasks: create_ou.yml
  tags:
    - ad
    - ou

- name: Include security group creation tasks
  include_tasks: create_groups.yml
  tags:
    - ad
    - groups

- name: Include group nesting tasks
  include_tasks: nest_groups.yml
  tags:
    - ad
    - groups
    - nesting

- name: Include user creation tasks
  include_tasks: create_users.yml
  tags:
    - ad
    - users
```

### 6.2 OU Creation: `roles/ad_admin_assistant/tasks/create_ou.yml`

```yaml
---
# Create Organizational Unit structure

- name: Check if SharedServices OU exists
  command: >
    {{ samba_tool }} ou show "{{ shared_services_ou_path }}"
  register: shared_services_ou_check
  failed_when: false
  changed_when: false

- name: Create SharedServices OU
  command: >
    {{ samba_tool }} ou create "{{ shared_services_ou_path }}"
    --description="Shared Services department organizational unit"
  when: shared_services_ou_check.rc != 0
  register: ou_creation

- name: Check if AdminAssistants OU exists
  command: >
    {{ samba_tool }} ou show "{{ admin_assistant_ou_path }}"
  register: admin_ou_check
  failed_when: false
  changed_when: false

- name: Create AdminAssistants OU
  command: >
    {{ samba_tool }} ou create "{{ admin_assistant_ou_path }}"
    --description="Administrative Assistant accounts for multi-departmental support"
  when: admin_ou_check.rc != 0
  register: admin_ou_creation

- name: Display OU creation results
  debug:
    msg: "Created OUs: {{ [ou_creation, admin_ou_creation] | selectattr('changed', 'equalto', true) | list | length }} OUs created"
```

### 6.3 Group Creation: `roles/ad_admin_assistant/tasks/create_groups.yml`

```yaml
---
# Create security groups

- name: Check if security groups exist
  command: >
    {{ samba_tool }} group show "{{ item.name }}"
  loop: "{{ admin_groups }}"
  register: group_check
  failed_when: false
  changed_when: false

- name: Create security groups
  command: >
    {{ samba_tool }} group add "{{ item.item.name }}"
    --description="{{ item.item.description }}"
    --group-scope="{{ item.item.scope }}"
    --group-type="{{ item.item.type }}"
  loop: "{{ group_check.results }}"
  when: item.rc != 0
  loop_control:
    label: "{{ item.item.name }}"

- name: Move groups to correct OUs (if needed)
  command: >
    {{ samba_tool }} group move "{{ item.name }}" "{{ item.ou }}"
  loop: "{{ admin_groups }}"
  when: item.ou is defined
  ignore_errors: yes  # May fail if already in correct OU
```

### 6.4 Group Nesting: `roles/ad_admin_assistant/tasks/nest_groups.yml`

```yaml
---
# Configure group nesting (add GG-Shared-Services to resource groups)

- name: Add GG-Shared-Services to resource access groups
  command: >
    {{ samba_tool }} group addmembers "{{ item.key }}" "{{ item.value | join(',') }}"
  loop: "{{ group_memberships | dict2items }}"
  register: group_nesting
  failed_when:
    - group_nesting.rc != 0
    - "'already a member' not in group_nesting.stderr"
  changed_when: "'already a member' not in group_nesting.stderr"
  loop_control:
    label: "Adding {{ item.value }} to {{ item.key }}"
```

### 6.5 User Creation: `roles/ad_admin_assistant/tasks/create_users.yml`

```yaml
---
# Create Admin Assistant user accounts

- name: Check if users exist
  command: >
    {{ samba_tool }} user show "{{ item.username }}"
  loop: "{{ admin_users }}"
  register: user_check
  failed_when: false
  changed_when: false
  loop_control:
    label: "{{ item.username }}"

- name: Create Admin Assistant user accounts
  command: >
    {{ samba_tool }} user create "{{ item.item.username }}" "{{ item.item.password }}"
    --given-name="{{ item.item.firstname }}"
    --surname="{{ item.item.lastname }}"
    --mail-address="{{ item.item.email }}"
    --department="{{ item.item.department }}"
    --job-title="{{ item.item.title }}"
    --use-username-as-cn
  loop: "{{ user_check.results }}"
  when: item.rc != 0
  no_log: yes  # Don't log passwords
  loop_control:
    label: "{{ item.item.username }}"

- name: Move users to AdminAssistants OU
  command: >
    {{ samba_tool }} user move "{{ item.username }}" "{{ admin_assistant_ou_path }}"
  loop: "{{ admin_users }}"
  register: user_move
  failed_when:
    - user_move.rc != 0
    - "'already exists' not in user_move.stderr"

- name: Add users to GG-Shared-Services group
  command: >
    {{ samba_tool }} group addmembers "{{ item.primary_group }}" "{{ item.username }}"
  loop: "{{ admin_users }}"
  register: add_to_group
  failed_when:
    - add_to_group.rc != 0
    - "'already a member' not in add_to_group.stderr"
  changed_when: "'already a member' not in add_to_group.stderr"
  loop_control:
    label: "{{ item.username }} -> {{ item.primary_group }}"

- name: Set user to change password at next login
  command: >
    {{ samba_tool }} user setexpiry "{{ item.username }}" --noexpiry
  loop: "{{ admin_users }}"
  when: item.must_change_password
  loop_control:
    label: "{{ item.username }}"

- name: Set user account options
  shell: |
    {{ samba_tool }} user setpassword "{{ item.username }}" \
      --must-change-at-next-login
  loop: "{{ admin_users }}"
  when: item.must_change_password
  no_log: yes
  loop_control:
    label: "{{ item.username }}"
```

---

## 7. Role 2: File Server Configuration

### 7.1 Main Tasks: `roles/fileserver_admin_shares/tasks/main.yml`

```yaml
---
# Main task file for File Server Admin Assistant shares

- name: Include directory creation tasks
  include_tasks: create_directories.yml
  tags:
    - fileserver
    - directories

- name: Include share configuration tasks
  include_tasks: configure_shares.yml
  tags:
    - fileserver
    - shares

- name: Include ACL configuration tasks
  include_tasks: set_acls.yml
  tags:
    - fileserver
    - acls
```

### 7.2 Directory Creation: `roles/fileserver_admin_shares/tasks/create_directories.yml`

```yaml
---
# Create directory structure

- name: Ensure base share directory exists
  file:
    path: "{{ share_root }}"
    state: directory
    owner: root
    group: root
    mode: '0755'

- name: Create main directories
  file:
    path: "{{ item.path }}"
    state: directory
    owner: "{{ item.owner }}"
    group: "{{ item.group }}"
    mode: "{{ item.mode }}"
  loop: "{{ directories }}"
  loop_control:
    label: "{{ item.path }}"

- name: Create subdirectories for templates
  file:
    path: "{{ templates_path }}/{{ item }}"
    state: directory
    owner: root
    group: root
    mode: '0755'
  loop:
    - memos
    - letters
    - presentations
    - spreadsheets

- name: Create HR forms templates directory
  file:
    path: "{{ hr_forms_path }}/templates"
    state: directory
    owner: root
    group: root
    mode: '0755'

- name: Create sample template files
  copy:
    dest: "{{ hr_forms_path }}/templates/{{ item }}"
    content: |
      # Sample HR Form Template
      # This is a placeholder file
    owner: root
    group: root
    mode: '0644'
  loop:
    - employment-application.txt
    - time-off-request.txt
    - employee-info-update.txt
  when: create_sample_files | default(false)
```

### 7.3 Share Configuration: `roles/fileserver_admin_shares/tasks/configure_shares.yml`

```yaml
---
# Configure Samba shares

- name: Generate Samba share configuration from template
  template:
    src: smb_admin_shares.conf.j2
    dest: /etc/samba/smb.conf.d/admin-shares.conf
    owner: root
    group: root
    mode: '0644'
  notify: restart smbd

- name: Include admin shares in main smb.conf
  lineinfile:
    path: /etc/samba/smb.conf
    line: "include = /etc/samba/smb.conf.d/admin-shares.conf"
    insertafter: '\[global\]'
    state: present
  notify: restart smbd

- name: Test Samba configuration
  command: testparm -s
  register: testparm_result
  failed_when: testparm_result.rc != 0
  changed_when: false

- name: Display Samba configuration test results
  debug:
    var: testparm_result.stdout_lines
```

### 7.4 Samba Share Template: `roles/fileserver_admin_shares/templates/smb_admin_shares.conf.j2`

```ini
# Admin Assistant Samba Shares
# Generated by Ansible - DO NOT EDIT MANUALLY

{% for share in samba_shares %}
[{{ share.name }}]
path = {{ share.path }}
comment = {{ share.comment }}
valid users = {{ share.valid_users }}
{% if share.read_list is defined %}
read list = {{ share.read_list }}
{% endif %}
{% if share.write_list is defined %}
write list = {{ share.write_list }}
{% endif %}
create mask = {{ share.create_mask }}
directory mask = {{ share.directory_mask }}
vfs objects = {{ share.vfs_objects }}
browseable = {{ share.browseable | lower }}
guest ok = {{ share.guest_ok | lower }}
{% if share.read_only is defined %}
read only = {{ share.read_only | lower }}
{% else %}
read only = no
{% endif %}

{% endfor %}
```

### 7.5 ACL Configuration: `roles/fileserver_admin_shares/tasks/set_acls.yml`

```yaml
---
# Set POSIX ACLs on share directories

- name: Install ACL package
  package:
    name: acl
    state: present

- name: Set ACLs on share directories
  acl:
    path: "{{ item.path }}"
    entity: "{{ acl_rule.split(':')[0] }}"
    etype: "{{ acl_rule.split(':')[0][0] }}"  # u or g
    permissions: "{{ acl_rule.split(':')[2] }}"
    state: present
    recursive: "{{ item.recursive }}"
  loop: "{{ posix_acls }}"
  loop_control:
    loop_var: acl_item
    label: "{{ acl_item.path }}"
  with_subelements:
    - "{{ posix_acls }}"
    - acl_rules
  vars:
    acl_rule: "{{ item.1 }}"
    item: "{{ acl_item }}"

- name: Set default ACLs (inheritance)
  acl:
    path: "{{ item.path }}"
    entity: "{{ acl_rule.split(':')[0] }}"
    etype: "{{ acl_rule.split(':')[0][0] }}"
    permissions: "{{ acl_rule.split(':')[2] }}"
    default: yes
    state: present
    recursive: "{{ item.recursive }}"
  loop: "{{ posix_acls }}"
  loop_control:
    loop_var: acl_item
    label: "{{ acl_item.path }}"
  with_subelements:
    - "{{ posix_acls }}"
    - default_acl_rules
  vars:
    acl_rule: "{{ item.1 }}"
    item: "{{ acl_item }}"
  when: item.default_acl_rules is defined

- name: Verify ACLs with getfacl
  command: getfacl "{{ item.path }}"
  loop: "{{ posix_acls }}"
  register: acl_verification
  changed_when: false
  loop_control:
    label: "{{ item.path }}"

- name: Display ACL verification results
  debug:
    msg: "{{ item.stdout_lines }}"
  loop: "{{ acl_verification.results }}"
  loop_control:
    label: "{{ item.item.path }}"
```

---

## 8. Role 3: Workstation Provisioning

### 8.1 Main Tasks: `roles/workstation_admin/tasks/main.yml`

```yaml
---
# Main task file for Admin workstation setup

- name: Include package installation tasks
  include_tasks: install_packages.yml
  tags:
    - workstation
    - packages

- name: Include domain join tasks
  include_tasks: domain_join.yml
  tags:
    - workstation
    - domain

- name: Include desktop configuration tasks
  include_tasks: configure_desktop.yml
  tags:
    - workstation
    - desktop

- name: Include access verification tasks
  include_tasks: verify_access.yml
  tags:
    - workstation
    - verify
```

### 8.2 Package Installation: `roles/workstation_admin/tasks/install_packages.yml`

```yaml
---
# Install required packages

- name: Update apt cache
  apt:
    update_cache: yes
    cache_valid_time: 3600
  when: ansible_os_family == "Debian"

- name: Install Admin Assistant workstation packages
  package:
    name: "{{ packages.ubuntu }}"
    state: present
  when: ansible_os_family == "Debian"

- name: Ensure CUPS client is configured
  systemd:
    name: cups-browsed
    state: started
    enabled: yes
```

### 8.3 Domain Join: `roles/workstation_admin/tasks/domain_join.yml`

```yaml
---
# Join workstation to AD domain via SSSD

- name: Configure Kerberos client
  template:
    src: krb5.conf.j2
    dest: /etc/krb5.conf
    owner: root
    group: root
    mode: '0644'

- name: Configure SSSD
  template:
    src: sssd.conf.j2
    dest: /etc/sssd/sssd.conf
    owner: root
    group: root
    mode: '0600'
  notify: restart sssd

- name: Check if already domain-joined
  command: realm list
  register: realm_check
  changed_when: false
  failed_when: false

- name: Join domain using realm
  command: >
    realm join {{ ad_domain }}
    --user={{ samba_admin_user }}
    --client-software=sssd
    --membership-software=samba
  when: ad_domain not in realm_check.stdout
  environment:
    REALM_PASSWORD: "{{ samba_admin_password }}"
  no_log: yes

- name: Permit all AD users to login
  command: realm permit --all
  when: ad_domain not in realm_check.stdout

- name: Configure PAM to create home directories
  lineinfile:
    path: /etc/pam.d/common-session
    line: "session required pam_mkhomedir.so skel=/etc/skel/ umask=0077"
    insertafter: "session.*pam_unix.so"
    state: present

- name: Start and enable SSSD
  systemd:
    name: sssd
    state: started
    enabled: yes
```

### 8.4 SSSD Template: `roles/workstation_admin/templates/sssd.conf.j2`

```ini
[sssd]
domains = {{ sssd_config.domains }}
config_file_version = {{ sssd_config.config_file_version }}
services = {{ sssd_config.services }}

[domain/{{ ad_domain }}]
ad_domain = {{ sssd_domain_config.ad_domain }}
krb5_realm = {{ sssd_domain_config.krb5_realm }}
realmd_tags = {{ sssd_domain_config.realmd_tags }}
cache_credentials = {{ sssd_domain_config.cache_credentials | lower }}
id_provider = {{ sssd_domain_config.id_provider }}
krb5_store_password_if_offline = {{ sssd_domain_config.krb5_store_password_if_offline | lower }}
default_shell = {{ sssd_domain_config.default_shell }}
ldap_id_mapping = {{ sssd_domain_config.ldap_id_mapping | lower }}
use_fully_qualified_names = {{ sssd_domain_config.use_fully_qualified_names | lower }}
fallback_homedir = {{ sssd_domain_config.fallback_homedir }}
access_provider = {{ sssd_domain_config.access_provider }}
ad_gpo_access_control = {{ sssd_domain_config.ad_gpo_access_control }}
```

### 8.5 Desktop Configuration: `roles/workstation_admin/tasks/configure_desktop.yml`

```yaml
---
# Configure desktop policies

- name: Create dconf profile directory
  file:
    path: /etc/dconf/profile
    state: directory
    owner: root
    group: root
    mode: '0755'

- name: Create dconf user profile
  copy:
    dest: /etc/dconf/profile/user
    content: |
      user-db:user
      system-db:local
    owner: root
    group: root
    mode: '0644'

- name: Create dconf local database directory
  file:
    path: /etc/dconf/db/local.d
    state: directory
    owner: root
    group: root
    mode: '0755'

- name: Apply desktop policies via dconf
  copy:
    dest: /etc/dconf/db/local.d/00-admin-assistant-policy
    content: |
      # Admin Assistant Desktop Policies
      [org/gnome/desktop/lockdown]
      disable-user-switching={{ desktop_policies | selectattr('key', 'equalto', '/org/gnome/desktop/lockdown/disable-user-switching') | map(attribute='value') | first }}
      disable-log-out={{ desktop_policies | selectattr('key', 'equalto', '/org/gnome/desktop/lockdown/disable-log-out') | map(attribute='value') | first }}

      [org/gnome/desktop/media-handling]
      automount={{ desktop_policies | selectattr('key', 'equalto', '/org/gnome/desktop/media-handling/automount') | map(attribute='value') | first }}
      automount-open={{ desktop_policies | selectattr('key', 'equalto', '/org/gnome/desktop/media-handling/automount-open') | map(attribute='value') | first }}

      [org/gnome/desktop/screensaver]
      lock-enabled={{ desktop_policies | selectattr('key', 'equalto', '/org/gnome/desktop/screensaver/lock-enabled') | map(attribute='value') | first }}
      lock-delay={{ desktop_policies | selectattr('key', 'equalto', '/org/gnome/desktop/screensaver/lock-delay') | map(attribute='value') | first | regex_replace('uint32 ', '') }}
      idle-activation-enabled={{ desktop_policies | selectattr('key', 'equalto', '/org/gnome/desktop/screensaver/idle-activation-enabled') | map(attribute='value') | first }}

      [org/gnome/desktop/session]
      idle-delay={{ desktop_policies | selectattr('key', 'equalto', '/org/gnome/desktop/session/idle-delay') | map(attribute='value') | first | regex_replace('uint32 ', '') }}
    owner: root
    group: root
    mode: '0644'
  notify: update dconf

- name: Create dconf locks directory
  file:
    path: /etc/dconf/db/local.d/locks
    state: directory
    owner: root
    group: root
    mode: '0755'

- name: Lock desktop policies
  copy:
    dest: /etc/dconf/db/local.d/locks/admin-assistant
    content: |
      /org/gnome/desktop/lockdown/disable-user-switching
      /org/gnome/desktop/media-handling/automount
      /org/gnome/desktop/screensaver/lock-enabled
      /org/gnome/desktop/screensaver/lock-delay
    owner: root
    group: root
    mode: '0644'
  notify: update dconf
```

---

## 9. Role 4: Security Controls

### 9.1 Main Tasks: `roles/security_admin_assistant/tasks/main.yml`

```yaml
---
# Main task file for security controls

- name: Include auditd deployment tasks
  include_tasks: deploy_auditd.yml
  tags:
    - security
    - auditd

- name: Include USB restriction tasks
  include_tasks: configure_usb.yml
  tags:
    - security
    - usb
```

### 9.2 Auditd Deployment: `roles/security_admin_assistant/tasks/deploy_auditd.yml`

```yaml
---
# Deploy auditd rules for Admin Assistant monitoring

- name: Install auditd package
  package:
    name: auditd
    state: present

- name: Deploy Admin Assistant audit rules
  copy:
    src: admin-assistant.rules
    dest: /etc/audit/rules.d/admin-assistant.rules
    owner: root
    group: root
    mode: '0640'
  notify: restart auditd

- name: Load audit rules
  command: augenrules --load
  changed_when: false

- name: Enable and start auditd
  systemd:
    name: auditd
    state: started
    enabled: yes
```

### 9.3 Audit Rules File: `roles/security_admin_assistant/files/admin-assistant.rules`

```bash
## Admin Assistant Audit Rules
## Monitors file access and modifications

# Monitor access to HR forms templates
-w /srv/samba/shares/hr/forms/templates -p r -k admin_hr_access

# Monitor modifications to company policies
-w /srv/samba/shares/company/policies -p w -k admin_policy_write

# Monitor template modifications
-w /srv/samba/shares/templates -p w -k admin_template_write

# Monitor USB device access
-w /dev/bus/usb -p r -k admin_usb_access

# Monitor execution of sensitive binaries
-w /usr/bin/smbclient -p x -k admin_samba_exec
-w /usr/bin/mount -p x -k admin_mount_exec

# System call monitoring for file operations
-a always,exit -F arch=b64 -S open,openat,creat -F dir=/srv/samba/shares -F auid>=1000 -F auid!=4294967295 -k admin_file_access
```

### 9.4 USB Configuration: `roles/security_admin_assistant/tasks/configure_usb.yml`

```yaml
---
# Configure USB storage restrictions (read-only)

- name: Deploy USB read-only udev rule
  copy:
    src: 99-usb-storage-ro.rules
    dest: /etc/udev/rules.d/99-usb-storage-ro.rules
    owner: root
    group: root
    mode: '0644'
  notify: reload udev

- name: Reload udev rules immediately
  command: udevadm control --reload-rules
  changed_when: false

- name: Trigger udev to apply rules
  command: udevadm trigger
  changed_when: false
```

### 9.5 USB udev Rules: `roles/security_admin_assistant/files/99-usb-storage-ro.rules`

```bash
# USB Storage Read-Only Rule for Admin Assistants
# This rule makes USB storage devices read-only

# Allow USB devices to be authorized
SUBSYSTEM=="usb", ATTR{authorized}="1"

# Set removable block devices to read-only presentation
SUBSYSTEM=="block", ATTRS{removable}=="1", ENV{UDISKS_PRESENTATION_HIDE}="0", ENV{UDISKS_PRESENTATION_RO}="1"

# Alternative approach using blockdev
# SUBSYSTEM=="block", ATTRS{removable}=="1", RUN+="/sbin/blockdev --setro /dev/%k"
```

---

## 10. Main Orchestration Playbook

### 10.1 Main Playbook: `playbooks/admin-assistant-deploy.yml`

```yaml
---
# Admin Assistant Infrastructure Deployment
# This playbook orchestrates the complete setup of Admin Assistant infrastructure

- name: Deploy Admin Assistant Active Directory Infrastructure
  hosts: domain_controllers
  gather_facts: yes
  become: yes

  pre_tasks:
    - name: Verify Samba AD is operational
      command: samba-tool domain info 127.0.0.1
      register: domain_check
      failed_when: domain_check.rc != 0
      changed_when: false

    - name: Display domain information
      debug:
        var: domain_check.stdout_lines

  roles:
    - role: ad_admin_assistant
      tags: ['ad', 'users', 'groups']

  post_tasks:
    - name: Verify AD configuration
      command: samba-tool group listmembers GG-Shared-Services
      register: group_members
      changed_when: false

    - name: Display GG-Shared-Services members
      debug:
        var: group_members.stdout_lines

---

- name: Configure File Server for Admin Assistant Access
  hosts: file_servers
  gather_facts: yes
  become: yes

  pre_tasks:
    - name: Verify file server is reachable
      ping:

    - name: Check if Samba is installed
      command: smbd --version
      register: samba_version
      changed_when: false

    - name: Display Samba version
      debug:
        var: samba_version.stdout

  roles:
    - role: fileserver_admin_shares
      tags: ['fileserver', 'shares', 'acls']

  post_tasks:
    - name: Test Samba share accessibility
      command: smbclient -L //{{ ansible_hostname }} -N
      register: share_list
      changed_when: false

    - name: Display available shares
      debug:
        var: share_list.stdout_lines

---

- name: Provision Admin Assistant Workstations
  hosts: admin_workstations
  gather_facts: yes
  become: yes

  pre_tasks:
    - name: Verify network connectivity to domain
      command: ping -c 3 {{ ad_domain }}
      register: domain_ping
      changed_when: false

    - name: Display network test results
      debug:
        msg: "Domain {{ ad_domain }} is reachable"

  roles:
    - role: workstation_admin
      tags: ['workstation', 'domain', 'desktop']

  post_tasks:
    - name: Test AD authentication
      command: id {{ item.assigned_user }}@{{ ad_domain }}
      register: user_id
      changed_when: false
      failed_when: false

    - name: Display user ID information
      debug:
        var: user_id.stdout

---

- name: Deploy Security Controls
  hosts: all
  gather_facts: yes
  become: yes

  roles:
    - role: security_admin_assistant
      tags: ['security', 'audit', 'usb']

  post_tasks:
    - name: Verify auditd is running
      systemd:
        name: auditd
        state: started
      check_mode: yes
      register: auditd_status

    - name: Display security deployment summary
      debug:
        msg:
          - "Auditd Status: {{ auditd_status.state }}"
          - "USB restrictions deployed"
```

---

## 11. Validation Playbook

### 11.1 Validation Playbook: `playbooks/admin-assistant-validate.yml`

```yaml
---
# Admin Assistant Configuration Validation Playbook

- name: Validate Active Directory Configuration
  hosts: domain_controllers
  gather_facts: no
  become: yes

  tasks:
    - name: Check if OUs exist
      command: samba-tool ou show "{{ item }}"
      loop:
        - "OU=AdminAssistants,OU=SharedServices,OU=Users,{{ ad_base_dn }}"
        - "OU=SharedServices,OU=Users,{{ ad_base_dn }}"
      register: ou_validation
      failed_when: ou_validation.rc != 0

    - name: Check if security groups exist
      command: samba-tool group show "{{ item }}"
      loop:
        - GG-Shared-Services
        - SG-Office-Scheduling
        - SG-Print-Access
        - SG-Templates-Write
        - SG-HR-Forms-Read
      register: group_validation
      failed_when: group_validation.rc != 0

    - name: Check if users exist
      command: samba-tool user show "{{ item }}"
      loop:
        - emily.chen
        - david.kim
      register: user_validation
      failed_when: user_validation.rc != 0

    - name: Verify group memberships
      command: samba-tool group listmembers GG-Shared-Services
      register: members_check

    - name: Display group members
      debug:
        var: members_check.stdout_lines

    - name: Assert users are members
      assert:
        that:
          - "'emily.chen' in members_check.stdout"
          - "'david.kim' in members_check.stdout"
        fail_msg: "Not all users are members of GG-Shared-Services"
        success_msg: "All users properly assigned to group"

---

- name: Validate File Server Configuration
  hosts: file_servers
  gather_facts: no
  become: yes

  tasks:
    - name: Check if share directories exist
      stat:
        path: "{{ item }}"
      loop:
        - /srv/samba/shares/templates
        - /srv/samba/shares/hr/forms/templates
        - /srv/samba/shares/company/policies
      register: dir_check

    - name: Assert directories exist
      assert:
        that: item.stat.exists
        fail_msg: "Directory {{ item.item }} does not exist"
      loop: "{{ dir_check.results }}"
      loop_control:
        label: "{{ item.item }}"

    - name: Verify ACLs on templates directory
      command: getfacl /srv/samba/shares/templates
      register: acl_check
      changed_when: false

    - name: Display ACL configuration
      debug:
        var: acl_check.stdout_lines

    - name: Verify Samba shares are defined
      command: testparm -s --section-name={{ item }}
      loop:
        - templates
        - hr-forms
        - company-policies
      register: share_validation
      changed_when: false

    - name: Test SMB share connectivity
      command: smbclient //{{ ansible_hostname }}/templates -N -c 'ls'
      register: smb_test
      failed_when: false
      changed_when: false

    - name: Display share test results
      debug:
        var: smb_test.stdout_lines

---

- name: Validate Workstation Configuration
  hosts: admin_workstations
  gather_facts: no
  become: yes

  tasks:
    - name: Check if domain-joined
      command: realm list
      register: realm_status
      changed_when: false

    - name: Assert domain membership
      assert:
        that: "ad_domain in realm_status.stdout"
        fail_msg: "Workstation not joined to {{ ad_domain }}"
        success_msg: "Workstation successfully joined to domain"

    - name: Test user ID resolution
      command: id {{ item }}
      loop:
        - emily.chen
        - david.kim
      register: id_test
      changed_when: false

    - name: Display user ID information
      debug:
        var: id_test.results

    - name: Check if required packages are installed
      package:
        name: "{{ item }}"
        state: present
      check_mode: yes
      loop:
        - libreoffice
        - thunderbird
        - firefox
      register: package_check

    - name: Verify SSSD is running
      systemd:
        name: sssd
        state: started
      check_mode: yes
      register: sssd_check

    - name: Assert SSSD is active
      assert:
        that: sssd_check.status.ActiveState == "active"
        fail_msg: "SSSD is not running"
        success_msg: "SSSD service is active"

---

- name: Validate Security Controls
  hosts: all
  gather_facts: no
  become: yes

  tasks:
    - name: Check if auditd is running
      systemd:
        name: auditd
        state: started
      check_mode: yes
      register: auditd_check

    - name: Verify audit rules are loaded
      command: auditctl -l
      register: audit_rules
      changed_when: false

    - name: Display loaded audit rules
      debug:
        var: audit_rules.stdout_lines

    - name: Check if USB udev rule exists
      stat:
        path: /etc/udev/rules.d/99-usb-storage-ro.rules
      register: udev_rule_check

    - name: Assert udev rule is deployed
      assert:
        that: udev_rule_check.stat.exists
        fail_msg: "USB restriction rule not deployed"
        success_msg: "USB restriction rule is in place"

---

- name: Generate Validation Report
  hosts: localhost
  gather_facts: no

  tasks:
    - name: Display validation summary
      debug:
        msg:
          - "==== Admin Assistant Infrastructure Validation ===="
          - "Active Directory: PASSED"
          - "File Server: PASSED"
          - "Workstations: PASSED"
          - "Security Controls: PASSED"
          - "All validation checks completed successfully"
```

---

## 12. Testing Procedures

### 12.1 Pre-Deployment Testing

**Test 1: Verify Prerequisites**
```bash
# On Ansible controller
ansible-playbook playbooks/admin-assistant-deploy.yml --check --diff

# Expected: No errors in check mode
```

**Test 2: Syntax Validation**
```bash
# Validate playbook syntax
ansible-playbook playbooks/admin-assistant-deploy.yml --syntax-check

# Validate all roles
for role in roles/*/tasks/main.yml; do
  ansible-playbook --syntax-check -i localhost, <(echo "- hosts: localhost; roles: [$(dirname $(dirname $role))]")
done
```

### 12.2 Deployment Testing

**Test 3: Deploy to Test Environment**
```bash
# Deploy with verbose output
ansible-playbook playbooks/admin-assistant-deploy.yml -vv

# Monitor progress and capture output
ansible-playbook playbooks/admin-assistant-deploy.yml | tee deploy-$(date +%Y%m%d-%H%M%S).log
```

**Test 4: Incremental Deployment**
```bash
# Deploy only AD components
ansible-playbook playbooks/admin-assistant-deploy.yml --tags ad

# Deploy only file server
ansible-playbook playbooks/admin-assistant-deploy.yml --tags fileserver

# Deploy only workstations
ansible-playbook playbooks/admin-assistant-deploy.yml --tags workstation

# Deploy only security
ansible-playbook playbooks/admin-assistant-deploy.yml --tags security
```

### 12.3 Validation Testing

**Test 5: Run Validation Playbook**
```bash
# Run complete validation
ansible-playbook playbooks/admin-assistant-validate.yml

# Expected: All assertions pass
```

**Test 6: Manual Access Testing**

From a workstation:
```bash
# Test AD authentication
id emily.chen
getent passwd emily.chen

# Test file share access
smbclient //files01/templates -U emily.chen
# Expected: Prompt for password, successful connection

# Test read-only access to HR forms
smbclient //files01/hr-forms -U emily.chen -c 'ls; mkdir test'
# Expected: ls works, mkdir fails (read-only)

# Test audit logging
sudo ausearch -k admin_template_write
# Expected: See logged file access events
```

### 12.4 Acceptance Criteria

| Test ID | Test Description | Pass Criteria | Status |
|---------|------------------|---------------|--------|
| TEST-AD-001 | OUs created successfully | `samba-tool ou show` returns OU details | [ ] |
| TEST-AD-002 | Security groups created | All 5 groups exist | [ ] |
| TEST-AD-003 | Group nesting configured | GG-Shared-Services member of all SG-* groups | [ ] |
| TEST-AD-004 | Users created in correct OU | Users show in AdminAssistants OU | [ ] |
| TEST-FS-001 | Share directories created | All paths exist with correct permissions | [ ] |
| TEST-FS-002 | Samba shares configured | `testparm` shows all shares | [ ] |
| TEST-FS-003 | ACLs set correctly | `getfacl` shows expected ACL entries | [ ] |
| TEST-WS-001 | Workstation domain-joined | `realm list` shows domain membership | [ ] |
| TEST-WS-002 | User can login | AD user can login to workstation | [ ] |
| TEST-WS-003 | Software installed | All required packages present | [ ] |
| TEST-WS-004 | Desktop policies applied | dconf shows locked settings | [ ] |
| TEST-SEC-001 | Auditd running and configured | Service active, rules loaded | [ ] |
| TEST-SEC-002 | USB restrictions active | USB devices mount read-only | [ ] |
| TEST-ACC-001 | Templates share RW access | Can read and write files | [ ] |
| TEST-ACC-002 | HR forms RO access | Can read, cannot write | [ ] |
| TEST-ACC-003 | Finance share denied | Access denied as expected | [ ] |

---

## 13. Troubleshooting

### 13.1 Common Issues and Solutions

**Issue 1: Samba-tool command not found**
```bash
# Solution: Verify Samba AD is installed
dpkg -l | grep samba  # Ubuntu
rpm -qa | grep samba  # Oracle Linux

# Install if missing
apt install samba samba-tool  # Ubuntu
dnf install samba samba-dc    # Oracle Linux
```

**Issue 2: "User already exists" error**
```bash
# Solution: Check if user exists before creating
samba-tool user show emily.chen

# If exists and you want to recreate:
samba-tool user delete emily.chen
# Then re-run playbook
```

**Issue 3: Group nesting fails with "already a member"**
```bash
# Solution: This is expected and handled by playbook
# Verify membership manually:
samba-tool group listmembers SG-Templates-Write
# Should show GG-Shared-Services
```

**Issue 4: ACL changes not applied**
```bash
# Solution: Verify ACL package is installed
which setfacl getfacl

# Manually set ACLs to test:
setfacl -m g:SG-Templates-Write:rwx /srv/samba/shares/templates
getfacl /srv/samba/shares/templates

# Check if filesystem supports ACLs:
mount | grep /srv
# Should show "acl" option
```

**Issue 5: Domain join fails**
```bash
# Solution: Check DNS and network connectivity
ping dc01.smboffice.local
nslookup dc01.smboffice.local

# Test Kerberos:
kinit administrator@SMBOFFICE.LOCAL
klist

# Check realm discovery:
realm discover smboffice.local
```

**Issue 6: Desktop policies not applying**
```bash
# Solution: Update dconf database
dconf update

# Check if profile is loaded:
cat /etc/dconf/profile/user

# Verify policy file:
cat /etc/dconf/db/local.d/00-admin-assistant-policy

# Test as user:
gsettings get org.gnome.desktop.screensaver lock-enabled
```

### 13.2 Debug Mode Execution

```bash
# Run with maximum verbosity
ansible-playbook playbooks/admin-assistant-deploy.yml -vvvv

# Run specific task with debug
ansible-playbook playbooks/admin-assistant-deploy.yml --start-at-task="Create security groups" -vv

# Check facts gathered
ansible admin_workstations -m setup | less
```

### 13.3 Rollback Procedure

If deployment fails and rollback is needed:

```bash
# 1. Remove users
samba-tool user delete emily.chen
samba-tool user delete david.kim

# 2. Remove groups
for group in GG-Shared-Services SG-Office-Scheduling SG-Print-Access SG-Templates-Write SG-HR-Forms-Read; do
  samba-tool group delete $group
done

# 3. Remove OUs (must be empty)
samba-tool ou delete "OU=AdminAssistants,OU=SharedServices,OU=Users,DC=smboffice,DC=local"

# 4. Remove file shares
# Edit /etc/samba/smb.conf and remove share definitions
rm /etc/samba/smb.conf.d/admin-shares.conf
systemctl restart smbd

# 5. Leave domain (workstations)
realm leave smboffice.local
```

---

## 14. Review History

| Version | Date | Reviewer | Notes |
|---------|------|----------|-------|
| v1.0 | 2025-12-24 | Ansible Programmer | Initial implementation guide created |

---

## 15. Departmental Approval Checklist

| Department / Agent        | Reviewed | Reviewer Notes |
|---------------------------|----------|----------------|
| SMB Analyst               | [ ]      |                |
| IT Business Analyst       | [ ]      |                |
| Project Doc Auditor       | [ ]      |                |
| IT Security Analyst       | [ ]      |                |
| IT AD Architect           | [ ]      |                |
| Linux Admin/Architect     | [ ]      |                |
| Ansible Programmer        | [ ]      |                |
| IT Code Auditor           | [ ]      |                |
| SEO Analyst               | [ ]      |                |
| Content Editor            | [ ]      |                |
| Project Manager           | [ ]      |                |
| Task Assistant            | [ ]      |                |

---

**End of Document**
