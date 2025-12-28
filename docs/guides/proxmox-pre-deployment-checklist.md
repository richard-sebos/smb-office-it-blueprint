# Proxmox Pre-Deployment Checklist

**Project:** SMB Office IT Blueprint
**Last Updated:** 2025-12-28
**Purpose:** Ensure Proxmox is optimally configured before VM deployment

## Overview

This checklist covers important Proxmox configurations that should be verified or implemented before deploying production VMs.

## Quick Status Check

Run this command on your Proxmox host to get current status:

```bash
ssh root@192.168.35.20

# System info
pveversion
df -h
free -h
ip addr | grep vmbr
pvesm status
```

## 1. Storage Configuration

### ✓ Already Configured
- [x] Primary storage pool: `vmDrive` (ZFS)
- [x] Templates created on `vmDrive`

### Recommended Additional Storage

**Check current storage:**
```bash
pvesm status
```

**Consider adding:**

#### Local Backup Storage
Store VM backups separately from VM disks for safety.

```bash
# Create backup directory
mkdir -p /var/lib/vz/backup

# Verify it's already configured
pvesm status | grep backup
```

**Expected:** Should see `local` storage with content type `backup`

#### ISO Storage
Verify ISO storage exists:

```bash
pvesm status | grep iso
```

**Expected:** Should see storage with `iso` content type

#### Snippets Storage (for cloud-init)
Verify snippets storage:

```bash
pvesm status | grep snippets
```

**If missing, enable snippets on local storage:**
```bash
pvesm set local --content vztmpl,iso,backup,snippets
```

### Storage Optimization

**Check ZFS ARC (cache) usage:**
```bash
arc_summary | grep "ARC size"
```

**Adjust ZFS ARC if needed** (optional):
Edit `/etc/modprobe.d/zfs.conf`:
```bash
# Limit ARC to 8GB (adjust based on your RAM)
options zfs zfs_arc_max=8589934592
```

Then update and reboot:
```bash
update-initramfs -u
reboot
```

## 2. Network Configuration

### ✓ Already Configured
- [x] vmbr0: Lab network (192.168.35.0/24)
- [x] vmbr1: Internal network (VLAN-aware)
- [x] VLANs 110, 120, 130, 140, 150 configured
- [x] Proxmox IPs: 10.0.110.2, 10.0.120.2

### Verify Network Status

```bash
# Check all interfaces are up
ip link show | grep -E "vmbr|state"

# Check VLAN interfaces
ip addr show | grep vmbr1

# Test connectivity
ping -c 2 10.0.110.1  # OPNsense VLAN 110
ping -c 2 10.0.120.1  # OPNsense VLAN 120
ping -c 2 8.8.8.8     # Internet
```

### Network Performance (Optional)

**Enable jumbo frames** if your network supports it:

```bash
# Check current MTU
ip link show vmbr1 | grep mtu

# Set jumbo frames (9000 MTU) - only if your switch supports it
# Edit /etc/network/interfaces
# Add: mtu 9000 to vmbr1
```

**Not recommended unless:** You have 10GbE and managed switches with jumbo frame support.

## 3. Resource Pools

### ✓ Should Already Exist
Created by the `create-resource-pools.yml` playbook:
- infrastructure
- production
- dmz
- templates
- development

**Verify:**
```bash
pvesh get /pools
```

**If missing, create them:**
```bash
ansible-playbook playbooks/create-resource-pools.yml
```

## 4. User Management and Security

### SSH Key Authentication

**Already configured** if you're using Ansible, but verify:

```bash
# On your workstation
ssh -v root@192.168.35.20 2>&1 | grep "Authenticating"
```

Should show: `Authenticating to 192.168.35.20:22 as 'root'` with key authentication.

### Create Non-Root Admin User (Recommended)

**Current:** Using root account

**Recommended:** Create dedicated admin account:

```bash
# On Proxmox host
pveum user add admin@pve
pveum acl modify / --user admin@pve --role Administrator

# Set password
pveum passwd admin@pve

# Or use SSH key
mkdir -p /home/admin/.ssh
cp /root/.ssh/authorized_keys /home/admin/.ssh/
chown -R admin:admin /home/admin/.ssh
```

**Update Ansible inventory** if you create a new user:
```yaml
# hosts.yml
pve:
  ansible_user: admin
```

### API Token (Already Configured)

**Already have:** `ansible-project@pve` with token

**Verify it works:**
```bash
# Should return node information
curl -k -H "Authorization: PVEAPIToken=ansible-project@pve\!project-automation=YOUR_TOKEN" \
  https://192.168.35.20:8006/api2/json/nodes
```

### Firewall Configuration

**Check Proxmox firewall status:**
```bash
# Datacenter firewall
pvesh get /cluster/firewall/options

# Node firewall
pvesh get /nodes/pve/firewall/options
```

**Recommendation:** Keep Proxmox firewall **disabled** for now (it's complex and can block VM traffic).

**Verify it's disabled:**
```bash
pvesh get /cluster/firewall/options | grep enable
# Should show: "enable": 0
```

## 5. Backup Configuration

### Current State
- No automated backups configured yet

### Recommended: Set Up Automated Backups

**Option 1: Via Web UI**
1. Navigate: **Datacenter → Backup**
2. Click **Add**
3. Configure:
   - Storage: `local`
   - Schedule: Daily at 2 AM
   - Selection mode: `All`
   - Compression: `ZSTD`
   - Mode: `Snapshot`
   - Retention: `Keep last 7`

**Option 2: Via CLI**
```bash
# Create backup job
pvesh create /cluster/backup --schedule "0 2 * * *" \
  --storage local \
  --mode snapshot \
  --compress zstd \
  --all 1 \
  --enabled 1 \
  --prune-backups "keep-last=7"
```

**Test backup manually:**
```bash
# Backup VM 100 (OPNsense)
vzdump 100 --mode snapshot --compress zstd --storage local
```

### Backup Strategy Recommendations

| VM Type | Backup Frequency | Retention |
|---------|-----------------|-----------|
| Templates | Weekly | 4 weeks |
| Infrastructure (Ansible, Monitoring) | Daily | 7 days |
| Domain Controllers | Daily | 14 days |
| Database Servers | Daily + transaction logs | 14 days |
| Application Servers | Daily | 7 days |
| Workstations | Weekly | 4 weeks |

## 6. Update Management

### Current Proxmox Version

```bash
pveversion --verbose
```

### Check for Updates

```bash
# Update package lists
apt update

# Check available updates
apt list --upgradable
```

### Update Strategy

**Before deploying VMs:**
```bash
# Update Proxmox (safe to do now before VMs are deployed)
apt update
apt dist-upgrade -y

# Reboot if kernel was updated
reboot
```

**After VMs are deployed:**
- Schedule updates during maintenance windows
- Test updates on non-production systems first
- Take snapshots before major updates

### Enable Enterprise Repository (Optional)

**Current:** Using free/no-subscription repository

**If you have a subscription:**
```bash
# Edit sources
nano /etc/apt/sources.list.d/pve-enterprise.list
# Uncomment enterprise repository

# Remove no-subscription nag
echo "DPkg::Post-Invoke { \"dpkg -V proxmox-widget-toolkit | grep -q '/proxmoxlib\.js$'; if [ \$? -eq 1 ]; then { echo 'Removing subscription nag from UI...'; sed -i '/data.status/{s/\!//;s/Active/NoMoreNagging/}' /usr/share/javascript/proxmox-widget-toolkit/proxmoxlib.js; }; fi\"; };" > /etc/apt/apt.conf.d/no-nag-script
apt --reinstall install proxmox-widget-toolkit
```

## 7. Monitoring and Alerting

### Current State
- Built-in Proxmox metrics (CPU, RAM, storage)
- No external monitoring yet

### Enable Email Notifications

**Configure email for alerts:**

Via Web UI:
1. Navigate: **Datacenter → Options**
2. Set **Email from address:** `proxmox@yourdomain.com`
3. Set **Email server:** Your SMTP server

Via CLI:
```bash
# Using external SMTP (e.g., Gmail)
apt install -y libsasl2-modules
nano /etc/postfix/main.cf

# Add:
relayhost = [smtp.gmail.com]:587
smtp_sasl_auth_enable = yes
smtp_sasl_password_maps = hash:/etc/postfix/sasl_passwd
smtp_sasl_security_options = noanonymous
smtp_tls_security_level = encrypt

# Create password file
echo "[smtp.gmail.com]:587 your-email@gmail.com:app-password" > /etc/postfix/sasl_passwd
chmod 600 /etc/postfix/sasl_passwd
postmap /etc/postfix/sasl_passwd

# Restart postfix
systemctl restart postfix

# Test
echo "Test email from Proxmox" | mail -s "Proxmox Test" your-email@gmail.com
```

### Set Up Monitoring VM (Recommended)

Deploy a monitoring VM (Zabbix, Prometheus, or Grafana) as part of your infrastructure deployment.

**Planned:** VM 111 on VLAN 110 for monitoring

## 8. High Availability (HA)

### Current State
- Single Proxmox host
- No HA configured (not needed for lab/SMB)

### Future Considerations

**If you add more Proxmox nodes:**
- Configure Proxmox cluster
- Set up shared storage (Ceph, NFS, or iSCSI)
- Enable HA for critical VMs
- Configure fencing

**Not recommended for:** Single-host setups or small labs

## 9. Performance Tuning

### CPU Governor

**Check current CPU governor:**
```bash
cat /sys/devices/system/cpu/cpu*/cpufreq/scaling_governor
```

**For better performance:**
```bash
# Set to performance mode
echo performance | tee /sys/devices/system/cpu/cpu*/cpufreq/scaling_governor

# Make permanent
apt install -y cpufrequtils
echo 'GOVERNOR="performance"' > /etc/default/cpufrequtils
systemctl restart cpufrequtils
```

### I/O Scheduler

**Check current I/O scheduler:**
```bash
cat /sys/block/sda/queue/scheduler
```

**For SSDs/NVMe:**
```bash
# Use none or mq-deadline
echo none > /sys/block/sda/queue/scheduler

# Make permanent
nano /etc/udev/rules.d/60-scheduler.rules
# Add:
ACTION=="add|change", KERNEL=="sd[a-z]|nvme[0-9]n[0-9]", ATTR{queue/scheduler}="none"
```

### Disable Swap (Optional)

**For systems with sufficient RAM:**
```bash
# Check swap
free -h

# Disable swap
swapoff -a

# Make permanent
nano /etc/fstab
# Comment out swap line
```

**Only do this if:** You have plenty of RAM (32GB+)

## 10. Time Synchronization

### Verify NTP is Working

```bash
# Check systemd-timesyncd
timedatectl status

# Or check chrony (if installed)
chronyc tracking
```

**Should show:** System clock synchronized: yes

### Configure NTP Servers

```bash
# Edit NTP configuration
nano /etc/systemd/timesyncd.conf

# Add reliable NTP servers
[Time]
NTP=pool.ntp.org time.google.com time.cloudflare.com

# Restart service
systemctl restart systemd-timesyncd

# Verify
timedatectl show-timesync --all
```

## 11. Logging and Audit

### Check Disk Space for Logs

```bash
df -h /var/log
```

**Should have:** At least 5GB free

### Configure Log Rotation

**Verify logrotate is configured:**
```bash
cat /etc/logrotate.d/pve
```

### Centralized Logging (Optional)

**Send Proxmox logs to syslog server:**
```bash
# Edit rsyslog
nano /etc/rsyslog.d/50-default.conf

# Add remote syslog server
*.* @@10.0.110.11:514

# Restart rsyslog
systemctl restart rsyslog
```

**Note:** Deploy a syslog server VM first

## 12. VM Templates Verification

### Verify Templates Exist

```bash
qm list | grep template

# Should show:
# 9000 - ubuntu-2204-template
# 9100 - debian-12-template
# 9200 - rocky-9-template
```

### Verify Templates are Configured

```bash
# Check each template
for vmid in 9000 9100 9200; do
    echo "=== Template $vmid ==="
    qm config $vmid | grep -E "name|template|cores|memory|scsi0|ide2|net0"
done
```

**Should show:**
- `template: 1`
- Cloud-init drive (`ide2: cloudinit`)
- Network on vmbr1
- Reasonable resources (2 cores, 2GB RAM)

## 13. Cloud-Init Configuration

### Verify Cloud-Init Snippets Directory

```bash
ls -la /var/lib/vz/snippets/
```

**Should exist** for custom cloud-init configurations.

### Create Default Cloud-Init User Config (Optional)

```bash
cat > /var/lib/vz/snippets/cloud-init-user.yml << EOF
#cloud-config
users:
  - name: ubuntu
    sudo: ALL=(ALL) NOPASSWD:ALL
    groups: sudo
    shell: /bin/bash
    ssh_authorized_keys:
      - $(cat ~/.ssh/id_rsa.pub)

package_update: true
package_upgrade: true

packages:
  - qemu-guest-agent
  - curl
  - vim
  - htop
  - net-tools

runcmd:
  - systemctl enable qemu-guest-agent
  - systemctl start qemu-guest-agent
EOF
```

## Pre-Deployment Checklist Summary

Before deploying VMs, verify:

- [ ] Storage configured and healthy (ZFS pool `vmDrive`)
- [ ] Network configured and tested (VLANs 110-150, OPNsense routing)
- [ ] Resource pools created (infrastructure, production, etc.)
- [ ] API token working for Ansible
- [ ] Templates exist and are configured (9000, 9100, 9200)
- [ ] Backup strategy planned (manual for now, automated later)
- [ ] Updates applied to Proxmox host
- [ ] Time synchronization working
- [ ] Email notifications configured (optional)
- [ ] Monitoring plan in place
- [ ] SSH access secured with keys
- [ ] Performance tuning applied (CPU governor, I/O scheduler)

## Quick Verification Script

Run this to check everything at once:

```bash
#!/bin/bash
echo "=== Proxmox Pre-Deployment Check ==="
echo ""

echo "1. Proxmox Version:"
pveversion

echo ""
echo "2. Storage Status:"
pvesm status

echo ""
echo "3. Network Interfaces:"
ip addr show | grep -E "vmbr1\.(110|120)" | grep inet

echo ""
echo "4. Resource Pools:"
pvesh get /pools --output-format json-pretty | grep poolid

echo ""
echo "5. Templates:"
qm list | grep template

echo ""
echo "6. OPNsense Connectivity:"
ping -c 2 10.0.110.1 && echo "✓ VLAN 110 reachable"
ping -c 2 10.0.120.1 && echo "✓ VLAN 120 reachable"

echo ""
echo "7. Internet Connectivity:"
ping -c 2 8.8.8.8 && echo "✓ Internet reachable"

echo ""
echo "8. Time Sync:"
timedatectl status | grep "System clock synchronized"

echo ""
echo "9. Disk Space:"
df -h | grep -E "Filesystem|vmDrive|/var/lib/vz"

echo ""
echo "10. Memory:"
free -h

echo ""
echo "=== Pre-Deployment Check Complete ==="
```

Save this as `/root/pre-deployment-check.sh` and run it:

```bash
chmod +x /root/pre-deployment-check.sh
/root/pre-deployment-check.sh
```

## Recommended: Optional but Useful

### Install Useful Packages

```bash
apt install -y \
  htop \
  iotop \
  iftop \
  ncdu \
  tmux \
  vim \
  curl \
  wget \
  git \
  jq
```

### Create Useful Aliases

```bash
cat >> ~/.bashrc << 'EOF'

# Proxmox aliases
alias vmlist='qm list'
alias vmstart='qm start'
alias vmstop='qm stop'
alias vmstatus='qm status'
alias storageinfo='pvesm status'
alias poollist='pvesh get /pools'

# Network aliases
alias showvlans='ip addr show | grep vmbr1'
alias testnetwork='ping -c 2 10.0.110.1 && ping -c 2 10.0.120.1 && ping -c 2 8.8.8.8'

EOF

source ~/.bashrc
```

---

## Ready to Deploy?

Once all items are checked, you're ready to deploy VMs:

```bash
# On your workstation
cd ~/Documents/claude/projects/smb-office-it-blueprint

# Deploy infrastructure VMs
ansible-playbook playbooks/deploy-infrastructure-vms.yml

# Start VMs
ssh root@192.168.35.20
qm start 110  # Ansible control
qm start 200  # DC01
qm start 201  # DC02
```

Good luck with your deployment!
