#!/bin/bash
################################################################################
# Script: fix-vm-tags-and-pools.sh
# Purpose: Apply tags and resource pool assignments to deployed VMs
# Author: SMB Office IT Blueprint Project
# Created: 2025-12-28
#
# Description:
#   Applies Proxmox tags and resource pool assignments to VMs that were
#   deployed without them. Run this on the Proxmox host.
#
# Usage:
#   bash fix-vm-tags-and-pools.sh
################################################################################

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

log_info() { echo -e "${GREEN}[INFO]${NC} $1"; }
log_warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1"; }

echo "╔════════════════════════════════════════════════════════════════════╗"
echo "║          FIX VM TAGS AND RESOURCE POOLS                           ║"
echo "╚════════════════════════════════════════════════════════════════════╝"
echo ""

# Check we're on Proxmox host
if ! command -v qm &> /dev/null; then
    log_error "This script must be run on the Proxmox host!"
    exit 1
fi

log_info "Applying tags and resource pools to all VMs..."
echo ""

# ========================================================================
# VLAN 110 - Management Infrastructure
# ========================================================================

log_info "Processing Management VMs (VLAN 110)..."

# VM 110 - Ansible Control
if qm status 110 &>/dev/null; then
    log_info "VM 110 (ansible-ctrl): Applying tags and pool..."
    qm set 110 --tags "infrastructure;automation;management;ubuntu;vlan-110"
    pvesh set /pools/infrastructure --vms 110 2>/dev/null || log_warn "Pool 'infrastructure' may not exist"
else
    log_warn "VM 110 does not exist, skipping"
fi

# VM 111 - Monitoring
if qm status 111 &>/dev/null; then
    log_info "VM 111 (monitoring): Applying tags and pool..."
    qm set 111 --tags "infrastructure;monitoring;management;ubuntu;vlan-110;auto-backup"
    pvesh set /pools/infrastructure --vms 111 2>/dev/null || log_warn "Pool 'infrastructure' may not exist"
else
    log_warn "VM 111 does not exist, skipping"
fi

# VM 112 - Backup
if qm status 112 &>/dev/null; then
    log_info "VM 112 (backup): Applying tags and pool..."
    qm set 112 --tags "infrastructure;backup;storage;debian;vlan-110;auto-backup"
    pvesh set /pools/infrastructure --vms 112 2>/dev/null || log_warn "Pool 'infrastructure' may not exist"
else
    log_warn "VM 112 does not exist, skipping"
fi

# VM 113 - Jump Host
if qm status 113 &>/dev/null; then
    log_info "VM 113 (jump-host): Applying tags and pool..."
    qm set 113 --tags "infrastructure;bastion;security;ubuntu;vlan-110;monitored"
    pvesh set /pools/infrastructure --vms 113 2>/dev/null || log_warn "Pool 'infrastructure' may not exist"
else
    log_warn "VM 113 does not exist, skipping"
fi

echo ""

# ========================================================================
# VLAN 120 - Production Servers
# ========================================================================

log_info "Processing Production Server VMs (VLAN 120)..."

# VM 200 - DC01
if qm status 200 &>/dev/null; then
    log_info "VM 200 (dc01): Applying tags and pool..."
    qm set 200 --tags "production;domain-controller;dns;dhcp;active-directory;primary;debian;vlan-120;auto-backup;monitored"
    pvesh set /pools/production --vms 200 2>/dev/null || log_warn "Pool 'production' may not exist"
else
    log_warn "VM 200 does not exist, skipping"
fi

# VM 201 - DC02
if qm status 201 &>/dev/null; then
    log_info "VM 201 (dc02): Applying tags and pool..."
    qm set 201 --tags "production;domain-controller;dns;dhcp;active-directory;replica;debian;vlan-120;auto-backup;monitored"
    pvesh set /pools/production --vms 201 2>/dev/null || log_warn "Pool 'production' may not exist"
else
    log_warn "VM 201 does not exist, skipping"
fi

# VM 210 - File Server
if qm status 210 &>/dev/null; then
    log_info "VM 210 (fs01): Applying tags and pool..."
    qm set 210 --tags "production;file-server;storage;samba;ubuntu;vlan-120;auto-backup;monitored"
    pvesh set /pools/production --vms 210 2>/dev/null || log_warn "Pool 'production' may not exist"
else
    log_warn "VM 210 does not exist, skipping"
fi

# VM 220 - Database Server
if qm status 220 &>/dev/null; then
    log_info "VM 220 (db01): Applying tags and pool..."
    qm set 220 --tags "production;database;postgresql;primary;debian;vlan-120;auto-backup;monitored;sensitive-data"
    pvesh set /pools/production --vms 220 2>/dev/null || log_warn "Pool 'production' may not exist"
else
    log_warn "VM 220 does not exist, skipping"
fi

# VM 230 - Application Server
if qm status 230 &>/dev/null; then
    log_info "VM 230 (app01): Applying tags and pool..."
    qm set 230 --tags "production;app-server;web-server;nginx;ubuntu;vlan-120;monitored"
    pvesh set /pools/production --vms 230 2>/dev/null || log_warn "Pool 'production' may not exist"
else
    log_warn "VM 230 does not exist, skipping"
fi

# VM 240 - Mail Server
if qm status 240 &>/dev/null; then
    log_info "VM 240 (mail01): Applying tags and pool..."
    qm set 240 --tags "production;mail-server;smtp;imap;debian;vlan-120;auto-backup;monitored"
    pvesh set /pools/production --vms 240 2>/dev/null || log_warn "Pool 'production' may not exist"
else
    log_warn "VM 240 does not exist, skipping"
fi

echo ""

# ========================================================================
# VLAN 130 - Workstations
# ========================================================================

log_info "Processing Workstation VMs (VLAN 130)..."

# VM 300 - Admin Workstation
if qm status 300 &>/dev/null; then
    log_info "VM 300 (ws-admin01): Applying tags and pool..."
    qm set 300 --tags "workstation;admin;privileged-access;ubuntu;vlan-130;monitored"
    pvesh set /pools/production --vms 300 2>/dev/null || log_warn "Pool 'production' may not exist"
else
    log_warn "VM 300 does not exist, skipping"
fi

echo ""

# ========================================================================
# VLAN 150 - DMZ Services
# ========================================================================

log_info "Processing DMZ VMs (VLAN 150)..."

# VM 400 - Web Server
if qm status 400 &>/dev/null; then
    log_info "VM 400 (web01): Applying tags and pool..."
    qm set 400 --tags "production;web-server;nginx;public-facing;ubuntu;vlan-150;monitored;auto-update"
    pvesh set /pools/dmz --vms 400 2>/dev/null || log_warn "Pool 'dmz' may not exist"
else
    log_warn "VM 400 does not exist, skipping"
fi

# VM 410 - VPN Gateway
if qm status 410 &>/dev/null; then
    log_info "VM 410 (vpn-gw): Applying tags and pool..."
    qm set 410 --tags "infrastructure;vpn;security;debian;vlan-150;monitored"
    pvesh set /pools/dmz --vms 410 2>/dev/null || log_warn "Pool 'dmz' may not exist"
else
    log_warn "VM 410 does not exist, skipping"
fi

# VM 420 - Mail Relay
if qm status 420 &>/dev/null; then
    log_info "VM 420 (mail-relay): Applying tags and pool..."
    qm set 420 --tags "production;mail-relay;smtp;public-facing;debian;vlan-150;monitored"
    pvesh set /pools/dmz --vms 420 2>/dev/null || log_warn "Pool 'dmz' may not exist"
else
    log_warn "VM 420 does not exist, skipping"
fi

echo ""
echo "╔════════════════════════════════════════════════════════════════════╗"
echo "║                    TAGS AND POOLS APPLIED                          ║"
echo "╚════════════════════════════════════════════════════════════════════╝"
echo ""

log_info "Verifying tags were applied..."
echo ""

for vmid in 110 111 112 113 200 201 210 220 230 240 300 400 410 420; do
    if qm status $vmid &>/dev/null; then
        tags=$(qm config $vmid | grep "^tags:" | cut -d' ' -f2- || echo "NO TAGS")
        echo "VM $vmid: $tags"
    fi
done

echo ""
log_info "Complete! Check Proxmox web UI to see tags and pool assignments."
