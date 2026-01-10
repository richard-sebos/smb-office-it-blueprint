# Backup Server Security Flow - SMB Office IT Blueprint

## Document Purpose
This document traces security flows through the backup server in the SMB Office IT Blueprint. It demonstrates how backup collection, encryption, retention, and recovery work together across multiple security layers to ensure business continuity while maintaining data protection.

**Target Audience:** Security auditors, compliance officers, IT administrators creating test cases and validation playbooks.

---

## Infrastructure Context

### Backup Server Role
- **Hostname:** `backup-server`
- **OS:** Rocky Linux 9 (SELinux enforcing)
- **VLAN:** 120 (Servers) - `10.0.120.60/24`
- **Purpose:** Centralized backup storage and recovery
- **Backup Software:** Bacula (enterprise-grade open source)
- **Storage:** 4TB RAID6 array + offsite replication
- **Encryption:** AES-256 for all backups (at-rest and in-transit)
- **Retention:** 90 days incremental + 7 years annual (SOX compliance)

### Network Architecture
```
┌─────────────────────────────────────────────────────────────────┐
│                      pfSense Firewall                            │
│  VLAN 110 (Mgmt) │ VLAN 120 (Servers) │ VLAN 130 (Work)         │
└─────────────────────────────────────────────────────────────────┘
         │                    │                     │
         │                    │                     │
    ┌────────────┐      ┌──────────────┐     ┌──────────┐
    │ansible-ctrl│      │backup-server │     │laptop-   │
    │10.0.120.50 │      │10.0.120.60   │     │it-admin-│
    │(Config)    │      │Bacula Director│     │01       │
    └────────────┘      └──────────────┘     └──────────┘
                              │
                              │ (Pull backups from all sources)
                              ├────────────┬─────────────┬─────────────┐
                              │            │             │             │
                         ┌─────────┐  ┌─────────┐  ┌─────────┐  ┌─────────┐
                         │dc01/dc02│  │file-srv │  │monitor  │  │print-srv│
                         │10.0.120.│  │10.0.120.│  │10.0.120.│  │10.0.120.│
                         │10/11    │  │20       │  │40       │  │30       │
                         └─────────┘  └─────────┘  └─────────┘  └─────────┘
                              │
                              ↓
                         (Offsite Replication)
                         Cloud Storage (AWS S3)
                         Encrypted, Immutable, 7-year retention
```

**Key Security Boundaries:**
1. **Backup Server → Source Hosts:** Bacula client (9102/tcp) with TLS + PSK authentication
2. **IT Staff → Backup Server:** SSH (ansible-ctrl only) + Bacula Console (bconsole) with password
3. **Backup Data at Rest:** AES-256 encryption with key stored in TPM
4. **Offsite Replication:** S3 with SSE-KMS encryption + versioning + object lock (immutable)
5. **Recovery Process:** JIT elevation required + audit logging + test restoration quarterly

---

## Security Requirements

| Requirement | Implementation | Verification |
|------------|---------------|--------------|
| **Data Encryption (at-rest)** | AES-256 with TPM-stored keys | Test decryption without key (should fail) |
| **Data Encryption (in-transit)** | TLS 1.3 for Bacula client connections | Test plaintext backup attempt (should fail) |
| **Authentication** | Bacula PSK (pre-shared keys) per client | Test backup with wrong PSK (should fail) |
| **Network Isolation** | Only backup-server can initiate connections | Test client-initiated connection (should fail) |
| **Backup Integrity** | SHA-256 checksums for all backups | Test corrupted backup detection |
| **Retention Policy** | 90 days incremental, 7 years annual | Verify automated pruning of old backups |
| **Immutable Backups** | S3 object lock (WORM), no deletion <7 years | Test backup deletion attempt (should fail) |
| **Access Control** | JIT elevation required for recovery | Test recovery without approval (should fail) |
| **Disaster Recovery** | Offsite replication to AWS S3 (cross-region) | Test recovery from S3 (quarterly drill) |
| **Audit Logging** | All backup/recovery operations logged | Verify all operations tracked |

---

## Backup Job Flow - Detailed Walkthrough

### Scenario 1: Automated Nightly Backup of File Server

**Context:**
- Source: file-server01 (10.0.120.20)
- Target: backup-server (10.0.120.60)
- Schedule: Daily 2:00 AM (incremental), Monthly 1st (full)
- Today: 2026-01-09 02:00:00 (incremental backup)

**Step-by-Step Security Flow:**

#### Step 1: Bacula Scheduler Triggers Job
```
# On backup-server (Bacula Director)
bacula-dir (PID 1234) → Checks schedule

Job: "FileServer-Daily-Incremental"
  Schedule: Daily at 02:00
  Client: file-server01-fd
  FileSet: FileServerFiles
  Storage: backup-server-sd
  Pool: Daily-Incremental
  Level: Incremental (since last full backup)
```

**Job Configuration (/etc/bacula/bacula-dir.conf):**
```
Job {
  Name = "FileServer-Daily-Incremental"
  Type = Backup
  Level = Incremental
  Client = file-server01-fd
  FileSet = "FileServerFiles"
  Schedule = "DailyCycle"
  Storage = File
  Pool = Daily-Incremental
  Messages = Standard
  Priority = 10
  Write Bootstrap = "/var/lib/bacula/%c.bsr"
}

FileSet {
  Name = "FileServerFiles"
  Include {
    Options {
      signature = SHA256
      compression = GZIP9
      encryption {
        enable = yes
        algorithm = AES-256-CBC
        key = "/etc/bacula/keys/file-server01.key"
      }
    }
    File = /srv/shares
    File = /etc
    File = /var/log
  }
  Exclude {
    File = /srv/shares/.snapshots  # LVM snapshots already handled
    File = /tmp
  }
}

Client {
  Name = file-server01-fd
  Address = 10.0.120.20
  FDPort = 9102
  Catalog = MyCatalog
  Password = "{{ file_server_bacula_psk }}"  # From Ansible Vault
  File Retention = 90 days
  Job Retention = 90 days
  AutoPrune = yes
  TLS Enable = yes
  TLS Require = yes
  TLS CA Certificate File = /etc/bacula/ssl/ca.crt
  TLS Certificate = /etc/bacula/ssl/backup-server.crt
  TLS Key = /etc/bacula/ssl/backup-server.key
}
```

**Timing:** 0ms (schedule check is instant)

#### Step 2: Bacula Director Connects to File Server Client
```
backup-server:9101 → file-server01:9102
  Protocol: Bacula File Daemon (FD) over TLS 1.3
  Authentication: Pre-shared key (PSK) from Ansible Vault

TLS Handshake:
  1. ClientHello (backup-server → file-server01)
     - Cipher: TLS_AES_256_GCM_SHA384
     - Server Name: file-server01-fd

  2. ServerHello (file-server01 → backup-server)
     - Certificate: /etc/bacula/ssl/file-server01.crt
     - Verify with CA: /etc/bacula/ssl/ca.crt

  3. PSK Authentication
     - backup-server sends: Password = {{ file_server_bacula_psk }}
     - file-server01 verifies: Match with /etc/bacula/bacula-fd.conf
     - Result: AUTHENTICATED
```

**Firewall Check (pfSense):**
```
Rule: allow-bacula-director-to-clients
  Source: 10.0.120.60 (backup-server)
  Destination: 10.0.120.0/24:9102 (Bacula clients)
  Action: PASS

Log: Jan 09 02:00:00 pfsense filterlog: PASS,120,10.0.120.60,10.0.120.20,tcp,9102
```

**Firewall Check (file-server01 firewalld):**
```bash
# Only backup-server can connect to Bacula FD
firewall-cmd --permanent --add-rich-rule='
  rule family="ipv4"
  source address="10.0.120.60/32"
  port protocol="tcp" port="9102"
  accept'

# All other sources BLOCKED
firewall-cmd --permanent --zone=server --set-target=DROP
```

**Timing:** 150ms (TLS handshake + PSK auth)

#### Step 3: File Discovery and Selection
```
# On file-server01 (Bacula FD)
bacula-fd[5678]: Job FileServer-Daily-Incremental.2026-01-09_02.00.00_03 started

# Scan fileset: /srv/shares, /etc, /var/log
# Criteria: Modified since last incremental (2026-01-08 02:00:00)

Files discovered:
  /srv/shares/departments/finance/Q1-report.xlsx (modified 2026-01-08 14:23)
  /srv/shares/departments/hr/employee-reviews-2026.docx (modified 2026-01-08 16:45)
  /etc/samba/smb.conf (modified 2026-01-08 10:30)
  /var/log/samba/audit.log (rotated 2026-01-08 23:59)
  ... (847 files total, 2.3GB)
```

**SELinux Check:**
```
# Can bacula-fd read /srv/shares?
Source context: system_u:system_r:bacula_t:s0 (bacula-fd process)
Target context: system_u:object_r:samba_share_t:s0 (/srv/shares)
Class: dir, file
Permission: read, getattr, open

SELinux policy:
  allow bacula_t samba_share_t:dir { read getattr search open };
  allow bacula_t samba_share_t:file { read getattr open };

Result: ALLOW
```

**Timing:** 12 seconds (scan 450,000 files, select 847 modified)

#### Step 4: Data Compression and Encryption (on file-server01)
```
# For each file selected:
1. Read file content
   - /srv/shares/departments/finance/Q1-report.xlsx (5.2MB)

2. Compress with GZIP9
   - Original: 5.2MB → Compressed: 3.8MB (27% reduction)

3. Calculate SHA-256 checksum
   - Checksum: a1b2c3d4e5f6...9876543210

4. Encrypt with AES-256-CBC
   - Key: /etc/bacula/keys/file-server01.key (256-bit)
   - IV: Random 128-bit
   - Encrypted size: 3.8MB (no size increase with AES-CBC)

5. Stream to backup-server over TLS connection
```

**Encryption Key Management:**
```bash
# Key stored on file-server01 (generated during Bacula client setup)
$ ls -la /etc/bacula/keys/file-server01.key
-rw-------. 1 bacula bacula 32 Jan 01 10:00 /etc/bacula/keys/file-server01.key

# Key also stored on backup-server (for recovery)
$ ssh backup-server ls -la /etc/bacula/keys/file-server01.key
-rw-------. 1 bacula bacula 32 Jan 01 10:00 /etc/bacula/keys/file-server01.key

# Keys backed up to TPM (Trusted Platform Module)
$ tpm2_nvread 0x1500001 | xxd
0000000: a1b2 c3d4 e5f6 7890 1234 5678 9abc def0  ................
```

**Timing:** 180 seconds (compress/encrypt/transfer 2.3GB @ ~13MB/s)

#### Step 5: Data Storage on Backup Server
```
# On backup-server (Bacula Storage Daemon)
bacula-sd[6789]: Writing to volume "Daily-Inc-2026-01-09"

Storage path: /backup/bacula/volumes/Daily-Inc-2026-01-09
  Volume size: 2.3GB (compressed/encrypted)
  File count: 847 files
  Checksum catalog: /backup/bacula/catalog/FileServer-2026-01-09.db
```

**Volume Structure:**
```
/backup/bacula/volumes/
├── Daily-Inc-2026-01-09 (2.3GB)
├── Daily-Inc-2026-01-08 (1.9GB)
├── Daily-Inc-2026-01-07 (2.1GB)
├── ...
├── Full-2026-01-01 (450GB - full backup)
└── Full-2025-12-01 (448GB - previous full)
```

**SELinux Check (backup-server):**
```
Source context: system_u:system_r:bacula_t:s0 (bacula-sd process)
Target context: system_u:object_r:bacula_store_t:s0 (/backup/bacula/volumes)
Class: file
Permission: create, write

SELinux policy:
  allow bacula_t bacula_store_t:file { create write open };

Result: ALLOW
```

**Disk Space Check:**
```bash
# RAID6 array: 4TB total, 2.8TB used (70%)
$ df -h /backup
Filesystem      Size  Used Avail Use% Mounted on
/dev/md0        3.7T  2.8T  900G  76% /backup

# Alert if >80% used (configured in monitoring01)
```

**Timing:** 30 seconds (write to RAID6 array)

#### Step 6: Catalog Update
```
# Bacula updates PostgreSQL catalog database
bacula-dir → PostgreSQL (localhost:5432)
  Database: bacula_catalog
  Table: File
    INSERT INTO File (
      FileId, FileIndex, JobId, PathId, FilenameId,
      LStat, MD5, DeltaSeq
    ) VALUES (
      1234567, 1, 42, 5678, 9012,
      'rw-r--r-- 1 finance finance 5242880 2026-01-08 14:23',
      'a1b2c3d4e5f6...9876543210', 0
    );

Total catalog entries: 450,000 files (cumulative across all backups)
Catalog size: 12GB
Catalog backup: Daily to /backup/bacula/catalog-backups/
```

**Timing:** 5 seconds (database insert for 847 files)

#### Step 7: Backup Completion and Verification
```
# Bacula verifies backup integrity
bacula-dir: Job FileServer-Daily-Incremental.2026-01-09_02.00.00_03 completed successfully

Statistics:
  Files backed up: 847
  Bytes transferred: 2,411,724,800 (2.3GB)
  Compression: 27% (3.1GB → 2.3GB)
  Encryption: AES-256-CBC
  Duration: 3 minutes 47 seconds
  Transfer rate: 10.6 MB/s
  Errors: 0
```

**Bootstrap File (for recovery):**
```bash
# /var/lib/bacula/file-server01-fd.bsr
Volume="Daily-Inc-2026-01-09"
Storage=File
VolSessionId=1
VolSessionTime=1736386800
VolAddr=0-2411724800
FileIndex=1-847
Count=847
```

**Auditd Log (backup-server):**
```
type=BACULA_JOB msg=audit(1736387027.456:7890):
  job_name="FileServer-Daily-Incremental" job_id=42
  client="file-server01-fd" level="Incremental"
  files=847 bytes=2411724800 duration=227s result=success
  key="backup_job_complete"
```

**Rsyslog Forward to monitoring01:**
```
Jan 09 02:03:47 backup-server bacula-dir[1234]:
  FileServer-Daily-Incremental.2026-01-09_02.00.00_03: Job completed successfully
    Files=847 Bytes=2.3GB Duration=3m47s

→ rsyslog (TCP/TLS) → monitoring01:514
→ Elasticsearch indexes
→ Wazuh SIEM: Backup completion verified (daily health check)
```

**Total Time:** ~4 minutes (227 seconds)

---

### Scenario 2: File Recovery After Accidental Deletion

**Context:**
- User: Sarah (Manager) accidentally deleted `/srv/shares/departments/hr/annual-budget-2026.xlsx`
- Deletion time: 2026-01-09 10:30:00
- Last backup: 2026-01-09 02:00:00 (file exists in backup)
- Recovery requested: 2026-01-09 11:00:00

**Step-by-Step Security Flow:**

#### Step 1: IT Admin Receives Recovery Request
```
# Sarah emails it-support@office.local:
Subject: URGENT: Deleted file recovery needed
Body: I accidentally deleted annual-budget-2026.xlsx from the HR share.
      Can you restore it from last night's backup?
      File path: /srv/shares/departments/hr/annual-budget-2026.xlsx
      Ticket: IT-2026-0023
```

#### Step 2: IT Admin SSH to Backup Server (via ansible-ctrl)
```bash
# On laptop-it-admin-01
alex@laptop-it-admin-01$ ssh ansible-ctrl.office.local
alex@ansible-ctrl$ ssh backup-server

# Kerberos + 2FA authentication (same as ansible-ctrl access)
```

#### Step 3: Request JIT Elevation for Recovery
```bash
alex@backup-server$ sudo bconsole
[sudo] password for alex:

# JIT approval required for production data recovery
sudo: JIT approval required for backup recovery operations
sudo: Requesting approval from IT Manager (sarah@office.local)...

# Sarah approves via mobile app (2FA with Yubikey)
# Note: Sarah is approving recovery of her OWN deleted file
sudo: Approval granted by sarah@office.local at 2026-01-09T11:05:00Z
sudo: Elevation valid for 1 hour
```

**Auditd Log:**
```
type=USER_AUTH msg=audit(1736427900.123:8901):
  pid=7890 uid=1002 auid=1002 ses=15
  msg='op=PAM:authentication grantors=pam_sss,pam_jit_approval acct="alex"
  exe="/usr/bin/sudo" approval="sarah@OFFICE.LOCAL"
  purpose="recovery_IT-2026-0023" res=success'
  key="jit_elevation_recovery"
```

#### Step 4: Query Bacula Catalog for File
```
alex@backup-server$ sudo bconsole
Connecting to Director backup-server:9101

Enter a period to cancel a command.
*estimate job=FileServer-Daily-Incremental listing client=file-server01-fd \
  file=/srv/shares/departments/hr/annual-budget-2026.xlsx

Catalog query:
  SELECT FileId, JobId, LStat, MD5
  FROM File
  JOIN Path ON File.PathId = Path.PathId
  JOIN Filename ON File.FilenameId = Filename.FilenameId
  WHERE Path.Path = '/srv/shares/departments/hr/'
    AND Filename.Name = 'annual-budget-2026.xlsx'
  ORDER BY JobId DESC
  LIMIT 10;

Results:
  FileId: 1234890
  JobId: 42 (FileServer-Daily-Incremental.2026-01-09_02.00.00_03)
  Volume: Daily-Inc-2026-01-09
  Backup Time: 2026-01-09 02:15:23
  Size: 8,945,234 bytes
  MD5: b2c3d4e5f6a7890123456789abcdef01
```

**Timing:** 2 seconds (PostgreSQL query on indexed catalog)

#### Step 5: Initiate Restore Job
```
*restore client=file-server01-fd fileset=FileServerFiles where=/tmp/bacula-restore \
  file=/srv/shares/departments/hr/annual-budget-2026.xlsx

You have selected the following JobId: 42

The defined Restore Job resources are:
     1: RestoreFiles
Select Restore Job (1-1): 1

Bootstrap records written to /var/lib/bacula/restore.bsr

The Job will require the following Volumes:
   Daily-Inc-2026-01-09

1,847 files selected to be restored.

Run Restore job
JobName:         RestoreFiles
Bootstrap:       /var/lib/bacula/restore.bsr
Where:           /tmp/bacula-restore
Replace:         Always
FileSet:         FileServerFiles
Backup Client:   file-server01-fd
Restore Client:  file-server01-fd
Storage:         File
When:            2026-01-09 11:06:00
Catalog:         MyCatalog
Priority:        10
OK to run? (yes/mod/no): yes

Job queued. JobId=43
```

**Timing:** 5 seconds (user interaction + job queue)

#### Step 6: Restore Job Execution
```
# Bacula reads from volume
bacula-sd[6789]: Reading volume "Daily-Inc-2026-01-09"
  Position: 1,234,890,000 bytes (seek to file)
  Read: 8,945,234 bytes (encrypted/compressed)

# Decrypt with AES-256 (key from /etc/bacula/keys/file-server01.key)
Decryption:
  Algorithm: AES-256-CBC
  Key: /etc/bacula/keys/file-server01.key
  IV: (from volume header)
  Result: Decrypted data (GZIP9 compressed)

# Decompress
Decompression:
  Input: 8,945,234 bytes (compressed)
  Output: 12,458,901 bytes (original size)
  Compression ratio: 28%

# Verify checksum
Checksum verification:
  Algorithm: SHA-256
  Catalog checksum: b2c3d4e5f6a7890123456789abcdef01
  Computed checksum: b2c3d4e5f6a7890123456789abcdef01
  Result: MATCH ✓
```

**Timing:** 8 seconds (read from RAID6, decrypt, decompress)

#### Step 7: Transfer to File Server
```
# Bacula sends file to file-server01-fd
backup-server → file-server01:9102 (TLS connection)
  Destination: /tmp/bacula-restore/srv/shares/departments/hr/annual-budget-2026.xlsx
  Transfer: 12,458,901 bytes
  Duration: 3 seconds

# On file-server01
bacula-fd[5678]: Restored file: /tmp/bacula-restore/srv/shares/departments/hr/annual-budget-2026.xlsx
  Owner: root:root (will be corrected by IT admin)
  Permissions: -rw-r--r--
  Size: 12,458,901 bytes
  Checksum: b2c3d4e5f6a7890123456789abcdef01 (verified)
```

**Timing:** 3 seconds (transfer over gigabit network)

#### Step 8: IT Admin Moves File to Final Location
```bash
# On file-server01 (via SSH from backup-server)
alex@file-server01$ sudo mv /tmp/bacula-restore/srv/shares/departments/hr/annual-budget-2026.xlsx \
  /srv/shares/departments/hr/annual-budget-2026.xlsx

alex@file-server01$ sudo chown hr:hr /srv/shares/departments/hr/annual-budget-2026.xlsx
alex@file-server01$ sudo chmod 660 /srv/shares/departments/hr/annual-budget-2026.xlsx

# Verify SELinux context
alex@file-server01$ sudo restorecon -v /srv/shares/departments/hr/annual-budget-2026.xlsx
Relabeled /srv/shares/departments/hr/annual-budget-2026.xlsx from unconfined_u:object_r:admin_home_t:s0
  to system_u:object_r:samba_share_t:s0
```

**Timing:** 5 seconds (file operations)

#### Step 9: Verification and Notification
```bash
# Verify file is accessible
alex@file-server01$ sudo -u sarah ls -lh /srv/shares/departments/hr/annual-budget-2026.xlsx
-rw-rw----. 1 hr hr 12M Jan  8 16:45 /srv/shares/departments/hr/annual-budget-2026.xlsx

# Success! Notify Sarah
alex@file-server01$ mail -s "File Restored: annual-budget-2026.xlsx" sarah@office.local <<EOF
Hi Sarah,

Your file has been successfully restored from last night's backup:
  File: annual-budget-2026.xlsx
  Location: HR department share
  Restored from: 2026-01-09 02:00 backup
  Ticket: IT-2026-0023

The file is now accessible via the network share.

-IT Support
EOF
```

**Auditd Log (backup-server + file-server01):**
```
# backup-server
type=BACULA_RESTORE msg=audit(1736427966.789:8902):
  job_name="RestoreFiles" job_id=43
  client="file-server01-fd" files=1 bytes=12458901
  destination="/tmp/bacula-restore" duration=16s result=success
  restored_by="alex@OFFICE.LOCAL" approval="sarah@OFFICE.LOCAL"
  ticket="IT-2026-0023" key="backup_restore_complete"

# file-server01
type=SYSCALL msg=audit(1736427971.123:9012): arch=c000003e syscall=82 success=yes
  comm="mv" exe="/usr/bin/mv"
  subj=unconfined_u:unconfined_r:unconfined_t:s0
  name="/srv/shares/departments/hr/annual-budget-2026.xlsx"
  key="file_restore_final"
```

**Wazuh SIEM Alert:**
```
Rule 100230: Data recovery operation completed
  Severity: Informational
  User: alex@OFFICE.LOCAL
  Approval: sarah@OFFICE.LOCAL
  File: annual-budget-2026.xlsx
  Source backup: Daily-Inc-2026-01-09 (2026-01-09 02:00)
  Ticket: IT-2026-0023
  Action: Log for audit trail + verify business continuity test
```

**Total Time:** ~30 seconds (actual recovery) + 5 minutes (JIT approval + user interaction)

---

### Scenario 3: Ransomware Recovery from Immutable S3 Backup

**Context:**
- Date: 2026-01-10 08:00:00
- Incident: Ransomware encrypted all files on file-server01
- Encryption timestamp: 2026-01-10 06:45:00 (detected by monitoring01)
- Last good backup: 2026-01-10 02:00:00 (incremental, before ransomware)
- Last full backup: 2026-01-01 02:00:00 (monthly full)
- Local backups: Potentially compromised (ransomware may have encrypted them)
- S3 backups: Immutable with object lock (WORM - Write Once Read Many)

**Step-by-Step Security Flow:**

#### Step 1: Ransomware Detection and Response
```
# monitoring01 (Wazuh SIEM) detects mass file encryption
Jan 10 06:45:23 monitoring01 wazuh-analysisd:
  Rule 100100: Possible ransomware - 50+ file operations in 60s
  User: john@OFFICE.LOCAL
  Workstation: laptop-john-01 (10.0.130.20)
  Target: file-server01
  Files affected: 15,234 (and counting...)

# Automated response:
1. Kill john's SMB session on file-server01
2. Block laptop-john-01 at pfSense firewall (isolate from network)
3. Snapshot file-server01 (capture ransomware state for forensics)
4. Alert IT team (PagerDuty + email + SMS)
```

**Timing:** 2 minutes from initial encryption to network isolation

#### Step 2: IT Team Assesses Damage
```bash
# IT Manager Sarah SSH to file-server01 (via ansible-ctrl)
sarah@file-server01$ ls /srv/shares/departments/finance/
Q1-report.xlsx.encrypted
Q2-forecast.xlsx.encrypted
annual-budget-2026.xlsx.encrypted
... (all files encrypted with .encrypted extension)

sarah@file-server01$ cat /srv/shares/README-RANSOM.txt
YOUR FILES HAVE BEEN ENCRYPTED!
To decrypt your files, send 5 BTC to: [bitcoin address]
After payment, email [attacker email] for decryption key.

# Check local backups
sarah@backup-server$ sudo ls /backup/bacula/volumes/
Daily-Inc-2026-01-10  <-- Created at 02:00, BEFORE ransomware (06:45)
Daily-Inc-2026-01-09
... (older backups)

# Verify local backup integrity
sarah@backup-server$ sudo bacula-dir
*list files jobid=44  # Latest backup (2026-01-10 02:00)
+----------------+-------+----------+
| FileName       | Size  | LStat    |
+----------------+-------+----------+
| Q1-report.xlsx | 5.2MB | rw-r--r--
| Q2-forecast... | 3.8MB | rw-r--r--
... (all files present, NOT encrypted)

Result: Local backups are CLEAN (ransomware occurred after backup)
```

**Timing:** 5 minutes (damage assessment)

#### Step 3: Decision - Full Restore from S3 (Immutable Backup)
```
# IT Team decision (Sarah + Alex):
# - Local backups look clean, but we'll verify against S3 for certainty
# - S3 backups are immutable (object lock), guaranteed no tampering
# - Restore from S3 provides highest confidence

# Check S3 backup availability
alex@backup-server$ aws s3 ls s3://office-backups-immutable/bacula/
2026-01-10 02:15:00  2411724800 Daily-Inc-2026-01-10.bak
2026-01-09 02:15:00  1987654321 Daily-Inc-2026-01-09.bak
2026-01-01 02:30:00 483729481728 Full-2026-01-01.bak
... (7 years of backups)

# Verify S3 object lock (immutable)
alex@backup-server$ aws s3api get-object-retention \
  --bucket office-backups-immutable \
  --key bacula/Daily-Inc-2026-01-10.bak
{
  "Retention": {
    "Mode": "GOVERNANCE",
    "RetainUntilDate": "2033-01-10T00:00:00.000Z"
  }
}

Result: S3 backup is immutable until 2033 (7-year SOX retention)
        Even AWS root account cannot delete before this date
```

**Timing:** 2 minutes (S3 verification)

#### Step 4: Download S3 Backup to Local
```bash
# Request JIT elevation for full system recovery
alex@backup-server$ sudo -v
[sudo] password for alex:

sudo: CRITICAL OPERATION - Full system recovery from S3
sudo: Requires dual approval: IT Manager + CTO
sudo: Requesting approval from sarah@office.local AND cto@office.local...

# Both approve via mobile app (2FA)
sudo: Approval granted by sarah@office.local at 2026-01-10T08:10:00Z
sudo: Approval granted by cto@office.local at 2026-01-10T08:11:00Z
sudo: Dual approval confirmed. Elevation valid for 4 hours (disaster recovery)

# Download full backup from S3
alex@backup-server$ sudo aws s3 cp \
  s3://office-backups-immutable/bacula/Full-2026-01-01.bak \
  /backup/bacula/s3-restore/Full-2026-01-01.bak

# Download incremental backups
for date in 01-02 01-03 01-04 ... 01-10; do
  sudo aws s3 cp \
    s3://office-backups-immutable/bacula/Daily-Inc-2026-${date}.bak \
    /backup/bacula/s3-restore/Daily-Inc-2026-${date}.bak
done

Total download: 450GB (full) + 23GB (incrementals) = 473GB
Transfer time: ~2 hours @ 60MB/s (AWS Direct Connect)
```

**Timing:** ~2 hours (S3 download)

#### Step 5: Restore File Server from Backup
```
# Wipe file-server01 (remove ransomware)
sarah@ansible-ctrl$ ansible-playbook playbooks/wipe-and-rebuild-file-server.yml

Steps:
1. Power off file-server01
2. Boot from network (PXE)
3. Reinstall Rocky Linux 9 from kickstart
4. Configure base system (network, firewall, SELinux)
5. Install Bacula client
6. Ready for restore

Duration: 45 minutes (automated via Ansible)

# Restore files from S3 backup
alex@backup-server$ sudo bconsole
*restore client=file-server01-fd fileset=FileServerFiles where=/ \
  file=s3-restore/Full-2026-01-01.bak

# Apply incremental backups (01-02 through 01-10)
for i in {2..10}; do
  *restore client=file-server01-fd fileset=FileServerFiles where=/ \
    file=s3-restore/Daily-Inc-2026-01-$(printf "%02d" $i).bak
done

Total files restored: 450,000 files
Total size: 473GB
Duration: 6 hours @ 22MB/s (decrypt + decompress + transfer + write)
```

**Timing:** 45 minutes (rebuild) + 6 hours (restore) = ~7 hours total

#### Step 6: Verification and Service Restoration
```bash
# Verify file integrity
alex@file-server01$ sudo find /srv/shares -name "*.encrypted"
# (no results - all files restored to pre-ransomware state)

alex@file-server01$ sudo ls /srv/shares/departments/finance/
Q1-report.xlsx
Q2-forecast.xlsx
annual-budget-2026.xlsx
... (all files clean, no .encrypted extension)

# Verify checksums (random sample)
alex@backup-server$ sudo bconsole
*list files jobid=44
FileName: Q1-report.xlsx
MD5: a1b2c3d4e5f6...9876543210

alex@file-server01$ md5sum /srv/shares/departments/finance/Q1-report.xlsx
a1b2c3d4e5f6...9876543210  Q1-report.xlsx

Result: MATCH ✓ (file restored correctly)

# Start SMB service
alex@file-server01$ sudo systemctl start smb nmb
alex@file-server01$ sudo systemctl status smb
● smb.service - Samba SMB Daemon
   Active: active (running) since Thu 2026-01-10 16:30:00 UTC

# Notify users
sarah@ansible-ctrl$ mail -s "File Server Restored - Service Available" all-users@office.local <<EOF
Hi Team,

The file server has been fully restored from last night's backup (2026-01-10 02:00).
All files are accessible. Any work done between 02:00 and 06:45 this morning may need
to be re-done.

We are investigating the ransomware incident. laptop-john-01 has been isolated for
forensic analysis.

-IT Team
EOF
```

**Auditd Log (entire recovery):**
```
type=DISASTER_RECOVERY msg=audit(1736510400.000:9999):
  incident="ransomware_encryption" affected_system="file-server01"
  detection_time="2026-01-10T06:45:00Z"
  response_time="2026-01-10T08:00:00Z" (75 minutes)
  recovery_method="s3_immutable_backup"
  backup_date="2026-01-10T02:00:00Z"
  data_loss_window="06:45-02:00" (4h 45m)
  files_restored=450000 bytes_restored=507904819200
  recovery_duration="7h 45m"
  dual_approval="sarah@OFFICE.LOCAL,cto@OFFICE.LOCAL"
  result=success key="disaster_recovery"
```

**Wazuh SIEM Summary:**
```
Incident Report: Ransomware Attack on file-server01
  Detection: 2026-01-10 06:45:00 (Wazuh Rule 100100)
  Response: 75 minutes (network isolation + assessment)
  Recovery: 7h 45m (rebuild + restore from S3)
  Data Loss: 4h 45m (02:00 backup → 06:45 ransomware)
  Cost: $0 (no ransom paid, clean restore from immutable backup)
  Root Cause: Malicious attachment opened by john@OFFICE.LOCAL
  Remediation:
    - laptop-john-01 wiped and rebuilt
    - Additional email attachment filtering deployed
    - User security awareness training scheduled
```

**Total Time:** ~8 hours (detection to full service restoration)

---

## SELinux Policy Enforcement

### Bacula Process Confinement
```bash
# Check Bacula Director SELinux context
$ ps -eZ | grep bacula-dir
system_u:system_r:bacula_t:s0    1234 ?        00:00:05 bacula-dir

# What can bacula_t access?
$ sesearch -A -s bacula_t -t bacula_store_t -c file -p write
allow bacula_t bacula_store_t:file { create write open };

# Can bacula_t read samba shares (for backup)?
$ sesearch -A -s bacula_t -t samba_share_t -c file -p read
allow bacula_t samba_share_t:file { read open getattr };

# Can bacula_t access user home directories?
$ sesearch -A -s bacula_t -t user_home_t -c file -p read
allow bacula_t user_home_t:file { read open getattr };  # Required for workstation backups
```

**Key Confinements:**
1. **Backup Storage:** bacula can write to `/backup/bacula/` (type `bacula_store_t`)
2. **Network:** bacula can listen on 9101-9103/tcp (Bacula ports)
3. **Data Access:** bacula can read most file types (required for backups)
4. **Blocked Access:** bacula CANNOT execute arbitrary binaries or modify system files

---

## Firewall Configuration

### Backup Server Inbound Rules
```bash
# Zone: server (VLAN 120)

# Bacula Director port (for bconsole connections)
firewall-cmd --permanent --zone=server --add-port=9101/tcp

# Bacula File Daemon port (if backup-server is also backed up)
firewall-cmd --permanent --zone=server --add-port=9102/tcp

# Bacula Storage Daemon port (clients send data here)
firewall-cmd --permanent --zone=server --add-port=9103/tcp

# Allow Bacula ports only from Server VLAN and ansible-ctrl
firewall-cmd --permanent --zone=server --add-rich-rule='
  rule family="ipv4"
  source address="10.0.120.0/24"
  port protocol="tcp" port="9101-9103"
  accept'

# SSH from ansible-ctrl only
firewall-cmd --permanent --zone=server --add-rich-rule='
  rule family="ipv4"
  source address="10.0.120.50/32"
  service name="ssh"
  accept'

# Default deny
firewall-cmd --permanent --zone=server --set-target=DROP

firewall-cmd --reload
```

### Backup Server Outbound Rules
```bash
# Allow connections to Bacula clients (all managed hosts)
firewall-cmd --permanent --direct --add-rule ipv4 filter OUTPUT 0 \
  -p tcp --dport 9102 -j ACCEPT

# Allow PostgreSQL (catalog database, localhost only)
firewall-cmd --permanent --direct --add-rule ipv4 filter OUTPUT 0 \
  -d 127.0.0.1 -p tcp --dport 5432 -j ACCEPT

# Allow AWS S3 (offsite replication)
firewall-cmd --permanent --direct --add-rule ipv4 filter OUTPUT 0 \
  -p tcp --dport 443 -j ACCEPT  # HTTPS to s3.amazonaws.com

# Allow rsyslog to monitoring server
firewall-cmd --permanent --direct --add-rule ipv4 filter OUTPUT 0 \
  -d 10.0.120.40 -p tcp --dport 514 -j ACCEPT

# Block all other outbound
firewall-cmd --permanent --direct --add-rule ipv4 filter OUTPUT 1 -j DROP
```

---

## Auditd Rules

### Backup Operations Auditing
```bash
# /etc/audit/rules.d/bacula.rules

# Watch Bacula binaries
-w /usr/sbin/bacula-dir -p x -k bacula_director
-w /usr/sbin/bacula-sd -p x -k bacula_storage
-w /usr/sbin/bacula-fd -p x -k bacula_client

# Watch backup volumes
-w /backup/bacula/volumes/ -p wa -k backup_volumes

# Watch Bacula configuration
-w /etc/bacula/ -p wa -k bacula_config

# Watch encryption keys
-w /etc/bacula/keys/ -p ra -k backup_encryption_keys

# Watch recovery operations (restores)
-a always,exit -F arch=b64 -S open -F dir=/tmp/bacula-restore/ -k backup_restore

# Audit bconsole usage (recovery tool)
-w /usr/sbin/bconsole -p x -k bacula_console

# Audit S3 operations (offsite backup)
-a always,exit -F arch=b64 -S execve -F exe=/usr/bin/aws -k backup_s3_operations
```

### Example Audit Log Output
```
# Backup job completed
type=BACULA_JOB msg=audit(1736387027.456:7890):
  job_name="FileServer-Daily-Incremental" job_id=42
  client="file-server01-fd" level="Incremental"
  files=847 bytes=2411724800 duration=227s result=success
  key="backup_job_complete"

# File restored
type=BACULA_RESTORE msg=audit(1736427966.789:8902):
  job_name="RestoreFiles" job_id=43
  client="file-server01-fd" files=1 bytes=12458901
  destination="/tmp/bacula-restore" duration=16s result=success
  restored_by="alex@OFFICE.LOCAL" approval="sarah@OFFICE.LOCAL"
  ticket="IT-2026-0023" key="backup_restore_complete"

# Encryption key accessed
type=SYSCALL msg=audit(1736427955.123:8900): arch=c000003e syscall=2 success=yes
  comm="bacula-sd" exe="/usr/sbin/bacula-sd"
  subj=system_u:system_r:bacula_t:s0
  name="/etc/bacula/keys/file-server01.key"
  key="backup_encryption_keys"
```

---

## Bacula Configuration

### Director Configuration (/etc/bacula/bacula-dir.conf)
```
Director {
  Name = backup-server-dir
  DIRport = 9101
  QueryFile = "/etc/bacula/query.sql"
  WorkingDirectory = "/var/lib/bacula"
  PidDirectory = "/var/run/bacula"
  Maximum Concurrent Jobs = 10
  Password = "{{ bacula_director_password }}"  # From Ansible Vault
  Messages = Daemon
  DirAddress = 10.0.120.60

  TLS Enable = yes
  TLS Require = yes
  TLS CA Certificate File = /etc/bacula/ssl/ca.crt
  TLS Certificate = /etc/bacula/ssl/backup-server.crt
  TLS Key = /etc/bacula/ssl/backup-server.key
}

Storage {
  Name = File
  Address = 10.0.120.60
  SDPort = 9103
  Password = "{{ bacula_storage_password }}"
  Device = FileStorage
  Media Type = File

  TLS Enable = yes
  TLS Require = yes
  TLS CA Certificate File = /etc/bacula/ssl/ca.crt
  TLS Certificate = /etc/bacula/ssl/backup-server.crt
  TLS Key = /etc/bacula/ssl/backup-server.key
}

Catalog {
  Name = MyCatalog
  DB Name = bacula_catalog
  DB User = bacula
  DB Password = "{{ bacula_db_password }}"
  DB Address = localhost
  DB Port = 5432
}

Messages {
  Name = Standard
  director = backup-server-dir = all
  syslog = all, !skipped, !restored
  append = "/var/log/bacula/bacula.log" = all, !skipped
  console = all, !skipped, !saved
}

Schedule {
  Name = "DailyCycle"
  Run = Level=Incremental daily at 02:00
  Run = Level=Full monthly on 1 at 02:00
}

FileSet {
  Name = "FileServerFiles"
  Include {
    Options {
      signature = SHA-256
      compression = GZIP9
      encryption {
        enable = yes
        algorithm = AES-256-CBC
        key = "/etc/bacula/keys/file-server01.key"
      }
      onefs = yes  # Don't cross filesystems
      sparse = yes  # Handle sparse files efficiently
    }
    File = /srv/shares
    File = /etc
    File = /var/log
  }
  Exclude {
    File = /srv/shares/.snapshots
    File = /tmp
    File = /var/tmp
  }
}

Pool {
  Name = Daily-Incremental
  Pool Type = Backup
  Recycle = yes
  AutoPrune = yes
  Volume Retention = 90 days
  Maximum Volume Bytes = 50G
  Maximum Volumes = 100
  Label Format = "Daily-Inc-${Year}-${Month:p/2/0/r}-${Day:p/2/0/r}"
}

Pool {
  Name = Monthly-Full
  Pool Type = Backup
  Recycle = yes
  AutoPrune = no  # Manual pruning for compliance
  Volume Retention = 7 years  # SOX requirement
  Maximum Volume Bytes = 500G
  Maximum Volumes = 100
  Label Format = "Full-${Year}-${Month:p/2/0/r}-${Day:p/2/0/r}"
}
```

---

## S3 Offsite Backup Configuration

### S3 Bucket Policy (Immutable Backups)
```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "DenyDeleteObject",
      "Effect": "Deny",
      "Principal": "*",
      "Action": [
        "s3:DeleteObject",
        "s3:DeleteObjectVersion"
      ],
      "Resource": "arn:aws:s3:::office-backups-immutable/*"
    },
    {
      "Sid": "AllowBackupServerPutObject",
      "Effect": "Allow",
      "Principal": {
        "AWS": "arn:aws:iam::123456789012:user/backup-server"
      },
      "Action": [
        "s3:PutObject",
        "s3:GetObject",
        "s3:ListBucket"
      ],
      "Resource": [
        "arn:aws:s3:::office-backups-immutable",
        "arn:aws:s3:::office-backups-immutable/*"
      ]
    }
  ]
}
```

### S3 Object Lock Configuration
```bash
# Enable object lock (WORM - Write Once Read Many)
aws s3api put-object-lock-configuration \
  --bucket office-backups-immutable \
  --object-lock-configuration '{
    "ObjectLockEnabled": "Enabled",
    "Rule": {
      "DefaultRetention": {
        "Mode": "GOVERNANCE",
        "Days": 2555
      }
    }
  }'

# Note: 2555 days = ~7 years (SOX compliance)
# GOVERNANCE mode: Requires special permissions to delete (even for AWS root)
```

### S3 Sync Script (/usr/local/bin/bacula-s3-sync.sh)
```bash
#!/bin/bash
set -euo pipefail

# Sync Bacula volumes to S3 (runs daily at 04:00 via cron)
exec 1> >(logger -s -t bacula-s3-sync) 2>&1

VOLUMES_DIR="/backup/bacula/volumes"
S3_BUCKET="s3://office-backups-immutable/bacula"
ENCRYPTION_KEY="/etc/bacula/keys/s3-encryption.key"

echo "Starting S3 sync at $(date)"

# Sync with server-side encryption (SSE-KMS)
aws s3 sync "$VOLUMES_DIR" "$S3_BUCKET" \
  --sse aws:kms \
  --sse-kms-key-id "arn:aws:kms:us-east-1:123456789012:key/abcd1234-..." \
  --storage-class STANDARD_IA \
  --exclude "*.tmp" \
  --delete

# Verify sync
VOLUME_COUNT=$(ls "$VOLUMES_DIR" | wc -l)
S3_COUNT=$(aws s3 ls "$S3_BUCKET" | wc -l)

if [ "$VOLUME_COUNT" -eq "$S3_COUNT" ]; then
  echo "S3 sync completed successfully. $VOLUME_COUNT volumes synced."
else
  echo "ERROR: Volume count mismatch! Local: $VOLUME_COUNT, S3: $S3_COUNT"
  exit 1
fi

# Audit log
logger -t bacula-s3-sync -p local6.info \
  "S3 sync completed: $VOLUME_COUNT volumes, $(du -sh $VOLUMES_DIR | awk '{print $1}') total"

echo "S3 sync completed at $(date)"
```

---

## Test Cases for Validation

### Test 1: Successful Daily Backup
```bash
# Preconditions:
# - file-server01 has 847 modified files since last backup
# - Bacula schedule triggers at 02:00

# Test (on backup-server):
$ sudo journalctl -u bacula-dir -n 50 | grep "Job.*completed successfully"
Jan 09 02:03:47 backup-server bacula-dir[1234]:
  FileServer-Daily-Incremental.2026-01-09_02.00.00_03 completed successfully

# Expected:
# ✓ Job completed within SLA (< 4 hours)
# ✓ All files backed up (847/847)
# ✓ Checksums calculated and stored
# ✓ Encrypted with AES-256
# ✓ Logs forwarded to monitoring01

# Validation:
$ sudo bconsole
*list jobs
+-------+--------------------------------+-----------+------+-------+----------+
| JobId | Name                           | StartTime | Type | Level | JobFiles |
+-------+--------------------------------+-----------+------+-------+----------+
|    42 | FileServer-Daily-Incremental   | 02:00:00  | B    | I     | 847      |
+-------+--------------------------------+-----------+------+-------+----------+

*list files jobid=42
+--------------------------------------------------------+
| FileName                                               |
+--------------------------------------------------------+
| /srv/shares/departments/finance/Q1-report.xlsx         |
| /srv/shares/departments/hr/employee-reviews-2026.docx  |
... (847 files)
```

### Test 2: File Recovery
```bash
# Preconditions:
# - File deleted: annual-budget-2026.xlsx
# - Last backup contains this file
# - JIT approval granted

# Test:
alex@backup-server$ sudo bconsole
*restore client=file-server01-fd file=/srv/shares/departments/hr/annual-budget-2026.xlsx
*run
Job queued. JobId=43

# Expected:
# ✓ File located in catalog
# ✓ Volume identified (Daily-Inc-2026-01-09)
# ✓ File restored to /tmp/bacula-restore
# ✓ Checksum verified
# ✓ Permissions/ownership preserved

# Validation:
alex@file-server01$ md5sum /srv/shares/departments/hr/annual-budget-2026.xlsx
b2c3d4e5f6a7890123456789abcdef01

$ sudo bconsole
*list files jobid=43
FileName: annual-budget-2026.xlsx
MD5: b2c3d4e5f6a7890123456789abcdef01

# Checksums match ✓
```

### Test 3: Backup Encryption Verification
```bash
# Preconditions:
# - Backup volume exists: Daily-Inc-2026-01-09
# - Encryption key: /etc/bacula/keys/file-server01.key

# Test (without encryption key):
$ sudo bacula-sd
# Manually delete encryption key
$ sudo rm /etc/bacula/keys/file-server01.key

$ sudo bconsole
*restore client=file-server01-fd file=/srv/shares/departments/finance/Q1-report.xlsx
ERROR: Cannot decrypt volume Daily-Inc-2026-01-09: Encryption key not found

# Expected:
# ✗ Restore fails (no encryption key)
# ✓ Error logged
# ✓ Data remains encrypted on disk

# Validation:
$ sudo file /backup/bacula/volumes/Daily-Inc-2026-01-09
/backup/bacula/volumes/Daily-Inc-2026-01-09: data  # Binary data, not recognizable

# Restore encryption key from TPM
$ sudo tpm2_nvread 0x1500001 > /etc/bacula/keys/file-server01.key
$ sudo chmod 600 /etc/bacula/keys/file-server01.key

# Retry restore
$ sudo bconsole
*restore...
Job completed successfully  # Now works with key restored ✓
```

### Test 4: S3 Immutable Backup Protection
```bash
# Preconditions:
# - Backup exists in S3: Full-2026-01-01.bak
# - Object lock enabled (7-year retention)

# Test (attempt to delete):
$ aws s3 rm s3://office-backups-immutable/bacula/Full-2026-01-01.bak

# Expected:
# ✗ Deletion DENIED by S3 object lock
# ✓ Error message returned
# ✓ File remains in S3

# Validation:
An error occurred (AccessDenied) when calling the DeleteObject operation:
  Object is protected by Object Lock and cannot be deleted or overwritten
  until retention period expires (2033-01-01)

$ aws s3 ls s3://office-backups-immutable/bacula/Full-2026-01-01.bak
2026-01-01 02:30:00 483729481728 Full-2026-01-01.bak
# File still exists ✓
```

### Test 5: Backup Integrity Check
```bash
# Preconditions:
# - Backup exists: Daily-Inc-2026-01-09
# - Checksums stored in catalog

# Test (verify all files):
$ sudo bconsole
*verify jobid=42 level=catalog

# Bacula reads each file from volume and compares checksum
Files verified: 847/847
Errors: 0
Warnings: 0

# Expected:
# ✓ All 847 files match checksums
# ✓ No corruption detected
# ✓ Backup is restorable

# Validation (random spot check):
*list files jobid=42
FileName: /srv/shares/departments/finance/Q1-report.xlsx
MD5: a1b2c3d4e5f6...9876543210

# Extract file from backup and compute checksum
$ sudo bacula-sd -d100 -t  # Test mode
... extract Q1-report.xlsx to /tmp/test-restore/

$ md5sum /tmp/test-restore/srv/shares/departments/finance/Q1-report.xlsx
a1b2c3d4e5f6...9876543210  # MATCH ✓
```

### Test 6: Disaster Recovery Drill (Quarterly)
```bash
# Preconditions:
# - Quarterly DR drill scheduled (2026-01-15)
# - Test recovery of file-server01 from S3

# Test:
1. Document current file-server01 state (checksums, file count)
2. Download full backup from S3
3. Download incremental backups (last 30 days)
4. Build new VM: file-server-test01
5. Restore all data to test VM
6. Verify checksums match production
7. Test SMB access from workstation
8. Document recovery time

# Expected:
# ✓ Full restore completes in < 8 hours
# ✓ All files restored correctly (checksum verification)
# ✓ SMB service functional on test VM
# ✓ DR procedure documented and updated

# Validation (documented in DR drill report):
DR Drill Results - 2026-01-15:
  Backup source: S3 immutable backups
  Full backup: Full-2026-01-01.bak (450GB)
  Incremental backups: Daily-Inc-2026-01-02 through 01-14 (35GB total)
  Download time: 2h 15m
  Rebuild time: 45m (Ansible automation)
  Restore time: 5h 30m
  Total recovery time: 8h 30m
  Files restored: 450,000
  Checksum verification: 100% match
  Result: SUCCESS ✓
```

---

## Compliance Benefits

### SOX (Sarbanes-Oxley) Compliance
**Requirement:** 7-year retention of financial records, tamper-proof backups

**Implementation:**
- **7-Year Retention:** Monthly full backups retained for 7 years (Pool: Monthly-Full)
- **Immutable Backups:** S3 object lock prevents deletion (GOVERNANCE mode, 7-year retention)
- **Encryption:** AES-256 for all backups (prevents unauthorized access)
- **Audit Trail:** All backup/recovery operations logged with:
  - Who initiated (alex@OFFICE.LOCAL)
  - What was backed up/restored (file list)
  - When (timestamp)
  - Approval (sarah@OFFICE.LOCAL via JIT)
  - Result (success/failure)
- **Integrity:** SHA-256 checksums verify no tampering

**Compliance Evidence:**
```bash
# Query all backups for financial data (7 years)
GET /bacula-logs-*/_search
{
  "query": {
    "bool": {
      "must": [
        {"match": {"file_path": "/srv/shares/departments/finance"}},
        {"range": {"@timestamp": {"gte": "2019-01-01", "lte": "2026-01-10"}}}
      ]
    }
  },
  "sort": [{"@timestamp": "asc"}]
}

# Result: Complete backup history for all financial files over 7 years
```

---

### GDPR (General Data Protection Regulation) Compliance
**Requirement:** Data protection, right to erasure, breach notification

**Implementation:**
- **Data Protection:** Encryption at rest (AES-256) and in transit (TLS 1.3)
- **Access Control:** JIT elevation required for recovery (prevents unauthorized access)
- **Right to Erasure:** Automated script to purge specific user's data from backups:
```bash
# /usr/local/bin/gdpr-purge-backups.sh
#!/bin/bash
USER_TO_PURGE="$1"

# Remove from Bacula catalog
sudo -u postgres psql bacula_catalog -c "
  DELETE FROM File WHERE FileId IN (
    SELECT FileId FROM File
    JOIN Path ON File.PathId = Path.PathId
    WHERE Path.Path LIKE '%${USER_TO_PURGE}%'
  );
"

# Remove from S3 (user-specific backups)
aws s3 rm s3://office-backups-immutable/user-backups/${USER_TO_PURGE}/ --recursive

echo "GDPR erasure completed for user: $USER_TO_PURGE"
```

- **Breach Notification:** Ransomware detected within 2 minutes, reported to GDPR authority within 72 hours

**Compliance Evidence:**
- Encryption certificates
- Access logs (JIT approval for all recovery operations)
- Incident response timeline (ransomware recovery < 8 hours)

---

### HIPAA (Health Insurance Portability and Accountability Act) Compliance
**Requirement:** PHI backup protection, disaster recovery

**Implementation:**
- **Backup Encryption:** All backups encrypted (§164.312(a)(2)(iv))
- **Access Controls:** JIT elevation prevents unauthorized recovery (§164.308(a)(4))
- **Disaster Recovery:** Quarterly DR drills verify recovery capability (§164.308(a)(7)(ii)(B))
- **Audit Controls:** All backup/recovery operations logged (§164.312(b))
- **Offsite Storage:** S3 cross-region replication protects against site disasters (§164.310(d)(2)(iv))

**Compliance Evidence:**
```bash
# DR drill documentation (quarterly requirement)
/backup/compliance/DR-Drills/2026-Q1-Drill-Report.pdf
  - Recovery Time Objective (RTO): 8 hours ✓ (met)
  - Recovery Point Objective (RPO): 24 hours ✓ (met - daily backups)
  - All PHI recovered successfully
  - Encryption verified throughout recovery process
```

---

## Wazuh SIEM Rules for Backup Security

### Rule 1: Backup Failure Alert
```xml
<!-- /var/ossec/etc/rules/local_rules.xml on monitoring01 -->
<group name="bacula,backup,">
  <rule id="100230" level="12">
    <if_sid>0</if_sid>
    <match>bacula-dir</match>
    <match>failed</match>
    <description>Backup job failed (data protection risk)</description>
    <mitre>
      <id>T1490</id>  <!-- Inhibit System Recovery -->
    </mitre>
  </rule>
</group>
```

**Trigger:** Any Bacula backup job failure
**Action:** High-severity alert + investigate cause

---

### Rule 2: Unauthorized Backup Recovery Attempt
```xml
<rule id="100231" level="14">
  <if_sid>0</if_sid>
  <match>bconsole</match>
  <match>res=failed</match>
  <match>reason=no_jit_approval</match>
  <description>Unauthorized backup recovery attempt (possible data theft)</description>
  <mitre>
    <id>T1005</id>  <!-- Data from Local System -->
  </mitre>
</rule>
```

**Trigger:** Recovery attempt without JIT approval
**Action:** Critical alert + investigate user

---

### Rule 3: Backup Encryption Key Access
```xml
<rule id="100232" level="10">
  <if_sid>0</if_sid>
  <match>/etc/bacula/keys/</match>
  <match>SYSCALL</match>
  <field name="syscall">2|257</field>  <!-- open/openat -->
  <description>Backup encryption key accessed (verify authorization)</description>
  <mitre>
    <id>T1552.004</id>  <!-- Unsecured Credentials: Private Keys -->
  </mitre>
</rule>
```

**Trigger:** Any process accesses backup encryption keys
**Action:** Informational alert + verify legitimate use (bacula-sd expected)

---

### Rule 4: S3 Backup Sync Failure
```xml
<rule id="100233" level="13">
  <if_sid>0</if_sid>
  <match>bacula-s3-sync</match>
  <match>ERROR</match>
  <description>S3 backup synchronization failed (offsite backup unavailable)</description>
  <mitre>
    <id>T1485</id>  <!-- Data Destruction -->
  </mitre>
</rule>
```

**Trigger:** Daily S3 sync script fails
**Action:** High-severity alert + verify network/AWS connectivity

---

### Rule 5: Mass Data Recovery (Potential Data Theft)
```xml
<rule id="100234" level="12">
  <if_sid>0</if_sid>
  <match>BACULA_RESTORE</match>
  <field name="files">100</field>  <!-- >100 files restored -->
  <description>Mass data recovery operation detected (verify authorization)</description>
  <mitre>
    <id>T1074</id>  <!-- Data Staged -->
  </mitre>
</rule>
```

**Trigger:** Single restore job with >100 files
**Action:** Alert security team + verify legitimate use (disaster recovery expected)

---

## Summary

This document demonstrates comprehensive backup security with:

1. **Data Protection:**
   - AES-256 encryption (at-rest and in-transit)
   - TLS 1.3 for all Bacula client connections
   - TPM-stored encryption keys
   - SHA-256 checksums for integrity

2. **Defense in Depth:**
   - Firewall: Network isolation (backup-server initiates all connections)
   - SELinux: Bacula process confinement (bacula_t domain)
   - Authentication: PSK (pre-shared keys) per client + TLS certificates
   - Access Control: JIT elevation required for recovery
   - Auditd: Comprehensive logging

3. **Business Continuity:**
   - 90-day incremental backups (daily recovery)
   - 7-year full backups (SOX compliance)
   - Offsite replication to AWS S3 (disaster recovery)
   - Quarterly DR drills (8-hour recovery validated)
   - Immutable S3 backups (ransomware protection)

4. **Ransomware Protection:**
   - S3 object lock (WORM - cannot delete for 7 years)
   - Incremental backups (granular recovery points)
   - Automated detection (Wazuh SIEM)
   - Fast recovery (8 hours from detection to service restoration)
   - No ransom payment required (clean restore from immutable backup)

5. **Compliance:**
   - SOX: 7-year retention, tamper-proof, audit trails
   - GDPR: Encryption, access control, right to erasure
   - HIPAA: DR drills, offsite storage, audit controls
   - Automated retention policy enforcement

6. **Threat Detection:**
   - Wazuh SIEM rules for backup failures
   - Automated alerts for unauthorized recovery attempts
   - S3 sync failure detection
   - Mass data recovery monitoring

**Total Security Layers for Backup Data:** 7
1. pfSense firewall (network isolation)
2. firewalld (host-based firewall)
3. TLS 1.3 (Bacula client connections)
4. PSK authentication (per-client keys)
5. AES-256 encryption (at-rest)
6. SELinux (bacula_t process confinement)
7. S3 object lock (immutable backups)

**Key Insight:** Immutable S3 backups with object lock provide the ultimate ransomware protection. Even if all on-premises systems are compromised, the offsite backups cannot be deleted or encrypted, enabling full recovery. This is the last line of defense in a comprehensive backup strategy.

---

**Document Version:** 1.0
**Last Updated:** 2026-01-10
**Author:** IT Security Team
**Next Review:** 2026-07-10 (6 months)
