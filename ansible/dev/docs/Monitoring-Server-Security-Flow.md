# Monitoring Server Security Flow
## monitoring01 - Rocky Linux with Log Aggregation and Security Analytics

---

## Use Case: Centralized Security Monitoring and Log Aggregation

**Server:** monitoring01 (10.0.120.60, VLAN 120)

**Purpose:**
- Centralized log collection (rsyslog from all VMs)
- Security event correlation and alerting
- Audit log aggregation (compliance)
- Anomaly detection (ransomware, brute force, mass operations)
- Dashboard for threat visibility
- Long-term log retention (7 years for compliance)

**Risk Level:** HIGH (contains all security data, compromise = attacker knows detection capabilities)

---

## Architecture Overview

```
┌─────────────────────────────────────────────────────────────────┐
│                MONITORING SERVER (monitoring01)                  │
│                  Rocky Linux 9.3 (Oracle Linux compatible)       │
│                  10.0.120.60 (VLAN 120 - Servers)                │
│                                                                   │
│  Services:                                                       │
│  ├─ rsyslog (centralized log receiver, TCP 514)                 │
│  ├─ Elasticsearch (log indexing and search)                     │
│  ├─ Kibana (visualization dashboard)                            │
│  ├─ Logstash (log parsing and enrichment)                       │
│  ├─ Wazuh (SIEM - Security Information Event Management)        │
│  └─ Custom alerting scripts (email, SMS, webhook)               │
│                                                                   │
│  Log Sources (All VMs send logs here):                           │
│  ├─ dc01, dc02          (authentication events)                 │
│  ├─ file-server01       (file access, virus detections)         │
│  ├─ ansible-ctrl        (automation execution)                  │
│  ├─ All workstations    (login attempts, security events)       │
│  ├─ Firewall (pfSense)  (network blocks, intrusions)            │
│  └─ backup-server       (backup status)                         │
│                                                                   │
│  Storage Layout:                                                 │
│  ├─ /var/log/remote/         (raw logs from all systems)        │
│  ├─ /var/log/aggregated/     (summarized for IT staff)          │
│  ├─ /var/log/detailed/       (detailed logs for JIT access)     │
│  └─ /var/lib/elasticsearch/  (indexed logs for search)          │
│                                                                   │
│  Security Layers:                                                │
│  ├─ SELinux (enforcing mode)                                    │
│  ├─ Firewalld (rsyslog from all VLANs, web UI from admin only)  │
│  ├─ Access Control (aggregated logs = IT staff, detailed = JIT) │
│  ├─ Encryption at rest (LUKS on log partition)                  │
│  ├─ Auditd (monitor who accesses logs)                          │
│  └─ Immutable logs (append-only, chattr +a)                     │
└──────────────────────────────────────────────────────────────────┘
```

---

## Security Requirements

| Requirement | Implementation | Why |
|-------------|----------------|-----|
| **Centralized Collection** | rsyslog over TCP (reliable delivery) | Single source of truth |
| **Log Segregation** | Aggregated vs. detailed directories | Privacy protection for IT staff |
| **Encryption at Rest** | LUKS on /var/log partition | Protect sensitive log data |
| **Immutable Logs** | chattr +a (append-only) | Prevent attacker from deleting evidence |
| **Access Control** | SELinux + file permissions | Only authorized personnel access logs |
| **Long Retention** | 7-year retention (compliance) | SOX, HIPAA requirements |
| **Anomaly Detection** | Wazuh SIEM rules | Detect attacks automatically |
| **Alerting** | Email, SMS, webhook | Real-time notification |
| **Dashboard** | Kibana web UI (HTTPS only) | Threat visibility |
| **Audit Log Access** | Auditd on log file access | Track who viewed sensitive logs |

---

## Security Flow Trace: Log Collection and Analysis

### **Scenario 1: Failed Login Attempt Collected and Analyzed**

```
[10:00 AM] Attacker attempts brute force on dc01

dc01 (Domain Controller):
  ├─ Failed authentication: attacker@corp.company.local
  ├─ Samba logs to: /var/log/samba/log.samba
  ├─ Auditd logs to: /var/log/audit/audit.log
  └─ rsyslog configured to forward to monitoring01
       ↓
rsyslog on dc01 (/etc/rsyslog.d/50-forward.conf):
  *.* @@monitoring01:514

  # Forwards all logs to monitoring01 via TCP (reliable)
       ↓
Network transmission:
  ├─ Source: dc01 (10.0.120.10)
  ├─ Destination: monitoring01 (10.0.120.60:514)
  ├─ Protocol: TCP (reliable, ensures delivery)
  └─ Encrypted: TLS (rsyslog with TLS enabled)
       ↓
Firewall Check (monitoring01):
  ├─ Rule: VLAN 120 → monitoring01:514 = PERMIT (syslog from servers)
  └─ Allowed
       ↓
rsyslog on monitoring01 receives log:
  ├─ Listener: 0.0.0.0:514 (TCP)
  ├─ Source: dc01 (10.0.120.10)
  ├─ Log entry: "AS-REQ FAILED for attacker@corp.company.local from 73.25.145.88"
       ↓
rsyslog processing (/etc/rsyslog.conf):
  # Store to disk by hostname
  template(name="RemoteHost" type="string" string="/var/log/remote/%HOSTNAME%/%$YEAR%%$MONTH%%$DAY%.log")
  *.* ?RemoteHost

  # Forward to Logstash for parsing
  *.* @@localhost:5044
       ↓
Log written to disk:
  /var/log/remote/dc01/20260109.log:
    Jan 09 10:00:15 dc01 samba[5678]: AS-REQ FAILED for attacker@corp.company.local from 73.25.145.88 (wrong password)
       ↓
Logstash receives log (port 5044):
  ├─ Parse with grok filter (extract fields)
  ├─ Fields extracted:
  │   timestamp: 2026-01-09 10:00:15
  │   hostname: dc01
  │   service: samba
  │   event_type: AUTH_FAILED
  │   user: attacker@corp.company.local
  │   source_ip: 73.25.145.88
  │   reason: wrong password
  └─ Enrichment: GeoIP lookup (73.25.145.88 = China, Beijing)
       ↓
Logstash sends to Elasticsearch:
  ├─ Index: logs-2026.01.09
  ├─ Document ID: auto-generated
  └─ Stored with all parsed fields
       ↓
Wazuh SIEM analyzes event:
  ├─ Rule: "Multiple failed authentication attempts"
  ├─ Query Elasticsearch: Count failed auths from 73.25.145.88 in last 60 seconds
  ├─ Count: 15 failed attempts
  ├─ Threshold: 5 failures = ALERT
  └─ Severity: HIGH (external IP, rapid attempts)
       ↓
Wazuh triggers alert:
  ├─ Alert ID: 5503 (Brute force attack detected)
  ├─ Action: Execute alert script (/var/ossec/scripts/alert-email.sh)
       ↓
Alert Script Execution:
  #!/bin/bash
  # /var/ossec/scripts/alert-email.sh

  ALERT_JSON=$1
  USER=$(echo $ALERT_JSON | jq -r '.data.user')
  SOURCE_IP=$(echo $ALERT_JSON | jq -r '.data.source_ip')
  COUNT=$(echo $ALERT_JSON | jq -r '.data.count')

  # Email IT Security
  echo "Brute force attack detected: $COUNT attempts on $USER from $SOURCE_IP" | \
    mail -s "SECURITY ALERT: Brute Force Attack" security@corp.company.local

  # SMS on-call engineer
  curl -X POST https://sms-gateway/send \
    -d "to=+1234567890" \
    -d "message=ALERT: Brute force from $SOURCE_IP on dc01"

  # Auto-block IP at firewall (optional)
  ssh firewall "pfctl -t bruteforce -T add $SOURCE_IP"
       ↓
Kibana Dashboard Updates:
  ├─ Widget: "Failed Logins (Last Hour)"
  │   └─ Count: 15 (up from 2)
  ├─ Widget: "Top Attack Sources"
  │   └─ 73.25.145.88 (China) - NEW ENTRY
  └─ Widget: "Alerts Timeline"
      └─ RED spike at 10:00 AM (brute force detected)
       ↓
IT Security receives alert:
  Email: "Brute force attack detected: 15 attempts on attacker@corp.company.local from 73.25.145.88 (China)"
  SMS: "ALERT: Brute force from 73.25.145.88 on dc01"
```

**Security Flow Summary:**
1. ✅ **Event occurs** on dc01 (failed auth)
2. ✅ **rsyslog forwards** to monitoring01 (TCP, encrypted)
3. ✅ **Stored to disk** (/var/log/remote/dc01/)
4. ✅ **Parsed by Logstash** (extract fields, enrich with GeoIP)
5. ✅ **Indexed in Elasticsearch** (searchable)
6. ✅ **Analyzed by Wazuh** (correlation, threshold detection)
7. ✅ **Alert triggered** (email, SMS, auto-remediation)
8. ✅ **Dashboard updated** (real-time visibility)

---

### **Scenario 2: Ransomware Detection via Log Correlation**

```
[2:00 AM] John's workstation (ws-employee-05) starts encrypting files

file-server01 (File Server):
  ├─ Auditd captures mass file operations:
  │   [02:00:15] SYSCALL unlink /srv/shares/home/john/doc1.docx
  │   [02:00:16] SYSCALL unlink /srv/shares/home/john/doc2.docx
  │   [02:00:17] SYSCALL unlink /srv/shares/home/john/doc3.docx
  │   ... (500 files in 30 seconds)
  ├─ rsyslog forwards to monitoring01
       ↓
monitoring01 receives auditd logs:
  ├─ Logstash parses each event
  ├─ Fields: type=SYSCALL, syscall=unlink, user=john, file=*
  └─ Stored in Elasticsearch index: logs-2026.01.09
       ↓
Wazuh SIEM correlation rule:
  <rule id="100100" level="15">
    <if_sid>5300</if_sid> <!-- File deletion rule -->
    <frequency>50</frequency>
    <timeframe>60</timeframe>
    <same_source_user />
    <description>Possible ransomware - Mass file deletion detected</description>
  </rule>

  # Triggers if 50+ file deletions by same user in 60 seconds
       ↓
Wazuh detects pattern (at 2:00:45 AM, after 50 files):
  ├─ User: john@corp.company.local
  ├─ Source: 10.0.130.35 (ws-employee-05)
  ├─ Files deleted: 50 (threshold exceeded)
  ├─ Time window: 30 seconds
  ├─ Assessment: RANSOMWARE
  └─ Severity: CRITICAL
       ↓
Automated Response:
  1. Kill SMB session:
     $ ssh file-server01 "smbcontrol smbd close-share home-john"

  2. Block workstation at firewall:
     $ ssh firewall "pfctl -t quarantine -T add 10.0.130.35"

  3. Disable AD account:
     $ ssh dc01 "samba-tool user disable john"

  4. Trigger emergency snapshot:
     $ ssh file-server01 "lvcreate -L 20G -s -n emergency-$(date +%s) /dev/vg0/shares"

  5. Alert all channels:
     Email: CISO, IT Security, On-call
     SMS: On-call engineer, Security team
     PagerDuty: Critical incident created
       ↓
Kibana Dashboard shows:
  ├─ CRITICAL ALERT: Ransomware detected on ws-employee-05
  ├─ Timeline: File deletion spike at 2:00 AM
  ├─ User: john@corp.company.local
  ├─ Files affected: 500+ (graph shows spike)
  ├─ Response: AUTOMATED CONTAINMENT ACTIVE
  └─ Status: Threat contained, awaiting IT response
       ↓
On-call engineer receives:
  SMS: "CRITICAL: Ransomware detected - ws-employee-05. Auto-contained. Snapshot created."
  Email: Full incident report with timeline, affected files, response actions taken
  PagerDuty: Page (phone call if not acknowledged in 5 minutes)
```

**Ransomware Detection via Log Correlation:**
- ✅ **Detects pattern** (mass file operations) across multiple logs
- ✅ **Correlates events** (same user, same timeframe)
- ✅ **Automated response** (kill session, block, disable, snapshot)
- ✅ **Multi-channel alerting** (email, SMS, PagerDuty)
- ✅ **Evidence preserved** (logs immutable, snapshot created)

---

### **Scenario 3: IT Staff Accesses Detailed User Logs (Privacy Audit)**

```
[3:00 PM] Mike (IT admin) needs to troubleshoot Sarah's login issue

Mike (normal user ID) tries to access detailed logs:
  mike@laptop-mike-01:~$ ssh monitoring01
  mike@monitoring01:~$ cat /var/log/remote/laptop-sarah-01/auth.log
  cat: /var/log/remote/laptop-sarah-01/auth.log: Permission denied
       ↓
File Permissions Check:
  $ ls -l /var/log/remote/laptop-sarah-01/auth.log
  -rw-r----- 1 root security-audit /var/log/remote/laptop-sarah-01/auth.log

  # Only root and security-audit group can read
  # mike (normal ID) is NOT in security-audit group
       ↓
Mike elevates to JIT (mike-admin):
  mike@laptop-mike-01:~$ jit-elevate
  Reason: "Troubleshoot Sarah's login issue - TKT#4590"
  [Yubikey + password authentication]
  → JIT session granted for 4 hours
       ↓
mike-admin@laptop-mike-01:~$ ssh monitoring01
mike-admin@monitoring01:~$ cat /var/log/remote/laptop-sarah-01/auth.log

SELinux Check:
  ├─ User: mike-admin (JIT elevated)
  ├─ Context: staff_u:staff_r:staff_t:s0
  ├─ File context: system_u:object_r:var_log_t:s0
  ├─ SELinux policy: staff_t can read var_log_t (allowed for security-audit group)
  └─ Access: GRANTED (mike-admin in security-audit group)
       ↓
Auditd captures access:
  type=SYSCALL msg=audit(1704816000.123:9000): arch=c000003e
    syscall=257 success=yes comm="cat"
    exe="/usr/bin/cat" auid=1604000 uid=1605000
    key="detailed_log_access"

  type=PATH msg=audit(1704816000.123:9000): item=0
    name="/var/log/remote/laptop-sarah-01/auth.log"
    inode=234567 dev=fd:00 mode=0100640
    obj=system_u:object_r:var_log_t:s0
    key="detailed_log_access"
       ↓
Privacy Alert Generated:
  [15:00:00] PRIVACY: Detailed user log accessed
    JIT User: mike-admin@corp.company.local
    Normal User: mike@corp.company.local
    Accessed Log: laptop-sarah-01/auth.log (contains PII)
    Reason: "Troubleshoot Sarah's login issue - TKT#4590"
    Ticket: TKT#4590 (cross-reference)
    Duration: File read for 2 minutes

    Privacy Compliance:
      ✓ Access was necessary for IT support
      ✓ Minimum data accessed (only Sarah's log, not others)
      ✓ Purpose documented (ticket reference)
      ✓ JIT session (time-limited access)
      ✓ Complete audit trail maintained

    GDPR Article 32: Security of processing - compliant
    Email: Privacy Officer (monthly summary of PII access)
       ↓
Mike finds issue:
  $ grep "sarah" /var/log/remote/laptop-sarah-01/auth.log | tail -10
  Jan 09 14:45:22 laptop-sarah-01 pam_faillock: User locked (3 failed attempts)

  # Sarah locked out due to 3 failed password attempts
  # Solution: Unlock account
       ↓
Mike unlocks Sarah's account:
  mike-admin@monitoring01:~$ ssh dc01
  mike-admin@dc01:~$ samba-tool user unlock sarah
  User 'sarah' unlocked successfully

  mike-admin@dc01:~$ exit
  mike-admin@monitoring01:~$ exit
```

**Privacy Protection for Logs:**
- ✅ **Detailed logs** require JIT elevation (not accessible to normal IT users)
- ✅ **Aggregated logs** (trends, no PII) accessible to normal IT users
- ✅ **Audit trail** tracks who accessed sensitive logs
- ✅ **Privacy alerts** notify Privacy Officer of PII access
- ✅ **Justification required** (ticket reference mandatory)

---

## Log Aggregation for IT Staff (Privacy-Preserving)

### Aggregated Logs (Normal IT Users Can Access)

```bash
# /var/log/aggregated/ directory structure

/var/log/aggregated/
├─ failed-logins-by-subnet.log          # No usernames, just subnet counts
├─ firewall-blocks-by-type.log          # Attack types, not specific IPs
├─ malware-detections-summary.log       # Malware types, not who clicked
├─ system-health-metrics.log            # CPU, RAM, disk usage trends
├─ backup-status-summary.log            # Success/failure counts
└─ threat-intelligence-feed.log         # Known bad IPs, domains

# Generated by cron job every hour:
# /usr/local/bin/generate-aggregated-logs.sh
```

**Example Aggregated Log:**
```
# /var/log/aggregated/failed-logins-by-subnet.log

2026-01-09 10:00-11:00
  Subnet: 10.0.130.0/24 (Workstations)
    Failed logins: 23
    Reasons:
      - Invalid password: 18
      - Account disabled: 3
      - Wrong workstation: 2
    Risk Level: LOW (normal user error)

  Subnet: 10.0.131.0/24 (Admin Workstations)
    Failed logins: 2
    Reasons:
      - 2FA timeout: 2
    Risk Level: MEDIUM (investigate)

  External (VPN):
    Failed logins: 127
    Top sources:
      - CN (China): 98
      - RU (Russia): 23
      - US (unknown): 6
    Risk Level: HIGH (brute force attack)
    Action: 15 IPs auto-blocked

Trend: +45% failed logins compared to last hour
```

**Mike (normal IT user) sees:**
- Trends and patterns (subnet-level)
- No individual usernames (privacy)
- Actionable intelligence (where to investigate)

**Mike does NOT see:**
- Which specific users failed login
- Individual user behavior
- Detailed authentication logs

---

## Wazuh SIEM Rules (Examples)

### Custom Detection Rules (/var/ossec/etc/rules/local_rules.xml)

```xml
<!-- Brute Force Detection -->
<rule id="100001" level="10">
  <if_sid>5503</if_sid>
  <frequency>5</frequency>
  <timeframe>60</timeframe>
  <same_source_ip />
  <description>Brute force attack - 5+ failed logins in 60s from same IP</description>
</rule>

<!-- Ransomware Detection (Mass File Operations) -->
<rule id="100100" level="15">
  <if_sid>5300</if_sid>
  <frequency>50</frequency>
  <timeframe>60</timeframe>
  <same_source_user />
  <description>Possible ransomware - 50+ file operations in 60s</description>
  <group>ransomware,</group>
</rule>

<!-- Disabled Account Access Attempt -->
<rule id="100200" level="8">
  <decoded_as>samba</decoded_as>
  <match>ACCOUNT_DISABLED</match>
  <description>Disabled user attempted access</description>
  <group>authentication_failed,pci_dss_10.2.4,</group>
</rule>

<!-- After-Hours Administrator Activity -->
<rule id="100300" level="7">
  <if_sid>5401</if_sid>
  <time>10 pm - 6 am</time>
  <user>^admin|^root</user>
  <description>Administrator activity outside business hours</description>
  <group>policy_violation,</group>
</rule>

<!-- Cross-Department File Access Attempt -->
<rule id="100400" level="6">
  <decoded_as>samba</decoded_as>
  <match>ACCESS_DENIED.*departments</match>
  <description>Unauthorized department share access attempt</description>
</rule>

<!-- Privilege Escalation via sudo -->
<rule id="100500" level="8">
  <decoded_as>sudo</decoded_as>
  <match>COMMAND=/bin/bash|/bin/sh</match>
  <description>User spawned root shell via sudo</description>
  <group>privilege_escalation,</group>
</rule>
```

---

## Firewall Configuration (firewalld)

```bash
# Allow rsyslog from all VLANs
firewall-cmd --permanent --zone=server --add-rich-rule='
  rule family="ipv4"
  source address="10.0.120.0/24"
  port port="514" protocol="tcp"
  accept'  # Server VLAN

firewall-cmd --permanent --zone=server --add-rich-rule='
  rule family="ipv4"
  source address="10.0.130.0/24"
  port port="514" protocol="tcp"
  accept'  # Workstation VLAN

firewall-cmd --permanent --zone=server --add-rich-rule='
  rule family="ipv4"
  source address="10.0.131.0/24"
  port port="514" protocol="tcp"
  accept'  # Admin VLAN

# Kibana dashboard (HTTPS only, admin VLAN only)
firewall-cmd --permanent --zone=server --add-rich-rule='
  rule family="ipv4"
  source address="10.0.131.0/24"
  port port="5601" protocol="tcp"
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

---

## Log Retention and Compliance

### Retention Policy

```bash
# /etc/logrotate.d/monitoring01-retention

/var/log/remote/*/*.log {
    daily
    rotate 2555        # 7 years (SOX compliance)
    compress
    delaycompress
    notifempty
    create 0640 root security-audit
    sharedscripts
    postrotate
        # Archive to backup server
        /usr/local/bin/archive-logs.sh
    endscript
}

/var/log/aggregated/*.log {
    daily
    rotate 90          # 90 days (sufficient for trends)
    compress
    notifempty
}
```

### Immutable Logs (Prevent Tampering)

```bash
# Make logs append-only (cannot be deleted or modified, only appended)
chattr +a /var/log/remote/*/*

# To remove immutability (only root can do this):
# chattr -a /var/log/remote/*/*

# Verify immutability:
lsattr /var/log/remote/dc01/20260109.log
-----a--------e----- /var/log/remote/dc01/20260109.log
```

**Immutability Protection:**
- Even if attacker gains root access, cannot delete logs
- Can append (so logging continues) but cannot modify past entries
- Prevents evidence destruction

---

## Test Cases for Validation

### Test Case 1: Log Collection
```
Test: Generate event on dc01, verify appears on monitoring01
Command:
  dc01: logger -t TEST "Test message from dc01"
  monitoring01: grep "Test message" /var/log/remote/dc01/$(date +%Y%m%d).log
Expected: Message appears within 5 seconds
```

### Test Case 2: Brute Force Detection
```
Test: Simulate 10 failed logins from same IP
Expected: Wazuh alert triggered, email sent, IP auto-blocked
Simulate: for i in {1..10}; do kinit fake@CORP.COMPANY.LOCAL; done
```

### Test Case 3: Ransomware Detection
```
Test: Simulate mass file operations
Expected: Alert triggered within 60 seconds, auto-response executed
Simulate: for i in {1..60}; do touch /tmp/file$i; rm /tmp/file$i; done (as test user)
```

### Test Case 4: Privacy Audit Trail
```
Test: mike-admin accesses detailed user logs
Expected: Audit log created, privacy alert generated
Command: ausearch -k detailed_log_access
```

### Test Case 5: Immutable Logs
```
Test: Attempt to delete log file
Expected: Operation not permitted (immutable flag)
Command: rm /var/log/remote/dc01/20260109.log
Expected: rm: cannot remove: Operation not permitted
```

---

## Compliance Benefits

### SOX (Financial Controls)
✅ **Audit Trail** - All access to financial systems logged (7-year retention)
✅ **Tamper-Proof** - Immutable logs prevent evidence destruction
✅ **Access Monitoring** - Track who accessed sensitive financial data
✅ **Change Tracking** - All administrative actions logged

### GDPR (Privacy Protection)
✅ **Data Minimization** - Aggregated logs (no PII) for normal IT staff
✅ **Access Control** - Detailed logs require JIT elevation + justification
✅ **Audit Trail** - Track who accessed personal data (Article 30)
✅ **Privacy Alerts** - Notify Privacy Officer of PII access

### HIPAA (Healthcare Compliance)
✅ **Audit Controls** - All access to PHI logged
✅ **Access Reports** - Who accessed what patient data, when
✅ **Security Monitoring** - Detect unauthorized PHI access attempts
✅ **Retention** - 7-year log retention (HIPAA requirement)

---

**Document Version:** 1.0
**Last Updated:** 2026-01-09
**For:** Monitoring Server (monitoring01) - Rocky Linux with ELK + Wazuh SIEM
**OS:** Rocky Linux 9.3 (Oracle Linux compatible)
**Services:** rsyslog, Elasticsearch, Logstash, Kibana, Wazuh SIEM
**Key Features:** Centralized logging, anomaly detection, privacy-preserving aggregation
