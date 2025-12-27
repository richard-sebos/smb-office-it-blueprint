#!/bin/bash
################################################################################
# Script: create-opnsense-vm.sh
# Purpose: Create OPNsense firewall VM on Proxmox
# Author: SMB Office IT Blueprint Project
# Created: 2025-12-27
# Version: 1.0
#
# Description:
#   Creates OPNsense firewall/router VM with two network interfaces:
#   - WAN interface on vmbr0 (lab network)
#   - LAN interface on vmbr1 (internal isolated network)
#
# VM Configuration:
#   - VMID: 100
#   - Name: opnsense-firewall
#   - CPUs: 2 cores
#   - RAM: 4 GB
#   - Disk: 32 GB
#   - Network: vmbr0 (WAN) + vmbr1 (LAN)
#
# Usage:
#   Run this script on the Proxmox host as root:
#   bash create-opnsense-vm.sh
#
# Prerequisites:
#   - OPNsense ISO downloaded to Proxmox (or script will download it)
#   - vmbr0 and vmbr1 bridges configured
#   - Resource pool "infrastructure" created
#
# Post-Creation Steps:
#   1. Start the VM: qm start 100
#   2. Open console: VNC or Proxmox web console
#   3. Install OPNsense following prompts
#   4. Configure WAN interface (vmbr0) - DHCP or static
#   5. Configure LAN interface (vmbr1) - 192.168.10.254/24
#   6. Access web UI: https://192.168.10.254
################################################################################

set -e  # Exit on error
set -u  # Exit on undefined variable

# Configuration
VMID=100
VM_NAME="opnsense-firewall"
CORES=2
MEMORY=4096  # MB
DISK_SIZE="32G"
STORAGE="local-lvm"  # Change if your storage is different
ISO_STORAGE="local"  # Storage for ISO files
POOL="infrastructure"

# Network interfaces
WAN_BRIDGE="vmbr0"  # Lab network
LAN_BRIDGE="vmbr1"  # Internal network

# OPNsense version and download URL
OPNSENSE_VERSION="24.7"
OPNSENSE_ISO="OPNsense-${OPNSENSE_VERSION}-dvd-amd64.iso"
OPNSENSE_URL="https://mirror.ams1.nl.leaseweb.net/opnsense/releases/${OPNSENSE_VERSION}/${OPNSENSE_ISO}.bz2"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

################################################################################
# Functions
################################################################################

log_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

check_prerequisites() {
    log_info "Checking prerequisites..."

    # Check if running as root
    if [ "$EUID" -ne 0 ]; then
        log_error "This script must be run as root"
        exit 1
    fi

    # Check if VMID already exists
    if qm status $VMID &>/dev/null; then
        log_error "VM $VMID already exists!"
        echo ""
        echo "To destroy and recreate:"
        echo "  qm stop $VMID"
        echo "  qm destroy $VMID"
        echo ""
        exit 1
    fi

    # Check if storage exists
    if ! pvesm status | grep -q "^$STORAGE "; then
        log_error "Storage '$STORAGE' not found!"
        echo "Available storage:"
        pvesm status
        exit 1
    fi

    # Check if bridges exist
    if ! ip link show $WAN_BRIDGE &>/dev/null; then
        log_error "Bridge $WAN_BRIDGE not found!"
        exit 1
    fi

    if ! ip link show $LAN_BRIDGE &>/dev/null; then
        log_error "Bridge $LAN_BRIDGE not found!"
        echo "Run the network configuration playbook first:"
        echo "  ansible-playbook playbooks/configure-proxmox-network.yml"
        exit 1
    fi

    log_info "Prerequisites check passed"
}

download_opnsense_iso() {
    local iso_path="/var/lib/vz/template/iso/${OPNSENSE_ISO}"

    if [ -f "$iso_path" ]; then
        log_info "OPNsense ISO already exists: $iso_path"
        return 0
    fi

    log_info "Downloading OPNsense ISO..."
    log_info "Version: $OPNSENSE_VERSION"
    log_info "URL: $OPNSENSE_URL"

    cd /var/lib/vz/template/iso

    # Download compressed ISO
    wget -q --show-progress "$OPNSENSE_URL" -O "${OPNSENSE_ISO}.bz2"

    # Decompress
    log_info "Decompressing ISO..."
    bunzip2 "${OPNSENSE_ISO}.bz2"

    log_info "OPNsense ISO downloaded successfully"
}

create_vm() {
    log_info "Creating OPNsense VM..."

    # Create VM
    qm create $VMID \
        --name $VM_NAME \
        --cores $CORES \
        --memory $MEMORY \
        --ostype other \
        --scsihw virtio-scsi-pci \
        --boot order=scsi0 \
        --onboot 1 \
        --startup order=1 \
        --description "OPNsense Firewall/Router

WAN: ${WAN_BRIDGE} (Lab network)
LAN: ${LAN_BRIDGE} (Internal network 192.168.10.254/24)

Purpose: Routing, NAT, firewall, DHCP, DNS for internal network
Created: $(date '+%Y-%m-%d %H:%M:%S')
Template: OPNsense ${OPNSENSE_VERSION}"

    log_info "VM $VMID created"
}

configure_storage() {
    log_info "Configuring storage..."

    # Add disk
    qm set $VMID --scsi0 ${STORAGE}:${DISK_SIZE}

    # Attach ISO
    qm set $VMID --ide2 ${ISO_STORAGE}:iso/${OPNSENSE_ISO},media=cdrom

    log_info "Storage configured"
}

configure_network() {
    log_info "Configuring network interfaces..."

    # WAN interface (vmbr0 - lab network)
    qm set $VMID --net0 virtio,bridge=${WAN_BRIDGE},firewall=0

    # LAN interface (vmbr1 - internal network)
    qm set $VMID --net1 virtio,bridge=${LAN_BRIDGE},firewall=0

    log_info "Network interfaces configured:"
    log_info "  net0 (WAN): ${WAN_BRIDGE} - Lab network connection"
    log_info "  net1 (LAN): ${LAN_BRIDGE} - Internal network (will be 192.168.10.254)"
}

configure_hardware() {
    log_info "Configuring additional hardware..."

    # Add serial console
    qm set $VMID --serial0 socket

    # VGA console
    qm set $VMID --vga std

    log_info "Hardware configuration complete"
}

add_to_pool() {
    log_info "Adding VM to resource pool..."

    # Check if pool exists
    if ! pvesh get /pools/$POOL &>/dev/null; then
        log_warn "Resource pool '$POOL' does not exist"
        log_info "Creating pool..."
        pvesh create /pools --poolid $POOL --comment "Core infrastructure services"
    fi

    # Add VM to pool
    pvesh set /pools/$POOL --vms $VMID

    log_info "VM added to pool '$POOL'"
}

display_summary() {
    echo ""
    echo "╔════════════════════════════════════════════════════════════════════╗"
    echo "║              OPNSENSE VM CREATED SUCCESSFULLY                     ║"
    echo "╚════════════════════════════════════════════════════════════════════╝"
    echo ""
    echo "VM Details:"
    echo "  VMID: $VMID"
    echo "  Name: $VM_NAME"
    echo "  CPUs: $CORES cores"
    echo "  Memory: $MEMORY MB"
    echo "  Disk: $DISK_SIZE on $STORAGE"
    echo ""
    echo "Network Configuration:"
    echo "  WAN (net0): $WAN_BRIDGE - Your lab network"
    echo "  LAN (net1): $LAN_BRIDGE - Internal network"
    echo ""
    echo "Next Steps:"
    echo ""
    echo "1. Start the VM:"
    echo "   qm start $VMID"
    echo ""
    echo "2. Open console (via Proxmox web UI or):"
    echo "   Open Proxmox Web UI > VM 100 > Console"
    echo ""
    echo "3. Install OPNsense:"
    echo "   - Login: installer / opnsense"
    echo "   - Select 'Install (UFS)'"
    echo "   - Follow installation prompts"
    echo "   - Select keymap, disk, root password"
    echo ""
    echo "4. Configure interfaces after installation:"
    echo "   - Assign interfaces:"
    echo "     - WAN: vtnet0 (first interface)"
    echo "     - LAN: vtnet1 (second interface)"
    echo "   - Configure WAN: DHCP or static from your lab"
    echo "   - Configure LAN: 192.168.10.254/24"
    echo ""
    echo "5. Access Web UI:"
    echo "   https://192.168.10.254"
    echo "   Username: root"
    echo "   Password: opnsense (change immediately!)"
    echo ""
    echo "6. Complete setup wizard:"
    echo "   - Set hostname: opnsense.lab.local"
    echo "   - Configure DNS"
    echo "   - Enable NAT on WAN"
    echo "   - Configure firewall rules"
    echo "   - Set up DHCP for VLANs 20, 30, 40, 50"
    echo ""
}

################################################################################
# Main
################################################################################

main() {
    echo "╔════════════════════════════════════════════════════════════════════╗"
    echo "║          CREATE OPNSENSE FIREWALL VM                              ║"
    echo "╚════════════════════════════════════════════════════════════════════╝"
    echo ""

    check_prerequisites
    download_opnsense_iso
    create_vm
    configure_storage
    configure_network
    configure_hardware
    add_to_pool
    display_summary
}

# Run main function
main
