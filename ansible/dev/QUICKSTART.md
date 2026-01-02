# Quick Start Guide

## Deploy ws-admin01 from Scratch

### 1. Set up SSH access to Proxmox
```bash
ssh-copy-id root@192.168.35.20
ssh root@192.168.35.20 "qm list"
```

### 2. Configure environment
```bash
cd ansible/dev
cp .env.example .env
vim .env  # Update PROXMOX_HOST if needed
source .env
```

### 3. Deploy and configure
```bash
ansible-playbook playbooks/deploy-and-configure-ws-admin01.yml
```

That's it! The playbook will:
1. Clone VM from template 9275 (Rocky Linux)
2. Configure resources (2 cores, 4GB RAM)
3. Set up network (VLAN 131, IP 10.0.131.10)
4. Apply tags and add to resource pool
5. Start the VM
6. Wait for SSH
7. Configure hostname, network, packages
8. Create admin user and deploy SSH key
9. Apply SSH hardening policies
10. Enable/disable services

## What Gets Created

**VM Details:**
- VMID: 300
- Hostname: ws-admin01
- IP: 10.0.131.10/24
- VLAN: 131
- OS: Rocky Linux 9

**Installed Software:**
- Base tools: vim, git, curl, wget, htop, tmux, tree
- Network tools: tcpdump, wireshark, nmap, netcat
- Admin tools: ansible, python3-pip, sshpass
- Desktop: firefox, remmina

**Security Hardening:**
- SSH key-only authentication
- No root login via SSH
- Session timeouts and keepalives
- All forwarding disabled
- CVE-2024-6387 mitigation

## Next Steps

### Connect to the VM
```bash
ssh richard@10.0.131.10
```

### Verify SSH hardening
```bash
ls -la /etc/ssh/sshd_config.d/
cat /etc/ssh/sshd_config.d/07-authentication.conf
```

### Check installed packages
```bash
rpm -qa | grep -E 'tcpdump|wireshark|nmap'
```

## Troubleshooting

### VM doesn't start
```bash
# Check Proxmox
ssh root@192.168.35.20
qm list | grep 300
qm status 300
```

### Can't SSH to VM
```bash
# Check from Proxmox console
ssh root@192.168.35.20
qm terminal 300

# Inside VM, check network
ip addr show
ping 10.0.131.1
cat /etc/NetworkManager/system-connections/ens18.nmconnection
```

### SSH key not working
```bash
# Check key was deployed
ssh richard@10.0.131.10
cat ~/.ssh/authorized_keys

# Check permissions
ls -la ~/.ssh/
```

## Environment Variables

Set these before running deployment:

```bash
export PROXMOX_HOST="192.168.35.20"      # Your Proxmox host
export PROXMOX_USER="root@pam"           # Proxmox user
export PROXMOX_PASSWORD="your-password"  # Proxmox password
```

Or use the .env file:
```bash
source .env
```

## Customization

Edit `host_vars/ws-admin01.yml` to change:
- Network settings (IP, VLAN, gateway)
- Resources (CPU, RAM, disk)
- Package lists
- SSH hardening policies
- User configuration
