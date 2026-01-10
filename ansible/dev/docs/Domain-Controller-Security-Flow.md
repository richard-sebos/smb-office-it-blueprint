# Domain Controller Security Flow
## dc01 and dc02 - Ubuntu with Samba AD DC

---

## Use Case: Active Directory Domain Controllers

**Servers:**
- **dc01** (10.0.120.10, VLAN 120) - Primary DC
- **dc02** (10.0.120.11, VLAN 120) - Secondary DC (replication)

**Purpose:**
- Authentication (Kerberos, LDAP)
- Authorization (AD groups, GPO)
- DNS (internal domain resolution)
- Domain replication (multi-master)

**Risk Level:** CRITICAL (compromise = full domain compromise)

---

## Architecture Overview

```
┌─────────────────────────────────────────────────────────────────┐
│                 DOMAIN CONTROLLER (dc01)                         │
│                  Ubuntu 24.04 LTS Server                         │
│                  10.0.120.10 (VLAN 120 - Servers)                │
│                                                                   │
│  Services Running:                                               │
│  ├─ Samba AD DC (Active Directory)                              │
│  ├─ Kerberos KDC (Authentication)                               │
│  ├─ LDAP (Directory queries)                                    │
│  ├─ DNS (Internal resolution for corp.company.local)            │
│  ├─ NTP (Time synchronization - critical for Kerberos)          │
│  └─ Samba replication (to dc02)                                 │
│                                                                   │
│  Security Layers:                                                │
│  ├─ UFW Firewall (strict port allowlist)                        │
│  ├─ AppArmor (MAC - Samba confinement)                          │
│  ├─ Fail2ban (brute force protection)                           │
│  ├─ Auditd (comprehensive logging)                              │
│  ├─ SSH key-only (password auth disabled)                       │
│  └─ Automated security updates                                  │
│                                                                   │
└────────────────────────────┬──────────────────────────────────┘
                             │
                             │ Replication (DRS)
                             ↓
┌─────────────────────────────────────────────────────────────────┐
│                 DOMAIN CONTROLLER (dc02)                         │
│                  Ubuntu 24.04 LTS Server                         │
│                  10.0.120.11 (VLAN 120 - Servers)                │
│                  (Same services and security as dc01)            │
└──────────────────────────────────────────────────────────────────┘
```

---

## Security Requirements

| Requirement | Implementation | Why |
|-------------|----------------|-----|
| **No Direct Login** | SSH key-only, from ansible-ctrl only | Minimize attack surface |
| **Service Isolation** | AppArmor profiles for Samba | Contain compromise |
| **Firewall Strictness** | UFW allow only required ports | Default deny |
| **Brute Force Protection** | Fail2ban on SSH, Kerberos, LDAP | Block automated attacks |
| **Time Sync Critical** | Chrony NTP (Kerberos requires ±5 min) | Prevent auth failures |
| **Replication Security** | Encrypted DRS, mutual auth | Protect domain data |
| **Audit Everything** | Auditd on all auth, admin actions | Detect compromise |
| **Read-Only Root** | Considered, but not implemented (Samba needs writes) | Would prevent some attacks |
| **Backup Encryption** | DC backups encrypted at rest | Offline attack protection |

---

## Security Flow Trace: Authentication Request

### **Scenario 1: User Login (Sarah logs into ws-employee-05)**

#### User Perspective (Already traced in workstation docs)
```
Sarah enters credentials on ws-employee-05:
  Username: sarah@corp.company.local
  Password: [her password]
       ↓
GDM → PAM → SSSD → dc01
```

#### Domain Controller Perspective (NEW - This Document)

```
[8:00:15 AM] dc01 receives authentication request

Samba AD DC Process:
  ├─ Listener: 0.0.0.0:389 (LDAP) and 0.0.0.0:88 (Kerberos)
  ├─ Receives connection from: 10.0.130.35 (ws-employee-05)
  └─ Protocol: Kerberos (port 88)
       ↓
Network Layer (Firewall):
  ├─ UFW rule check:
  │   Source: 10.0.130.35 (VLAN 130 - Workstations)
  │   Destination: 10.0.120.10:88 (dc01 Kerberos)
  │   Rule: VLAN 130 → VLAN 120:88 = PERMIT
  └─ Packet allowed, forwarded to Samba
       ↓
Samba Kerberos KDC:
  ├─ Process: /usr/sbin/samba (Kerberos KDC component)
  ├─ Request type: AS-REQ (Authentication Service Request)
  ├─ Principal: sarah@CORP.COMPANY.LOCAL
  ├─ Client IP: 10.0.130.35
       ↓
AppArmor MAC Check:
  ├─ Profile: /usr/sbin/samba (enforcing mode)
  ├─ Allowed operations:
  │   ✓ Read /var/lib/samba/private/sam.ldb (user database)
  │   ✓ Read /var/lib/samba/private/secrets.ldb (Kerberos keys)
  │   ✓ Write /var/log/samba/ (logging)
  │   ✗ Read /etc/shadow (blocked by AppArmor)
  │   ✗ Write /etc/passwd (blocked by AppArmor)
  └─ Operation: Read sam.ldb (allowed)
       ↓
LDB Database Query:
  ├─ Database: /var/lib/samba/private/sam.ldb
  ├─ Query: SELECT * FROM users WHERE sAMAccountName='sarah'
  ├─ Result found:
  │   DN: CN=Sarah Johnson,CN=Users,DC=corp,DC=company,DC=local
  │   sAMAccountName: sarah
  │   userPrincipalName: sarah@corp.company.local
  │   userAccountControl: 512 (NORMAL_ACCOUNT, enabled)
  │   memberOf: CN=Employees,CN=Users,DC=corp,DC=company,DC=local
  │   pwdLastSet: 133484736000000000 (2026-01-02 09:00:00)
  └─ Account status: ENABLED
       ↓
Password Verification:
  ├─ Password hash stored in: supplementalCredentials attribute
  ├─ Hash type: NT hash (MD4 of Unicode password)
  ├─ Client provided: Kerberos pre-authentication data
  ├─ Decrypt using password hash
  └─ Match: SUCCESS (password correct)
       ↓
Kerberos Ticket Issuance:
  ├─ Generate TGT (Ticket Granting Ticket)
  │   ├─ Principal: sarah@CORP.COMPANY.LOCAL
  │   ├─ Valid from: 2026-01-09 08:00:15
  │   ├─ Valid until: 2026-01-09 18:00:15 (10 hours)
  │   ├─ Renewable until: 2026-01-16 08:00:15 (7 days)
  │   └─ Encryption: AES256-CTS-HMAC-SHA1-96
  ├─ Sign with KDC key (krbtgt account)
  └─ Return to client: AS-REP (Authentication Service Reply)
       ↓
Logging and Audit:
  ├─ Samba log (/var/log/samba/log.samba):
  │   [2026/01/09 08:00:15, 3] ../source4/kdc/kdc-server.c:123
  │     AS-REQ from 10.0.130.35 for sarah@CORP.COMPANY.LOCAL
  │   [2026/01/09 08:00:15, 3] ../source4/kdc/kdc-server.c:456
  │     AS-REP issued for sarah@CORP.COMPANY.LOCAL (valid 10h)
  │
  └─ Auditd log:
      type=USER_AUTH msg=audit(1704790815.123:1000): pid=2345
        uid=0 auid=4294967295 ses=4294967295
        msg='op=kerberos-auth acct="sarah@CORP.COMPANY.LOCAL"
        exe="/usr/sbin/samba" hostname=? addr=10.0.130.35
        terminal=? res=success' key="dc_kerberos_auth"
       ↓
Fail2ban Monitor:
  ├─ Monitors: /var/log/samba/log.samba
  ├─ Pattern: Failed authentication attempts
  ├─ This auth: SUCCESS (no action)
  └─ Counter reset for sarah@corp.company.local from 10.0.130.35
       ↓
Response sent to client (ws-employee-05)
  └─ Sarah's workstation receives TGT, login proceeds
```

**Security Layers Demonstrated:**
1. **Firewall** - Only allowed ports accessible
2. **AppArmor** - Samba can only access specific files
3. **Authentication** - Password verified against AD database
4. **Authorization** - Group membership retrieved for access control
5. **Audit** - All auth requests logged
6. **Fail2ban** - Brute force protection (monitors for failed attempts)

---

### **Scenario 2: Failed Login (Brute Force Attack)**

```
[2:00:00 AM] Attacker attempts brute force from external IP

Attacker sends authentication attempts:
  Attempt 1: sarah@corp.company.local / password123
  Attempt 2: sarah@corp.company.local / Password123
  Attempt 3: sarah@corp.company.local / Sarah2024
  [continues...]
       ↓
dc01 receives requests:
  ├─ Source: 73.25.145.88 (external IP, via VPN or exposed port)
  ├─ Destination: 10.0.120.10:88 (Kerberos)
  └─ Rapid succession (10 attempts in 30 seconds)
       ↓
Attempt 1:
  Samba Kerberos: Password verification FAILED
  Log: [2026/01/09 02:00:05] AS-REQ FAILED for sarah from 73.25.145.88 (wrong password)
       ↓
Attempt 2:
  Samba Kerberos: Password verification FAILED
  Log: [2026/01/09 02:00:07] AS-REQ FAILED for sarah from 73.25.145.88 (wrong password)
       ↓
Attempt 3:
  Samba Kerberos: Password verification FAILED
  Log: [2026/01/09 02:00:09] AS-REQ FAILED for sarah from 73.25.145.88 (wrong password)
       ↓
Fail2ban Detection:
  ├─ Monitors: /var/log/samba/log.samba
  ├─ Pattern: AS-REQ FAILED.*from 73.25.145.88
  ├─ Count: 3 failures in 60 seconds
  ├─ Threshold: 3 failures = BAN
  └─ Action: Block IP 73.25.145.88 at firewall
       ↓
Fail2ban executes:
  $ ufw insert 1 deny from 73.25.145.88 to any
       ↓
Attempt 4 (and all subsequent):
  Firewall: Packet from 73.25.145.88 DROPPED (banned)
  Attacker sees: Connection timeout (no response)
       ↓
Monitoring Alert (HIGH SEVERITY):
  [02:00:10 AM] CRITICAL: Brute force attack detected
    Target: sarah@corp.company.local
    Source: 73.25.145.88 (External IP, Geolocation: CN)
    Failed attempts: 3 (in 10 seconds)
    Action: IP BANNED for 1 hour

    AUTOMATIC ACTIONS TAKEN:
      ✓ Source IP blocked at firewall
      ✓ Alert sent to IT Security
      ✓ Account sarah@corp.company.local locked (3+ failures)

    RECOMMENDATIONS:
      ⚠ Contact Sarah to verify legitimate access attempts
      ⚠ Force password reset if compromise suspected
      ⚠ Review VPN access logs (how did external IP reach DC?)
      ⚠ Check for other accounts targeted from same IP

    Email: IT Security, Sarah (mobile alert)
    SMS: On-call security engineer
```

**Auditd Log:**
```
type=USER_ERR msg=audit(1704762005.123:2000): pid=2345 uid=0
  msg='op=kerberos-auth acct="sarah@CORP.COMPANY.LOCAL"
  exe="/usr/sbin/samba" addr=73.25.145.88 res=failed'
  key="dc_auth_failure"

type=USER_ERR msg=audit(1704762007.456:2001): pid=2345 uid=0
  msg='op=kerberos-auth acct="sarah@CORP.COMPANY.LOCAL"
  exe="/usr/sbin/samba" addr=73.25.145.88 res=failed'
  key="dc_auth_failure"

type=USER_ERR msg=audit(1704762009.789:2002): pid=2345 uid=0
  msg='op=kerberos-auth acct="sarah@CORP.COMPANY.LOCAL"
  exe="/usr/sbin/samba" addr=73.25.145.88 res=failed'
  key="dc_auth_failure"

type=SERVICE_START msg=audit(1704762010.123:2003): pid=3456
  uid=0 msg='op=fail2ban-ban acct="fail2ban"
  exe="/usr/bin/fail2ban-client" addr=73.25.145.88
  action="ban" duration=3600' key="fail2ban_action"
```

---

## Security Flow Trace: Domain Replication (dc01 → dc02)

### **Scenario 3: User Sarah Added to Finance Group**

```
[10:00 AM] IT admin (mike-admin) adds Sarah to Finance group on dc01

Active Directory Change (dc01):
  ├─ Tool: samba-tool group addmembers
  ├─ Command: samba-tool group addmembers Finance sarah
  ├─ Executed by: mike-admin@corp.company.local
  ├─ Source: laptop-mike-01 (10.0.131.30)
       ↓
dc01 LDB Database Update:
  ├─ Database: /var/lib/samba/private/sam.ldb
  ├─ Modify operation:
  │   DN: CN=Finance,CN=Users,DC=corp,DC=company,DC=local
  │   Attribute: member
  │   Action: ADD
  │   Value: CN=Sarah Johnson,CN=Users,DC=corp,DC=company,DC=local
  ├─ Update: SUCCESS
  └─ USN (Update Sequence Number): 12345 → 12346
       ↓
Samba Replication Trigger:
  ├─ Change detected (USN incremented)
  ├─ Replication needed to: dc02
  ├─ Notification sent to dc02: "Changes available, USN 12346"
       ↓
dc02 Initiates Replication Request:
  ├─ dc02 queries dc01: "Give me changes since USN 12345"
  ├─ Protocol: DRS (Directory Replication Service)
  ├─ Connection: dc02 (10.0.120.11) → dc01 (10.0.120.10:389)
  ├─ Authentication: Mutual Kerberos (dc02$ computer account)
       ↓
Firewall Check (dc01):
  ├─ Source: 10.0.120.11 (dc02, VLAN 120)
  ├─ Destination: 10.0.120.10:389 (dc01 LDAP)
  ├─ Rule: VLAN 120 → VLAN 120:389 = PERMIT (server-to-server)
  └─ Allowed
       ↓
dc01 Sends Replication Data:
  ├─ Changes since USN 12345:
  │   Object: CN=Finance,CN=Users,DC=corp,DC=company,DC=local
  │   Attribute: member
  │   Change: ADDED CN=Sarah Johnson,...
  │   USN: 12346
  ├─ Encryption: Kerberos-encrypted LDAP session
  └─ Transmitted to dc02
       ↓
dc02 Receives and Applies Change:
  ├─ Database: /var/lib/samba/private/sam.ldb on dc02
  ├─ Apply change: Add Sarah to Finance group
  ├─ Update USN: 12346
  ├─ Replication: SUCCESS
  └─ Log: Replication completed, 1 object updated
       ↓
Verification:
  Query dc01: samba-tool group listmembers Finance
    Output: sarah

  Query dc02: samba-tool group listmembers Finance
    Output: sarah

  ✓ Both DCs now have Sarah in Finance group
       ↓
Audit Logs (Both DCs):
  dc01:
    type=USER_MGMT msg=audit(1704790800.123:3000): pid=4567
      uid=1605000 auid=1604000 msg='op=group-add-member
      group="Finance" member="sarah@corp.company.local"
      exe="/usr/bin/samba-tool" hostname=laptop-mike-01
      res=success' key="dc_group_modification"

  dc02:
    type=DRS_REPLICATION msg=audit(1704790805.456:3001): pid=5678
      msg='op=replication source=dc01.corp.company.local
      object="CN=Finance,CN=Users,DC=corp,DC=company,DC=local"
      usn_old=12345 usn_new=12346 res=success'
      key="dc_replication"
```

**Replication Security:**
- ✅ **Mutual authentication** (both DCs verify each other via Kerberos)
- ✅ **Encrypted transport** (Kerberos-encrypted LDAP)
- ✅ **Integrity checking** (USN tracking prevents missing changes)
- ✅ **Conflict resolution** (multi-master with timestamp-based resolution)
- ✅ **Audit trail** (all changes logged on both DCs)

---

## Security Flow Trace: DNS Resolution

### **Scenario 4: Workstation Queries DNS for file-server01**

```
[8:30 AM] User's application needs to resolve file-server01.corp.company.local

Application (ws-employee-05):
  └─ DNS query: "What is IP of file-server01.corp.company.local?"
       ↓
System Resolver (/etc/resolv.conf):
  nameserver 10.0.120.10  # dc01
  nameserver 10.0.120.11  # dc02
  search corp.company.local
       ↓
Query sent to dc01:
  ├─ Source: 10.0.130.35:54321 (ws-employee-05, random port)
  ├─ Destination: 10.0.120.10:53 (dc01 DNS)
  ├─ Protocol: UDP (DNS)
  └─ Query: A record for file-server01.corp.company.local
       ↓
Firewall Check (dc01):
  ├─ Source: 10.0.130.35 (VLAN 130)
  ├─ Destination: 10.0.120.10:53 (DNS)
  ├─ Rule: VLAN 130 → VLAN 120:53 = PERMIT
  └─ Allowed
       ↓
Samba DNS Service:
  ├─ Process: /usr/sbin/samba (DNS component)
  ├─ Receives query: file-server01.corp.company.local
  ├─ Zone: corp.company.local (AD-integrated DNS)
       ↓
DNS Database Lookup:
  ├─ Backend: /var/lib/samba/private/dns.ldb
  ├─ Query: SELECT * FROM dns_records WHERE name='file-server01'
  ├─ Result:
  │   Name: file-server01.corp.company.local
  │   Type: A
  │   Value: 10.0.120.20
  │   TTL: 900 seconds
  └─ Record found
       ↓
AppArmor Check:
  ├─ Profile: /usr/sbin/samba
  ├─ Operation: Read /var/lib/samba/private/dns.ldb
  └─ Allowed (Samba profile permits DNS database access)
       ↓
Response sent:
  ├─ Answer: file-server01.corp.company.local = 10.0.120.20
  ├─ TTL: 900 seconds
  └─ Sent to: 10.0.130.35:54321
       ↓
Logging:
  ├─ Samba DNS log (if debug level high):
  │   [2026/01/09 08:30:15] DNS query from 10.0.130.35: file-server01.corp.company.local → 10.0.120.20
  │
  └─ Auditd (if rule configured):
      type=NETFILTER_PKT msg=audit(1704791415.123:4000):
        saddr=10.0.130.35 daddr=10.0.120.10 proto=17 dport=53
        res=success key="dns_query"
```

**DNS Security Features:**
- ✅ **AD-Integrated Zones** (replicated with domain data)
- ✅ **Secure Dynamic Updates** (only authenticated clients can update)
- ✅ **DNSSEC** (optional, can be enabled for validation)
- ✅ **Rate Limiting** (prevent DNS amplification attacks)
- ❌ **Split-Horizon DNS** (not implemented, all zones internal-only)

---

## Hardening Configuration

### UFW Firewall Rules (/etc/ufw/applications.d/samba-ad)

```bash
# Domain Controller allowed ports

# DNS
ufw allow from 10.0.120.0/24 to any port 53 proto udp comment 'DNS from Servers'
ufw allow from 10.0.130.0/24 to any port 53 proto udp comment 'DNS from Workstations'
ufw allow from 10.0.131.0/24 to any port 53 proto udp comment 'DNS from Admin'

# Kerberos
ufw allow from 10.0.120.0/24 to any port 88 proto tcp comment 'Kerberos from Servers'
ufw allow from 10.0.130.0/24 to any port 88 proto tcp comment 'Kerberos from Workstations'
ufw allow from 10.0.131.0/24 to any port 88 proto tcp comment 'Kerberos from Admin'
ufw allow from 10.0.120.0/24 to any port 88 proto udp comment 'Kerberos UDP'

# LDAP
ufw allow from 10.0.120.0/24 to any port 389 proto tcp comment 'LDAP from Servers'
ufw allow from 10.0.130.0/24 to any port 389 proto tcp comment 'LDAP from Workstations'
ufw allow from 10.0.131.0/24 to any port 389 proto tcp comment 'LDAP from Admin'

# LDAPS (encrypted)
ufw allow from 10.0.120.0/24 to any port 636 proto tcp comment 'LDAPS from Servers'
ufw allow from 10.0.131.0/24 to any port 636 proto tcp comment 'LDAPS from Admin'

# Global Catalog
ufw allow from 10.0.120.0/24 to any port 3268 proto tcp comment 'GC from Servers'
ufw allow from 10.0.120.0/24 to any port 3269 proto tcp comment 'GC-SSL from Servers'

# SMB (for SYSVOL/NETLOGON replication)
ufw allow from 10.0.120.10 to any port 445 proto tcp comment 'SMB from dc01 (replication)'
ufw allow from 10.0.120.11 to any port 445 proto tcp comment 'SMB from dc02 (replication)'

# NTP (time sync - critical for Kerberos)
ufw allow from 10.0.120.0/24 to any port 123 proto udp comment 'NTP from Servers'
ufw allow from 10.0.130.0/24 to any port 123 proto udp comment 'NTP from Workstations'

# SSH (ansible-ctrl only)
ufw allow from 10.0.120.50 to any port 22 proto tcp comment 'SSH from ansible-ctrl'

# Default deny
ufw default deny incoming
ufw default allow outgoing
```

---

### AppArmor Profile (/etc/apparmor.d/usr.sbin.samba)

```
#include <tunables/global>

/usr/sbin/samba {
  #include <abstractions/base>
  #include <abstractions/nameservice>
  #include <abstractions/authentication>
  #include <abstractions/openssl>

  # Capabilities (minimal)
  capability dac_override,
  capability dac_read_search,
  capability chown,
  capability fowner,
  capability fsetid,
  capability kill,
  capability net_bind_service,
  capability setgid,
  capability setuid,
  capability sys_admin,

  # Samba binaries
  /usr/sbin/samba mr,
  /usr/bin/samba-tool rix,

  # Configuration
  /etc/samba/** r,

  # Databases (AD data)
  /var/lib/samba/** rw,
  /var/lib/samba/private/*.ldb rwk,
  /var/lib/samba/private/*.tdb rwk,

  # Logs
  /var/log/samba/** rw,

  # SYSVOL and NETLOGON (GPO distribution)
  /var/lib/samba/sysvol/** rw,

  # Kerberos
  /var/lib/samba/private/krb5.conf r,
  /etc/krb5.conf r,

  # Deny dangerous operations
  deny /etc/shadow r,
  deny /etc/passwd w,
  deny /etc/group w,
  deny /root/** rw,
  deny /home/** rw,
  deny /usr/bin/** w,
  deny /usr/sbin/** w,

  # Deny network except allowed
  deny network raw,
  deny network packet,
}
```

**AppArmor Protection:**
- Samba can ONLY access its own databases and config
- CANNOT read /etc/shadow (even if exploited)
- CANNOT modify system binaries
- CANNOT access user home directories
- Limits blast radius if Samba compromised

---

### Fail2ban Configuration (/etc/fail2ban/jail.d/samba.conf)

```ini
[samba-auth]
enabled = true
port = 88,389,636,445
filter = samba-auth
logpath = /var/log/samba/log.samba
maxretry = 3
findtime = 600
bantime = 3600
action = ufw

[samba-brute]
enabled = true
port = 88
filter = samba-kerberos-brute
logpath = /var/log/samba/log.samba
maxretry = 5
findtime = 300
bantime = 86400
action = ufw
```

**Filter (/etc/fail2ban/filter.d/samba-auth.conf):**
```ini
[Definition]
failregex = .*AS-REQ FAILED.*from <HOST>
            .*LDAP.*authentication.*failed.*<HOST>
            .*Failed password for.*from <HOST>
ignoreregex =
```

---

### Auditd Rules (/etc/audit/rules.d/dc.rules)

```bash
# Domain Controller audit rules

# Watch AD database modifications
-w /var/lib/samba/private/sam.ldb -p wa -k ad_database_modification
-w /var/lib/samba/private/secrets.ldb -p wa -k ad_secrets_access

# Watch Kerberos operations
-a always,exit -F arch=b64 -S socket -F a0=2 -F a2=88 -k kerberos_connections

# Watch LDAP bind operations
-a always,exit -F arch=b64 -S bind -F a0=389 -k ldap_bind
-a always,exit -F arch=b64 -S bind -F a0=636 -k ldaps_bind

# Watch admin actions
-a always,exit -F arch=b64 -S execve -F exe=/usr/bin/samba-tool -k samba_admin_commands

# Watch user/group modifications
-w /usr/bin/samba-tool -p x -k ad_user_management

# Watch replication events
-w /var/lib/samba/private/dns.ldb -p wa -k dns_database_modification

# Watch SYSVOL changes (GPO modifications)
-w /var/lib/samba/sysvol -p wa -k sysvol_modification

# Failed authentication attempts (supplement Fail2ban)
-a always,exit -F arch=b64 -S connect -F success=0 -k auth_failure
```

---

## Administrative Access (Ansible Only)

### SSH Access Restriction

```bash
# /etc/ssh/sshd_config.d/99-ansible-only.conf

# Only ansible user can SSH
AllowUsers ansible

# Key-only authentication
PasswordAuthentication no
ChallengeResponseAuthentication no
PubkeyAuthentication yes

# Only from ansible-ctrl
Match User ansible Address 10.0.120.50
    AuthorizedKeysFile /home/ansible/.ssh/authorized_keys
    ForceCommand /usr/local/bin/ansible-wrapper

# Deny all other sources
Match User ansible Address !10.0.120.50
    DenyUsers ansible
```

**Ansible Wrapper Script (/usr/local/bin/ansible-wrapper):**
```bash
#!/bin/bash
# Wrapper for Ansible SSH connections
# Logs all commands, restricts operations

# Log connection
logger -t ansible-wrapper "Ansible connection from $SSH_CLIENT by $USER"
echo "[$(date)] Ansible connection: $SSH_ORIGINAL_COMMAND" >> /var/log/ansible-access.log

# Audit log
auditctl -m "ansible-access: $SSH_ORIGINAL_COMMAND"

# Execute original command (only if from ansible-ctrl)
if [[ "$SSH_CLIENT" =~ ^10\.0\.120\.50 ]]; then
    exec $SSH_ORIGINAL_COMMAND
else
    echo "ERROR: SSH access only allowed from ansible-ctrl (10.0.120.50)"
    exit 1
fi
```

---

## Disaster Recovery

### Backup Strategy

```bash
# Daily backup script (run by ansible-ctrl)
#!/bin/bash
# /usr/local/bin/backup-dc.sh

DATE=$(date +%Y%m%d)
BACKUP_DIR="/backup/dc01/$DATE"

# Stop Samba (brief outage, dc02 handles requests)
systemctl stop samba-ad-dc

# Backup AD database
mkdir -p "$BACKUP_DIR"
tar czf "$BACKUP_DIR/ad-database.tar.gz" \
    /var/lib/samba/private/*.ldb \
    /var/lib/samba/private/*.tdb

# Backup SYSVOL (GPOs)
tar czf "$BACKUP_DIR/sysvol.tar.gz" \
    /var/lib/samba/sysvol

# Backup configuration
tar czf "$BACKUP_DIR/config.tar.gz" \
    /etc/samba

# Start Samba
systemctl start samba-ad-dc

# Encrypt backup
gpg --encrypt --recipient backup@corp.company.local \
    "$BACKUP_DIR/ad-database.tar.gz"

# Copy to backup server
rsync -avz "$BACKUP_DIR/" backup-server:/backups/dc01/$DATE/

# Cleanup local backup
rm -rf "$BACKUP_DIR"

# Log
logger -t dc-backup "DC backup completed: $DATE"
```

---

## Test Cases for Validation

### Test Case 1: Authentication Success
```
Test: User authenticates from workstation
Expected: Kerberos ticket issued, logged, no alerts
Command: ssh user@workstation "kinit user@CORP.COMPANY.LOCAL"
```

### Test Case 2: Failed Authentication (Brute Force)
```
Test: 5 failed auth attempts from same IP
Expected: IP banned after 3 attempts, alert generated
Simulate: for i in {1..5}; do kinit fake@CORP.COMPANY.LOCAL; done
```

### Test Case 3: Replication Verification
```
Test: Add user on dc01, verify appears on dc02
Expected: User replicated within 15 seconds
Command:
  dc01: samba-tool user add testuser Password123!
  dc02: samba-tool user show testuser (wait 15s)
```

### Test Case 4: DNS Resolution
```
Test: Query DNS for server record
Expected: Correct IP returned, logged
Command: dig @10.0.120.10 file-server01.corp.company.local
```

### Test Case 5: AppArmor Enforcement
```
Test: Samba tries to read /etc/shadow
Expected: AppArmor denies, AVC log generated
Simulate: sudo -u samba cat /etc/shadow (should fail)
```

### Test Case 6: Firewall Rule Validation
```
Test: Connection from unauthorized subnet
Expected: Connection blocked, no response
Command: From external: telnet 10.0.120.10 88 (should timeout)
```

### Test Case 7: SSH Access Control
```
Test: SSH from non-ansible-ctrl IP
Expected: Connection refused
Command: From workstation: ssh dc01 (should fail)
```

### Test Case 8: Audit Log Capture
```
Test: Admin adds user, verify audit trail
Expected: Complete audit log with who/what/when
Command: ausearch -k ad_user_management
```

---

## Compliance Benefits

### Multi-Master Replication (High Availability)
✅ **dc01 fails** → dc02 handles all authentication (no downtime)
✅ **Automatic failover** → DNS round-robin, clients retry dc02
✅ **Data consistency** → Multi-master with conflict resolution

### Security Hardening (CIS Benchmark)
✅ **Firewall** - Default deny, explicit allow only required ports
✅ **AppArmor** - MAC confinement, limit blast radius
✅ **Fail2ban** - Automated brute force protection
✅ **SSH** - Key-only, from ansible-ctrl only
✅ **Audit** - Comprehensive logging of all auth and admin actions

### Compliance (SOX, HIPAA, ISO 27001)
✅ **Authentication audit** - All login attempts logged
✅ **Authorization audit** - Group changes logged
✅ **Encryption** - Kerberos tickets encrypted (AES256)
✅ **Time sync** - NTP ensures Kerberos functions (±5 min requirement)
✅ **Backup** - Daily encrypted backups to separate server

---

**Document Version:** 1.0
**Last Updated:** 2026-01-09
**For:** Domain Controllers (dc01, dc02) - Ubuntu with Samba AD DC
**OS:** Ubuntu 24.04 LTS Server
**Service:** Samba 4.x Active Directory Domain Controller
