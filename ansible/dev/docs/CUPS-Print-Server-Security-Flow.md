# CUPS Print Server Security Flow - SMB Office IT Blueprint

## Document Purpose
This document traces security flows through the CUPS print server (Rocky/Oracle Linux) in the SMB Office IT Blueprint. It demonstrates how print job submission, authentication, authorization, and audit logging work together across multiple security layers.

**Target Audience:** Security auditors, compliance officers, IT administrators creating test cases and validation playbooks.

---

## Infrastructure Context

### Print Server Role
- **Hostname:** `print-server01`
- **OS:** Rocky Linux 9 (SELinux enforcing)
- **VLAN:** 120 (Servers) - `10.0.120.30/24`
- **Purpose:** Central print management via CUPS
- **Authentication:** Samba AD integration (GSSAPI/Kerberos)
- **Print Queues:** Department-based with quotas
- **Printers:** Physical devices on VLAN 140 (IoT) - isolated from server

### Network Architecture
```
┌─────────────────────────────────────────────────────────────────┐
│                      pfSense Firewall                            │
│  VLAN 110 (Management) │ VLAN 120 (Servers) │ VLAN 130 (Work)  │
│  VLAN 131 (Admin)      │ VLAN 140 (IoT)     │                   │
└─────────────────────────────────────────────────────────────────┘
         │                         │                        │
         │                         │                        │
    ┌────────┐              ┌──────────────┐         ┌──────────┐
    │ansible-│              │print-server01│         │laptop-   │
    │ctrl    │              │10.0.120.30   │         │john-01   │
    │(SSH)   │              │CUPS Server   │         │(IPP)     │
    └────────┘              └──────────────┘         └──────────┘
                                    │
                                    │ (ONE-WAY: server → IoT)
                                    ↓
                            ┌──────────────┐
                            │ VLAN 140     │
                            │ (IoT)        │
                            │              │
                            │ HP-Office-01 │ 10.0.140.10
                            │ Canon-HR-01  │ 10.0.140.11
                            │ Xerox-Fin-01 │ 10.0.140.12
                            └──────────────┘
```

**Key Security Boundaries:**
1. **Workstation → Print Server:** IPP (631/tcp) with Kerberos auth
2. **Print Server → IoT Printers:** One-way only (server initiates, printers cannot reach server VLAN)
3. **Ansible → Print Server:** SSH from ansible-ctrl only
4. **IoT VLAN Isolation:** Printers cannot communicate with each other or other VLANs

---

## Security Requirements

| Requirement | Implementation | Verification |
|------------|---------------|--------------|
| **Authentication** | Kerberos via Samba AD (GSSAPI) | Test unauthorized print attempt |
| **Authorization** | AD group-based print queue access | Test cross-department print denial |
| **Network Isolation** | Firewall rules: IPP from work VLANs only | Test direct IoT VLAN access (should fail) |
| **Print Quotas** | CUPS quota plugin per user/group | Test quota exceeded scenario |
| **Audit Logging** | CUPS access logs + auditd | Verify all print jobs logged |
| **SELinux Confinement** | cupsd runs in `cupsd_t` domain | Test policy violation (should deny) |
| **Job Privacy** | Only owner + print admins can view jobs | Test job viewing by other user |
| **Data Protection** | Print jobs encrypted in transit (IPP + TLS) | Verify TLS cert validation |
| **Printer Isolation** | Printers on separate VLAN (140), no lateral movement | Test printer-to-printer traffic |
| **Log Retention** | 7 years (SOX compliance) | Verify rsyslog forward to monitoring01 |

---

## Print Job Flow - Detailed Walkthrough

### Scenario 1: Successful Print Job Submission

**Context:**
- John (General Employee, Accounting dept) wants to print `quarterly-report.pdf`
- John's workstation: `laptop-john-01` (10.0.130.20)
- Target printer: `HP-Office-01` (general office printer)
- Date/Time: 2026-01-09 14:23:00

**Step-by-Step Security Flow:**

#### Step 1: User Initiates Print Job
```bash
# On laptop-john-01
$ lp -d HP-Office-01 quarterly-report.pdf
request id is HP-Office-01-42 (1 file(s))
```

**Security Check:**
- CUPS client library checks for valid Kerberos ticket
- Timing: 5ms

#### Step 2: Kerberos Ticket Acquisition
```
laptop-john-01 → dc01:88 (Kerberos)
  Request: TGS for HTTP/print-server01.office.local@OFFICE.LOCAL
  Principal: john@OFFICE.LOCAL

dc01 → laptop-john-01
  Response: Service ticket (valid 10 hours)
  Encryption: AES256-CTS-HMAC-SHA1-96
```

**Timing:** 15ms (ticket already cached from previous authentication)

#### Step 3: IPP Request to Print Server
```
laptop-john-01:ephemeral → print-server01:631 (IPP over TLS)
  POST /printers/HP-Office-01 HTTP/1.1
  Host: print-server01.office.local:631
  Authorization: Negotiate <base64-kerberos-token>
  Content-Type: application/pdf
  Content-Length: 2458623

  [PDF data encrypted with TLS 1.3]
```

**Firewall Check (pfSense):**
```
Rule: allow-ipp-from-workstations
  Source: 10.0.130.0/24 (Workstation VLAN)
  Destination: 10.0.120.30:631
  Action: PASS

Log: Jan 09 14:23:00 pfsense filterlog: PASS,130,10.0.130.20,10.0.120.30,tcp,631
```

**Timing:** 0.5ms (firewall processing)

#### Step 4: Print Server Receives Request
```
cupsd (PID 1234, SELinux context: system_u:system_r:cupsd_t:s0)
  ↓
1. TLS handshake validation
   - Client cert check: Not required (Kerberos used)
   - TLS 1.3 with ECDHE-RSA-AES256-GCM-SHA384
   - Timing: 12ms

2. Kerberos token validation
   - Extract token from Authorization header
   - Verify with dc01 (KDC)
   - Extract principal: john@OFFICE.LOCAL
   - Timing: 8ms

3. AD group membership lookup
   - Query dc01 for john's groups
   - Groups: Domain Users, Accounting, CN=Print-Users-General
   - Timing: 10ms
```

#### Step 5: Authorization Check
```
CUPS policy check for printer "HP-Office-01":
  <Policy default>
    <Limit Send-Document>
      Require user @Print-Users-General
      Require valid-user
    </Limit>
  </Policy>

Authorization result:
  ✓ john is member of @Print-Users-General
  ✓ john is authenticated (valid Kerberos ticket)
  → ALLOW
```

**Timing:** 2ms

#### Step 6: SELinux Policy Enforcement
```
SELinux check:
  Source context: system_u:system_r:cupsd_t:s0
  Target context: system_u:object_r:cupsd_var_run_t:s0 (job spool)
  Class: file
  Permission: write

Policy rule:
  allow cupsd_t cupsd_var_run_t:file { create write };

Result: ALLOW
```

**Timing:** <1ms

#### Step 7: Quota Check
```
CUPS quota plugin check:
  User: john@OFFICE.LOCAL
  Current usage: 847 pages (this month)
  Quota limit: 1000 pages/month
  Job size: 24 pages

  847 + 24 = 871 < 1000 → ALLOW
```

**Timing:** 3ms

#### Step 8: Job Spooling
```
cupsd writes job to:
  /var/spool/cups/d00042-001 (PDF data)
  /var/spool/cups/c00042 (control file)

Control file contents:
  Job-ID: 42
  User: john@OFFICE.LOCAL
  Printer: HP-Office-01
  Pages: 24
  Timestamp: 2026-01-09T14:23:00Z
```

**Auditd Log:**
```
type=SYSCALL msg=audit(1736431380.123:4567): arch=c000003e syscall=2 success=yes
  comm="cupsd" exe="/usr/sbin/cupsd"
  subj=system_u:system_r:cupsd_t:s0
  key="print_job_created"

type=CUPS msg=audit(1736431380.123:4568):
  user=john@OFFICE.LOCAL printer=HP-Office-01 job=42 pages=24 action=created
```

**Timing:** 450ms (write 2.4MB to disk)

#### Step 9: Send Job to Physical Printer
```
cupsd → HP-Office-01 (10.0.140.10:9100)
  Protocol: JetDirect (raw TCP/9100)
  Direction: Server VLAN 120 → IoT VLAN 140 (ONE-WAY allowed)

Firewall rule:
  allow-print-server-to-iot
    Source: 10.0.120.30
    Destination: 10.0.140.0/24:9100
    Action: PASS
    Direction: ONE-WAY (no response traffic initiated by IoT)
```

**Timing:** 8 seconds (printer processing + printing)

#### Step 10: Completion and Logging
```
CUPS access log (/var/log/cups/access_log):
  10.0.130.20 - john@OFFICE.LOCAL [09/Jan/2026:14:23:00 +0000]
    "POST /printers/HP-Office-01 HTTP/1.1" 200 - - -

CUPS page log (/var/log/cups/page_log):
  HP-Office-01 john@OFFICE.LOCAL 42 [09/Jan/2026:14:23:08 +0000] 24 1 - localhost quarterly-report.pdf

Auditd completion:
  type=CUPS msg=audit(1736431388.456:4569):
    user=john@OFFICE.LOCAL printer=HP-Office-01 job=42 pages=24
    action=completed status=success
```

**Logs forwarded to monitoring01 via rsyslog (TCP/TLS):**
```
Jan 09 14:23:08 print-server01 cupsd[1234]: [Job 42] Job completed successfully
  → rsyslog → monitoring01:514 → Elasticsearch → indexed for 7-year retention
```

**Total Time:** ~9 seconds (mostly printer processing)

---

### Scenario 2: Unauthorized Cross-Department Print Attempt

**Context:**
- John (Accounting) attempts to print to `Canon-HR-01` (HR-only printer)
- Canon-HR-01 requires membership in `CN=Print-Users-HR` group
- John is NOT in this group

**Step-by-Step Flow:**

#### Step 1: Print Job Submission
```bash
# On laptop-john-01
$ lp -d Canon-HR-01 document.pdf
lp: Not authorized to print to Canon-HR-01
```

#### Step 2-4: Authentication Succeeds
(Same as Scenario 1 - Kerberos ticket valid, firewall allows IPP traffic)

#### Step 5: Authorization Check (FAILS)
```
CUPS policy check for printer "Canon-HR-01":
  <Policy hr-only>
    <Limit Send-Document>
      Require user @Print-Users-HR
      AuthType Negotiate
    </Limit>
  </Policy>

Authorization result:
  ✗ john is NOT member of @Print-Users-HR
  → DENY (HTTP 403 Forbidden)
```

**Response to client:**
```
HTTP/1.1 403 Forbidden
Content-Type: application/ipp
Date: Thu, 09 Jan 2026 14:25:00 GMT

status-code: client-error-forbidden
status-message: Not authorized to access this printer
```

**Auditd Log (Failed Attempt):**
```
type=CUPS msg=audit(1736431500.789:4580):
  user=john@OFFICE.LOCAL printer=Canon-HR-01 job=NONE
  action=denied reason=not_in_required_group result=403
```

**Alert Triggered:**
If multiple denied attempts (>3 in 5 minutes), Wazuh SIEM generates alert:
```
Rule 100110: Multiple unauthorized print attempts
  Severity: Medium
  User: john@OFFICE.LOCAL
  Target: Canon-HR-01 (HR printer)
  Action: Notify IT + generate incident ticket
```

**Timing:** ~50ms (fast rejection, no job spooling)

---

### Scenario 3: Print Quota Exceeded

**Context:**
- Sarah (Manager) has printed 995 pages this month
- Monthly quota: 1000 pages
- Attempts to print 24-page document

**Step-by-Step Flow:**

#### Step 1-5: Authentication and Authorization Succeed
(Sarah is in `Print-Users-General` group)

#### Step 6: Quota Check (FAILS)
```
CUPS quota plugin check:
  User: sarah@OFFICE.LOCAL
  Current usage: 995 pages
  Quota limit: 1000 pages/month
  Job size: 24 pages

  995 + 24 = 1019 > 1000 → DENY
```

**Response to client:**
```
HTTP/1.1 403 Forbidden
Content-Type: application/ipp

status-code: client-error-not-possible
status-message: Print quota exceeded (995/1000 pages used).
                Quota resets on 2026-02-01 or contact IT for increase.
```

**CUPS Error Log:**
```
E [09/Jan/2026:14:30:00 +0000] [Job 43] Quota exceeded for sarah@OFFICE.LOCAL
  (995/1000 pages, requested 24 pages)
```

**Auditd Log:**
```
type=CUPS msg=audit(1736431800.123:4590):
  user=sarah@OFFICE.LOCAL printer=HP-Office-01 job=NONE
  action=denied reason=quota_exceeded quota_used=995 quota_limit=1000
  requested_pages=24 result=403
```

**Timing:** ~40ms (rejected before spooling)

---

### Scenario 4: Print Job Privacy Protection

**Context:**
- Sarah submits confidential HR document to `Canon-HR-01`
- John attempts to view Sarah's print job status

**Step-by-Step Flow:**

#### Step 1: Sarah Submits Job
```bash
# On laptop-sarah-01
$ lp -d Canon-HR-01 employee-salaries.pdf
request id is Canon-HR-01-44 (1 file(s))
```

Job spooled successfully (Sarah is in `Print-Users-HR` group).

#### Step 2: John Attempts to View Job
```bash
# On laptop-john-01
$ lpstat -o Canon-HR-01-44
lpstat: Forbidden - not authorized to view this job
```

**CUPS Privacy Check:**
```
Request: GET /jobs/44
Authorization: john@OFFICE.LOCAL

CUPS policy:
  Job owner: sarah@OFFICE.LOCAL
  Requesting user: john@OFFICE.LOCAL

  Access rules:
    - Owner can view: YES (sarah only)
    - Print admins can view: YES (IT staff with @OFFICE.LOCAL\Print-Admins)
    - Other users can view: NO

  john ≠ sarah AND john NOT IN Print-Admins
  → DENY (HTTP 403)
```

**Auditd Log:**
```
type=CUPS msg=audit(1736432000.456:4600):
  user=john@OFFICE.LOCAL target_job=44 job_owner=sarah@OFFICE.LOCAL
  action=view_job result=denied reason=not_owner
```

**Alert (if suspicious pattern):**
If John attempts to view multiple other users' jobs, Wazuh SIEM triggers:
```
Rule 100120: Suspicious print job enumeration attempt
  Severity: Medium
  User: john@OFFICE.LOCAL
  Pattern: 5+ denied job view attempts in 2 minutes
  Action: Notify security team
```

---

## SELinux Policy Enforcement

### CUPS Daemon Confinement
```bash
# Check cupsd SELinux context
$ ps -eZ | grep cupsd
system_u:system_r:cupsd_t:s0    1234 ?        00:00:05 cupsd

# What can cupsd_t do?
$ sesearch -A -s cupsd_t -t cupsd_var_run_t -c file -p write
allow cupsd_t cupsd_var_run_t:file { create write ... };

# What can cupsd_t NOT do?
$ sesearch -A -s cupsd_t -t user_home_t -c file -p read
# (no results) → cupsd cannot read user home directories
```

**Key Confinements:**
1. **Spool Directory:** cupsd can write to `/var/spool/cups/` (type `cupsd_var_run_t`)
2. **Log Directory:** cupsd can write to `/var/log/cups/` (type `cupsd_log_t`)
3. **Config Files:** cupsd can read `/etc/cups/` (type `cupsd_etc_t`)
4. **Network Access:** cupsd can bind to 631/tcp (IPP) and connect to printers
5. **Blocked Access:** cupsd CANNOT access user home directories, system binaries, or other services

**Test Case: Attempt to Violate Policy**
```bash
# Attacker tries to modify cupsd to read /etc/shadow
# This would require cupsd_t to read shadow_t files

$ sesearch -A -s cupsd_t -t shadow_t -c file -p read
# (no results) → DENIED by SELinux

# If attacker somehow injects code into cupsd process:
# SELinux denies access:
type=AVC msg=audit(1736432200.789:4610): avc: denied
  { read } for pid=1234 comm="cupsd" name="shadow" dev="dm-0" ino=67890
  scontext=system_u:system_r:cupsd_t:s0
  tcontext=system_u:object_r:shadow_t:s0
  tclass=file permissive=0
```

---

## IoT VLAN Printer Isolation

### One-Way Communication Model
```
Print Server (VLAN 120) → Printers (VLAN 140)  ✓ ALLOWED
Printers (VLAN 140) → Print Server (VLAN 120)  ✗ BLOCKED
Printer A (VLAN 140) → Printer B (VLAN 140)    ✗ BLOCKED
Printers → Internet                             ✗ BLOCKED
```

**Firewall Rules (pfSense):**
```bash
# VLAN 140 (IoT) rules - DENY ALL by default
# Rule 1: Block all IoT-initiated traffic
pass in on $IoT_VLAN from any to any flags S/SA keep state label "BLOCK_IOT_OUTBOUND" block

# Rule 2: Allow print server to reach printers (JetDirect)
pass out on $IoT_VLAN proto tcp from 10.0.120.30 to 10.0.140.0/24 port 9100 keep state

# Rule 3: Allow print server SNMP queries (printer status)
pass out on $IoT_VLAN proto udp from 10.0.120.30 to 10.0.140.0/24 port 161 keep state

# Result: Printers can ONLY receive connections from print-server01
#         Printers CANNOT initiate connections anywhere
#         Printers CANNOT talk to each other
```

**Why This Matters:**
- **Compromised Printer:** If printer firmware is exploited, attacker cannot pivot to other systems
- **Lateral Movement:** Blocked - printers are isolated from each other
- **Data Exfiltration:** Blocked - printers have no internet access
- **C2 Communication:** Blocked - printers cannot initiate outbound connections

**Test Case: Attempt Printer-to-Printer Communication**
```bash
# On compromised HP-Office-01 (10.0.140.10)
# Attacker tries to scan Canon-HR-01 (10.0.140.11)
root@HP-Office-01# nmap 10.0.140.11
Starting Nmap...
Note: Host seems down. If it is really up, but blocking our ping probes, try -Pn
Nmap done: 1 IP address (0 hosts up) scanned in 3.02 seconds

# pfSense blocks and logs:
Jan 09 14:35:00 pfsense filterlog: BLOCK,140,10.0.140.10,10.0.140.11,tcp,23
  Rule: default-deny-iot
```

---

## Firewall Configuration

### Print Server Inbound Rules
```bash
# Zone: server (VLAN 120)
firewall-cmd --permanent --zone=server --add-service=ipp
firewall-cmd --permanent --zone=server --add-service=ipp-client

# Allow IPP from workstation VLANs only
firewall-cmd --permanent --zone=server --add-rich-rule='
  rule family="ipv4"
  source address="10.0.130.0/24"
  service name="ipp"
  accept'

firewall-cmd --permanent --zone=server --add-rich-rule='
  rule family="ipv4"
  source address="10.0.131.0/24"
  service name="ipp"
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

### Print Server Outbound Rules
```bash
# Allow connections to printers (IoT VLAN)
firewall-cmd --permanent --direct --add-rule ipv4 filter OUTPUT 0 \
  -d 10.0.140.0/24 -p tcp --dport 9100 -j ACCEPT

# Allow SNMP to printers (status queries)
firewall-cmd --permanent --direct --add-rule ipv4 filter OUTPUT 0 \
  -d 10.0.140.0/24 -p udp --dport 161 -j ACCEPT

# Allow Kerberos to domain controllers
firewall-cmd --permanent --direct --add-rule ipv4 filter OUTPUT 0 \
  -d 10.0.120.0/24 -p tcp --dport 88 -j ACCEPT

# Allow rsyslog to monitoring server
firewall-cmd --permanent --direct --add-rule ipv4 filter OUTPUT 0 \
  -d 10.0.120.40 -p tcp --dport 514 -j ACCEPT
```

---

## Auditd Rules

### Print Job Auditing
```bash
# /etc/audit/rules.d/cups.rules

# Watch CUPS spool directory
-w /var/spool/cups/ -p wa -k print_jobs

# Watch CUPS configuration changes
-w /etc/cups/cupsd.conf -p wa -k cups_config
-w /etc/cups/printers.conf -p wa -k cups_printers

# Watch print quota database
-w /var/lib/cups/quota.db -p wa -k print_quota

# Audit all cupsd execution
-a always,exit -F arch=b64 -S execve -F exe=/usr/sbin/cupsd -k cupsd_exec

# Audit print job syscalls
-a always,exit -F arch=b64 -S open -F dir=/var/spool/cups/ -F success=1 -k print_job_access

# Audit printer communication (network syscalls from cupsd)
-a always,exit -F arch=b64 -S connect -F exe=/usr/sbin/cupsd -k printer_network
```

### Example Audit Log Output
```
# Print job created
type=SYSCALL msg=audit(1736431380.123:4567): arch=c000003e syscall=2 success=yes exit=3
  a0=7ffda1234560 a1=80042 a2=1b6 a3=0 items=2 ppid=1 pid=1234 auid=4294967295 uid=0 gid=0
  euid=0 suid=0 fsuid=0 egid=0 sgid=0 fsgid=0 tty=(none) ses=4294967295
  comm="cupsd" exe="/usr/sbin/cupsd"
  subj=system_u:system_r:cupsd_t:s0 key="print_jobs"

# User john printed document
type=USER_CMD msg=audit(1736431380.123:4568): pid=5678 uid=1001 auid=1001 ses=12
  subj=unconfined_u:unconfined_r:unconfined_t:s0-s0:c0.c1023
  msg='user=john@OFFICE.LOCAL printer=HP-Office-01 job=42 pages=24
       file="quarterly-report.pdf" cmd=print terminal=pts/1 res=success'
```

---

## CUPS Configuration

### Main Configuration (/etc/cups/cupsd.conf)
```apache
# Listen on all interfaces (firewalld handles access control)
Listen 631

# AD Authentication
DefaultAuthType Negotiate

# Kerberos configuration
ServerName print-server01.office.local
Krb5Keytab /etc/cups/cups.keytab

# Logging
LogLevel info
MaxLogSize 10m
AccessLogLevel actions
PageLogFormat %p %u %j %T %P %a %{job-billing} %{job-originating-host-name} %{job-name}

# Job privacy
<Policy default>
  <Limit All>
    Require valid-user
    Order deny,allow
  </Limit>

  <Limit Send-Document Send-URI Hold-Job Release-Job Restart-Job Purge-Jobs
         Set-Job-Attributes Create-Job-Subscription Renew-Subscription
         Cancel-Subscription Get-Subscription-Attributes Get-Subscriptions>
    Require user @OWNER @Print-Admins
    Order deny,allow
  </Limit>
</Policy>

# HR printer - restricted access
<Policy hr-only>
  <Limit All>
    AuthType Negotiate
    Require user @Print-Users-HR @Print-Admins
    Order deny,allow
  </Limit>
</Policy>

# Finance printer - restricted access
<Policy finance-only>
  <Limit All>
    AuthType Negotiate
    Require user @Print-Users-Finance @Print-Admins
    Order deny,allow
  </Limit>
</Policy>
```

### Printer Definitions (/etc/cups/printers.conf)
```apache
<Printer HP-Office-01>
  UUID urn:uuid:12345678-1234-1234-1234-123456789abc
  Info General Office Printer
  Location Main Office - 1st Floor
  DeviceURI socket://10.0.140.10:9100
  State Idle
  StateTime 1736431000
  Accepting Yes
  Shared No
  JobSheets none none
  QuotaPeriod 2678400  # 31 days (monthly)
  PageLimit 1000       # 1000 pages/month default
  KLimit 0
  ErrorPolicy retry-job
  OpPolicy default
</Printer>

<Printer Canon-HR-01>
  UUID urn:uuid:abcdef12-3456-7890-abcd-ef1234567890
  Info HR Department Printer
  Location HR Office - 2nd Floor
  DeviceURI socket://10.0.140.11:9100
  State Idle
  StateTime 1736431000
  Accepting Yes
  Shared No
  JobSheets none none
  QuotaPeriod 2678400
  PageLimit 500        # Lower quota for HR-only printer
  KLimit 0
  ErrorPolicy retry-job
  OpPolicy hr-only     # RESTRICTED ACCESS
</Printer>

<Printer Xerox-Fin-01>
  UUID urn:uuid:98765432-fedc-ba09-8765-432109876543
  Info Finance Department Printer
  Location Finance Office - 3rd Floor
  DeviceURI socket://10.0.140.12:9100
  State Idle
  StateTime 1736431000
  Accepting Yes
  Shared No
  JobSheets confidential confidential  # Header/footer on all pages
  QuotaPeriod 2678400
  PageLimit 2000       # Higher quota for finance reports
  KLimit 0
  ErrorPolicy retry-job
  OpPolicy finance-only  # RESTRICTED ACCESS
</Printer>
```

### Quota Configuration (/etc/cups/quota.conf)
```ini
# CUPS quota configuration for pykota or similar plugin

# Default quota for all users
DefaultQuota: 1000 pages/month

# Group-based overrides
Group:Print-Users-Finance:2000
Group:Print-Users-IT:5000
Group:Print-Admins:unlimited

# User-specific overrides (managers)
User:sarah@OFFICE.LOCAL:2000
User:michael@OFFICE.LOCAL:2000

# Quota warning thresholds
WarnPercent: 90  # Warn at 90% usage
WarnEmail: it-support@office.local

# Quota reset schedule
ResetSchedule: monthly  # Reset on 1st of each month at 00:00
ResetDay: 1

# Enforcement
EnforcementMode: hard  # Hard limit (soft = warn but allow)
GracePages: 0          # No grace pages after quota exceeded
```

---

## Rsyslog Configuration

### Forward CUPS Logs to Monitoring Server
```bash
# /etc/rsyslog.d/cups-forward.conf

# Load modules
module(load="imfile" PollingInterval="10")

# CUPS access log
input(type="imfile"
      File="/var/log/cups/access_log"
      Tag="cups-access"
      Severity="info"
      Facility="local4"
      reopenOnTruncate="on")

# CUPS error log
input(type="imfile"
      File="/var/log/cups/error_log"
      Tag="cups-error"
      Severity="error"
      Facility="local4"
      reopenOnTruncate="on")

# CUPS page log (print job completion)
input(type="imfile"
      File="/var/log/cups/page_log"
      Tag="cups-page"
      Severity="info"
      Facility="local4"
      reopenOnTruncate="on")

# Forward to monitoring server (TLS encrypted)
action(type="omfwd"
       target="10.0.120.40"
       port="514"
       protocol="tcp"
       StreamDriver="gtls"
       StreamDriverMode="1"
       StreamDriverAuthMode="x509/name"
       StreamDriverPermittedPeers="monitoring01.office.local")
```

---

## Test Cases for Validation

### Test 1: Successful Print Job
```bash
# Preconditions:
# - John authenticated to laptop-john-01
# - John is member of Print-Users-General
# - John has 100 pages used (900 remaining quota)

# Test:
$ lp -d HP-Office-01 test-document.pdf
request id is HP-Office-01-100 (1 file(s))

# Expected:
# ✓ HTTP 200 OK response
# ✓ Job spooled to /var/spool/cups/
# ✓ Auditd log entry created
# ✓ CUPS page log shows job completion
# ✓ Physical printout produced
# ✓ Quota updated: 100 → 105 pages (assuming 5-page doc)
# ✓ Logs forwarded to monitoring01

# Validation:
$ lpstat -o HP-Office-01-100
HP-Office-01-100  john  1024  Thu 09 Jan 2026 02:23:00 PM UTC

# On print-server01:
$ journalctl -u cups -n 20 | grep "Job 100"
Jan 09 14:23:05 print-server01 cupsd[1234]: [Job 100] Job completed successfully

# On monitoring01 (Kibana):
# Search: cups-page AND job:100
# Result: 1 document with full job details
```

### Test 2: Cross-Department Print Denial
```bash
# Preconditions:
# - John is NOT member of Print-Users-HR
# - Canon-HR-01 requires Print-Users-HR membership

# Test:
$ lp -d Canon-HR-01 document.pdf
lp: Not authorized to print to Canon-HR-01

# Expected:
# ✗ HTTP 403 Forbidden
# ✗ No job created
# ✓ Auditd denial log entry
# ✓ CUPS error log shows authorization failure
# ✓ Alert generated if >3 attempts in 5 minutes

# Validation:
# On print-server01:
$ journalctl -u cups -n 20 | grep "Not authorized"
Jan 09 14:25:00 print-server01 cupsd[1234]: [Client 10.0.130.20]
  User john@OFFICE.LOCAL not authorized to print to Canon-HR-01

$ ausearch -k print_jobs -i | grep denied
type=CUPS ... action=denied user=john@OFFICE.LOCAL printer=Canon-HR-01
```

### Test 3: Print Quota Exceeded
```bash
# Preconditions:
# - Sarah has 998 pages used (2 remaining)
# - Monthly quota: 1000 pages
# - Attempting to print 10-page document

# Test:
$ lp -d HP-Office-01 large-document.pdf
lp: Print quota exceeded (998/1000 pages used). Quota resets on 2026-02-01.

# Expected:
# ✗ HTTP 403 Forbidden
# ✗ No job created
# ✓ Quota denial logged
# ✓ User notified of quota reset date
# ✓ Email sent to user with quota summary

# Validation:
$ journalctl -u cups -n 20 | grep "Quota exceeded"
Jan 09 14:30:00 print-server01 cupsd[1234]: [Job 101]
  Quota exceeded for sarah@OFFICE.LOCAL (998/1000, requested 10)
```

### Test 4: Printer Isolation (IoT VLAN)
```bash
# Preconditions:
# - Attacker has shell on HP-Office-01 (10.0.140.10)
# - Attempting lateral movement to other printers

# Test (on compromised printer):
# nmap 10.0.140.11  # Scan Canon-HR-01
# curl http://10.0.140.11  # Try to access web interface
# ping 8.8.8.8  # Try internet access

# Expected:
# ✗ All outbound connections BLOCKED by pfSense
# ✓ pfSense logs all blocked attempts
# ✓ Alert generated for suspicious IoT VLAN activity

# Validation:
# On pfSense:
Status > System Logs > Firewall
  Filter: source=10.0.140.10
  Result: Multiple BLOCK entries for outbound traffic

# On monitoring01 (Wazuh):
Rule 100130: IoT device attempting outbound connection
  Severity: High
  Source: HP-Office-01 (10.0.140.10)
  Action: Alert security team + isolate device
```

### Test 5: SELinux Confinement Test
```bash
# Preconditions:
# - Attacker injected code into cupsd process
# - Attempting to read /etc/shadow

# Test (simulated with custom SELinux test):
$ runcon system_u:system_r:cupsd_t:s0 cat /etc/shadow
cat: /etc/shadow: Permission denied

# Expected:
# ✗ Access DENIED by SELinux
# ✓ AVC denial logged to audit.log

# Validation:
$ ausearch -m AVC -c cupsd
type=AVC msg=audit(1736432200.789:4610): avc: denied { read } for pid=1234
  comm="cupsd" name="shadow" scontext=system_u:system_r:cupsd_t:s0
  tcontext=system_u:object_r:shadow_t:s0 tclass=file permissive=0
```

### Test 6: Job Privacy Protection
```bash
# Preconditions:
# - Sarah submitted job 105 to Canon-HR-01
# - John (different user) tries to view job details

# Test (as John):
$ lpstat -o Canon-HR-01-105
lpstat: Forbidden - not authorized to view this job

# Expected:
# ✗ HTTP 403 Forbidden (job owner mismatch)
# ✓ Privacy denial logged
# ✓ Alert if pattern of unauthorized job viewing detected

# Test (as IT admin with Print-Admins group):
$ lpstat -o Canon-HR-01-105
Canon-HR-01-105  sarah@OFFICE.LOCAL  5120  Thu 09 Jan 2026 02:35:00 PM UTC

# Expected:
# ✓ HTTP 200 OK (admin override)
# ✓ Admin access logged for audit trail
```

---

## Compliance Benefits

### SOX (Sarbanes-Oxley) Compliance
**Requirement:** Audit trail of all access to financial data

**Implementation:**
- **Print Job Logging:** All print jobs to `Xerox-Fin-01` (Finance printer) logged with:
  - User identity (john@OFFICE.LOCAL)
  - Timestamp (2026-01-09T14:23:00Z)
  - Document name (quarterly-report.pdf)
  - Page count (24 pages)
  - Completion status (success/failure)

- **7-Year Retention:** All logs forwarded to monitoring01, retained in Elasticsearch for 7 years (SOX requirement)

- **Access Control:** Finance printer restricted to `Print-Users-Finance` AD group (separation of duties)

- **Immutable Logs:** Audit logs protected with `chattr +a` (append-only, cannot be tampered)

**Compliance Evidence:**
```bash
# Query all Finance printer access for 2026 Q1 audit
# On monitoring01 (Elasticsearch):
GET /cups-logs-*/_search
{
  "query": {
    "bool": {
      "must": [
        {"match": {"printer": "Xerox-Fin-01"}},
        {"range": {"@timestamp": {"gte": "2026-01-01", "lte": "2026-03-31"}}}
      ]
    }
  }
}

# Result: Complete audit trail of all financial document printing
```

---

### GDPR (General Data Protection Regulation) Compliance
**Requirement:** Privacy by design, data minimization, access logging

**Implementation:**
- **Job Privacy:** Only job owner + print admins can view job details (Article 32 - Security of processing)

- **Minimal Data Collection:** Print logs contain only necessary information:
  - User identity (legitimate interest for security)
  - Timestamp (required for audit)
  - Document name (required for incident investigation)
  - NO document content stored on server (privacy by design)

- **Access Logging:** All detailed log access by IT staff logged with auditd (Article 30 - Records of processing)

- **Data Retention:** Print logs retained only as long as necessary (7 years for SOX, then automatically purged)

- **Right to Erasure:** Automated script to purge specific user's print history upon GDPR request:
```bash
# /usr/local/bin/gdpr-purge-print-logs.sh
#!/bin/bash
USER_TO_PURGE="$1"

# Remove from CUPS logs
sed -i "/$USER_TO_PURGE/d" /var/log/cups/access_log
sed -i "/$USER_TO_PURGE/d" /var/log/cups/page_log

# Remove from Elasticsearch (monitoring01)
curl -X POST "monitoring01:9200/cups-logs-*/_delete_by_query" -H 'Content-Type: application/json' -d'
{
  "query": {
    "match": {"user": "'"$USER_TO_PURGE"'"}
  }
}'

echo "Print logs for $USER_TO_PURGE purged per GDPR Article 17 request"
```

**Compliance Evidence:**
- Privacy Impact Assessment (PIA) documents minimal data collection
- Access logs demonstrate auditability
- Retention policy documented in data processing records

---

### HIPAA (Health Insurance Portability and Accountability Act) Compliance
**Requirement:** PHI (Protected Health Information) protection, audit trails

**Implementation:**
- **Encrypted Transmission:** IPP over TLS 1.3 prevents eavesdropping on print jobs (§164.312(e)(1))

- **Access Controls:** HR printer (Canon-HR-01) restricted to HR staff only (§164.308(a)(4))
  - HR department may handle employee health benefits (PHI)
  - Only `Print-Users-HR` group can print to this device

- **Audit Controls:** All HR printer access logged (§164.312(b))
  - Who accessed what, when
  - Failed access attempts logged
  - Audit logs retained and protected from tampering

- **Device Isolation:** Printers on isolated IoT VLAN (§164.308(a)(3)(i))
  - Compromised printer cannot exfiltrate PHI
  - No lateral movement to other systems

**Compliance Evidence:**
```bash
# Query all HR printer access (potential PHI) for HIPAA audit
GET /cups-logs-*/_search
{
  "query": {
    "bool": {
      "must": [
        {"match": {"printer": "Canon-HR-01"}},
        {"range": {"@timestamp": {"gte": "2025-01-01", "lte": "2025-12-31"}}}
      ]
    }
  },
  "sort": [{"@timestamp": "asc"}]
}

# Result: Complete audit trail of all HR printer access (HIPAA §164.312(b) requirement)
```

---

## Wazuh SIEM Rules for Print Security

### Rule 1: Brute Force Print Attempts
```xml
<!-- /var/ossec/etc/rules/local_rules.xml on monitoring01 -->
<group name="cups,">
  <rule id="100110" level="10">
    <if_sid>0</if_sid>
    <match>action=denied</match>
    <frequency>3</frequency>
    <timeframe>300</timeframe>
    <same_source_ip />
    <description>Multiple unauthorized print attempts detected (possible reconnaissance)</description>
    <mitre>
      <id>T1087</id>  <!-- Account Discovery -->
    </mitre>
  </rule>
</group>
```

**Trigger Condition:** 3+ denied print attempts from same IP in 5 minutes
**Action:** Alert IT team + log for investigation
**Example:** John tries to print to 3 different restricted printers

---

### Rule 2: Quota Manipulation Attempt
```xml
<rule id="100111" level="12">
  <if_sid>0</if_sid>
  <match>/var/lib/cups/quota.db</match>
  <match>SYSCALL</match>
  <field name="syscall">2|257</field>  <!-- open/openat -->
  <field name="success">yes</field>
  <description>Unauthorized modification of print quota database detected</description>
  <mitre>
    <id>T1565.001</id>  <!-- Data Manipulation: Stored Data Object -->
  </mitre>
</rule>
```

**Trigger Condition:** Direct write to quota database (should only be modified by cupsd)
**Action:** Critical alert + kill cupsd process + investigate
**Example:** Attacker tries to increase their quota by editing database

---

### Rule 3: Suspicious Job Enumeration
```xml
<rule id="100120" level="8">
  <if_sid>0</if_sid>
  <match>action=view_job result=denied</match>
  <frequency>5</frequency>
  <timeframe>120</timeframe>
  <same_source_user />
  <description>User attempting to enumerate other users' print jobs</description>
  <mitre>
    <id>T1087</id>  <!-- Account Discovery -->
  </mitre>
</rule>
```

**Trigger Condition:** 5+ denied job view attempts by same user in 2 minutes
**Action:** Alert security team + log user activity for investigation
**Example:** John tries to view Sarah's, Michael's, and Lisa's print jobs

---

### Rule 4: IoT Printer Outbound Connection
```xml
<rule id="100130" level="15">
  <if_sid>0</if_sid>
  <match>BLOCK.*10.0.140.</match>  <!-- IoT VLAN source -->
  <match>OUTPUT</match>
  <description>IoT printer attempting unauthorized outbound connection (possible compromise)</description>
  <mitre>
    <id>T1071</id>  <!-- Application Layer Protocol (C2) -->
  </mitre>
</rule>
```

**Trigger Condition:** Any outbound connection attempt from IoT VLAN (10.0.140.0/24)
**Action:** Critical alert + isolate printer + investigate
**Example:** Compromised printer tries to connect to C2 server

---

### Rule 5: Mass Print Job Submission
```xml
<rule id="100140" level="10">
  <if_sid>0</if_sid>
  <match>action=created</match>
  <frequency>20</frequency>
  <timeframe>60</timeframe>
  <same_source_user />
  <description>Unusual mass print job submission detected (possible data exfiltration)</description>
  <mitre>
    <id>T1020</id>  <!-- Automated Exfiltration -->
  </mitre>
</rule>
```

**Trigger Condition:** 20+ print jobs submitted by same user in 1 minute
**Action:** Alert security team + investigate (possible data theft via printing)
**Example:** Malicious insider rapidly printing confidential documents before termination

---

## Summary

This document demonstrates comprehensive print security with:

1. **Multi-Layer Authentication:**
   - Kerberos (AD integration)
   - TLS encryption (IPP over HTTPS)
   - AD group-based authorization

2. **Defense in Depth:**
   - Firewall (pfSense + firewalld): Network segmentation
   - SELinux: Process confinement (cupsd_t domain)
   - CUPS Policy: Job privacy and access control
   - Print Quotas: Resource management and abuse prevention
   - Auditd: Comprehensive logging

3. **Network Isolation:**
   - Printers on isolated IoT VLAN (140)
   - One-way communication (server → printers only)
   - No lateral movement between printers
   - No internet access for printers

4. **Privacy Protection:**
   - Job owner + admin-only access to job details
   - No document content stored on server
   - Encrypted transmission (TLS 1.3)
   - GDPR-compliant data minimization

5. **Compliance:**
   - SOX: 7-year audit trail, financial data segregation
   - GDPR: Privacy by design, right to erasure
   - HIPAA: Encrypted transmission, access controls, audit logs

6. **Threat Detection:**
   - Wazuh SIEM rules for anomaly detection
   - Automated response to suspicious activity
   - Log correlation across infrastructure
   - Real-time alerting

**Total Security Layers for Print Job:** 7
1. pfSense firewall (VLAN isolation)
2. firewalld (host-based firewall)
3. Kerberos authentication
4. CUPS policy (AD group authorization)
5. Print quota enforcement
6. SELinux MAC (cupsd_t confinement)
7. Auditd logging + SIEM monitoring

**Key Insight:** Even if attacker compromises a printer (IoT VLAN), they cannot pivot to other systems due to strict network isolation. The print server acts as a security boundary, mediating all access between workstations and printers.

---

**Document Version:** 1.0
**Last Updated:** 2026-01-10
**Author:** IT Security Team
**Next Review:** 2026-07-10 (6 months)
