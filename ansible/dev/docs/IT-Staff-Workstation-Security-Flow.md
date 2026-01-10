# IT Staff Workstation Security Flow
## Dual Identity Model: Normal User + Just-In-Time (JIT) Privileged Access

---

## Use Case: IT Administrator Workstation

**User:** Mike (IT Administrator)
- **Normal Identity:** mike@corp.company.local (daily work, email, documentation)
- **JIT Privileged Identity:** mike-admin@corp.company.local (elevated access for maintenance)
- **Location:** IT office area (secured, badge access)
- **Risk Level:** HIGH (access to all infrastructure)
- **Security Model:** Least privilege + JIT elevation + comprehensive audit

---

## Architecture Overview

```
┌─────────────────────────────────────────────────────────────────┐
│                  IT ADMINISTRATOR WORKSTATION                    │
│                        laptop-mike-01                            │
│                   10.0.131.30 (VLAN 131 - Admin)                 │
│                                                                   │
│  Two User Identities on Same Device:                             │
│                                                                   │
│  1. mike@corp.company.local (Normal ID)                          │
│     ├─ Email, documentation, tickets                             │
│     ├─ /home/mike → file-server01:/shares/home/mike             │
│     ├─ /mnt/monitoring-ro → monitoring01:/logs (READ-ONLY)      │
│     ├─ Access to dev-test01 for script testing                  │
│     └─ NO admin access to production                            │
│                                                                   │
│  2. mike-admin@corp.company.local (JIT Privileged ID)            │
│     ├─ Activated ONLY when needed (time-limited session)        │
│     ├─ Ansible playbook execution                               │
│     ├─ SSH to production servers/workstations                   │
│     ├─ Emergency fixes, system maintenance                      │
│     ├─ Expires after 4 hours (must re-authenticate)             │
│     └─ ALL actions audited (session recording)                  │
│                                                                   │
└────────────────────────────┬──────────────────────────────────┘
                             │
                ┌────────────┼──────────────────────────┐
                │            │                          │
         ┌──────▼──────┐ ┌──▼────────────┐ ┌──────────▼─────────┐
         │ dc01/dc02   │ │file-server01  │ │ansible-ctrl        │
         │ (AD Auth)   │ │(Home + Logs)  │ │(JIT elevation)     │
         │ VLAN 120    │ │VLAN 120       │ │VLAN 120            │
         └─────────────┘ └───────────────┘ └────────────────────┘
                │
         ┌──────▼──────────┐
         │ monitoring01     │
         │ (Aggregated logs)│
         │ VLAN 120         │
         └──────────────────┘
```

---

## Security Requirements

| Requirement | Implementation | Why |
|-------------|----------------|-----|
| **Dual Identity** | Two AD accounts: mike + mike-admin | Separation of privilege (normal work vs. admin tasks) |
| **JIT Elevation** | mike-admin access time-limited (4 hours) | Minimize attack surface (not always privileged) |
| **2FA for JIT** | Yubikey required for mike-admin elevation | Extra security for privileged access |
| **Session Recording** | All mike-admin SSH sessions recorded | Audit trail, incident investigation |
| **Monitoring Access** | Read-only access to aggregated logs (threat view) | IT can see security trends, not raw user data |
| **Dev Environment** | Access to dev-test01 as mike (normal ID) | Safe testing without production access |
| **Ansible Execution** | Only mike-admin can run Ansible | Production changes require elevation |
| **SSH Access** | mike-admin can SSH to servers/workstations | Troubleshooting and fixes |
| **Time-Limited Tickets** | Kerberos tickets expire after 4 hours | Stolen credentials have short window |
| **Comprehensive Audit** | All JIT actions logged to monitoring01 | Compliance, accountability |

---

## Security Flow Trace: Dual Identity in Action

### **Scenario 1: Normal Work (mike@corp.company.local)**

#### 8:00 AM - Mike Starts His Day (Normal Identity)

```
Mike logs in to laptop-mike-01:
  ├─ Username: mike@corp.company.local
  ├─ Password: [Mike's normal password]
  ├─ NO Yubikey required (normal work doesn't need 2FA)
  └─ Login succeeds
       ↓
PAM mounts filesystems:
  ├─ /home/mike → file-server01:/shares/home/mike (personal files)
  ├─ /mnt/monitoring-ro → monitoring01:/logs-aggregated (READ-ONLY)
  └─ /mnt/dev-scripts → dev-test01:/scripts (testing area)
       ↓
Mike's Desktop Loads:
  ├─ Email client (mike@corp.company.local)
  ├─ Ticketing system (helpdesk tickets)
  ├─ Documentation wiki
  ├─ VS Code (for script development)
  └─ Monitoring dashboard (threat aggregation view)
```

**What mike (normal ID) CAN do:**
```bash
# Read email and respond to tickets
$ thunderbird

# View aggregated security logs (trends, not individual user data)
$ firefox http://monitoring01/dashboard
  Shows:
    - Failed login attempts by subnet (not by specific user)
    - Malware detections by workstation group
    - Firewall block counts by threat type
    - System health metrics

# Develop and test scripts on dev server
$ ssh mike@dev-test01
mike@dev-test01:~$ nano /scripts/test-backup.sh
mike@dev-test01:~$ bash /scripts/test-backup.sh
  Output: Script runs in isolated dev environment (no production access)

# Read monitoring logs (aggregated, anonymized)
$ ls /mnt/monitoring-ro/aggregated-logs/
  2026-01-09-failed-logins-by-subnet.log
  2026-01-09-firewall-blocks-summary.log
  2026-01-09-malware-detections.log
```

**What mike (normal ID) CANNOT do:**
```bash
# Cannot SSH to production servers
$ ssh mike@file-server01
Permission denied (mike not in Admin group)

# Cannot run Ansible
$ ansible all -m ping
ERROR: User mike@corp.company.local not authorized to run Ansible

# Cannot access raw user audit logs (privacy protection)
$ cat /mnt/monitoring-ro/workstations/ws-employee-01/auth.log
Permission denied (not in Security-Audit group)

# Cannot sudo on local workstation
$ sudo dnf update
[sudo] password for mike:
mike is not in the sudoers file. This incident will be reported.
```

**Audit Log (Normal Work):**
```
type=USER_START msg=audit(1704369600.123:100): pid=1234 uid=1604000
  auid=1604000 ses=1 msg='op=PAM:session_open
  acct="mike@corp.company.local" exe="/usr/sbin/gdm"
  hostname=laptop-mike-01 res=success' key="it_staff_normal_login"

type=MOUNT msg=audit(1704369605.456:105): pid=2345 uid=0 auid=1604000
  ses=1 msg='op=mount path="/mnt/monitoring-ro"
  dev="//monitoring01/logs-aggregated" res=success'
  key="monitoring_readonly_mount"
```

---

### **Scenario 2: Emergency - Server Down, JIT Elevation Required**

#### 10:30 AM - User Reports File Server Offline

```
Mike receives helpdesk ticket:
  "Users cannot access \\file-server01\SharedDrive"
  Priority: HIGH (business-critical)
       ↓
Mike needs to investigate file-server01:
  ├─ Option 1: SSH to file-server01 (requires admin access)
  ├─ Option 2: Run Ansible diagnostic playbook
  └─ Both require JIT elevation to mike-admin
       ↓
Mike initiates JIT elevation:
  $ jit-elevate
  OR
  $ su - mike-admin@corp.company.local
```

---

#### Step 1: JIT Elevation Process

```
Terminal command:
  $ jit-elevate

JIT Elevation Script (/usr/local/bin/jit-elevate):
  ├─ Current user: mike@corp.company.local
  ├─ Target: mike-admin@corp.company.local
  ├─ Check: Is mike member of "IT-Staff" group? YES
  └─ Proceed with elevation
       ↓
Elevation Prompt:
  ┌────────────────────────────────────────────────┐
  │  Just-In-Time Privilege Elevation              │
  │                                                 │
  │  Current ID: mike@corp.company.local           │
  │  Target ID:  mike-admin@corp.company.local     │
  │                                                 │
  │  Reason for elevation (required):              │
  │  [Investigate file-server01 outage - TKT#4567] │
  │                                                 │
  │  Duration: [4 hours] (max 8 hours)             │
  │                                                 │
  │  Insert Yubikey and enter password:            │
  │  Password: [_______________]                   │
  │  [Touch Yubikey to continue]                   │
  └────────────────────────────────────────────────┘
       ↓
Mike provides:
  ├─ Reason: "Investigate file-server01 outage - TKT#4567"
  ├─ Duration: 4 hours (default)
  ├─ Password: [mike-admin password - DIFFERENT from normal mike password]
  ├─ Yubikey: [Inserts and touches]
  └─ Submits
       ↓
JIT Elevation Backend (ansible-ctrl or dc01):
  ├─ Validate credentials:
  │   ├─ Yubikey authentication: SUCCESS
  │   └─ AD password for mike-admin: SUCCESS
  ├─ Check authorization:
  │   ├─ Is mike@corp.company.local member of IT-Staff? YES
  │   └─ Can mike@corp.company.local elevate to mike-admin? YES
  ├─ Log elevation request:
  │   ├─ Who: mike@corp.company.local
  │   ├─ To: mike-admin@corp.company.local
  │   ├─ Why: "Investigate file-server01 outage - TKT#4567"
  │   ├─ When: 2026-01-09 10:30:15
  │   ├─ Duration: 4 hours (expires 14:30:15)
  │   └─ Source: laptop-mike-01 (10.0.131.30)
  ├─ Issue time-limited Kerberos ticket:
  │   ├─ Principal: mike-admin@corp.company.local
  │   ├─ Valid from: 10:30:15
  │   ├─ Expires: 14:30:15 (4 hours)
  │   └─ Renewable: NO (must re-authenticate after expiry)
  └─ Grant SSH agent forwarding for mike-admin
       ↓
Terminal shows:
  [JIT] Elevation granted to mike-admin@corp.company.local
  [JIT] Session expires: 2026-01-09 14:30:15 (4 hours)
  [JIT] Reason: Investigate file-server01 outage - TKT#4567
  [JIT] All actions will be audited and recorded

  mike-admin@laptop-mike-01:~$
```

**Audit Log (JIT Elevation):**
```
type=USER_AUTH msg=audit(1704377415.123:200): pid=3456 uid=1604000
  auid=1604000 ses=1 msg='op=JIT:elevation
  from="mike@corp.company.local" to="mike-admin@corp.company.local"
  reason="Investigate file-server01 outage - TKT#4567"
  duration=14400 grantors=pam_u2f,pam_sss exe="/usr/local/bin/jit-elevate"
  hostname=laptop-mike-01 res=success' key="jit_elevation_granted"

type=CRED_ACQ msg=audit(1704377415.456:201): pid=3456 uid=1604000
  auid=1604000 ses=2 msg='op=PAM:setcred grantors=pam_sss
  acct="mike-admin@corp.company.local" exe="/usr/local/bin/jit-elevate"
  res=success' key="jit_kerberos_ticket_issued"
```

**Monitoring Alert (INFO level):**
```
[10:30:15] INFO: JIT privilege elevation
  User: mike@corp.company.local
  Elevated to: mike-admin@corp.company.local
  Reason: "Investigate file-server01 outage - TKT#4567"
  Duration: 4 hours (expires 14:30:15)
  Source: laptop-mike-01 (10.0.131.30)
  2FA: Yubikey verified

  Context: Normal JIT elevation for IT staff
  Risk Level: NORMAL (expected IT operations)
  Ticket: TKT#4567 (cross-reference for audit)

  Email: IT Manager (notification of elevated access)
  Dashboard: Update "Active Privileged Sessions" count
```

---

#### Step 2: SSH to Production Server with JIT Identity

```
mike-admin@laptop-mike-01:~$ ssh file-server01

SSH Connection:
  ├─ Source: laptop-mike-01 (10.0.131.30)
  ├─ Destination: file-server01 (10.0.120.20)
  ├─ User: mike-admin@corp.company.local
  ├─ Authentication: Kerberos ticket (JIT, expires in 4 hours)
  └─ Session recording: ENABLED
       ↓
Firewall (pfSense):
  ├─ Rule check: VLAN 131 (Admin) → VLAN 120 (Servers) SSH = PERMIT
  ├─ Additional check: Is user in Admin-SSH group?
  │   └─ Query AD: mike-admin in Admin-SSH group? YES
  └─ Allow connection
       ↓
file-server01 sshd:
  ├─ Receives connection from 10.0.131.30
  ├─ Authentication: Kerberos (mike-admin@corp.company.local)
  ├─ Validate ticket:
  │   ├─ Issued by: dc01.corp.company.local
  │   ├─ Valid until: 14:30:15 (3.5 hours remaining)
  │   └─ Ticket valid: YES
  ├─ Check authorization:
  │   ├─ Is mike-admin in allowed groups? YES (Admin-SSH)
  │   └─ SSH access: GRANTED
  └─ Start session with session recording
       ↓
Session Recording (asciinema or similar):
  ├─ Record all keystrokes and output
  ├─ Session ID: ssh-20260109-103018-mike-admin-file-server01
  ├─ Recording saved to: monitoring01:/session-recordings/
  └─ Can be replayed for audit/investigation
       ↓
mike-admin@file-server01:~$
```

**What mike-admin CAN do on production server:**
```bash
# Check Samba status
mike-admin@file-server01:~$ sudo systemctl status smbd
● smbd.service - Samba SMB Daemon
   Loaded: loaded (/usr/lib/systemd/system/smbd.service; enabled)
   Active: failed (Result: exit-code) since 10:15:22

# View logs
mike-admin@file-server01:~$ sudo journalctl -u smbd -n 50
Jan 09 10:15:20 file-server01 smbd[5678]: disk full on /srv/shares
Jan 09 10:15:22 file-server01 systemd[1]: smbd.service: Failed

# Fix issue (disk cleanup)
mike-admin@file-server01:~$ sudo df -h
Filesystem      Size  Used Avail Use% Mounted on
/srv/shares     500G  500G     0 100% /srv/shares

mike-admin@file-server01:~$ sudo find /srv/shares/temp -type f -mtime +30 -delete
Deleted 1234 old temporary files, freed 50GB

mike-admin@file-server01:~$ sudo systemctl restart smbd
mike-admin@file-server01:~$ sudo systemctl status smbd
● smbd.service - Samba SMB Daemon
   Active: active (running) since 10:35:45

# Verify users can connect
mike-admin@file-server01:~$ smbstatus
Samba version 4.18.8
Service      pid  Machine       Connected at
-------------------------------------------------
SharedDrive  7890 10.0.130.30   Wed Jan 9 10:36:12 2026

# Exit
mike-admin@file-server01:~$ exit
logout
Connection to file-server01 closed.
```

**Audit Log (SSH Session):**
```
# On file-server01:
type=USER_AUTH msg=audit(1704377418.123:500): pid=4567 uid=0
  auid=1605000 ses=10 msg='op=PAM:authentication
  grantors=pam_krb5 acct="mike-admin@corp.company.local"
  exe="/usr/sbin/sshd" hostname=laptop-mike-01 addr=10.0.131.30
  terminal=ssh res=success' key="admin_ssh_login"

type=USER_START msg=audit(1704377418.456:501): pid=4567 uid=1605000
  auid=1605000 ses=10 msg='op=PAM:session_open
  acct="mike-admin@corp.company.local" exe="/usr/sbin/sshd"
  hostname=laptop-mike-01 res=success' key="admin_session_start"

type=USER_CMD msg=audit(1704377520.789:502): pid=5678 uid=1605000
  auid=1605000 ses=10 msg='cwd="/home/mike-admin" cmd="systemctl status smbd"
  terminal=pts/0 res=success' key="admin_command_execution"

type=USER_CMD msg=audit(1704377680.123:503): pid=6789 uid=1605000
  auid=1605000 ses=10 msg='cwd="/home/mike-admin"
  cmd="find /srv/shares/temp -type f -mtime +30 -delete"
  terminal=pts/0 res=success' key="admin_file_deletion"

type=USER_CMD msg=audit(1704377720.456:504): pid=7890 uid=1605000
  auid=1605000 ses=10 msg='cwd="/home/mike-admin"
  cmd="systemctl restart smbd" terminal=pts/0 res=success'
  key="admin_service_restart"

type=USER_END msg=audit(1704377850.789:505): pid=4567 uid=1605000
  auid=1605000 ses=10 msg='op=PAM:session_close
  acct="mike-admin@corp.company.local" exe="/usr/sbin/sshd"
  res=success' key="admin_session_end"
```

**Session Recording (saved to monitoring01):**
```
# Session recording metadata
Session ID: ssh-20260109-103018-mike-admin-file-server01
User: mike-admin@corp.company.local
Source: laptop-mike-01 (10.0.131.30)
Destination: file-server01 (10.0.120.20)
Start: 2026-01-09 10:30:18
End: 2026-01-09 10:37:30
Duration: 7 minutes 12 seconds
Commands executed: 8
Files modified: /srv/shares/temp/* (1234 files deleted)
Services restarted: smbd
Result: SUCCESS (service restored)

# Can replay session:
$ ssh-replay ssh-20260109-103018-mike-admin-file-server01.cast
[Shows exact terminal session, keystroke-by-keystroke]
```

---

#### Step 3: Run Ansible Playbook with JIT Identity

```
mike-admin@laptop-mike-01:~$ cd /opt/smb-ansible/ansible/dev
mike-admin@laptop-mike-01:~/ansible$ ansible-playbook playbooks/verify-backups.yml

Ansible Playbook Execution:
  ├─ Check: Is user mike-admin? YES
  ├─ Check: Is mike-admin in Ansible-Users group? YES
  ├─ Kerberos ticket: Valid (2.5 hours remaining)
  └─ Proceed
       ↓
Playbook: verify-backups.yml
  ├─ Connects to backup-server (10.0.120.40) via SSH
  ├─ Authentication: Kerberos (mike-admin ticket)
  ├─ Runs tasks:
  │   ├─ Check backup age
  │   ├─ Verify backup integrity
  │   └─ Report status
  └─ Output:
      PLAY [Verify Backups] **********

      TASK [Check last backup time] ***
      ok: [backup-server] =>
        last_backup: 2026-01-09 02:00:15 (8.5 hours ago)

      TASK [Verify backup integrity] ***
      ok: [backup-server] =>
        integrity_check: PASSED (all checksums valid)

      PLAY RECAP **********************
      backup-server : ok=2  changed=0  failed=0
```

**Ansible Execution Audit:**
```
type=USER_CMD msg=audit(1704378000.123:600): pid=8901 uid=1605000
  auid=1604000 ses=2 msg='cwd="/opt/smb-ansible/ansible/dev"
  cmd="ansible-playbook playbooks/verify-backups.yml"
  terminal=pts/1 res=success' key="ansible_playbook_execution"

type=EXECVE msg=audit(1704378000.124:601): argc=3
  a0="ansible-playbook" a1="playbooks/verify-backups.yml"

type=CWD msg=audit(1704378000.124:601): cwd="/opt/smb-ansible/ansible/dev"
```

**Monitoring Dashboard:**
```
[10:45:00] Ansible Playbook Execution
  User: mike-admin@corp.company.local (JIT session)
  Playbook: verify-backups.yml
  Targets: backup-server
  Duration: 45 seconds
  Result: SUCCESS (0 failed, 0 changed)
  Session: JIT (expires 14:30:15, 3.75 hours remaining)

  Recorded to: monitoring01:/ansible-logs/20260109-104500-verify-backups.log
```

---

### **Scenario 3: JIT Session Expires (Auto-Revocation)**

#### 14:30:15 - JIT Ticket Expires (4 Hours After Elevation)

```
[14:30:15] Kerberos ticket expiration:

System checks Kerberos ticket status:
  ├─ Current time: 14:30:15
  ├─ Ticket issued: 10:30:15
  ├─ Ticket expires: 14:30:15
  └─ Ticket status: EXPIRED
       ↓
Mike attempts to SSH to server:
  mike-admin@laptop-mike-01:~$ ssh dc01
       ↓
SSH client checks Kerberos:
  ├─ Look for valid ticket for mike-admin@corp.company.local
  ├─ Ticket found, but expired
  └─ Return: No valid credentials
       ↓
SSH fails:
  Permission denied (no valid Kerberos ticket)

  To continue working, re-elevate using: jit-elevate
```

**Automatic Session Termination:**
```
# All active SSH sessions with mike-admin terminated
# (optional, depending on policy)

# Notification to Mike:
┌────────────────────────────────────────────────┐
│  JIT Session Expired                           │
│                                                 │
│  Your elevated session (mike-admin) has        │
│  expired after 4 hours.                        │
│                                                 │
│  Reason: Investigate file-server01 outage      │
│  Started: 10:30:15                             │
│  Ended: 14:30:15                               │
│                                                 │
│  To elevate again, run: jit-elevate            │
└────────────────────────────────────────────────┘
```

**Audit Log (Session Expiry):**
```
type=CRED_DISP msg=audit(1704391815.123:700): pid=3456 uid=1604000
  auid=1604000 ses=2 msg='op=PAM:setcred
  acct="mike-admin@corp.company.local" exe="/usr/bin/kdestroy"
  res=success' key="jit_session_expired"

type=USER_END msg=audit(1704391815.456:701): pid=3456 uid=1604000
  auid=1604000 ses=2 msg='op=JIT:expiration
  acct="mike-admin@corp.company.local" duration=14400
  reason="time_limit_reached" res=success' key="jit_auto_revocation"
```

**Monitoring Summary (JIT Session Report):**
```
[14:30:15] JIT Session Completed
  User: mike@corp.company.local → mike-admin@corp.company.local
  Started: 10:30:15
  Ended: 14:30:15
  Duration: 4 hours (as requested)
  Reason: "Investigate file-server01 outage - TKT#4567"

  Activity Summary:
    SSH Connections: 3
      - file-server01 (7 min, service restart)
      - backup-server (2 min, verification)
      - ansible-ctrl (15 min, playbook execution)

    Commands Executed: 23
      - systemctl: 4
      - find/delete: 1 (1234 files removed)
      - journalctl: 3
      - ansible-playbook: 2
      - Other: 13

    Files Modified: 1234 (temp files deleted from /srv/shares/temp)
    Services Restarted: 1 (smbd on file-server01)
    Ansible Playbooks Run: 2 (verify-backups.yml, check-disk-space.yml)

  Outcome: Issue resolved (file-server01 disk space freed, service restored)
  Ticket Status: TKT#4567 closed (resolved)

  Session Recordings: 3 files saved to /session-recordings/
  Audit Compliance: SOX, HIPAA, ISO 27001
```

---

## Monitoring Access: Aggregated Logs (Threat View)

### What IT Staff See vs. What They Don't See

```
Mike's Normal ID (mike@corp.company.local) accesses:
  /mnt/monitoring-ro/aggregated-logs/

Directory Structure:
  /mnt/monitoring-ro/
  ├─ aggregated-logs/           ← Mike (normal) CAN access
  │   ├─ failed-logins-by-subnet.log
  │   ├─ firewall-blocks-by-type.log
  │   ├─ malware-detections-summary.log
  │   ├─ system-health-metrics.log
  │   └─ threat-intelligence-feed.log
  │
  ├─ detailed-logs/              ← Mike (normal) CANNOT access
  │   ├─ workstations/
  │   │   ├─ ws-employee-01/auth.log  (individual user data)
  │   │   └─ ws-employee-02/auth.log
  │   └─ servers/
  │       ├─ file-server01/access.log
  │       └─ dc01/auth.log
  │
  └─ session-recordings/         ← Mike-admin (JIT) CAN access
      ├─ ssh-20260109-103018-mike-admin-file-server01.cast
      └─ ssh-20260108-140522-mike-admin-dc01.cast
```

---

### Example: Aggregated Threat View (Privacy-Preserving)

**File: /mnt/monitoring-ro/aggregated-logs/failed-logins-by-subnet.log**
```
# Failed login attempts aggregated by subnet (no individual usernames)

2026-01-09 08:00-09:00
  Subnet: 10.0.130.0/24 (Workstations)
    Failed logins: 12
    Most common reason: Invalid password (8)
    Second reason: Account disabled (3)
    Third reason: Wrong workstation (1)
    Risk Level: LOW (normal user error rate)

  Subnet: 10.0.131.0/24 (Admin)
    Failed logins: 2
    Reason: 2FA timeout (Yubikey not present)
    Risk Level: MEDIUM (possible credential compromise, investigate)

  External IPs (VPN attempts):
    Failed logins: 45
    Source countries: CN (30), RU (10), US (5)
    Risk Level: HIGH (brute force attack detected, IPs blocked)
```

**Mike sees:** "45 failed VPN attempts from CN/RU, IPs auto-blocked"
**Mike does NOT see:** Which users were targeted, specific usernames, raw auth logs

---

**File: /mnt/monitoring-ro/aggregated-logs/malware-detections-summary.log**
```
# Malware detection events (anonymized)

2026-01-09
  Total detections: 8

  By workstation group:
    Workstations (VLAN 130): 6 detections
      - Phishing email attachment: 4
      - Drive-by download: 2
      - Result: All blocked by AV, 0 infections

    Admin workstations (VLAN 131): 0 detections

    Servers (VLAN 120): 0 detections

  Top threats:
    1. Generic.Phishing.EmailAttachment (4)
    2. Trojan.DownloadAssist (2)
    3. PUA.BrowserExtension (2)

  Actions taken:
    - Files quarantined: 8
    - Workstations scanned: 8
    - False positives: 0
    - Confirmed malware: 8

  Trend: +2 compared to yesterday (within normal variance)
```

**Mike sees:** "6 phishing attempts on workstation VLAN, all blocked"
**Mike does NOT see:** Which employees clicked phishing links (privacy)

---

### JIT Access to Detailed Logs (When Needed)

```
Mike needs to investigate specific user issue:
  User Sarah reports: "I can't log in"
       ↓
Mike elevates to mike-admin (JIT):
  $ jit-elevate
  Reason: "Investigate Sarah's login issue - TKT#4590"
  Duration: 2 hours
       ↓
mike-admin@laptop-mike-01:~$ ssh monitoring01
mike-admin@monitoring01:~$ sudo cat /var/log/workstations/laptop-sarah-01/auth.log

Jan 09 14:45:22 laptop-sarah-01 pam_sss: Authentication failure (invalid password) for sarah@corp.company.local
Jan 09 14:45:35 laptop-sarah-01 pam_sss: Authentication failure (invalid password) for sarah@corp.company.local
Jan 09 14:45:48 laptop-sarah-01 pam_sss: Authentication failure (invalid password) for sarah@corp.company.local
Jan 09 14:46:00 laptop-sarah-01 pam_faillock: User sarah@corp.company.local locked out (3 failed attempts)
       ↓
mike-admin finds issue:
  - Sarah entered wrong password 3 times
  - Account auto-locked (security policy)
  - Solution: Unlock account, verify Sarah's identity, reset password if needed
       ↓
mike-admin@monitoring01:~$ exit
mike-admin@laptop-mike-01:~$ ssh dc01
mike-admin@dc01:~$ sudo pam_faillock --user sarah@corp.company.local --reset
Faillock entry for sarah@corp.company.local cleared

mike-admin@dc01:~$ exit
```

**Audit of Detailed Log Access:**
```
type=USER_AUTH msg=audit(1704395145.123:800): pid=9012 uid=1605000
  auid=1604000 ses=3 msg='op=PAM:authentication
  acct="mike-admin@corp.company.local" exe="/usr/sbin/sshd"
  hostname=laptop-mike-01 res=success' key="jit_monitoring_access"

type=SYSCALL msg=audit(1704395200.456:801): arch=c000003e syscall=257
  success=yes exit=3 comm="cat" exe="/usr/bin/cat"
  a1="/var/log/workstations/laptop-sarah-01/auth.log"
  auid=1604000 ses=3 key="detailed_log_access"

type=PROCTITLE msg=audit(1704395200.456:801):
  proctitle="cat" "/var/log/workstations/laptop-sarah-01/auth.log"
```

**Compliance Logging:**
```
[14:46:40] PRIVACY ALERT: Detailed user log accessed
  Elevated User: mike-admin@corp.company.local
  Normal User: mike@corp.company.local
  Accessed Log: laptop-sarah-01/auth.log (contains PII)
  Reason: "Investigate Sarah's login issue - TKT#4590"
  Ticket: TKT#4590 (cross-reference)

  Justification: Troubleshooting user-reported issue
  Authorization: JIT elevation (valid until 16:45:00)

  Privacy Compliance:
    ✓ Access was necessary for legitimate IT support
    ✓ Minimum data accessed (only Sarah's auth log, not others)
    ✓ Purpose logged and documented (ticket reference)
    ✓ Time-limited access (JIT expiration)
    ✓ Complete audit trail maintained

  GDPR Article 32: Security of processing - compliant
  HIPAA Security Rule: Access controls - compliant

  Email: Privacy Officer (monthly summary of PII access)
  Retention: 7 years (compliance requirement)
```

---

## Dev/Test Environment Access

### Script Development and Testing (Normal ID)

```
Mike develops monitoring script:
  mike@laptop-mike-01:~$ ssh dev-test01
  mike@dev-test01:~$ cd /scripts
  mike@dev-test01:/scripts$ nano check-disk-space.sh
```

**Script Content:**
```bash
#!/bin/bash
# Check disk space on all servers
# Author: mike@corp.company.local
# Test: Run on dev-test01 before deploying to production

THRESHOLD=80

for server in file-server01 dc01 dc02 backup-server; do
  echo "Checking $server..."

  # This is DEV - connects to test servers, not production
  ssh $server "df -h | grep -v tmpfs" || echo "ERROR: Cannot reach $server"
done
```

**Dev Environment Characteristics:**
```
dev-test01 (10.0.120.100):
  ├─ Isolated from production
  ├─ mike (normal ID) has SSH access
  ├─ Can run scripts safely (no production impact)
  ├─ Has test data (synthetic, not real user data)
  └─ Used for:
      ├─ Script development
      ├─ Ansible playbook testing
      ├─ Configuration validation
      └─ Safe experimentation

Production (VLAN 120):
  ├─ mike (normal ID) CANNOT access
  ├─ Only mike-admin (JIT) can access
  ├─ Real user data, business-critical
  └─ Changes require JIT elevation + audit
```

**Testing Process:**
```
# Step 1: Develop on local workstation
mike@laptop-mike-01:~$ nano check-disk-space.sh

# Step 2: Test on dev-test01
mike@laptop-mike-01:~$ scp check-disk-space.sh dev-test01:/scripts/
mike@laptop-mike-01:~$ ssh dev-test01
mike@dev-test01:~$ bash /scripts/check-disk-space.sh
Output: [Test output from dev servers]

# Step 3: Review, refine, test again
mike@dev-test01:~$ nano /scripts/check-disk-space.sh
mike@dev-test01:~$ bash /scripts/check-disk-space.sh
Output: [Improved output]

# Step 4: When ready for production, elevate to JIT
mike@dev-test01:~$ exit
mike@laptop-mike-01:~$ jit-elevate
Reason: "Deploy disk-space monitoring script - TKT#4600"

# Step 5: Deploy to production Ansible
mike-admin@laptop-mike-01:~$ cd /opt/smb-ansible/ansible/dev/roles
mike-admin@laptop-mike-01:~/roles$ mkdir monitoring-scripts
mike-admin@laptop-mike-01:~/roles$ cp ~/check-disk-space.sh monitoring-scripts/files/
mike-admin@laptop-mike-01:~/roles$ ansible-playbook playbooks/deploy-monitoring-scripts.yml
```

**Security Value:**
- Normal work (development) doesn't require JIT elevation
- Testing happens in isolated environment (no production risk)
- Production deployment requires JIT + audit
- Separation prevents accidental production changes

---

## Comparison: IT Staff vs. Other User Types

| Feature | IT Normal (mike) | IT JIT (mike-admin) | Managers/Finance/HR | General Employees |
|---------|------------------|---------------------|---------------------|-------------------|
| **Device Assignment** | Assigned laptop | Same device | Assigned laptop | Shared workstations |
| **2FA Requirement** | NO (normal work) | YES (Yubikey) | YES (Yubikey) | NO |
| **SSH to Servers** | Dev/test only | Production allowed | NO | NO |
| **Ansible Execution** | NO | YES | NO | NO |
| **Monitoring Logs** | Aggregated (threat view) | Detailed (when elevated) | NO | NO |
| **Session Recording** | NO | YES (all SSH sessions) | NO | NO |
| **Time-Limited Access** | N/A (always available) | YES (4-8 hours max) | N/A | N/A |
| **Justification Required** | NO | YES (reason + ticket) | NO | NO |
| **Department Shares** | NO | YES (when elevated) | YES (role-based) | NO |
| **Audit Level** | Standard | COMPREHENSIVE | Enhanced | Standard |
| **Compliance** | N/A | SOX, HIPAA, ISO 27001 | SOX, GDPR | Basic |

---

## Implementation: Ansible Configuration

### Host Variables (host_vars/laptop-mike-01.yml)

```yaml
---
hostname: laptop-mike-01
ip_address: 10.0.131.30
netmask: 255.255.255.0
gateway: 10.0.131.1
vlan_id: 131  # Admin network
dns_servers:
  - 10.0.120.10  # dc01
  - 10.0.120.11  # dc02

# Device assignment
device_type: laptop
assigned_user: mike@corp.company.local
asset_tag: LAPTOP-2026-089
serial_number: "5CD23456DEF"
user_role: it_administrator

# Dual identity configuration
normal_user: mike@corp.company.local
jit_user: mike-admin@corp.company.local
jit_enabled: true
jit_max_duration: 28800  # 8 hours max (14400 = 4 hours default)
jit_require_reason: true
jit_require_yubikey: true

# Normal user permissions
normal_user_groups:
  - IT-Staff
  - Employees
  - VPN-Users

# JIT user permissions (elevated)
jit_user_groups:
  - Admins
  - Admin-SSH
  - Ansible-Users
  - Security-Audit  # Can access detailed logs

# Network home directory (normal user)
home_directory:
  type: cifs
  server: file-server01.corp.company.local
  path: shares/home/mike
  mountpoint: /home/mike
  options: sec=krb5,uid=%(USERUID),gid=%(USERGID)

# Monitoring access (read-only aggregated logs)
monitoring_shares:
  - name: monitoring-aggregated
    type: cifs
    server: monitoring01.corp.company.local
    path: logs-aggregated
    mountpoint: /mnt/monitoring-ro
    required_group: IT-Staff
    options: sec=krb5,ro,uid=%(USERUID),gid=10300
    selinux_context: monitoring_ro_t

# Dev environment access (normal user)
dev_environment:
  - name: dev-scripts
    type: cifs
    server: dev-test01.corp.company.local
    path: scripts
    mountpoint: /mnt/dev-scripts
    required_group: IT-Staff
    options: sec=krb5,uid=%(USERUID),gid=10400

# JIT session configuration
jit_session:
  enabled: true
  default_duration: 14400  # 4 hours
  max_duration: 28800  # 8 hours
  require_reason: true
  require_ticket_reference: true
  session_recording: true
  recording_path: /var/log/session-recordings
  rsync_to_monitoring: true

# Audit configuration
audit_level: comprehensive
audit_jit_sessions: true
audit_detailed_log_access: true
audit_retention_days: 2555  # 7 years (compliance)
session_recording_enabled: true

# Security
full_disk_encryption: true
luks_enabled: true
idle_timeout_minutes: 10
screen_lock_enabled: true

# Logging
rsyslog_target: 10.0.120.60  # monitoring01
log_jit_elevations: true
log_ansible_executions: true
log_ssh_connections: true
```

---

### JIT Elevation Script (/usr/local/bin/jit-elevate)

```bash
#!/bin/bash
# JIT Privilege Elevation Script
# Author: IT Security Team
# Purpose: Provide time-limited privileged access to IT staff

set -euo pipefail

# Configuration
NORMAL_USER="${USER}@corp.company.local"
JIT_USER="${USER}-admin@corp.company.local"
MAX_DURATION=28800  # 8 hours
DEFAULT_DURATION=14400  # 4 hours
REQUIRE_REASON=true
REQUIRE_YUBIKEY=true
AUDIT_LOG="/var/log/jit-elevation.log"

# Functions
log_audit() {
  echo "[$(date '+%Y-%m-%d %H:%M:%S')] $*" >> "$AUDIT_LOG"
  logger -t jit-elevate -p auth.info "$*"
}

# Check if user is in IT-Staff group
if ! groups | grep -q "IT-Staff"; then
  echo "ERROR: JIT elevation only available to IT-Staff group members"
  log_audit "DENIED: User $NORMAL_USER not in IT-Staff group"
  exit 1
fi

# Prompt for reason
if [ "$REQUIRE_REASON" = true ]; then
  echo "Reason for privilege elevation (include ticket #):"
  read -r REASON

  if [ -z "$REASON" ]; then
    echo "ERROR: Reason is required"
    exit 1
  fi

  # Check for ticket reference
  if ! echo "$REASON" | grep -qiE '(TKT|TICKET|INC|INCIDENT).*[0-9]+'; then
    echo "WARNING: No ticket reference found in reason"
    echo "Continue anyway? (y/N): "
    read -r CONFIRM
    if [ "$CONFIRM" != "y" ]; then
      exit 1
    fi
  fi
fi

# Prompt for duration
echo "Duration in hours (default: 4, max: 8):"
read -r DURATION_HOURS
DURATION_HOURS=${DURATION_HOURS:-4}

if [ "$DURATION_HOURS" -gt 8 ]; then
  echo "ERROR: Maximum duration is 8 hours"
  exit 1
fi

DURATION_SECONDS=$((DURATION_HOURS * 3600))

# Yubikey + Password authentication
echo "Authenticating to $JIT_USER..."
echo "Insert Yubikey and enter password for $JIT_USER:"

# Request Kerberos ticket with limited lifetime
kinit -l ${DURATION_HOURS}h "$JIT_USER"

if [ $? -ne 0 ]; then
  log_audit "FAILED: Authentication failed for $NORMAL_USER -> $JIT_USER"
  exit 1
fi

# Calculate expiration time
EXPIRE_TIME=$(date -d "+${DURATION_HOURS} hours" '+%Y-%m-%d %H:%M:%S')

# Success
log_audit "SUCCESS: $NORMAL_USER elevated to $JIT_USER, reason: $REASON, duration: ${DURATION_HOURS}h, expires: $EXPIRE_TIME"

echo ""
echo "✓ JIT Elevation Granted"
echo "  User: $JIT_USER"
echo "  Expires: $EXPIRE_TIME (${DURATION_HOURS} hours)"
echo "  Reason: $REASON"
echo ""
echo "All actions will be audited and recorded."
echo "Session expires in ${DURATION_HOURS} hours - you will need to re-authenticate."
echo ""

# Start new shell as JIT user
exec su - "$JIT_USER"
```

---

## Test Cases for Validation

### Test Case 1: Normal Work (No Elevation)
```
Test: Mike logs in with normal ID, accesses email and aggregated logs
Expected: Login succeeds, monitoring-ro mounted, no production access
Command: ssh mike@10.0.131.30 "ls /mnt/monitoring-ro"
```

### Test Case 2: JIT Elevation with Yubikey
```
Test: Mike elevates to mike-admin with Yubikey
Expected: Elevation succeeds, 4-hour ticket issued, audit logged
Command: ssh mike@10.0.131.30 "jit-elevate"
Input: Reason, Yubikey, password
```

### Test Case 3: JIT Elevation without Yubikey
```
Test: Mike attempts JIT elevation without Yubikey
Expected: Elevation DENIED, high-severity alert
Command: Remove Yubikey, attempt jit-elevate
```

### Test Case 4: SSH to Production Server (JIT)
```
Test: mike-admin SSH to file-server01
Expected: Connection succeeds, session recorded, audit logged
Command: ssh mike-admin@10.0.131.30 "ssh file-server01"
```

### Test Case 5: SSH to Production Server (Normal User)
```
Test: mike (normal) tries SSH to file-server01
Expected: Permission denied, not in Admin-SSH group
Command: ssh mike@10.0.131.30 "ssh file-server01"
Expected: Permission denied
```

### Test Case 6: Ansible Execution (JIT)
```
Test: mike-admin runs Ansible playbook
Expected: Playbook executes, audit logged, output recorded
Command: ssh mike-admin@10.0.131.30 "ansible-playbook playbooks/test.yml"
```

### Test Case 7: Ansible Execution (Normal User)
```
Test: mike (normal) tries to run Ansible
Expected: Denied, not in Ansible-Users group
Command: ssh mike@10.0.131.30 "ansible all -m ping"
Expected: Permission denied
```

### Test Case 8: JIT Session Expiry
```
Test: Wait 4 hours, attempt SSH with expired ticket
Expected: Authentication fails, ticket expired
Command: sleep 14400; ssh mike-admin@10.0.131.30 "ssh dc01"
Expected: Permission denied (Kerberos ticket expired)
```

### Test Case 9: Dev Environment Testing
```
Test: mike (normal) develops and tests script on dev-test01
Expected: SSH succeeds, script runs in dev environment
Command: ssh mike@10.0.131.30 "ssh dev-test01 'bash /scripts/test.sh'"
```

### Test Case 10: Detailed Log Access (JIT)
```
Test: mike-admin accesses individual user auth logs
Expected: Access granted, privacy alert logged
Command: ssh mike-admin@monitoring01 "cat /var/log/workstations/ws-employee-01/auth.log"
```

### Test Case 11: Detailed Log Access (Normal User)
```
Test: mike (normal) tries to access detailed logs
Expected: Permission denied, privacy protection
Command: ssh mike@10.0.131.30 "cat /mnt/monitoring-ro/detailed-logs/ws-employee-01/auth.log"
Expected: Permission denied
```

### Test Case 12: Session Recording Replay
```
Test: Replay mike-admin SSH session from recording
Expected: Complete session playback with all commands visible
Command: ssh-replay /session-recordings/ssh-20260109-103018-mike-admin-file-server01.cast
```

---

## Compliance Benefits

### Principle of Least Privilege
✅ **Normal work** requires NO elevated access (email, tickets, monitoring trends)
✅ **Elevated access** only granted when needed (JIT elevation)
✅ **Time-limited** privileged sessions (auto-revocation after 4-8 hours)
✅ **Justification required** (reason + ticket reference)

### Separation of Duties
✅ **Development** (normal ID on dev-test01) separate from **production** (JIT ID)
✅ **Monitoring trends** (aggregated, privacy-preserving) vs. **detailed logs** (JIT only)
✅ **Two separate passwords** (mike vs. mike-admin)

### Audit Trail (SOX, HIPAA, ISO 27001)
✅ **Every JIT elevation logged** (who, why, when, duration)
✅ **Every SSH session recorded** (keystroke-level audit)
✅ **Every Ansible execution tracked** (what changed, where)
✅ **Detailed log access audited** (privacy compliance - GDPR Article 32)

### Non-Repudiation
✅ **Yubikey** physical device proves identity (can't claim "someone used my password")
✅ **Session recordings** prove exactly what was done
✅ **Kerberos tickets** timestamped and non-forgeable

---

**Document Version:** 1.0
**Last Updated:** 2026-01-09
**For:** IT Staff Workstations - Dual Identity (Normal + JIT) Security Model
**Compliance:** SOX, HIPAA, ISO 27001, GDPR privacy requirements
