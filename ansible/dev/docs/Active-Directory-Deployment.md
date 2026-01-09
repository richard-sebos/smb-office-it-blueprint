# Active Directory Deployment Guide

## Overview

This guide covers the automated deployment of a complete Active Directory infrastructure using Ansible, with two Ubuntu-based Samba domain controllers for high availability.

## Architecture

### Domain Controllers

**dc01 - Primary Domain Controller**
- **VMID:** 110
- **IP:** 10.0.120.10/24
- **OS:** Ubuntu 22.04 LTS
- **Role:** Primary DC, DNS master
- **Resources:** 2 vCPU, 4GB RAM, 100GB disk

**dc02 - Secondary Domain Controller**
- **VMID:** 111
- **IP:** 10.0.120.11/24
- **OS:** Ubuntu 22.04 LTS
- **Role:** Secondary DC, DNS replication, failover
- **Resources:** 2 vCPU, 4GB RAM, 100GB disk

### Domain Configuration

- **Domain:** corp.company.local
- **Realm:** CORP.COMPANY.LOCAL
- **NetBIOS:** CORP
- **VLAN:** 120 (Servers)
- **DNS:** Internal Samba DNS with forwarder to 8.8.8.8

## Deployment Process

The deployment is split into two separate playbooks for clarity and control:

### Phase 1: Deploy VMs and Configure Base System

```bash
ansible-playbook playbooks/deploy-domain-controllers.yml
```

This playbook:
1. Creates both VM 110 (dc01) and VM 111 (dc02) on Proxmox
2. Configures networking (VLAN 120, static IPs)
3. Sets hostnames and FQDN
4. Updates packages
5. Installs base packages
6. Creates admin user and deploys SSH keys
7. Applies SSH hardening
8. Removes temporary management interface

**Duration:** ~15-20 minutes for both VMs

### Phase 2: Configure Active Directory

```bash
ansible-playbook playbooks/configure-active-directory.yml
```

This playbook:
1. Prompts for Administrator password (once - used for both DCs)
2. Installs Samba AD DC on dc01 (primary)
3. Provisions the Active Directory domain
4. Configures DNS, Kerberos, and firewall on dc01
5. Verifies dc01 is operational
6. Installs Samba AD DC on dc02 (secondary)
7. Joins dc02 to the domain as secondary DC
8. Configures replication between DCs
9. Runs verification tests on both

**Duration:** ~10-15 minutes for both DCs

## Files Created

### Ansible Role Structure

```
roles/samba_ad_dc/
├── README.md                      # Role documentation
├── defaults/
│   └── main.yml                   # Default variables
├── tasks/
│   ├── main.yml                   # Main installation tasks
│   ├── configure-firewall.yml     # UFW firewall configuration
│   └── verify.yml                 # Post-install verification
└── templates/
    └── resolv.conf.j2             # DNS configuration template
```

### Playbooks

```
playbooks/
├── deploy-domain-controllers.yml   # VM deployment + base config
└── configure-active-directory.yml  # AD installation + config
```

### Host Variables

```
host_vars/
├── dc01.yml                        # Primary DC configuration
└── dc02.yml                        # Secondary DC configuration
```

## Usage

### Full Deployment (Fresh Install)

```bash
# Step 1: Deploy VMs and configure base system
cd /opt/smb-ansible/dev
ansible-playbook playbooks/deploy-domain-controllers.yml

# Step 2: Configure Active Directory
ansible-playbook playbooks/configure-active-directory.yml
# When prompted, enter Administrator password (minimum 8 characters)
```

### Verify Deployment

```bash
# SSH to dc01
ssh richard@10.0.120.10

# Check service status
sudo systemctl status samba-ad-dc

# Verify domain
samba-tool domain level show

# List users
samba-tool user list

# Check DNS
host -t A corp.company.local
host -t SRV _ldap._tcp.corp.company.local

# Test Kerberos
kinit administrator@CORP.COMPANY.LOCAL
klist
kdestroy

# Check replication (on both DCs)
samba-tool drs showrepl
```

## Post-Deployment Tasks

### 1. Create Organizational Units

```bash
# Connect to dc01
ssh richard@10.0.120.10

# Create standard OU structure
sudo samba-tool ou create "OU=Users,DC=corp,DC=company,DC=local"
sudo samba-tool ou create "OU=Computers,DC=corp,DC=company,DC=local"
sudo samba-tool ou create "OU=Groups,DC=corp,DC=company,DC=local"
sudo samba-tool ou create "OU=Servers,DC=corp,DC=company,DC=local"
sudo samba-tool ou create "OU=Workstations,DC=corp,DC=company,DC=local"
```

### 2. Create Security Groups

```bash
# IT and administrative groups
sudo samba-tool group add "Domain Admins"  # Usually exists
sudo samba-tool group add "IT Admins"
sudo samba-tool group add "Help Desk"

# Departmental groups
sudo samba-tool group add "Accounting"
sudo samba-tool group add "Sales"
sudo samba-tool group add "Engineering"

# Access control groups
sudo samba-tool group add "VPN Users"
sudo samba-tool group add "Remote Desktop Users"
sudo samba-tool group add "File Server Access"
```

### 3. Create User Accounts

```bash
# Create user with full attributes
sudo samba-tool user create jdoe \
  --given-name="John" \
  --surname="Doe" \
  --mail-address="jdoe@corp.company.local" \
  --job-title="Systems Administrator" \
  --department="IT"

# Set password to never expire (for service accounts)
sudo samba-tool user setexpiry jdoe --noexpiry

# Add user to groups
sudo samba-tool group addmembers "IT Admins" jdoe
sudo samba-tool group addmembers "Domain Admins" jdoe
```

### 4. Configure Group Policy (Optional)

Group Policy requires Windows RSAT tools or alternative tools:

```bash
# Option 1: Use Windows RSAT
# Install "Remote Server Administration Tools" on Windows
# Connect to dc01.corp.company.local with GPMC

# Option 2: Use Samba's basic GPO tools (limited functionality)
sudo samba-tool gpo create "Workstation Security Policy"
sudo samba-tool gpo listall
```

### 5. Join Workstations to Domain

**For Linux Workstations:**
```bash
# On the workstation (e.g., ws-admin01)
# This will be covered in a separate playbook/role
```

**For Windows Workstations:**
```powershell
# Set DNS to point to DCs
Set-DnsClientServerAddress -InterfaceAlias "Ethernet" `
  -ServerAddresses "10.0.120.10","10.0.120.11"

# Join domain
Add-Computer -DomainName corp.company.local -Restart
```

## Security Considerations

### Password Policy

The default Samba AD password policy:
- Minimum length: 7 characters
- Complexity: Enabled (uppercase, lowercase, numbers, special chars)
- History: 24 passwords remembered
- Max age: 42 days
- Lockout threshold: 5 failed attempts

Modify with:
```bash
samba-tool domain passwordsettings set --complexity=on
samba-tool domain passwordsettings set --min-pwd-length=12
samba-tool domain passwordsettings set --max-pwd-age=90
```

### Firewall Rules

UFW is configured with these rules on both DCs:
- SSH (22) - Management access
- DNS (53 TCP/UDP) - Name resolution
- Kerberos (88 TCP/UDP) - Authentication
- RPC (135 TCP) - Remote procedures
- NetBIOS (137-139) - Legacy Windows support
- LDAP (389 TCP/UDP) - Directory queries
- SMB (445 TCP) - File sharing and domain communications
- Kerberos Password (464 TCP/UDP) - Password changes
- LDAPS (636 TCP) - Secure LDAP
- Global Catalog (3268-3269 TCP) - Forest-wide searches
- Dynamic RPC (49152-65535 TCP) - Dynamic port allocation

### Backup Strategy

**What to Backup:**
1. Domain database: `/var/lib/samba/private/sam.ldb`
2. Samba configuration: `/etc/samba/smb.conf`
3. Kerberos config: `/etc/krb5.conf`
4. DNS zones: `/var/lib/samba/private/dns/*`
5. Full Samba directory: `/var/lib/samba/`

**Automated Backups:**
```bash
# Create backup script (to be run from backup-server)
#!/bin/bash
BACKUP_DIR="/backup/dc-backups/$(date +%Y%m%d)"
mkdir -p "$BACKUP_DIR"

# Backup dc01
ssh root@10.0.120.10 "tar czf - /var/lib/samba /etc/samba /etc/krb5.conf" \
  > "$BACKUP_DIR/dc01-backup.tar.gz"

# Backup dc02
ssh root@10.0.120.11 "tar czf - /var/lib/samba /etc/samba /etc/krb5.conf" \
  > "$BACKUP_DIR/dc02-backup.tar.gz"

# Retention: Keep 30 days
find /backup/dc-backups -type d -mtime +30 -exec rm -rf {} \;
```

## Disaster Recovery

### Scenario 1: Primary DC (dc01) Failure

If dc01 fails:
1. dc02 automatically handles all authentication and DNS
2. No immediate action required - domain continues to function
3. Restore dc01 from backup or rebuild when convenient

**To rebuild dc01:**
```bash
# Deploy new VM
ansible-playbook playbooks/deploy-domain-controllers.yml --limit dc01

# Join as additional DC (don't provision new domain)
# Manually join to existing domain or create specialized playbook
```

### Scenario 2: Both DCs Fail (Catastrophic)

If both DCs are lost:
1. Deploy new dc01 from playbook
2. Restore Samba database from backup:
```bash
# Stop samba
systemctl stop samba-ad-dc

# Restore database
tar xzf dc01-backup.tar.gz -C /

# Start samba
systemctl start samba-ad-dc

# Verify
samba-tool domain level show
samba-tool user list
```
3. Deploy dc02 and join to restored domain

### Scenario 3: Corrupted Domain Database

If the domain database becomes corrupted:
1. Stop Samba on affected DC
2. Restore from last known good backup
3. Check replication health
4. Force replication if needed:
```bash
samba-tool drs replicate dc02 dc01 DC=corp,DC=company,DC=local
```

## Monitoring

### Key Metrics to Monitor

1. **Service Health**
```bash
# Check service status
systemctl is-active samba-ad-dc

# Check if listening on ports
netstat -tlnp | grep samba
```

2. **Replication Status**
```bash
# Check replication
samba-tool drs showrepl

# Look for:
# - Last success time (should be recent)
# - Consecutive failures (should be 0)
```

3. **DNS Functionality**
```bash
# Test DNS resolution
dig @127.0.0.1 corp.company.local
dig @127.0.0.1 _ldap._tcp.corp.company.local SRV
```

4. **Authentication**
```bash
# Test Kerberos
echo "password" | kinit administrator@CORP.COMPANY.LOCAL
```

5. **Disk Space**
```bash
# Monitor /var/lib/samba
df -h /var/lib/samba
```

### Alerting

Set up alerts for:
- samba-ad-dc service down
- Replication failures
- Disk space >80% on /var/lib/samba
- Failed login attempts (security)
- DNS resolution failures

## Troubleshooting

### Common Issues

#### Issue 1: DNS Not Resolving

**Symptoms:** Clients can't resolve domain names

**Diagnosis:**
```bash
# On DC
host -t A corp.company.local 127.0.0.1
systemctl status samba-ad-dc
```

**Resolution:**
```bash
# Check resolv.conf
cat /etc/resolv.conf  # Should point to 127.0.0.1

# Restart Samba
systemctl restart samba-ad-dc

# Check DNS zones
samba-tool dns query localhost corp.company.local @ ALL
```

#### Issue 2: Replication Not Working

**Symptoms:** Changes on dc01 not appearing on dc02

**Diagnosis:**
```bash
# Check replication status
samba-tool drs showrepl

# Look for errors in output
```

**Resolution:**
```bash
# Force replication
samba-tool drs replicate dc02 dc01 DC=corp,DC=company,DC=local

# Check if firewalls allow replication traffic
ufw status
```

#### Issue 3: Client Can't Join Domain

**Symptoms:** "Domain controller could not be contacted" error

**Diagnosis:**
```bash
# On client, test DNS
nslookup corp.company.local
nslookup dc01.corp.company.local

# Test LDAP
ldapsearch -H ldap://10.0.120.10 -b "DC=corp,DC=company,DC=local"
```

**Resolution:**
```bash
# Ensure client DNS points to DCs
# /etc/resolv.conf or DHCP
nameserver 10.0.120.10
nameserver 10.0.120.11

# Test Kerberos
kinit administrator@CORP.COMPANY.LOCAL
```

#### Issue 4: Time Sync Issues

**Symptoms:** Kerberos errors, replication problems

**Diagnosis:**
```bash
# Check time on both DCs
date
timedatectl

# Time difference should be <5 minutes
```

**Resolution:**
```bash
# Sync with NTP
systemctl restart chrony
chronyc sources
```

## Performance Tuning

### For Large Environments (500+ users)

1. **Increase Samba resources:**
```bash
# Edit /etc/samba/smb.conf
[global]
    max xmit = 65535
    min receivefile size = 16384
    use sendfile = yes
```

2. **Optimize DNS:**
```bash
# If using BIND instead of internal DNS
# Configure DNS forwarding and caching
```

3. **VM Resources:**
- CPU: 4 cores (from 2)
- RAM: 8GB (from 4GB)
- Disk: SSD for /var/lib/samba

## Next Steps

After AD is deployed:

1. ☐ Create organizational structure (OUs)
2. ☐ Create security groups
3. ☐ Create user accounts
4. ☐ Join workstations to domain
5. ☐ Configure Group Policy (if needed)
6. ☐ Set up automated backups
7. ☐ Configure monitoring and alerting
8. ☐ Document procedures for team
9. ☐ Test disaster recovery procedures

## Additional Resources

- [Samba Wiki - Active Directory](https://wiki.samba.org/index.php/Setting_up_Samba_as_an_Active_Directory_Domain_Controller)
- [Ubuntu Samba Documentation](https://ubuntu.com/server/docs/samba-active-directory)
- [Samba AD DC Troubleshooting](https://wiki.samba.org/index.php/Troubleshooting_Samba_Domain_Members)

---

**Document Version:** 1.0
**Last Updated:** 2026-01-04
**License:** CC BY-SA 4.0
