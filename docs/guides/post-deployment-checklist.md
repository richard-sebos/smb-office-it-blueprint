# Post-Deployment Checklist

**Project:** SMB Office IT Blueprint
**Last Updated:** 2025-12-28
**Status:** Infrastructure Deployed - Configuration Phase

## Overview

All infrastructure VMs have been deployed. This checklist guides you through configuring each service to create a fully functional SMB office environment.

## Phase 1: Core Infrastructure (Do First)

### Domain Controllers (VMs 200-201)

**Priority:** CRITICAL - Everything depends on this

- [ ] **Start VMs**
  ```bash
  qm start 200  # dc01
  qm start 201  # dc02
  ```

- [ ] **Configure Samba AD DC on dc01 (Primary)**
  - [ ] SSH: `ssh debian@10.0.120.10`
  - [ ] Install Samba AD: `sudo apt update && sudo apt install -y samba krb5-config winbind`
  - [ ] Provision domain: `sudo samba-tool domain provision`
    - Domain: `CORP`
    - Realm: `CORP.COMPANY.LOCAL`
    - Server Role: `dc`
    - DNS backend: `SAMBA_INTERNAL`
    - Admin password: (set strong password)
  - [ ] Configure DNS forwarders: Edit `/etc/samba/smb.conf`
  - [ ] Start Samba: `sudo systemctl start samba-ad-dc`
  - [ ] Enable on boot: `sudo systemctl enable samba-ad-dc`
  - [ ] Test: `samba-tool domain level show`

- [ ] **Join dc02 as Replica**
  - [ ] SSH: `ssh debian@10.0.120.11`
  - [ ] Install Samba: `sudo apt update && sudo apt install -y samba krb5-config winbind`
  - [ ] Join domain: `sudo samba-tool domain join corp.company.local DC -U administrator`
  - [ ] Start Samba: `sudo systemctl start samba-ad-dc && sudo systemctl enable samba-ad-dc`
  - [ ] Verify replication: `sudo samba-tool drs showrepl`

- [ ] **Update OPNsense DNS Settings**
  - [ ] Web UI → Services → Unbound DNS → General
  - [ ] Add domain overrides:
    - Domain: `corp.company.local` → Server: `10.0.120.10`
    - Domain: `corp.company.local` → Server: `10.0.120.11`
  - [ ] Update DHCP to provide DC IPs as DNS servers

- [ ] **Test Domain**
  ```bash
  # From any VM
  nslookup dc01.corp.company.local 10.0.120.10
  ping dc01.corp.company.local
  ```

**Documentation:**
- [ ] Document admin password in password manager
- [ ] Document domain join procedure
- [ ] Create user creation playbook

---

## Phase 2: Management Services

### Ansible Control Server (VM 110)

- [ ] **Start VM:** `qm start 110`
- [ ] **SSH:** `ssh ubuntu@10.0.110.10`
- [ ] **Install Ansible**
  ```bash
  sudo apt update
  sudo apt install -y ansible git python3-pip
  pip3 install ansible-lint
  ```
- [ ] **Clone project repository**
  ```bash
  git clone https://github.com/yourusername/smb-office-it-blueprint.git
  cd smb-office-it-blueprint
  ```
- [ ] **Configure Ansible inventory** with all infrastructure VMs
- [ ] **Set up SSH keys** for passwordless access
- [ ] **Test connectivity:** `ansible all -m ping`
- [ ] **Create playbooks** for:
  - [ ] User management (AD integration)
  - [ ] Package updates
  - [ ] Security hardening
  - [ ] Service configuration

### Monitoring Server (VM 111)

- [ ] **Start VM:** `qm start 111`
- [ ] **SSH:** `ssh ubuntu@10.0.110.11`
- [ ] **Choose monitoring solution:**
  - Option A: Zabbix (comprehensive, enterprise-grade)
  - Option B: Prometheus + Grafana (modern, metrics-focused)
  - Option C: Netdata (simple, real-time)

**If using Zabbix:**
- [ ] Install Zabbix Server
  ```bash
  wget https://repo.zabbix.com/zabbix/6.4/ubuntu/pool/main/z/zabbix-release/zabbix-release_6.4-1+ubuntu22.04_all.deb
  sudo dpkg -i zabbix-release_6.4-1+ubuntu22.04_all.deb
  sudo apt update
  sudo apt install -y zabbix-server-mysql zabbix-frontend-php zabbix-apache-conf zabbix-sql-scripts zabbix-agent
  ```
- [ ] Configure MySQL database
- [ ] Configure web interface: `http://10.0.110.11/zabbix`
- [ ] Add all infrastructure hosts
- [ ] Configure alerts (email, Slack, etc.)

**If using Prometheus + Grafana:**
- [ ] Install Prometheus
- [ ] Install Grafana
- [ ] Configure node_exporter on all VMs
- [ ] Import dashboards
- [ ] Configure alerting

### Jump Host / Bastion (VM 113)

- [ ] **Start VM:** `qm start 113`
- [ ] **SSH:** `ssh ubuntu@10.0.110.13`
- [ ] **Harden SSH**
  ```bash
  sudo nano /etc/ssh/sshd_config
  # Set: PasswordAuthentication no
  # Set: PermitRootLogin no
  # Set: AllowUsers yourusername
  sudo systemctl restart sshd
  ```
- [ ] **Install 2FA** (optional but recommended)
  ```bash
  sudo apt install -y libpam-google-authenticator
  google-authenticator
  ```
- [ ] **Configure session recording** (optional)
- [ ] **Set up firewall rules** on OPNsense to only allow SSH via jump host

### Backup Server (VM 112)

- [ ] **Start VM:** `qm start 112`
- [ ] **SSH:** `ssh debian@10.0.110.12`
- [ ] **Choose backup solution:**
  - Option A: Bacula (enterprise-grade)
  - Option B: rsync + scripts (simple)
  - Option C: Proxmox Backup Server (integrated)

**If using rsync:**
- [ ] Install rsync: `sudo apt install -y rsync`
- [ ] Create backup directories: `sudo mkdir -p /backup/{vms,files,databases}`
- [ ] Create backup scripts
- [ ] Schedule with cron
- [ ] Test restore procedure

---

## Phase 3: Production Services

### File Server (VM 210)

- [ ] **Start VM:** `qm start 210`
- [ ] **SSH:** `ssh ubuntu@10.0.120.20`
- [ ] **Join to domain**
  ```bash
  sudo apt install -y samba winbind krb5-config
  sudo net ads join -U administrator
  ```
- [ ] **Create file shares**
  ```bash
  sudo mkdir -p /srv/shares/{departments,users,public}
  sudo nano /etc/samba/smb.conf
  # Add share definitions
  sudo systemctl restart smbd
  ```
- [ ] **Set up user home directories**
- [ ] **Configure quotas** (if needed)
- [ ] **Test access** from workstation

### Database Server (VM 220)

- [ ] **Start VM:** `qm start 220`
- [ ] **SSH:** `ssh debian@10.0.120.30`
- [ ] **Install PostgreSQL**
  ```bash
  sudo apt install -y postgresql postgresql-contrib
  sudo systemctl start postgresql
  sudo systemctl enable postgresql
  ```
- [ ] **Secure PostgreSQL**
  ```bash
  sudo -u postgres psql
  \password postgres
  ```
- [ ] **Create application databases**
- [ ] **Configure remote access** (if needed)
- [ ] **Set up automated backups**
  ```bash
  sudo crontab -e
  # 0 2 * * * /usr/bin/pg_dumpall > /backup/postgres_$(date +\%Y\%m\%d).sql
  ```

### Application Server (VM 230)

- [ ] **Start VM:** `qm start 230`
- [ ] **SSH:** `ssh ubuntu@10.0.120.40`
- [ ] **Install web stack**
  ```bash
  sudo apt install -y nginx nodejs npm python3-pip
  ```
- [ ] **Deploy applications** (specific to your needs)
- [ ] **Configure reverse proxy**
- [ ] **Set up SSL/TLS** with Let's Encrypt
- [ ] **Connect to database server**

### Email Server (VM 240)

- [ ] **Start VM:** `qm start 240`
- [ ] **SSH:** `ssh debian@10.0.120.50`
- [ ] **Choose email solution:**
  - Option A: Postfix + Dovecot (traditional)
  - Option B: Zimbra (all-in-one)
  - Option C: Mail-in-a-Box (simple)

**If using Postfix + Dovecot:**
- [ ] Install packages
  ```bash
  sudo apt install -y postfix dovecot-core dovecot-imapd
  ```
- [ ] Configure Postfix for internal mail
- [ ] Configure Dovecot for IMAP
- [ ] Set up LDAP/AD authentication
- [ ] Configure spam filtering
- [ ] Test email delivery

---

## Phase 4: DMZ Services

### VPN Gateway (VM 410)

- [ ] **Start VM:** `qm start 410`
- [ ] **SSH:** `ssh debian@10.0.150.20`
- [ ] **Choose VPN solution:**
  - Option A: OpenVPN (traditional, widely supported)
  - Option B: WireGuard (modern, faster)

**If using WireGuard:**
- [ ] Install WireGuard
  ```bash
  sudo apt install -y wireguard
  wg genkey | sudo tee /etc/wireguard/privatekey | wg pubkey | sudo tee /etc/wireguard/publickey
  ```
- [ ] Configure server
- [ ] Generate client configs
- [ ] Configure OPNsense firewall rules
- [ ] Test remote access

### Mail Relay (VM 420)

- [ ] **Start VM:** `qm start 420`
- [ ] **SSH:** `ssh debian@10.0.150.30`
- [ ] **Install Postfix**
  ```bash
  sudo apt install -y postfix
  sudo dpkg-reconfigure postfix
  ```
- [ ] Configure as relay
- [ ] Set up SPF/DKIM/DMARC
- [ ] Configure spam filtering
- [ ] Relay to internal mail server

### Web Server (VM 450)

- [ ] **Start VM:** `qm start 450`
- [ ] **SSH:** `ssh ubuntu@10.0.150.10`
- [ ] **Install Nginx**
  ```bash
  sudo apt install -y nginx certbot python3-certbot-nginx
  ```
- [ ] Configure website
- [ ] Set up SSL with Let's Encrypt
  ```bash
  sudo certbot --nginx -d example.com
  ```
- [ ] Configure firewall rules on OPNsense (allow 80/443)
- [ ] Test public access

---

## Phase 5: Workstations

### Admin Workstation (VM 300)

- [ ] **Start VM:** `qm start 300`
- [ ] **Install desktop environment**
  ```bash
  ssh ubuntu@10.0.130.10
  sudo apt update
  sudo apt install -y ubuntu-desktop-minimal
  ```
- [ ] **Join to domain**
- [ ] **Install admin tools**
  - [ ] RSAT (Remote Server Administration Tools)
  - [ ] Ansible
  - [ ] SSH clients
  - [ ] Network tools
- [ ] **Configure VNC/RDP access**

### End-User Workstations (Optional)

- [ ] **Deploy user workstations** (if needed)
  ```bash
  ansible-playbook playbooks/deploy-user-workstations.yml -e "num_workstations=5"
  ```
- [ ] **Join to domain**
- [ ] **Install desktop applications**
- [ ] **Configure user profiles**

---

## Phase 6: Security Hardening

### OPNsense Firewall Rules

- [ ] **Refine inter-VLAN rules**
  - [ ] Management → All (allow admin access)
  - [ ] Servers → Servers (allow)
  - [ ] Workstations → Servers (allow specific ports only)
  - [ ] Guest/IoT → Internet only (block all internal)
  - [ ] DMZ → Limited inbound from Internet

- [ ] **Enable IDS/IPS** (Suricata)
- [ ] **Configure traffic shaping** (QoS)
- [ ] **Set up VPN** for remote admin access
- [ ] **Enable logging** and log forwarding

### System Security

- [ ] **Update all VMs**
  ```bash
  ansible all -m apt -a "update_cache=yes upgrade=dist" --become
  ```
- [ ] **Configure automatic security updates**
- [ ] **Set up fail2ban** on all internet-facing services
- [ ] **Harden SSH** on all VMs
- [ ] **Configure host-based firewalls** (ufw/iptables)
- [ ] **Enable SELinux/AppArmor**

### Backup and DR

- [ ] **Configure Proxmox backups**
  - [ ] Schedule: Daily at 2 AM
  - [ ] Retention: 7 days
  - [ ] Storage: External backup location
- [ ] **Test restore procedure**
- [ ] **Document recovery steps**
- [ ] **Create DR plan**

---

## Phase 7: Documentation

- [ ] **Network diagram** with all VMs and VLANs
- [ ] **IP address spreadsheet**
- [ ] **Admin password vault**
- [ ] **Service documentation** (how to restart, troubleshoot each service)
- [ ] **Runbooks** for common tasks
- [ ] **User onboarding guide**
- [ ] **Disaster recovery procedures**

---

## Phase 8: Testing

### Functionality Testing

- [ ] **User can login** to domain from workstation
- [ ] **User can access** file shares
- [ ] **User can send/receive** email
- [ ] **Applications work** correctly
- [ ] **Internet access** works from all VLANs
- [ ] **VPN access** works for remote users

### Performance Testing

- [ ] **Network throughput** between VLANs
- [ ] **Database performance**
- [ ] **File server performance**
- [ ] **Website load time**

### Security Testing

- [ ] **Port scan** from external network
- [ ] **Vulnerability scan** (OpenVAS, Nessus)
- [ ] **Penetration testing** (if budget allows)
- [ ] **Firewall rule verification**
- [ ] **Access control testing**

### Disaster Recovery Testing

- [ ] **Restore VM from backup**
- [ ] **Restore database from backup**
- [ ] **Restore file shares from backup**
- [ ] **Failover to DC02** (domain controller)
- [ ] **Recovery time objective (RTO)** measurement

---

## Phase 9: User Migration (If Applicable)

- [ ] **Create user accounts** in AD
- [ ] **Migrate user data** to file server
- [ ] **Configure user email** accounts
- [ ] **Set up user workstations**
- [ ] **Train users** on new system
- [ ] **Provide support** during transition

---

## Phase 10: Production Cutover

- [ ] **Final testing** in production mode
- [ ] **Communication plan** to users
- [ ] **Cutover schedule** (ideally weekend/off-hours)
- [ ] **Rollback plan** if issues arise
- [ ] **Post-cutover monitoring**
- [ ] **User support** availability

---

## Maintenance Schedule

### Daily
- [ ] Check monitoring alerts
- [ ] Review system logs
- [ ] Verify backups completed

### Weekly
- [ ] Review security logs
- [ ] Check disk space
- [ ] Update documentation

### Monthly
- [ ] Apply security updates
- [ ] Review user access
- [ ] Test backup restores
- [ ] Performance review

### Quarterly
- [ ] Full system audit
- [ ] DR test
- [ ] Review and update documentation
- [ ] Capacity planning

---

## Quick Reference

**Start all infrastructure:**
```bash
bash scripts/start-all-infrastructure.sh
```

**Stop all infrastructure:**
```bash
bash scripts/stop-all-infrastructure.sh
```

**Check status:**
```bash
qm list | grep -v template
```

**SSH quick access:**
```bash
ssh ubuntu@10.0.110.10  # Ansible control
ssh debian@10.0.120.10  # dc01
ssh debian@10.0.120.11  # dc02
```

---

## Support Resources

- **Project Documentation:** `~/Documents/claude/projects/smb-office-it-blueprint/docs/`
- **Proxmox Docs:** https://pve.proxmox.com/pve-docs/
- **Samba AD:** https://wiki.samba.org/index.php/Setting_up_Samba_as_an_Active_Directory_Domain_Controller
- **OPNsense Docs:** https://docs.opnsense.org/

---

**Status:** Infrastructure deployed, ready for configuration
**Next Step:** Configure domain controllers (Phase 1)
