# Receptionist Workstation Deployment Guide

## Executive Summary

This guide documents the complete deployment and configuration of **ws-reception01**, a high-security Fedora Silverblue workstation designed for public-area receptionist use.

**Security Level:** HIGH
**Risk Profile:** Public physical access, visible to guests/visitors
**Security Model:** Ephemeral/Immutable with nightly automated reset

## Architecture Overview

### System Specifications

| Component | Value |
|-----------|-------|
| **Hostname** | ws-reception01.corp.company.local |
| **VMID** | 310 |
| **OS** | Fedora Silverblue 41 (Immutable) |
| **IP Address** | 10.0.130.25/24 |
| **VLAN** | 130 (Workstations) |
| **Resources** | 2 vCPU, 4GB RAM, 60GB disk |

### Security Features

| Feature | Implementation | Purpose |
|---------|----------------|---------|
| **Immutable OS** | Fedora Silverblue (OSTree) | Prevents malware persistence |
| **AD Authentication** | SSSD + Kerberos | Centralized identity management |
| **Access Control** | PAM access.conf | Only Receptionists group can log in |
| **Nightly Reset** | Systemd timer at 2 AM | Wipe all local data daily |
| **Idle Timeout** | 3 minutes | Auto-lock in public area |
| **Remote Logging** | rsyslog + auditd | Real-time log forwarding to monitoring01 |
| **Network Printers** | CUPS with IPP | Access to reception printers only |
| **Firewall** | Firewalld whitelist | Blocks all except approved destinations |

## Security Layers

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
      Blocked: Disabled accounts

Layer 3: Authorization (PAM + access.conf)
  └─> Only "Receptionists" group can log in
      Blocked: Valid users not in group

Layer 4: Session Security
  └─> Auto-lock after 3 minutes idle
      Protects: If user walks away

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

## Deployment Components

### Ansible Roles Created

1. **silverblue_ad_integration**
   - Configures SSSD for AD authentication
   - Sets up Kerberos for ticket management
   - Joins workstation to corp.company.local domain
   - Enables automatic home directory creation

2. **silverblue_pam_access**
   - Configures PAM access control rules
   - Restricts login to "Receptionists" group only
   - Blocks all other AD users (even valid accounts)
   - Logs all authorization failures

3. **silverblue_printer_config**
   - Layers CUPS and printer drivers onto OSTree
   - Configures HP-Reception-Printer (10.0.140.55)
   - Configures HP-Reception-Fax (10.0.140.56)
   - Bakes printer config into immutable image

4. **silverblue_nightly_reset**
   - Creates nightly reset script
   - Configures systemd timer for 2 AM daily
   - Syncs logs to monitoring01 before reset
   - Clears /home, /tmp, browser caches
   - Resets OSTree to base snapshot
   - Reboots to fresh system

### Playbook Structure

```yaml
deploy-and-configure-ws-reception01.yml
│
├─ Play 1: Deploy VM on Proxmox
│   └─ Role: proxmox_vm_deploy
│
├─ Play 2: Configure Base System
│   ├─ Role: network_config
│   ├─ Role: hostname_config
│   └─ Role: system_update
│
├─ Play 3: Configure Silverblue Security
│   ├─ Role: silverblue_ad_integration
│   ├─ Role: silverblue_pam_access
│   ├─ Role: silverblue_printer_config
│   └─ Role: silverblue_nightly_reset
│
├─ Play 4: Configure Desktop Environment
│   ├─ Task: Set GNOME idle timeout (3 min)
│   ├─ Task: Enable screen lock
│   └─ Task: Configure browser bookmarks
│
├─ Play 5: Configure Firewall
│   ├─ Task: Install firewalld
│   ├─ Task: Configure allowed services
│   └─ Task: Whitelist destinations
│
└─ Play 6: Finalize Configuration
    ├─ Task: Remove management interface
    └─ Task: Create verification script
```

## Security Scenarios

### Scenario 1: Terminated Employee Access Attempt

**Situation:** Tom (fired last week, AD account disabled) tries to log in at reception desk.

**Flow:**
1. Tom enters: tom@corp.company.local + password
2. GDM → PAM → SSSD
3. SSSD queries dc01
4. dc01 returns: "Account disabled"
5. PAM denies authentication
6. Event logged to monitoring01
7. Alert sent to IT and Security (physical security concern)

**Result:** ✅ Access denied, security team notified

### Scenario 2: Unauthorized User Access Attempt

**Situation:** David (Partner, valid AD account) needs to print, tries to use reception desk.

**Flow:**
1. David enters: david@corp.company.local + correct password
2. GDM → PAM → SSSD
3. SSSD queries dc01
4. dc01 returns: "Authentication successful"
5. PAM checks access.conf: Is david in "Receptionists" group?
6. SSSD queries dc01: No, david is in "Partners" group
7. PAM denies authorization
8. Event logged to monitoring01

**Result:** ✅ Access denied (authenticated but not authorized)

### Scenario 3: Malware Infection

**Situation:** Sarah (receptionist) opens malicious Excel file from email, malware executes.

**Flow:**
1. Malware runs in user context (no admin rights)
2. Attempts to install persistence in /usr/local → BLOCKED (read-only filesystem)
3. Attempts to modify startup files in /etc → BLOCKED (read-only filesystem)
4. Creates files in /home/sarah → Allowed (but wiped at 2 AM)
5. 2:00 AM: Nightly reset timer triggers
6. Logs synced to monitoring01 (malware activity captured)
7. /home/sarah cleared
8. OSTree reset to base snapshot
9. System reboots to fresh state

**Result:** ✅ Malware cannot persist, wiped within 24 hours

### Scenario 4: Physical Security Breach

**Situation:** Sarah steps away for 5 minutes, malicious visitor tries to access workstation.

**Flow:**
1. 3 minutes after last activity: Screen locks automatically
2. Visitor sees locked screen
3. Cannot access without sarah@corp.company.local password
4. Any login attempts logged to monitoring01

**Result:** ✅ No unauthorized access, aggressive timeout protects public area

## Logging and Monitoring

### Log Categories

| Log Type | Location | Retention | Purpose |
|----------|----------|-----------|---------|
| **Authentication** | monitoring01:/var/log/workstations/ws-reception01/auth.log | 90 days | Track all login attempts |
| **Authorization** | monitoring01:/var/log/workstations/ws-reception01/auth.log | 90 days | Track access control failures |
| **Audit** | monitoring01:/var/log/workstations/ws-reception01/audit.log | 90 days | File access, sudo usage |
| **System** | monitoring01:/var/log/workstations/ws-reception01/syslog | 90 days | Boot, services, errors |
| **Print Jobs** | monitoring01:/var/log/workstations/ws-reception01/cups.log | 90 days | Printer usage |
| **Reset Logs** | monitoring01:/var/log/workstations/ws-reception01/reset-logs/ | 90 days | Nightly reset operations |

### Alert Triggers

| Event | Severity | Action |
|-------|----------|--------|
| Failed login (disabled user) | **CRITICAL** | Email IT + Security, SMS Security Manager |
| Failed login (wrong password) | INFO | Log only |
| Unauthorized group login attempt | INFO | Log only (normal behavior) |
| Multiple failed logins (3+ in 5 min) | **WARNING** | Email IT team |
| Nightly reset failure | **CRITICAL** | Email IT team, page on-call |
| Print job to unknown printer | **WARNING** | Email IT team |

## Compliance Readiness

### HIPAA (Healthcare)

✅ **Access Control:** Only authorized users (Receptionists group) can log in
✅ **Audit Trail:** 90-day log retention on monitoring01
✅ **Automatic Logoff:** 3-minute idle timeout
✅ **Encryption:** FIPS-capable (can be enabled in host_vars)
✅ **Integrity:** Immutable OS prevents unauthorized modifications

### SOC 2 (Service Organizations)

✅ **Access Control:** Group-based authentication and authorization
✅ **Change Management:** Immutable infrastructure, controlled via Ansible
✅ **Logging and Monitoring:** Real-time log forwarding, 90-day retention
✅ **Incident Response:** Nightly reset limits exposure window to 24 hours
✅ **Network Segmentation:** Firewall restricts access to approved resources

### PCI-DSS (Payment Card Industry)

✅ **No Local Storage:** Nightly reset ensures no credit card data persists
✅ **Access Control:** Multi-layer authentication and authorization
✅ **Audit Logging:** All access attempts logged and retained
✅ **Network Segmentation:** Firewall whitelist, cannot access payment systems
✅ **Auto-Logoff:** 3-minute timeout protects unattended terminals

### GDPR (General Data Protection Regulation)

✅ **Right to Erasure:** Nightly reset automatically erases all local data
✅ **Data Minimization:** No local data storage, network home directory only
✅ **Accountability:** Complete audit trail of who accessed what, when
✅ **Privacy by Design:** Web-only mode, no local file storage

## Cost Analysis

### Traditional Windows Setup (Per Workstation)

| Item | Cost | Notes |
|------|------|-------|
| Windows 11 Pro License | $200 | One-time |
| Microsoft Office 365 | $150/year | Subscription |
| Antivirus Software | $75/year | Subscription |
| Management Tools | $50/year | SCCM/Intune |
| **3-Year Total** | **$1,025** | Per workstation |

### Fedora Silverblue Setup (Per Workstation)

| Item | Cost | Notes |
|------|------|-------|
| Fedora Silverblue | $0 | Free and open source |
| LibreOffice | $0 | Free and open source |
| Built-in Security | $0 | SELinux, firewalld, auditd |
| Management | $0 | Ansible (already deployed) |
| **3-Year Total** | **$0** | Per workstation |

**Savings per workstation:** $1,025 over 3 years
**Savings for 10 workstations:** $10,250 over 3 years

## Maintenance Tasks

### Daily

- Monitor logs on monitoring01 for failed login attempts
- Review nightly reset logs for failures

### Weekly

- Check OSTree updates available: `rpm-ostree upgrade --check`
- Review print job logs for anomalies

### Monthly

- Apply OSTree updates: `rpm-ostree upgrade && systemctl reboot`
- Test AD authentication with test user
- Verify printer configuration

### Quarterly

- Review access control groups in AD
- Audit log retention (ensure 90-day compliance)
- Test disaster recovery (rebuild from Ansible)

### Annually

- Review and update security policies
- Compliance audit preparation
- Update Fedora Silverblue base template

## Disaster Recovery

### Complete Workstation Rebuild

**Time to rebuild:** ~30 minutes

```bash
# 1. Destroy existing VM (if needed)
qm stop 310
qm destroy 310

# 2. Redeploy from Ansible
cd /home/richard/Documents/claude/projects/smb-office-it-blueprint/ansible/dev
ansible-playbook playbooks/deploy-and-configure-ws-reception01.yml \
  --ask-vault-pass \
  -e @vars/ad_credentials.yml

# 3. Verify deployment
ssh ansible-admin@10.0.130.25
sudo /usr/local/bin/verify-workstation.sh
```

**Result:** Identical workstation deployed from configuration as code

### User Data Recovery

**User data is NOT stored locally** - all work files are on network home directory:

```
files01:/home/sarah@corp.company.local → /home/sarah
```

- Backed up hourly on files01
- 30-day retention
- Survives workstation rebuild

## Future Enhancements

### Planned

1. **GPO Equivalent with Ansible**
   - Desktop lockdown policies
   - Application whitelisting
   - USB device control

2. **Monitoring Integration**
   - Grafana dashboards for workstation security
   - Prometheus metrics collection
   - Alertmanager integration

3. **Additional Workstation Types**
   - Finance workstation (FIN-WS01)
   - HR workstation (HR-WS01)
   - Executive workstation (EXEC-WS01)
   - Developer workstation (DEV-WS01)

4. **Zero Trust Networking**
   - Certificate-based authentication
   - Per-application network policies
   - Micro-segmentation

### Under Consideration

- **Qubes OS** for ultra-high-security workstations (Executive, Finance)
- **Wayland enforced** for additional display server security
- **Mandatory 2FA** for high-security workstation types
- **USB armory** for hardware-based authentication

## References

### Documentation

- [Fedora Silverblue Documentation](https://docs.fedoraproject.org/en-US/fedora-silverblue/)
- [SSSD Active Directory Integration](https://sssd.io/)
- [PAM Access Control](https://linux.die.net/man/5/access.conf)
- [OSTree Documentation](https://ostreedev.github.io/ostree/)

### Related Project Documents

- [Receptionist Workstation Security Flow](../docs/Receptionist-Workstation-Security-Flow.md)
- [Receptionist Use Case](../../simulated-client-project/use-cases/receptionist-use-case.md)
- [Security Policy Framework](../docs/Security-Policy-Framework-Explained.md)
- [SMB Infrastructure Planning](../../articles/03-smb-infrastructure-planning.md)

### Ansible Playbooks

- [deploy-and-configure-ws-reception01.yml](../playbooks/deploy-and-configure-ws-reception01.yml)
- [README-ws-reception01.md](../playbooks/README-ws-reception01.md)

## Contact

**Project:** SMB Office IT Blueprint
**Author:** Richard
**Repository:** [github.com/richard/smb-office-it-blueprint](https://github.com/richard/smb-office-it-blueprint)

---

**Document Version:** 1.0
**Last Updated:** 2026-01-11
**Status:** Production Ready
