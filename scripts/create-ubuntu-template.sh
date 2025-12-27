#!/bin/bash
################################################################################
# Script: create-ubuntu-template.sh
# Purpose: Create Ubuntu 22.04 LTS cloud-init template on Proxmox
# Author: SMB Office IT Blueprint Project
# Created: 2025-12-27
# Version: 1.0
#
# Description:
#   Downloads Ubuntu 22.04 LTS cloud image and creates a VM template
#   ready for rapid cloning and cloud-init configuration.
#
# Template Configuration:
#   - VMID: 9000
#   - Name: ubuntu-2204-template
#   - CPUs: 2 cores
#   - RAM: 2 GB
#   - Disk: 10 GB (expandable)
#   - Cloud-init ready
#
# Usage:
#   Run this script on the Proxmox host as root:
#   bash create-ubuntu-template.sh
#
# After Creation:
#   Clone VMs from this template with:
#   qm clone 9000 <new-vmid> --name <vm-name> --full
################################################################################

set -e
set -u

# Configuration
VMID=9000
VM_NAME="ubuntu-2204-template"
CORES=2
MEMORY=2048
DISK_SIZE="10G"
STORAGE="vmDrive"
POOL="templates"

# Cloud image
IMAGE_URL="https://cloud-images.ubuntu.com/jammy/current/jammy-server-cloudimg-amd64.img"
IMAGE_FILE="ubuntu-22.04-cloudimg.img"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

log_info() { echo -e "${GREEN}[INFO]${NC} $1"; }
log_warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1"; }

check_prerequisites() {
    log_info "Checking prerequisites..."

    if [ "$EUID" -ne 0 ]; then
        log_error "This script must be run as root"
        exit 1
    fi

    if qm status $VMID &>/dev/null; then
        log_error "VM $VMID already exists!"
        echo "To destroy: qm destroy $VMID"
        exit 1
    fi

    if ! pvesm status | grep -q "^$STORAGE "; then
        log_error "Storage '$STORAGE' not found!"
        exit 1
    fi

    # Check for required tools
    for tool in wget qm; do
        if ! command -v $tool &>/dev/null; then
            log_error "Required tool '$tool' not found"
            exit 1
        fi
    done

    log_info "Prerequisites check passed"
}

download_cloud_image() {
    local image_path="/tmp/${IMAGE_FILE}"

    if [ -f "$image_path" ]; then
        log_info "Cloud image already exists: $image_path"
        return 0
    fi

    log_info "Downloading Ubuntu 22.04 LTS cloud image..."
    log_info "URL: $IMAGE_URL"

    wget -q --show-progress "$IMAGE_URL" -O "$image_path"

    log_info "Cloud image downloaded successfully"
}

create_template() {
    log_info "Creating VM template..."

    # Create VM
    qm create $VMID \
        --name $VM_NAME \
        --cores $CORES \
        --memory $MEMORY \
        --net0 virtio,bridge=vmbr1 \
        --scsihw virtio-scsi-pci \
        --ostype l26 \
        --agent enabled=1 \
        --description "Ubuntu 22.04 LTS Cloud Template

Base template for Ubuntu server deployments
Cloud-init enabled for automated configuration

Created: $(date '+%Y-%m-%d %H:%M:%S')
Source: Ubuntu Cloud Images"

    log_info "VM $VMID created"

    # Import cloud image as disk
    log_info "Importing cloud image as disk..."
    qm importdisk $VMID /tmp/${IMAGE_FILE} $STORAGE

    # Attach disk
    log_info "Attaching disk to VM..."
    qm set $VMID --scsi0 ${STORAGE}:vm-${VMID}-disk-0

    # Resize disk
    log_info "Resizing disk to ${DISK_SIZE}..."
    qm resize $VMID scsi0 $DISK_SIZE

    # Add cloud-init drive
    log_info "Adding cloud-init drive..."
    qm set $VMID --ide2 ${STORAGE}:cloudinit

    # Set boot disk
    log_info "Configuring boot order..."
    qm set $VMID --boot order=scsi0

    # Add serial console
    qm set $VMID --serial0 socket --vga serial0

    # Enable QEMU guest agent
    log_info "QEMU guest agent enabled"

    # Convert to template
    log_info "Converting to template..."
    qm template $VMID

    log_info "Template created successfully"
}

add_to_pool() {
    log_info "Adding template to resource pool..."

    if ! pvesh get /pools/$POOL &>/dev/null; then
        log_info "Creating pool '$POOL'..."
        pvesh create /pools --poolid $POOL --comment "VM templates for rapid deployment"
    fi

    pvesh set /pools/$POOL --vms $VMID

    log_info "Template added to pool '$POOL'"
}

cleanup() {
    log_info "Cleaning up temporary files..."
    rm -f /tmp/${IMAGE_FILE}
    log_info "Cleanup complete"
}

display_summary() {
    echo ""
    echo "╔════════════════════════════════════════════════════════════════════╗"
    echo "║         UBUNTU 22.04 TEMPLATE CREATED SUCCESSFULLY                ║"
    echo "╚════════════════════════════════════════════════════════════════════╝"
    echo ""
    echo "Template Details:"
    echo "  VMID: $VMID"
    echo "  Name: $VM_NAME"
    echo "  CPUs: $CORES cores"
    echo "  Memory: $MEMORY MB"
    echo "  Disk: $DISK_SIZE (expandable)"
    echo ""
    echo "To clone a VM from this template:"
    echo "  qm clone $VMID <new-vmid> --name <vm-name> --full"
    echo ""
    echo "Example - Create VM 110 (Project Ansible Server):"
    echo "  qm clone $VMID 110 --name project-ansible-server --full"
    echo "  qm set 110 --memory 4096 --cores 2"
    echo "  qm set 110 --ipconfig0 ip=192.168.10.10/24,gw=192.168.10.254"
    echo "  qm set 110 --sshkeys ~/.ssh/authorized_keys"
    echo "  qm resize 110 scsi0 +90G  # Expand to 100GB total"
    echo "  qm start 110"
    echo ""
}

main() {
    echo "╔════════════════════════════════════════════════════════════════════╗"
    echo "║          CREATE UBUNTU 22.04 LTS TEMPLATE                         ║"
    echo "╚════════════════════════════════════════════════════════════════════╝"
    echo ""

    check_prerequisites
    download_cloud_image
    create_template
    add_to_pool
    cleanup
    display_summary
}

main
