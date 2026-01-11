# Deploying ws-reception01 Receptionist Workstation

## Overview

This playbook deploys and configures a **Fedora Silverblue** receptionist workstation with:
- **Active Directory integration** (SSSD + Kerberos)
- **Group-based access control** (Only Receptionists group can log in)
- **Nightly automated reset** (2 AM daily wipe and reboot)
- **Network printer configuration** (HP printers on IoT VLAN)
- **Remote logging** (All events to monitoring01)
- **Immutable OS** (Read-only root filesystem)

## Prerequisites

### 1. Proxmox Environment
- Proxmox VE host accessible
- Network configured with VLAN 130 (Workstations)
- Storage available for VM deployment

### 2. Fedora Silverblue Template
Create a Fedora Silverblue template (VMID 9300) on Proxmox:

```bash
# On Proxmox host
# Download Fedora Silverblue 41 cloud image
wget https://download.fedoraproject.org/pub/fedora/linux/releases/41/Cloud/x86_64/images/Fedora-Silverblue-41-*.qcow2

# Create VM template
qm create 9300 --name fedora-silverblue-41-template --memory 2048 --cores 2 --net0 virtio,bridge=vmbr1
qm importdisk 9300 Fedora-Silverblue-41-*.qcow2 vmDrive
qm set 9300 --scsihw virtio-scsi-pci --scsi0 vmDrive:vm-9300-disk-0
qm set 9300 --ide2 vmDrive:cloudinit
qm set 9300 --boot c --bootdisk scsi0
qm set 9300 --serial0 socket --vga serial0
qm set 9300 --agent enabled=1
qm template 9300
```

### 3. Active Directory Domain Controllers
- dc01.corp.company.local (10.0.120.10)
- dc02.corp.company.local (10.0.120.11)
- Domain: corp.company.local
- AD group: "Receptionists" exists with members

### 4. Monitoring Server
- monitoring01 (10.0.120.60)
- Rsyslog configured to receive logs on port 514/tcp
- Log directory: `/var/log/workstations/ws-reception01/`

### 5. File Server (Optional for network home directories)
- files01.corp.company.local (10.0.120.50)
- SMB/CIFS shares available

### 6. Ansible Requirements
- Ansible 2.9+
- Python 3.6+
- Proxmox API access configured

## Configuration

### Host Variables

Edit `host_vars/ws-reception01.yml` to customize:

```yaml
# Network
network:
  ip_address: 10.0.130.25  # Production IP
  mgmt_ip: 192.168.35.135  # Temporary management IP

# AD Integration
ad_integration:
  domain: corp.company.local
  realm: CORP.COMPANY.LOCAL

# Access Control
access_control:
  allowed_ad_groups:
    - Receptionists
    - GG-Reception

# Security
session_security:
  idle_timeout_minutes: 3  # Aggressive for public area

nightly_reset:
  enabled: true
  reset_time: "02:00"

# Printers
printers:
  - name: HP-Reception-Printer
    ip: 10.0.140.55
    default: true
```

### Inventory

Add to `inventory/hosts.yml`:

```yaml
[workstations]
ws-reception01 ansible_host=192.168.35.135 ansible_user=ansible-admin
```

## Deployment

### Step 1: Deploy VM and Base Configuration

```bash
cd /home/richard/Documents/claude/projects/smb-office-it-blueprint/ansible/dev

# Deploy VM and configure base system
ansible-playbook playbooks/deploy-and-configure-ws-reception01.yml
```

### Step 2: Join Active Directory

**Important:** You need to provide AD credentials to join the domain.

Create a vault file with AD admin credentials:

```bash
ansible-vault create vars/ad_credentials.yml
```

Add the following content:

```yaml
---
ad_join_user: "Administrator"
ad_join_password: "YourADPassword"
test_ad_user: "sarah"  # Test user in Receptionists group
```

Run playbook with vault:

```bash
ansible-playbook playbooks/deploy-and-configure-ws-reception01.yml \
  --ask-vault-pass \
  -e @vars/ad_credentials.yml
```

### Step 3: Verify Deployment

SSH to the workstation:

```bash
ssh ansible-admin@10.0.130.25
```

Run verification script:

```bash
sudo /usr/local/bin/verify-workstation.sh
```

Expected output:

```
=========================================
Workstation Verification Script
Hostname: ws-reception01
=========================================

Network Configuration:
inet 10.0.130.25/24 brd 10.0.130.255 scope global ens18

AD Integration:
corp.company.local
  configured: kerberos-member
  server-software: active-directory
  client-software: sssd

SSSD Status:
● sssd.service - System Security Services Daemon
   Active: active (running)

Printer Status:
printer HP-Reception-Printer is idle.  enabled since [date]
system default destination: HP-Reception-Printer

Nightly Reset Timer:
● workstation-nightly-reset.timer
   Active: active (waiting)
   Trigger: *-*-* 02:00:00

OSTree Status:
● fedora:fedora/41/x86_64/silverblue
                  Version: 41.20260110.0 (2026-01-10)
```

## Testing

### Test 1: AD Authentication

Try logging in as a receptionist:

```bash
# From GDM login screen
Username: sarah@corp.company.local
Password: [sarah's AD password]
```

Should succeed if sarah is in "Receptionists" group.

### Test 2: Access Control (Unauthorized User)

Try logging in as a non-receptionist:

```bash
# From GDM login screen
Username: david@corp.company.local  # Partner, not receptionist
Password: [david's AD password]
```

Should fail with: "You are not authorized to log in to this workstation"

Check monitoring01 logs:

```bash
# On monitoring01
tail -f /var/log/workstations/ws-reception01/$(date +%Y%m%d)/auth.log
```

Should see:

```
[timestamp] ws-reception01 pam_access: Access DENIED for david@corp.company.local (not in Receptionists group)
```

### Test 3: Nightly Reset

Manually trigger reset (warning: will reboot!):

```bash
sudo systemctl start workstation-nightly-reset.service
```

Check reset logs on monitoring01:

```bash
# On monitoring01
cat /var/log/workstations/ws-reception01/reset-logs/reset-$(date +%Y%m%d).log
```

### Test 4: Printer Configuration

```bash
lpstat -p -d
lp -d HP-Reception-Printer /etc/hosts  # Test print
```

### Test 5: Remote Logging

Generate auth event:

```bash
sudo su - root
```

Check monitoring01:

```bash
# On monitoring01
tail -f /var/log/workstations/ws-reception01/$(date +%Y%m%d)/auth.log
```

Should see the sudo event logged in real-time.

## Roles Used

| Role | Purpose |
|------|---------|
| `proxmox_vm_deploy` | Deploy VM on Proxmox |
| `network_config` | Configure network settings |
| `hostname_config` | Set hostname and FQDN |
| `system_update` | Update OS packages |
| `silverblue_ad_integration` | Configure SSSD + Kerberos for AD |
| `silverblue_pam_access` | Configure PAM access control |
| `silverblue_printer_config` | Configure network printers |
| `silverblue_nightly_reset` | Configure nightly automated reset |

## Security Flow

### Login Flow

```
User enters credentials at GDM
    ↓
PAM authenticates against SSSD
    ↓
SSSD queries dc01/dc02 (Kerberos)
    ↓
dc01 validates credentials
    ↓
PAM checks access.conf
    ↓
Is user in "Receptionists" group?
    ↓ YES              ↓ NO
Login succeeds    Login denied
    ↓
Event logged to monitoring01
```

### Nightly Reset Flow

```
02:00 AM - Timer triggers
    ↓
1. Sync logs to monitoring01 (rsync)
    ↓
2. Clear /home, /tmp, browser data
    ↓
3. rpm-ostree reset (immutable OS)
    ↓
4. Reboot
    ↓
02:02 AM - System boots clean
    ↓
Fresh system, identical to deployment
```

## Troubleshooting

### AD Join Fails

```bash
# Check realm discovery
realm discover corp.company.local

# Check DNS resolution
dig dc01.corp.company.local

# Check Kerberos
kinit Administrator@CORP.COMPANY.LOCAL
klist
```

### SSSD Not Working

```bash
# Check SSSD status
systemctl status sssd

# Check SSSD logs
journalctl -u sssd -f

# Test AD user lookup
id sarah@corp.company.local
getent passwd sarah@corp.company.local
```

### PAM Access Control Not Working

```bash
# Check access.conf syntax
cat /etc/security/access.conf

# Check PAM configuration
cat /etc/pam.d/gdm-password | grep pam_access

# Test as root
pamtester gdm-password sarah@corp.company.local authenticate
```

### Printers Not Working

```bash
# Check CUPS status
systemctl status cups

# List printers
lpstat -p -d

# Check printer connectivity
ping 10.0.140.55

# Check firewall
firewall-cmd --list-all
```

### Nightly Reset Not Running

```bash
# Check timer status
systemctl status workstation-nightly-reset.timer

# Check timer schedule
systemctl list-timers workstation-nightly-reset.timer

# Check last run
journalctl -u workstation-nightly-reset.service
```

## Maintenance

### Updating OSTree Image

```bash
# Check for updates
rpm-ostree upgrade --check

# Apply updates
rpm-ostree upgrade

# Reboot to new deployment
systemctl reboot
```

### Adding New Printers

Edit `host_vars/ws-reception01.yml`:

```yaml
printers:
  - name: HP-Reception-Printer
    ip: 10.0.140.55
    default: true
  - name: New-Printer
    ip: 10.0.140.60
    default: false
```

Re-run playbook:

```bash
ansible-playbook playbooks/deploy-and-configure-ws-reception01.yml --tags printers
```

### Changing Allowed Groups

Edit `host_vars/ws-reception01.yml`:

```yaml
access_control:
  allowed_ad_groups:
    - Receptionists
    - GG-Reception
    - NewGroup  # Add new group
```

Re-run playbook:

```bash
ansible-playbook playbooks/deploy-and-configure-ws-reception01.yml --tags pam_access
```

## Files Created

```
ansible/dev/
├── host_vars/
│   └── ws-reception01.yml
├── playbooks/
│   └── deploy-and-configure-ws-reception01.yml
└── roles/
    ├── silverblue_ad_integration/
    │   ├── defaults/main.yml
    │   ├── handlers/main.yml
    │   ├── tasks/main.yml
    │   └── templates/
    │       ├── krb5.conf.j2
    │       ├── sssd.conf.j2
    │       └── rsyslog-remote.conf.j2
    ├── silverblue_pam_access/
    │   ├── defaults/main.yml
    │   ├── tasks/main.yml
    │   └── templates/
    │       └── access.conf.j2
    ├── silverblue_printer_config/
    │   ├── defaults/main.yml
    │   ├── handlers/main.yml
    │   ├── tasks/
    │   │   ├── main.yml
    │   │   └── configure_printer.yml
    │   └── templates/
    └── silverblue_nightly_reset/
        ├── defaults/main.yml
        ├── handlers/main.yml
        ├── tasks/main.yml
        └── templates/
            ├── workstation-reset.sh.j2
            ├── workstation-nightly-reset.service.j2
            └── workstation-nightly-reset.timer.j2
```

## Next Steps

1. **Create additional workstation types:**
   - Finance workstation (FIN-WS01)
   - HR workstation (HR-WS01)
   - Executive workstation (EXEC-WS01)

2. **Implement GPO alternative:**
   - Use Ansible to enforce desktop policies
   - Create workstation-specific policy roles

3. **Add monitoring integration:**
   - Configure monitoring01 to alert on failed logins
   - Create dashboards for workstation security events

4. **Document compliance:**
   - Create audit reports from monitoring01 logs
   - Document HIPAA/SOC2/PCI-DSS readiness
