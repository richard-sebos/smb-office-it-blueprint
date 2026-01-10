# Ansible Control Server Security Flow - SMB Office IT Blueprint

## Document Purpose
This document traces security flows through the Ansible control server in the SMB Office IT Blueprint. It demonstrates how centralized automation, credential management, privilege escalation, and audit logging work together to maintain infrastructure security while enabling efficient operations.

**Target Audience:** Security auditors, compliance officers, IT administrators creating test cases and validation playbooks.

---

## Infrastructure Context

### Ansible Control Server Role
- **Hostname:** `ansible-ctrl`
- **OS:** Rocky Linux 9 (SELinux enforcing)
- **VLAN:** 110 (Management) - `10.0.120.50/24`
- **Purpose:** Centralized infrastructure automation and configuration management
- **Authentication:** Kerberos + SSH key-based for managed hosts
- **Vault:** Ansible Vault (AES256) for secrets management
- **Access:** IT staff only (JIT elevation required for production changes)

### Network Architecture
```
┌─────────────────────────────────────────────────────────────────┐
│                      pfSense Firewall                            │
│  VLAN 110 (Mgmt) │ VLAN 120 (Servers) │ VLAN 130 (Work)         │
└─────────────────────────────────────────────────────────────────┘
         │                    │                     │
         │                    │                     │
    ┌────────────┐      ┌─────────┐           ┌──────────┐
    │ansible-ctrl│      │dc01     │           │laptop-   │
    │10.0.120.50 │      │10.0.120.│           │it-admin-│
    │(Automation)│      │10/11    │           │01       │
    └────────────┘      └─────────┘           └──────────┘
         │
         │ (SSH to ALL managed hosts)
         ├─────────────┬─────────────┬─────────────┬─────────────┐
         │             │             │             │             │
    ┌─────────┐  ┌─────────┐  ┌─────────┐  ┌─────────┐  ┌─────────┐
    │file-srv │  │monitor  │  │print-srv│  │backup-  │  │dev-test │
    │10.0.120.│  │10.0.120.│  │10.0.120.│  │srv      │  │01       │
    │20       │  │40       │  │30       │  │10.0.120.│  │10.0.120.│
    └─────────┘  └─────────┘  └─────────┘  │60       │  │70       │
                                            └─────────┘  └─────────┘
```

**Key Security Boundaries:**
1. **IT Staff → Ansible Control:** SSH with 2FA (Yubikey) + AD authentication
2. **Ansible Control → Managed Hosts:** SSH with key-based auth (separate keys per host class)
3. **Ansible Vault:** AES256 encryption for all secrets (passwords, API keys, certs)
4. **JIT Elevation:** Production playbooks require explicit approval (dual control)
5. **Audit Logging:** All playbook runs logged with full command history

---

## Security Requirements

| Requirement | Implementation | Verification |
|------------|---------------|--------------|
| **Authentication** | SSH key-based (ed25519) + Kerberos for AD integration | Test unauthorized SSH access (should fail) |
| **Authorization** | AD group-based (IT-Staff, IT-Admins) | Test playbook run without IT-Staff membership |
| **Secret Management** | Ansible Vault (AES256) with rotating keys | Test vault decryption with wrong password |
| **Privilege Escalation** | sudo with logging, JIT approval for production | Test production change without approval |
| **Network Isolation** | Management VLAN (110) separate from workstations | Test SSH from workstation VLAN (should fail) |
| **Audit Logging** | All playbook runs logged to monitoring01 | Verify audit trail for configuration change |
| **Change Control** | Git-based workflow with peer review | Test direct playbook execution (blocked) |
| **Secrets Rotation** | Automated 90-day password rotation via playbooks | Verify all managed hosts updated |
| **Immutable Infrastructure** | Playbooks are idempotent, no manual changes | Test manual change detection and reversion |
| **Disaster Recovery** | Ansible control backed up daily to backup-server | Test restore from backup |

---

## Playbook Execution Flow - Detailed Walkthrough

### Scenario 1: IT Admin Runs Playbook to Update File Server Config

**Context:**
- IT Admin: Alex (member of IT-Staff and IT-Admins AD groups)
- Task: Update SMB share permissions on file-server01
- Playbook: `playbooks/file-server-permissions.yml`
- Date/Time: 2026-01-09 15:00:00

**Step-by-Step Security Flow:**

#### Step 1: IT Admin SSH to Ansible Control
```bash
# On laptop-it-admin-01 (10.0.131.20)
$ ssh alex@ansible-ctrl.office.local

# Kerberos authentication
laptop-it-admin-01 → dc01:88
  Request: TGT for alex@OFFICE.LOCAL
  Response: Ticket-granting ticket (TGT)

laptop-it-admin-01 → dc01:88
  Request: Service ticket for host/ansible-ctrl.office.local@OFFICE.LOCAL
  Response: Service ticket (10-hour validity)

laptop-it-admin-01 → ansible-ctrl:22
  SSH connection with GSSAPI authentication
  Kerberos token: <encrypted service ticket>
```

**Firewall Check (pfSense):**
```
Rule: allow-ssh-to-mgmt-from-admin-vlan
  Source: 10.0.131.0/24 (Admin VLAN)
  Destination: 10.0.120.50:22 (ansible-ctrl)
  Action: PASS

Log: Jan 09 15:00:00 pfsense filterlog: PASS,131,10.0.131.20,10.0.120.50,tcp,22
```

**SSH Authentication (ansible-ctrl):**
```
sshd[5678]: Accepted gssapi-with-mic for alex from 10.0.131.20 port 52341 ssh2
sshd[5678]: pam_sss(sshd:session): User alex is member of IT-Staff
sshd[5678]: pam_sss(sshd:session): User alex is member of IT-Admins

# SELinux context assigned
alex's login shell: system_u:unconfined_r:unconfined_t:s0-s0:c0.c1023
```

**2FA Check (Yubikey):**
```
# PAM configuration requires 2FA for admin VLAN connections
pam_yubico[5678]: Yubikey OTP validation successful
  Serial: YK-12345678
  User: alex@OFFICE.LOCAL
  Timestamp: 2026-01-09T15:00:05Z
```

**Timing:** 150ms (Kerberos) + 800ms (2FA) = ~950ms total login time

#### Step 2: Navigate to Playbook Directory
```bash
alex@ansible-ctrl:~$ cd /opt/ansible/playbooks
alex@ansible-ctrl:/opt/ansible/playbooks$ ls -la
total 24
drwxr-x---. 5 ansible-admin IT-Staff    4096 Jan  9 10:00 .
drwxr-xr-x. 8 ansible-admin IT-Staff    4096 Jan  8 14:30 ..
drwxr-x---. 8 ansible-admin IT-Staff    4096 Jan  9 10:00 .git
-rw-r-----. 1 ansible-admin IT-Staff    2048 Jan  9 10:00 file-server-permissions.yml
-rw-r-----. 1 ansible-admin IT-Staff    1536 Jan  8 12:00 domain-controller-config.yml
drwxr-x---. 3 ansible-admin IT-Staff    4096 Jan  7 09:00 roles
drwx------. 2 ansible-admin IT-Staff    4096 Jan  9 10:00 group_vars
```

**SELinux Check:**
```
# Can alex (IT-Staff member) read playbooks?
$ ls -Z file-server-permissions.yml
unconfined_u:object_r:ansible_content_t:s0 file-server-permissions.yml

# SELinux policy allows:
allow unconfined_t ansible_content_t:file { read open };
→ ALLOW (alex is in unconfined_t domain as admin user)
```

#### Step 3: Review Playbook Content
```bash
alex@ansible-ctrl:/opt/ansible/playbooks$ cat file-server-permissions.yml
---
- name: Update File Server SMB Share Permissions
  hosts: file_servers
  become: yes
  vars_files:
    - group_vars/vault.yml  # Encrypted secrets

  tasks:
    - name: Ensure Finance share has correct ACLs
      ansible.builtin.command:
        cmd: >
          setfacl -m g:"{{ finance_group }}":rwx
          /srv/shares/departments/finance
      notify: restart_smb

    - name: Set SELinux context for Finance share
      community.general.sefcontext:
        target: '/srv/shares/departments/finance(/.*)?'
        setype: samba_share_t
        state: present

    - name: Apply SELinux context
      ansible.builtin.command:
        cmd: restorecon -Rv /srv/shares/departments/finance

  handlers:
    - name: restart_smb
      ansible.builtin.service:
        name: smb
        state: restarted
```

**Security Review:**
- Uses `become: yes` (requires sudo on target)
- Loads encrypted vault file (contains `finance_group` variable)
- Makes persistent changes (ACLs, SELinux contexts)
- Classification: **PRODUCTION** (requires JIT approval)

#### Step 4: Check Git Status (Change Control)
```bash
alex@ansible-ctrl:/opt/ansible/playbooks$ git status
On branch main
Your branch is up to date with 'origin/main'.

nothing to commit, working tree clean

alex@ansible-ctrl:/opt/ansible/playbooks$ git log -1
commit a1b2c3d4e5f6 (HEAD -> main, origin/main)
Author: alex@office.local
Date:   Thu Jan 9 10:00:00 2026 +0000

    Update file server ACLs for Q1 audit requirements

    Reviewed-by: michael@office.local
    Approved-by: sarah@office.local (IT Manager)
    Ticket: IT-2026-0015
```

**Change Control Verification:**
- Playbook committed to Git ✓
- Peer review by Michael ✓
- Management approval by Sarah ✓
- Linked to ticket IT-2026-0015 ✓

#### Step 5: Request JIT Elevation (Production Change)
```bash
alex@ansible-ctrl:/opt/ansible/playbooks$ sudo -v
[sudo] password for alex:

# JIT approval check via custom sudo plugin
sudo: JIT approval required for production playbook execution
sudo: Requesting approval from IT Manager...

# Approval request sent via Slack/Email to sarah@office.local
# Subject: JIT Approval Request - alex - file-server-permissions.yml
# Expires in: 5 minutes

# Sarah approves via mobile app (2FA with Yubikey)
sudo: Approval granted by sarah@office.local at 2026-01-09T15:02:00Z
sudo: Elevation valid for 1 hour
```

**Auditd Log:**
```
type=USER_AUTH msg=audit(1736436120.456:5678): pid=5679 uid=1002 auid=1002
  ses=10 subj=unconfined_u:unconfined_r:unconfined_t:s0-s0:c0.c1023
  msg='op=PAM:authentication grantors=pam_sss,pam_jit_approval acct="alex"
  exe="/usr/bin/sudo" hostname=ansible-ctrl addr=10.0.131.20 terminal=pts/0
  res=success'
  key="jit_elevation"
```

**Timing:** 120 seconds (waiting for Sarah's approval)

#### Step 6: Decrypt Ansible Vault
```bash
alex@ansible-ctrl:/opt/ansible/playbooks$ ansible-vault view group_vars/vault.yml
Vault password:

# Vault contents (decrypted in memory only):
---
finance_group: "OFFICE\\Finance"
finance_share_password: "Secure123!XyZ"
backup_encryption_key: "AES256:a1b2c3d4..."
monitoring_api_token: "Bearer eyJhbGc..."
```

**Vault Security:**
- Password stored in alex's password manager (1Password with Yubikey unlock)
- Vault file encrypted at rest (AES256)
- Decryption happens in memory only (never written to disk in plaintext)
- Vault password rotated every 90 days

**Auditd Log:**
```
type=CRYPTO_KEY_USER msg=audit(1736436150.789:5680):
  pid=5680 uid=1002 auid=1002 ses=10
  subj=unconfined_u:unconfined_r:unconfined_t:s0-s0:c0.c1023
  msg='op=crypto-vault-decrypt key="group_vars/vault.yml"
  exe="/usr/bin/ansible-vault" res=success'
  key="vault_access"
```

#### Step 7: Execute Playbook
```bash
alex@ansible-ctrl:/opt/ansible/playbooks$ ansible-playbook \
  --ask-vault-pass \
  -i inventory/production/hosts.yml \
  file-server-permissions.yml

Vault password: ********

PLAY [Update File Server SMB Share Permissions] ********************************

TASK [Gathering Facts] *********************************************************
ok: [file-server01]

TASK [Ensure Finance share has correct ACLs] **********************************
changed: [file-server01]

TASK [Set SELinux context for Finance share] **********************************
ok: [file-server01]

TASK [Apply SELinux context] ***************************************************
changed: [file-server01]

RUNNING HANDLER [restart_smb] **************************************************
changed: [file-server01]

PLAY RECAP *********************************************************************
file-server01              : ok=5    changed=3    unreachable=0    failed=0
```

**Connection Flow (ansible-ctrl → file-server01):**
```
ansible-ctrl (10.0.120.50) → file-server01 (10.0.120.20)
  Protocol: SSH (port 22)
  Authentication: SSH key (/home/alex/.ssh/file_servers_ed25519)
  User: ansible (dedicated automation account on target)

# SSH key authentication
ansible-ctrl → file-server01:22
  SSH_MSG_USERAUTH_REQUEST (publickey)
  Key: ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAA... (ansible-file-servers)

file-server01 → ansible-ctrl
  SSH_MSG_USERAUTH_SUCCESS

# Privilege escalation on target
ansible@file-server01 → sudo -i
  /etc/sudoers.d/ansible:
    ansible ALL=(ALL) NOPASSWD: ALL

  Reason for NOPASSWD: ansible account is locked (no password, key-only)
  and can only be accessed from ansible-ctrl (firewall restriction)
```

**Firewall Rules:**
```
# pfSense: Allow ansible-ctrl SSH to all managed hosts
allow-ansible-ssh-outbound
  Source: 10.0.120.50/32 (ansible-ctrl)
  Destination: 10.0.120.0/24, 10.0.130.0/24, 10.0.131.0/24
  Port: 22
  Action: PASS

# file-server01 firewalld: Only allow SSH from ansible-ctrl
firewall-cmd --permanent --add-rich-rule='
  rule family="ipv4"
  source address="10.0.120.50/32"
  service name="ssh"
  accept'

firewall-cmd --permanent --zone=server --remove-service=ssh  # Remove default
```

#### Step 8: Task Execution on file-server01

**Task 1: Set ACLs**
```bash
# Executed on file-server01 as root (via sudo)
setfacl -m g:"OFFICE\\Finance":rwx /srv/shares/departments/finance

# SELinux check
Source context: unconfined_u:unconfined_r:unconfined_t:s0 (root via ansible)
Target context: system_u:object_r:samba_share_t:s0 (/srv/shares/departments/finance)
Class: dir
Permission: setattr

Policy: allow unconfined_t samba_share_t:dir setattr;
Result: ALLOW
```

**Auditd Log (file-server01):**
```
type=SYSCALL msg=audit(1736436170.123:7890): arch=c000003e syscall=188 success=yes
  comm="setfacl" exe="/usr/bin/setfacl"
  subj=unconfined_u:unconfined_r:unconfined_t:s0
  key="finance_share_modify"

type=PATH msg=audit(1736436170.123:7890):
  name="/srv/shares/departments/finance"
  objtype=NORMAL cap_fp=0 cap_fi=0 cap_fe=0 cap_fver=0 cap_frootid=0
```

**Task 2: Restart SMB Service**
```bash
# Executed on file-server01
systemctl restart smb

# SELinux check
Source context: unconfined_u:unconfined_r:unconfined_t:s0
Target context: system_u:object_r:smbd_exec_t:s0 (/usr/sbin/smbd)
Action: execute, restart service

Policy: allow unconfined_t smbd_exec_t:file execute;
        allow unconfined_t init_t:service { start stop restart };
Result: ALLOW
```

**Timing:** 45 seconds total (ACL update 2s, SELinux context 3s, SMB restart 40s)

#### Step 9: Playbook Completion and Logging

**Ansible Log (ansible-ctrl):**
```bash
# /var/log/ansible/ansible.log
2026-01-09 15:03:00,456 - ansible-playbook - INFO - Playbook started
  User: alex@OFFICE.LOCAL
  Playbook: file-server-permissions.yml
  Inventory: inventory/production/hosts.yml
  Vault: group_vars/vault.yml (decrypted successfully)

2026-01-09 15:03:45,789 - ansible-playbook - INFO - Playbook completed
  Result: SUCCESS
  Tasks: 5 ok, 3 changed, 0 failed
  Duration: 45 seconds
```

**Rsyslog Forward to monitoring01:**
```
# All Ansible logs forwarded in real-time
Jan 09 15:03:45 ansible-ctrl ansible-playbook[5680]:
  PLAY_RECAP: file-server01 ok=5 changed=3 failed=0
  user=alex@OFFICE.LOCAL playbook=file-server-permissions.yml
  duration=45s result=SUCCESS

→ rsyslog (TCP/TLS) → monitoring01:514
→ Logstash parses → Elasticsearch indexes
→ Kibana dashboard: "Infrastructure Changes" updated
```

**Wazuh SIEM Alert:**
```
Rule 100200: Infrastructure configuration change detected
  Severity: Informational (approved change)
  User: alex@OFFICE.LOCAL
  Target: file-server01
  Change: SMB share ACLs modified
  Approval: sarah@office.local (JIT-2026-01-09-001)
  Ticket: IT-2026-0015
  Action: Log for audit trail (no remediation needed)
```

**Total Time:** ~3 minutes (including JIT approval wait)

---

### Scenario 2: Unauthorized Playbook Execution Attempt

**Context:**
- User: John (General Employee, NOT in IT-Staff group)
- John somehow obtained SSH access to ansible-ctrl (credential compromise scenario)
- Attempts to run playbook to elevate privileges

**Step-by-Step Flow:**

#### Step 1: John SSH to Ansible Control (Compromised Credentials)
```bash
# On laptop-john-01 (10.0.130.20)
$ ssh john@ansible-ctrl.office.local
ssh: connect to host ansible-ctrl.office.local port 22: Connection refused
```

**Firewall Block (pfSense):**
```
Rule: default-deny-workstation-to-mgmt
  Source: 10.0.130.0/24 (Workstation VLAN)
  Destination: 10.0.120.50:22 (ansible-ctrl)
  Action: BLOCK

Log: Jan 09 15:10:00 pfsense filterlog: BLOCK,130,10.0.130.20,10.0.120.50,tcp,22
```

**Result:** Connection blocked at network layer (firewall)

#### Step 2: John Pivots Through IT Admin Workstation (Lateral Movement)
```bash
# Assume John compromised laptop-it-admin-01 (10.0.131.20)
$ ssh john@ansible-ctrl.office.local
john@ansible-ctrl.office.local's password: ******

# SSH authentication
ansible-ctrl sshd[6789]: Failed password for john from 10.0.131.20 port 54321 ssh2
ansible-ctrl sshd[6789]: pam_sss: User john is NOT member of IT-Staff
ansible-ctrl sshd[6789]: Connection closed by 10.0.131.20 port 54321 [preauth]
```

**PAM Configuration (/etc/pam.d/sshd):**
```
# Require IT-Staff group membership for SSH access
account required pam_access.so
account required pam_sss.so

# /etc/security/access.conf
# Only IT-Staff and IT-Admins can access ansible-ctrl
+ : (IT-Staff) (IT-Admins) : ALL
- : ALL : ALL
```

**Result:** Authentication failed (not in required AD group)

**Auditd Log:**
```
type=USER_AUTH msg=audit(1736436600.123:5690): pid=6789 uid=0 auid=4294967295
  ses=4294967295 subj=system_u:system_r:sshd_t:s0-s0:c0.c1023
  msg='op=PAM:authentication grantors=? acct="john" exe="/usr/sbin/sshd"
  hostname=ansible-ctrl addr=10.0.131.20 terminal=ssh res=failed'
  key="unauthorized_ssh"
```

**Wazuh SIEM Alert:**
```
Rule 100210: Unauthorized SSH attempt to Ansible control server
  Severity: High
  User: john (not in IT-Staff)
  Source: 10.0.131.20 (IT admin workstation - COMPROMISED?)
  Action: Alert security team + investigate laptop-it-admin-01
  MITRE: T1021.004 (Remote Services: SSH)
```

---

### Scenario 3: Automated Secret Rotation

**Context:**
- Scheduled task: Rotate all managed host passwords every 90 days
- Playbook: `playbooks/rotate-passwords.yml`
- Execution: Automated via cron (no human interaction)

**Step-by-Step Flow:**

#### Step 1: Cron Job Triggers
```bash
# /etc/cron.d/ansible-automation
# Run password rotation playbook quarterly (every 90 days)
0 2 1 */3 * ansible-automation /opt/ansible/scripts/run-password-rotation.sh

# run-password-rotation.sh
#!/bin/bash
set -euo pipefail

# Logging
exec 1> >(logger -s -t ansible-automation) 2>&1

echo "Starting automated password rotation..."

# Unlock vault with automation key (stored in TPM)
VAULT_PASS=$(tpm2_unseal -c 0x81000001)

# Run playbook
ansible-playbook \
  --vault-password-file <(echo "$VAULT_PASS") \
  -i /opt/ansible/inventory/production/hosts.yml \
  /opt/ansible/playbooks/rotate-passwords.yml

echo "Password rotation completed successfully"
```

**Security Considerations:**
- Automation user: `ansible-automation` (dedicated account, no interactive login)
- Vault password stored in TPM (Trusted Platform Module)
- Playbook runs at 2 AM (minimal user impact)
- All password changes logged and audited

#### Step 2: Generate New Passwords
```yaml
# playbooks/rotate-passwords.yml
---
- name: Rotate Managed Host Passwords
  hosts: all
  become: yes
  vars:
    password_length: 32
    password_complexity: "uppercase,lowercase,digits,special"

  tasks:
    - name: Generate new random password
      set_fact:
        new_password: "{{ lookup('password', '/dev/null length={{ password_length }} chars={{ password_complexity }}') }}"

    - name: Update local ansible user password
      ansible.builtin.user:
        name: ansible
        password: "{{ new_password | password_hash('sha512') }}"
        update_password: always

    - name: Store new password in vault
      delegate_to: localhost
      ansible.builtin.lineinfile:
        path: /opt/ansible/group_vars/vault.yml
        regexp: "^{{ inventory_hostname }}_ansible_password:"
        line: "{{ inventory_hostname }}_ansible_password: {{ new_password }}"
        state: present
      notify: encrypt_vault

  handlers:
    - name: encrypt_vault
      delegate_to: localhost
      ansible.builtin.command:
        cmd: ansible-vault encrypt /opt/ansible/group_vars/vault.yml
        stdin: "{{ vault_password }}"
```

#### Step 3: Update Passwords on All Managed Hosts
```
ansible-ctrl → dc01: Update ansible user password
ansible-ctrl → dc02: Update ansible user password
ansible-ctrl → file-server01: Update ansible user password
ansible-ctrl → monitoring01: Update ansible user password
ansible-ctrl → print-server01: Update ansible user password
ansible-ctrl → backup-server: Update ansible user password
ansible-ctrl → dev-test01: Update ansible user password

Total hosts: 7 servers + ~20 workstations = 27 hosts
Timing: ~5 seconds per host = 135 seconds total
```

**Auditd Log (per host):**
```
# On file-server01
type=USER_CHAUTHTOK msg=audit(1736477200.456:8901):
  pid=7890 uid=0 auid=4294967295 ses=4294967295
  subj=unconfined_u:unconfined_r:unconfined_t:s0
  msg='op=PAM:chauthtok grantors=pam_unix acct="ansible"
  exe="/usr/sbin/usermod" hostname=? addr=? terminal=? res=success'
  key="password_change"
```

#### Step 4: Verification and Rollback Preparation
```yaml
- name: Verify new passwords work
  hosts: all
  gather_facts: no

  tasks:
    - name: Test SSH with new password
      ansible.builtin.wait_for_connection:
        timeout: 30
      register: connection_test

    - name: Rollback if connection fails
      when: connection_test is failed
      block:
        - name: Restore old password from backup
          ansible.builtin.user:
            name: ansible
            password: "{{ old_password_hash }}"

        - name: Alert IT team of rollback
          delegate_to: localhost
          ansible.builtin.mail:
            to: it-team@office.local
            subject: "ALERT: Password rotation rollback on {{ inventory_hostname }}"
            body: "New password failed verification. Rolled back to previous password."
```

**Result:** All 27 hosts successfully updated, no rollbacks needed

**Completion Log:**
```
2026-01-09 02:03:15,789 - ansible-automation - INFO
  Password rotation completed successfully
  Hosts updated: 27/27
  Failed: 0
  Duration: 3 minutes 15 seconds
  Next rotation: 2026-04-09 02:00:00
```

---

## SELinux Policy Enforcement

### Ansible Process Confinement
```bash
# Check ansible-playbook SELinux context
$ ps -eZ | grep ansible
unconfined_u:unconfined_r:unconfined_t:s0 5680 pts/0 00:00:02 ansible-playbook

# Note: ansible-playbook runs in unconfined_t because it needs broad access
# to manage multiple hosts and execute varied tasks
# However, the system is still protected by:
# 1. Network firewall rules (pfSense + firewalld)
# 2. SSH key-based authentication (no password login)
# 3. sudo logging and JIT approval
# 4. Comprehensive auditd monitoring
```

**Ansible Vault File Protection:**
```bash
$ ls -Z group_vars/vault.yml
unconfined_u:object_r:ansible_content_t:s0 group_vars/vault.yml

# Only ansible-admin and IT-Staff group can read vault files
$ getfacl group_vars/vault.yml
# file: group_vars/vault.yml
# owner: ansible-admin
# group: IT-Staff
user::rw-
group::r--
other::---
```

---

## Firewall Configuration

### Ansible Control Server Inbound Rules
```bash
# Zone: management (VLAN 110)
firewall-cmd --permanent --zone=management --add-service=ssh

# Allow SSH only from Admin VLAN
firewall-cmd --permanent --zone=management --add-rich-rule='
  rule family="ipv4"
  source address="10.0.131.0/24"
  service name="ssh"
  accept'

# Block all other SSH attempts
firewall-cmd --permanent --zone=management --add-rich-rule='
  rule family="ipv4"
  service name="ssh"
  reject'

# Default deny
firewall-cmd --permanent --zone=management --set-target=DROP

firewall-cmd --reload
```

### Ansible Control Server Outbound Rules
```bash
# Allow SSH to all managed hosts
firewall-cmd --permanent --direct --add-rule ipv4 filter OUTPUT 0 \
  -p tcp --dport 22 -j ACCEPT

# Allow Kerberos to domain controllers
firewall-cmd --permanent --direct --add-rule ipv4 filter OUTPUT 0 \
  -d 10.0.120.10 -p tcp --dport 88 -j ACCEPT
firewall-cmd --permanent --direct --add-rule ipv4 filter OUTPUT 0 \
  -d 10.0.120.11 -p tcp --dport 88 -j ACCEPT

# Allow rsyslog to monitoring server
firewall-cmd --permanent --direct --add-rule ipv4 filter OUTPUT 0 \
  -d 10.0.120.40 -p tcp --dport 514 -j ACCEPT

# Allow Git operations (for playbook updates)
firewall-cmd --permanent --direct --add-rule ipv4 filter OUTPUT 0 \
  -p tcp --dport 443 -j ACCEPT  # GitHub/GitLab via HTTPS

# Block all other outbound (explicit allowlist)
firewall-cmd --permanent --direct --add-rule ipv4 filter OUTPUT 1 -j DROP
```

---

## Auditd Rules

### Ansible Activity Auditing
```bash
# /etc/audit/rules.d/ansible.rules

# Watch all playbook executions
-w /usr/bin/ansible-playbook -p x -k ansible_playbook_exec

# Watch vault operations
-w /usr/bin/ansible-vault -p x -k ansible_vault_access

# Watch playbook directory
-w /opt/ansible/playbooks/ -p rwa -k playbook_changes

# Watch inventory directory
-w /opt/ansible/inventory/ -p rwa -k inventory_changes

# Watch vault files
-w /opt/ansible/group_vars/vault.yml -p rwa -k vault_file_access

# Watch SSH key directory
-w /home/ansible-automation/.ssh/ -p rwa -k ansible_ssh_keys

# Audit all sudo commands (JIT elevation)
-a always,exit -F arch=b64 -S execve -F exe=/usr/bin/sudo -k sudo_commands

# Audit password changes (automated rotation)
-a always,exit -F arch=b64 -S execve -F exe=/usr/sbin/usermod -k password_changes
-a always,exit -F arch=b64 -S execve -F exe=/usr/bin/passwd -k password_changes

# Network connections (SSH to managed hosts)
-a always,exit -F arch=b64 -S connect -F a2=16 -k ansible_ssh_connections
```

### Example Audit Log Output
```
# Playbook execution
type=EXECVE msg=audit(1736436150.123:5678): argc=5
  a0="ansible-playbook" a1="--ask-vault-pass"
  a2="-i" a3="inventory/production/hosts.yml"
  a4="file-server-permissions.yml"

type=SYSCALL msg=audit(1736436150.123:5678): arch=c000003e syscall=59 success=yes
  exit=0 ppid=5677 pid=5680 auid=1002 uid=1002 gid=1002 euid=1002 suid=1002
  fsuid=1002 egid=1002 sgid=1002 fsgid=1002 tty=pts0 ses=10
  comm="ansible-playbook" exe="/usr/bin/ansible-playbook"
  subj=unconfined_u:unconfined_r:unconfined_t:s0-s0:c0.c1023
  key="ansible_playbook_exec"

# JIT elevation
type=USER_CMD msg=audit(1736436120.456:5679): pid=5679 uid=1002 auid=1002
  ses=10 msg='user=alex@OFFICE.LOCAL pwd=/opt/ansible/playbooks
  cmd=/usr/bin/ansible-playbook exe="/usr/bin/sudo"
  approval=sarah@OFFICE.LOCAL res=success'
  key="jit_elevation"
```

---

## Ansible Configuration

### Main Configuration (/etc/ansible/ansible.cfg)
```ini
[defaults]
# Inventory
inventory = /opt/ansible/inventory/production/hosts.yml
host_key_checking = False  # SSH keys managed separately

# Logging
log_path = /var/log/ansible/ansible.log
log_level = INFO

# Performance
forks = 10  # Parallel task execution
gathering = smart
fact_caching = jsonfile
fact_caching_connection = /tmp/ansible_fact_cache
fact_caching_timeout = 3600

# Security
vault_password_file = /opt/ansible/.vault_pass  # Automated runs only
ask_vault_pass = False  # Prompt for interactive runs
command_warnings = True
deprecation_warnings = True

# SSH settings
remote_user = ansible
private_key_file = /home/ansible-automation/.ssh/managed_hosts_ed25519
timeout = 30
ssh_args = -o ControlMaster=auto -o ControlPersist=60s

[privilege_escalation]
become = True
become_method = sudo
become_user = root
become_ask_pass = False  # SSH key-based, no password needed

[ssh_connection]
ssh_args = -o ControlMaster=auto -o ControlPersist=60s -o StrictHostKeyChecking=no
control_path = /tmp/ansible-ssh-%%h-%%p-%%r
pipelining = True  # Performance optimization
```

### Inventory Configuration (/opt/ansible/inventory/production/hosts.yml)
```yaml
---
all:
  vars:
    ansible_user: ansible
    ansible_ssh_private_key_file: /home/ansible-automation/.ssh/managed_hosts_ed25519
    ansible_become: yes
    ansible_become_method: sudo

  children:
    domain_controllers:
      hosts:
        dc01:
          ansible_host: 10.0.120.10
        dc02:
          ansible_host: 10.0.120.11

    file_servers:
      hosts:
        file-server01:
          ansible_host: 10.0.120.20

    monitoring_servers:
      hosts:
        monitoring01:
          ansible_host: 10.0.120.40

    print_servers:
      hosts:
        print-server01:
          ansible_host: 10.0.120.30

    backup_servers:
      hosts:
        backup-server:
          ansible_host: 10.0.120.60

    dev_servers:
      hosts:
        dev-test01:
          ansible_host: 10.0.120.70

    workstations:
      children:
        general_workstations:
          hosts:
            laptop-john-01:
              ansible_host: 10.0.130.20
            laptop-emily-01:
              ansible_host: 10.0.130.21
            # ... (20 more workstations)

        admin_workstations:
          hosts:
            laptop-it-admin-01:
              ansible_host: 10.0.131.20
            laptop-sarah-01:
              ansible_host: 10.0.131.21
```

---

## Rsyslog Configuration

### Forward Ansible Logs to Monitoring Server
```bash
# /etc/rsyslog.d/ansible-forward.conf

# Load modules
module(load="imfile" PollingInterval="10")

# Ansible playbook execution log
input(type="imfile"
      File="/var/log/ansible/ansible.log"
      Tag="ansible-playbook"
      Severity="info"
      Facility="local5"
      reopenOnTruncate="on")

# System audit log (contains ansible activity)
input(type="imfile"
      File="/var/log/audit/audit.log"
      Tag="auditd"
      Severity="info"
      Facility="local6"
      reopenOnTruncate="on")

# Filter: Only forward ansible-related audit events
if $msg contains 'ansible' then {
  action(type="omfwd"
         target="10.0.120.40"
         port="514"
         protocol="tcp"
         StreamDriver="gtls"
         StreamDriverMode="1"
         StreamDriverAuthMode="x509/name"
         StreamDriverPermittedPeers="monitoring01.office.local")
}

# Forward all Ansible logs
if $syslogtag == 'ansible-playbook' then {
  action(type="omfwd"
         target="10.0.120.40"
         port="514"
         protocol="tcp"
         StreamDriver="gtls"
         StreamDriverMode="1"
         StreamDriverAuthMode="x509/name"
         StreamDriverPermittedPeers="monitoring01.office.local")
}
```

---

## Test Cases for Validation

### Test 1: Authorized Playbook Execution
```bash
# Preconditions:
# - Alex is member of IT-Staff and IT-Admins
# - Playbook has peer review and management approval
# - JIT elevation granted

# Test:
alex@ansible-ctrl$ ansible-playbook \
  --ask-vault-pass \
  -i inventory/production/hosts.yml \
  playbooks/file-server-permissions.yml

# Expected:
# ✓ Vault decryption succeeds
# ✓ SSH connections to managed hosts succeed
# ✓ Tasks execute successfully
# ✓ Changes applied to file-server01
# ✓ All activity logged to monitoring01

# Validation:
# On monitoring01 (Elasticsearch):
GET /ansible-logs-*/_search
{
  "query": {
    "bool": {
      "must": [
        {"match": {"user": "alex@OFFICE.LOCAL"}},
        {"match": {"playbook": "file-server-permissions.yml"}},
        {"match": {"result": "SUCCESS"}}
      ]
    }
  }
}
# Result: 1 document with full execution details
```

### Test 2: Unauthorized SSH Access Attempt
```bash
# Preconditions:
# - John is NOT member of IT-Staff
# - John attempts SSH from workstation VLAN

# Test:
john@laptop-john-01$ ssh john@ansible-ctrl.office.local

# Expected:
# ✗ Connection refused (firewall block)
# ✓ pfSense logs blocked connection
# ✓ Alert generated for unauthorized access attempt

# Validation:
# On pfSense:
Status > System Logs > Firewall
  Filter: destination=10.0.120.50 AND action=BLOCK
  Result: Entry showing 10.0.130.20 → 10.0.120.50:22 BLOCKED

# On monitoring01 (Wazuh):
Rule 100210: Unauthorized SSH attempt to Ansible control server
  User: john
  Source: 10.0.130.20
```

### Test 3: Vault Decryption with Wrong Password
```bash
# Preconditions:
# - Alex has correct SSH access
# - Uses wrong vault password

# Test:
alex@ansible-ctrl$ ansible-vault view group_vars/vault.yml
Vault password: ********  # Wrong password

# Expected:
# ✗ Decryption fails
# ✓ Error message displayed
# ✓ Failed attempt logged

# Validation:
ERROR! Decryption failed (no vault secrets were found that could decrypt)
Attempted 1 times

# Audit log:
$ ausearch -k vault_access -i | tail -5
type=CRYPTO_KEY_USER ... msg='op=crypto-vault-decrypt
  key="group_vars/vault.yml" res=failed' key="vault_access"
```

### Test 4: JIT Elevation Without Approval
```bash
# Preconditions:
# - Alex attempts production playbook without requesting JIT elevation
# - No approval from IT Manager

# Test:
alex@ansible-ctrl$ ansible-playbook playbooks/domain-controller-config.yml

# Expected:
# ✗ sudo fails (no JIT approval)
# ✓ Playbook execution blocked
# ✓ Alert generated

# Validation:
TASK [Update DC registry settings] *********************************************
fatal: [dc01]: FAILED! => {
  "msg": "Missing sudo password. JIT approval required for production changes."
}

# Audit log:
type=USER_CMD ... msg='user=alex@OFFICE.LOCAL
  cmd=/usr/bin/ansible-playbook res=failed reason=no_jit_approval'
```

### Test 5: Automated Password Rotation
```bash
# Preconditions:
# - Cron job scheduled for 2026-01-09 02:00:00
# - Automation vault key stored in TPM

# Test (simulated):
ansible-automation@ansible-ctrl$ /opt/ansible/scripts/run-password-rotation.sh

# Expected:
# ✓ Vault unlocked via TPM
# ✓ New passwords generated (32 chars, complex)
# ✓ All 27 managed hosts updated
# ✓ Vault re-encrypted with new passwords
# ✓ Success log generated

# Validation:
# Check log:
$ journalctl -t ansible-automation -n 50 | grep "Password rotation"
Jan 09 02:03:15 ansible-ctrl ansible-automation: Password rotation completed successfully
  Hosts updated: 27/27 Failed: 0 Duration: 3m15s

# Verify new password works:
$ ssh -i /home/ansible-automation/.ssh/managed_hosts_ed25519 ansible@file-server01
# Should succeed with new password (key-based, password in authorized_keys updated)
```

### Test 6: Playbook Execution Without Git Review
```bash
# Preconditions:
# - Alex modifies playbook directly without committing to Git
# - Pre-commit hook enforces Git workflow

# Test:
alex@ansible-ctrl$ vim playbooks/test-playbook.yml  # Make changes
alex@ansible-ctrl$ ansible-playbook playbooks/test-playbook.yml

# Expected:
# ✗ Pre-execution check fails (playbook not in Git)
# ✓ Execution blocked
# ✓ Alert generated

# Validation (if pre-commit hook implemented):
ERROR: Playbook 'test-playbook.yml' has uncommitted changes.
All playbooks must be committed to Git and peer-reviewed before execution.

git diff playbooks/test-playbook.yml:
  +     # Unauthorized change
```

---

## Compliance Benefits

### SOX (Sarbanes-Oxley) Compliance
**Requirement:** Change control, segregation of duties, audit trails

**Implementation:**
- **Change Control:** All playbooks stored in Git with peer review and management approval
- **Segregation of Duties:**
  - IT Staff can write playbooks (development)
  - IT Managers approve production changes (approval)
  - Ansible executes changes (automation)
  - Separate individuals for each role
- **Audit Trails:** All playbook executions logged with:
  - Who executed (alex@OFFICE.LOCAL)
  - What changed (file-server-permissions.yml)
  - When (2026-01-09T15:03:45Z)
  - Approval (sarah@OFFICE.LOCAL via JIT)
  - Result (SUCCESS, 3 changed)
- **7-Year Retention:** All logs forwarded to monitoring01, retained in Elasticsearch

**Compliance Evidence:**
```bash
# Query all infrastructure changes for SOX audit
GET /ansible-logs-*/_search
{
  "query": {
    "bool": {
      "must": [
        {"range": {"@timestamp": {"gte": "2025-01-01", "lte": "2025-12-31"}}},
        {"match": {"result": "SUCCESS"}}
      ]
    }
  },
  "aggs": {
    "by_user": {"terms": {"field": "user.keyword"}},
    "by_target": {"terms": {"field": "target_host.keyword"}}
  }
}

# Result: Complete audit trail of all infrastructure changes with segregation of duties
```

---

### NIST 800-53 (Federal Information Security Management Act)
**Requirement:** CM-3 (Configuration Change Control), CM-6 (Configuration Settings)

**Implementation:**
- **CM-3.1:** Configuration changes documented in Git with commit messages
- **CM-3.2:** Approval required for production changes (JIT elevation)
- **CM-3.4:** Audit record of configuration changes (ansible.log + auditd)
- **CM-6.1:** Configuration baseline defined in playbooks (idempotent, declarative)
- **CM-6.2:** Automated compliance checks (playbook validates current state)

**Compliance Evidence:**
- Git repository with full commit history
- JIT approval logs linked to change tickets
- Ansible ensures configuration drift detection and remediation

---

### PCI-DSS (Payment Card Industry Data Security Standard)
**Requirement:** 10.2 (Audit Trails), 10.3 (Audit Trail Entries)

**Implementation:**
- **10.2.2:** All administrative actions logged (ansible-playbook executions)
- **10.2.5:** Unauthorized access attempts logged (SSH failures, JIT denials)
- **10.3.1:** User identification (alex@OFFICE.LOCAL)
- **10.3.2:** Type of event (playbook execution, password rotation)
- **10.3.3:** Date and time (2026-01-09T15:03:45Z)
- **10.3.4:** Success or failure (SUCCESS, 3 changed, 0 failed)
- **10.3.5:** Origination of event (ansible-ctrl, 10.0.120.50)
- **10.3.6:** Identity of affected resource (file-server01)

**Compliance Evidence:**
- Comprehensive Ansible logs with all PCI-DSS 10.3 fields
- Centralized log collection (monitoring01)
- Tamper-proof logs (rsyslog TLS, immutable storage)

---

## Wazuh SIEM Rules for Ansible Security

### Rule 1: Unauthorized Ansible Access Attempt
```xml
<!-- /var/ossec/etc/rules/local_rules.xml on monitoring01 -->
<group name="ansible,authentication,">
  <rule id="100210" level="12">
    <if_sid>5503</if_sid>  <!-- SSH failed login -->
    <hostname>ansible-ctrl</hostname>
    <description>Unauthorized SSH attempt to Ansible control server</description>
    <mitre>
      <id>T1021.004</id>  <!-- Remote Services: SSH -->
    </mitre>
  </rule>
</group>
```

**Trigger:** SSH failed login to ansible-ctrl
**Action:** High-severity alert + investigate source workstation

---

### Rule 2: Playbook Execution Without JIT Approval
```xml
<rule id="100211" level="14">
  <if_sid>0</if_sid>
  <match>ansible-playbook</match>
  <match>res=failed</match>
  <match>reason=no_jit_approval</match>
  <description>Production playbook executed without JIT approval</description>
  <mitre>
    <id>T1078.003</id>  <!-- Valid Accounts: Local Accounts -->
  </mitre>
</rule>
```

**Trigger:** Playbook execution attempt without JIT approval
**Action:** Critical alert + review user privileges

---

### Rule 3: Vault Access by Non-IT User
```xml
<rule id="100212" level="13">
  <if_sid>0</if_sid>
  <match>ansible-vault</match>
  <field name="auid">!1002,!1003,!1004</field>  <!-- Not IT Staff UIDs -->
  <description>Ansible Vault accessed by non-IT user (possible privilege escalation)</description>
  <mitre>
    <id>T1552.001</id>  <!-- Unsecured Credentials: Credentials In Files -->
  </mitre>
</rule>
```

**Trigger:** Vault file accessed by user outside IT-Staff group
**Action:** Critical alert + kill session + investigate

---

### Rule 4: Mass Configuration Changes
```xml
<rule id="100220" level="10">
  <if_sid>0</if_sid>
  <match>PLAY RECAP</match>
  <field name="changed_tasks">10</field>  <!-- >10 changes -->
  <description>Mass infrastructure configuration changes detected</description>
  <mitre>
    <id>T1496</id>  <!-- Resource Hijacking (if unauthorized) -->
  </mitre>
</rule>
```

**Trigger:** Playbook execution with >10 changed tasks
**Action:** Informational alert (review for authorization) + verify change ticket

---

### Rule 5: Password Rotation Failure
```xml
<rule id="100221" level="12">
  <if_sid>0</if_sid>
  <match>ansible-automation</match>
  <match>Password rotation</match>
  <match>failed</match>
  <description>Automated password rotation failed (security risk)</description>
  <mitre>
    <id>T1098</id>  <!-- Account Manipulation -->
  </mitre>
</rule>
```

**Trigger:** Automated password rotation playbook fails
**Action:** High-severity alert + manual password rotation required

---

## Summary

This document demonstrates comprehensive automation security with:

1. **Centralized Control:**
   - Single ansible-ctrl server manages all 27 hosts
   - Git-based workflow with peer review and approval
   - JIT elevation for production changes (dual control)

2. **Defense in Depth:**
   - Firewall: Network segmentation (Admin VLAN only)
   - PAM: AD group-based access control (IT-Staff required)
   - SSH Keys: Key-based authentication (no passwords)
   - 2FA: Yubikey required for admin VLAN access
   - Ansible Vault: AES256 encryption for all secrets
   - Auditd: Comprehensive logging of all activity

3. **Secret Management:**
   - Ansible Vault encrypts all sensitive data
   - Vault password stored in TPM for automation
   - Automated 90-day password rotation
   - No plaintext secrets in playbooks or logs

4. **Change Control:**
   - All playbooks committed to Git
   - Peer review required (michael@office.local)
   - Management approval required (sarah@office.local)
   - Change tickets linked to all production changes

5. **Compliance:**
   - SOX: Change control, segregation of duties, audit trails
   - NIST 800-53: Configuration change control (CM-3, CM-6)
   - PCI-DSS: Comprehensive audit logs (10.2, 10.3)
   - 7-year log retention

6. **Threat Detection:**
   - Wazuh SIEM rules for unauthorized access
   - Automated response to suspicious activity
   - Real-time alerting for failed JIT approvals
   - Log correlation across infrastructure

**Total Security Layers for Playbook Execution:** 8
1. pfSense firewall (Admin VLAN isolation)
2. firewalld (host-based firewall)
3. PAM (AD group membership - IT-Staff)
4. 2FA (Yubikey for admin VLAN)
5. SSH key authentication (ed25519)
6. JIT elevation (management approval)
7. Ansible Vault (AES256 encryption)
8. Auditd logging + SIEM monitoring

**Key Insight:** The ansible-ctrl server is the most privileged system in the infrastructure (can access all hosts), making it a high-value target. Defense in depth with multiple security layers ensures that even if one layer is bypassed, others prevent unauthorized access.

---

**Document Version:** 1.0
**Last Updated:** 2026-01-10
**Author:** IT Security Team
**Next Review:** 2026-07-10 (6 months)
