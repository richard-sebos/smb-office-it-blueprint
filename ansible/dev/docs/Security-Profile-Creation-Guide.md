# Security Profile Creation Guide: Step-by-Step

## Overview

This guide walks you through creating security profiles using the 3-layer architecture:
1. **Business Layer**: Define user profiles (WHO)
2. **Policy Layer**: Create security objects (WHAT)
3. **Tool Layer**: Map tools to policies (HOW)

**Time Investment**: 2-4 weeks for initial setup, then continuous refinement

---

## Step 1: Inventory Your Users (Business Layer)

### Goal
Identify all the different types of users in your organization, grouped by what they need to do (not just job titles).

### How To Do It

1. **List all job roles** in your organization:
   - Department heads, managers
   - Finance/accounting staff
   - HR staff
   - IT administrators
   - Developers/DevOps
   - General office workers
   - Contractors/temporary staff
   - Executives
   - Front desk/reception

2. **For each role, answer these questions**:
   ```
   Role: ___________________

   What do they need to access?
   - Files/shares: ___________
   - Applications: ___________
   - Servers: ___________
   - Network resources: ___________

   Where do they work from?
   - Office only
   - Remote/home
   - Both
   - Mobile/field work

   What's the sensitivity level of their data?
   - Public (anyone can see)
   - Internal (employees only)
   - Confidential (department only)
   - Restricted (specific individuals only)

   What compliance requirements apply?
   - SOX (financial data)
   - HIPAA (health data)
   - GDPR (personal data)
   - None

   What's the security risk if compromised?
   - Low (limited data exposure)
   - Medium (department data exposure)
   - High (company-wide data exposure)
   - Critical (financial/legal liability)
   ```

3. **Group similar roles together**:
   - If Finance Manager and HR Manager need similar security, they're one profile
   - If Junior Developer and Senior Developer need different access, they're separate profiles
   - Goal: 5-10 profiles for most organizations (more if you're large/complex)

### Example Output

```yaml
# Profile inventory (not final format, just notes)

Profile: manager
- Who: Department heads (Finance, HR, Sales, Operations)
- Access: Department files (sensitive), email, office apps
- Location: Office + home (VPN)
- Sensitivity: Confidential to Restricted
- Compliance: SOX (if Finance), HIPAA (if HR), GDPR
- Risk: High (handles sensitive employee/financial data)

Profile: employee
- Who: General office workers (accounting clerks, sales reps, admins)
- Access: Department files (non-sensitive), email, office apps, printers
- Location: Office only
- Sensitivity: Internal
- Compliance: GDPR (basic)
- Risk: Low to Medium

Profile: developer
- Who: Software developers, DevOps engineers
- Access: Dev/test servers, code repositories, CI/CD tools
- Location: Office + home (VPN)
- Sensitivity: Internal (code, test data only - NO production data)
- Compliance: None (no real data in dev)
- Risk: Medium (could introduce vulnerabilities, but isolated from production)

Profile: it_admin
- Who: IT system administrators, security team
- Access: ALL systems (production servers, firewalls, backups)
- Location: Office + approved home IPs only
- Sensitivity: All levels (can access everything)
- Compliance: All (manages compliance tools)
- Risk: Critical (keys to the kingdom)

Profile: receptionist
- Who: Front desk staff, shared workstations
- Access: Email, calendar, visitor system, directory
- Location: Office only (specific workstation)
- Sensitivity: Public to Internal
- Compliance: GDPR (visitor data)
- Risk: Low (limited access, no persistent storage)
```

**Deliverable**: A document listing 5-10 user profiles with descriptions.

---

## Step 2: Define Security Requirements (Policy Layer - Part 1)

### Goal
For each user profile, define what security policies apply (without worrying about HOW to implement them yet).

### How To Do It

For each profile from Step 1, fill out this template:

```yaml
# Profile: [PROFILE_NAME]

## User Access Requirements

Logon Policy:
- Authentication method: [ ] Password only
                         [ ] Password + 2FA (Yubikey)
                         [ ] SSH key
                         [ ] Certificate
- Password requirements: Length: ___ chars, Complexity: Y/N, Expiration: ___ days
- Failed login handling: Lock after ___ attempts, Duration: ___ minutes
- Login location: [ ] Office only
                  [ ] Office + VPN
                  [ ] Anywhere (with restrictions)

Session Policy:
- Idle timeout: ___ minutes
- Concurrent sessions allowed: ___ (1 = single login, 2+ = multiple devices)
- Screen lock timeout: ___ minutes
- Session recording: [ ] Yes (for compliance)  [ ] No (privacy)

Audit Policy:
- Logging level: [ ] Minimal (login/logout only)
                 [ ] Standard (file access, network connections)
                 [ ] Detailed (all commands, all actions)
- Log retention: ___ days/years
- Alert on: [ ] Failed logins
            [ ] After-hours access
            [ ] Large file downloads
            [ ] Access to restricted files

## Data Access Requirements

Storage Policy:
- Encryption at rest: [ ] Standard  [ ] FIPS 140-2 (government-grade)
- Access control: [ ] Basic (POSIX permissions)
                  [ ] Enhanced (SELinux/AppArmor)
                  [ ] Multi-level (SELinux categories)
- What data: _______________ (e.g., "Finance department files", "All company data")
- File quotas: ___ GB per user

Encryption Policy:
- Network encryption: [ ] Standard (TLS 1.2)
                      [ ] Required (TLS 1.3 + SMB3 encryption)
                      [ ] Optional (dev environments only)

Backup Policy:
- Frequency: [ ] Hourly  [ ] Daily  [ ] Weekly
- Retention: [ ] 90 days  [ ] 1 year  [ ] 7 years (SOX)
- Recovery: Who can request: _______________

## Network Access Requirements

Remote Access Policy:
- VPN required: [ ] Yes  [ ] No  [ ] N/A (office only)
- SSH access: [ ] Yes (servers)  [ ] No
- Allowed source IPs: [ ] Any (with VPN)
                      [ ] Office VLAN only
                      [ ] Specific IPs: _______________

Firewall Policy:
- Can access:
  [ ] File servers (which: _______________)
  [ ] Print servers
  [ ] Email servers
  [ ] Database servers (which: _______________)
  [ ] Development servers
  [ ] Production servers
  [ ] Other user workstations
  [ ] Internet (with filtering)

- Cannot access:
  [ ] Production servers
  [ ] Backup servers
  [ ] Security infrastructure (firewalls, monitoring)
  [ ] Other departments' resources
```

### Example Output

```yaml
# Profile: manager

## User Access Requirements

Logon Policy:
- Authentication method: [X] Password + 2FA (Yubikey)
- Password requirements: Length: 16 chars, Complexity: Yes, Expiration: 60 days
- Failed login handling: Lock after 3 attempts, Duration: 60 minutes
- Login location: [X] Office + VPN

Session Policy:
- Idle timeout: 15 minutes
- Concurrent sessions allowed: 1 (enforce single device)
- Screen lock timeout: 5 minutes
- Session recording: [ ] No (privacy for managers)

Audit Policy:
- Logging level: [X] Detailed (all commands, all actions)
- Log retention: 7 years (SOX compliance)
- Alert on: [X] Failed logins
            [X] After-hours access
            [X] Large file downloads
            [X] Access to restricted files

## Data Access Requirements

Storage Policy:
- Encryption at rest: [X] FIPS 140-2 (government-grade)
- Access control: [X] Enhanced (SELinux)
- What data: Department files (Finance, HR, etc. - sensitive)
- File quotas: 100 GB per user

Encryption Policy:
- Network encryption: [X] Required (TLS 1.3 + SMB3 encryption)

Backup Policy:
- Frequency: [X] Continuous (changed files within 5 minutes)
- Retention: [X] 7 years (SOX)
- Recovery: Who can request: Manager + IT Director (dual approval)

## Network Access Requirements

Remote Access Policy:
- VPN required: [X] Yes
- SSH access: [ ] No (not needed)
- Allowed source IPs: [X] Office VLAN + VPN

Firewall Policy:
- Can access:
  [X] File servers (their department + company-wide shares)
  [X] Print servers
  [X] Email servers
  [ ] Database servers
  [ ] Development servers
  [ ] Production servers (except file servers)
  [ ] Other user workstations
  [X] Internet (with filtering)

- Cannot access:
  [X] Production servers (database, monitoring, backup)
  [X] Backup servers
  [X] Security infrastructure
  [X] Other departments' resources (unless explicitly granted)
```

**Deliverable**: Completed templates for each profile (5-10 documents).

---

## Step 3: Create Security Objects (Policy Layer - Part 2)

### Goal
Group related policies into reusable "security objects" that can be shared across multiple profiles.

### How To Do It

1. **Look across all profiles from Step 2** and find common patterns:
   - Do multiple profiles have the same "Password + 2FA" requirement?
   - Do multiple profiles need "7-year backup retention"?
   - Do multiple profiles need "access to Finance files"?

2. **Create security objects for each pattern**:

   ```yaml
   # Security Object Template

   object_name: [descriptive_name]
   type: [user_access | data_access | network_access]
   description: [what this object provides]

   policies:
     [policy_name]:
       - name: [descriptive name]
         requirements:
           - [requirement 1]
           - [requirement 2]
   ```

3. **Common security objects** to create:

   ### User Access Objects
   - `user_access_basic` - Password only, minimal logging
   - `user_access_standard` - Password only, standard logging
   - `user_access_privileged` - Password + 2FA, detailed logging
   - `user_access_developer` - Password + SSH keys, dev-focused logging
   - `user_access_admin` - Password + 2FA + JIT approval, comprehensive logging

   ### Data Access Objects
   - `data_access_public` - No encryption, basic permissions
   - `data_access_internal` - Standard encryption, group-based access
   - `data_access_confidential` - Enhanced encryption, department-restricted
   - `data_access_restricted` - FIPS encryption, individual access control
   - `data_access_test_only` - Synthetic data, no production data allowed

   ### Network Access Objects
   - `network_access_workstation_only` - No remote access, office only
   - `network_access_standard` - VPN allowed, file/print/email servers
   - `network_access_isolated` - Dev/test servers only, blocked from production
   - `network_access_admin` - Full access with JIT approval

4. **Map profiles to security objects**:

   ```yaml
   # Profile to Security Object Mapping

   profile: manager
   security_objects:
     - user_access_privileged     # 2FA, detailed logging
     - data_access_confidential   # Department-restricted data
     - network_access_standard    # VPN + file/email servers

   profile: employee
   security_objects:
     - user_access_standard       # Password only, standard logging
     - data_access_internal       # Department files
     - network_access_standard    # VPN + file/email/print servers

   profile: developer
   security_objects:
     - user_access_developer      # Password + SSH keys
     - data_access_test_only      # No production data
     - network_access_isolated    # Dev/test servers only

   profile: it_admin
   security_objects:
     - user_access_admin          # 2FA + JIT approval
     - data_access_restricted     # All data (for support/recovery)
     - network_access_admin       # All systems
   ```

### Example Output

```yaml
# security_objects/user_access_privileged.yml

object_name: user_access_privileged
type: user_access
description: Enhanced authentication and logging for users who handle sensitive data
applies_to: [manager, finance_staff, hr_staff]

policies:
  logon_policy:
    - name: Multi-Factor Authentication Required
      requirements:
        - authentication_methods: [password, yubikey]
        - password_length: 16
        - password_complexity: true
        - password_expiration_days: 60
        - failed_login_threshold: 3
        - lockout_duration_minutes: 60
        - allowed_locations: [office_vlan, vpn]

  session_policy:
    - name: Enhanced Session Security
      requirements:
        - idle_timeout_minutes: 15
        - max_concurrent_sessions: 1
        - screen_lock_timeout_minutes: 5
        - session_recording: false

  audit_policy:
    - name: Comprehensive Audit Logging
      requirements:
        - logging_level: detailed
        - log_retention_years: 7
        - log_events: [login, logout, file_access, file_modify, command_execution, network_connection]
        - alert_triggers: [failed_login, after_hours_access, large_download, restricted_file_access]

---

# security_objects/data_access_confidential.yml

object_name: data_access_confidential
type: data_access
description: Access to department-specific sensitive data with enhanced encryption
applies_to: [manager, finance_staff, hr_staff]

policies:
  storage_policy:
    - name: Enhanced Encryption and Access Control
      requirements:
        - encryption_at_rest: fips_140_2
        - access_control_mechanism: selinux
        - access_control_model: group_based
        - file_quota_gb: 100
        - virus_scanning: enabled

  encryption_policy:
    - name: Mandatory Encryption in Transit
      requirements:
        - smb3_encryption: required
        - tls_minimum_version: "1.3"
        - certificate_validation: strict

  backup_policy:
    - name: Long-term Retention for Compliance
      requirements:
        - frequency: continuous
        - retention_period_years: 7
        - recovery_point_objective_minutes: 5
        - recovery_approvers: [manager, it_director]
        - immutable_backups: enabled

---

# security_objects/network_access_standard.yml

object_name: network_access_standard
type: network_access
description: Standard network access for office work (file/print/email servers)
applies_to: [manager, employee]

policies:
  remote_access_policy:
    - name: Secure Remote Access
      requirements:
        - vpn_required: true
        - vpn_protocol: wireguard
        - ssh_access: false
        - allowed_source_networks: [office_vlan, vpn]

  firewall_policy:
    - name: Office Resource Access
      requirements:
        - allowed_destinations:
          - file_servers: [file-server01]
          - print_servers: [print-server01]
          - email_servers: [mail-server01]
          - internet: true
        - blocked_destinations:
          - production_servers: [dc01, dc02, backup-server, monitoring01]
          - dev_servers: [dev-test01]
          - other_workstations: true
          - security_infrastructure: true
```

**Deliverable**: 8-15 security object YAML files.

---

## Step 4: Map Security Tools (Tool Layer)

### Goal
For each policy in your security objects, identify which tools will enforce it.

### How To Do It

1. **List all security tools you have** (or plan to implement):
   ```
   Authentication:
   - PAM (Linux authentication)
   - Active Directory / LDAP
   - pam_yubico (2FA)
   - SSH (key-based auth)

   Access Control:
   - SELinux (Linux MAC)
   - AppArmor (Ubuntu MAC)
   - POSIX ACLs
   - Windows ACLs

   Encryption:
   - LUKS (disk encryption)
   - FIPS mode (crypto library)
   - SMB3 encryption
   - TLS/SSL

   Firewall:
   - pfSense (network firewall)
   - firewalld (host firewall)
   - iptables

   Logging:
   - auditd (system auditing)
   - rsyslog (log forwarding)
   - Elasticsearch (log storage)
   - Wazuh SIEM (alerting)

   Backup:
   - Bacula
   - Restic
   - AWS S3 (offsite)

   Monitoring:
   - Wazuh
   - Nagios/Icinga
   - Prometheus/Grafana
   ```

2. **For each policy requirement, map it to tools**:

   ```yaml
   # Tool Mapping Template

   policy: [policy_name]
   requirement: [specific requirement from security object]

   tools:
     primary: [main tool that enforces this]
     configuration:
       - setting: [what to configure]
         value: [what value]

     supporting: [additional tools that help]
     verification: [how to test this works]
   ```

3. **Create tool mappings**:

### Example Output

```yaml
# tool_mappings/logon_policy.yml

policy: logon_policy
requirement: Multi-Factor Authentication (password + Yubikey)

tools:
  primary: PAM (Pluggable Authentication Modules)

  configurations:
    # /etc/pam.d/common-auth
    - file: /etc/pam.d/common-auth
      settings:
        - "auth required pam_yubico.so id=12345 key=abcd1234 urllist=https://api.yubico.com/wsapi/2.0/verify"
        - "auth required pam_sss.so"  # Active Directory integration

    # /etc/security/access.conf
    - file: /etc/security/access.conf
      settings:
        - "+ : (Privileged-Users) : ALL"  # Allow if in AD group
        - "- : ALL : ALL"  # Deny everyone else

  supporting:
    - Active Directory (group membership)
    - pam_sss (SSSD - AD connector)
    - fail2ban (block brute force)

  verification:
    - test: "User with Yubikey can log in"
      command: "ssh user@host"
      expected: "Success after password + Yubikey touch"

    - test: "User without Yubikey cannot log in"
      command: "ssh user@host"
      expected: "Authentication failure"

    - test: "User not in Privileged-Users group cannot log in"
      command: "ssh unauthorized_user@host"
      expected: "Access denied"

---

# tool_mappings/storage_policy.yml

policy: storage_policy
requirement: FIPS 140-2 encryption at rest

tools:
  primary: FIPS mode (system-wide cryptography)

  configurations:
    # Enable FIPS mode
    - file: /etc/default/grub
      settings:
        - "GRUB_CMDLINE_LINUX=\"fips=1\""

    # Update initramfs
    - command: "update-initramfs -u"

    # Verify FIPS mode
    - command: "cat /proc/sys/crypto/fips_enabled"
      expected: "1"

  supporting:
    - LUKS (disk encryption uses FIPS algorithms)
    - SELinux (access control)
    - dm-crypt (encrypts block devices)

  verification:
    - test: "FIPS mode enabled"
      command: "cat /proc/sys/crypto/fips_enabled"
      expected: "1"

    - test: "Only FIPS-approved algorithms available"
      command: "openssl ciphers -v | grep -v FIPS"
      expected: "Empty output (no non-FIPS ciphers)"

---

# tool_mappings/firewall_policy.yml

policy: firewall_policy
requirement: Allow access to file servers, block production servers

tools:
  primary: pfSense (network firewall)

  configurations:
    # Allow Manager VLAN → File Server
    - rule_name: "allow-managers-to-fileserver"
      source: "10.0.131.0/24"  # Admin VLAN (managers)
      destination: "10.0.120.20"  # file-server01
      ports: [139, 445]  # SMB
      action: "allow"

    # Block Manager VLAN → Domain Controllers
    - rule_name: "block-managers-to-dc"
      source: "10.0.131.0/24"
      destination: "10.0.120.10,10.0.120.11"  # dc01, dc02
      action: "block"

    # Block Manager VLAN → Backup Server
    - rule_name: "block-managers-to-backup"
      source: "10.0.131.0/24"
      destination: "10.0.120.60"  # backup-server
      action: "block"

  supporting:
    - firewalld (host-based firewall on servers)
    - Wazuh SIEM (alert on blocked connections)

  verification:
    - test: "Manager can access file server"
      command: "smbclient //file-server01/share -U manager"
      expected: "Connection successful"

    - test: "Manager cannot SSH to domain controller"
      command: "ssh manager@dc01"
      expected: "Connection refused (firewall block)"
```

**Deliverable**: Tool mapping documents for each policy (15-25 YAML files).

---

## Step 5: Write Ansible Playbooks (Automation)

### Goal
Automate the application of security profiles using Ansible.

### How To Do It

1. **Create directory structure**:
   ```
   ansible/
   ├── profiles/
   │   ├── manager.yml
   │   ├── employee.yml
   │   ├── developer.yml
   │   └── it_admin.yml
   ├── security_objects/
   │   ├── user_access_privileged.yml
   │   ├── data_access_confidential.yml
   │   └── network_access_standard.yml
   ├── tool_mappings/
   │   ├── logon_policy.yml
   │   ├── storage_policy.yml
   │   └── firewall_policy.yml
   ├── roles/
   │   ├── configure_pam/
   │   ├── configure_selinux/
   │   ├── configure_firewall/
   │   └── configure_audit/
   └── playbooks/
       ├── apply_profile.yml
       ├── verify_compliance.yml
       └── remove_profile.yml
   ```

2. **Create profile playbook**:

   ```yaml
   # playbooks/apply_profile.yml

   ---
   - name: Apply Security Profile to User
     hosts: all
     gather_facts: yes

     vars:
       user: "{{ user_email }}"  # e.g., sarah@OFFICE.LOCAL
       profile: "{{ user_profile }}"  # e.g., manager
       department: "{{ user_department }}"  # e.g., finance

     tasks:
       - name: Load profile definition
         include_vars:
           file: "../profiles/{{ profile }}.yml"
           name: profile_def

       - name: Apply each security object
         include_role:
           name: "apply_security_object"
         vars:
           security_object: "{{ item }}"
         loop: "{{ profile_def.security_objects }}"

       - name: Verify profile applied correctly
         include_tasks: verify_profile.yml

       - name: Generate compliance report
         template:
           src: compliance_report.j2
           dest: "/var/log/security_profiles/{{ user }}_{{ profile }}_{{ ansible_date_time.iso8601 }}.txt"
   ```

3. **Create security object role**:

   ```yaml
   # roles/apply_security_object/tasks/main.yml

   ---
   - name: Load security object definition
     include_vars:
       file: "../../security_objects/{{ security_object }}.yml"
       name: sec_obj

   - name: Apply user access policies
     include_tasks: apply_user_access.yml
     when: sec_obj.type == "user_access"

   - name: Apply data access policies
     include_tasks: apply_data_access.yml
     when: sec_obj.type == "data_access"

   - name: Apply network access policies
     include_tasks: apply_network_access.yml
     when: sec_obj.type == "network_access"
   ```

4. **Create tool configuration tasks**:

   ```yaml
   # roles/apply_security_object/tasks/apply_user_access.yml

   ---
   - name: Load tool mapping for logon policy
     include_vars:
       file: "../../tool_mappings/logon_policy.yml"
       name: tool_map

   - name: Configure PAM for 2FA
     template:
       src: pam_common_auth.j2
       dest: /etc/pam.d/common-auth
       owner: root
       group: root
       mode: '0644'
     when: "'yubikey' in tool_map.tools.configurations"

   - name: Add user to Privileged-Users AD group
     command: >
       samba-tool group addmembers "Privileged-Users" "{{ user }}"
     delegate_to: dc01
     when: "'Privileged-Users' in sec_obj.policies.logon_policy[0].requirements"

   - name: Configure auditd rules for user
     template:
       src: auditd_user.rules.j2
       dest: "/etc/audit/rules.d/{{ user | regex_replace('@.*', '') }}.rules"
       owner: root
       group: root
       mode: '0640'
     notify: restart auditd
   ```

### Example Playbook Execution

```bash
# Apply manager profile to Sarah
ansible-playbook playbooks/apply_profile.yml \
  --extra-vars "user_email=sarah@OFFICE.LOCAL user_profile=manager user_department=finance"

# Output:
PLAY [Apply Security Profile to User] ******************************************

TASK [Load profile definition] ************************************************
ok: [localhost]

TASK [Apply security object: user_access_privileged] ***************************
changed: [localhost]
  - Configured PAM for Yubikey 2FA
  - Added sarah@OFFICE.LOCAL to Privileged-Users AD group
  - Created auditd rules: /etc/audit/rules.d/sarah.rules

TASK [Apply security object: data_access_confidential] *************************
changed: [file-server01]
  - Enabled FIPS mode
  - Added sarah to Finance share ACL
  - Configured SELinux context: user_u:user_r:user_t:s0:c0.c5
  - Created Bacula backup job: Sarah-Finance-7year

TASK [Apply security object: network_access_standard] **************************
changed: [pfsense]
  - Added firewall rule: allow-sarah-to-fileserver
  - Blocked firewall rule: block-sarah-to-production-servers

TASK [Verify profile applied correctly] ****************************************
ok: [all]
  ✓ Sarah can log in with Yubikey
  ✓ Sarah can access Finance share
  ✗ Sarah cannot access HR share (correct)
  ✓ Sarah's actions are logged to monitoring01

TASK [Generate compliance report] **********************************************
changed: [localhost]
  Report: /var/log/security_profiles/sarah@OFFICE.LOCAL_manager_2026-01-10T10:30:00Z.txt

PLAY RECAP *********************************************************************
localhost                  : ok=6    changed=4    unreachable=0    failed=0
file-server01              : ok=4    changed=3    unreachable=0    failed=0
pfsense                    : ok=2    changed=1    unreachable=0    failed=0
```

**Deliverable**: Working Ansible playbooks that can apply profiles.

---

## Step 6: Test and Validate

### Goal
Verify that profiles work correctly and provide the right level of access.

### How To Do It

1. **Create test users** (one for each profile):
   ```bash
   # Test manager profile
   ansible-playbook playbooks/apply_profile.yml \
     --extra-vars "user_email=test-manager@OFFICE.LOCAL user_profile=manager user_department=finance"

   # Test employee profile
   ansible-playbook playbooks/apply_profile.yml \
     --extra-vars "user_email=test-employee@OFFICE.LOCAL user_profile=employee user_department=accounting"
   ```

2. **Run verification playbook**:
   ```yaml
   # playbooks/verify_compliance.yml

   ---
   - name: Verify Security Profile Compliance
     hosts: all

     vars:
       user: "{{ user_email }}"
       profile: "{{ user_profile }}"

     tasks:
       - name: Test authentication
         block:
           - name: Verify password login works
             command: "sshpass -p '{{ test_password }}' ssh {{ user }}@localhost echo success"
             register: password_login
             failed_when: password_login.rc != 0

           - name: Verify 2FA required (if applicable)
             command: "ssh {{ user }}@localhost echo success"
             register: no_2fa_login
             failed_when: no_2fa_login.rc == 0  # Should FAIL without 2FA
             when: "'privileged' in profile"

       - name: Test file access
         block:
           - name: Verify can access authorized share
             command: "smbclient //file-server01/{{ department }} -U {{ user }} -c 'ls'"
             register: authorized_access
             failed_when: authorized_access.rc != 0

           - name: Verify cannot access unauthorized share
             command: "smbclient //file-server01/restricted -U {{ user }} -c 'ls'"
             register: unauthorized_access
             failed_when: unauthorized_access.rc == 0  # Should FAIL

       - name: Test network access
         block:
           - name: Verify can reach file server
             command: "ping -c 1 file-server01"
             register: fileserver_ping
             failed_when: fileserver_ping.rc != 0

           - name: Verify cannot reach production servers (if developer)
             command: "ping -c 1 dc01"
             register: dc_ping
             failed_when: dc_ping.rc == 0  # Should FAIL for developers
             when: "profile == 'developer'"

       - name: Generate test report
         debug:
           msg: |
             Profile: {{ profile }}
             User: {{ user }}

             Authentication Tests:
               ✓ Password login: {{ 'PASS' if password_login.rc == 0 else 'FAIL' }}
               ✓ 2FA required: {{ 'PASS' if no_2fa_login.rc != 0 else 'FAIL' }}

             File Access Tests:
               ✓ Authorized share: {{ 'PASS' if authorized_access.rc == 0 else 'FAIL' }}
               ✓ Unauthorized share blocked: {{ 'PASS' if unauthorized_access.rc != 0 else 'FAIL' }}

             Network Access Tests:
               ✓ File server reachable: {{ 'PASS' if fileserver_ping.rc == 0 else 'FAIL' }}
               ✓ Production servers blocked: {{ 'PASS' if dc_ping.rc != 0 else 'FAIL' }}
   ```

3. **Fix any issues** found during testing:
   - Update security objects if requirements wrong
   - Update tool mappings if tools misconfigured
   - Update Ansible playbooks if automation incorrect

**Deliverable**: Test reports showing all profiles work correctly.

---

## Step 7: Document and Train

### Goal
Create documentation for IT staff and train users on the new system.

### How To Do It

1. **Create user documentation**:
   ```markdown
   # User Guide: Security Profiles at [Company Name]

   ## What is a Security Profile?
   Your security profile determines:
   - How you log in (password, 2FA, etc.)
   - What files you can access
   - What systems you can connect to
   - How your activity is logged

   ## Your Profile: Manager

   ### How to Log In
   1. Enter your password
   2. Touch your Yubikey when prompted
   3. You have 15 minutes of idle time before automatic logout

   ### What You Can Access
   - Your department's files (Finance)
   - Company-wide shared files
   - Email and office applications
   - Print servers

   ### What You CANNOT Access
   - Other departments' files (unless explicitly granted)
   - Production servers (database, backup, etc.)
   - Other employees' workstations

   ### Security Features
   - All your file access is logged (7-year retention)
   - Your data is backed up continuously
   - All network traffic is encrypted
   - You can only log in from one device at a time

   ### Working from Home
   1. Connect to VPN first
   2. Then log in as normal
   3. Same security applies (all actions logged)

   ### What to Do If...
   - **Lost Yubikey**: Contact IT immediately (we'll issue temporary password-only access)
   - **Need access to restricted file**: Request via IT ticket (manager approval required)
   - **Forgot password**: Self-service reset at https://passwordreset.company.com
   ```

2. **Create IT admin documentation**:
   ```markdown
   # IT Admin Guide: Managing Security Profiles

   ## Onboarding New User

   ```bash
   # 1. Determine correct profile (manager, employee, developer, etc.)
   # 2. Run onboarding playbook
   ansible-playbook playbooks/apply_profile.yml \
     --extra-vars "user_email=newuser@OFFICE.LOCAL user_profile=manager user_department=finance"

   # 3. Issue Yubikey (if privileged profile)
   # 4. Train user on their profile
   ```

   ## Changing User Profile

   ```bash
   # Example: John promoted from employee to manager

   # 1. Remove old profile
   ansible-playbook playbooks/remove_profile.yml \
     --extra-vars "user_email=john@OFFICE.LOCAL user_profile=employee"

   # 2. Apply new profile
   ansible-playbook playbooks/apply_profile.yml \
     --extra-vars "user_email=john@OFFICE.LOCAL user_profile=manager user_department=finance"

   # 3. Issue Yubikey (now required)
   # 4. Train user on new privileges
   ```

   ## Troubleshooting

   ### User Can't Log In
   - Check AD group membership: `samba-tool group listmembers Privileged-Users`
   - Check Yubikey registered: `ykman list`
   - Check PAM logs: `journalctl -u sshd | grep pam`

   ### User Can't Access File
   - Check profile: `ansible-inventory --host user@OFFICE.LOCAL`
   - Check file ACL: `getfacl /srv/shares/departments/finance`
   - Check SELinux: `ausearch -m avc -c smbd`

   ### Need to Grant Exception
   - Temporary: Update user's profile YAML directly
   - Permanent: Update security object to include new requirement
   ```

3. **Conduct training**:
   - **IT Staff**: How to apply profiles, troubleshoot issues
   - **Managers**: What profiles exist, how to request access changes
   - **Users**: How their profile affects their daily work

**Deliverable**: User guides, admin guides, training materials.

---

## Step 8: Deploy to Production

### Goal
Roll out security profiles to all users.

### How To Do It

1. **Pilot rollout** (10-20 users):
   ```bash
   # Week 1: IT staff only
   ansible-playbook playbooks/apply_profile.yml --limit it-staff-group

   # Week 2: One department (Finance)
   ansible-playbook playbooks/apply_profile.yml --limit finance-group

   # Gather feedback, fix issues
   ```

2. **Phased rollout** (remaining users):
   ```bash
   # Week 3-4: Managers
   ansible-playbook playbooks/apply_profile.yml --limit manager-group

   # Week 5-8: All employees (department by department)
   ansible-playbook playbooks/apply_profile.yml --limit sales-group
   ansible-playbook playbooks/apply_profile.yml --limit accounting-group
   ansible-playbook playbooks/apply_profile.yml --limit operations-group
   ```

3. **Monitor and adjust**:
   - Check Wazuh SIEM for policy violations
   - Check audit logs for access denials
   - Adjust profiles based on real-world usage

**Deliverable**: All users transitioned to security profiles.

---

## Step 9: Maintain and Improve

### Goal
Keep profiles up-to-date as business needs and security requirements change.

### How To Do It

1. **Quarterly review**:
   - Are profiles still accurate? (roles change over time)
   - Are security objects comprehensive? (new tools added?)
   - Are policies being followed? (compliance verification)

2. **Automated compliance checks** (daily):
   ```bash
   # Cron job: /etc/cron.daily/verify-security-profiles
   #!/bin/bash
   ansible-playbook playbooks/verify_compliance.yml --all

   # Email report to security team
   ```

3. **Policy updates** (as needed):
   ```bash
   # New requirement: All Finance access needs 2FA

   # 1. Update security object
   vim security_objects/data_access_confidential.yml
   # Add: required_user_access: user_access_privileged

   # 2. Run update playbook
   ansible-playbook playbooks/update_security_objects.yml --tags data_access_confidential

   # 3. Verify all users updated
   ansible-playbook playbooks/verify_compliance.yml --tags finance-2fa
   ```

**Deliverable**: Continuous improvement process.

---

## Summary: Timeline and Effort

| Step | Duration | Effort | Deliverable |
|------|----------|--------|-------------|
| 1. Inventory Users | 1 week | Medium | 5-10 user profiles documented |
| 2. Define Security Requirements | 1-2 weeks | Medium | Security requirements for each profile |
| 3. Create Security Objects | 1 week | Medium | 8-15 reusable security objects |
| 4. Map Security Tools | 1-2 weeks | High | Tool mappings for each policy |
| 5. Write Ansible Playbooks | 2-4 weeks | High | Working automation |
| 6. Test and Validate | 1-2 weeks | Medium | Verified profiles |
| 7. Document and Train | 1 week | Medium | User/admin guides |
| 8. Deploy to Production | 4-8 weeks | Low | All users transitioned |
| 9. Maintain and Improve | Ongoing | Low | Continuous compliance |

**Total Initial Setup**: 12-20 weeks (3-5 months)

**Ongoing Maintenance**: 2-4 hours per month

---

## Quick Reference

### Essential Commands

```bash
# Apply profile to user
ansible-playbook playbooks/apply_profile.yml \
  --extra-vars "user_email=USER@OFFICE.LOCAL user_profile=PROFILE user_department=DEPT"

# Remove profile from user
ansible-playbook playbooks/remove_profile.yml \
  --extra-vars "user_email=USER@OFFICE.LOCAL"

# Verify user compliance
ansible-playbook playbooks/verify_compliance.yml \
  --extra-vars "user_email=USER@OFFICE.LOCAL"

# Update security object (apply to all users)
ansible-playbook playbooks/update_security_objects.yml \
  --tags SECURITY_OBJECT_NAME

# Query who has specific access
ansible-inventory --graph --vars | grep -A 10 "SECURITY_OBJECT_NAME"
```

### File Structure Quick Reference

```
ansible/
├── profiles/               # WHO (business roles)
│   └── manager.yml
├── security_objects/       # WHAT (policies)
│   └── user_access_privileged.yml
├── tool_mappings/          # HOW (tool configs)
│   └── logon_policy.yml
└── playbooks/              # Automation
    ├── apply_profile.yml
    └── verify_compliance.yml
```

---

## Success Criteria

You'll know this is working when:

✅ New user onboarding takes 10 minutes instead of 2-3 hours
✅ Compliance questions answered in seconds, not hours
✅ Profile changes applied consistently across all systems
✅ Security incidents investigated quickly (user profile shows what they should/shouldn't access)
✅ No "special snowflake" configurations (everyone with same profile has same access)
✅ Auditors satisfied with automated compliance verification

---

**Next Steps**: Start with Step 1 (inventory your users) and work through sequentially. Don't skip steps - each builds on the previous one.
