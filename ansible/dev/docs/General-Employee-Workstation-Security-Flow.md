# General Employee Workstation Security Flow
## Zero-Trust Desktop with Network-Mounted Home Directories

---

## Use Case: Standard Office Employee Workstation

**Scenario:** General employee workstation in office area
- **Users:** Multiple employees (john, jane, mike, etc.) from "Employees" AD group
- **Location:** Office area (not public, but shared equipment)
- **Risk Level:** MEDIUM (multiple users share equipment, network-mounted home)
- **Security Model:** Defense-in-depth with network isolation and mandatory access controls

---

## Architecture Overview

```
┌─────────────────────────────────────────────────────────────────┐
│                     GENERAL EMPLOYEE WORKSTATION                 │
│                        ws-employee-01                            │
│                     10.0.130.30 (VLAN 130)                       │
│                                                                   │
│  ┌──────────────────────────────────────────────────────────┐  │
│  │  Local Filesystem (MAC/DAC/ACL Protected)                 │  │
│  │  ├─ /              (root - immutable, user cannot touch)  │  │
│  │  ├─ /usr           (read-only for users)                  │  │
│  │  ├─ /var           (read-only for users)                  │  │
│  │  ├─ /etc           (read-only for users)                  │  │
│  │  ├─ /tmp           (user writable, cleared on logout)     │  │
│  │  └─ /home          (mount point for network shares)       │  │
│  └──────────────────────────────────────────────────────────┘  │
│                                                                   │
│  Network Home Directory:                                          │
│  /home/john  → Mounted from file-server01:/shares/home/john      │
│                                                                   │
└────────────────────────────┬──────────────────────────────────┘
                             │
                ┌────────────┼────────────────────┐
                │            │                    │
         ┌──────▼──────┐ ┌──▼────────────┐ ┌────▼──────┐
         │ dc01/dc02   │ │file-server01  │ │monitoring01│
         │ (AD Auth)   │ │(Home dirs)    │ │(Logs)      │
         │ VLAN 120    │ │VLAN 120       │ │VLAN 120    │
         └─────────────┘ └───────────────┘ └────────────┘

         ┌──────────────────────────────────────────────┐
         │     WORKSTATION ISOLATION (Firewall)         │
         │  Each desktop = isolated zone                │
         │  ws-employee-01 CANNOT talk to ws-employee-02│
         │  Even though same VLAN 130                   │
         └──────────────────────────────────────────────┘
```

---

## Security Requirements

| Requirement | Implementation | Why |
|-------------|----------------|-----|
| **AD Authentication** | SSSD + Kerberos | Centralized user management |
| **Network Home Directory** | NFS/CIFS mount to file-server01 | Data centralized, backed up |
| **DAC (Discretionary Access Control)** | Standard Unix permissions (chmod/chown) | Basic file ownership |
| **ACL (Access Control Lists)** | POSIX ACLs (setfacl/getfacl) | Fine-grained permissions |
| **MAC (Mandatory Access Control)** | SELinux enforcing mode | Kernel-level enforcement |
| **Audit Logging** | auditd rules | Track all file access, privilege escalation |
| **Workstation Isolation** | pfSense firewall rules | Each desktop isolated, even on same subnet |
| **Ansible Management** | SSH access for ansible@ansible-ctrl | Automated configuration |
| **Multiple User Support** | PAM + SSSD allows any Employee group member | Shared workstation |

---

## Security Flow Trace: User Login with Network Home Directory

### **Scenario 1: John Logs In (First Login of the Day)**

#### Step 1: Authentication

```
[8:00 AM] John sits at ws-employee-01

GDM Login Screen:
  ├─ Username: john@corp.company.local
  ├─ Password: [entered]
  └─ Click "Sign In"
       ↓
PAM Stack (/etc/pam.d/gdm-password):
  ├─ pam_sss.so → SSSD queries dc01
       ↓
dc01 (Active Directory):
  ├─ User john@corp.company.local exists? YES
  ├─ Password correct? YES
  ├─ Account enabled? YES
  ├─ Member of "Employees" group? YES
  ├─ Issue Kerberos TGT (valid 10 hours)
  └─ Return: SUCCESS
       ↓
PAM creates local user session:
  ├─ UID assigned dynamically (e.g., 1601000)
  ├─ GID assigned dynamically (e.g., 1601000)
  ├─ Home directory: /home/john
  └─ Shell: /bin/bash
```

**Audit Log (auditd):**
```
type=USER_AUTH msg=audit(1704369600.123:100): pid=1234 uid=0 auid=1601000
  ses=1 msg='op=PAM:authentication acct="john@corp.company.local"
  exe="/usr/sbin/gdm" hostname=ws-employee-01 addr=? terminal=:0 res=success'
```

---

#### Step 2: Home Directory Mount

```
PAM session module (pam_mount.so):
  ├─ User authenticated successfully
  ├─ Read /etc/security/pam_mount.conf.xml
  ├─ Configuration for network home:
  │   <volume user="*"
  │           fstype="cifs"
  │           server="file-server01.corp.company.local"
  │           path="shares/home/%(USER)"
  │           mountpoint="/home/%(USER)"
  │           options="sec=krb5,uid=%(USERUID),gid=%(USERGID)" />
       ↓
Mount Process:
  ├─ Check: Does /home/john exist locally? Create if not
  ├─ Mount command:
  │   mount -t cifs //file-server01/shares/home/john /home/john \
  │     -o sec=krb5,uid=1601000,gid=1601000,forceuid,forcegid,file_mode=0700,dir_mode=0700
       ↓
Kerberos Authentication to File Server:
  ├─ Use John's Kerberos TGT from AD
  ├─ Contact file-server01 (10.0.120.20)
  ├─ Request: Access to //file-server01/shares/home/john
       ↓
file-server01 receives request:
  ├─ Check Kerberos ticket: Valid for john@corp.company.local? YES
  ├─ Check share permissions: john has access to /shares/home/john? YES
  ├─ Grant access
  └─ Return: CIFS share mounted
       ↓
Mount successful:
  /home/john now shows contents from file-server01:/shares/home/john
       ↓
GDM completes login:
  └─ John sees his desktop, /home/john has his files
```

**System Log:**
```
Jan 09 08:00:05 ws-employee-01 pam_mount: mount.cifs: Successfully mounted //file-server01/shares/home/john to /home/john
Jan 09 08:00:05 ws-employee-01 kernel: CIFS: Attempting to mount //file-server01/shares/home/john
Jan 09 08:00:05 ws-employee-01 systemd-logind: New session 1 of user john@corp.company.local
```

**Audit Log:**
```
type=USER_START msg=audit(1704369605.456:105): pid=1234 uid=0 auid=1601000
  ses=1 msg='op=PAM:session_open acct="john@corp.company.local"
  exe="/usr/sbin/gdm" hostname=ws-employee-01 res=success'

type=MOUNT msg=audit(1704369605.789:106): pid=2345 uid=0 auid=1601000
  ses=1 msg='op=mount path="/home/john" dev="//file-server01/shares/home/john"
  exe="/usr/bin/mount.cifs" res=success'
```

---

#### Step 3: DAC/ACL/MAC Enforcement

**DAC (Discretionary Access Control) - Unix Permissions:**

```bash
# On local workstation filesystem
$ ls -la /
drwxr-xr-x.  root root /              # Root can write, users read-only
drwxr-xr-x.  root root /usr           # Users read-only
drwxr-xr-x.  root root /etc           # Users read-only
drwxr-xr-x.  root root /var           # Users read-only
drwxrwxrwt.  root root /tmp           # All users can write (sticky bit)
drwxr-xr-x.  root root /home          # Home mount point

# John's mounted home directory
$ ls -la /home/john
drwx------. 1601000 1601000 /home/john              # Only John can access
drwx------. 1601000 1601000 /home/john/Documents
drwx------. 1601000 1601000 /home/john/Desktop
```

**What John CANNOT do:**
```bash
$ touch /etc/test.conf
touch: cannot touch '/etc/test.conf': Permission denied

$ echo "malware" > /usr/bin/malware
bash: /usr/bin/malware: Permission denied

$ cat /var/log/auth.log
cat: /var/log/auth.log: Permission denied

$ ls /home/jane
ls: cannot open directory '/home/jane': Permission denied
```

**Audit Log (failed attempts):**
```
type=PATH msg=audit(1704370000.123:200): item=0 name="/etc/test.conf"
  inode=12345 dev=08:01 mode=040755 ouid=0 ogid=0 rdev=00:00
  obj=system_u:object_r:etc_t:s0 nametype=CREATE cap_fp=0 cap_fi=0
  cap_fe=0 cap_fver=0 cap_frootid=0

type=SYSCALL msg=audit(1704370000.123:200): arch=c000003e syscall=257
  success=no exit=-13 a0=ffffff9c a1=7ffd1234 a2=241 a3=1b6 items=1
  ppid=3456 pid=4567 auid=1601000 uid=1601000 gid=1601000
  euid=1601000 suid=1601000 fsuid=1601000 egid=1601000 sgid=1601000
  fsgid=1601000 tty=pts0 ses=1 comm="touch"
  exe="/usr/bin/touch" subj=unconfined_u:unconfined_r:unconfined_t:s0
  key="etc_write_attempt"
```

---

**ACL (Access Control Lists) - Fine-Grained Permissions:**

```bash
# Example: John creates a shared document for jane to read

$ cd /home/john/Documents
$ touch project-report.doc
$ getfacl project-report.doc
# file: project-report.doc
# owner: john
# group: john
user::rw-
group::---
other::---

# John grants jane read-only access via ACL
$ setfacl -m u:jane@corp.company.local:r project-report.doc

$ getfacl project-report.doc
# file: project-report.doc
# owner: john
# group: john
user::rw-
user:jane@corp.company.local:r--
group::---
mask::r--
other::---
```

**What this allows:**
- John can read/write his own file (user::rw-)
- Jane can read John's file (user:jane:r--)
- Nobody else can access it (other::---)

**Audit Log (ACL modification):**
```
type=SYSCALL msg=audit(1704370500.456:250): arch=c000003e syscall=188
  success=yes exit=0 a0=3 a1=7ffd5678 a2=22 a3=0 items=1 ppid=4567
  pid=5678 auid=1601000 uid=1601000 gid=1601000 comm="setfacl"
  exe="/usr/bin/setfacl" key="acl_modification"
```

---

**MAC (Mandatory Access Control) - SELinux:**

```bash
# SELinux enforces kernel-level mandatory policies

$ getenforce
Enforcing

# SELinux contexts on files
$ ls -Z /home/john
drwx------. john john unconfined_u:object_r:user_home_dir_t:s0 /home/john

# SELinux prevents John from modifying system binaries
$ echo "malware" > /usr/bin/ls
bash: /usr/bin/ls: Permission denied

# Even if DAC allowed it (hypothetically), SELinux would block
$ ls -Z /usr/bin/ls
-rwxr-xr-x. root root system_u:object_r:bin_t:s0 /usr/bin/ls

# SELinux policy:
# - user_home_dir_t can only be modified by its owner
# - bin_t can only be modified by system processes (not user processes)
# - unconfined_u (user domain) cannot transition to system_u
```

**SELinux Denial (if John tries to modify system files):**
```
type=AVC msg=audit(1704371000.789:300): avc:  denied  { write }
  for pid=6789 comm="bash" name="ls" dev="dm-0" ino=12345
  scontext=unconfined_u:unconfined_r:unconfined_t:s0
  tcontext=system_u:object_r:bin_t:s0 tclass=file permissive=0
```

---

#### Step 4: Auditd Rules for Security Monitoring

**Configuration: /etc/audit/rules.d/employee-workstation.rules**

```bash
# Monitor authentication events
-w /var/log/auth.log -p wa -k auth_log_changes
-w /etc/passwd -p wa -k passwd_changes
-w /etc/shadow -p wa -k shadow_changes
-w /etc/sudoers -p wa -k sudoers_changes

# Monitor privilege escalation attempts
-a always,exit -F arch=b64 -S execve -F euid=0 -F auid>=1000 -k privilege_escalation
-w /usr/bin/sudo -p x -k sudo_execution

# Monitor file access in sensitive directories
-w /etc/ -p wa -k etc_changes
-w /var/log/ -p wa -k log_changes
-w /usr/bin/ -p wa -k bin_changes
-w /usr/sbin/ -p wa -k sbin_changes

# Monitor network home directory access
-a always,exit -F arch=b64 -S mount -S umount2 -k home_directory_mount

# Monitor ACL modifications
-a always,exit -F arch=b64 -S setxattr -S lsetxattr -S fsetxattr -k acl_modifications

# Monitor suspicious file operations
-a always,exit -F arch=b64 -S unlink -S unlinkat -S rename -S renameat -k file_deletion

# Monitor network connections
-a always,exit -F arch=b64 -S socket -S connect -k network_connections
```

**Audit Events Generated:**

```
# John reads a file in his home directory (normal operation)
type=SYSCALL msg=audit(1704372000.123:400): arch=c000003e syscall=257
  success=yes exit=3 a0=ffffff9c a1=7ffd9abc comm="cat"
  exe="/usr/bin/cat" key="normal_file_access"

# John tries to sudo (privilege escalation attempt)
type=EXECVE msg=audit(1704372100.456:410): argc=2 a0="sudo" a1="ls"
type=SYSCALL msg=audit(1704372100.456:410): arch=c000003e syscall=59
  success=yes exit=0 euid=0 auid=1601000 comm="sudo"
  exe="/usr/bin/sudo" key="privilege_escalation"

# Logs sent to monitoring01 via rsyslog
```

---

## Workstation Network Isolation (Zero-Trust Model)

### Firewall Rules: Each Desktop is Isolated Zone

**Problem:** Traditional setup = all workstations on VLAN 130 can talk to each other
- ws-employee-01 (10.0.130.30) can ping ws-employee-02 (10.0.130.31)
- Lateral movement risk: If one workstation compromised, attacker can pivot to others

**Solution:** Firewall private VLAN (PVLAN) or firewall micro-segmentation

```
pfSense Firewall Rules (VLAN 130 - Workstations):

Rule 1: Allow workstation → Servers (VLAN 120)
  Source: VLAN 130 (any workstation)
  Destination: VLAN 120 (Servers: dc01, dc02, file-server01)
  Ports: 88 (Kerberos), 389/636 (LDAP), 445 (SMB), 22 (SSH from ansible only)
  Action: PERMIT
  Log: Yes

Rule 2: Allow workstation → Internet
  Source: VLAN 130
  Destination: !RFC1918 (Internet)
  Ports: 80, 443 (HTTP/HTTPS)
  Action: PERMIT
  Log: Yes

Rule 3: DENY workstation → workstation (ISOLATION)
  Source: 10.0.130.30 (ws-employee-01)
  Destination: 10.0.130.31 (ws-employee-02)
  Ports: ANY
  Action: DENY
  Log: Yes

Rule 4: DENY workstation → workstation (ISOLATION)
  Source: 10.0.130.31 (ws-employee-02)
  Destination: 10.0.130.30 (ws-employee-01)
  Ports: ANY
  Action: DENY
  Log: Yes

Rule 5: Allow ansible-ctrl → workstations (Management)
  Source: 10.0.120.50 (ansible-ctrl)
  Destination: VLAN 130 (all workstations)
  Ports: 22 (SSH)
  Action: PERMIT
  Log: Yes

Rule 6: DEFAULT DENY
  Source: ANY
  Destination: ANY
  Action: DENY
  Log: Yes
```

**Result:**
- ws-employee-01 **CAN** access dc01, file-server01, internet
- ws-employee-01 **CANNOT** access ws-employee-02 (even though same subnet)
- ansible-ctrl **CAN** SSH to all workstations for management

**Test from ws-employee-01:**
```bash
# Can reach file server (VLAN 120)
$ ping 10.0.120.20
PING 10.0.120.20 (10.0.120.20) 56(84) bytes of data.
64 bytes from 10.0.120.20: icmp_seq=1 ttl=64 time=1.2 ms

# CANNOT reach other workstation (same VLAN 130)
$ ping 10.0.130.31
PING 10.0.130.31 (10.0.130.31) 56(84) bytes of data.
^C
--- 10.0.130.31 ping statistics ---
5 packets transmitted, 0 received, 100% packet loss

# Firewall log shows block
Jan 09 08:30:00 pfSense filterlog: BLOCK,vlan130,in,10.0.130.30,10.0.130.31,ICMP,echo-request
```

---

## Ansible Management Access

### How Ansible Accesses Workstations via SSH

**Scenario:** Ansible needs to deploy software update to ws-employee-01

```
ansible-ctrl (10.0.120.50):
  └─ ansible-playbook playbooks/update-workstations.yml
       ↓
Ansible SSH Connection:
  Source: 10.0.120.50 (ansible-ctrl, VLAN 120)
  Destination: 10.0.130.30 (ws-employee-01, VLAN 130)
  Port: 22 (SSH)
       ↓
pfSense Firewall:
  ├─ Check Rule 5: ansible-ctrl → workstations:22 = PERMIT
  ├─ Allow connection
  └─ Log: "PERMIT,vlan120,out,10.0.120.50,10.0.130.30,TCP,22,SSH"
       ↓
ws-employee-01 sshd:
  ├─ Receives connection from ansible-ctrl
  ├─ Authentication: SSH key (ansible user)
  ├─ Check /home/ansible/.ssh/authorized_keys
  ├─ Key matches
  └─ Grant access
       ↓
Ansible executes task:
  └─ dnf update -y
       ↓
Audit log captures:
  type=USER_CMD msg=audit(1704375000.123:500): pid=8901 uid=2000
    auid=2000 ses=10 msg='cwd="/home/ansible" cmd="dnf update -y"
    terminal=ssh res=success' key="ansible_command"
```

**Security Value:**
- Only ansible-ctrl can SSH to workstations (not other workstations)
- Ansible uses dedicated service account (not root)
- All Ansible commands logged via auditd
- Firewall allows management, blocks lateral movement

---

## Concurrent Login Scenario: Same User, Two Workstations

### **Scenario 2: John Logs Into TWO Workstations Simultaneously**

```
[9:00 AM] John is logged into ws-employee-01
  └─ /home/john mounted from file-server01:/shares/home/john

[9:15 AM] John walks to different desk, logs into ws-employee-02
  └─ Attempts to mount /home/john from file-server01:/shares/home/john
```

#### What Happens: Network Home Directory Concurrent Access

```
ws-employee-02 login process:
  ├─ AD authentication: SUCCESS (John can log in to multiple workstations)
  ├─ PAM attempts to mount /home/john
  ├─ Mount command: mount -t cifs //file-server01/shares/home/john /home/john
       ↓
file-server01 (Samba file server):
  ├─ Receives mount request from ws-employee-02 (10.0.130.31)
  ├─ Check: Is /shares/home/john already mounted?
  │   Yes, from ws-employee-01 (10.0.130.30)
  ├─ Samba SMB protocol supports multiple connections
  └─ Grant access (second mount succeeds)
       ↓
Result:
  ├─ ws-employee-01: /home/john mounted (session 1)
  ├─ ws-employee-02: /home/john mounted (session 2)
  └─ BOTH sessions access SAME files on file-server01
```

---

### **File Locking and Concurrency Issues**

#### Scenario A: John Edits Document on BOTH Workstations

```
[9:20 AM] ws-employee-01:
  John opens /home/john/Documents/report.odt in LibreOffice

LibreOffice:
  ├─ Opens file: /home/john/Documents/report.odt
  ├─ Creates lock file: /home/john/Documents/.~lock.report.odt#
  ├─ Lock file contains: ws-employee-01, john, timestamp
  └─ Edits document

[9:22 AM] ws-employee-02:
  John (forgetting he has it open elsewhere) opens same file

LibreOffice on ws-employee-02:
  ├─ Attempts to open: /home/john/Documents/report.odt
  ├─ Checks for lock file: /home/john/Documents/.~lock.report.odt#
  ├─ Lock file EXISTS (from ws-employee-01)
  └─ Shows warning: "Document is locked for editing by john on ws-employee-01"
       ↓
LibreOffice Decision:
  ├─ Option 1: Open Read-Only
  ├─ Option 2: Open Copy (notify when original becomes available)
  └─ Option 3: Cancel
```

**What John sees on ws-employee-02:**
```
┌─────────────────────────────────────────────┐
│  Document "report.odt" is locked            │
│                                             │
│  The document is already open for editing   │
│  by john on ws-employee-01.                 │
│                                             │
│  You can:                                   │
│  [ ] Open Read-Only                         │
│  [ ] Open a Copy                            │
│  [X] Cancel                                 │
└─────────────────────────────────────────────┘
```

**Security/Integrity Value:**
- Application-level locking prevents concurrent write conflicts
- User notified which workstation has file open
- Data corruption prevented

---

#### Scenario B: File Saved Simultaneously (Race Condition)

**Worst Case:** John edits TEXT file (no lock file) on both workstations

```
[9:30 AM] ws-employee-01:
  $ nano /home/john/Documents/notes.txt
  Add line: "Meeting with client at 2 PM"
  Save (Ctrl+O)

  ↓ Network write to file-server01

[9:30:05 AM] ws-employee-02 (5 seconds later):
  $ nano /home/john/Documents/notes.txt
  Add line: "Call vendor about invoice"
  Save (Ctrl+O)

  ↓ Network write to file-server01
```

**File Server Behavior (Samba):**
```
file-server01:
  [9:30:00] Receives write from ws-employee-01
    ├─ Write to /shares/home/john/Documents/notes.txt
    ├─ File updated
    └─ Cache synced

  [9:30:05] Receives write from ws-employee-02
    ├─ Write to /shares/home/john/Documents/notes.txt
    ├─ File OVERWRITTEN (last write wins)
    └─ Cache synced
       ↓
Result: ws-employee-02 write OVERWRITES ws-employee-01 write
  ├─ John's "Meeting with client" line is LOST
  └─ Only "Call vendor" line remains
```

**This is a DATA RACE CONDITION**

---

### **Solutions to Concurrent Access Issues**

#### Solution 1: User Education
**Policy:** "Do not log in to multiple workstations simultaneously"
- Enforce via training
- Display warning at login if user already logged in elsewhere

#### Solution 2: Single Sign-On (SSO) with Session Enforcement
**Technology:** Configure PAM to check for existing sessions

```bash
# /etc/security/limits.conf
john@corp.company.local    maxlogins    1

# PAM configuration
# /etc/pam.d/common-session
session required pam_limits.so
```

**Result:** If John tries to log in to ws-employee-02 while logged into ws-employee-01:
```
Login attempt on ws-employee-02:
  ├─ AD authentication: SUCCESS
  ├─ PAM checks: How many active sessions for john? 1 (on ws-employee-01)
  ├─ pam_limits.so: maxlogins=1 exceeded
  └─ DENY login
       ↓
John sees:
  "Maximum number of logins exceeded. Please log out of other sessions."
```

**Audit Log:**
```
type=USER_ERR msg=audit(1704376000.789:600): pid=9012 uid=0 auid=1601000
  ses=2 msg='op=PAM:session_open acct="john@corp.company.local"
  exe="/usr/sbin/gdm" hostname=ws-employee-02 res=failed'
  reason='maxlogins exceeded'
```

---

#### Solution 3: Logout Previous Session (Single Session Enforcement)

**Configuration:** Force logout of previous session when user logs in elsewhere

```bash
# Script: /usr/local/bin/enforce-single-session.sh
#!/bin/bash
# Called by PAM during login

USER=$1
NEW_DISPLAY=$2

# Find existing sessions for this user
EXISTING_SESSIONS=$(loginctl list-sessions --no-legend | grep "$USER" | awk '{print $1}')

for SESSION in $EXISTING_SESSIONS; do
  SESSION_DISPLAY=$(loginctl show-session $SESSION -p Display --value)

  # If existing session on different display, terminate it
  if [ "$SESSION_DISPLAY" != "$NEW_DISPLAY" ]; then
    logger "Terminating existing session $SESSION for $USER (new login on $NEW_DISPLAY)"
    loginctl terminate-session $SESSION
  fi
done
```

**PAM configuration to call script:**
```bash
# /etc/pam.d/gdm-password
session optional pam_exec.so /usr/local/bin/enforce-single-session.sh
```

**What happens:**
```
[9:30 AM] John logs into ws-employee-02:
  ├─ AD authentication: SUCCESS
  ├─ PAM detects existing session on ws-employee-01
  ├─ Script terminates session on ws-employee-01
  │   ├─ /home/john unmounted on ws-employee-01
  │   ├─ All applications closed forcefully
  │   └─ User logged out
  ├─ New session created on ws-employee-02
  └─ /home/john mounted on ws-employee-02

[9:30:10] ws-employee-01:
  └─ John's screen shows: "Your session has ended. You have been logged out."
```

**Audit Log:**
```
type=USER_END msg=audit(1704376200.123:610): pid=3456 uid=1601000
  auid=1601000 ses=1 msg='op=PAM:session_close acct="john@corp.company.local"
  exe="/usr/sbin/gdm" hostname=ws-employee-01 res=success'
  reason='terminated by enforce-single-session'

type=USER_START msg=audit(1704376200.456:611): pid=4567 uid=1601000
  auid=1601000 ses=2 msg='op=PAM:session_open acct="john@corp.company.local"
  exe="/usr/sbin/gdm" hostname=ws-employee-02 res=success'
```

---

#### Solution 4: Concurrent Access Allowed with File Locking (Current Approach)

**Decision:** ALLOW concurrent logins, rely on application-level file locking

**Pros:**
- Flexibility: User can log in from home + office simultaneously
- Application-level locks prevent most conflicts (LibreOffice, MS Office)
- Network home directory supports multiple connections

**Cons:**
- User can accidentally edit same file on two machines (if no lock)
- Potential data race conditions with plain text files
- Increased network load (two workstations accessing same files)

**Recommended for General Employees:**
- Allow concurrent logins
- User education: "Don't edit same file on multiple computers"
- Most applications (Office suite, etc.) have built-in file locking
- Backup/versioning on file server catches data loss

---

## Security Flow Summary

### Login Process (Successful)
1. **Authentication** (AD via SSSD) → John's credentials verified
2. **Authorization** (PAM + group membership) → John is in "Employees" group
3. **Home Directory Mount** (CIFS/NFS to file-server01) → /home/john mounted
4. **DAC/ACL Enforcement** (Unix permissions) → John can only access his files
5. **MAC Enforcement** (SELinux) → Kernel prevents system file modification
6. **Audit Logging** (auditd) → All actions logged to monitoring01
7. **Network Isolation** (Firewall PVLAN) → John's workstation isolated from others

### Failed Access Attempts (Blocked)
- ❌ John tries to modify /etc → DAC denies (not owner)
- ❌ John tries to modify /usr/bin → MAC denies (SELinux policy)
- ❌ John tries to access /home/jane → DAC denies (not owner)
- ❌ John tries to ping other workstation → Firewall denies (PVLAN isolation)
- ❌ Attacker compromises ws-employee-01 → Cannot pivot to ws-employee-02 (firewall blocks)

### Concurrent Login Behavior
- ✅ John CAN log into multiple workstations (no restriction by default)
- ✅ /home/john accessible from all sessions (network-mounted)
- ⚠️ File locking depends on application (LibreOffice: yes, nano/vim: no)
- ⚠️ Race conditions possible with simultaneous edits (last write wins)
- 🔧 Optional: Enforce single session via PAM (force logout previous session)

---

## Test Cases for Validation

### Test Case 1: User Authentication
```
Test: Valid employee logs in
Expected: Authentication succeeds, home directory mounts, audit log created
Command: ssh john@10.0.130.30 "ls /home/john"
```

### Test Case 2: Invalid User Blocked
```
Test: User not in "Employees" group tries to log in
Expected: Authentication fails, no home directory mount, failure logged
Command: ssh contractor@10.0.130.30 "ls /home/contractor"
Expected Result: Permission denied
```

### Test Case 3: DAC Enforcement
```
Test: User tries to modify system file
Expected: Permission denied, audit log captures attempt
Command: ssh john@10.0.130.30 "touch /etc/malware.conf"
Expected Result: Permission denied
```

### Test Case 4: MAC Enforcement (SELinux)
```
Test: User tries to modify system binary
Expected: SELinux denies, AVC denial logged
Command: ssh john@10.0.130.30 "echo malware > /usr/bin/ls"
Expected Result: Permission denied (even if DAC somehow allowed)
```

### Test Case 5: Workstation Isolation
```
Test: One workstation tries to ping another
Expected: Firewall blocks, connection denied, logged
Command: ssh john@10.0.130.30 "ping 10.0.130.31"
Expected Result: 100% packet loss (firewall blocks)
```

### Test Case 6: Ansible Management Access
```
Test: Ansible can SSH to workstation for management
Expected: Connection succeeds, commands execute, audit logged
Command: ansible ws-employee-01 -m ping
Expected Result: SUCCESS
```

### Test Case 7: Concurrent Login
```
Test: User logs into two workstations simultaneously
Expected: Both logins succeed, same /home/john mounted on both
Command:
  Terminal 1: ssh john@10.0.130.30 "touch /home/john/test1.txt"
  Terminal 2: ssh john@10.0.130.31 "ls /home/john/test1.txt"
Expected Result: File visible from both sessions
```

### Test Case 8: File Locking (LibreOffice)
```
Test: Open same document on two workstations
Expected: Second open shows "locked" warning, open read-only
Steps:
  1. ws-employee-01: Open /home/john/doc.odt
  2. ws-employee-02: Open /home/john/doc.odt
Expected Result: Warning displayed, read-only mode offered
```

### Test Case 9: Audit Log Capture
```
Test: All security-relevant events logged
Expected: auditd captures events, rsyslog forwards to monitoring01
Command: ausearch -k privilege_escalation
Expected Result: All sudo attempts logged
```

### Test Case 10: Home Directory Unmount on Logout
```
Test: User logs out, home directory unmounted
Expected: /home/john unmounted, no lingering access
Command: loginctl terminate-session <session-id>
Expected Result: Mount removed from /proc/mounts
```

---

**Document Version:** 1.0
**Last Updated:** 2026-01-09
**For:** General Employee Workstations (ws-employee-XX) - Zero-Trust Desktop Model
