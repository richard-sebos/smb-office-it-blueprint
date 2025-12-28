# Admin Workstation Setup Guide

**Project:** SMB Office IT Blueprint
**VM:** 300 (ws-admin01)
**IP:** 10.0.130.10
**OS:** Ubuntu 22.04
**Purpose:** IT administrator workstation with GUI and all admin tools

## Overview

This guide configures VM 300 as a full-featured IT administrator workstation. From here, you'll manage the entire infrastructure, including setting up the Ansible control server.

## Prerequisites

- [x] VM 300 deployed
- [x] Network configured (VLAN 130, IP 10.0.130.10)
- [x] OPNsense routing working

## Part 1: Start and Initial Access

### Step 1: Start the VM

```bash
# On Proxmox host
ssh root@192.168.35.20
qm start 300

# Check status
qm status 300
```

### Step 2: Wait for Cloud-Init

```bash
# Wait 60 seconds for cloud-init to complete
sleep 60

# Test SSH access
ssh ubuntu@10.0.130.10
```

**Default credentials:**
- Username: `ubuntu`
- Password: Set via SSH key (cloud-init)

### Step 3: Update System

```bash
# On the VM
sudo apt update
sudo apt upgrade -y
```

## Part 2: Install Desktop Environment

### Option A: Ubuntu Desktop (Recommended - Full Featured)

```bash
# Install full Ubuntu Desktop
sudo apt install -y ubuntu-desktop

# This takes 10-15 minutes
# Includes: GNOME desktop, Firefox, LibreOffice, etc.
```

### Option B: Minimal Desktop (Lighter, Faster)

```bash
# Install minimal GNOME desktop
sudo apt install -y ubuntu-desktop-minimal

# Less bloat, faster startup
# You can add applications as needed
```

### Option C: XFCE Desktop (Lightest)

```bash
# Install XFCE (very lightweight)
sudo apt install -y xubuntu-desktop

# Best for lower resources
# Fast and efficient
```

**Recommendation:** Use Ubuntu Desktop (Option A) for full functionality.

### Reboot After Installation

```bash
sudo reboot
```

Wait 2 minutes for reboot, then continue.

## Part 3: Set Up Remote Desktop Access

### Option A: VNC (Works from Anywhere)

**On the VM:**

```bash
# SSH back in after reboot
ssh ubuntu@10.0.130.10

# Install TigerVNC server
sudo apt install -y tigervnc-standalone-server tigervnc-common

# Set VNC password
vncpasswd
# Enter password (you'll use this to connect)
# No view-only password needed
```

**Create VNC startup script:**

```bash
# Create systemd service
sudo nano /etc/systemd/system/vncserver@.service
```

**Paste this content:**

```ini
[Unit]
Description=Remote desktop service (VNC)
After=syslog.target network.target

[Service]
Type=simple
User=ubuntu
PAMName=login
PIDFile=/home/ubuntu/.vnc/%H%i.pid
ExecStartPre=/bin/sh -c '/usr/bin/vncserver -kill :%i > /dev/null 2>&1 || :'
ExecStart=/usr/bin/vncserver :%i -geometry 1920x1080 -depth 24 -localhost no
ExecStop=/usr/bin/vncserver -kill :%i

[Install]
WantedBy=multi-user.target
```

**Enable and start VNC:**

```bash
# Reload systemd
sudo systemctl daemon-reload

# Enable VNC on display :1
sudo systemctl enable vncserver@1
sudo systemctl start vncserver@1

# Check status
sudo systemctl status vncserver@1
```

**Connect from your workstation:**

1. Install VNC viewer: Download TigerVNC or RealVNC viewer
2. Connect to: `10.0.130.10:5901`
3. Enter VNC password you set earlier
4. You should see the Ubuntu desktop!

### Option B: RDP (Windows-style Remote Desktop)

**On the VM:**

```bash
# Install xrdp
sudo apt install -y xrdp

# Enable and start
sudo systemctl enable xrdp
sudo systemctl start xrdp

# Allow RDP through firewall
sudo ufw allow 3389/tcp
```

**Connect from your workstation:**

- **Windows:** Use built-in Remote Desktop Connection
  - Computer: `10.0.130.10`
  - Username: `ubuntu`
  - Password: (your SSH key won't work here - set password below)

**Set password for RDP access:**

```bash
# On the VM
sudo passwd ubuntu
# Enter new password
```

### Option C: Proxmox Console (Quick Access, No Network)

**Via Proxmox Web UI:**

1. Open: `https://192.168.35.20:8006`
2. Navigate: VM 300 → Console
3. Login: `ubuntu` / (password if set)
4. Use directly in browser

**Good for:** Quick checks, troubleshooting network issues

## Part 4: Install Administrative Tools

### Essential Tools

```bash
# SSH back to VM or use VNC/RDP
ssh ubuntu@10.0.130.10

# Update first
sudo apt update

# Install essential admin tools
sudo apt install -y \
  vim \
  nano \
  git \
  curl \
  wget \
  htop \
  iotop \
  iftop \
  ncdu \
  tmux \
  screen \
  net-tools \
  dnsutils \
  tcpdump \
  nmap \
  wireshark \
  remmina \
  putty-tools \
  openssh-server \
  ansible \
  python3-pip \
  python3-venv \
  sshpass \
  rsync \
  tree \
  jq \
  yamllint
```

### Network Tools

```bash
# Advanced network diagnostics
sudo apt install -y \
  traceroute \
  mtr \
  netcat \
  telnet \
  ftp \
  lftp \
  smbclient \
  nfs-common \
  cifs-utils
```

### Development Tools

```bash
# For working with Ansible and scripts
sudo apt install -y \
  build-essential \
  python3-dev \
  python3-setuptools \
  virtualenv \
  code
```

### Virtualization Management

```bash
# Install Proxmox GUI tools
sudo apt install -y \
  virt-manager \
  virt-viewer

# For managing VMs graphically (optional)
```

## Part 5: Configure SSH Keys

### Generate SSH Key Pair

```bash
# On the admin workstation
ssh-keygen -t ed25519 -C "admin@corp.company.local"

# Press Enter for default location
# Set passphrase (optional but recommended)

# Your public key:
cat ~/.ssh/id_ed25519.pub
```

### Copy SSH Key to Infrastructure Servers

```bash
# Copy to Ansible control server
ssh-copy-id ubuntu@10.0.110.10

# Copy to domain controllers
ssh-copy-id debian@10.0.120.10
ssh-copy-id debian@10.0.120.11

# Copy to all other VMs
ssh-copy-id ubuntu@10.0.120.20  # File server
ssh-copy-id debian@10.0.120.30  # Database
ssh-copy-id ubuntu@10.0.120.40  # App server
# etc.
```

Now you can SSH without passwords!

## Part 6: Install Ansible and Set Up Project

### Install Ansible

```bash
# Already installed above, but verify
ansible --version

# Install additional Ansible tools
pip3 install --user ansible-lint
pip3 install --user molecule
```

### Clone Project Repository

**Option A: If you have the project in Git:**

```bash
# Clone from repository
cd ~
git clone https://github.com/yourusername/smb-office-it-blueprint.git
cd smb-office-it-blueprint
```

**Option B: Copy from your workstation:**

```bash
# On your workstation
cd ~/Documents/claude/projects/smb-office-it-blueprint
tar czf smb-project.tar.gz playbooks/ scripts/ docs/ hosts.yml ansible.cfg

# Copy to admin workstation
scp smb-project.tar.gz ubuntu@10.0.130.10:~/

# On admin workstation
ssh ubuntu@10.0.130.10
tar xzf smb-project.tar.gz
```

**Option C: Create fresh on admin workstation:**

```bash
# Create directory structure
mkdir -p ~/smb-office-it-blueprint/{playbooks,scripts,docs,inventory}
cd ~/smb-office-it-blueprint
```

### Create Ansible Configuration

```bash
# Create ansible.cfg
cat > ansible.cfg << 'EOF'
[defaults]
inventory = ./inventory/hosts.yml
host_key_checking = False
retry_files_enabled = False
gathering = smart
fact_caching = jsonfile
fact_caching_connection = /tmp/ansible_facts
fact_caching_timeout = 3600
roles_path = ./roles
callbacks_enabled = profile_tasks, timer

[privilege_escalation]
become = True
become_method = sudo
become_user = root
become_ask_pass = False

[ssh_connection]
pipelining = True
ssh_args = -o ControlMaster=auto -o ControlPersist=60s
EOF
```

### Create Ansible Inventory

```bash
# Create inventory directory
mkdir -p inventory

# Create hosts file
cat > inventory/hosts.yml << 'EOF'
all:
  children:
    management:
      hosts:
        ansible-ctrl:
          ansible_host: 10.0.110.10
          ansible_user: ubuntu
        monitoring:
          ansible_host: 10.0.110.11
          ansible_user: ubuntu
        backup:
          ansible_host: 10.0.110.12
          ansible_user: debian
        jump-host:
          ansible_host: 10.0.110.13
          ansible_user: ubuntu

    domain_controllers:
      hosts:
        dc01:
          ansible_host: 10.0.120.10
          ansible_user: debian
        dc02:
          ansible_host: 10.0.120.11
          ansible_user: debian

    servers:
      hosts:
        fs01:
          ansible_host: 10.0.120.20
          ansible_user: ubuntu
        db01:
          ansible_host: 10.0.120.30
          ansible_user: debian
        app01:
          ansible_host: 10.0.120.40
          ansible_user: ubuntu
        mail01:
          ansible_host: 10.0.120.50
          ansible_user: debian

    workstations:
      hosts:
        ws-admin01:
          ansible_host: 10.0.130.10
          ansible_user: ubuntu

    dmz:
      hosts:
        vpn-gw:
          ansible_host: 10.0.150.20
          ansible_user: debian
        mail-relay:
          ansible_host: 10.0.150.30
          ansible_user: debian
        web01:
          ansible_host: 10.0.150.10
          ansible_user: ubuntu

  vars:
    ansible_python_interpreter: /usr/bin/python3
EOF
```

### Test Ansible Connectivity

```bash
# First, make sure all VMs are started
# Then test connectivity

# Test ping to all hosts
ansible all -m ping

# Test specific groups
ansible management -m ping
ansible domain_controllers -m ping
ansible servers -m ping
```

**Expected output:** All hosts should respond with "pong"

## Part 7: Install GUI Applications

### Remote Management Tools

```bash
# Install Remmina (RDP/VNC client)
sudo apt install -y remmina remmina-plugin-rdp remmina-plugin-vnc

# Install Firefox for web access
sudo apt install -y firefox

# Install Chrome (optional)
wget https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb
sudo apt install -y ./google-chrome-stable_current_amd64.deb
```

### Code Editors

```bash
# Install Visual Studio Code
wget -qO- https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor > packages.microsoft.gpg
sudo install -o root -g root -m 644 packages.microsoft.gpg /etc/apt/trusted.gpg.d/
sudo sh -c 'echo "deb [arch=amd64,arm64,armhf signed-by=/etc/apt/trusted.gpg.d/packages.microsoft.gpg] https://packages.microsoft.com/repos/code stable main" > /etc/apt/sources.list.d/vscode.list'
sudo apt update
sudo apt install -y code

# Or use built-in gedit
sudo apt install -y gedit
```

### Documentation Tools

```bash
# Install LibreOffice
sudo apt install -y libreoffice

# Install markdown editors
sudo apt install -y ghostwriter
```

## Part 8: Bookmark Essential URLs

**Open Firefox and bookmark these:**

1. **Proxmox:** `https://192.168.35.20:8006`
2. **OPNsense:** `https://192.168.35.XXX` (WAN IP)
3. **OPNsense LAN:** `https://10.0.110.1`
4. **Monitoring:** `http://10.0.110.11` (when configured)
5. **Applications:** (as you deploy them)

## Part 9: Create Useful Scripts

### Quick SSH Connections

```bash
# Create bin directory
mkdir -p ~/bin

# Create SSH shortcuts
cat > ~/bin/ssh-ansible << 'EOF'
#!/bin/bash
ssh ubuntu@10.0.110.10
EOF

cat > ~/bin/ssh-dc01 << 'EOF'
#!/bin/bash
ssh debian@10.0.120.10
EOF

cat > ~/bin/ssh-dc02 << 'EOF'
#!/bin/bash
ssh debian@10.0.120.11
EOF

# Make executable
chmod +x ~/bin/ssh-*

# Add to PATH
echo 'export PATH="$HOME/bin:$PATH"' >> ~/.bashrc
source ~/.bashrc
```

**Now you can just type:** `ssh-ansible` or `ssh-dc01`

### Infrastructure Status Check

```bash
cat > ~/bin/infra-status << 'EOF'
#!/bin/bash
echo "=== Infrastructure Status ==="
echo ""
echo "Testing connectivity to all servers..."
echo ""

ansible all -m ping --one-line | grep -E "SUCCESS|UNREACHABLE|FAILED"

echo ""
echo "VM Status on Proxmox:"
ssh root@192.168.35.20 "qm list | grep -v template"
EOF

chmod +x ~/bin/infra-status
```

**Usage:** `infra-status`

## Part 10: Set Up Desktop Shortcuts

### Create Desktop Launchers

```bash
# Create desktop directory if needed
mkdir -p ~/Desktop

# Proxmox launcher
cat > ~/Desktop/proxmox.desktop << 'EOF'
[Desktop Entry]
Version=1.0
Type=Link
Name=Proxmox Web UI
Comment=Manage Proxmox VE
Icon=applications-system
URL=https://192.168.35.20:8006
EOF

# OPNsense launcher
cat > ~/Desktop/opnsense.desktop << 'EOF'
[Desktop Entry]
Version=1.0
Type=Link
Name=OPNsense Firewall
Comment=Manage OPNsense
Icon=security-high
URL=https://10.0.110.1
EOF

# Terminal launcher with SSH to Ansible
cat > ~/Desktop/ansible-ssh.desktop << 'EOF'
[Desktop Entry]
Version=1.0
Type=Application
Name=Ansible Control SSH
Comment=SSH to Ansible Control Server
Icon=utilities-terminal
Exec=gnome-terminal -- ssh ubuntu@10.0.110.10
Terminal=false
EOF

# Make executable
chmod +x ~/Desktop/*.desktop
```

## Part 11: Configure Shortcuts and Aliases

```bash
# Add useful aliases
cat >> ~/.bashrc << 'EOF'

# Infrastructure aliases
alias infra='cd ~/smb-office-it-blueprint'
alias ans='ansible'
alias ap='ansible-playbook'
alias pve='ssh root@192.168.35.20'
alias ans-ctrl='ssh ubuntu@10.0.110.10'
alias dc01='ssh debian@10.0.120.10'
alias dc02='ssh debian@10.0.120.11'

# Ansible shortcuts
alias ping-all='ansible all -m ping'
alias ping-mgmt='ansible management -m ping'
alias ping-servers='ansible servers -m ping'

# System shortcuts
alias ll='ls -alh'
alias ports='sudo netstat -tulpn'
alias update='sudo apt update && sudo apt upgrade -y'
EOF

source ~/.bashrc
```

## Part 12: Final Configuration

### Set Up Firewall (UFW)

```bash
# Enable firewall
sudo ufw enable

# Allow SSH
sudo ufw allow ssh

# Allow VNC (if using)
sudo ufw allow 5901/tcp

# Allow RDP (if using)
sudo ufw allow 3389/tcp

# Check status
sudo ufw status
```

### Configure Time Sync

```bash
# Verify time is correct
timedatectl

# If needed, configure NTP
sudo systemctl enable systemd-timesyncd
sudo systemctl start systemd-timesyncd
```

### Set Hostname

```bash
# Set proper hostname
sudo hostnamectl set-hostname ws-admin01

# Update /etc/hosts
sudo nano /etc/hosts
# Add: 10.0.130.10  ws-admin01.corp.company.local ws-admin01
```

## Verification Checklist

After setup, verify:

- [ ] Desktop environment loads properly (VNC/RDP)
- [ ] Can access Proxmox web UI via browser
- [ ] Can access OPNsense web UI via browser
- [ ] SSH works to all infrastructure VMs
- [ ] Ansible can ping all hosts
- [ ] All admin tools installed and working
- [ ] Code editor (VS Code) opens and works
- [ ] Terminal works properly
- [ ] Desktop shortcuts work
- [ ] Can copy/paste between workstation and VMs

## Next Steps

Now that your admin workstation is set up:

1. **Configure Ansible Control Server (VM 110)**
   - Transfer your playbooks
   - Set up automation
   - Create service configuration playbooks

2. **Set Up Monitoring (VM 111)**
   - Install Zabbix or Prometheus
   - Add all infrastructure to monitoring

3. **Configure Domain Controllers (VMs 200-201)**
   - Set up Samba AD
   - Configure DNS
   - Join machines to domain

## Quick Reference

**Access Admin Workstation:**
```bash
# Via VNC
vncviewer 10.0.130.10:5901

# Via RDP
rdesktop 10.0.130.10

# Via SSH
ssh ubuntu@10.0.130.10
```

**From Admin Workstation:**
```bash
# Quick infrastructure check
infra-status

# Test all Ansible hosts
ping-all

# SSH to Ansible control
ans-ctrl

# Open Proxmox
firefox https://192.168.35.20:8006 &
```

---

**Status:** Admin workstation ready for infrastructure management!
**Next:** Configure Ansible Control Server (VM 110)
