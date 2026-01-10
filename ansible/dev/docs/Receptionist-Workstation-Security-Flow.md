# Receptionist Workstation Security Flow
## Immutable Fedora Silverblue with AD Integration

---

## Use Case: Public Area Workstation

**Scenario:** Receptionist workstation in lobby area
- **User:** Sarah (Receptionist)
- **Location:** Front desk in common/public area
- **Risk Level:** HIGH (physical access, visible to guests/visitors)
- **Security Model:** Ephemeral/Immutable with nightly refresh

---

## Security Requirements

| Requirement | Implementation | Why |
|-------------|----------------|-----|
| **Ephemeral/Stateless** | Fedora Silverblue (immutable) | Nothing persists maliciously, forced nightly reset |
| **AD Authentication** | SSSD + Kerberos to dc01/dc02 | Centralized user management |
| **Single User Access** | PAM + AD group restriction | Only sarah@corp.company.local can log in |
| **Web-based Tools** | Firefox/Chrome to webmail, web apps | No local data storage |
| **Printer/Fax Access** | CUPS with drivers baked into OSTree | Works after nightly refresh |
| **Auto-lock** | 3-minute idle timeout (vs 15 min for normal users) | Protects if Sarah steps away |
| **Continuous Log Sync** | rsyslog to monitoring01 | Logs preserved even after nightly wipe |
| **Nightly Regeneration** | Automated OSTree reset + reboot at 2 AM | Fresh system daily |

---

## Security Flow Trace: Day in the Life

### **8:00 AM - Sarah Arrives and Logs In**

#### Step 1: System Boot

```
[7:58 AM] - Scheduled reboot completes (from 2 AM reset)

GRUB:
  ├─ Loads Fedora Silverblue OSTree snapshot
  ├─ Snapshot: silverblue-20260104-receptionist-v1.2
  ├─ This snapshot was created last week and is immutable
  └─ All previous day's changes discarded

Systemd Boot:
  ├─ Mounts root filesystem as READ-ONLY
  ├─ /var and /etc on overlay (ephemeral, reset nightly)
  ├─ /home on separate partition (but cleared nightly via script)
  └─ System boots to GDM login screen

Network Configuration:
  ├─ VLAN 130 (Workstations) - 10.0.130.25
  ├─ Static IP configured in OSTree image
  ├─ DNS points to dc01/dc02 (10.0.120.10, 10.0.120.11)
  └─ Firewall allows: DNS, LDAP, Kerberos, HTTPS, Syslog

First Boot Services:
  ├─ rsyslog starts → connects to monitoring01 (10.0.120.60)
  ├─ SSSD starts → connects to dc01 for AD authentication
  ├─ CUPS starts → network printers available
  └─ System ready for login
```

**Log Entry (monitoring01 receives via rsyslog):**
```
Jan 04 07:58:42 ws-reception01 systemd[1]: Started Daily OSTree Reset - Fresh Boot
Jan 04 07:58:45 ws-reception01 NetworkManager[812]: <info> DHCP declined, using static IP 10.0.130.25
Jan 04 07:58:46 ws-reception01 sssd[be[corp.company.local]]: Connected to dc01.corp.company.local
Jan 04 07:58:47 ws-reception01 rsyslog: [origin software="rsyslogd"] rsyslogd started, connected to monitoring01
```

---

#### Step 2: Sarah Attempts Login

```
[8:00 AM] Sarah arrives at desk:
  └─ Sees GDM login screen

Sarah enters credentials:
  ├─ Username: sarah@corp.company.local
  ├─ Password: [her AD password]
  └─ Clicks "Sign In"
       ↓
GDM Authentication Flow:
  ├─ Calls PAM (Pluggable Authentication Modules)
  ├─ PAM checks: /etc/pam.d/gdm-password
       ↓
PAM Stack:
  1. pam_unix.so → Skip (no local users)
  2. pam_sss.so → Query SSSD for AD authentication
       ↓
SSSD (System Security Services Daemon):
  ├─ Receives auth request: sarah@corp.company.local
  ├─ Queries dc01: "Authenticate user sarah@corp.company.local"
  ├─ Sends Kerberos request to dc01:389 (LDAP)
       ↓
dc01 (Domain Controller):
  ├─ Receives auth request from 10.0.130.25
  ├─ Checks: User sarah@corp.company.local exists? YES
  ├─ Checks: Password correct? YES
  ├─ Checks: Account enabled? YES
  ├─ Checks: User in "Receptionists" group? YES
  ├─ Issues Kerberos ticket (TGT) valid for 10 hours
  └─ Returns: SUCCESS + Kerberos TGT
       ↓
PAM Additional Check (Custom Rule):
  ├─ File: /etc/security/access.conf
  ├─ Rule: Only members of "Receptionists" group can log in to ws-reception01
  ├─ SSSD queries: Is sarah member of "Receptionists"? YES
  └─ Decision: ALLOW LOGIN
       ↓
GDM:
  ├─ Authentication successful
  ├─ Creates session for sarah@corp.company.local
  ├─ Applies desktop policies (web-only mode)
  └─ Logs event
       ↓
Rsyslog → monitoring01:
  [8:00:15] ws-reception01 gdm[1234]: User sarah@corp.company.local logged in from :0
  [8:00:15] ws-reception01 pam_sss: Authentication success for sarah@corp.company.local
  [8:00:15] ws-reception01 sssd[be]: Issued Kerberos ticket for sarah@corp.company.local (expires 6:00 PM)
```

**What Sarah sees:** Desktop loads with:
- Firefox (default browser, opens to company intranet)
- Web-based email (outlook.office365.com or webmail)
- Desktop locked down (cannot install software, cannot save files locally)
- Printer icon shows reception area printer available

**Security Value:**
- Authentication centralized (AD manages password complexity, expiration)
- Kerberos ticket has expiration (10 hours = 8 AM to 6 PM)
- All login attempts logged to monitoring01 (even if workstation wiped later)
- Group membership enforced (only Receptionists group can access this workstation)

---

### **10:30 AM - Wrong User Tries to Login (Sarah at lunch, workstation auto-locked)**

#### Security Scenario: Tom (Terminated Employee) Tries to Access

```
[10:30 AM] Sarah went to lunch, workstation auto-locked after 3 minutes

Tom walks by reception desk:
  └─ Sees locked screen
  └─ Clicks "Not Sarah? Sign in as different user"
       ↓
Tom enters HIS credentials:
  ├─ Username: tom@corp.company.local
  ├─ Password: [his old password, before he was fired]
  └─ Clicks "Sign In"
       ↓
GDM → PAM → SSSD:
  ├─ SSSD queries dc01: "Authenticate tom@corp.company.local"
       ↓
dc01 Response:
  ├─ Checks: User tom@corp.company.local exists? YES
  ├─ Checks: Account enabled? NO (DISABLED - he was fired last week)
  └─ Returns: AUTHENTICATION FAILED - Account Disabled
       ↓
PAM receives failure:
  ├─ Authentication DENIED
  └─ Logs failure
       ↓
GDM:
  ├─ Shows: "Authentication failed"
  └─ Returns to lock screen
       ↓
Rsyslog → monitoring01:
  [10:30:45] ws-reception01 gdm[2341]: Authentication FAILED for tom@corp.company.local
  [10:30:45] ws-reception01 pam_sss: Authentication failure (Account disabled) for tom@corp.company.local from :0
  [10:30:45] ws-reception01 sssd[be]: ALERT - Disabled user attempted login on ws-reception01
       ↓
Monitoring Alert Triggered:
  [10:30:46 AM] SECURITY ALERT: Disabled user login attempt
    User: tom@corp.company.local
    Workstation: ws-reception01 (10.0.130.25) - RECEPTION DESK
    Status: Account is DISABLED
    Action: Login DENIED

    Context: This is a public-area workstation
    Risk: Terminated employee attempting physical access

    Recommendation:
      - Review physical security at reception desk
      - Check if Tom is on premises (security cameras?)
      - Consider escort out of building if still employed

    Email: IT team, Security, HR
    SMS: Security manager (physical security concern)
```

**What Tom sees:** "Authentication failed" - No hint that account is disabled, no information leakage

**Security Value:**
- Physical access to workstation doesn't grant system access
- AD authentication blocks disabled users instantly
- Attempt logged even though workstation will be wiped tonight
- Alert escalated (physical security + IT security)
- No information disclosed to potential attacker

---

### **10:35 AM - Unauthorized User Tries to Login**

#### Security Scenario: David (Managing Partner) Tries to Use Reception Desk

```
[10:35 AM] David (Managing Partner) needs to print something quickly
  └─ Sarah still at lunch, workstation locked
  └─ David tries to log in with his credentials
       ↓
David enters:
  ├─ Username: david@corp.company.local
  ├─ Password: [his correct AD password]
  └─ Clicks "Sign In"
       ↓
GDM → PAM → SSSD:
  ├─ SSSD queries dc01: "Authenticate david@corp.company.local"
       ↓
dc01 Response:
  ├─ User david@corp.company.local exists? YES
  ├─ Account enabled? YES
  ├─ Password correct? YES
  ├─ Issues Kerberos ticket
  └─ Returns: SUCCESS
       ↓
PAM Additional Check (THIS IS WHERE IT DIFFERS):
  ├─ File: /etc/security/access.conf
  ├─ Rule: + : (Receptionists) : ws-reception01
  ├─ Rule: - : ALL : ws-reception01
  ├─ Checks: Is david member of "Receptionists" group?
       ↓
SSSD queries dc01:
  ├─ "Is david@corp.company.local member of Receptionists group?"
  ├─ dc01 checks Active Directory groups
  └─ Returns: NO (David is in "Partners" group, not "Receptionists")
       ↓
PAM Decision:
  ├─ Authentication to AD: SUCCESS
  ├─ Authorization to THIS workstation: DENIED
  └─ Final decision: ACCESS DENIED
       ↓
GDM:
  ├─ Shows: "You are not authorized to log in to this workstation"
  └─ Returns to lock screen
       ↓
Rsyslog → monitoring01:
  [10:35:22] ws-reception01 pam_access: Access DENIED for david@corp.company.local (not in Receptionists group)
  [10:35:22] ws-reception01 gdm[2456]: Authorization failed for david@corp.company.local on ws-reception01
  [10:35:22] ws-reception01 sssd[be]: User david@corp.company.local denied access (wrong workstation type)
```

**What David sees:** "You are not authorized to log in to this workstation. Please use your assigned workstation."

**Monitoring Entry (Low severity, informational):**
```
[10:35:22 AM] INFO: Unauthorized workstation access attempt
  User: david@corp.company.local (Managing Partner)
  Workstation: ws-reception01 (Reception Desk)
  Reason: User not in Receptionists group
  Action: Login DENIED

  Note: Valid user, wrong workstation type. Normal behavior.
  No action needed unless pattern emerges.
```

**Security Value:**
- Even valid AD users cannot access workstations they're not authorized for
- Role-based access control (RBAC) enforced at workstation level
- Prevents partners/managers from using public-area workstations (data leakage risk)
- Logged for compliance (who tried to access what, when)

---

### **2:00 PM - Sarah Prints Document to Reception Printer**

#### Security Flow: Network Printing

```
[2:00 PM] Sarah needs to print visitor badge for client

Sarah's Firefox:
  └─ Opens web-based visitor management system
  └─ Fills out visitor info
  └─ Clicks "Print Visitor Badge"
       ↓
Browser Print Dialog:
  ├─ Shows: "HP-Reception-Printer" (preconfigured)
  ├─ Sarah clicks "Print"
       ↓
CUPS (Common Unix Printing System):
  ├─ Print job created
  ├─ Job ID: 123
  ├─ Destination: HP-Reception-Printer (10.0.140.55 on IoT VLAN)
  ├─ Renders document to PostScript
       ↓
Network Path:
  Source: ws-reception01 (10.0.130.25, VLAN 130 - Workstations)
  Destination: HP-Reception-Printer (10.0.140.55, VLAN 140 - IoT)
       ↓
Firewall (pfSense):
  ├─ Inspects packet:
  │   Source: 10.0.130.25 (Workstation VLAN)
  │   Destination: 10.0.140.55 (IoT VLAN)
  │   Protocol: IPP (Internet Printing Protocol, port 631)
  ├─ Checks firewall rules:
  │   Rule: VLAN 130 → VLAN 140 = DENY (default)
  │   Exception: VLAN 130 → VLAN 140 port 631 (IPP) = PERMIT
  │   Specific printers only: 10.0.140.55, 10.0.140.56, 10.0.140.57
  ├─ Decision: PERMIT (workstations can print to approved printers)
  └─ Logs connection
       ↓
Printer receives job:
  ├─ Prints visitor badge
  └─ Job completes
       ↓
Rsyslog → monitoring01:
  [14:00:15] ws-reception01 cupsd: Print job 123 sent to HP-Reception-Printer by sarah@corp.company.local
  [14:00:18] pfSense filterlog: PERMIT,vlan130,out,10.0.130.25,10.0.140.55,TCP,631,IPP,print-job
  [14:00:22] ws-reception01 cupsd: Print job 123 completed successfully
```

**Why printer config survives reboot:**
- Printer drivers and CUPS config baked into OSTree image
- `/etc/cups/printers.conf` part of immutable snapshot
- Every morning after reboot, printer is already configured
- No user intervention needed

**Security Value:**
- Workstations can ONLY print to approved printers (whitelist in firewall)
- Cannot access other IoT devices (cameras, door controllers, etc.)
- Print jobs logged (compliance requirement in some industries)
- If printer compromised (Scenario 3 from main article), cannot attack workstations

---

### **5:30 PM - Sarah Leaves, Workstation Auto-Locks**

#### Security Flow: Idle Timeout

```
[5:30 PM] Sarah finishes work, walks away without locking

GNOME Session Monitor:
  ├─ Detects no keyboard/mouse input
  ├─ Starts idle timer
       ↓
[5:33 PM] 3 minutes of idle time elapsed:
  ├─ GNOME triggers screen lock
  ├─ GDM locks screen
  ├─ Kerberos ticket still valid (expires 6 PM)
  └─ Sarah's session suspended but not logged out
       ↓
Rsyslog → monitoring01:
  [17:33:00] ws-reception01 gnome-session: Screen locked due to idle timeout (3 min) for sarah@corp.company.local
```

**Security Value:**
- Shorter timeout than normal workstations (3 min vs 15 min)
- Public area = higher risk of unauthorized physical access
- Session remains active (Sarah can unlock with password if she returns)

---

### **2:00 AM - Nightly Automated Reset**

#### Security Flow: Forced Regeneration

```
[2:00 AM] Cron job triggers nightly reset

Systemd Timer:
  ├─ Unit: workstation-nightly-reset.timer
  ├─ Triggers: workstation-nightly-reset.service
       ↓
Reset Script (/usr/local/bin/workstation-reset.sh):

Step 1: Sync final logs
  ├─ rsync -avz /var/log/* monitoring01:/logs/ws-reception01/$(date +%Y%m%d)/
  └─ Ensures all logs from past 24 hours are preserved

Step 2: Clear ephemeral data
  ├─ rm -rf /home/sarah/*  (clears any accidentally saved files)
  ├─ rm -rf /tmp/*  (clears temporary files)
  ├─ rm -rf /var/tmp/*  (clears temporary files)
  └─ Clears browser cache, cookies, history

Step 3: Reset to base OSTree snapshot
  ├─ rpm-ostree reset
  ├─ This discards any overlay changes (nothing should exist, but safety measure)
  ├─ Ensures system identical to base image
  └─ Any malware, rootkit, or persistence mechanism is wiped

Step 4: Reboot
  └─ systemctl reboot
       ↓
[2:01 AM] System reboots

[2:02 AM] System boots clean:
  ├─ Root filesystem is READ-ONLY (immutable)
  ├─ /var and /etc overlays are fresh
  ├─ /home is empty
  ├─ No persistence from previous day
  └─ Fresh system, identical to original deployment

Rsyslog → monitoring01 (before reboot):
  [02:00:00] ws-reception01 workstation-reset: Starting nightly reset
  [02:00:05] ws-reception01 workstation-reset: Logs synced to monitoring01
  [02:00:10] ws-reception01 workstation-reset: Ephemeral data cleared
  [02:00:15] ws-reception01 workstation-reset: OSTree reset complete
  [02:00:20] ws-reception01 workstation-reset: Initiating reboot
  [02:00:25] ws-reception01 systemd: Rebooting...

Rsyslog → monitoring01 (after reboot):
  [02:02:15] ws-reception01 systemd: System boot complete (post-nightly-reset)
  [02:02:20] ws-reception01 workstation-reset: Boot verification - System clean
```

**Security Value:**
- Any malware installed during the day is wiped (cannot persist)
- Any files accidentally saved to /home are deleted (no data leakage)
- Browser history/cookies cleared (privacy in public area)
- System returns to known-good state every 24 hours
- Logs preserved before wipe (forensics still possible)

---

## Complete Security Chain Visualization

```
┌─────────────────────────────────────────────────────────────────┐
│                    RECEPTIONIST WORKSTATION                      │
│                   (Fedora Silverblue Immutable)                  │
│                        10.0.130.25 VLAN 130                      │
└────────────────────────────┬────────────────────────────────────┘
                             │
                ┌────────────┼────────────┐
                │            │            │
         ┌──────▼──────┐ ┌──▼───┐ ┌─────▼─────┐
         │ dc01/dc02   │ │Print │ │monitoring01│
         │ (AD Auth)   │ │VLAN  │ │ (Rsyslog)  │
         │ VLAN 120    │ │140   │ │  VLAN 120  │
         └─────────────┘ └──────┘ └────────────┘

Security Layers Applied:

Layer 1: Physical Access
  └─> Public area, visible to guests
      Risk: Unauthorized physical access

Layer 2: Authentication (AD via SSSD)
  └─> Only valid AD users can attempt login
      Blocked: Disabled accounts (Tom)

Layer 3: Authorization (PAM + access.conf)
  └─> Only "Receptionists" group can log in
      Blocked: Valid users not in group (David)

Layer 4: Session Security
  └─> Auto-lock after 3 minutes idle
      Protects: If Sarah walks away

Layer 5: Network Segmentation
  └─> Firewall rules: Can only reach approved resources
      Allowed: AD servers, approved printers, internet (filtered)
      Blocked: Server VLAN, Management VLAN, other workstations

Layer 6: Read-Only Root Filesystem
  └─> Immutable OSTree prevents persistence
      Blocked: Malware installation, rootkits, system changes

Layer 7: Nightly Reset (2 AM)
  └─> Full system regeneration
      Wipes: Malware, saved files, browser data, any changes

Layer 8: Continuous Logging (Rsyslog)
  └─> All events logged to monitoring01 in real-time
      Preserved: Even after nightly wipe, logs remain for forensics
```

---

## Log Retention and Forensics

### Where Logs Are Stored

```
monitoring01 Log Structure:
/var/log/workstations/
  └─ ws-reception01/
      ├─ 20260104/
      │   ├─ auth.log         (all login attempts)
      │   ├─ syslog           (system events)
      │   ├─ audit.log        (security events)
      │   └─ cups.log         (print jobs)
      ├─ 20260103/
      │   └─ [previous day's logs]
      └─ 20260102/
          └─ [older logs]

Retention: 90 days (compliance requirement)
Backup: Logs backed up nightly to backup-server
```

### Example: Investigating Unauthorized Access Attempt

```bash
# On monitoring01, search for failed login attempts on ws-reception01

grep "Authentication FAILED" /var/log/workstations/ws-reception01/20260104/auth.log

Output:
Jan 04 10:30:45 ws-reception01 pam_sss: Authentication failure (Account disabled) for tom@corp.company.local
Jan 04 14:22:33 ws-reception01 pam_sss: Authentication failure (Invalid password) for guest@corp.company.local

# Search for who successfully logged in that day
grep "logged in" /var/log/workstations/ws-reception01/20260104/syslog

Output:
Jan 04 08:00:15 ws-reception01 gdm[1234]: User sarah@corp.company.local logged in from :0

# Conclusion: Only Sarah successfully logged in, 2 failed attempts (Tom and unknown "guest")
```

**Security Value:**
- Even though workstation is wiped nightly, complete audit trail exists
- Can prove who accessed workstation on any given day
- Can detect patterns (repeated failed login attempts = investigation needed)
- Compliance requirement met (know who accessed what, when)

---

## Comparison: Receptionist vs. Standard Workstation

| Feature | Receptionist (ws-reception01) | Standard User (ws-user-10) |
|---------|-------------------------------|----------------------------|
| **OS Type** | Fedora Silverblue (immutable) | Fedora Workstation (standard) |
| **Root Filesystem** | Read-only (OSTree) | Read-write (normal) |
| **Nightly Reset** | YES (forced at 2 AM) | NO (persistent) |
| **Who Can Login** | Only "Receptionists" group | User's assigned group |
| **Idle Timeout** | 3 minutes | 15 minutes |
| **Local File Storage** | Discouraged, wiped nightly | Normal /home persistence |
| **Application Install** | Impossible (read-only root) | Allowed via sudo |
| **Log Sync** | Real-time rsyslog | Daily batch sync |
| **Physical Location** | Public area (lobby) | Office area (secured) |
| **Risk Level** | HIGH (public access) | MEDIUM (office access) |

---

## Implementation: Ansible Configuration

### Host Variables (host_vars/ws-reception01.yml)

```yaml
---
hostname: ws-reception01
ip_address: 10.0.130.25
netmask: 255.255.255.0
gateway: 10.0.130.1
vlan_id: 130
dns_servers:
  - 10.0.120.10  # dc01
  - 10.0.120.11  # dc02

# Workstation-specific settings
workstation_type: receptionist
workstation_profile: high_security_public_area

# OS Configuration
os_type: fedora_silverblue
os_immutable: true
nightly_reset: true
reset_time: "02:00"

# User Access Control
allowed_ad_groups:
  - Receptionists
denied_ad_groups:
  - ALL  # Deny everyone except allowed groups

# Session Security
idle_timeout_minutes: 3
screen_lock_enabled: true
suspend_on_lid_close: false  # Desktop, not laptop

# Application Restrictions
allow_local_apps: false  # Web-only mode
allow_software_install: false
browser_only_mode: true

# Printer Configuration
printers:
  - name: HP-Reception-Printer
    ip: 10.0.140.55
    driver: hplip
    default: true
  - name: HP-Reception-Fax
    ip: 10.0.140.56
    driver: hplip
    default: false

# Logging
rsyslog_target: 10.0.120.60  # monitoring01
rsyslog_protocol: tcp
rsyslog_port: 514
log_all_auth_attempts: true

# Monitoring
monitoring_level: verbose
alert_on_failed_login: true
alert_on_unauthorized_group: true
```

---

## Security Benefits Summary

### What This Protects Against

✅ **Terminated Employee Access** - Tom's disabled account blocked at AD level
✅ **Unauthorized User Access** - David's valid account blocked (not in Receptionists group)
✅ **Malware Persistence** - Nightly reset wipes any malware
✅ **Data Leakage** - No local file storage, web-only mode
✅ **Physical Security Breach** - Auto-lock after 3 minutes
✅ **Compromised Session** - Kerberos tickets expire, session doesn't persist overnight
✅ **Rootkit/Backdoor** - Immutable root filesystem prevents installation

### What Gets Logged

📋 **Login Attempts** - Successful and failed, with username and reason
📋 **Authorization Failures** - Valid users denied due to group membership
📋 **Print Jobs** - Who printed what, when
📋 **System Events** - Boot, shutdown, reset, errors
📋 **Network Connections** - What services were accessed

### Compliance Benefits

- **HIPAA**: Audit trail of who accessed workstation in medical office lobby
- **SOC 2**: Access control, logging, immutable infrastructure
- **PCI-DSS**: No credit card data stored on public-area workstation
- **GDPR**: No personal data persists, right to erasure enforced automatically

---

**Document Version:** 1.0
**Last Updated:** 2026-01-09
**For:** Receptionist workstation (ws-reception01) - Public Area Security Model
