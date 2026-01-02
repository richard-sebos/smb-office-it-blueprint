# SSH Hardening Guide

## Overview

The `ssh_hardening` role implements modular SSH security policies using OpenSSH's `Include` directive and policy files in `/etc/ssh/sshd_config.d/`.

## Security Policies Implemented

### 1. Session Management (06-session.conf)
- **ClientAliveInterval: 300** - Keepalive every 5 minutes
- **ClientAliveCountMax: 0** - Disconnect on first missed response
- **TCPKeepAlive: no** - Disable OS-level TCP keepalives
- **LoginGraceTime: 0** - Mitigates CVE-2024-6387
- **MaxStartups: 3:30:10** - Throttle brute-force attempts

### 2. Authentication (07-authentication.conf)
- **PermitRootLogin: no** - Block direct root login
- **AllowGroups: ssh-users** - Only ssh-users group can login
- **PermitEmptyPasswords: no** - Prevent empty password login
- **MaxAuthTries: 3** - Limit authentication attempts
- **MaxSessions: 2** - Limit concurrent sessions
- **PasswordAuthentication: no** - Key-based auth only
- **ChallengeResponseAuthentication: no** - Disable keyboard-interactive
- **StrictModes: yes** - Enforce secure file permissions

### 3. Access Control (08-access-control.conf)
- Network-based access restrictions (optional)
- Configured via `ssh_hardening.allowed_networks` variable

### 4. Forwarding Restrictions (10-forwarding.conf)
- **AllowTcpForwarding: no** - Block port forwarding
- **AllowStreamLocalForwarding: no** - Block Unix socket forwarding
- **AllowAgentForwarding: no** - Prevent agent hijacking
- **PermitTunnel: no** - Block VPN-like tunnels
- **GatewayPorts: no** - Prevent remote port binding
- **X11Forwarding: no** - Block GUI forwarding

### 5. Environment Hardening (99-hardening.conf)
- **PermitUserEnvironment: no** - Block environment variable injection

## Configuration

### Basic Configuration (No Network Restrictions)

```yaml
# host_vars/hostname.yml
admin_user:
  username: richard
  ssh_public_key_path: ~/.ssh/id_rsa.pub

# No ssh_hardening section = no network restrictions
```

### With Network Restrictions

```yaml
# host_vars/hostname.yml
admin_user:
  username: richard
  ssh_public_key_path: ~/.ssh/id_rsa.pub

ssh_hardening:
  allowed_networks:
    - cidr: 10.0.0.0/8
      description: Internal private network
    - cidr: 192.168.0.0/16
      description: Home network range
    - cidr: 172.16.0.0/12
      description: Private network
```

## Important Notes

### ⚠️ Pre-requisites

**CRITICAL**: Deploy SSH public key BEFORE applying ssh_hardening!

```yaml
# Correct role order:
roles:
  - user_config      # Deploys SSH key
  - ssh_config       # Basic SSH setup
  - ssh_hardening    # Applies security policies (disables password auth)
```

If you apply `ssh_hardening` before deploying keys, you'll be locked out!

### Network Restrictions vs Firewall

The `08-access-control.conf` provides network-based SSH restrictions at the application level. However:

- **Firewall is still recommended** for defense in depth
- sshd_config cannot do "deny all except" logic
- Firewall rules should complement SSH access controls

Example firewall configuration (firewalld):

```bash
# Allow SSH only from trusted networks
firewall-cmd --permanent --zone=trusted --add-source=10.0.0.0/8
firewall-cmd --permanent --zone=trusted --add-service=ssh
firewall-cmd --permanent --zone=public --remove-service=ssh
firewall-cmd --reload
```

### Testing Configuration

All policy files are validated before deployment:

```bash
# Ansible validates automatically using:
/usr/sbin/sshd -t -f /etc/ssh/sshd_config.d/06-session.conf
```

Manual testing:

```bash
# Test SSH config syntax
sudo sshd -t

# View effective configuration
sudo sshd -T

# Check specific policy files
ls -la /etc/ssh/sshd_config.d/
cat /etc/ssh/sshd_config.d/07-authentication.conf
```

## Policy File Locations

All policy files are created in `/etc/ssh/sshd_config.d/`:

```
/etc/ssh/sshd_config.d/
├── 06-session.conf          # Session management
├── 07-authentication.conf   # Authentication policies
├── 08-access-control.conf   # Network access control (optional)
├── 10-forwarding.conf       # Forwarding restrictions
└── 99-hardening.conf        # Environment hardening
```

The main `/etc/ssh/sshd_config` is modified only to add:
```
Include /etc/ssh/sshd_config.d/*.conf
```

## Troubleshooting

### Locked Out After Applying

If you get locked out:

1. **Access via console** (Proxmox VNC/SPICE)
2. **Temporarily enable password auth**:
   ```bash
   sudo mv /etc/ssh/sshd_config.d/07-authentication.conf \
           /etc/ssh/sshd_config.d/07-authentication.conf.disabled
   sudo systemctl restart sshd
   ```
3. **Deploy SSH key**:
   ```bash
   mkdir -p ~/.ssh
   chmod 700 ~/.ssh
   echo "your-public-key" >> ~/.ssh/authorized_keys
   chmod 600 ~/.ssh/authorized_keys
   ```
4. **Re-enable hardening**:
   ```bash
   sudo mv /etc/ssh/sshd_config.d/07-authentication.conf.disabled \
           /etc/ssh/sshd_config.d/07-authentication.conf
   sudo systemctl restart sshd
   ```

### Connection Timeouts

If connections timeout too quickly, adjust in `host_vars`:

```yaml
# Create custom template override
ssh_hardening:
  client_alive_interval: 600  # 10 minutes instead of 5
```

Then modify the role template to use variables.

### Group Membership Issues

Check user is in ssh-users group:

```bash
# Check group membership
groups username

# Add user to group manually if needed
sudo usermod -aG ssh-users username
```

## Security Benefits

### CVE Mitigation
- **CVE-2024-6387**: LoginGraceTime 0 prevents race condition exploitation

### Attack Surface Reduction
- No password-based attacks (key-only auth)
- No brute force (connection throttling)
- No tunneling/forwarding abuse
- No environment variable injection

### Access Control
- Group-based access (ssh-users only)
- Optional network restrictions
- Root login blocked

### Session Management
- Idle connections terminated
- Connection attempt throttling
- Limited concurrent sessions

## Compliance

These policies help meet common security frameworks:

- **CIS Benchmark**: SSH hardening recommendations
- **NIST**: Multi-factor authentication requirements (key + passphrase)
- **PCI DSS**: Restrict administrative access
- **SOC 2**: Access controls and authentication

## Customization

To customize policies:

1. Edit role templates in `roles/ssh_hardening/templates/`
2. Add variables to `host_vars/<hostname>.yml`
3. Modify role tasks in `roles/ssh_hardening/tasks/main.yml`

Example - different policies per environment:

```yaml
# host_vars/production-server.yml
ssh_hardening:
  max_auth_tries: 2  # Stricter for production
  allowed_networks:
    - cidr: 10.0.0.0/8

# host_vars/dev-server.yml
ssh_hardening:
  max_auth_tries: 5  # More lenient for dev
  # No network restrictions
```

## References

- [OpenSSH sshd_config manual](https://man.openbsd.org/sshd_config)
- [CVE-2024-6387 Details](https://nvd.nist.gov/vuln/detail/CVE-2024-6387)
- [CIS OpenSSH Benchmark](https://www.cisecurity.org/)
