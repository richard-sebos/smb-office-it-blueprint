# File Server Security Flow
## file-server01 - Rocky Linux with Samba File Server

---

## Use Case: Centralized File Storage

**Server:** file-server01 (10.0.120.20, VLAN 120)

**Purpose:**
- Network file shares (home directories, department shares, company-wide)
- Centralized data storage and backup
- Access control via AD groups
- Virus scanning (ClamAV on-access)
- Quota enforcement

**Risk Level:** HIGH (contains all business data)

---

## Architecture Overview

```
┌─────────────────────────────────────────────────────────────────┐
│                  FILE SERVER (file-server01)                     │
│                  Rocky Linux 9.3 (Oracle Linux compatible)       │
│                  10.0.120.20 (VLAN 120 - Servers)                │
│                                                                   │
│  Services:                                                       │
│  ├─ Samba (SMB file sharing with AD integration)                │
│  ├─ ClamAV (on-access virus scanning)                           │
│  ├─ XFS quotas (disk usage limits)                              │
│  └─ LVM snapshots (hourly, for recovery)                        │
│                                                                   │
│  Storage Layout (/srv/shares):                                   │
│  ├─ home/                    (user home directories)            │
│  │   ├─ john/                (john@corp.company.local)          │
│  │   ├─ sarah/               (sarah@corp.company.local)         │
│  │   └─ david/               (david@corp.company.local)         │
│  ├─ departments/             (department-specific shares)        │
│  │   ├─ finance/             (Finance group only)               │
│  │   ├─ hr/                  (HR group only)                    │
│  │   └─ management/          (Managers group only)              │
│  └─ company/                 (all employees, read/write)        │
│                                                                   │
│  Security Layers:                                                │
│  ├─ SELinux (MAC - samba_share_t contexts)                      │
│  ├─ Firewalld (SMB ports, ansible-ctrl SSH only)                │
│  ├─ AD Group Permissions (Finance, HR, Managers groups)         │
│  ├─ POSIX ACLs (fine-grained file permissions)                  │
│  ├─ SMB3 Encryption (mandatory for sensitive shares)            │
│  ├─ ClamAV (on-access scanning blocks malware)                  │
│  ├─ Auditd (comprehensive file access logging)                  │
│  └─ LVM Snapshots (point-in-time recovery)                      │
└──────────────────────────────────────────────────────────────────┘
```

---

## Security Requirements

| Requirement | Implementation | Why |
|-------------|----------------|-----|
| **AD Integration** | Samba winbind + Kerberos | Centralized authentication |
| **SELinux MAC** | Enforcing mode, samba_share_t contexts | Kernel-level protection |
| **Encrypted Transport** | SMB3 encryption (mandatory for Finance/HR) | Protect data in transit |
| **Access Control** | AD groups + POSIX ACLs | Role-based file access |
| **Virus Scanning** | ClamAV on-access (blocks before write) | Prevent malware storage |
| **Quota Enforcement** | XFS quotas per user/group | Prevent disk exhaustion |
| **Audit Logging** | Auditd on all share access | Track who accessed what |
| **Snapshots** | LVM hourly snapshots (24-hour retention) | Ransomware recovery |
| **Firewall** | firewalld (SMB from workstations only) | Network segmentation |
| **SSH Restriction** | ansible-ctrl only, key-based | Management access control |

---

## Security Flow Trace: File Access

### **Scenario 1: John (Employee) Accesses His Home Directory**

```
[9:00 AM] John opens File Explorer on ws-employee-05

Windows File Explorer:
  └─ Navigate to: \\file-server01\home-john
       ↓
SMB Connection Initiation:
  ├─ Source: 10.0.130.35 (ws-employee-05)
  ├─ Destination: 10.0.120.20:445 (file-server01)
  └─ Protocol: SMB3
       ↓
Firewall Check (file-server01):
  ├─ firewalld receives packet
  ├─ Rule check:
  │   Source: 10.0.130.35 (VLAN 130 - Workstations)
  │   Destination: 10.0.120.20:445 (Samba)
  │   Rule: zone=server, source=10.0.130.0/24, service=samba, action=ACCEPT
  └─ Packet allowed
       ↓
Samba Daemon (smbd):
  ├─ Process: /usr/sbin/smbd
  ├─ Receives connection request from 10.0.130.35
  └─ Initiates authentication
       ↓
Authentication (Kerberos via winbind):
  ├─ Client sends: Kerberos ticket from dc01
  ├─ Ticket principal: john@CORP.COMPANY.LOCAL
  ├─ Samba validates ticket:
  │   ├─ Query dc01: "Is ticket valid?"
  │   └─ dc01 response: Valid (issued at 8:00 AM, expires 6:00 PM)
  ├─ Samba queries winbind: "What are john's groups?"
  ├─ Winbind queries AD:
  │   └─ Groups: Employees (GID 10000)
  └─ Authentication: SUCCESS
       ↓
Share Access Check:
  ├─ Share requested: home-john
  ├─ Samba config (/etc/samba/smb.conf):
  │   [home-john]
  │   path = /srv/shares/home/john
  │   valid users = john@CORP.COMPANY.LOCAL
  │   read only = no
  │   browseable = yes
  ├─ Check: Is john in valid users list? YES
  └─ Access: GRANTED to share
       ↓
SELinux MAC Check:
  ├─ Process context: smbd_t (Samba daemon)
  ├─ File context: samba_share_t (/srv/shares/home/john)
  ├─ SELinux policy:
  │   allow smbd_t samba_share_t:file { read write };
  │   allow smbd_t samba_share_t:dir { read write search };
  └─ Operation: ALLOWED
       ↓
File System Permissions (DAC):
  ├─ Path: /srv/shares/home/john
  ├─ Owner: john (UID 1601000, mapped from AD)
  ├─ Group: john (GID 1601000)
  ├─ Permissions: drwx------ (0700) - Only john can access
  ├─ Check: Requesting user is john? YES
  └─ Operation: ALLOWED
       ↓
Quota Check:
  ├─ XFS quota query: How much space has john used?
  ├─ john's usage: 15GB / 50GB quota
  ├─ Quota status: OK (not exceeded)
  └─ Operation: ALLOWED
       ↓
Directory Listing Returned:
  ├─ Files in /srv/shares/home/john:
  │   ├─ Documents/
  │   ├─ Desktop/
  │   └─ project-proposal.docx
  └─ Sent to client
       ↓
Audit Logging:
  type=SYSCALL msg=audit(1704790800.123:5000): arch=c000003e
    syscall=257 success=yes exit=3 comm="smbd"
    exe="/usr/sbin/smbd" auid=4294967295 uid=0
    key="samba_file_operations"

  type=PATH msg=audit(1704790800.123:5000): item=0
    name="/srv/shares/home/john" inode=123456 dev=fd:00
    mode=040700 ouid=1601000 ogid=1601000
    obj=system_u:object_r:samba_share_t:s0
    key="samba_file_operations"
       ↓
John sees his files in File Explorer
```

**Security Layers in Action:**
1. ✅ Firewall - Only workstation VLAN allowed
2. ✅ Kerberos - AD authentication verified
3. ✅ Share ACL - Only john can access home-john share
4. ✅ SELinux - Kernel enforces samba_share_t access
5. ✅ File Permissions - john owns directory (0700)
6. ✅ Quota - Usage within limits
7. ✅ Audit - All access logged

---

### **Scenario 2: Sarah (Finance) Accesses Finance Share with SMB3 Encryption**

```
[10:00 AM] Sarah opens Finance share

Windows File Explorer (laptop-sarah-01):
  └─ Navigate to: \\file-server01\finance
       ↓
SMB Connection:
  ├─ Source: 10.0.131.25 (laptop-sarah-01, VLAN 131 - Admin)
  ├─ Destination: 10.0.120.20:445
  └─ Protocol: SMB3 with encryption negotiation
       ↓
Samba Receives Connection:
  ├─ Client requests: Share=finance
  ├─ Samba config check:
  │   [finance]
  │   path = /srv/shares/departments/finance
  │   valid users = @Finance
  │   read only = no
  │   smb encrypt = required    ← ENCRYPTION MANDATORY
  │   vfs objects = full_audit
       ↓
Encryption Negotiation:
  ├─ Samba requires SMB3 encryption
  ├─ Client supports: SMB 3.1.1 with AES-128-GCM
  ├─ Negotiation: SUCCESS
  └─ All data encrypted with AES-128-GCM
       ↓
Authentication (same as before):
  ├─ Kerberos ticket: sarah@CORP.COMPANY.LOCAL
  ├─ Winbind queries AD groups:
  │   └─ sarah is member of: Finance (GID 10200), Employees
  └─ Authentication: SUCCESS
       ↓
Share Access Check:
  ├─ Share: finance
  ├─ Valid users: @Finance (AD group)
  ├─ Check: Is sarah member of Finance group? YES
  └─ Access: GRANTED
       ↓
SELinux MAC Check (Department Share):
  ├─ File context: finance_share_t (custom context for Finance)
  ├─ SELinux policy:
  │   allow smbd_t finance_share_t:file { read write };
  │   (Only if user in Finance group - policy enforced)
  └─ Operation: ALLOWED (sarah in Finance group)
       ↓
File System Permissions:
  ├─ Path: /srv/shares/departments/finance
  ├─ Owner: root
  ├─ Group: Finance (GID 10200 from AD)
  ├─ Permissions: drwxrws--- (2770)
  │   ├─ User (root): rwx
  │   ├─ Group (Finance): rws (read, write, execute, setgid)
  │   └─ Other: --- (no access)
  ├─ POSIX ACL:
  │   user::rwx
  │   group::rwx
  │   group:Finance:rwx
  │   mask::rwx
  │   other::---
  └─ sarah's GID includes Finance → Access GRANTED
       ↓
Directory Listing (Encrypted):
  ├─ Files retrieved from /srv/shares/departments/finance
  ├─ Encrypted with SMB3 AES-128-GCM
  └─ Sent to client
       ↓
Audit Logging (Enhanced for Finance Share):
  type=SYSCALL msg=audit(1704794400.456:5100): arch=c000003e
    syscall=257 success=yes comm="smbd"
    key="finance_file_access"

  type=PATH msg=audit(1704794400.456:5100): item=0
    name="/srv/shares/departments/finance" mode=042770
    obj=system_u:object_r:finance_share_t:s0
    key="finance_read"

  # VFS full_audit module logs every operation
  /var/log/samba/audit-finance.log:
    2026/01/09 10:00:15|sarah@CORP.COMPANY.LOCAL|10.0.131.25|
    connect|finance|READ|/payroll/salaries-2026.xlsx
       ↓
Sarah sees Finance files (encrypted in transit)
```

**Additional Security for Finance Share:**
- ✅ SMB3 Encryption - MANDATORY (can't access without encryption)
- ✅ Separate SELinux context - finance_share_t (not generic samba_share_t)
- ✅ VFS full_audit - Every file operation logged
- ✅ Group enforcement - Only Finance group members
- ✅ Setgid bit - All new files inherit Finance group ownership

---

### **Scenario 3: John Tries to Access Finance Share (Unauthorized)**

```
[10:15 AM] John (regular employee) tries to access Finance

John's workstation:
  └─ Navigate to: \\file-server01\finance
       ↓
SMB Connection:
  ├─ Authentication succeeds (john has valid Kerberos ticket)
  ├─ Share requested: finance
       ↓
Share Access Check:
  ├─ Share config: valid users = @Finance
  ├─ Winbind queries AD: Is john member of Finance group?
  │   └─ john's groups: Employees (only)
  ├─ Check: john in Finance group? NO
  └─ Access: DENIED
       ↓
Samba Response:
  └─ SMB error: NT_STATUS_ACCESS_DENIED
       ↓
SELinux (not reached, but would also deny):
  ├─ If share ACL bypassed somehow (misconfiguration)
  ├─ SELinux would still check:
  │   ├─ User's AD groups don't include Finance
  │   └─ finance_share_t context requires Finance group
  └─ SELinux: DENY
       ↓
File System DAC (not reached, but would also deny):
  ├─ /srv/shares/departments/finance
  ├─ Group: Finance (GID 10200)
  ├─ Permissions: drwxrws--- (other = ---)
  └─ john (not in Finance group): NO ACCESS
       ↓
Audit Log (Failed Access):
  type=SYSCALL msg=audit(1704795315.789:5200): arch=c000003e
    syscall=257 success=no exit=-13 comm="smbd"
    key="samba_file_operations"

  type=AVC msg=audit(1704795315.789:5200): avc: denied { read }
    for pid=5678 comm="smbd" name="finance"
    scontext=system_u:system_r:smbd_t:s0
    tcontext=system_u:object_r:finance_share_t:s0
    tclass=dir permissive=0
       ↓
Monitoring Alert (INFO level):
  [10:15:45] INFO: Unauthorized share access attempt
    User: john@CORP.COMPANY.LOCAL
    Share: finance (Finance department data)
    Source: 10.0.130.35 (ws-employee-05)
    Result: ACCESS DENIED (not in Finance group)

    Context: Normal denial, user lacks authorization
    Risk Level: LOW (expected behavior)
    No action needed unless pattern emerges
       ↓
John sees:
  "\\file-server01\finance is not accessible. You might not have permission to use this network resource."
```

**Three Layers of Defense (Defense in Depth):**
1. Samba Share ACL - Checks AD group membership → DENY
2. SELinux MAC - Checks finance_share_t context → Would DENY if #1 bypassed
3. File System DAC - Checks POSIX permissions → Would DENY if #1 & #2 bypassed

---

## ClamAV On-Access Scanning

### **Scenario 4: User Uploads Malware (Blocked by ClamAV)**

```
[15:30 AM] Jane tries to upload email attachment to her home directory

Jane's email client:
  └─ Save attachment "invoice.pdf.exe" to \\file-server01\home-jane\Documents\
       ↓
SMB Upload:
  ├─ Source: 10.0.130.40 (ws-employee-08)
  ├─ File: invoice.pdf.exe (actually malware, not PDF)
  ├─ Destination: /srv/shares/home/jane/Documents/invoice.pdf.exe
       ↓
Samba begins write operation:
  ├─ Authentication: SUCCESS (jane's Kerberos ticket)
  ├─ Share access: home-jane (jane has access)
  ├─ File path: /srv/shares/home/jane/Documents/invoice.pdf.exe
  └─ Write starts...
       ↓
ClamAV On-Access Scanner (clamonacc):
  ├─ Kernel fanotify notification: File write detected
  ├─ Path: /srv/shares/home/jane/Documents/invoice.pdf.exe
  ├─ Scanner intercepts BEFORE write completes
       ↓
ClamAV Scan Engine:
  ├─ Signature database: daily.cvd (updated daily via freshclam)
  ├─ Scan invoice.pdf.exe
  ├─ File header: PE32 executable (not PDF!)
  ├─ Signature match: Win.Trojan.GenericKD-12345
  └─ VERDICT: VIRUS DETECTED
       ↓
ClamAV Actions:
  ├─ Block write operation (file NOT saved to disk)
  ├─ Quarantine: Move to /var/lib/clamav/quarantine/
  ├─ Log: /var/log/clamd.scan
  │   2026-01-09 15:30:42 Found Win.Trojan.GenericKD-12345 in invoice.pdf.exe
  └─ Execute virus event script: /usr/local/bin/virus-detected.sh
       ↓
Virus Event Script:
  #!/bin/bash
  VIRUS_NAME=$1
  FILENAME=$2

  # Log to syslog
  logger -t clamav "VIRUS: $VIRUS_NAME in $FILENAME"

  # Send to monitoring server
  echo "VIRUS|$(date)|file-server01|$VIRUS_NAME|$FILENAME|$USER" | \
    nc monitoring01 5140

  # Email IT security
  echo "Virus detected: $VIRUS_NAME in $FILENAME uploaded by $USER" | \
    mail -s "VIRUS ALERT" security@corp.company.local
       ↓
Samba Response to Client:
  └─ SMB error: NT_STATUS_ACCESS_DENIED
     (Generic error - doesn't reveal virus detection to avoid tipping off attacker)
       ↓
Jane sees:
  "The file could not be copied to the server. Access denied."
  (No indication it was malware - prevents attacker from testing evasion)
       ↓
Monitoring Alert (CRITICAL):
  [15:30:42] CRITICAL: Virus upload attempt blocked
    User: jane@CORP.COMPANY.LOCAL
    File: invoice.pdf.exe
    Virus: Win.Trojan.GenericKD-12345
    Source: 10.0.130.40 (ws-employee-08)
    Action: Upload BLOCKED, file quarantined

    Analysis:
      ⚠ Likely phishing email attachment
      ⚠ User attempted to save to file server (good - not executed locally)
      ⚠ Malware prevented from reaching backup (would persist if not caught)

    IMMEDIATE ACTIONS:
      ✓ File upload blocked automatically
      ✓ File quarantined: /var/lib/clamav/quarantine/invoice.pdf.exe
      ⚠ Scan ws-employee-08 for local infection
      ⚠ Check jane's email for phishing source
      ⚠ Security awareness training for jane

    Email: IT Security, jane's manager
    Quarantine: /var/lib/clamav/quarantine/ (retained 30 days)
       ↓
Audit Log:
  type=AVC msg=audit(1704802242.123:5300): avc: denied { write }
    for pid=6789 comm="clamonacc" name="invoice.pdf.exe"
    scontext=system_u:system_r:clamd_t:s0
    tcontext=system_u:object_r:samba_share_t:s0
    key="clamav_virus_block"
```

**ClamAV Protection Value:**
- ✅ **On-Access** - Scans before write completes (proactive)
- ✅ **Zero-Day Protection** - Signature updates daily (freshclam)
- ✅ **Backup Protection** - Malware never reaches backup server
- ✅ **Quarantine** - File preserved for analysis
- ✅ **Silent Blocking** - Doesn't reveal detection method to attacker

---

## LVM Snapshots (Ransomware Recovery)

### **Scenario 5: Ransomware Detection and Recovery**

```
[2:00 AM] Automated ransomware behavior detected

Monitoring System (anomaly detection):
  ├─ User: john@CORP.COMPANY.LOCAL
  ├─ Activity: 500 files modified in 30 seconds
  ├─ Pattern: Files renamed with .encrypted extension
  ├─ Assessment: RANSOMWARE
       ↓
Automatic Response (triggered by monitoring01):
  1. Kill SMB session for john
     $ smbcontrol smbd close-share home-john

  2. Block john's workstation at firewall
     $ firewall-cmd --zone=server --add-rich-rule='
       rule family="ipv4" source address="10.0.130.35" reject'

  3. Disable john's AD account
     $ ssh dc01 "samba-tool user disable john"

  4. Trigger immediate LVM snapshot (before more damage)
     $ lvcreate -L 20G -s -n emergency-snapshot-20260109-0200 /dev/vg0/shares
       ↓
Snapshot Created:
  ├─ Snapshot name: emergency-snapshot-20260109-0200
  ├─ Size: 20GB (COW - copy-on-write)
  ├─ Contains: State of /srv/shares at 2:00 AM
  │   ├─ home/john/* - Files BEFORE encryption
  │   └─ Other users unaffected
  └─ Mount point: /mnt/snapshot-recovery
       ↓
IT Response (3:00 AM - On-call engineer):
  1. Confirm ransomware (review audit logs)
     $ ausearch -k samba_file_operations -ui john | tail -500

  2. Mount snapshot
     $ mount /dev/vg0/emergency-snapshot-20260109-0200 /mnt/snapshot

  3. Verify clean files in snapshot
     $ ls /mnt/snapshot/home/john/Documents/
       project-proposal.docx (NOT project-proposal.docx.encrypted)

  4. Restore john's files from snapshot
     $ rsync -av /mnt/snapshot/home/john/ /srv/shares/home/john/

  5. Verify restoration
     $ ls /srv/shares/home/john/Documents/
       project-proposal.docx ✓ (clean file restored)

  6. Remove snapshot
     $ umount /mnt/snapshot
     $ lvremove /dev/vg0/emergency-snapshot-20260109-0200
       ↓
Recovery Complete:
  ├─ Time to detect: 30 seconds (anomaly detection)
  ├─ Time to contain: 2 minutes (auto-response)
  ├─ Time to recover: 30 minutes (IT engineer)
  ├─ Data loss: 0 hours (snapshot from 2:00 AM, attack at 2:00 AM)
  └─ Business impact: Minimal (john's account only, others unaffected)
       ↓
Post-Incident Actions:
  1. Forensic analysis of john's workstation
  2. Malware remediation (wipe and reimage)
  3. Security awareness training
  4. Review firewall logs (how did ransomware enter?)
  5. Update IDS rules based on attack pattern
```

**LVM Snapshot Strategy:**
```
Hourly snapshots (24-hour retention):
  ├─ snapshot-20260109-0100 (1:00 AM)
  ├─ snapshot-20260109-0200 (2:00 AM) ← Used for recovery
  ├─ snapshot-20260109-0300 (3:00 AM)
  └─ ... (up to 24 snapshots)

Daily snapshots (30-day retention):
  └─ snapshot-daily-20260109 (midnight)

Weekly snapshots (12-week retention):
  └─ snapshot-weekly-20260105 (Sunday)
```

---

## Quota Enforcement

### **Scenario 6: User Exceeds Quota**

```
[11:00 AM] John tries to save large video file

John's Application:
  └─ Save "project-video.mp4" (10GB) to \\file-server01\home-john\Videos\
       ↓
SMB Upload Begins:
  ├─ Chunk 1: 1GB written → SUCCESS
  ├─ Chunk 2: 1GB written → SUCCESS
  ├─ Chunk 3: 1GB written → SUCCESS
  ├─ John's usage: 48GB / 50GB quota (WARNING threshold: 45GB)
       ↓
Quota Warning (at 45GB):
  ├─ XFS quota system detects: john has exceeded warning threshold
  ├─ Syslog: user john exceeded 45GB warning on /srv/shares
  └─ Email sent to john: "You are using 90% of your file server quota (45GB/50GB)"
       ↓
Upload continues:
  ├─ Chunk 4: 1GB written → SUCCESS (49GB total)
  ├─ Chunk 5: 1GB write attempt...
       ↓
Quota Hard Limit Reached:
  ├─ john's usage: 50GB / 50GB quota (HARD LIMIT)
  ├─ XFS quota enforcement: EDQUOT (Disk quota exceeded)
  └─ Write operation: FAILED
       ↓
Samba Error to Client:
  └─ NT_STATUS_DISK_FULL
       ↓
John sees:
  "There is not enough space on file-server01.
   You need an additional 1GB to copy this file."
       ↓
Monitoring Alert (INFO):
  [11:15:00] INFO: User quota exceeded
    User: john@CORP.COMPANY.LOCAL
    Share: home-john
    Usage: 50GB / 50GB (100%)
    File: project-video.mp4 (partial upload)

    Action Required:
      ⚠ Contact john to delete old files
      ⚠ Or: Increase quota if justified (manager approval)

    Email: john@corp.company.local, IT helpdesk
       ↓
Resolution Options:
  1. John deletes old files to free space
  2. IT increases quota (if business need)
  3. John moves file to department share (if work-related)
```

**Quota Configuration:**
```bash
# XFS quotas configured in /etc/fstab
/dev/vg0/shares  /srv/shares  xfs  defaults,usrquota,grpquota  0 0

# User quota limits
xfs_quota -x -c 'limit -u bsoft=45G bhard=50G john' /srv/shares

# Group quota limits (department shares)
xfs_quota -x -c 'limit -g bsoft=450G bhard=500G Finance' /srv/shares

# Report quota usage
xfs_quota -x -c 'report -h' /srv/shares
```

---

(Continuing in next message due to length...)
## Firewall Configuration (firewalld)

```bash
# Default zone
firewall-cmd --set-default-zone=server

# Allow SMB from workstation/admin VLANs
firewall-cmd --permanent --zone=server --add-rich-rule='
  rule family="ipv4"
  source address="10.0.130.0/24"
  service name="samba"
  accept'

firewall-cmd --permanent --zone=server --add-rich-rule='
  rule family="ipv4"
  source address="10.0.131.0/24"
  service name="samba"
  accept'

# Allow from server VLAN (backup, monitoring)
firewall-cmd --permanent --zone=server --add-rich-rule='
  rule family="ipv4"
  source address="10.0.120.0/24"
  service name="samba"
  accept'

# SSH only from ansible-ctrl
firewall-cmd --permanent --zone=server --add-rich-rule='
  rule family="ipv4"
  source address="10.0.120.50/32"
  service name="ssh"
  accept'

# Rsyslog to monitoring01
firewall-cmd --permanent --zone=server --add-rich-rule='
  rule family="ipv4"
  destination address="10.0.120.60"
  port port="514" protocol="tcp"
  accept'

# Default deny
firewall-cmd --permanent --zone=server --set-target=DROP

# Reload
firewall-cmd --reload
```

---

## Auditd Rules (/etc/audit/rules.d/file-server.rules)

```bash
# File server audit rules

# Watch all Samba share modifications
-w /srv/shares -p wa -k samba_file_operations

# Watch Finance share (high sensitivity)
-w /srv/shares/departments/finance -p rwxa -k finance_file_access
-a always,exit -F dir=/srv/shares/departments/finance -F perm=r -k finance_read
-a always,exit -F dir=/srv/shares/departments/finance -F perm=w -k finance_write

# Watch HR share (PII)
-w /srv/shares/departments/hr -p rwxa -k hr_file_access

# Watch Management share
-w /srv/shares/departments/management -p rwxa -k mgmt_file_access

# Watch Samba configuration changes
-w /etc/samba/smb.conf -p wa -k samba_config_change

# Watch SELinux context changes
-a always,exit -F arch=b64 -S setxattr -S lsetxattr -S fsetxattr -k selinux_context_change

# Monitor Samba process
-a always,exit -F arch=b64 -S execve -F exe=/usr/sbin/smbd -k samba_process

# Detect mass file operations (potential ransomware)
-a always,exit -F arch=b64 -S unlink -S unlinkat -S rename -S renameat -k mass_file_deletion

# Monitor quota commands
-w /usr/sbin/xfs_quota -p x -k quota_management
```

---

## Test Cases for Validation

### Test Case 1: User Access Home Directory
```
Test: John accesses his home directory
Expected: Access granted, operation logged
Command: smbclient //file-server01/home-john -U john@CORP.COMPANY.LOCAL -k
```

### Test Case 2: Department Share Access (Authorized)
```
Test: Sarah (Finance) accesses Finance share
Expected: Access granted, SMB3 encryption enforced
Command: smbclient //file-server01/finance -U sarah@CORP.COMPANY.LOCAL -k
```

### Test Case 3: Department Share Access (Unauthorized)
```
Test: John tries to access Finance share
Expected: Access denied, attempt logged
Command: smbclient //file-server01/finance -U john@CORP.COMPANY.LOCAL -k
Expected: NT_STATUS_ACCESS_DENIED
```

### Test Case 4: SELinux Enforcement
```
Test: Direct file access bypassing Samba
Expected: SELinux blocks (if attempted by unauthorized user)
Command: cat /srv/shares/departments/finance/file.xlsx (as non-Finance user)
Expected: Permission denied
```

### Test Case 5: Virus Upload Detection
```
Test: Upload EICAR test file
Expected: ClamAV blocks upload, file quarantined
Command: echo 'X5O!P%@AP[4\PZX54(P^)7CC)7}$EICAR-STANDARD-ANTIVIRUS-TEST-FILE!$H+H*' > eicar.txt
        smbclient //file-server01/company -U john -c "put eicar.txt"
Expected: Upload blocked, alert generated
```

### Test Case 6: Quota Enforcement
```
Test: User exceeds quota
Expected: Write fails, quota warning generated
Command: dd if=/dev/zero of=/home/john/bigfile bs=1G count=65
Expected: Disk quota exceeded
```

### Test Case 7: Snapshot Recovery
```
Test: Delete file, recover from snapshot
Expected: File restored from hourly snapshot
Commands:
  rm /srv/shares/company/important.doc
  mount /dev/vg0/shares-snapshot-latest /mnt/snapshot
  cp /mnt/snapshot/company/important.doc /srv/shares/company/
```

### Test Case 8: Ransomware Detection
```
Test: Simulate mass file encryption
Expected: Anomaly detected, session killed, snapshot triggered
Simulate: Script that renames 50+ files with .encrypted extension in <1 min
```

---

## Compliance Benefits

### SOX (Financial Data)
✅ **Access Control** - Only Finance group accesses financial data
✅ **Encryption** - SMB3 encryption mandatory for Finance share
✅ **Audit Trail** - All access to payroll/financial files logged
✅ **Integrity** - Snapshots provide point-in-time recovery
✅ **Separation** - Finance data isolated from other departments

### GDPR (Personal Data)
✅ **Access Limitation** - HR data only accessible by authorized personnel
✅ **Audit Logging** - All PII access tracked (Article 30 compliance)
✅ **Encryption in Transit** - SMB3 encryption protects employee data
✅ **Right to Erasure** - Files can be deleted with audit trail
✅ **Breach Notification** - Monitoring detects unauthorized access

### HIPAA (Healthcare Data - if applicable)
✅ **Authentication** - Kerberos with AD integration
✅ **Access Control** - Role-based via AD groups
✅ **Audit Controls** - Comprehensive logging of PHI access
✅ **Encryption** - Data in transit (SMB3) and at rest (LUKS)
✅ **Integrity Controls** - SELinux + Snapshots

---

## Performance Optimization

### Samba Tuning (/etc/samba/smb.conf)

```ini
[global]
    # Kernel oplocks (performance)
    kernel oplocks = no
    kernel share modes = yes

    # Read ahead (large files)
    read raw = yes
    write raw = yes

    # Socket options
    socket options = TCP_NODELAY IPTOS_LOWDELAY SO_RCVBUF=131072 SO_SNDBUF=131072

    # Async I/O
    aio read size = 16384
    aio write size = 16384

    # Wide links (disabled for security)
    unix extensions = no
    wide links = no
```

### XFS Mount Options (/etc/fstab)

```
/dev/vg0/shares  /srv/shares  xfs  defaults,noatime,nodiratime,logbufs=8,logbsize=256k,usrquota,grpquota  0 0
```

**Optimizations:**
- `noatime, nodiratime` - Reduce metadata updates
- `logbufs=8, logbsize=256k` - Larger transaction log for better performance
- `usrquota, grpquota` - Quotas enabled

---

**Document Version:** 1.0
**Last Updated:** 2026-01-09
**For:** File Server (file-server01) - Rocky Linux 9 with Samba
**OS:** Rocky Linux 9.3 (Oracle Linux compatible)
**Service:** Samba 4.x File Server with AD Integration
**Key Features:** SELinux MAC, LVM Snapshots, ClamAV, Full Audit Logging
