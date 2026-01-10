# Security Profile Framework: Complete Documentation

## Table of Contents

1. [Introduction](#introduction)
2. [Architecture Overview](#architecture-overview)
3. [Core Concepts](#core-concepts)
4. [Framework Components](#framework-components)
5. [Implementation Workflow](#implementation-workflow)
6. [Example Configurations](#example-configurations)
7. [Ansible Integration](#ansible-integration)
8. [Compliance and Auditing](#compliance-and-auditing)
9. [Troubleshooting Guide](#troubleshooting-guide)
10. [Appendix](#appendix)

---

## Introduction

### What is the Security Profile Framework?

The Security Profile Framework is a **policy-based security architecture** that separates security concerns into three distinct layers:

1. **Business Layer** - Who users are (job roles)
2. **Policy Layer** - What security requirements apply (policies grouped into objects)
3. **Tool Layer** - How policies are enforced (specific security tools)

This separation allows:
- **Business users** to understand security in terms they know (roles and responsibilities)
- **Security teams** to define policies without worrying about implementation details
- **IT staff** to implement tools without repeatedly configuring individual users

### Why This Approach?

**Traditional Problem:**
- Configuring security for one user requires touching 8-12 different systems
- Each system has its own syntax, configuration files, and documentation
- High risk of misconfiguration or missing a step
- Difficult to answer compliance questions ("Who can access Finance data?")
- Policy changes require updating hundreds of configuration files

**Framework Solution:**
- Define a user's role once → All security configurations applied automatically
- Change a policy once → All affected users updated consistently
- Answer compliance questions in seconds → Query the profile definitions
- Onboard users in minutes → Single command applies all security
- Audit compliance continuously → Automated verification

### Key Benefits

| Stakeholder | Benefit |
|------------|---------|
| **Business Leaders** | Understand security in business terms (roles, not tools) |
| **Security Officers** | Enforce policies consistently, prove compliance easily |
| **IT Administrators** | Configure once, apply everywhere; less manual work |
| **Auditors** | Fast answers to compliance questions, automated verification |
| **Users** | Appropriate access for their role, no more "access denied" surprises |

---

## Architecture Overview

### Three-Layer Model

```
┌─────────────────────────────────────────────────────────────┐
│                     BUSINESS LAYER                          │
│                  User Profiles (WHO)                        │
│                                                             │
│  ┌──────────┐  ┌──────────┐  ┌──────────┐  ┌──────────┐  │
│  │ Manager  │  │ Employee │  │Developer │  │IT Admin  │  │
│  │ Profile  │  │ Profile  │  │ Profile  │  │ Profile  │  │
│  └────┬─────┘  └────┬─────┘  └────┬─────┘  └────┬─────┘  │
└───────┼─────────────┼─────────────┼─────────────┼─────────┘
        │             │             │             │
        │ applies     │ applies     │ applies     │ applies
        ▼             ▼             ▼             ▼
┌─────────────────────────────────────────────────────────────┐
│                     POLICY LAYER                            │
│              Security Objects (WHAT)                        │
│                                                             │
│  ┌─────────────────┐  ┌─────────────────┐  ┌────────────┐ │
│  │ User Access     │  │ Data Access     │  │ Network    │ │
│  │ Object          │  │ Object          │  │ Access     │ │
│  ├─────────────────┤  ├─────────────────┤  ├────────────┤ │
│  │• Logon Policy   │  │• Storage Policy │  │• Remote    │ │
│  │• Session Policy │  │• Encryption Pol │  │  Access    │ │
│  │• Audit Policy   │  │• Backup Policy  │  │• Firewall  │ │
│  └────┬────────────┘  └────┬────────────┘  └────┬───────┘ │
└───────┼────────────────────┼────────────────────┼─────────┘
        │ enforced by        │ enforced by        │ enforced by
        ▼                    ▼                    ▼
┌─────────────────────────────────────────────────────────────┐
│                     TOOL LAYER                              │
│           Security Tools (HOW)                              │
│                                                             │
│  Logon:              Storage:           Network:           │
│  • PAM               • SELinux          • pfSense          │
│  • Yubikey           • FIPS 140-2       • firewalld        │
│  • Active Directory  • LUKS encryption  • SSH config       │
│  • fail2ban          • XFS quotas       • WireGuard VPN    │
│                                                             │
│  Audit:              Encryption:        Backup:            │
│  • auditd            • TLS 1.3          • Bacula           │
│  • rsyslog           • SMB3 encryption  • S3 (immutable)   │
│  • Wazuh SIEM        • Kerberos AES-256 • LVM snapshots    │
└─────────────────────────────────────────────────────────────┘
```

### Data Flow

**User Onboarding Example:**

```
1. HR says: "Sarah is a Finance Manager"
   └─> Input: Business role

2. IT applies profile: "manager"
   └─> Lookup: What security objects does this profile need?

3. Profile includes:
   ├─> user_access_privileged
   ├─> data_access_confidential (Finance)
   └─> network_access_standard

4. Each security object contains policies:
   ├─> Logon Policy: 2FA required, 16-char password, 60-day expiration
   ├─> Storage Policy: FIPS encryption, Finance share access
   └─> Firewall Policy: Allow file server, block production servers

5. Ansible configures tools:
   ├─> PAM: Enable pam_yubico for Sarah
   ├─> Active Directory: Add Sarah to Privileged-Users, Finance groups
   ├─> SELinux: Set context user_u:user_r:user_t:s0:c0.c5
   ├─> pfSense: Add firewall rules for laptop-sarah-01
   ├─> auditd: Create /etc/audit/rules.d/sarah.rules
   └─> Bacula: Create backup job Sarah-Finance-7year

6. Verification tests run:
   ├─> ✓ Can Sarah log in with Yubikey?
   ├─> ✓ Can Sarah access Finance share?
   ├─> ✗ Can Sarah access HR share? (should fail)
   └─> ✓ Are Sarah's actions being logged?

7. Report generated:
   └─> Sarah is ready to start work (10 minutes elapsed)
```

---

## Core Concepts

### User Profile

**Definition:** A named collection of security objects that represent a business role.

**Purpose:** Translate job roles (understood by HR/management) into security requirements (understood by IT/security).

**Components:**
- **Profile name**: e.g., `manager`, `employee`, `developer`
- **Description**: Who this profile is for
- **Security objects**: List of security objects to apply
- **Metadata**: Department, sensitivity level, compliance requirements

**Example:**
```yaml
profile_name: manager
description: "Department managers who handle sensitive data"
security_objects:
  - user_access_privileged
  - data_access_confidential
  - network_access_standard
applies_to: [Finance Manager, HR Manager, Sales Manager]
compliance: [SOX, GDPR, HIPAA]
```

---

### Security Object

**Definition:** A reusable collection of related security policies that can be applied to multiple user profiles.

**Purpose:** Group policies that commonly go together, enabling reuse and consistency.

**Types:**
1. **User Access Object** - How users authenticate and what's logged
2. **Data Access Object** - What data users can access and how it's protected
3. **Network Access Object** - What systems users can connect to

**Components:**
- **Object name**: e.g., `user_access_privileged`
- **Type**: `user_access`, `data_access`, or `network_access`
- **Policies**: List of policies this object contains
- **Metadata**: Applies to which profiles, compliance requirements

**Example:**
```yaml
object_name: user_access_privileged
type: user_access
description: "Enhanced authentication and logging for sensitive data handlers"
applies_to: [manager, finance_staff, hr_staff]

policies:
  logon_policy:
    - name: "Multi-Factor Authentication Required"
      requirements:
        - authentication_methods: [password, yubikey]
        - password_length: 16
        - password_expiration_days: 60
        - failed_login_threshold: 3

  session_policy:
    - name: "Enhanced Session Security"
      requirements:
        - idle_timeout_minutes: 15
        - max_concurrent_sessions: 1

  audit_policy:
    - name: "Comprehensive Audit Logging"
      requirements:
        - logging_level: detailed
        - log_retention_years: 7
```

---

### Policy

**Definition:** A specific security requirement within a security object.

**Purpose:** Define WHAT needs to be enforced, without specifying HOW (that's the tool layer's job).

**Common Policy Types:**

| Policy | Purpose | Examples |
|--------|---------|----------|
| **Logon Policy** | Authentication requirements | Password + 2FA, SSH key-only, certificate-based |
| **Session Policy** | Active session controls | Idle timeout, concurrent sessions, screen lock |
| **Audit Policy** | What to log and for how long | Login events, file access, commands, retention period |
| **Storage Policy** | Data at rest protection | Encryption algorithm, access control model, quotas |
| **Encryption Policy** | Data in transit protection | TLS version, SMB3 encryption, Kerberos encryption |
| **Backup Policy** | Data recovery requirements | Frequency, retention, who can restore |
| **Remote Access Policy** | How to connect from outside | VPN required, SSH keys, allowed source IPs |
| **Firewall Policy** | Network segmentation | Allowed destinations, blocked destinations |

---

### Tool Mapping

**Definition:** The configuration that connects a policy requirement to one or more security tools.

**Purpose:** Define HOW policies are enforced by specific tools.

**Components:**
- **Policy**: Which policy this implements
- **Requirement**: Specific requirement from the policy
- **Primary tool**: Main tool that enforces this
- **Configuration**: Specific settings for the tool
- **Supporting tools**: Additional tools that help
- **Verification**: How to test this works

**Example:**
```yaml
policy: logon_policy
requirement: "Multi-Factor Authentication (password + Yubikey)"

tools:
  primary: PAM (Pluggable Authentication Modules)

  configuration:
    - file: /etc/pam.d/common-auth
      settings:
        - "auth required pam_yubico.so id=12345 key=secret"
        - "auth required pam_sss.so"

    - file: /etc/security/access.conf
      settings:
        - "+ : (Privileged-Users) : ALL"
        - "- : ALL : ALL"

  supporting:
    - Active Directory (group membership)
    - pam_sss (AD connector)
    - fail2ban (brute force protection)

  verification:
    - test: "User with Yubikey can log in"
      command: "ssh user@host"
      expected: "Success after password + Yubikey"
```

---

## Framework Components

### Directory Structure

```
security-framework/
├── README.md
├── docs/
│   ├── overview.md                    # This document
│   ├── user-guide.md                  # For end users
│   └── admin-guide.md                 # For IT administrators
│
├── profiles/                          # BUSINESS LAYER
│   ├── manager.yml
│   ├── employee.yml
│   ├── developer.yml
│   ├── it_admin.yml
│   ├── finance_staff.yml
│   ├── hr_staff.yml
│   └── receptionist.yml
│
├── security_objects/                  # POLICY LAYER
│   ├── user_access/
│   │   ├── basic.yml
│   │   ├── standard.yml
│   │   ├── privileged.yml
│   │   ├── developer.yml
│   │   └── admin.yml
│   ├── data_access/
│   │   ├── public.yml
│   │   ├── internal.yml
│   │   ├── confidential.yml
│   │   ├── restricted.yml
│   │   └── test_only.yml
│   └── network_access/
│       ├── workstation_only.yml
│       ├── standard.yml
│       ├── isolated.yml
│       └── admin.yml
│
├── tool_mappings/                     # TOOL LAYER
│   ├── authentication/
│   │   ├── pam_config.yml
│   │   ├── yubikey_setup.yml
│   │   └── ad_integration.yml
│   ├── access_control/
│   │   ├── selinux_policy.yml
│   │   ├── apparmor_profile.yml
│   │   └── posix_acl.yml
│   ├── encryption/
│   │   ├── fips_mode.yml
│   │   ├── luks_encryption.yml
│   │   └── smb3_encryption.yml
│   ├── firewall/
│   │   ├── pfsense_rules.yml
│   │   └── firewalld_zones.yml
│   ├── audit/
│   │   ├── auditd_rules.yml
│   │   ├── rsyslog_forward.yml
│   │   └── wazuh_alerts.yml
│   └── backup/
│       ├── bacula_jobs.yml
│       └── s3_replication.yml
│
├── ansible/                           # AUTOMATION
│   ├── playbooks/
│   │   ├── apply_profile.yml
│   │   ├── remove_profile.yml
│   │   ├── update_profile.yml
│   │   ├── verify_compliance.yml
│   │   └── generate_report.yml
│   ├── roles/
│   │   ├── apply_user_access/
│   │   ├── apply_data_access/
│   │   ├── apply_network_access/
│   │   ├── configure_pam/
│   │   ├── configure_selinux/
│   │   ├── configure_firewall/
│   │   └── configure_audit/
│   ├── inventory/
│   │   ├── production/
│   │   │   ├── hosts.yml
│   │   │   └── group_vars/
│   │   └── test/
│   │       ├── hosts.yml
│   │       └── group_vars/
│   └── templates/
│       ├── pam_common_auth.j2
│       ├── auditd_rules.j2
│       ├── firewall_rules.j2
│       └── compliance_report.j2
│
└── tests/                             # TESTING
    ├── unit/
    │   ├── test_profiles.py
    │   ├── test_security_objects.py
    │   └── test_tool_mappings.py
    ├── integration/
    │   ├── test_apply_profile.py
    │   ├── test_verify_compliance.py
    │   └── test_access_control.py
    └── fixtures/
        ├── test_users.yml
        └── expected_configs/
```

---

## Implementation Workflow

### Phase 1: Discovery and Planning (2-4 weeks)

**Objective:** Understand current state and define desired state.

**Activities:**

1. **User Role Inventory**
   - Interview department heads
   - Review org chart
   - Identify 5-10 distinct roles
   - Document what each role needs

2. **Security Tool Audit**
   - What tools do we have? (PAM, SELinux, firewalls, etc.)
   - What's already configured?
   - What's missing?
   - What needs to change?

3. **Compliance Requirements Review**
   - What regulations apply? (SOX, GDPR, HIPAA, PCI-DSS)
   - What's required for each?
   - Map to policies

4. **Gap Analysis**
   - What security controls are missing?
   - What configurations are inconsistent?
   - What can't be automated (yet)?

**Deliverables:**
- User role inventory document
- Security tool inventory spreadsheet
- Compliance requirements matrix
- Gap analysis report

---

### Phase 2: Framework Design (2-4 weeks)

**Objective:** Create profile definitions, security objects, and tool mappings.

**Activities:**

1. **Define User Profiles**
   ```yaml
   # profiles/manager.yml
   profile_name: manager
   description: "Department managers handling sensitive data"
   security_objects:
     - user_access_privileged
     - data_access_confidential
     - network_access_standard
   metadata:
     applies_to: [Finance Manager, HR Manager, Sales Manager]
     risk_level: high
     compliance: [SOX, GDPR]
   ```

2. **Create Security Objects**
   ```yaml
   # security_objects/user_access/privileged.yml
   object_name: user_access_privileged
   type: user_access
   policies:
     logon_policy:
       - name: "2FA Required"
         requirements:
           authentication_methods: [password, yubikey]
     session_policy:
       - name: "Single Session"
         requirements:
           max_concurrent_sessions: 1
     audit_policy:
       - name: "Detailed Logging"
         requirements:
           logging_level: detailed
           retention_years: 7
   ```

3. **Document Tool Mappings**
   ```yaml
   # tool_mappings/authentication/pam_config.yml
   policy: logon_policy
   requirement: "2FA Required"
   tools:
     primary: PAM
     configuration:
       - file: /etc/pam.d/common-auth
         settings:
           - "auth required pam_yubico.so"
           - "auth required pam_sss.so"
   ```

**Deliverables:**
- 5-10 user profile YAML files
- 8-15 security object YAML files
- 15-25 tool mapping YAML files

---

### Phase 3: Automation Development (4-8 weeks)

**Objective:** Build Ansible playbooks to apply profiles automatically.

**Activities:**

1. **Create Ansible Directory Structure**
   ```bash
   mkdir -p ansible/{playbooks,roles,inventory,templates}
   ```

2. **Write Core Playbooks**
   - `apply_profile.yml` - Apply profile to user
   - `remove_profile.yml` - Remove profile from user
   - `verify_compliance.yml` - Check configuration matches profile
   - `generate_report.yml` - Create compliance report

3. **Create Ansible Roles**
   - `apply_user_access` - Configure PAM, AD, audit
   - `apply_data_access` - Configure SELinux, encryption, backups
   - `apply_network_access` - Configure firewalls, VPN, SSH

4. **Write Templates**
   - `pam_common_auth.j2` - PAM configuration
   - `auditd_rules.j2` - Audit rules
   - `firewall_rules.j2` - Firewall rules
   - `compliance_report.j2` - Compliance report

5. **Build Testing Framework**
   - Unit tests for profile definitions
   - Integration tests for full profile application
   - Compliance verification tests

**Deliverables:**
- Working Ansible playbooks
- Ansible roles for each security object type
- Jinja2 templates for all configurations
- Test suite with 80%+ coverage

---

### Phase 4: Testing and Validation (2-4 weeks)

**Objective:** Verify framework works correctly in test environment.

**Activities:**

1. **Unit Testing**
   ```bash
   # Test profile definitions are valid YAML
   yamllint profiles/*.yml

   # Test security objects have required fields
   python tests/unit/test_security_objects.py
   ```

2. **Integration Testing**
   ```bash
   # Create test user with manager profile
   ansible-playbook playbooks/apply_profile.yml \
     --extra-vars "user=test-manager@TEST.LOCAL profile=manager" \
     --limit test-environment

   # Run verification
   ansible-playbook playbooks/verify_compliance.yml \
     --extra-vars "user=test-manager@TEST.LOCAL" \
     --limit test-environment
   ```

3. **Security Validation**
   - Can test user access what they should?
   - Can test user NOT access what they shouldn't?
   - Are all actions logged correctly?
   - Do alerts fire for violations?

4. **Performance Testing**
   - How long to apply a profile?
   - How long to verify compliance?
   - Can we handle 100+ users?

**Deliverables:**
- Test reports showing all profiles work
- Performance benchmarks
- Security validation results
- Bug fixes for any issues found

---

### Phase 5: Pilot Rollout (2-4 weeks)

**Objective:** Deploy to small group of real users, gather feedback.

**Activities:**

1. **Select Pilot Group** (10-20 users)
   - Mix of roles (managers, employees, IT staff)
   - IT-savvy users who can provide feedback
   - Non-critical systems (if something breaks, limited impact)

2. **Communication Plan**
   - Email pilot users: What's happening, when, what to expect
   - Set up feedback channel (Slack, email, Teams)
   - Document known limitations

3. **Apply Profiles to Pilot Users**
   ```bash
   # Week 1: IT staff (5 users)
   ansible-playbook playbooks/apply_profile.yml \
     --extra-vars "@pilot_users_it_staff.yml"

   # Week 2: One department (10 users)
   ansible-playbook playbooks/apply_profile.yml \
     --extra-vars "@pilot_users_finance.yml"
   ```

4. **Monitor and Support**
   - Daily check-ins with pilot users
   - Quick fixes for issues
   - Document feedback

5. **Adjust Framework**
   - Update profiles based on feedback
   - Fix bugs discovered
   - Add missing features

**Deliverables:**
- Pilot user list
- Communication materials
- Feedback summary
- Updated framework (bug fixes, improvements)

---

### Phase 6: Production Rollout (4-12 weeks)

**Objective:** Deploy to all users in phased approach.

**Activities:**

1. **Rollout Plan**
   ```
   Week 1-2:  IT staff (already done in pilot)
   Week 3-4:  Managers (all departments)
   Week 5-6:  Finance department
   Week 7-8:  HR department
   Week 9-10: Sales/Operations departments
   Week 11-12: Remaining users + contractors
   ```

2. **Communication**
   - Department-specific emails
   - Training sessions
   - FAQ document
   - Help desk preparation

3. **Phased Deployment**
   ```bash
   # Managers
   ansible-playbook playbooks/apply_profile.yml \
     --limit manager-group

   # Finance
   ansible-playbook playbooks/apply_profile.yml \
     --limit finance-group

   # Continue for each department...
   ```

4. **Monitoring**
   - Daily compliance checks
   - Alert monitoring (Wazuh SIEM)
   - User support tickets
   - Performance metrics

5. **Documentation Updates**
   - User guides (per profile)
   - Admin troubleshooting guide
   - Runbooks for common issues

**Deliverables:**
- All users transitioned to framework
- Updated documentation
- Help desk training materials
- Monitoring dashboards

---

### Phase 7: Continuous Improvement (Ongoing)

**Objective:** Keep framework current and improve over time.

**Activities:**

1. **Daily Automated Checks**
   ```bash
   # Cron job: /etc/cron.daily/verify-security-profiles
   #!/bin/bash
   ansible-playbook playbooks/verify_compliance.yml --all

   # Email report to security team
   mail -s "Daily Compliance Report" security@company.com < /tmp/compliance-report.txt
   ```

2. **Quarterly Reviews**
   - Are profiles still accurate?
   - New roles needed?
   - Policy changes required?
   - Tool updates needed?

3. **Policy Updates**
   ```bash
   # Example: New requirement - All Finance access needs 2FA

   # 1. Update security object
   vim security_objects/data_access/confidential.yml
   # Add: required_user_access: user_access_privileged

   # 2. Apply update to all affected users
   ansible-playbook playbooks/update_security_objects.yml \
     --tags data_access_confidential

   # 3. Verify compliance
   ansible-playbook playbooks/verify_compliance.yml \
     --tags finance-2fa
   ```

4. **Incident Response Integration**
   - Security incident → Check user's profile
   - Policy violation → Investigate why
   - Update profile/policy if needed

5. **Compliance Reporting**
   - Automated monthly reports
   - Audit trail for all changes
   - Evidence for auditors

**Deliverables:**
- Daily compliance reports
- Quarterly review documents
- Updated policies (as needed)
- Compliance evidence for audits

---

## Example Configurations

### Example 1: Manager Profile

**File:** `profiles/manager.yml`

```yaml
---
profile_name: manager
version: 1.0
description: Department managers who handle sensitive data

# BUSINESS INFORMATION
metadata:
  applies_to:
    - Finance Manager
    - HR Manager
    - Sales Manager
    - Operations Manager
  risk_level: high
  data_sensitivity: confidential_to_restricted
  compliance_requirements:
    - SOX (if Finance)
    - HIPAA (if HR)
    - GDPR

# SECURITY OBJECTS (WHAT)
security_objects:
  - user_access_privileged      # 2FA, detailed logging, single session
  - data_access_confidential    # Department data, FIPS encryption, 7-year backups
  - network_access_standard     # VPN, file/email servers, no direct prod access

# EXCEPTIONS (if any)
exceptions: []

# ACCESS DETAILS
access:
  files:
    - path: /srv/shares/departments/${department}
      permission: read_write
      acl: ${department} group membership required
    - path: /srv/shares/company-wide
      permission: read_only
      acl: All employees

  applications:
    - email
    - office_suite
    - department_specific_apps

  servers:
    - file-server01 (SMB)
    - print-server01
    - mail-server01

  locations:
    - office_vlan
    - vpn (with same security)

# USAGE NOTES
notes: |
  Managers require enhanced security due to access to sensitive department data.
  All actions are logged for 7 years (compliance requirement).
  Single concurrent session enforced (no account sharing).
  VPN access allowed for remote work (same security as office).
```

---

### Example 2: User Access Privileged Object

**File:** `security_objects/user_access/privileged.yml`

```yaml
---
object_name: user_access_privileged
version: 1.0
type: user_access
description: Enhanced authentication and logging for users handling sensitive data

# WHO USES THIS
applies_to_profiles:
  - manager
  - finance_staff
  - hr_staff

# POLICIES (WHAT)
policies:
  logon_policy:
    - name: Multi-Factor Authentication Required
      description: Password + physical security key (Yubikey)
      requirements:
        authentication_methods:
          - password
          - yubikey
        password_requirements:
          length_min: 16
          complexity: true
          history: 12  # Can't reuse last 12 passwords
          expiration_days: 60
        failed_login_handling:
          threshold: 3  # Lock after 3 failures
          lockout_duration_minutes: 60
          alert_security_team: true
        allowed_locations:
          - office_vlan
          - vpn
        disallowed_locations:
          - internet (without VPN)
          - untrusted_networks

  session_policy:
    - name: Enhanced Session Security
      description: Stricter session controls for sensitive data handlers
      requirements:
        idle_timeout_minutes: 15
        max_concurrent_sessions: 1  # Single device only
        screen_lock_timeout_minutes: 5
        screen_lock_required: true
        session_recording: false  # Privacy for managers (but all actions logged)
        force_logout_on_lock: false  # Just lock, don't logout

  audit_policy:
    - name: Comprehensive Audit Logging
      description: Log all actions for compliance and incident investigation
      requirements:
        logging_level: detailed
        log_retention_years: 7  # SOX compliance
        log_events:
          - login_success
          - login_failure
          - logout
          - session_timeout
          - file_open
          - file_modify
          - file_delete
          - command_execution
          - network_connection
          - privilege_escalation
          - policy_violation
        alert_triggers:
          - login_failure_threshold: 3
          - after_hours_access: true
          - weekend_access: true
          - large_file_download_mb: 100
          - restricted_file_access: true
          - multiple_failed_2fa: true
        log_destinations:
          - local: /var/log/audit/audit.log (immutable)
          - remote: monitoring01.office.local:514 (TLS encrypted)
          - siem: wazuh (real-time analysis)

# COMPLIANCE MAPPING
compliance:
  SOX:
    - "§404: Audit trail of all access to financial data"
    - "§802: 7-year retention of audit logs"
  GDPR:
    - "Article 32: Security of processing (2FA, logging)"
    - "Article 30: Records of processing activities"
  HIPAA:
    - "§164.312(b): Audit controls"
    - "§164.308(a)(5)(ii)(C): Log-in monitoring"
  PCI-DSS:
    - "10.2: Audit trail for all access to cardholder data"
    - "10.3: Audit trail entries must include user identification"

# TESTING
verification_tests:
  - test: User with correct password and Yubikey can log in
    expected: success
  - test: User with correct password but no Yubikey cannot log in
    expected: failure
  - test: User with wrong password is locked after 3 attempts
    expected: account_locked
  - test: User's file access is logged to monitoring01
    expected: log_entry_exists
  - test: User can only have 1 active session
    expected: second_login_blocks_first
```

---

### Example 3: Tool Mapping for 2FA

**File:** `tool_mappings/authentication/yubikey_2fa.yml`

```yaml
---
policy: logon_policy
requirement: Multi-Factor Authentication (password + Yubikey)
version: 1.0

# PRIMARY TOOL
tools:
  primary:
    name: PAM (Pluggable Authentication Modules)
    version: "1.5.x"
    description: Linux authentication framework

  # CONFIGURATION
  configuration:
    - name: Enable pam_yubico module
      file: /etc/pam.d/common-auth
      content: |
        # Yubikey 2FA (must be present and touched)
        auth required pam_yubico.so id={{ yubico_client_id }} key={{ yubico_secret_key }} \
          urllist=https://api.yubico.com/wsapi/2.0/verify \
          mode=client debug

        # Active Directory authentication (password)
        auth required pam_sss.so use_first_pass

        # Account lockout after failed attempts
        auth required pam_faillock.so preauth silent audit deny=3 unlock_time=3600

        # Log authentication attempts
        auth optional pam_echo.so file=/var/log/auth-attempts.log

    - name: Require Privileged-Users AD group
      file: /etc/security/access.conf
      content: |
        # Only Privileged-Users group can log in
        + : (Privileged-Users) : ALL
        - : ALL : ALL

    - name: Register Yubikey for user
      command: |
        # Run on user onboarding
        ykman list  # Verify Yubikey detected
        ykman info  # Get serial number

        # Store in AD (custom attribute)
        samba-tool user edit {{ user }} \
          --attribute yubikey_serial_number \
          --value {{ yubikey_serial }}

  # SUPPORTING TOOLS
  supporting:
    - name: Active Directory
      purpose: Group membership (Privileged-Users)
      configuration:
        - Create group: Privileged-Users
        - Add custom attribute: yubikey_serial_number

    - name: pam_sss (SSSD)
      purpose: Connect PAM to Active Directory
      configuration:
        - file: /etc/sssd/sssd.conf
          content: |
            [sssd]
            domains = OFFICE.LOCAL
            services = nss, pam

            [domain/OFFICE.LOCAL]
            ad_domain = office.local
            krb5_realm = OFFICE.LOCAL
            cache_credentials = true
            id_provider = ad
            access_provider = ad

    - name: fail2ban
      purpose: Block brute force attacks
      configuration:
        - file: /etc/fail2ban/jail.local
          content: |
            [sshd]
            enabled = true
            port = ssh
            filter = sshd
            logpath = /var/log/auth.log
            maxretry = 3
            bantime = 3600
            findtime = 600

  # VERIFICATION
  verification:
    - test: User with Yubikey can log in
      command: |
        # Test as the user
        ssh {{ user }}@{{ host }}
        # Expected: Prompt for password, then prompt to touch Yubikey
      expected_output: |
        Password: [user types password]
        Touch your Yubikey...
        [user touches Yubikey]
        Welcome to {{ host }}
      exit_code: 0

    - test: User without Yubikey cannot log in
      command: |
        # Test with password only (no Yubikey)
        sshpass -p '{{ password }}' ssh {{ user }}@{{ host }}
      expected_output: |
        Authentication failed: Yubikey required
      exit_code: 255

    - test: User not in Privileged-Users group cannot log in
      command: |
        # Test with user not in required AD group
        ssh unauthorized_user@{{ host }}
      expected_output: |
        Access denied
      exit_code: 255

    - test: Failed login is logged
      command: |
        # Check audit log for failed attempt
        ausearch -m USER_AUTH -sv no | grep {{ user }}
      expected_output: |
        type=USER_AUTH ... res=failed
      exit_code: 0

# ROLLBACK
rollback:
  description: Remove 2FA requirement (emergency access)
  steps:
    - name: Disable pam_yubico temporarily
      command: |
        # Comment out pam_yubico line
        sed -i 's/^auth required pam_yubico.so/#&/' /etc/pam.d/common-auth

        # User can now log in with password only

    - name: Alert security team
      command: |
        mail -s "ALERT: 2FA disabled for emergency access" security@company.com <<EOF
        2FA has been disabled on {{ host }} for emergency access.
        User: {{ user }}
        Time: $(date)
        Duration: Temporary (must re-enable within 24 hours)
        Approval: Required from IT Director
        EOF

# TROUBLESHOOTING
troubleshooting:
  - issue: User's Yubikey not recognized
    symptoms:
      - Error message: "Yubikey not detected"
    diagnosis:
      - Check USB connection
      - Verify ykman can see device: `ykman list`
      - Check permissions: User in `plugdev` group?
    resolution:
      - Add user to group: `usermod -aG plugdev {{ user }}`
      - Re-plug Yubikey
      - Test again

  - issue: Authentication succeeds but session fails
    symptoms:
      - Login accepted but immediately disconnects
    diagnosis:
      - Check PAM session modules
      - Verify home directory exists
      - Check disk quota
    resolution:
      - Create home directory: `mkhomedir_helper {{ user }}`
      - Check quota: `quota -u {{ user }}`

  - issue: Yubikey OTP not validating
    symptoms:
      - Error: "Invalid Yubikey OTP"
    diagnosis:
      - Check Yubico API connectivity
      - Verify client ID and secret key
      - Check firewall rules (allow HTTPS to api.yubico.com)
    resolution:
      - Test API: `curl https://api.yubico.com/wsapi/2.0/verify`
      - Verify credentials: Check /etc/pam.d/common-auth
      - Add firewall rule if needed

# DEPENDENCIES
dependencies:
  packages:
    - libpam-yubico
    - yubikey-manager
    - sssd
    - fail2ban
  services:
    - sssd (must be running for AD integration)
    - fail2ban (optional but recommended)
  external:
    - Yubico OTP API (api.yubico.com)
    - Active Directory (domain controllers)

# COST
cost:
  hardware:
    - Yubikey 5 Series: $50 per user
    - Backup Yubikey (recommended): $50 per user
  software:
    - pam_yubico: Free (open source)
    - Yubico OTP API: Free for <10,000 validations/month
  time:
    - Initial setup: 2-4 hours
    - Per-user onboarding: 15 minutes (including Yubikey registration)
    - Annual maintenance: 2-4 hours (renew API keys, update configs)
```

---

## Ansible Integration

### Main Playbook: Apply Profile

**File:** `ansible/playbooks/apply_profile.yml`

```yaml
---
- name: Apply Security Profile to User
  hosts: all
  gather_facts: yes
  become: yes

  vars:
    # Required variables (passed via --extra-vars)
    user_email: "{{ user }}"           # e.g., sarah@OFFICE.LOCAL
    user_profile: "{{ profile }}"      # e.g., manager
    user_department: "{{ department }}" # e.g., finance

    # Internal variables
    profile_dir: "{{ playbook_dir }}/../../profiles"
    security_objects_dir: "{{ playbook_dir }}/../../security_objects"
    tool_mappings_dir: "{{ playbook_dir }}/../../tool_mappings"
    report_dir: "/var/log/security_profiles"

  pre_tasks:
    - name: Validate required variables
      assert:
        that:
          - user_email is defined
          - user_profile is defined
          - user_department is defined
        fail_msg: "Missing required variables: user, profile, department"

    - name: Create report directory
      file:
        path: "{{ report_dir }}"
        state: directory
        mode: '0755'

    - name: Load profile definition
      include_vars:
        file: "{{ profile_dir }}/{{ user_profile }}.yml"
        name: profile_def

    - name: Display profile information
      debug:
        msg: |
          Applying security profile:
            User: {{ user_email }}
            Profile: {{ user_profile }}
            Department: {{ user_department }}
            Security Objects: {{ profile_def.security_objects | join(', ') }}

  tasks:
    - name: Apply each security object
      include_role:
        name: apply_security_object
      vars:
        security_object: "{{ item }}"
      loop: "{{ profile_def.security_objects }}"
      loop_control:
        label: "{{ item }}"

    - name: Run verification tests
      include_tasks: verify_profile.yml

  post_tasks:
    - name: Generate compliance report
      template:
        src: "{{ playbook_dir }}/../templates/compliance_report.j2"
        dest: "{{ report_dir }}/{{ user_email | regex_replace('@.*', '') }}_{{ user_profile }}_{{ ansible_date_time.iso8601 }}.txt"
        mode: '0644'

    - name: Display report location
      debug:
        msg: "Compliance report: {{ report_dir }}/{{ user_email | regex_replace('@.*', '') }}_{{ user_profile }}_{{ ansible_date_time.iso8601 }}.txt"

    - name: Send notification
      mail:
        to: it-security@company.com
        subject: "Security Profile Applied: {{ user_email }}"
        body: |
          User: {{ user_email }}
          Profile: {{ user_profile }}
          Applied by: {{ ansible_user_id }}
          Timestamp: {{ ansible_date_time.iso8601 }}

          Security Objects Applied:
          {{ profile_def.security_objects | join('\n') }}

          All verification tests passed.

          Report: {{ report_dir }}/{{ user_email | regex_replace('@.*', '') }}_{{ user_profile }}_{{ ansible_date_time.iso8601 }}.txt
      delegate_to: localhost
```

---

### Role: Apply Security Object

**File:** `ansible/roles/apply_security_object/tasks/main.yml`

```yaml
---
- name: Load security object definition
  include_vars:
    file: "{{ security_objects_dir }}/{{ security_object }}.yml"
    name: sec_obj

- name: Display security object info
  debug:
    msg: "Applying security object: {{ sec_obj.object_name }} ({{ sec_obj.type }})"

- name: Apply user access security object
  include_tasks: apply_user_access.yml
  when: sec_obj.type == "user_access"

- name: Apply data access security object
  include_tasks: apply_data_access.yml
  when: sec_obj.type == "data_access"

- name: Apply network access security object
  include_tasks: apply_network_access.yml
  when: sec_obj.type == "network_access"
```

**File:** `ansible/roles/apply_security_object/tasks/apply_user_access.yml`

```yaml
---
- name: Load tool mapping for logon policy
  include_vars:
    file: "{{ tool_mappings_dir }}/authentication/yubikey_2fa.yml"
    name: tool_map
  when: "'yubikey' in (sec_obj.policies.logon_policy[0].requirements.authentication_methods | default([]))"

- name: Configure PAM for 2FA
  template:
    src: pam_common_auth.j2
    dest: /etc/pam.d/common-auth
    owner: root
    group: root
    mode: '0644'
    backup: yes
  when: tool_map is defined
  notify: restart sssd

- name: Add user to Privileged-Users AD group
  command: >
    samba-tool group addmembers "Privileged-Users" "{{ user_email }}"
  delegate_to: "{{ groups['domain_controllers'][0] }}"
  when: "'privileged' in sec_obj.object_name"
  register: ad_group_add
  failed_when: ad_group_add.rc != 0 and 'already a member' not in ad_group_add.stderr

- name: Register Yubikey serial number in AD
  command: >
    samba-tool user edit "{{ user_email }}"
      --attribute yubikey_serial_number
      --value "{{ yubikey_serial }}"
  delegate_to: "{{ groups['domain_controllers'][0] }}"
  when: yubikey_serial is defined

- name: Configure auditd rules for user
  template:
    src: auditd_user_rules.j2
    dest: "/etc/audit/rules.d/{{ user_email | regex_replace('@.*', '') }}.rules"
    owner: root
    group: root
    mode: '0640'
  notify: restart auditd

- name: Create user-specific log directory
  file:
    path: "/var/log/users/{{ user_email | regex_replace('@.*', '') }}"
    state: directory
    owner: root
    group: adm
    mode: '0750'

- name: Configure rsyslog for user logs
  template:
    src: rsyslog_user.conf.j2
    dest: "/etc/rsyslog.d/{{ user_email | regex_replace('@.*', '') }}.conf"
    owner: root
    group: root
    mode: '0644'
  notify: restart rsyslog
```

---

### Compliance Verification Playbook

**File:** `ansible/playbooks/verify_compliance.yml`

```yaml
---
- name: Verify Security Profile Compliance
  hosts: all
  gather_facts: yes
  become: yes

  vars:
    user_email: "{{ user }}"
    user_profile: "{{ profile }}"
    profile_dir: "{{ playbook_dir }}/../../profiles"
    report_dir: "/var/log/security_profiles/compliance"

  tasks:
    - name: Load profile definition
      include_vars:
        file: "{{ profile_dir }}/{{ user_profile }}.yml"
        name: profile_def

    - name: Initialize test results
      set_fact:
        test_results: []

    # AUTHENTICATION TESTS
    - name: Test block - Authentication
      block:
        - name: Check PAM configuration
          command: grep -q "pam_yubico.so" /etc/pam.d/common-auth
          register: pam_2fa_check
          failed_when: false
          changed_when: false

        - name: Record PAM 2FA test result
          set_fact:
            test_results: "{{ test_results + [{'test': 'PAM 2FA configured', 'result': pam_2fa_check.rc == 0}] }}"

        - name: Check AD group membership
          command: >
            samba-tool group listmembers "Privileged-Users"
          delegate_to: "{{ groups['domain_controllers'][0] }}"
          register: ad_members
          changed_when: false

        - name: Record AD group membership test result
          set_fact:
            test_results: "{{ test_results + [{'test': 'User in Privileged-Users group', 'result': user_email in ad_members.stdout}] }}"

    # FILE ACCESS TESTS
    - name: Test block - File Access
      block:
        - name: Check file server ACL
          command: >
            getfacl /srv/shares/departments/{{ user_department }}
          register: file_acl
          changed_when: false
          when: "'file-server' in inventory_hostname"

        - name: Record file ACL test result
          set_fact:
            test_results: "{{ test_results + [{'test': 'Department share ACL configured', 'result': user_department in file_acl.stdout}] }}"
          when: file_acl is defined

    # AUDIT TESTS
    - name: Test block - Audit Logging
      block:
        - name: Check auditd rules exist
          stat:
            path: "/etc/audit/rules.d/{{ user_email | regex_replace('@.*', '') }}.rules"
          register: audit_rules_file

        - name: Record audit rules test result
          set_fact:
            test_results: "{{ test_results + [{'test': 'Auditd rules configured', 'result': audit_rules_file.stat.exists}] }}"

        - name: Check rsyslog forwarding
          command: >
            grep -q "monitoring01" /etc/rsyslog.d/{{ user_email | regex_replace('@.*', '') }}.conf
          register: rsyslog_forward
          failed_when: false
          changed_when: false

        - name: Record rsyslog forwarding test result
          set_fact:
            test_results: "{{ test_results + [{'test': 'Rsyslog forwarding configured', 'result': rsyslog_forward.rc == 0}] }}"

    # FIREWALL TESTS
    - name: Test block - Firewall Rules
      block:
        - name: Check pfSense rules (API call)
          uri:
            url: "https://pfsense.office.local/api/v1/firewall/rule?source={{ hostvars[inventory_hostname]['ansible_default_ipv4']['address'] }}"
            method: GET
            headers:
              Authorization: "Bearer {{ pfsense_api_token }}"
            validate_certs: no
          register: firewall_rules
          delegate_to: localhost
          when: inventory_hostname not in groups['firewalls']

        - name: Record firewall rules test result
          set_fact:
            test_results: "{{ test_results + [{'test': 'Firewall rules configured', 'result': firewall_rules.json | length > 0}] }}"
          when: firewall_rules is defined

    # GENERATE REPORT
    - name: Create compliance report directory
      file:
        path: "{{ report_dir }}"
        state: directory
        mode: '0755'
      delegate_to: localhost
      run_once: true

    - name: Generate compliance report
      template:
        src: "{{ playbook_dir }}/../templates/compliance_verification.j2"
        dest: "{{ report_dir }}/{{ user_email | regex_replace('@.*', '') }}_{{ ansible_date_time.date }}.txt"
        mode: '0644'
      delegate_to: localhost

    - name: Display test results
      debug:
        msg: |
          Compliance Verification for {{ user_email }}
          Profile: {{ user_profile }}

          Test Results:
          {% for result in test_results %}
            {{ '✓' if result.result else '✗' }} {{ result.test }}
          {% endfor %}

          Overall: {{ 'PASS' if test_results | selectattr('result', 'equalto', true) | list | length == test_results | length else 'FAIL' }}

    - name: Fail if any tests failed
      assert:
        that:
          - test_results | selectattr('result', 'equalto', true) | list | length == test_results | length
        fail_msg: "Compliance verification failed. See report for details."
```

---

## Compliance and Auditing

### Compliance Matrix

| Regulation | Requirements | Framework Implementation | Verification |
|-----------|--------------|--------------------------|--------------|
| **SOX** | Audit trail of financial data access | Auditd logs all file access, 7-year retention | Daily compliance check |
| **SOX** | Segregation of duties | Profiles enforce role-based access | Profile definitions |
| **SOX** | Change control | All profile changes in Git, peer reviewed | Git commit history |
| **GDPR** | Data protection by design | Encryption policies in all profiles | Encryption verification |
| **GDPR** | Right to erasure | Script to purge user data from all systems | Test quarterly |
| **GDPR** | Data breach notification | Wazuh SIEM alerts within 15 minutes | Alert testing |
| **HIPAA** | Access controls | Profile-based access to PHI | Access testing |
| **HIPAA** | Audit controls | Comprehensive logging in audit_policy | Log verification |
| **HIPAA** | Integrity controls | FIPS encryption, checksums | Integrity checks |
| **PCI-DSS** | User identification | All actions tied to user_email | Audit log review |
| **PCI-DSS** | Access control | Network segmentation via firewall_policy | Firewall testing |
| **PCI-DSS** | Monitoring | Real-time SIEM analysis | Alert verification |

### Audit Reports

#### Daily Compliance Report

```bash
#!/bin/bash
# /etc/cron.daily/security-profile-compliance

REPORT_DATE=$(date +%Y-%m-%d)
REPORT_FILE="/var/log/security_profiles/compliance/daily_${REPORT_DATE}.txt"

echo "Daily Security Profile Compliance Report" > "$REPORT_FILE"
echo "Date: $REPORT_DATE" >> "$REPORT_FILE"
echo "========================================" >> "$REPORT_FILE"
echo "" >> "$REPORT_FILE"

# Run compliance verification for all users
ansible-playbook /opt/ansible/playbooks/verify_compliance.yml --all \
  >> "$REPORT_FILE" 2>&1

# Check for failures
if grep -q "FAIL" "$REPORT_FILE"; then
  SUBJECT="ALERT: Daily compliance check FAILED"
  PRIORITY="High"
else
  SUBJECT="Daily compliance check passed"
  PRIORITY="Normal"
fi

# Email report
mail -s "$SUBJECT" \
  -a "Priority: $PRIORITY" \
  security@company.com < "$REPORT_FILE"

# Rotate old reports (keep 90 days)
find /var/log/security_profiles/compliance/ -name "daily_*.txt" -mtime +90 -delete
```

#### Quarterly Audit Package

```bash
#!/bin/bash
# Generate quarterly audit package for compliance team

QUARTER="Q$(( ($(date +%-m)-1)/3+1 ))"
YEAR=$(date +%Y)
PACKAGE_DIR="/var/log/security_profiles/audit_packages/${YEAR}_${QUARTER}"

mkdir -p "$PACKAGE_DIR"

# 1. Profile Definitions (WHO)
echo "Collecting profile definitions..."
cp -r /opt/security-framework/profiles "$PACKAGE_DIR/"

# 2. Security Objects (WHAT)
echo "Collecting security objects..."
cp -r /opt/security-framework/security_objects "$PACKAGE_DIR/"

# 3. User-to-Profile Mapping
echo "Generating user-to-profile mapping..."
ansible-inventory --list --yaml > "$PACKAGE_DIR/user_profile_mapping.yml"

# 4. Compliance Verification Results
echo "Collecting compliance verification results..."
mkdir -p "$PACKAGE_DIR/compliance_results"
find /var/log/security_profiles/compliance/ -name "*.txt" -mtime -90 \
  -exec cp {} "$PACKAGE_DIR/compliance_results/" \;

# 5. Audit Logs Summary
echo "Generating audit logs summary..."
ansible-playbook /opt/ansible/playbooks/generate_audit_summary.yml \
  --extra-vars "start_date=${YEAR}-$(printf "%02d" $(( (QUARTER-1)*3+1 )))-01 end_date=$(date +%Y-%m-%d)" \
  --output "$PACKAGE_DIR/audit_summary.txt"

# 6. Access Control Matrix
echo "Generating access control matrix..."
cat > "$PACKAGE_DIR/access_control_matrix.txt" <<EOF
Access Control Matrix - ${YEAR} ${QUARTER}
=========================================

Profile | User Count | Finance Data | HR Data | Prod Servers | 2FA Required
--------|-----------|--------------|---------|--------------|-------------
EOF

for profile in /opt/security-framework/profiles/*.yml; do
  profile_name=$(basename "$profile" .yml)
  user_count=$(ansible-inventory --graph --vars | grep -c "$profile_name")

  # Check access permissions (simplified - actual implementation more complex)
  finance_access=$(grep -q "finance" "$profile" && echo "Yes" || echo "No")
  hr_access=$(grep -q "hr" "$profile" && echo "Yes" || echo "No")
  prod_access=$(grep -q "production" "$profile" && echo "Yes" || echo "No")
  twofa=$(grep -q "yubikey" "$profile" && echo "Yes" || echo "No")

  printf "%-8s | %10s | %12s | %8s | %13s | %12s\n" \
    "$profile_name" "$user_count" "$finance_access" "$hr_access" "$prod_access" "$twofa" \
    >> "$PACKAGE_DIR/access_control_matrix.txt"
done

# 7. Policy Changes Log
echo "Collecting policy changes log..."
cd /opt/security-framework
git log --since="3 months ago" --pretty=format:"%h - %an, %ar : %s" \
  > "$PACKAGE_DIR/policy_changes.log"

# 8. Security Incidents
echo "Collecting security incidents..."
grep -r "ALERT\|CRITICAL\|security_violation" /var/log/wazuh/ \
  > "$PACKAGE_DIR/security_incidents.log"

# 9. Create archive
echo "Creating archive..."
tar -czf "${PACKAGE_DIR}.tar.gz" -C "$(dirname "$PACKAGE_DIR")" "$(basename "$PACKAGE_DIR")"

# 10. Encrypt for auditors
echo "Encrypting archive..."
gpg --encrypt --recipient auditors@company.com "${PACKAGE_DIR}.tar.gz"

echo "Quarterly audit package ready: ${PACKAGE_DIR}.tar.gz.gpg"
echo "Send to: auditors@company.com"
```

---

## Troubleshooting Guide

### Common Issues and Resolutions

#### Issue 1: User Cannot Log In After Profile Applied

**Symptoms:**
- User gets "Permission denied" when trying to SSH
- Or "Authentication failed" message

**Diagnosis:**
```bash
# Check PAM configuration
grep "pam_yubico" /etc/pam.d/common-auth

# Check AD group membership
samba-tool group listmembers "Privileged-Users" | grep user@OFFICE.LOCAL

# Check audit logs
ausearch -m USER_AUTH -sv no | grep user@OFFICE.LOCAL | tail -20

# Check SELinux denials
ausearch -m AVC | grep ssh | tail -20
```

**Common Causes:**
1. **Yubikey not registered**: User's Yubikey serial number not in AD
2. **Wrong AD group**: User not added to required AD group
3. **PAM misconfiguration**: Typo in /etc/pam.d/common-auth
4. **SELinux denial**: SSH being blocked by SELinux policy

**Resolution:**
```bash
# Register Yubikey
ykman list  # Get serial number
samba-tool user edit user@OFFICE.LOCAL \
  --attribute yubikey_serial_number --value 12345678

# Add to AD group
samba-tool group addmembers "Privileged-Users" "user@OFFICE.LOCAL"

# Fix PAM config (re-apply profile)
ansible-playbook playbooks/apply_profile.yml \
  --extra-vars "user=user@OFFICE.LOCAL profile=manager department=finance"

# Allow SELinux (if needed)
ausearch -m AVC | grep ssh | audit2allow -M ssh_custom
semodule -i ssh_custom.pp
```

---

#### Issue 2: User Can Access Files They Shouldn't

**Symptoms:**
- User successfully accesses restricted department share
- No "Permission denied" error when expected

**Diagnosis:**
```bash
# Check user's profile
ansible-inventory --host user@OFFICE.LOCAL

# Check file ACL
getfacl /srv/shares/departments/finance/

# Check SELinux context
ls -Z /srv/shares/departments/finance/

# Check Samba share configuration
smbclient //file-server01/finance -U user@OFFICE.LOCAL -c 'ls'

# Check audit logs for access
ausearch -f /srv/shares/departments/finance/ | grep user@OFFICE.LOCAL
```

**Common Causes:**
1. **Wrong profile applied**: User has elevated profile when they shouldn't
2. **ACL misconfigured**: File ACL too permissive
3. **SELinux context wrong**: File has incorrect SELinux label
4. **Group membership**: User in wrong AD group

**Resolution:**
```bash
# Verify correct profile
cat /opt/security-framework/profiles/employee.yml
# User should have "employee" profile, not "manager"

# Re-apply correct profile
ansible-playbook playbooks/remove_profile.yml \
  --extra-vars "user=user@OFFICE.LOCAL"

ansible-playbook playbooks/apply_profile.yml \
  --extra-vars "user=user@OFFICE.LOCAL profile=employee department=accounting"

# Fix file ACL if needed
setfacl -R -m g:Finance:rwx /srv/shares/departments/finance/
setfacl -R -m g:Accounting:--- /srv/shares/departments/finance/

# Fix SELinux context
restorecon -Rv /srv/shares/departments/finance/
```

---

#### Issue 3: Compliance Verification Fails

**Symptoms:**
- `verify_compliance.yml` playbook reports "FAIL"
- Daily compliance check email shows failures

**Diagnosis:**
```bash
# Run compliance check manually with verbose output
ansible-playbook playbooks/verify_compliance.yml \
  --extra-vars "user=user@OFFICE.LOCAL profile=manager" \
  -vvv

# Check specific test that failed
grep "FAIL" /var/log/security_profiles/compliance/user_2026-01-10.txt

# Check if configuration drift occurred
ansible-playbook playbooks/verify_compliance.yml --check --diff
```

**Common Causes:**
1. **Manual changes**: Someone manually edited config files (bypassing Ansible)
2. **Service not running**: auditd, sssd, or firewalld stopped
3. **Disk full**: Can't write audit logs
4. **Network issue**: Can't reach Active Directory

**Resolution:**
```bash
# Re-apply profile to fix drift
ansible-playbook playbooks/apply_profile.yml \
  --extra-vars "user=user@OFFICE.LOCAL profile=manager department=finance"

# Restart services if needed
systemctl restart sssd auditd firewalld rsyslog

# Check disk space
df -h /var/log

# Check AD connectivity
ping dc01.office.local
samba-tool testparm
```

---

#### Issue 4: Profile Application Takes Too Long

**Symptoms:**
- `apply_profile.yml` playbook runs for 30+ minutes
- Playbook appears to hang

**Diagnosis:**
```bash
# Run with verbose output to see where it's stuck
ansible-playbook playbooks/apply_profile.yml \
  --extra-vars "user=user@OFFICE.LOCAL profile=manager department=finance" \
  -vvv

# Check task timing
export ANSIBLE_CALLBACK_WHITELIST=profile_tasks
ansible-playbook playbooks/apply_profile.yml \
  --extra-vars "user=user@OFFICE.LOCAL profile=manager department=finance"

# Check if waiting for external service
netstat -antp | grep ESTABLISHED
```

**Common Causes:**
1. **Slow AD response**: Domain controller overloaded or network latency
2. **Firewall API timeout**: pfSense API slow to respond
3. **Large file operation**: Copying large audit logs
4. **DNS resolution**: Slow DNS lookups

**Resolution:**
```bash
# Optimize AD queries (use caching)
# Edit ansible.cfg
[defaults]
gathering = smart
fact_caching = jsonfile
fact_caching_connection = /tmp/ansible_facts
fact_caching_timeout = 3600

# Run in parallel where possible
# Edit playbook to use async/poll
- name: Configure firewall rules
  uri:
    url: https://pfsense.office.local/api/v1/firewall/rule
    method: POST
    body_format: json
    body: "{{ firewall_rule }}"
  async: 300
  poll: 0
  register: firewall_task

# Wait for all async tasks
- name: Wait for firewall configuration
  async_status:
    jid: "{{ firewall_task.ansible_job_id }}"
  register: job_result
  until: job_result.finished
  retries: 30
```

---

### Debug Commands

**Check Profile Applied to User:**
```bash
ansible-inventory --host user@OFFICE.LOCAL --yaml
```

**List All Users with Specific Profile:**
```bash
ansible-inventory --graph --vars | grep -B 5 "profile: manager"
```

**Check Security Object Configuration:**
```bash
cat /opt/security-framework/security_objects/user_access/privileged.yml
```

**Test Profile Application (Dry Run):**
```bash
ansible-playbook playbooks/apply_profile.yml \
  --extra-vars "user=user@OFFICE.LOCAL profile=manager department=finance" \
  --check --diff
```

**Verify Single Component:**
```bash
# Test PAM 2FA
ssh user@host  # Should prompt for Yubikey

# Test file access
smbclient //file-server01/finance -U user@OFFICE.LOCAL -c 'ls'

# Test firewall
nmap -p 22,445 file-server01  # From user's workstation

# Test audit logging
ausearch -m USER_AUTH | grep user@OFFICE.LOCAL | tail -5
```

---

## Appendix

### A. Glossary

| Term | Definition |
|------|------------|
| **User Profile** | A named collection of security objects representing a business role (e.g., manager, developer) |
| **Security Object** | A reusable group of related policies (e.g., user_access_privileged, data_access_confidential) |
| **Policy** | A specific security requirement (e.g., logon_policy, firewall_policy) |
| **Tool Mapping** | Configuration connecting a policy to specific security tools (e.g., PAM, SELinux) |
| **PAM** | Pluggable Authentication Modules - Linux authentication framework |
| **SELinux** | Security-Enhanced Linux - Mandatory Access Control system |
| **2FA** | Two-Factor Authentication - Password + something you have (Yubikey) |
| **Yubikey** | Physical security key for 2FA |
| **AD** | Active Directory - Microsoft's directory service for user management |
| **SSSD** | System Security Services Daemon - Connects Linux to Active Directory |
| **auditd** | Linux Audit Daemon - Logs system events for security and compliance |
| **Wazuh SIEM** | Security Information and Event Management - Real-time log analysis and alerting |
| **JIT** | Just-In-Time elevation - Temporary privilege escalation with approval |
| **FIPS 140-2** | Federal Information Processing Standard - Government-approved cryptography |
| **SOX** | Sarbanes-Oxley Act - Financial data protection regulation |
| **GDPR** | General Data Protection Regulation - EU privacy law |
| **HIPAA** | Health Insurance Portability and Accountability Act - Healthcare data protection |

### B. Related Documents

- [Security-Policy-Framework-Explained.md](Security-Policy-Framework-Explained.md) - Casual-level explanation for IT pros and business users
- [Security-Profile-Creation-Guide.md](Security-Profile-Creation-Guide.md) - Step-by-step implementation guide
- Domain-Controller-Security-Flow.md - Security flow for Samba AD DCs
- File-Server-Security-Flow.md - Security flow for file servers
- [All other *-Security-Flow.md documents] - Complete infrastructure security documentation

### C. Version History

| Version | Date | Author | Changes |
|---------|------|--------|---------|
| 1.0 | 2026-01-10 | IT Security Team | Initial release |

### D. Feedback and Contributions

**Questions or suggestions?**
- Email: it-security@company.com
- Slack: #security-framework
- Git Issues: https://gitlab.company.com/security/framework/issues

**Contributing:**
1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Submit a merge request with description
5. Tag @security-team for review

---

**Document Prepared By:** IT Security Team
**Last Updated:** 2026-01-10
**Next Review:** 2026-04-10 (Quarterly)
**Classification:** Internal Use Only
