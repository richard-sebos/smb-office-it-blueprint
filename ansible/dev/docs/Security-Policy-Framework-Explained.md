# Understanding Security Policies: From Tools to User Profiles


- There one thing I learnt in my time in IT, we people understand what happens behind the sense when doing IT task and projects.
- This leads 2 to 3 day request being ask as no hurry, can you get it done by the end of the day, that actual happen.
- Whether to be ill time request or initial prototypes, one thing usually get left for the next state of the task or project, security.
- It's not that all security is ignored, the base security is normally there last minute changes will not have the smae security that a well plan project will.
  
- I recently teasers is it time for a Linux business desktop.
- I do think there are certaim business cases there this could work but if all it offers is the same AD directory functionality then why should business users use?
- Because it is free? There are people, include myself that got into Linux because of free licensing or Open Source.
- A free item that doesn't solve a basic need will not be used.
- So what can Linux bring of value?
  
## Introduction: The Problem with Traditional Security

Imagine you're setting up security for a new employee, Sarah, who's a Finance Manager. In a traditional IT setup, you'd need to:

1. Configure her for 2FA Login
2. Add her to the right Active Directory groups
3. Set up permissions for Finance files
4. Configure firewall rules for her laptop
5. Enable audit logging for her account
6. Set up encrypted file access
7. Configure remote access
8. Set backup retention policies for her data

That's **8 different systems** to configure, each with its own syntax, documentation, and potential for misconfiguration. Miss one step, and you've either locked her out or left a security hole.

Now imagine you need to do this for 50 employees across 5 different job roles. And then imagine changing the security requirements 6 months later (new compliance requirement, security incident, etc.). You'd need to touch hundreds of configuration files across dozens of systems.

**There has to be a better way.**

## The Big Idea: Think Like a Business, Not Like a Sysadmin

What if instead of thinking about tools (PAM, SELinux, firewalls), we thought about **what users need to do their jobs**?

- **Managers** need to access sensitive department data with strong security
- **Developers** need isolated environments that can't touch production
- **Finance staff** need encrypted access to financial records with audit trails
- **General employees** need basic access to shared files and printers

These are **business requirements**, not technical specifications. But somehow we need to translate them into the hundreds of low-level settings across our infrastructure.

The solution is a **four-layer architecture**:

```
BUSINESS LAYER:    Who are you?
    ↓              (Manager, Developer, Employee)

POLICY LAYER:      What do you need?
    ↓              (Secure logon, encrypted data, network access)

TOOL LAYER:        How do we enforce it?
    ↓              (PAM, SELinux, firewalls, SSH)

DEPLOYMENT:        Deploy it consistently?
                   (Ansible)
```
- 
- This is not new but as part of the project I am working, I want to define standart security template that can be used to setup Linux desktops
- there templates can be used by business to secure they Linux desktops.

 
This seems complex and why going to these steps?
---

- Linux, correct or not has a reparations of being more secure that Windows.
- There a feeling that once installed you change check off the security
- And well there are more virus for Windows than Linux, there are still more steps than installing and update

## Layer 1: Business Layer - User Profiles (The "Who")
- With the intruduction of AI, there will be a neew set of small business with limited number of user but still needing enterprise level security.
- When it comes to security, not all users are created equal.
- A receipt in an area open to the public may need tigher security than employees working in the back office but finance users may need stricture security.
- This is more than just what they have access to, and include kios mode setup in open space, short auto log off, or MFA and secure keys or cards

At the top, we define **user profiles** based on job roles. These are easy for HR and management to understand:

### Profile: Manager
**Who they are**: Department heads, senior staff who handle sensitive information

**What they can do**:
- Access department financial records
- View HR employee data (if HR manager)
- Work from office or home
- Access during business hours (with exceptions for on-call)

**Security requirements**:
- Strong authentication (password + physical key)
- All actions logged for compliance
- Encrypted data access
- Single device at a time (no account sharing)

### Profile: Developer
**Who they are**: IT staff who write and test code

**What they can do**:
- Access development/test servers
- Deploy code to staging environments
- Use Docker containers for testing
- Download packages from the Internet

**What they CANNOT do**:
- Access production servers directly
- View real customer data
- Access file servers or financial systems
- Connect from untrusted networks

**Security requirements**:
- Standard authentication (password only for dev work)
- Container isolation (can't break out to host)
- All code changes reviewed before production
- Test data only (synthetic, no PII)

### Profile: Employee
**Who they are**: General office workers (accounting, sales, operations)

**What they can do**:
- Access shared network drives (their department only)
- Print to office printers
- Use email and Office applications
- Access from office workstation only

**What they CANNOT do**:
- Access other departments' files
- Connect remotely (no SSH, no VPN)
- Install software or change system settings
- Access servers directly

**Security requirements**:
- Basic authentication (password only)
- Limited logging (privacy-preserving)
- Standard encryption for network shares
- Hourly backups with 90-day retention

### Profile: Receptionist
**Who they are**: Front desk staff with shared workstation

**What they can do**:
- Check email and calendar
- Use visitor management system
- Print visitor badges
- Access company directory

**What they CANNOT do**:
- Access financial or HR data
- Save files locally (workstation resets nightly)
- Install applications
- Use USB drives or external devices

**Security requirements**:
- Minimal authentication (shared account acceptable)
- Immutable workstation (resets to clean state daily)
- Network-only storage (no local data persistence)
- Limited Internet access (business sites only)

---

## Layer 2: Policy Layer - Security Objects (The "What")
- this is where we take this like the 8 layers above and start expanding it out
- User Login
	- Receiption kois mode with limited access, so standard login with AD
  - Finance/HR users AD and MFA
  - Senior managers and partners AD, MFA and security keys like Yuboic

- file permission
  - No local storage on any user devices
  - Receipion - Read access to limited network shares
  - Financial/HR - Special share drives that are encrypted and protected 
  - Senior Managers - Have access to most shared drives but from limited devices

This is the magic layer that translates business needs into security requirements. We group related policies into **security objects** that can be mixed and matched.

Think of security objects like Lego blocks - you combine different blocks to build the exact security profile you need.

### Security Object: User Access (Basic)

**Purpose**: Control how users log in and what they can do during a session

**Contains these policies**:

#### Logon Policy
*How do you prove you are who you say you are?*

- **Authentication method**: Password only
- **Password requirements**: 12 characters, complexity rules, 90-day expiration
- **Failed login handling**: Lock account after 5 failed attempts
- **Where you can log in from**: Office workstations only

#### Session Policy
*What happens while you're logged in?*

- **Idle timeout**: 30 minutes (automatically log out if inactive)
- **Concurrent sessions**: 2 allowed (desktop + laptop)
- **Screen lock**: Required after 10 minutes
- **Session recording**: No (privacy for general users)

#### Audit Policy
*What do we log about your activity?*

- **Logging level**: Aggregated (we see trends, not individual actions)
- **Log retention**: 90 days
- **What we log**: Login/logout times, failed access attempts
- **What we DON'T log**: Individual file opens, keystrokes, screen content

**Who gets this**: General employees, receptionists

---

### Security Object: User Access (Privileged)

**Purpose**: Enhanced security for users who handle sensitive data

**Contains these policies**:

#### Logon Policy
*Two-factor authentication required*

- **Authentication method**: Password + Yubikey (physical security key)
- **Password requirements**: 16 characters, complexity rules, 60-day expiration
- **Failed login handling**: Lock after 3 failed attempts + notify security team
- **Where you can log in from**: Office or approved home IP addresses only

#### Session Policy
*Restricted to single device*

- **Idle timeout**: 15 minutes (stricter than general users)
- **Concurrent sessions**: 1 only (no account sharing)
- **Screen lock**: Required after 5 minutes
- **Session recording**: No (managers get privacy too)

#### Audit Policy
*Everything logged for compliance*

- **Logging level**: Detailed (every file access, every command)
- **Log retention**: 7 years (SOX compliance requirement)
- **What we log**: File opens, file modifications, commands executed, network connections
- **Alert triggers**: Access to restricted files, large file downloads, after-hours activity

**Who gets this**: Managers, finance staff, HR staff

---

### Security Object: User Access (Developer)

**Purpose**: Isolated development access with limited production reach

**Contains these policies**:

#### Logon Policy
*Standard authentication for development work*

- **Authentication method**: Password + AD group membership (IT-Staff)
- **Password requirements**: 14 characters, complexity rules, 90-day expiration
- **Failed login handling**: Lock after 5 failed attempts
- **Where you can log in from**: Office, home (VPN), or dev-test servers only

#### Session Policy
*Multiple sessions allowed for development*

- **Idle timeout**: 30 minutes
- **Concurrent sessions**: 3 allowed (workstation + multiple SSH sessions)
- **Screen lock**: Required after 15 minutes
- **Session recording**: Yes for production server access (incident investigation)

#### Audit Policy
*Code changes and deployments logged*

- **Logging level**: Development activity (Git commits, deployments, container starts)
- **Log retention**: 1 year
- **What we log**: Code commits, CI/CD pipeline runs, container deployments, production access attempts
- **Alert triggers**: Attempts to access production servers, hardcoded secrets in code

**Who gets this**: Developers, DevOps engineers

---

### Security Object: Data Access (Department)

**Purpose**: Access to department-specific shared files

**Contains these policies**:

#### Storage Policy
*How data is protected at rest*

- **Encryption**: Standard (SELinux with default contexts)
- **Access control**: Department group membership required
- **File permissions**: Read/write for group members, no access for others
- **Quotas**: 50 GB per user

#### Encryption Policy
*How data is protected in transit*

- **Network protocol**: SMB3 with encryption
- **Certificate validation**: Standard (trust internal CA)
- **Minimum TLS version**: 1.2

#### Backup Policy
*How we protect you from data loss*

- **Frequency**: Hourly snapshots + nightly backup
- **Retention**: 90 days
- **Recovery point**: Can restore from any hour in the last 90 days
- **Who can request recovery**: Department manager or IT staff

**Who gets this**: General employees accessing department shares

---

### Security Object: Data Access (Sensitive)

**Purpose**: Access to sensitive data (financial, HR, legal)

**Contains these policies**:

#### Storage Policy
*Enhanced encryption and access control*

- **Encryption**: FIPS 140-2 mode (government-grade cryptography)
- **Access control**: Multi-level security (SELinux categories)
- **File permissions**: Explicit allow-list (deny by default)
- **Quotas**: 100 GB per user
- **Additional protection**: ClamAV virus scanning on access

#### Encryption Policy
*Mandatory encryption in transit*

- **Network protocol**: SMB3 with encryption REQUIRED (not optional)
- **Certificate validation**: Strict (reject invalid certs)
- **Minimum TLS version**: 1.3 (most secure)

#### Backup Policy
*Long-term retention for compliance*

- **Frequency**: Continuous (changed files backed up within 5 minutes)
- **Retention**: 7 years (SOX compliance)
- **Recovery point**: Can restore from any 5-minute interval
- **Who can request recovery**: Manager with dual approval (manager + IT director)
- **Additional protection**: Immutable backups (ransomware can't delete them)

**Who gets this**: Finance managers, HR directors, legal team

---

### Security Object: Data Access (Test-Only)

**Purpose**: Isolated development environments with no production data

**Contains these policies**:

#### Storage Policy
*Synthetic data only*

- **Encryption**: Standard (container isolation sufficient)
- **Access control**: IT-Staff group membership
- **Data source**: Synthetic test data OR anonymized production data only
- **Quotas**: 500 GB (large datasets for testing)
- **Additional protection**: No PII allowed (automated scanning blocks real data)

#### Encryption Policy
*Relaxed for development speed*

- **Network protocol**: HTTP acceptable (no TLS requirement for dev)
- **Certificate validation**: Self-signed certs OK
- **Minimum TLS version**: N/A (not required)

#### Backup Policy
*Short retention (test data is ephemeral)*

- **Frequency**: Daily
- **Retention**: 30 days
- **Recovery point**: Daily snapshots only (not critical data)
- **Who can request recovery**: Any developer or IT staff
- **Note**: Test environments can be rebuilt from scratch if needed

**Who gets this**: Developers, QA testers

---

### Security Object: Network Access (Standard)

**Purpose**: Normal network connectivity for office work

**Contains these policies**:

#### Remote Access Policy
*How you connect from outside the office*

- **VPN required**: Yes (for home access)
- **VPN authentication**: Same as workstation login (password or password + Yubikey)
- **SSH access**: No (not needed for general users)
- **Allowed source IPs**: Any (but VPN required outside office)

#### Firewall Policy
*What network resources you can reach*

- **File server**: Yes (your department shares only)
- **Print server**: Yes (all office printers)
- **Email server**: Yes
- **Internet**: Yes (with content filtering)
- **Other servers**: No (databases, monitoring, backups - IT only)
- **Other user workstations**: No (no lateral movement)

**Who gets this**: General employees, managers

---

### Security Object: Network Access (Isolated)

**Purpose**: Strict isolation for development environments

**Contains these policies**:

#### Remote Access Policy
*SSH access for server management*

- **VPN required**: Yes
- **VPN authentication**: Password + Yubikey (enhanced for IT staff)
- **SSH access**: Yes (key-based authentication only, no passwords)
- **Allowed source IPs**: Admin VLAN or VPN only

#### Firewall Policy
*Can ONLY access dev/test servers*

- **Dev/test servers**: Yes
- **Production servers**: **BLOCKED** (file server, domain controllers, databases)
- **Internet**: Yes (for package downloads - npm, pip, apt)
- **Monitoring server**: Yes (to view logs)
- **Other resources**: No

**Key principle**: Even if a developer's workstation is compromised, the attacker cannot pivot to production systems.

**Who gets this**: Developers, DevOps engineers

---

### Security Object: Network Access (Administrative)

**Purpose**: Full network access for IT operations

**Contains these policies**:

#### Remote Access Policy
*Enhanced authentication for privileged access*

- **VPN required**: Yes
- **VPN authentication**: Password + Yubikey + JIT approval for production changes
- **SSH access**: Yes (key-based + Kerberos)
- **Allowed source IPs**: Admin VLAN or approved home IPs only
- **Session recording**: Yes (for compliance and incident investigation)

#### Firewall Policy
*Access to all systems*

- **All servers**: Yes (file, database, backup, monitoring, etc.)
- **All workstations**: Yes (for support)
- **Management interfaces**: Yes (firewalls, switches, routers)
- **Internet**: Yes
- **Note**: Access logged comprehensively (who, what, when, from where)

**Additional control**: Just-In-Time (JIT) elevation - production changes require manager approval before execution.

**Who gets this**: IT administrators, security team

---

## Layer 3: Tool Layer - Implementation (The "How")

This is where the rubber meets the road. Each policy is enforced by specific security tools. The beauty of this architecture is that **business users never need to think about these tools** - they're hidden behind the policies.

### Logon Policy → Implemented By:

| Policy Requirement | Security Tool | What It Does |
|-------------------|--------------|--------------|
| Password authentication | **PAM (Pluggable Authentication Modules)** | Validates username/password against Active Directory |
| Multi-factor authentication | **pam_yubico** | Requires physical Yubikey in addition to password |
| Active Directory integration | **pam_sss (SSSD)** | Connects Linux systems to Windows Active Directory |
| Failed login lockout | **fail2ban** | Automatically blocks IPs after too many failed attempts |
| Password complexity | **pam_pwquality** | Enforces length, complexity, history requirements |

**Example**: When Sarah (Finance Manager) logs in:
1. She types her password → PAM checks it against Active Directory
2. She plugs in her Yubikey and touches the button → pam_yubico validates the one-time code
3. Both succeed → SSSD confirms she's in the "Privileged-Users" AD group
4. Login allowed → auditd logs the successful login

If someone tries to brute-force her account:
- After 3 failed attempts → fail2ban blocks their IP for 1 hour
- Security team gets an alert → investigate potential compromise

---

### Session Policy → Implemented By:

| Policy Requirement | Security Tool | What It Does |
|-------------------|--------------|--------------|
| Idle timeout | **pam_exec + custom script** | Automatically logs out inactive users |
| Concurrent session limit | **pam_limits** | Blocks new logins if user already has max sessions |
| Screen lock | **GNOME/KDE settings** | Activates screensaver with password after idle time |
| Session recording | **tmux + script** | Records all terminal commands for IT staff accessing production |

**Example**: When Alex (Developer) accesses the production database server:
1. SSH connection starts → tmux automatically starts recording
2. Every command Alex types is logged: `SELECT * FROM users WHERE...`
3. Recording saved to monitoring server with timestamp and user ID
4. If an incident occurs, security team can replay exactly what happened

---

### Storage Policy → Implemented By:

| Policy Requirement | Security Tool | What It Does |
|-------------------|--------------|--------------|
| Access control (Linux) | **SELinux** | Mandatory Access Control - even root can't bypass it |
| Encryption at rest | **FIPS 140-2 mode** | Government-certified cryptography for sensitive data |
| Disk encryption | **dm-crypt/LUKS** | Full-disk encryption (can't read disk outside the system) |
| File quotas | **XFS quotas** | Limits how much space each user can consume |
| Virus scanning | **ClamAV** | Scans files on access (prevents ransomware spread) |

**Example**: Finance share protection:
1. Sarah tries to access `/srv/shares/departments/finance/budget.xlsx`
2. SELinux checks: Is Sarah's user context allowed to read `samba_share_t:Finance` files? → Yes (she's in Finance group)
3. File read from disk → LUKS automatically decrypts
4. ClamAV scans file for malware → Clean
5. File data sent to Sarah's workstation via encrypted SMB3 connection

If John (Accounting, not Finance) tries to access the same file:
1. SELinux checks: Is John's user context allowed to read `samba_share_t:Finance` files? → **No** (not in Finance group)
2. Access denied before even reading from disk
3. Audit log created: "john@OFFICE.LOCAL denied access to /srv/shares/departments/finance/budget.xlsx"
4. Alert generated if John tries multiple times (possible reconnaissance)

---

### Encryption Policy → Implemented By:

| Policy Requirement | Security Tool | What It Does |
|-------------------|--------------|--------------|
| Network encryption | **SMB3 encryption** | Encrypts file data over the network (prevents eavesdropping) |
| Certificate validation | **TLS 1.3** | Ensures you're connecting to the real server (not a fake) |
| Kerberos encryption | **AES-256** | Encrypts authentication tickets |
| Email encryption | **S/MIME or GPG** | Encrypts email content (for sensitive communications) |

**Example**: Sarah accesses Finance share from home:
1. Laptop connects to VPN → WireGuard encrypts ALL traffic to office
2. Inside VPN tunnel, laptop connects to file server → SMB3 adds second layer of encryption
3. Kerberos ticket for authentication → AES-256 encrypted (can't be stolen by network sniffing)
4. Result: Three layers of encryption (VPN, SMB3, Kerberos)

---

### Remote Access Policy → Implemented By:

| Policy Requirement | Security Tool | What It Does |
|-------------------|--------------|--------------|
| SSH configuration | **sshd_config** | Disables password auth, requires keys, sets allowed users |
| SSH keys | **ed25519 keys** | Modern, secure key algorithm (better than RSA) |
| VPN | **WireGuard** | Fast, modern VPN with strong encryption |
| Key restrictions | **authorized_keys options** | Limits which IPs can use a key, what commands can be run |

**Example**: Alex (Developer) SSH to dev-test server:
1. Alex runs: `ssh alex@dev-test01`
2. SSH client sends public key fingerprint → Server checks `/home/alex/.ssh/authorized_keys`
3. Key found with restrictions: `from="10.0.131.0/24,172.16.100.0/24"`
4. Client IP 10.0.131.20 matches restriction → Connection allowed
5. SSH establishes encrypted tunnel (ChaCha20-Poly1305 cipher)

If Alex tries to SSH to production file server:
1. Alex runs: `ssh alex@file-server01`
2. Connection attempt → pfSense firewall checks rules
3. Source: 10.0.120.70 (dev-test01), Destination: 10.0.120.20 (file-server01), Rule: **BLOCK dev-test to production**
4. Connection refused → Audit log created → Alert sent to IT Manager

---

### Firewall Policy → Implemented By:

| Policy Requirement | Security Tool | What It Does |
|-------------------|--------------|--------------|
| Network firewall | **pfSense** | Controls traffic between VLANs (physical network segments) |
| Host firewall | **firewalld** | Controls traffic to/from individual servers |
| VLAN isolation | **Switch configuration** | Physically separates networks (dev can't see production) |

**Example**: Firewall rules for dev-test01:

```
Inbound (what can connect TO dev-test01):
✓ ALLOW: Admin VLAN (10.0.131.0/24) → dev-test01:22 (SSH)
✓ ALLOW: Admin VLAN (10.0.131.0/24) → dev-test01:443 (GitLab)
✓ ALLOW: ansible-ctrl (10.0.120.50) → dev-test01:22 (automation)
✗ DENY: Everything else

Outbound (what dev-test01 can connect TO):
✓ ALLOW: dev-test01 → Internet:80,443 (package downloads)
✓ ALLOW: dev-test01 → monitoring01:514 (send logs)
✗ DENY: dev-test01 → file-server01 (production data)
✗ DENY: dev-test01 → dc01/dc02 (production AD)
✗ DENY: dev-test01 → backup-server (production backups)
✗ DENY: dev-test01 → Workstation VLAN (lateral movement)
✓ ALLOW: Everything else to Internet
```

**Why this matters**: Even if a developer's account is compromised and attacker gets access to dev-test01, they are **trapped** in the development environment. They can't pivot to production systems where real data lives.

---

### Audit Policy → Implemented By:

| Policy Requirement | Security Tool | What It Does |
|-------------------|--------------|--------------|
| Linux audit framework | **auditd** | Logs system calls, file access, commands at kernel level |
| Log collection | **rsyslog** | Forwards logs to central monitoring server (can't be tampered locally) |
| Log analysis | **Elasticsearch** | Indexes logs for fast searching (find all file access by user X) |
| Alerting | **Wazuh SIEM** | Correlates events, detects attacks, sends alerts |
| Visualization | **Kibana** | Dashboards showing security events, trends, anomalies |

**Example**: Comprehensive audit trail for Sarah's workday:

```
08:45 - Login to laptop-sarah-01 from IP 10.0.131.21
        auditd: type=USER_LOGIN user=sarah@OFFICE.LOCAL result=success

09:12 - Access Finance share
        auditd: type=PATH name="/srv/shares/departments/finance" result=success

09:15 - Open budget.xlsx
        auditd: type=SYSCALL syscall=open file="budget.xlsx" result=success

09:47 - Modified budget.xlsx
        auditd: type=SYSCALL syscall=write file="budget.xlsx" bytes=245760

12:30 - Attempted to access HR share
        auditd: type=PATH name="/srv/shares/departments/hr" result=denied
        SELinux: AVC denied { read } scontext=user_u:user_r:user_t:Finance
        Wazuh alert: User attempted cross-department access (normal, no action)

17:30 - Logout from laptop-sarah-01
        auditd: type=USER_LOGOUT user=sarah@OFFICE.LOCAL session_duration=8h45m
```

All logs forwarded to monitoring01 (Sarah can't delete them), retained for 7 years (SOX compliance), searchable in seconds via Kibana.

If security incident occurs:
- Search: "Show me all files Sarah accessed on Jan 9, 2026"
- Result: Complete timeline with timestamps, file names, actions taken

---

## Putting It All Together: Real-World Examples

### Example 1: Onboarding Sarah (Finance Manager)

**Traditional Approach** (IT admin does this):
1. Create AD account, add to groups: Domain Users, Finance, Privileged-Users, Print-Users-Finance
2. Configure Yubikey, register serial number in AD
3. Create home directory on file server, set permissions
4. Add to Finance share ACL with read/write permissions
5. Configure laptop firewall rules in pfSense
6. Set up auditd rules for her UID
7. Configure Bacula backup job for her data (7-year retention)
8. Generate SSH key if needed, add to authorized_keys
9. Set up rsyslog forwarding for her logs
10. Configure SELinux context for her user

**Time**: 2-3 hours, touching 10+ different systems, high chance of missing something.

---

**Policy Framework Approach**:

```bash
# Single command (Ansible playbook)
ansible-playbook onboard-user.yml \
  --extra-vars "user=sarah@OFFICE.LOCAL profile=manager department=finance"
```

**What happens behind the scenes**:

1. **Playbook reads profile definition**: `manager`
2. **Applies security objects**:
   - `user_access_privileged` (2FA, enhanced logging)
   - `data_access_sensitive` (Finance share, FIPS encryption, 7-year backups)
   - `network_access_standard` (VPN, file server access)

3. **Ansible configures all tools automatically**:
   - Creates AD account with correct groups
   - Registers Yubikey serial number
   - Generates `/etc/security/access.conf` entry (PAM)
   - Creates `/etc/audit/rules.d/sarah.rules` (auditd)
   - Adds firewall rules in pfSense (via API)
   - Configures file server ACLs (via Ansible samba module)
   - Creates Bacula backup job with 7-year retention
   - Sets up rsyslog forwarding
   - Configures SELinux user context

4. **Verification tests run**:
   - Can Sarah log in? ✓
   - Can Sarah access Finance share? ✓
   - Can Sarah access HR share? ✗ (correct - not authorized)
   - Is 2FA working? ✓
   - Are logs being forwarded? ✓

5. **Report generated**:
   ```
   User: sarah@OFFICE.LOCAL
   Profile: manager
   Security Objects Applied:
     ✓ user_access_privileged
     ✓ data_access_sensitive (Finance)
     ✓ network_access_standard

   Tools Configured:
     ✓ PAM + Yubikey 2FA
     ✓ Active Directory (Privileged-Users, Finance groups)
     ✓ SELinux (user_u:user_r:user_t:s0:c0.c5)
     ✓ Firewall (pfSense rules: laptop-sarah-01 → file-server01)
     ✓ Audit logging (auditd rules for UID 1005)
     ✓ Backups (Bacula job: Sarah-Finance-7year)

   All tests passed. Sarah is ready to start work.
   ```

**Time**: 10 minutes (mostly waiting for AD replication), zero chance of missing a step (playbook enforces completeness).

---

### Example 2: Compliance Audit - "Show Me All Users Who Can Access Finance Data"

**Traditional Approach**:
1. Check AD groups: Who's in "Finance" group? (10 people)
2. Check file server ACLs: Who has explicit permissions? (3 more people)
3. Check SELinux policies: Any custom contexts? (2 more people)
4. Check backup access: Who can restore Finance files? (IT team = 5 people)
5. Cross-reference audit logs: Anyone who accessed Finance files recently? (8 more people)
6. Check firewall rules: Any special exceptions? (1 more person)

**Manual work**: 4-6 hours, results may be incomplete or outdated.

---

**Policy Framework Approach**:

```bash
# Single query
ansible-inventory --graph --vars | grep -A 10 "data_access_sensitive.*Finance"
```

**Result**:
```
Users with Finance Data Access:
  Profile: manager (Department: Finance)
    - sarah@OFFICE.LOCAL
    - michael@OFFICE.LOCAL (CFO)

  Profile: manager (Department: HR)
    - lisa@OFFICE.LOCAL (can access Finance data via cross-dept approval)

  Profile: employee (Department: Finance)
    - john@OFFICE.LOCAL
    - emily@OFFICE.LOCAL
    - david@OFFICE.LOCAL
    - jennifer@OFFICE.LOCAL

  Profile: it-admin
    - alex@OFFICE.LOCAL (full access for support/backup recovery)

Total: 8 users

Security Objects Applied:
  - data_access_sensitive (Sarah, Michael, Lisa, Alex)
  - data_access_department (John, Emily, David, Jennifer)

Compliance Verification:
  ✓ All access logged (auditd rules verified)
  ✓ All changes backed up (7-year retention confirmed)
  ✓ Encryption enabled (SMB3 required, FIPS mode active)
  ✓ Access control enforced (SELinux contexts verified)
```

**Time**: 30 seconds, guaranteed accurate (reflects actual configuration).

---

### Example 3: Security Incident - "Developer Accessed Production File Server"

**Alert received**:
```
Wazuh SIEM Alert - Priority: HIGH
Rule 100240: Development server attempting to access production system

Time: 2026-01-09 14:10:23
Source: dev-test01 (10.0.120.70)
Destination: file-server01 (10.0.120.20)
User: alex@OFFICE.LOCAL
Action: SSH connection attempt
Result: BLOCKED by firewall
```

**Investigation using policy framework**:

1. **Check Alex's profile**:
   ```bash
   ansible-inventory --host alex@OFFICE.LOCAL
   ```

   **Result**:
   ```yaml
   profile: developer
   security_objects:
     - user_access_standard
     - data_access_test_only
     - network_access_isolated  # ← This is the key
   ```

2. **Check network_access_isolated policy**:
   ```yaml
   network_access_isolated:
     firewall_policy:
       allowed_destinations:
         - dev-test01 (development server)
         - monitoring01 (view logs only)
         - Internet (package downloads)
       blocked_destinations:
         - file-server01 (PRODUCTION DATA)  # ← Correctly blocked
         - dc01/dc02 (PRODUCTION AD)
         - backup-server (PRODUCTION BACKUPS)
   ```

3. **Verdict**: **This is expected behavior, not a security incident.**
   - Alex has `developer` profile
   - Developer profile includes `network_access_isolated` security object
   - That object explicitly blocks production server access
   - Firewall correctly enforced the policy
   - Alert is informational (shows policy working as designed)

4. **Follow-up action**: Check with Alex
   - "Hey Alex, we saw you tried to SSH to the file server today. Everything OK?"
   - Alex: "Oh yeah, I needed some sample data for testing. I created a ticket for anonymized data export."
   - IT: "Perfect, that's the correct procedure. The data will be ready in a few hours."

**Time to investigate**: 5 minutes (vs. hours of checking firewall rules, ACLs, logs manually).

---

### Example 4: Policy Change - "New Compliance Requirement: All Finance Access Requires 2FA"

**Scenario**: SOX audit found that some Finance staff only use passwords (no 2FA). New requirement: **Everyone who accesses Finance data must use 2FA**.

**Traditional Approach**:
1. Identify all users with Finance access (see Example 2 - takes hours)
2. For each user, check if they have Yubikey configured
3. Order Yubikeys for users who don't have them
4. Configure pam_yubico for each user
5. Update AD groups to enforce 2FA
6. Update documentation
7. Train users
8. Update audit rules to verify 2FA usage

**Time**: 2-3 weeks, high risk of missing someone.

---

**Policy Framework Approach**:

1. **Update the `data_access_sensitive` security object**:
   ```yaml
   # File: security_objects/data_access_sensitive.yml

   data_access_sensitive:
     storage_policy:
       # ... existing settings ...

     # NEW REQUIREMENT: Add 2FA to this security object
     required_user_access: user_access_privileged  # ← This enforces 2FA
   ```

2. **Run update playbook**:
   ```bash
   ansible-playbook update-security-policies.yml \
     --tags data_access_sensitive
   ```

3. **Ansible automatically**:
   - Identifies all users with `data_access_sensitive` object (8 users from Example 2)
   - Checks which ones have `user_access_privileged` (4 do, 4 don't)
   - Creates report: "4 users need upgrade: john, emily, david, jennifer"
   - Orders Yubikeys for those 4 users (via IT procurement API)
   - Generates temporary exception (30 days to receive and configure Yubikeys)
   - Sends email to those users: "New security requirement: 2FA for Finance access. Your Yubikey will arrive in 3-5 days. Training session scheduled for Jan 15."
   - After Yubikeys configured, removes temporary exception
   - Updates PAM configuration on all relevant systems
   - Verifies 2FA working with test login
   - Updates audit rules to log 2FA failures

4. **Verification**:
   ```bash
   ansible-playbook verify-compliance.yml --tags finance-2fa
   ```

   **Result**:
   ```
   Finance Data Access - 2FA Compliance Check

   Users with Finance access: 8
   Users with 2FA enabled: 8 (100%)

   Compliance Status: ✓ PASS

   Details:
     ✓ sarah@OFFICE.LOCAL - Yubikey SN: 12345678 (registered 2025-06-15)
     ✓ michael@OFFICE.LOCAL - Yubikey SN: 23456789 (registered 2025-06-16)
     ✓ lisa@OFFICE.LOCAL - Yubikey SN: 34567890 (registered 2025-08-22)
     ✓ alex@OFFICE.LOCAL - Yubikey SN: 45678901 (registered 2024-03-10)
     ✓ john@OFFICE.LOCAL - Yubikey SN: 56789012 (registered 2026-01-18)
     ✓ emily@OFFICE.LOCAL - Yubikey SN: 67890123 (registered 2026-01-18)
     ✓ david@OFFICE.LOCAL - Yubikey SN: 78901234 (registered 2026-01-19)
     ✓ jennifer@OFFICE.LOCAL - Yubikey SN: 89012345 (registered 2026-01-19)

   Last verified: 2026-01-20 09:00:00
   Next verification: 2026-02-20 09:00:00
   ```

**Time**: 2-3 weeks for Yubikey delivery and user training (physical constraint), but **policy enforcement is automatic** and **compliance verification takes 30 seconds**.

---

## Benefits Summary: Why This Architecture Matters

### For Business Users and Managers

**You think in business terms, not tech terms:**
- "Sarah is a Finance Manager" → Not "Sarah needs PAM + Yubikey + SELinux + firewall rules"
- "Developers can't access production" → Not "iptables OUTPUT chain blocks 10.0.120.70 → 10.0.120.20"
- "Finance data must be encrypted" → Not "Enable SMB3 encryption + FIPS mode + LUKS + TLS 1.3"

**Compliance is automatic:**
- Auditor asks: "Who can access Finance data?" → Answer in 30 seconds (see Example 2)
- New requirement: "All Finance access needs 2FA" → Update one policy, applies to all 8 users automatically
- Evidence for audit: Ansible playbook logs show exactly what's configured and when

**Onboarding/offboarding is fast and reliable:**
- New hire: 10 minutes to configure everything (vs. 2-3 hours manual)
- Role change: Update profile, all tools reconfigure automatically
- Departure: Disable profile, all access revoked instantly across all systems

**Security incidents are easier to investigate:**
- Alert fires → Check user's profile → See what they're supposed to be able to do
- Deviation from policy? → Investigate (real incident)
- Policy working as designed? → No action needed (false positive)

---

### For IT Staff

**You configure once, apply everywhere:**
- Write policy definition once → Ansible applies to all relevant users
- Change policy → All users updated automatically
- No more "did I remember to update the firewall rule for this user?"

**Consistency is guaranteed:**
- All users with same profile get same configuration (no special snowflakes)
- All tools configured together (can't have 2FA without audit logging)
- Drift detection: Ansible can verify actual configuration matches policy

**Troubleshooting is faster:**
- User can't access something → Check their profile → See what they should have
- Missing access? → Check which security object provides it
- Tool misconfigured? → Ansible can fix it automatically

**Documentation is the configuration:**
- Policy files (YAML) ARE the documentation
- No separate wiki that gets out of date
- Want to know what "manager" profile includes? → Read the YAML file

**Changes are tracked:**
- All policies in Git → Full history of who changed what and when
- Roll back bad change → `git revert` + `ansible-playbook`
- Peer review required → No accidental security holes

---

### For Security Team

**Security is enforced, not requested:**
- Policy says "2FA required" → PAM enforces it (users can't bypass)
- Policy says "no production access" → Firewall blocks it (not just a guideline)
- Policy says "log everything" → Auditd captures it (can't be disabled by user)

**Defense in depth is built-in:**
- Each policy enforced by multiple tools (if one fails, others catch it)
- Example: Finance data protection
  - Layer 1: Firewall (blocks unauthorized networks)
  - Layer 2: SELinux (blocks unauthorized users)
  - Layer 3: POSIX ACLs (blocks unauthorized groups)
  - Layer 4: Encryption (protects data in transit)
  - Layer 5: Audit logging (detects policy violations)

**Compliance is continuous:**
- Daily verification: Does actual config match policy?
- Automated reporting: Who has what access?
- Audit trail: Complete history of all changes

**Incident response is systematic:**
- Alert fires → Check user's profile → Expected behavior or violation?
- Forensics: Audit logs tied to specific policies (easy to trace "why was this allowed?")
- Remediation: Update policy, not individual tools

---

## Next Steps: How to Implement This

If this approach makes sense for your organization, here's how to get started:

### Phase 1: Document Current State (2-4 weeks)

1. **Identify user profiles** (business roles):
   - What roles exist in your organization? (Manager, Developer, Employee, etc.)
   - What does each role need to do their job?
   - What security requirements apply to each role?

2. **Map existing security configurations to policies**:
   - What tools are you already using? (AD, firewalls, SELinux, etc.)
   - What policies do they enforce? (Authentication, access control, encryption, etc.)
   - Which users have which configurations?

3. **Define security objects**:
   - Group related policies together
   - Identify common patterns (most managers need similar access)
   - Document exceptions (CFO needs higher privileges than other managers)

### Phase 2: Build the Framework (4-8 weeks)

1. **Create policy definitions** (YAML files):
   - User profiles: `profiles/manager.yml`, `profiles/developer.yml`, etc.
   - Security objects: `security_objects/user_access_privileged.yml`, etc.
   - Tool configurations: `tools/pam_config.yml`, `tools/firewall_rules.yml`, etc.

2. **Write Ansible playbooks**:
   - `onboard-user.yml`: Apply profile to new user
   - `update-policy.yml`: Change policy, apply to all affected users
   - `verify-compliance.yml`: Check actual config matches policy
   - `offboard-user.yml`: Remove all access for departing user

3. **Test in dev environment**:
   - Create test users with different profiles
   - Verify access is correct (can access what they should, can't access what they shouldn't)
   - Test policy changes (update object, verify all users updated)

### Phase 3: Pilot Rollout (2-4 weeks)

1. **Choose pilot group** (10-20 users):
   - Mix of roles (managers, employees, developers)
   - IT-savvy users who can provide feedback
   - Non-critical systems (if something breaks, limited impact)

2. **Convert pilot users to policy framework**:
   - Document their current access
   - Create profiles that match current access
   - Apply profiles with Ansible
   - Verify they can still do their jobs

3. **Gather feedback**:
   - Did anything break?
   - Is it easier to manage than before?
   - What policies are missing?

### Phase 4: Full Rollout (3-6 months)

1. **Convert all users to policy framework** (waves of 50-100 users):
   - Start with easy roles (general employees)
   - Then complex roles (managers, developers)
   - Finally special cases (contractors, executives)

2. **Migrate all security configurations to policies**:
   - Firewall rules → `network_access` security objects
   - File permissions → `data_access` security objects
   - Authentication settings → `user_access` security objects

3. **Decommission manual processes**:
   - No more manual firewall changes (Ansible only)
   - No more manual AD group changes (policy-driven)
   - No more manual audit rule updates (templates only)

### Phase 5: Continuous Improvement (Ongoing)

1. **Regular policy reviews** (quarterly):
   - Are profiles still accurate? (roles change over time)
   - Are security objects comprehensive? (new tools added?)
   - Are policies being followed? (compliance verification)

2. **Automated compliance checks** (daily):
   - Does actual configuration match policy?
   - Any unauthorized changes? (drift detection)
   - Any policy violations? (access outside profile)

3. **Policy updates** (as needed):
   - New compliance requirements → Update security objects
   - New security tools → Add to implementation layer
   - Business changes → Update profiles

---

## Conclusion: Security That Makes Sense

The traditional approach to security is tool-centric: "We have PAM, SELinux, firewalls, and audit logs. Let's configure them all individually for each user."

This policy framework is **business-centric**: "We have Managers, Developers, and Employees. Let's define what each role needs, then let the tools enforce it automatically."

**The result**:
- **Business users** understand security (profiles match their mental model)
- **IT staff** manage less complexity (configure policies, not individual tools)
- **Security team** enforces consistently (policies can't be bypassed)
- **Auditors** get fast answers (compliance is continuous, not a scramble)

Security stops being a burden and starts being an enabler. You can move fast (onboard users in minutes) while staying secure (policies are always enforced). You can prove compliance (automated verification) without manual work (Ansible does the checking).

**That's the power of thinking in layers**: Business roles → Security policies → Security tools.

---

## Questions for Discussion

As you think about implementing this in your organization:

1. **What user profiles exist in your company?** (Not just job titles, but roles with different security needs)

2. **What security policies are most important to you?** (Compliance-driven? Data protection? Incident prevention?)

3. **What tools are you already using?** (Can we map them to this framework, or do you need new tools?)

4. **What's your biggest security pain point today?** (Manual work? Compliance audits? User onboarding? Incident response?)

5. **How would success be measured?** (Time saved? Fewer security incidents? Audit compliance? User satisfaction?)

Let's discuss how this framework could work for your specific environment.

---

**Document Version:** 1.0
**Last Updated:** 2026-01-10
**Author:** IT Security Team
**Audience:** IT professionals and business stakeholders
**Next Steps:** Review with leadership, gather feedback, plan implementation
