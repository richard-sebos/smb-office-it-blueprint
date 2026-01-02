# Development Ansible Configuration

## Directory Structure

```
ansible/dev/
├── ansible.cfg                    # Ansible configuration
├── inventory/
│   └── hosts.yml                 # Inventory (built as VMs are created)
├── host_vars/
│   └── ws-admin01.yml            # Per-VM configuration
├── roles/                         # Reusable roles
│   ├── network_config/           # Static network configuration
│   ├── hostname_config/          # Hostname and /etc/hosts
│   ├── system_update/            # OS updates
│   ├── install_packages/         # Package installation
│   ├── user_config/              # User and sudo setup
│   ├── ssh_config/               # Basic SSH configuration
│   ├── ssh_hardening/            # Modular SSH security policies
│   └── service_config/           # Service management
└── playbooks/
    └── configure-ws-admin01-roles.yml # Role-based playbook
```

## Usage

### Initial Setup

1. **Set up Proxmox credentials:**
   ```bash
   cd ansible/dev
   cp .env.example .env
   # Edit .env with your Proxmox password
   vim .env
   source .env
   ```

2. **Install required Ansible collections:**
   ```bash
   ansible-galaxy collection install community.general
   ```

### Deploy and Configure ws-admin01

**Option 1: Deploy and configure in one command (recommended)**
```bash
cd ansible/dev
source .env
ansible-playbook playbooks/deploy-and-configure-ws-admin01.yml
```

**Option 2: Deploy then configure separately**
```bash
# Deploy VM on Proxmox
ansible-playbook playbooks/deploy-ws-admin01.yml

# Configure the VM
ansible-playbook playbooks/configure-ws-admin01-roles.yml
```

**Option 3: Configure existing VM**
```bash
# If VM already exists and is accessible
ansible ws-admin01 -m ping
ansible-playbook playbooks/configure-ws-admin01-roles.yml

# Run with verbose output
ansible-playbook playbooks/configure-ws-admin01-roles.yml -v

# Run specific roles only
ansible-playbook playbooks/configure-ws-admin01-roles.yml --tags network_config
```

### Adding New VMs

1. Add VM to `inventory/hosts.yml`
2. Create `host_vars/<hostname>.yml` with VM-specific config
3. Create `playbooks/configure-<hostname>.yml` using the same roles
4. Run the playbook

**Example for a new server:**

```yaml
# playbooks/configure-newserver.yml
---
- name: Configure New Server
  hosts: newserver
  become: yes
  gather_facts: yes

  roles:
    - network_config
    - hostname_config
    - system_update
    - install_packages
    - user_config
    - ssh_config
    - service_config
```

## Per-VM Configuration Files

Each VM has its own `host_vars/<hostname>.yml` file containing:

- **VM Identity**: vmid, hostname, fqdn
- **Network**: IP, gateway, DNS, VLAN
- **OS**: Type (ubuntu/rocky), version, template
- **Resources**: CPU, memory, disk
- **Proxmox**: Tags, pool, storage
- **Packages**: Lists of packages to install
- **Users**: Admin user configuration and SSH key path
- **Services**: Services to enable/disable

### SSH Key Setup

The playbook can deploy your SSH public key to the admin user's authorized_keys:

1. Generate SSH key pair on your control machine (if needed):
   ```bash
   ssh-keygen -t ed25519 -C "your-email@example.com"
   ```

2. Specify the public key path in `host_vars/<hostname>.yml`:
   ```yaml
   admin_user:
     ssh_public_key_path: ~/.ssh/id_ed25519.pub
   ```

3. The playbook will automatically deploy the key during configuration

## Network Configuration

The playbook automatically detects OS type and applies the correct network configuration:

- **Ubuntu**: Uses netplan (`/etc/netplan/01-netcfg.yaml`)
- **Rocky**: Uses NetworkManager (`/etc/NetworkManager/system-connections/ens18.nmconnection`)

## Reusable Roles

Each role is independent and can be used across different VMs:

- **network_config**: Configures static IP (supports both Ubuntu netplan and Rocky NetworkManager)
- **hostname_config**: Sets hostname and updates /etc/hosts
- **system_update**: Updates all system packages
- **install_packages**: Installs base, network tools, admin tools, and desktop packages
- **user_config**: Creates admin user with sudo access and deploys SSH keys
- **ssh_config**: Enables and configures SSH service
- **ssh_hardening**: Applies modular SSH security policies (CVE mitigation, key-only auth, no forwarding)
- **service_config**: Enables/disables system services

## Current VMs

| VMID | Hostname    | IP           | VLAN | OS Type | Role              |
|------|-------------|--------------|------|---------|-------------------|
| 300  | ws-admin01  | 10.0.131.10  | 131  | rocky   | Admin Workstation |

