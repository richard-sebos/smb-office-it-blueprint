#!/bin/bash
################################################################################
# Script: setup-project-ansible-server.sh
# Purpose: Setup Oracle Linux 9 as Project Ansible Server
# Author: Richard Sebos
# Created: 2025-12-26
# Version: 1.0
#
# Description:
#   Configures a fresh Oracle Linux 9 server as the Project Ansible Server
#   including:
#   - User account creation
#   - Ansible installation
#   - Python dependencies
#   - Project workspace setup
#   - SSH configuration
#   - Security hardening
#
# Usage:
#   sudo ./setup-project-ansible-server.sh
#
# Requirements:
#   - Oracle Linux 9 with updates applied
#   - Root or sudo access
#   - Internet connectivity
################################################################################

set -euo pipefail  # Exit on error, undefined vars, pipe failures

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration variables
ANSIBLE_USER="ansible-admin"
ANSIBLE_USER_COMMENT="Ansible Project Administrator"
PROJECT_DIR="/opt/project-ansible"
GIT_REPO_URL=""  # Set this if you want to clone existing repo
VAULT_PASS_FILE="/home/${ANSIBLE_USER}/.vault_pass"

################################################################################
# Helper Functions
################################################################################

log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

check_root() {
    if [[ $EUID -ne 0 ]]; then
        log_error "This script must be run as root or with sudo"
        exit 1
    fi
}

################################################################################
# Main Setup Functions
################################################################################

install_base_packages() {
    log_info "Installing base packages..."

    dnf install -y \
        git \
        vim \
        curl \
        wget \
        tar \
        unzip \
        jq \
        tree \
        python3 \
        python3-pip \
        python3-devel \
        gcc \
        openssl-devel \
        libffi-devel \
        sshpass

    log_success "Base packages installed"
}

create_ansible_user() {
    log_info "Creating Ansible administrator user: ${ANSIBLE_USER}"

    # Check if user already exists
    if id "${ANSIBLE_USER}" &>/dev/null; then
        log_warning "User ${ANSIBLE_USER} already exists, skipping creation"
        return 0
    fi

    # Create user with home directory
    useradd -m -s /bin/bash -c "${ANSIBLE_USER_COMMENT}" "${ANSIBLE_USER}"

    # Add to wheel group (sudo access)
    usermod -aG wheel "${ANSIBLE_USER}"

    # Set password (you'll be prompted)
    log_info "Please set password for ${ANSIBLE_USER}:"
    passwd "${ANSIBLE_USER}"

    log_success "User ${ANSIBLE_USER} created and added to wheel group"
}

configure_sudo() {
    log_info "Configuring sudo access for ${ANSIBLE_USER}..."

    # Allow wheel group sudo access without password for ansible commands
    # (Optional - remove NOPASSWD: for more security)
    cat > /etc/sudoers.d/${ANSIBLE_USER} << EOF
# Ansible administrator sudo configuration
${ANSIBLE_USER} ALL=(ALL) NOPASSWD: ALL
EOF

    chmod 0440 /etc/sudoers.d/${ANSIBLE_USER}

    log_success "Sudo access configured"
}

install_ansible() {
    log_info "Installing Ansible and Python dependencies..."

    # Upgrade pip
    python3 -m pip install --upgrade pip

    # Install Ansible and required libraries
    python3 -m pip install \
        ansible \
        ansible-core \
        proxmoxer \
        requests \
        jinja2 \
        paramiko \
        cryptography \
        pyyaml

    # Install Ansible linting tools
    python3 -m pip install \
        ansible-lint \
        yamllint

    # Verify installation
    /usr/local/bin/ansible --version

    log_success "Ansible installed: $(ansible --version | head -1)"
}

install_ansible_collections() {
    log_info "Installing required Ansible collections..."

    # Create temporary requirements file
    cat > /tmp/ansible-collections.yml << EOF
---
collections:
  - name: community.general
    version: ">=8.0.0"

  - name: ansible.posix
    version: ">=1.5.0"

  - name: community.crypto
    version: ">=2.0.0"
EOF

    # Install collections as ansible-admin user
    sudo -u "${ANSIBLE_USER}" /usr/local/bin/ansible-galaxy collection install -r /tmp/ansible-collections.yml

    rm /tmp/ansible-collections.yml

    log_success "Ansible collections installed"
}

create_project_structure() {
    log_info "Creating project directory structure..."

    # Create main project directory
    mkdir -p "${PROJECT_DIR}"

    # Create standard Ansible directory structure
    mkdir -p "${PROJECT_DIR}"/{playbooks,roles,inventory,library,filter_plugins,module_utils}
    mkdir -p "${PROJECT_DIR}"/group_vars/{all,proxmox}
    mkdir -p "${PROJECT_DIR}"/host_vars
    mkdir -p "${PROJECT_DIR}"/files
    mkdir -p "${PROJECT_DIR}"/templates
    mkdir -p "${PROJECT_DIR}"/scripts
    mkdir -p "${PROJECT_DIR}"/logs
    mkdir -p "${PROJECT_DIR}"/docs

    # Create role directories
    mkdir -p "${PROJECT_DIR}"/roles/{proxmox_network,proxmox_pools,proxmox_vms,proxmox_backup,proxmox_templates}

    # Set ownership to ansible-admin
    chown -R "${ANSIBLE_USER}":"${ANSIBLE_USER}" "${PROJECT_DIR}"

    # Set appropriate permissions
    chmod 755 "${PROJECT_DIR}"
    chmod 750 "${PROJECT_DIR}"/group_vars/all  # Vault files will be here

    log_success "Project structure created at ${PROJECT_DIR}"
}

create_ansible_config() {
    log_info "Creating ansible.cfg configuration..."

    cat > "${PROJECT_DIR}/ansible.cfg" << 'EOF'
[defaults]
inventory = ./inventory/hosts.yml
roles_path = ./roles
vault_password_file = ~/.vault_pass
host_key_checking = False
retry_files_enabled = False
gathering = smart
fact_caching = jsonfile
fact_caching_connection = /tmp/ansible_facts
fact_caching_timeout = 3600
callbacks_enabled = profile_tasks, timer
log_path = ./logs/ansible.log
deprecation_warnings = False
interpreter_python = auto_silent
forks = 10

[privilege_escalation]
become = True
become_method = sudo
become_user = root
become_ask_pass = False

[ssh_connection]
pipelining = True
control_path = /tmp/ansible-%%r@%%h:%%p
ssh_args = -o ControlMaster=auto -o ControlPersist=60s

[inventory]
enable_plugins = host_list, yaml, ini, auto
EOF

    chown "${ANSIBLE_USER}":"${ANSIBLE_USER}" "${PROJECT_DIR}/ansible.cfg"
    chmod 644 "${PROJECT_DIR}/ansible.cfg"

    log_success "ansible.cfg created"
}

create_inventory_template() {
    log_info "Creating inventory template..."

    cat > "${PROJECT_DIR}/inventory/hosts.yml" << 'EOF'
---
# Ansible Inventory for SMB Office IT Blueprint Project
# Project Ansible Server - Proxmox Infrastructure Management

all:
  children:
    # Proxmox host (for direct configuration if needed)
    proxmox_hosts:
      hosts:
        pve:
          ansible_host: 192.168.1.100  # CHANGE THIS to your Proxmox IP
          ansible_user: root
          ansible_python_interpreter: /usr/bin/python3
      vars:
        ansible_connection: ssh

    # Localhost (for API-based Proxmox management)
    localhost:
      hosts:
        127.0.0.1:
          ansible_connection: local
          ansible_python_interpreter: /usr/bin/python3

  vars:
    # Global variables
    project_name: smb-office-it-blueprint
    proxmox_node: pve
    proxmox_api_host: 192.168.1.100  # CHANGE THIS
    proxmox_api_validate_certs: false
EOF

    chown "${ANSIBLE_USER}":"${ANSIBLE_USER}" "${PROJECT_DIR}/inventory/hosts.yml"
    chmod 644 "${PROJECT_DIR}/inventory/hosts.yml"

    log_success "Inventory template created"
}

create_vault_template() {
    log_info "Creating vault templates..."

    # Create unencrypted vars file
    cat > "${PROJECT_DIR}/group_vars/all/vars.yml" << 'EOF'
---
# Unencrypted variables
# Reference encrypted vault variables using {{ vault_variable_name }}

# Proxmox API Configuration
proxmox_api_user: "ansible-project@pve"
proxmox_api_token_id: "{{ vault_proxmox_api_token_id }}"
proxmox_api_token_secret: "{{ vault_proxmox_api_token_secret }}"

# Project Configuration
project_environment: lab
deployment_date: "{{ ansible_date_time.date }}"
EOF

    # Create vault file template (unencrypted for now)
    cat > "${PROJECT_DIR}/group_vars/all/vault.yml.template" << 'EOF'
---
# Encrypted Vault Variables
# IMPORTANT: Encrypt this file after adding credentials:
#   ansible-vault encrypt group_vars/all/vault.yml

# Proxmox API Credentials
vault_proxmox_api_token_id: "project-automation"
vault_proxmox_api_token_secret: "REPLACE-WITH-YOUR-TOKEN-SECRET"

# Optional: Root password (if not using tokens)
# vault_proxmox_root_password: "YourSecurePassword"

# VM SSH Keys (generated later)
# vault_vm_root_password: "TemporaryRootPassword"
EOF

    chown "${ANSIBLE_USER}":"${ANSIBLE_USER}" "${PROJECT_DIR}"/group_vars/all/*.yml*
    chmod 640 "${PROJECT_DIR}"/group_vars/all/vars.yml
    chmod 640 "${PROJECT_DIR}"/group_vars/all/vault.yml.template

    log_success "Vault templates created"
}

configure_ssh_keys() {
    log_info "Generating SSH keys for ${ANSIBLE_USER}..."

    # Switch to ansible-admin user for key generation
    sudo -u "${ANSIBLE_USER}" bash << 'EOSU'
    if [ ! -f ~/.ssh/id_ed25519 ]; then
        ssh-keygen -t ed25519 -C "ansible-admin@project-ansible-server" -f ~/.ssh/id_ed25519 -N ""
        echo "SSH key generated: ~/.ssh/id_ed25519"
    else
        echo "SSH key already exists, skipping generation"
    fi

    # Set proper permissions
    chmod 700 ~/.ssh
    chmod 600 ~/.ssh/id_ed25519
    chmod 644 ~/.ssh/id_ed25519.pub
EOSU

    log_success "SSH keys configured"
}

create_helper_scripts() {
    log_info "Creating helper scripts..."

    # Script to initialize vault password
    cat > "${PROJECT_DIR}/scripts/init-vault.sh" << 'EOF'
#!/bin/bash
# Initialize Ansible Vault password

VAULT_PASS_FILE="${HOME}/.vault_pass"

echo "Ansible Vault Password Initialization"
echo "======================================"
echo ""
echo "This will create your vault password file at: ${VAULT_PASS_FILE}"
echo ""
read -sp "Enter vault password: " VAULT_PASSWORD
echo ""
read -sp "Confirm vault password: " VAULT_PASSWORD_CONFIRM
echo ""

if [ "${VAULT_PASSWORD}" != "${VAULT_PASSWORD_CONFIRM}" ]; then
    echo "ERROR: Passwords do not match"
    exit 1
fi

if [ -z "${VAULT_PASSWORD}" ]; then
    echo "ERROR: Password cannot be empty"
    exit 1
fi

echo "${VAULT_PASSWORD}" > "${VAULT_PASS_FILE}"
chmod 600 "${VAULT_PASS_FILE}"

echo ""
echo "Vault password file created: ${VAULT_PASS_FILE}"
echo "IMPORTANT: Keep this password secure and backed up!"
echo ""
echo "Next steps:"
echo "  1. Copy group_vars/all/vault.yml.template to group_vars/all/vault.yml"
echo "  2. Edit vault.yml and add your Proxmox credentials"
echo "  3. Encrypt the vault: ansible-vault encrypt group_vars/all/vault.yml"
EOF

    chmod +x "${PROJECT_DIR}/scripts/init-vault.sh"

    # Script to test Proxmox connectivity
    cat > "${PROJECT_DIR}/scripts/test-proxmox-connection.sh" << 'EOF'
#!/bin/bash
# Test Proxmox API connectivity

echo "Testing Proxmox API Connection"
echo "==============================="
echo ""

# Load configuration
cd /opt/project-ansible

PROXMOX_HOST=$(grep proxmox_api_host inventory/hosts.yml | awk '{print $2}')

if [ -z "${PROXMOX_HOST}" ]; then
    echo "ERROR: Could not find proxmox_api_host in inventory/hosts.yml"
    exit 1
fi

echo "Proxmox Host: ${PROXMOX_HOST}"
echo ""

# Test basic connectivity
echo "Testing basic connectivity..."
if ping -c 2 "${PROXMOX_HOST}" &>/dev/null; then
    echo "✓ Host is reachable"
else
    echo "✗ Host is NOT reachable"
    exit 1
fi

# Test HTTPS connectivity
echo ""
echo "Testing HTTPS connectivity..."
if curl -k -s "https://${PROXMOX_HOST}:8006" &>/dev/null; then
    echo "✓ Proxmox web interface is accessible"
else
    echo "✗ Proxmox web interface is NOT accessible"
    exit 1
fi

echo ""
echo "Next step: Run a test playbook to verify API authentication"
echo "  ansible-playbook playbooks/test-proxmox-api.yml"
EOF

    chmod +x "${PROJECT_DIR}/scripts/test-proxmox-connection.sh"

    # Set ownership
    chown -R "${ANSIBLE_USER}":"${ANSIBLE_USER}" "${PROJECT_DIR}/scripts"

    log_success "Helper scripts created"
}

create_gitignore() {
    log_info "Creating .gitignore..."

    cat > "${PROJECT_DIR}/.gitignore" << 'EOF'
# Ansible
*.retry
.vault_pass
group_vars/all/vault.yml

# Python
__pycache__/
*.py[cod]
*$py.class
*.so
.Python
.venv/
venv/
ENV/
env/

# IDE
.vscode/
.idea/
*.swp
*.swo
*~
.DS_Store

# Logs
*.log
logs/*.log

# Ansible facts cache
/tmp/ansible_facts/

# Backup files
*.bak
*.backup
*~

# Temporary files
*.tmp
.tmp/
EOF

    chown "${ANSIBLE_USER}":"${ANSIBLE_USER}" "${PROJECT_DIR}/.gitignore"
    chmod 644 "${PROJECT_DIR}/.gitignore"

    log_success ".gitignore created"
}

configure_firewall() {
    log_info "Configuring firewall..."

    # Enable and start firewalld
    systemctl enable --now firewalld

    # Allow SSH (should already be allowed)
    firewall-cmd --permanent --add-service=ssh

    # Reload firewall
    firewall-cmd --reload

    log_success "Firewall configured"
}

configure_selinux() {
    log_info "Configuring SELinux..."

    # Ensure SELinux is enforcing
    setenforce 1

    # Set SELinux context for project directory
    semanage fcontext -a -t user_home_dir_t "${PROJECT_DIR}(/.*)?" 2>/dev/null || true
    restorecon -Rv "${PROJECT_DIR}" || true

    log_success "SELinux configured"
}

create_readme() {
    log_info "Creating README..."

    cat > "${PROJECT_DIR}/README.md" << 'EOF'
# Project Ansible Server - SMB Office IT Blueprint

This is the Project Ansible Server for managing Proxmox virtualization infrastructure.

## Quick Start

### 1. Initialize Vault Password

```bash
cd /opt/project-ansible
./scripts/init-vault.sh
```

### 2. Configure Proxmox Credentials

```bash
# Copy vault template
cp group_vars/all/vault.yml.template group_vars/all/vault.yml

# Edit and add your Proxmox API token
vim group_vars/all/vault.yml

# Encrypt the vault
ansible-vault encrypt group_vars/all/vault.yml
```

### 3. Update Inventory

Edit `inventory/hosts.yml` and update:
- Proxmox host IP address
- Proxmox node name

### 4. Test Connection

```bash
./scripts/test-proxmox-connection.sh
```

### 5. Run Your First Playbook

```bash
ansible-playbook playbooks/test-proxmox-api.yml
```

## Directory Structure

```
/opt/project-ansible/
├── ansible.cfg              # Ansible configuration
├── inventory/               # Inventory files
│   └── hosts.yml           # Main inventory
├── group_vars/             # Group variables
│   ├── all/                # Variables for all hosts
│   │   ├── vars.yml        # Unencrypted variables
│   │   └── vault.yml       # Encrypted secrets
│   └── proxmox/            # Proxmox-specific vars
├── playbooks/              # Ansible playbooks
├── roles/                  # Ansible roles
├── scripts/                # Helper scripts
├── logs/                   # Ansible logs
└── docs/                   # Documentation
```

## Important Files

- `~/.vault_pass` - Vault password file (KEEP SECURE!)
- `~/.ssh/id_ed25519` - SSH private key
- `group_vars/all/vault.yml` - Encrypted credentials

## Common Commands

```bash
# Test playbook syntax
ansible-playbook playbooks/deploy.yml --syntax-check

# Dry run (check mode)
ansible-playbook playbooks/deploy.yml --check

# Run playbook
ansible-playbook playbooks/deploy.yml

# Edit encrypted vault
ansible-vault edit group_vars/all/vault.yml

# View encrypted vault
ansible-vault view group_vars/all/vault.yml
```

## Security Notes

- Keep `~/.vault_pass` secure and backed up
- Never commit unencrypted secrets to git
- Regularly rotate Proxmox API tokens
- Use SSH keys instead of passwords for VM access

## Support

For issues or questions, refer to:
- Project documentation: `/opt/project-ansible/docs/`
- Ansible docs: https://docs.ansible.com/
- Proxmox API: https://pve.proxmox.com/pve-docs/api-viewer/
EOF

    chown "${ANSIBLE_USER}":"${ANSIBLE_USER}" "${PROJECT_DIR}/README.md"
    chmod 644 "${PROJECT_DIR}/README.md"

    log_success "README created"
}

print_summary() {
    echo ""
    echo "========================================================================"
    log_success "Project Ansible Server Setup Complete!"
    echo "========================================================================"
    echo ""
    echo "Configuration Summary:"
    echo "  • User created: ${ANSIBLE_USER}"
    echo "  • Project directory: ${PROJECT_DIR}"
    echo "  • Ansible version: $(ansible --version | head -1)"
    echo "  • Python version: $(python3 --version)"
    echo ""
    echo "Next Steps:"
    echo ""
    echo "1. Switch to ansible-admin user:"
    echo "   sudo su - ${ANSIBLE_USER}"
    echo ""
    echo "2. Initialize vault password:"
    echo "   cd ${PROJECT_DIR}"
    echo "   ./scripts/init-vault.sh"
    echo ""
    echo "3. Configure Proxmox credentials:"
    echo "   cp group_vars/all/vault.yml.template group_vars/all/vault.yml"
    echo "   vim group_vars/all/vault.yml  # Add your Proxmox API token"
    echo "   ansible-vault encrypt group_vars/all/vault.yml"
    echo ""
    echo "4. Update inventory with your Proxmox IP:"
    echo "   vim inventory/hosts.yml"
    echo ""
    echo "5. Test Proxmox connection:"
    echo "   ./scripts/test-proxmox-connection.sh"
    echo ""
    echo "6. Copy your SSH public key to distribute to VMs:"
    echo "   cat ~/.ssh/id_ed25519.pub"
    echo ""
    echo "Important Security Notes:"
    echo "  • Vault password stored in: ~/.vault_pass"
    echo "  • SSH private key: ~/.ssh/id_ed25519"
    echo "  • Keep both files secure and backed up!"
    echo ""
    echo "Documentation: ${PROJECT_DIR}/README.md"
    echo "========================================================================"
    echo ""
}

################################################################################
# Main Execution
################################################################################

main() {
    log_info "Starting Project Ansible Server setup on Oracle Linux 9..."
    echo ""

    check_root

    install_base_packages
    create_ansible_user
    configure_sudo
    install_ansible
    install_ansible_collections
    create_project_structure
    create_ansible_config
    create_inventory_template
    create_vault_template
    configure_ssh_keys
    create_helper_scripts
    create_gitignore
    configure_firewall
    configure_selinux
    create_readme

    print_summary
}

# Run main function
main "$@"
