#!/bin/bash
################################################################################
# Script: first-time-setup-checklist.sh
# Purpose: Interactive checklist for first-time Project Ansible Server setup
# Author: SMB Office IT Blueprint Project
# Created: 2025-12-26
# Version: 1.0
#
# Description:
#   Walks through the initial setup steps needed before running any
#   Proxmox automation playbooks. Verifies configuration and helps
#   troubleshoot common issues.
#
# Usage:
#   ./scripts/first-time-setup-checklist.sh
################################################################################

set -euo pipefail

# Color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Expected project directory
PROJECT_DIR="/opt/project-ansible"

################################################################################
# Helper Functions
################################################################################

print_header() {
    echo ""
    echo -e "${BLUE}════════════════════════════════════════════════════════════════${NC}"
    echo -e "${CYAN}  $1${NC}"
    echo -e "${BLUE}════════════════════════════════════════════════════════════════${NC}"
    echo ""
}

print_step() {
    echo -e "${CYAN}▸ $1${NC}"
}

print_success() {
    echo -e "${GREEN}  ✓ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}  ⚠ $1${NC}"
}

print_error() {
    echo -e "${RED}  ✗ $1${NC}"
}

ask_yes_no() {
    local prompt="$1"
    local response
    while true; do
        read -p "$(echo -e ${CYAN}${prompt}${NC} [y/n]: )" response
        case "$response" in
            [Yy]* ) return 0;;
            [Nn]* ) return 1;;
            * ) echo "Please answer yes or no.";;
        esac
    done
}

pause_for_user() {
    echo ""
    read -p "Press ENTER to continue..."
    echo ""
}

################################################################################
# Check Functions
################################################################################

check_directory() {
    print_step "Checking project directory..."

    if [ -d "$PROJECT_DIR" ]; then
        print_success "Project directory exists: $PROJECT_DIR"
        cd "$PROJECT_DIR"
        return 0
    else
        print_error "Project directory not found: $PROJECT_DIR"
        print_warning "Have you run setup-project-ansible-server.sh yet?"
        return 1
    fi
}

check_ansible() {
    print_step "Checking Ansible installation..."

    if command -v ansible &> /dev/null; then
        local version=$(ansible --version | head -1)
        print_success "Ansible installed: $version"
        return 0
    else
        print_error "Ansible not found"
        print_warning "Run: pip3 install ansible"
        return 1
    fi
}

check_python_deps() {
    print_step "Checking Python dependencies..."

    local all_good=true

    if python3 -c "import proxmoxer" 2>/dev/null; then
        print_success "proxmoxer installed"
    else
        print_error "proxmoxer not installed"
        print_warning "Run: pip3 install proxmoxer"
        all_good=false
    fi

    if python3 -c "import requests" 2>/dev/null; then
        print_success "requests installed"
    else
        print_error "requests not installed"
        print_warning "Run: pip3 install requests"
        all_good=false
    fi

    if [ "$all_good" = true ]; then
        return 0
    else
        return 1
    fi
}

check_vault_password() {
    print_step "Checking vault password file..."

    if [ -f ~/.vault_pass ]; then
        print_success "Vault password file exists: ~/.vault_pass"

        # Check permissions
        local perms=$(stat -c "%a" ~/.vault_pass 2>/dev/null || stat -f "%OLp" ~/.vault_pass 2>/dev/null)
        if [ "$perms" = "600" ]; then
            print_success "Vault password file has correct permissions (600)"
        else
            print_warning "Vault password file permissions are $perms (should be 600)"
            chmod 600 ~/.vault_pass
            print_success "Fixed permissions to 600"
        fi
        return 0
    else
        print_error "Vault password file not found: ~/.vault_pass"
        print_warning "Run: ./scripts/init-vault.sh"
        return 1
    fi
}

check_vault_file() {
    print_step "Checking vault configuration..."

    local vault_file="$PROJECT_DIR/group_vars/all/vault.yml"

    if [ -f "$vault_file" ]; then
        print_success "Vault file exists: $vault_file"

        # Check if encrypted
        if head -1 "$vault_file" | grep -q "ANSIBLE_VAULT"; then
            print_success "Vault file is encrypted"

            # Try to decrypt and check for placeholder values
            if ansible-vault view "$vault_file" 2>/dev/null | grep -q "REPLACE-WITH-YOUR-TOKEN-SECRET"; then
                print_warning "Vault still contains placeholder values"
                print_warning "Edit vault and add real Proxmox credentials"
                return 1
            else
                print_success "Vault appears to have real credentials configured"
                return 0
            fi
        else
            print_warning "Vault file exists but is NOT encrypted"
            print_warning "Run: ansible-vault encrypt $vault_file"
            return 1
        fi
    else
        print_error "Vault file not found: $vault_file"
        print_warning "Copy template: cp group_vars/all/vault.yml.template group_vars/all/vault.yml"
        return 1
    fi
}

check_inventory() {
    print_step "Checking inventory configuration..."

    local inventory_file="$PROJECT_DIR/inventory/hosts.yml"

    if [ -f "$inventory_file" ]; then
        print_success "Inventory file exists: $inventory_file"

        # Check for default IP
        if grep -q "192.168.1.100" "$inventory_file"; then
            print_warning "Inventory still has default IP (192.168.1.100)"
            print_warning "Update with your actual Proxmox IP address"
            return 1
        else
            print_success "Inventory has been customized"

            # Extract and display Proxmox IP
            local proxmox_ip=$(grep "ansible_host:" "$inventory_file" | head -1 | awk '{print $2}')
            echo -e "${CYAN}    Proxmox Host: $proxmox_ip${NC}"
            return 0
        fi
    else
        print_error "Inventory file not found: $inventory_file"
        return 1
    fi
}

check_proxmox_connectivity() {
    print_step "Checking network connectivity to Proxmox..."

    local proxmox_ip=$(grep "ansible_host:" "$PROJECT_DIR/inventory/hosts.yml" | grep -v "127.0.0.1" | head -1 | awk '{print $2}')

    if [ -z "$proxmox_ip" ]; then
        print_error "Could not determine Proxmox IP from inventory"
        return 1
    fi

    echo -e "${CYAN}    Testing: $proxmox_ip${NC}"

    # Ping test
    if ping -c 2 -W 2 "$proxmox_ip" &>/dev/null; then
        print_success "Host is reachable (ping)"
    else
        print_warning "Host not responding to ping (may have ICMP disabled)"
    fi

    # Port 8006 test
    if timeout 3 bash -c "cat < /dev/null > /dev/tcp/$proxmox_ip/8006" 2>/dev/null; then
        print_success "Proxmox API port 8006 is accessible"
        return 0
    else
        print_error "Cannot connect to port 8006 on $proxmox_ip"
        print_warning "Check firewall rules and network connectivity"
        return 1
    fi
}

################################################################################
# Setup Guidance Functions
################################################################################

guide_proxmox_user_creation() {
    print_header "PROXMOX USER SETUP REQUIRED"

    echo "Before Ansible can manage Proxmox, you need to create a dedicated user"
    echo "on your Proxmox host with API token authentication."
    echo ""
    echo "Follow these steps ON YOUR PROXMOX HOST:"
    echo ""
    echo -e "${GREEN}# 1. Create user${NC}"
    echo "pveum user add ansible-project@pve --comment \"Ansible Project Automation User\""
    echo ""
    echo -e "${GREEN}# 2. Create custom role${NC}"
    echo 'pveum role add ProjectAutomation \'
    echo '  --privs "VM.Allocate VM.Audit VM.Config.CDROM VM.Config.CPU VM.Config.Cloudinit \'
    echo '           VM.Config.Disk VM.Config.HWType VM.Config.Memory VM.Config.Network \'
    echo '           VM.Config.Options VM.Clone VM.Console VM.PowerMgmt VM.Monitor \'
    echo '           Datastore.Allocate Datastore.Audit Pool.Allocate Pool.Audit Sys.Audit \'
    echo '           SDN.Audit SDN.Allocate"'
    echo ""
    echo -e "${GREEN}# 3. Assign role to user${NC}"
    echo "pveum acl modify / --user ansible-project@pve --role ProjectAutomation"
    echo ""
    echo -e "${GREEN}# 4. Create API token${NC}"
    echo "pveum user token add ansible-project@pve project-automation --privsep 0"
    echo ""
    echo -e "${YELLOW}IMPORTANT: Copy the token secret that is displayed!${NC}"
    echo ""

    if ask_yes_no "Have you completed these steps on Proxmox?"; then
        echo ""
        echo "Great! Next, you need to add the token to your vault file."
        echo ""
        pause_for_user
        guide_vault_configuration
    else
        echo ""
        print_warning "Complete Proxmox user setup before proceeding"
    fi
}

guide_vault_configuration() {
    print_header "VAULT CONFIGURATION"

    echo "Now we'll configure your Ansible vault with Proxmox credentials."
    echo ""

    # Check if vault password exists
    if [ ! -f ~/.vault_pass ]; then
        print_warning "Vault password not configured"
        if ask_yes_no "Initialize vault password now?"; then
            ./scripts/init-vault.sh
        else
            return 1
        fi
    fi

    # Check if vault.yml exists
    local vault_file="$PROJECT_DIR/group_vars/all/vault.yml"
    if [ ! -f "$vault_file" ]; then
        echo "Creating vault file from template..."
        cp "$PROJECT_DIR/group_vars/all/vault.yml.template" "$vault_file"
        print_success "Created $vault_file"
    fi

    echo ""
    echo "Edit the vault file and add your Proxmox API token:"
    echo ""
    echo -e "${CYAN}  ansible-vault edit group_vars/all/vault.yml${NC}"
    echo ""
    echo "Replace these placeholder values:"
    echo "  - vault_proxmox_api_token_id: \"project-automation\""
    echo "  - vault_proxmox_api_token_secret: \"YOUR-TOKEN-SECRET-HERE\""
    echo ""

    if ask_yes_no "Edit vault file now?"; then
        ansible-vault edit "$vault_file"

        # Verify it's encrypted
        if head -1 "$vault_file" | grep -q "ANSIBLE_VAULT"; then
            print_success "Vault file is encrypted"
        else
            print_warning "Encrypting vault file..."
            ansible-vault encrypt "$vault_file"
        fi
    fi
}

guide_inventory_update() {
    print_header "INVENTORY CONFIGURATION"

    echo "Update your inventory file with your Proxmox server details."
    echo ""
    echo "Edit: $PROJECT_DIR/inventory/hosts.yml"
    echo ""
    echo "Update these values:"
    echo "  - ansible_host: YOUR-PROXMOX-IP"
    echo "  - proxmox_api_host: YOUR-PROXMOX-IP"
    echo "  - proxmox_node: YOUR-NODE-NAME (usually 'pve')"
    echo ""

    if ask_yes_no "Edit inventory now?"; then
        ${EDITOR:-vim} "$PROJECT_DIR/inventory/hosts.yml"
        print_success "Inventory updated"
    fi
}

################################################################################
# Main Execution
################################################################################

main() {
    print_header "PROJECT ANSIBLE SERVER - FIRST TIME SETUP"

    echo "This script will verify your Ansible server is properly configured"
    echo "to manage your Proxmox host."
    echo ""

    pause_for_user

    # Track overall status
    local all_checks_passed=true

    # Run checks
    print_header "STEP 1: ENVIRONMENT CHECKS"

    check_directory || all_checks_passed=false
    echo ""

    check_ansible || all_checks_passed=false
    echo ""

    check_python_deps || all_checks_passed=false
    echo ""

    print_header "STEP 2: CONFIGURATION CHECKS"

    check_vault_password || { all_checks_passed=false; guide_vault_configuration; }
    echo ""

    check_vault_file || { all_checks_passed=false; guide_vault_configuration; }
    echo ""

    check_inventory || { all_checks_passed=false; guide_inventory_update; }
    echo ""

    print_header "STEP 3: CONNECTIVITY CHECKS"

    check_proxmox_connectivity || all_checks_passed=false
    echo ""

    # Final summary
    print_header "SETUP SUMMARY"

    if [ "$all_checks_passed" = true ]; then
        print_success "All checks passed!"
        echo ""
        echo "You are ready to test Proxmox API connectivity."
        echo ""
        echo "Next step:"
        echo -e "${GREEN}  ansible-playbook playbooks/test-proxmox-api.yml${NC}"
        echo ""
    else
        print_warning "Some checks failed"
        echo ""
        echo "Review the messages above and complete the required setup steps."
        echo ""
        echo "Common next steps:"
        echo "  1. Initialize vault password: ./scripts/init-vault.sh"
        echo "  2. Create Proxmox user (see guide above)"
        echo "  3. Configure vault: ansible-vault edit group_vars/all/vault.yml"
        echo "  4. Update inventory: vim inventory/hosts.yml"
        echo ""

        if ask_yes_no "Do you need help creating the Proxmox user?"; then
            guide_proxmox_user_creation
        fi
    fi
}

# Run main function
main "$@"
