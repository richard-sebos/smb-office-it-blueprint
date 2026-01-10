# Privileged User Workstation Security Flow
## Managers, Finance, and HR - Single-User Assignment with Yubikey 2FA

---

## Use Case: Dedicated Workstation for Privileged Users

**User Types:**
- **Managers:** Access to business-critical documents, strategic planning, employee data
- **Finance:** Access to QuickBooks, financial records, payroll, tax documents
- **HR:** Access to employee records, hiring docs, disciplinary actions, salary info

**Security Model:** Enhanced protection for sensitive data access

---

## Architecture Overview

```
┌─────────────────────────────────────────────────────────────────┐
│              PRIVILEGED USER WORKSTATION                         │
│                    laptop-david-01                               │
│               10.0.131.20 (VLAN 131 - Admin)                     │
│               Assigned to: david@corp.company.local              │
│                                                                   │
│  ┌──────────────────────────────────────────────────────────┐  │
│  │  Local Filesystem (MAC/DAC/ACL Protected)                 │  │
│  │  ├─ /home/david  → file-server01:/shares/home/david      │  │
│  │  ├─ /mnt/finance → file-server01:/shares/departments/... │  │
│  │  └─ /mnt/hr      → file-server01:/shares/departments/... │  │
│  └──────────────────────────────────────────────────────────┘  │
│                                                                   │
│  Physical Security:                                              │
│  ├─ Laptop assigned to David (serial # tracked)                 │
│  ├─ Full disk encryption (LUKS)                                 │
│  └─ Yubikey required for login                                  │
│                                                                   │
└────────────────────────────┬──────────────────────────────────┘
                             │
                ┌────────────┼────────────────────┐
                │            │                    │
         ┌──────▼──────┐ ┌──▼────────────┐ ┌────▼──────┐
         │ dc01/dc02   │ │file-server01  │ │monitoring01│
         │ (AD Auth    │ │(Home + Dept   │ │(Auditd     │
         │  + Yubikey) │ │  Shares)      │ │ Logs)      │
         │ VLAN 120    │ │VLAN 120       │ │VLAN 120    │
         └─────────────┘ └───────────────┘ └────────────┘
```

---

## Security Requirements

| Requirement | Implementation | Why |
|-------------|----------------|-----|
| **Device Assignment** | Laptop/Desktop assigned to specific user (BIOS serial # tracked) | No shared equipment, physical accountability |
| **User Restriction** | PAM + hostallow: Only assigned user can log in | No other users can access, even with valid AD credentials |
| **2FA (Yubikey)** | pam_u2f + Yubikey FIDO2 | Stolen password alone won't grant access |
| **Full Disk Encryption** | LUKS with TPM | Physical theft protection |
| **Network Home Directory** | CIFS mount to file-server01 | Centralized backup |
| **Department Shares** | Additional mounts for Finance/HR/Mgmt | Role-based data access |
| **MAC Protection on Shares** | SELinux contexts on department shares | Kernel-level protection, even if DAC bypassed |
| **Auditd on Share Access** | Audit rules for all department share access | Track who accessed sensitive data, when |
| **Enhanced Logging** | All file access to sensitive shares logged | Compliance (HIPAA, SOX, GDPR) |

---

## Security Flow Trace: Manager/Finance/HR Login with Yubikey

### **Scenario 1: David (Managing Partner) Logs In with Yubikey**

#### Step 1: Boot and Disk Decryption

```
[8:00 AM] David opens laptop (laptop-david-01)

GRUB Boot:
  └─ Boots from encrypted disk (LUKS)
       ↓
LUKS Decryption:
  ┌─────────────────────────────────────┐
  │  Enter passphrase to decrypt disk   │
  │  [________________________]          │
  └─────────────────────────────────────┘
       ↓
David enters disk encryption passphrase:
  ├─ Passphrase: [David's disk password]
  ├─ LUKS decrypts master key
  ├─ Root filesystem unlocked
  └─ System boots

Optional: TPM (Trusted Platform Module) integration
  ├─ TPM stores decryption key
  ├─ Only releases key if system unmodified (Secure Boot)
  └─ Automatic unlock if TPM + PIN provided

SystemD Boot:
  ├─ Mounts decrypted root filesystem
  ├─ Network initialized (VLAN 131 - Admin network)
  ├─ IP: 10.0.131.20 (static assignment)
  └─ GDM login screen appears
```

---

#### Step 2: Authentication with Yubikey (2FA)

```
GDM Login Screen:
  ├─ Shows: "David's Laptop (laptop-david-01)"
  ├─ Username pre-filled: david@corp.company.local
  └─ Cursor in password field
       ↓
David enters credentials:
  ├─ Username: david@corp.company.local (pre-filled)
  ├─ Password: [David's AD password]
  └─ Presses Enter
       ↓
PAM Authentication Stack (/etc/pam.d/gdm-password):

auth required pam_u2f.so
auth required pam_sss.so

Step 1: Yubikey Challenge (pam_u2f.so)
  ├─ PAM reads: /etc/u2f_mappings
  │   david@corp.company.local:[yubikey_credential_id]:...
  ├─ Sends FIDO2 challenge to connected USB devices
  ├─ Yubikey responds: "Press button to authenticate"
       ↓
David's Action:
  ├─ Laptop displays: "Touch your security key"
  ├─ David inserts Yubikey into USB port
  ├─ David presses button on Yubikey (physical touch required)
       ↓
Yubikey Response:
  ├─ Yubikey generates signed response using private key
  ├─ Private key stored in Yubikey (cannot be extracted)
  ├─ Response sent to PAM
       ↓
PAM validates Yubikey:
  ├─ Verifies signature matches registered Yubikey for david
  ├─ Check: Is this the correct Yubikey? YES
  └─ Yubikey authentication: SUCCESS
       ↓
Step 2: AD Password (pam_sss.so)
  ├─ PAM sends password to SSSD
  ├─ SSSD queries dc01: "Authenticate david@corp.company.local"
       ↓
dc01 (Active Directory):
  ├─ User david@corp.company.local exists? YES
  ├─ Password correct? YES
  ├─ Account enabled? YES
  ├─ Issue Kerberos TGT
  └─ Return: SUCCESS
       ↓
Step 3: Host Assignment Check (pam_access.so)
  ├─ PAM reads: /etc/security/access.conf
  │   + : david@corp.company.local : laptop-david-01
  │   - : ALL : laptop-david-01
  ├─ Check: Is this laptop-david-01? YES (hostname check)
  ├─ Check: Is user david? YES
  └─ Authorization: SUCCESS
       ↓
All PAM modules passed:
  ├─ Yubikey: ✓
  ├─ AD Password: ✓
  ├─ Host assignment: ✓
  └─ Login GRANTED
       ↓
GDM creates session for david@corp.company.local
```

**Audit Log (auditd):**
```
type=USER_AUTH msg=audit(1704369600.123:100): pid=1234 uid=0 auid=1602000
  ses=1 msg='op=PAM:authentication grantors=pam_u2f,pam_sss
  acct="david@corp.company.local" exe="/usr/sbin/gdm"
  hostname=laptop-david-01 addr=? terminal=:0 res=success'
  key="yubikey_2fa_auth"

type=USER_START msg=audit(1704369600.456:101): pid=1234 uid=0 auid=1602000
  ses=1 msg='op=PAM:session_open acct="david@corp.company.local"
  exe="/usr/sbin/gdm" hostname=laptop-david-01 res=success'
```

**Rsyslog → monitoring01:**
```
Jan 09 08:00:05 laptop-david-01 pam_u2f: Yubikey authentication successful for david@corp.company.local (device: YubiKey 5C NFC)
Jan 09 08:00:06 laptop-david-01 pam_sss: AD authentication successful for david@corp.company.local
Jan 09 08:00:06 laptop-david-01 gdm: User david@corp.company.local logged in (2FA verified)
```

---

### **Scenario 2: Wrong User Tries to Login (Sarah from HR tries David's laptop)**

```
[10:00 AM] Sarah (HR) sits at David's desk while he's in meeting
  └─ Tries to log in to laptop-david-01

GDM Login Screen:
  ├─ Sarah clicks "Not David? Sign in as different user"
  ├─ Username: sarah@corp.company.local
  ├─ Password: [Sarah's correct AD password]
  └─ Presses Enter
       ↓
PAM Authentication:

Step 1: Yubikey (pam_u2f.so)
  ├─ Reads: /etc/u2f_mappings
  ├─ No entry for sarah@corp.company.local (only David's Yubikey registered)
  ├─ Waits for Yubikey...
       ↓
Sarah's Action:
  ├─ Sarah inserts HER Yubikey
  ├─ Presses button
       ↓
Yubikey Response:
  ├─ Sarah's Yubikey generates signed response
  ├─ PAM validates: Does this match david's registered key? NO
  └─ Yubikey authentication: FAILED
       ↓
Step 2: Host Assignment Check (pam_access.so)
  ├─ Reads: /etc/security/access.conf
  │   + : david@corp.company.local : laptop-david-01
  │   - : ALL : laptop-david-01
  ├─ Check: Is user sarah? YES
  ├─ Check: Is sarah allowed on laptop-david-01? NO (only David allowed)
  └─ Authorization: DENIED
       ↓
PAM Decision:
  ├─ Yubikey: ✗ (wrong key)
  ├─ Host assignment: ✗ (wrong user for this laptop)
  └─ Login DENIED
       ↓
GDM shows error:
  "You are not authorized to log in to this device.
   This laptop is assigned to david@corp.company.local.
   Please use your assigned workstation."
```

**Audit Log:**
```
type=USER_AUTH msg=audit(1704373200.789:200): pid=2345 uid=0 auid=1603000
  ses=2 msg='op=PAM:authentication grantors=? acct="sarah@corp.company.local"
  exe="/usr/sbin/gdm" hostname=laptop-david-01 res=failed'
  reason='pam_u2f failed, pam_access denied'

type=USER_ERR msg=audit(1704373200.790:201): pid=2345 uid=0 auid=1603000
  ses=2 msg='op=PAM:authentication acct="sarah@corp.company.local"
  exe="/usr/sbin/gdm" hostname=laptop-david-01 res=failed'
  key="unauthorized_device_access_attempt"
```

**Security Alert (monitoring01):**
```
[10:00 AM] ALERT: Unauthorized device access attempt
  User: sarah@corp.company.local (HR employee)
  Device: laptop-david-01 (assigned to david@corp.company.local)
  Reason: User attempted to log in to device not assigned to them
  Action: Login DENIED

  Context:
    - Sarah has valid AD credentials
    - Sarah's Yubikey is valid
    - BUT: Sarah is not authorized for THIS device
    - Device assignment enforced by PAM

  Risk Level: LOW (likely innocent mistake, not malicious)
  Recommendation: Remind users to only use assigned devices

  Email: IT team (informational)
```

---

### **Scenario 3: Attacker with Stolen Password (No Yubikey)**

```
[2:00 AM] Attacker obtained David's AD password (phishing)
  └─ Attacker has: david@corp.company.local password
  └─ Attacker does NOT have: David's Yubikey (physical device)

Attack Attempt:
  ├─ Attacker travels to office (physical access)
  ├─ Finds laptop-david-01 on David's desk
  ├─ Opens laptop (disk encrypted, but attacker watches David type passphrase)
  └─ Reaches GDM login screen
       ↓
Attacker enters stolen credentials:
  ├─ Username: david@corp.company.local
  ├─ Password: [stolen password - CORRECT]
  └─ Presses Enter
       ↓
PAM Authentication:

Step 1: Yubikey (pam_u2f.so)
  ├─ Laptop displays: "Touch your security key"
  ├─ Attacker does not have David's Yubikey
  ├─ Timeout: 30 seconds
  └─ Yubikey authentication: FAILED (no response)
       ↓
PAM Decision:
  ├─ Yubikey: ✗ (no device)
  ├─ AD Password: Not checked (Yubikey is required first)
  └─ Login DENIED
       ↓
GDM shows error:
  "Authentication failed. Security key required."
```

**Audit Log:**
```
type=USER_AUTH msg=audit(1704333600.123:300): pid=3456 uid=0 auid=1602000
  ses=3 msg='op=PAM:authentication grantors=? acct="david@corp.company.local"
  exe="/usr/sbin/gdm" hostname=laptop-david-01 res=failed'
  reason='pam_u2f timeout (no Yubikey present)'

type=USER_ERR msg=audit(1704333600.124:301): pid=3456 uid=0
  msg='Possible attack: Password correct but 2FA failed'
  key="stolen_password_attempt"
```

**Security Alert (HIGH SEVERITY):**
```
[2:00 AM] HIGH SEVERITY: Possible stolen password attack
  User: david@corp.company.local
  Device: laptop-david-01
  Time: 2:00 AM (outside normal hours)
  Reason: Correct password entered, but Yubikey not present

  Analysis:
    - Password was correct (indicates compromise)
    - Yubikey not present (attacker doesn't have physical key)
    - Time: 2 AM (suspicious, David's normal hours: 8 AM - 6 PM)

  Action Taken: Login DENIED

  IMMEDIATE ACTIONS REQUIRED:
    ✓ Password alone insufficient (2FA prevented breach)
    ⚠ Contact David immediately (password may be compromised)
    ⚠ Force password reset for david@corp.company.local
    ⚠ Review physical security (how did attacker access laptop?)
    ⚠ Check for other login attempts with David's credentials

  Email: IT Security, David (mobile), Management
  SMS: Security team, On-call admin
  Phone: Escalation if no response in 15 minutes
```

**Security Value:**
- Stolen password ALONE is insufficient
- Yubikey (physical device) required
- Attack prevented even with correct password
- Early warning system (alert generated immediately)

---

## Home Directory and Department Share Mounting

### **Step 3: Mount Home Directory and Department Shares**

```
PAM Session Module (pam_mount.so):
  └─ User authenticated successfully, now mount filesystems
       ↓
Mount Configuration (/etc/security/pam_mount.conf.xml):

<!-- Personal home directory -->
<volume user="david@corp.company.local"
        fstype="cifs"
        server="file-server01.corp.company.local"
        path="shares/home/david"
        mountpoint="/home/david"
        options="sec=krb5,uid=%(USERUID),gid=%(USERGID)" />

<!-- Management department share (for managers) -->
<volume user="david@corp.company.local"
        fstype="cifs"
        server="file-server01.corp.company.local"
        path="shares/departments/management"
        mountpoint="/mnt/management"
        options="sec=krb5,uid=%(USERUID),gid=10100" />

<!-- Finance department share (if David also has finance role) -->
<volume user="david@corp.company.local"
        fstype="cifs"
        server="file-server01.corp.company.local"
        path="shares/departments/finance"
        mountpoint="/mnt/finance"
        options="sec=krb5,uid=%(USERUID),gid=10200" />
```

---

#### Mount Process for Each Share

```
[Mount 1] Personal Home Directory:

mount.cifs //file-server01/shares/home/david /home/david \
  -o sec=krb5,uid=1602000,gid=1602000
       ↓
file-server01 Samba:
  ├─ Receives mount request with Kerberos ticket
  ├─ Validates: david@corp.company.local ticket valid? YES
  ├─ Check share ACL: david has access to /shares/home/david? YES
  └─ Grant access
       ↓
Mount successful: /home/david → file-server01:/shares/home/david

[Mount 2] Management Department Share:

mount.cifs //file-server01/shares/departments/management /mnt/management \
  -o sec=krb5,uid=1602000,gid=10100
       ↓
file-server01 Samba:
  ├─ Receives mount request
  ├─ Validates Kerberos ticket: YES
  ├─ Check share ACL: Is david member of "Managers" AD group? YES
  ├─ Samba checks: [managers] share definition
  │   path = /srv/shares/departments/management
  │   valid users = @Managers
  │   read only = no
  └─ Grant access
       ↓
Mount successful: /mnt/management → file-server01:/shares/departments/management

[Mount 3] Finance Department Share (if applicable):

mount.cifs //file-server01/shares/departments/finance /mnt/finance \
  -o sec=krb5,uid=1602000,gid=10200
       ↓
file-server01 Samba:
  ├─ Receives mount request
  ├─ Check share ACL: Is david member of "Finance" AD group? NO
  └─ DENY access
       ↓
Mount fails: /mnt/finance not accessible (David not in Finance group)
```

**System Log:**
```
Jan 09 08:00:07 laptop-david-01 pam_mount: Successfully mounted /home/david
Jan 09 08:00:08 laptop-david-01 pam_mount: Successfully mounted /mnt/management
Jan 09 08:00:09 laptop-david-01 pam_mount: Failed to mount /mnt/finance (access denied)
```

---

## MAC Protection on Department Shares (SELinux)

### **SELinux Contexts for Sensitive Shares**

```bash
# On file-server01, SELinux contexts applied to department shares

# Finance share (highly sensitive - payroll, tax docs)
$ ls -Z /srv/shares/departments/finance
drwxrws---. root Finance system_u:object_r:finance_share_t:s0 /srv/shares/departments/finance

# HR share (sensitive - employee records, disciplinary actions)
$ ls -Z /srv/shares/departments/hr
drwxrws---. root HR system_u:object_r:hr_share_t:s0 /srv/shares/departments/hr

# Management share (confidential - strategic plans, M&A docs)
$ ls -Z /srv/shares/departments/management
drwxrws---. root Managers system_u:object_r:mgmt_share_t:s0 /srv/shares/departments/management

# Standard user home (normal sensitivity)
$ ls -Z /srv/shares/home/john
drwx------. john john unconfined_u:object_r:user_home_t:s0 /srv/shares/home/john
```

---

### **SELinux Policy Enforcement**

#### Scenario: Finance User Tries to Access HR Data (Cross-Department)

```
Sarah (Finance) laptop has /mnt/finance mounted:
  └─ /mnt/finance → file-server01:/shares/departments/finance

Sarah tries to access HR share via symlink or direct path:
  $ ls /mnt/finance/../hr
       ↓
File Server (file-server01):
  ├─ Samba receives request from Sarah's laptop
  ├─ Kerberos auth: Valid (Sarah is authenticated)
  ├─ Check Samba ACL: Is Sarah in HR group? NO → DENY
       ↓
Request blocked at Samba level (DAC)

Hypothetically, if Samba ACL bypassed (misconfiguration):
  ├─ Process tries to access /srv/shares/departments/hr
  ├─ SELinux checks context:
  │   Source: samba_t (Samba daemon)
  │   Target: hr_share_t (HR share)
  │   User context: sarah@corp.company.local (Finance group)
  ├─ SELinux policy:
  │   allow samba_t hr_share_t:dir read;
  │   ONLY if user is member of HR group
  ├─ Sarah is NOT in HR group
  └─ SELinux: DENY
       ↓
Access blocked at kernel level (MAC)
```

**SELinux AVC Denial:**
```
type=AVC msg=audit(1704374000.123:400): avc:  denied  { read }
  for pid=5678 comm="smbd" name="hr" dev="sda3" ino=234567
  scontext=system_u:system_r:samba_t:s0
  tcontext=system_u:object_r:hr_share_t:s0
  tclass=dir permissive=0
  reason="user sarah not in required group HR"
```

**Audit Log (on file-server01):**
```
type=SYSCALL msg=audit(1704374000.123:400): arch=c000003e syscall=257
  success=no exit=-13 comm="smbd" exe="/usr/sbin/smbd" key="cross_dept_access_denied"

type=AVC msg=audit(1704374000.123:400): avc:  denied  { read }
  scontext=samba_t tcontext=hr_share_t key="selinux_mac_violation"
```

---

### **SELinux Prevents Local Privilege Escalation**

#### Scenario: Attacker Compromises David's Laptop, Tries to Read Finance Data

```
[Hypothetical] Malware executes on David's laptop:
  ├─ Malware has David's user privileges (uid=1602000)
  ├─ /mnt/management is mounted (David has legitimate access)
  ├─ Malware tries to access /mnt/finance (David does NOT have access)
       ↓
Malware attempts:
  $ cat /mnt/finance/payroll/salaries.xlsx
       ↓
Client-side (laptop-david-01):
  ├─ SELinux context of malware process: unconfined_u:unconfined_r:unconfined_t
  ├─ Mounted CIFS share has context: system_u:object_r:cifs_t
  ├─ SELinux allows read of CIFS mounts (normal operation)
       ↓
Server-side (file-server01):
  ├─ Receives read request from David's laptop
  ├─ Kerberos: Valid (David's ticket)
  ├─ Samba ACL: Is David in Finance group? NO
  └─ DENY at Samba level
       ↓
Request blocked before SELinux check needed

If somehow Samba bypassed:
  ├─ SELinux checks: Does David's token include Finance group? NO
  └─ SELinux: DENY
```

**Security Value:**
- Even if David's laptop compromised, attacker cannot access Finance data
- Samba ACL (first layer) checks AD group membership
- SELinux (second layer) enforces at kernel level
- Both layers must pass for access

---

## Auditd Rules for Department Share Access

### **Configuration: /etc/audit/rules.d/department-shares.rules**

```bash
# On file-server01: Audit all access to sensitive department shares

# Finance share access (SOX compliance requirement)
-w /srv/shares/departments/finance -p rwxa -k finance_share_access
-a always,exit -F dir=/srv/shares/departments/finance -F perm=r -k finance_read
-a always,exit -F dir=/srv/shares/departments/finance -F perm=w -k finance_write
-a always,exit -F dir=/srv/shares/departments/finance -F perm=x -k finance_execute

# HR share access (GDPR/privacy compliance)
-w /srv/shares/departments/hr -p rwxa -k hr_share_access
-a always,exit -F dir=/srv/shares/departments/hr -F perm=r -k hr_read
-a always,exit -F dir=/srv/shares/departments/hr -F perm=w -k hr_write

# Management share access (business confidential)
-w /srv/shares/departments/management -p rwxa -k mgmt_share_access
-a always,exit -F dir=/srv/shares/departments/management -F perm=r -k mgmt_read
-a always,exit -F dir=/srv/shares/departments/management -F perm=w -k mgmt_write

# Specific high-value files (extra monitoring)
-w /srv/shares/departments/finance/payroll/ -p rwxa -k payroll_access
-w /srv/shares/departments/hr/employee-records/ -p rwxa -k employee_records_access
-w /srv/shares/departments/management/strategic-plans/ -p rwxa -k strategic_plans_access

# Detect failed access attempts (authorization failures)
-a always,exit -F dir=/srv/shares/departments/finance -F success=0 -k finance_access_denied
-a always,exit -F dir=/srv/shares/departments/hr -F success=0 -k hr_access_denied

# Detect bulk file operations (potential data exfiltration)
-a always,exit -F arch=b64 -S open -F dir=/srv/shares/departments/finance -F success=1 -k finance_file_open
-a always,exit -F arch=b64 -S openat -F dir=/srv/shares/departments/finance -F success=1 -k finance_file_open
```

---

### **Audit Log Examples**

#### Example 1: Sarah (Finance) Accesses Payroll Spreadsheet

```
Sarah's Action:
  $ cd /mnt/finance/payroll
  $ libreoffice salaries-2026.xlsx

Audit Events Generated (on file-server01):

type=PATH msg=audit(1704375000.123:500): item=0
  name="/srv/shares/departments/finance/payroll/salaries-2026.xlsx"
  inode=345678 dev=08:03 mode=0100660 ouid=0 ogid=10200
  rdev=00:00 obj=system_u:object_r:finance_share_t:s0
  nametype=NORMAL cap_fp=0 cap_fi=0 cap_fe=0

type=SYSCALL msg=audit(1704375000.123:500): arch=c000003e syscall=257
  success=yes exit=3 a0=ffffff9c a1=7ffd5678 ppid=5678 pid=6789
  auid=1603001 uid=1603001 gid=10200 euid=1603001 suid=1603001
  fsuid=1603001 egid=10200 sgid=10200 fsgid=10200 ses=5
  comm="soffice.bin" exe="/usr/lib64/libreoffice/program/soffice.bin"
  subj=unconfined_u:unconfined_r:unconfined_t:s0 key="finance_read"

type=PROCTITLE msg=audit(1704375000.123:500):
  proctitle="libreoffice" "--calc" "salaries-2026.xlsx"
```

**Translated Audit Log (monitoring01 dashboard):**
```
Timestamp: 2026-01-09 09:30:00
Event: Finance share access
User: sarah@corp.company.local (Finance team)
Action: READ
File: /shares/departments/finance/payroll/salaries-2026.xlsx
Application: LibreOffice Calc
Source IP: 10.0.131.25 (laptop-sarah-01)
Result: SUCCESS
Risk Level: NORMAL (authorized access)
Compliance: SOX audit trail recorded
```

---

#### Example 2: David (Manager) Accesses Strategic Plans

```
David's Action:
  $ cd /mnt/management/strategic-plans
  $ cat acquisition-targets-2026.pdf

Audit Events:

type=SYSCALL msg=audit(1704376000.456:600): arch=c000003e syscall=257
  success=yes exit=3 comm="cat" exe="/usr/bin/cat" auid=1602000
  key="strategic_plans_access"

type=PATH msg=audit(1704376000.456:600):
  name="/srv/shares/departments/management/strategic-plans/acquisition-targets-2026.pdf"
  obj=system_u:object_r:mgmt_share_t:s0 nametype=NORMAL
```

**Monitoring Dashboard:**
```
Timestamp: 2026-01-09 10:45:00
Event: Management share access - Strategic Plans
User: david@corp.company.local (Managing Partner)
Action: READ
File: acquisition-targets-2026.pdf
Classification: HIGHLY CONFIDENTIAL
Result: SUCCESS
Risk Level: NORMAL (authorized, but flagged for executive awareness)
Notification: Monthly report to board (who accessed M&A docs)
```

---

#### Example 3: Unauthorized Access Attempt (John tries to access Finance share)

```
John (Regular Employee) attempts:
  $ ls /mnt/finance

Result: Permission denied (John not in Finance group)

Audit Events (file-server01):

type=SYSCALL msg=audit(1704377000.789:700): arch=c000003e syscall=257
  success=no exit=-13 a0=ffffff9c a1=7ffd9abc comm="ls"
  exe="/usr/bin/ls" auid=1601000 key="finance_access_denied"

type=AVC msg=audit(1704377000.789:700): avc:  denied  { read }
  for pid=7890 comm="smbd" name="finance" scontext=samba_t
  tcontext=finance_share_t tclass=dir reason="user not in Finance group"
```

**Security Alert:**
```
[11:15 AM] ALERT: Unauthorized department share access attempt
  User: john@corp.company.local (Regular employee)
  Attempted Access: /shares/departments/finance (Finance department)
  User's Groups: Employees (does NOT include Finance)
  Action: DENIED by Samba ACL + SELinux
  Source: ws-employee-05 (10.0.130.35)

  Context:
    - John is not in Finance group (legitimate denial)
    - This is normal (users sometimes mistype paths)
    - No further action needed unless pattern emerges

  Risk Level: LOW (single failed attempt, likely mistake)
  Logged for: Compliance audit trail
  No escalation required
```

---

#### Example 4: Bulk Download Detection (Potential Data Exfiltration)

```
Malicious Script attempts to download entire Finance share:
  $ rsync -av /mnt/finance /tmp/exfiltrate/

Audit Events:

# 500+ file open syscalls in rapid succession
type=SYSCALL msg=audit(1704378000.123:800): syscall=257 success=yes comm="rsync" key="finance_file_open"
type=SYSCALL msg=audit(1704378000.125:801): syscall=257 success=yes comm="rsync" key="finance_file_open"
type=SYSCALL msg=audit(1704378000.127:802): syscall=257 success=yes comm="rsync" key="finance_file_open"
[... 497 more in 30 seconds ...]
```

**Anomaly Detection (monitoring01):**
```
[2:30 PM] CRITICAL: Bulk file access detected - Possible data exfiltration
  User: sarah@corp.company.local
  Share: /shares/departments/finance
  Activity: 500 files opened in 30 seconds
  Application: rsync
  Source: laptop-sarah-01 (10.0.131.25)

  Analysis:
    ⚠ ANOMALY: Normal file access = 5-10 files/hour
    ⚠ Current rate: 500 files in 30 seconds = 1000x normal
    ⚠ Application: rsync (bulk copy tool)
    ⚠ Likely exfiltration attempt

  AUTOMATIC ACTIONS TAKEN:
    ✓ Block laptop-sarah-01 at firewall (quarantine)
    ✓ Kill rsync process (via Ansible)
    ✓ Disable sarah's Kerberos ticket on file-server01
    ✓ Force logout sarah's session

  IMMEDIATE ACTIONS REQUIRED:
    ⚠ Contact Sarah immediately (compromised account?)
    ⚠ Forensic analysis of laptop-sarah-01
    ⚠ Review what files were accessed
    ⚠ Check for external network connections (USB, email, cloud)

  Incident Response Team: ACTIVATED
  Email: CISO, IT Security, Sarah's manager, Legal
  SMS: On-call security engineer
  Ticket: INC-20260109-001 (CRITICAL priority)
```

---

## Comparison: Privileged vs. Standard Workstation

| Feature | Privileged (Manager/Finance/HR) | Standard Employee |
|---------|--------------------------------|-------------------|
| **Device Assignment** | Single user (David's laptop only) | Multi-user (any employee can log in) |
| **2FA Requirement** | YES (Yubikey required) | NO (password only) |
| **PAM Host Restriction** | YES (only assigned user can log in) | NO (any employee group member) |
| **Network Location** | VLAN 131 (Admin network) | VLAN 130 (Workstation network) |
| **Home Directory** | /home/david (personal) | /home/john (personal) |
| **Department Shares** | /mnt/management, /mnt/finance, /mnt/hr | None (or read-only company-wide share) |
| **SELinux Contexts** | finance_share_t, hr_share_t, mgmt_share_t | user_home_t only |
| **Auditd Logging** | ALL file access to dept shares | Standard auth/privilege escalation only |
| **Log Retention** | 7 years (compliance: SOX, GDPR) | 90 days (standard) |
| **Disk Encryption** | REQUIRED (LUKS full disk) | Recommended (not enforced) |
| **Physical Security** | Assigned device (serial # tracked) | Shared equipment (not tracked) |
| **Idle Timeout** | 5 minutes | 15 minutes |
| **USB Restrictions** | Disabled (except Yubikey) | Enabled |
| **Screen Privacy Filter** | Recommended (finance/HR) | Not required |

---

## Implementation: Ansible Configuration

### Host Variables (host_vars/laptop-david-01.yml)

```yaml
---
hostname: laptop-david-01
ip_address: 10.0.131.20
netmask: 255.255.255.0
gateway: 10.0.131.1
vlan_id: 131  # Admin network
dns_servers:
  - 10.0.120.10  # dc01
  - 10.0.120.11  # dc02

# Device assignment
device_type: laptop
assigned_user: david@corp.company.local
asset_tag: LAPTOP-2026-045
serial_number: "5CD12345ABC"  # From BIOS
allow_other_users: false

# User profile
user_role: manager
user_groups:
  - Managers
  - Executives
  - VPN-Users

# Security requirements
require_2fa: true
yubikey_required: true
yubikey_id: "ccccccdfjklm"  # David's Yubikey credential ID
full_disk_encryption: true
luks_enabled: true

# Network home directory
home_directory:
  type: cifs
  server: file-server01.corp.company.local
  path: shares/home/david
  mountpoint: /home/david
  options: sec=krb5,uid=%(USERUID),gid=%(USERGID)

# Department shares
department_shares:
  - name: management
    type: cifs
    server: file-server01.corp.company.local
    path: shares/departments/management
    mountpoint: /mnt/management
    required_group: Managers
    options: sec=krb5,uid=%(USERUID),gid=10100
    selinux_context: mgmt_share_t
    audit_all_access: true

# Session security
idle_timeout_minutes: 5  # Shorter than standard (15)
screen_lock_enabled: true
require_password_on_wake: true

# Logging
rsyslog_target: 10.0.120.60  # monitoring01
audit_level: verbose
audit_retention_days: 2555  # 7 years (SOX compliance)
log_department_share_access: true

# USB restrictions
usb_whitelist_only: true
usb_allowed_devices:
  - vendor_id: "1050"  # Yubico
    product_id: "0407"  # Yubikey 5 series
usb_block_storage: true
usb_allow_hid: true  # Keyboard/mouse
```

---

### Example Ansible Playbook Task: Configure Yubikey 2FA

```yaml
---
- name: Configure Yubikey 2FA for Privileged Users
  hosts: privileged_workstations
  become: yes
  tasks:
    - name: Install pam_u2f module
      dnf:
        name: pam-u2f
        state: present

    - name: Create U2F mappings directory
      file:
        path: /etc/u2f_mappings
        state: directory
        mode: '0755'

    - name: Deploy U2F mappings for assigned user
      template:
        src: u2f_mappings.j2
        dest: /etc/u2f_mappings
        mode: '0644'
      vars:
        username: "{{ assigned_user }}"
        yubikey_credential: "{{ yubikey_id }}"

    - name: Configure PAM for Yubikey authentication
      lineinfile:
        path: /etc/pam.d/gdm-password
        line: "auth required pam_u2f.so authfile=/etc/u2f_mappings cue origin=pam://{{ hostname }} appid=pam://{{ hostname }}"
        insertbefore: "auth.*pam_sss"
        state: present

    - name: Configure PAM host access control
      blockinfile:
        path: /etc/security/access.conf
        block: |
          # Only assigned user can log in to this device
          + : {{ assigned_user }} : {{ hostname }}
          - : ALL : {{ hostname }}
        marker: "# {mark} ANSIBLE MANAGED: Host assignment for {{ assigned_user }}"
        state: present

    - name: Enable auditd rule for 2FA events
      lineinfile:
        path: /etc/audit/rules.d/2fa.rules
        line: "-w /etc/u2f_mappings -p wa -k yubikey_config_changes"
        state: present
      notify: reload auditd

  handlers:
    - name: reload auditd
      service:
        name: auditd
        state: reloaded
```

---

## Test Cases for Validation

### Test Case 1: Assigned User Login with Yubikey
```
Test: David logs in to laptop-david-01 with correct password + Yubikey
Expected: Login succeeds, home + dept shares mounted, audit logged
Command: Physical test (GDM login)
```

### Test Case 2: Assigned User Login WITHOUT Yubikey
```
Test: David logs in with correct password, but no Yubikey present
Expected: Login DENIED, 2FA required, high-severity alert generated
Command: Physical test (remove Yubikey during login)
```

### Test Case 3: Wrong User Login Attempt
```
Test: Sarah tries to log in to David's laptop with her credentials
Expected: Login DENIED, unauthorized device access alert
Command: Physical test (different user account)
```

### Test Case 4: Department Share Access (Authorized)
```
Test: David accesses /mnt/management (he's in Managers group)
Expected: Access succeeds, all file operations logged to audit
Command: ssh david@10.0.131.20 "ls /mnt/management"
```

### Test Case 5: Cross-Department Access Attempt
```
Test: Sarah (Finance) tries to access HR share
Expected: Denied by Samba ACL + SELinux, audit logged
Command: ssh sarah@10.0.131.25 "ls /mnt/hr"
Expected: Permission denied
```

### Test Case 6: Bulk Download Detection
```
Test: Simulate rsync of entire Finance share
Expected: Anomaly detected, automatic quarantine, incident response triggered
Command: ssh sarah@10.0.131.25 "rsync -av /mnt/finance /tmp/test/"
Expected: Blocked after X files, alert generated
```

### Test Case 7: SELinux Enforcement
```
Test: Attempt to bypass Samba ACL (hypothetical)
Expected: SELinux blocks at kernel level, AVC denial logged
Command: Test requires simulated misconfiguration
```

### Test Case 8: Auditd Log Verification
```
Test: Access finance share, verify audit trail captured
Expected: All file opens/reads/writes logged with full context
Command: ausearch -k finance_share_access
Expected: Detailed audit trail with user, file, timestamp
```

### Test Case 9: Single-User Enforcement
```
Test: Attempt concurrent login (David logs in to another device)
Expected: Prevented by PAM host restriction
Command: ssh from different device
Expected: "This device is assigned to laptop-david-01"
```

### Test Case 10: Full Disk Encryption
```
Test: Boot laptop, verify LUKS encryption active
Expected: Passphrase prompt before system boot
Command: Physical test (reboot and observe)
```

---

## Compliance Benefits

### SOX (Sarbanes-Oxley) - Financial Controls
✅ **Access Control**: Only Finance group members can access financial data
✅ **Audit Trail**: All access to financial records logged (who, what, when)
✅ **Segregation of Duties**: Finance data isolated from HR, Management
✅ **Change Tracking**: All modifications to financial data audited
✅ **Non-repudiation**: Yubikey ensures user identity (can't claim "someone else used my password")

### GDPR (General Data Protection Regulation) - Privacy
✅ **Access Limitation**: HR data only accessible by authorized personnel
✅ **Audit Logging**: All access to personal data logged (GDPR Article 30)
✅ **Data Minimization**: Users only see data they need (role-based access)
✅ **Right to Access**: Audit logs show who accessed individual's data
✅ **Accountability**: Complete audit trail for data protection impact assessments

### HIPAA (Health Insurance Portability and Accountability Act)
✅ **Authentication**: 2FA (Yubikey) satisfies multi-factor requirement
✅ **Access Control**: Role-based access to protected health information
✅ **Audit Controls**: All PHI access logged (who accessed patient records)
✅ **Integrity Controls**: SELinux prevents unauthorized data modification
✅ **Transmission Security**: Encrypted CIFS mounts for data in transit

---

**Document Version:** 1.0
**Last Updated:** 2026-01-09
**For:** Privileged User Workstations (Managers, Finance, HR) - Enhanced Security Model
**Compliance:** SOX, GDPR, HIPAA audit requirements
