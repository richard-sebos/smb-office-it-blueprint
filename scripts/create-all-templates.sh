#!/bin/bash
################################################################################
# Script: create-all-templates.sh
# Purpose: Create all VM templates and OPNsense VM in correct order
# Author: SMB Office IT Blueprint Project
# Created: 2025-12-27
# Version: 1.0
#
# Description:
#   Master script to create all templates and VMs needed for the
#   SMB Office IT Blueprint infrastructure.
#
# Creates:
#   1. VM templates (9000, 9100, 9200)
#   2. OPNsense firewall VM (100)
#
# Usage:
#   Run on Proxmox host as root:
#   bash create-all-templates.sh
#
# Options:
#   --templates-only   : Only create templates, skip OPNsense
#   --opnsense-only    : Only create OPNsense, skip templates
################################################################################

set -e
set -u

# Get script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

log_info() { echo -e "${GREEN}[INFO]${NC} $1"; }
log_warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1"; }
log_section() { echo -e "${BLUE}[SECTION]${NC} $1"; }

# Parse arguments
CREATE_TEMPLATES=true
CREATE_OPNSENSE=true

while [[ $# -gt 0 ]]; do
    case $1 in
        --templates-only)
            CREATE_OPNSENSE=false
            shift
            ;;
        --opnsense-only)
            CREATE_TEMPLATES=false
            shift
            ;;
        *)
            log_error "Unknown option: $1"
            echo "Usage: $0 [--templates-only | --opnsense-only]"
            exit 1
            ;;
    esac
done

check_prerequisites() {
    log_info "Checking prerequisites..."

    if [ "$EUID" -ne 0 ]; then
        log_error "This script must be run as root"
        exit 1
    fi

    # Check if scripts exist
    local required_scripts=(
        "create-ubuntu-template.sh"
        "create-debian-template.sh"
        "create-rocky-template.sh"
        "create-opnsense-vm.sh"
    )

    for script in "${required_scripts[@]}"; do
        if [ ! -f "$SCRIPT_DIR/$script" ]; then
            log_error "Required script not found: $script"
            exit 1
        fi
        # Make executable
        chmod +x "$SCRIPT_DIR/$script"
    done

    log_info "All required scripts found and executable"
}

create_templates() {
    log_section "Creating VM Templates"
    echo ""

    local templates=(
        "create-ubuntu-template.sh:Ubuntu 22.04 LTS"
        "create-debian-template.sh:Debian 12"
        "create-rocky-template.sh:Rocky Linux 9"
    )

    for template_info in "${templates[@]}"; do
        IFS=: read -r script description <<< "$template_info"

        log_info "Creating $description template..."
        echo ""

        if bash "$SCRIPT_DIR/$script"; then
            log_info "$description template created successfully"
        else
            log_error "Failed to create $description template"
            log_warn "Continuing with remaining templates..."
        fi

        echo ""
        echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
        echo ""
    done
}

create_opnsense() {
    log_section "Creating OPNsense Firewall VM"
    echo ""

    log_info "Creating OPNsense VM..."
    echo ""

    if bash "$SCRIPT_DIR/create-opnsense-vm.sh"; then
        log_info "OPNsense VM created successfully"
    else
        log_error "Failed to create OPNsense VM"
        return 1
    fi

    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
}

display_final_summary() {
    echo ""
    echo "╔════════════════════════════════════════════════════════════════════╗"
    echo "║              ALL VMs/TEMPLATES CREATED                            ║"
    echo "╚════════════════════════════════════════════════════════════════════╝"
    echo ""

    if [ "$CREATE_TEMPLATES" = true ]; then
        echo "Templates Created:"
        echo "  ✓ VM 9000: ubuntu-2204-template"
        echo "  ✓ VM 9100: debian-12-template"
        echo "  ✓ VM 9200: rocky-9-template"
        echo ""
    fi

    if [ "$CREATE_OPNSENSE" = true ]; then
        echo "VMs Created:"
        echo "  ✓ VM 100: opnsense-firewall (needs installation)"
        echo ""
    fi

    echo "Next Steps:"
    echo ""

    if [ "$CREATE_OPNSENSE" = true ]; then
        echo "1. Install and Configure OPNsense:"
        echo "   - Start VM: qm start 100"
        echo "   - Open console in Proxmox Web UI"
        echo "   - Install OPNsense (login: installer/opnsense)"
        echo "   - Configure WAN (vmbr0) and LAN (vmbr1) interfaces"
        echo "   - Set LAN IP: 192.168.10.254/24"
        echo "   - Access web UI: https://192.168.10.254"
        echo ""
    fi

    if [ "$CREATE_TEMPLATES" = true ]; then
        echo "2. Clone VMs from Templates:"
        echo "   qm clone 9000 110 --name project-ansible-server --full"
        echo "   qm clone 9000 120 --name monitoring-server --full"
        echo "   qm clone 9100 200 --name domain-controller --full"
        echo "   qm clone 9000 210 --name file-server --full"
        echo ""
        echo "3. Customize Cloned VMs:"
        echo "   qm set <vmid> --memory <MB> --cores <N>"
        echo "   qm set <vmid> --ipconfig0 ip=<IP>/24,gw=192.168.10.254"
        echo "   qm set <vmid> --sshkeys ~/.ssh/authorized_keys"
        echo "   qm resize <vmid> scsi0 +<size>G"
        echo ""
    fi

    echo "4. View all VMs:"
    echo "   qm list"
    echo ""
    echo "5. Check resource pools:"
    echo "   pvesh get /pools"
    echo ""
}

main() {
    echo "╔════════════════════════════════════════════════════════════════════╗"
    echo "║          CREATE ALL TEMPLATES AND VMs                             ║"
    echo "╚════════════════════════════════════════════════════════════════════╝"
    echo ""

    if [ "$CREATE_TEMPLATES" = false ] && [ "$CREATE_OPNSENSE" = false ]; then
        log_error "Nothing to do! (both templates and opnsense disabled)"
        exit 1
    fi

    check_prerequisites

    if [ "$CREATE_TEMPLATES" = true ]; then
        create_templates
    fi

    if [ "$CREATE_OPNSENSE" = true ]; then
        create_opnsense
    fi

    display_final_summary
}

main
