#!/bin/bash
################################################################################
# Script: create-rocky-template.sh
# Purpose: Create Rocky Linux 9 cloud-init template on Proxmox
# Author: SMB Office IT Blueprint Project
# Created: 2025-12-27
# Version: 1.0
#
# Description:
#   Downloads Rocky Linux 9 cloud image and creates a VM template
#   ready for rapid cloning and cloud-init configuration.
#
# Template Configuration:
#   - VMID: 9200
#   - Name: rocky-9-template
#   - CPUs: 2 cores
#   - RAM: 2 GB
#   - Disk: 10 GB (expandable)
#   - Cloud-init ready
################################################################################

set -e
set -u

# Configuration
VMID=9200
VM_NAME="rocky-9-template"
CORES=2
MEMORY=2048
DISK_SIZE="10G"
STORAGE="vmDrive"
POOL="templates"

# Cloud image
IMAGE_URL="https://download.rockylinux.org/pub/rocky/9/images/x86_64/Rocky-9-GenericCloud-Base.latest.x86_64.qcow2"
IMAGE_FILE="rocky-9-cloudimg.qcow2"

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

    log_info "Prerequisites check passed"
}

download_cloud_image() {
    local image_path="/tmp/${IMAGE_FILE}"

    if [ -f "$image_path" ]; then
        log_info "Cloud image already exists: $image_path"
        return 0
    fi

    log_info "Downloading Rocky Linux 9 cloud image..."
    log_info "URL: $IMAGE_URL"

    wget -q --show-progress "$IMAGE_URL" -O "$image_path"

    log_info "Cloud image downloaded successfully"
}

create_template() {
    log_info "Creating VM template..."

    qm create $VMID \
        --name $VM_NAME \
        --cores $CORES \
        --memory $MEMORY \
        --net0 virtio,bridge=vmbr1 \
        --scsihw virtio-scsi-pci \
        --ostype l26 \
        --agent enabled=1 \
        --description "Rocky Linux 9 Cloud Template

Base template for RHEL-compatible server deployments
Cloud-init enabled for automated configuration

Created: $(date '+%Y-%m-%d %H:%M:%S')
Source: Rocky Linux Cloud Images"

    log_info "VM $VMID created"

    log_info "Importing cloud image as disk..."
    qm importdisk $VMID /tmp/${IMAGE_FILE} $STORAGE

    log_info "Attaching disk to VM..."
    qm set $VMID --scsi0 ${STORAGE}:vm-${VMID}-disk-0

    log_info "Resizing disk to ${DISK_SIZE}..."
    qm resize $VMID scsi0 $DISK_SIZE

    log_info "Adding cloud-init drive..."
    qm set $VMID --ide2 ${STORAGE}:cloudinit

    log_info "Configuring boot order..."
    qm set $VMID --boot order=scsi0

    qm set $VMID --serial0 socket --vga serial0

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
    echo "║         ROCKY LINUX 9 TEMPLATE CREATED SUCCESSFULLY               ║"
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
    echo "Example:"
    echo "  qm clone $VMID 230 --name application-server --full"
    echo "  qm set 230 --memory 8192 --cores 4"
    echo "  qm set 230 --ipconfig0 ip=192.168.20.40/24,gw=192.168.10.254"
    echo "  qm resize 230 scsi0 +190G"
    echo "  qm start 230"
    echo ""
}

main() {
    echo "╔════════════════════════════════════════════════════════════════════╗"
    echo "║          CREATE ROCKY LINUX 9 TEMPLATE                            ║"
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
