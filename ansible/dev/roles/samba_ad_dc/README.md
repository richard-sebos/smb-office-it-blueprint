# Samba AD DC Role

## Overview

This Ansible role installs and configures Samba as an Active Directory Domain Controller on Ubuntu 22.04/24.04 LTS.

## Requirements

- **OS**: Ubuntu 22.04 LTS or 24.04 LTS
- **Network**: Static IP address configured
- **Hostname**: Properly configured FQDN
- **Privileges**: Root or sudo access

## Role Variables

### Required Variables

These must be defined in host_vars or passed to the role:

```yaml
# Domain configuration
domain: "corp.company.local"
realm: "CORP.COMPANY.LOCAL"
netbios_domain: "CORP"

# Host configuration (from host_vars)
hostname: "dc01"
fqdn: "dc01.corp.company.local"
network:
  ip_address: "10.0.120.10"

# Administrator password (prompted or vaulted)
admin_password: "SecurePassword123!"
```

### Optional Variables (with defaults)

```yaml
# DNS Configuration
dns_forwarder: "8.8.8.8"
dns_backend: "SAMBA_INTERNAL"

# Server Role
server_role: "dc"
use_rfc2307: true

# Feature Toggles
configure_firewall: true
configure_chrony: true
create_backup: true

# Backup Configuration
backup_dir: "/root/samba-backup-{{ ansible_date_time.date }}"
```

## Dependencies

This role depends on the following roles being run first:
- `network_config` - Static IP configuration
- `hostname_config` - Hostname and FQDN setup
- `system_update` - OS packages up to date

## Example Playbook

### Basic Usage

```yaml
- name: Configure Domain Controller
  hosts: dc01
  become: yes
  gather_facts: yes

  vars_prompt:
    - name: admin_password
      prompt: "Enter the Administrator password"
      private: yes
      confirm: yes

  roles:
    - role: samba_ad_dc
      vars:
        domain: "corp.company.local"
        realm: "CORP.COMPANY.LOCAL"
        netbios_domain: "CORP"
```

### With Ansible Vault

```yaml
# Store password in vault
# ansible-vault create group_vars/domain_controllers/vault.yml
# Content:
# vault_admin_password: "SecurePassword123!"

- name: Configure Domain Controller
  hosts: dc01
  become: yes
  gather_facts: yes

  roles:
    - role: samba_ad_dc
      vars:
        domain: "corp.company.local"
        realm: "CORP.COMPANY.LOCAL"
        netbios_domain: "CORP"
        admin_password: "{{ vault_admin_password }}"
```

## What This Role Does

1. **Validates Environment**
   - Checks for Ubuntu 22.04/24.04
   - Verifies network configuration

2. **Installs Packages**
   - Samba AD DC
   - Kerberos (krb5)
   - Winbind
   - DNS utilities
   - Time sync (chrony)

3. **Stops Conflicting Services**
   - systemd-resolved
   - smbd, nmbd, winbind (standalone mode)

4. **Backs Up Existing Configuration**
   - /etc/samba/smb.conf
   - /etc/krb5.conf
   - /var/lib/samba/

5. **Provisions Active Directory**
   - Creates domain with samba-tool
   - Configures DNS (internal)
   - Sets up Kerberos realm
   - Enables RFC2307 (POSIX attributes)

6. **Configures DNS Resolution**
   - Points to localhost (127.0.0.1)
   - Makes resolv.conf immutable

7. **Configures Firewall (UFW)**
   - Opens all required AD ports:
     - 53 (DNS)
     - 88 (Kerberos)
     - 135 (RPC)
     - 137-139 (NetBIOS)
     - 389 (LDAP)
     - 445 (SMB)
     - 464 (Kerberos password)
     - 636 (LDAPS)
     - 3268-3269 (Global Catalog)
     - 49152-65535 (Dynamic RPC)

8. **Starts Samba AD DC Service**
   - Enables samba-ad-dc
   - Starts service
   - Verifies operational status

9. **Verification Tests**
   - Service status
   - DNS resolution
   - DNS SRV records
   - Kerberos authentication
   - Domain information query

## Firewall Ports

This role opens the following ports:

| Port | Protocol | Service |
|------|----------|---------|
| 22 | TCP | SSH |
| 53 | TCP/UDP | DNS |
| 88 | TCP/UDP | Kerberos |
| 135 | TCP | RPC |
| 137 | UDP | NetBIOS Name |
| 138 | UDP | NetBIOS Datagram |
| 139 | TCP | NetBIOS Session |
| 389 | TCP/UDP | LDAP |
| 445 | TCP | SMB |
| 464 | TCP/UDP | Kerberos Password |
| 636 | TCP | LDAPS |
| 3268 | TCP | Global Catalog |
| 3269 | TCP | Global Catalog SSL |
| 49152-65535 | TCP | Dynamic RPC |

## Post-Installation Tasks

After running this role, perform these manual tasks:

### 1. Verify Domain Functionality

```bash
# Show domain level
samba-tool domain level show

# List users
samba-tool user list

# Test DNS
host -t A corp.company.local
host -t SRV _ldap._tcp.corp.company.local
```

### 2. Create Organizational Structure

```bash
# Create OUs
samba-tool ou create "OU=Users,DC=corp,DC=company,DC=local"
samba-tool ou create "OU=Computers,DC=corp,DC=company,DC=local"
samba-tool ou create "OU=Groups,DC=corp,DC=company,DC=local"
samba-tool ou create "OU=Servers,DC=corp,DC=company,DC=local"
```

### 3. Create User Accounts

```bash
# Create user
samba-tool user add jdoe \
  --given-name=John \
  --surname=Doe \
  --mail-address=jdoe@corp.company.local

# Set user properties
samba-tool user setexpiry jdoe --noexpiry
```

### 4. Create Security Groups

```bash
# Create groups
samba-tool group add ITAdmins
samba-tool group add Developers
samba-tool group add Users

# Add members
samba-tool group addmembers ITAdmins jdoe
```

### 5. Configure Secondary DC (for redundancy)

Run this role on a second server (dc02) to create a secondary domain controller for high availability.

## Troubleshooting

### Service Won't Start

```bash
# Check service status
systemctl status samba-ad-dc

# Check logs
journalctl -u samba-ad-dc -n 50

# Check Samba configuration
samba-tool testparm
```

### DNS Not Resolving

```bash
# Check DNS service
samba-tool dns query localhost corp.company.local @ ALL

# Test DNS directly
host -t A dc01.corp.company.local 127.0.0.1

# Check resolv.conf
cat /etc/resolv.conf
```

### Kerberos Issues

```bash
# Test Kerberos
kinit administrator@CORP.COMPANY.LOCAL
klist

# Check Kerberos config
cat /etc/krb5.conf
```

### Check Replication (Secondary DC)

```bash
# On both DCs
samba-tool drs showrepl
```

## Security Considerations

1. **Administrator Password**
   - Use a strong password (minimum 8 characters)
   - Store in Ansible Vault, not plaintext
   - Rotate regularly

2. **Firewall**
   - UFW is enabled by default
   - Only required AD ports are opened
   - Consider restricting to specific source networks

3. **Backup**
   - Configuration backup created automatically
   - Store backups securely offsite
   - Test restoration procedures

4. **Updates**
   - Keep Samba packages updated
   - Monitor security advisories
   - Test updates in dev environment first

## License

CC BY-SA 4.0 (Attribution-ShareAlike)

## Author

SMB Office IT Blueprint Project
