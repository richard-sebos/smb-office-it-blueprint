# Development Ansible Configuration

## Directory Structure

```
ansible/dev/
├── ansible.cfg              # Ansible configuration
├── inventory/
│   └── hosts.yml           # Inventory (built as VMs are created)
├── host_vars/
│   └── ws-admin01.yml      # Per-VM configuration
├── playbooks/
│   └── configure-ws-admin01.yml  # VM-specific playbook
└── templates/
    ├── netplan-static.j2         # Ubuntu network config
    └── nmconnection-static.j2    # Rocky network config
```

## Usage

### Configure ws-admin01

From the `ansible/dev` directory:

```bash
cd ansible/dev

# Test connectivity
ansible ws-admin01 -m ping

# Run configuration playbook
ansible-playbook playbooks/configure-ws-admin01.yml

# Run with verbose output
ansible-playbook playbooks/configure-ws-admin01.yml -v
```

### Adding New VMs

1. Add VM to `inventory/hosts.yml`
2. Create `host_vars/<hostname>.yml` with VM-specific config
3. Create `playbooks/configure-<hostname>.yml` playbook
4. Run the playbook

## Per-VM Configuration Files

Each VM has its own `host_vars/<hostname>.yml` file containing:

- **VM Identity**: vmid, hostname, fqdn
- **Network**: IP, gateway, DNS, VLAN
- **OS**: Type (ubuntu/rocky), version, template
- **Resources**: CPU, memory, disk
- **Proxmox**: Tags, pool, storage
- **Packages**: Lists of packages to install
- **Users**: Admin user configuration
- **Services**: Services to enable/disable

## Network Configuration

The playbook automatically detects OS type and applies the correct network configuration:

- **Ubuntu**: Uses netplan (`/etc/netplan/01-netcfg.yaml`)
- **Rocky**: Uses NetworkManager (`/etc/NetworkManager/system-connections/ens18.nmconnection`)

## Current VMs

| VMID | Hostname    | IP           | OS Type | Role              |
|------|-------------|--------------|---------|-------------------|
| 300  | ws-admin01  | 10.0.130.10  | ubuntu  | Admin Workstation |

