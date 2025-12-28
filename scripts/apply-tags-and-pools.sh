#!/bin/bash
################################################################################
# Script: apply-tags-and-pools.sh
# Purpose: Apply tags and resource pools to deployed infrastructure VMs
# Created: 2025-12-28
################################################################################

set -e

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

log_info() { echo -e "${GREEN}[INFO]${NC} $1"; }
log_warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }

echo "Applying tags and resource pools to infrastructure VMs..."
echo ""

# Management VMs (VLAN 110)
log_info "VM 110 (ansible-ctrl)..."
qm set 110 --tags "infrastructure;automation;management;ubuntu;vlan-110"
pvesh set /pools/infrastructure --vms 110 2>/dev/null || log_warn "Pool not found"

log_info "VM 111 (monitoring)..."
qm set 111 --tags "infrastructure;monitoring;management;ubuntu;vlan-110;auto-backup"
pvesh set /pools/infrastructure --vms 111 2>/dev/null || log_warn "Pool not found"

log_info "VM 112 (backup)..."
qm set 112 --tags "infrastructure;backup;storage;debian;vlan-110;auto-backup"
pvesh set /pools/infrastructure --vms 112 2>/dev/null || log_warn "Pool not found"

log_info "VM 113 (jump-host)..."
qm set 113 --tags "infrastructure;bastion;security;ubuntu;vlan-110;monitored"
pvesh set /pools/infrastructure --vms 113 2>/dev/null || log_warn "Pool not found"

# Production Servers (VLAN 120)
log_info "VM 200 (dc01)..."
qm set 200 --tags "production;domain-controller;dns;dhcp;active-directory;primary;debian;vlan-120;auto-backup;monitored"
pvesh set /pools/production --vms 200 2>/dev/null || log_warn "Pool not found"

log_info "VM 201 (dc02)..."
qm set 201 --tags "production;domain-controller;dns;dhcp;active-directory;replica;debian;vlan-120;auto-backup;monitored"
pvesh set /pools/production --vms 201 2>/dev/null || log_warn "Pool not found"

log_info "VM 210 (fs01)..."
qm set 210 --tags "production;file-server;storage;samba;ubuntu;vlan-120;auto-backup;monitored"
pvesh set /pools/production --vms 210 2>/dev/null || log_warn "Pool not found"

log_info "VM 220 (db01)..."
qm set 220 --tags "production;database;postgresql;primary;debian;vlan-120;auto-backup;monitored;sensitive-data"
pvesh set /pools/production --vms 220 2>/dev/null || log_warn "Pool not found"

log_info "VM 230 (app01)..."
qm set 230 --tags "production;app-server;web-server;nginx;ubuntu;vlan-120;monitored"
pvesh set /pools/production --vms 230 2>/dev/null || log_warn "Pool not found"

log_info "VM 240 (mail01)..."
qm set 240 --tags "production;mail-server;smtp;imap;debian;vlan-120;auto-backup;monitored"
pvesh set /pools/production --vms 240 2>/dev/null || log_warn "Pool not found"

# Workstations (VLAN 130)
log_info "VM 300 (ws-admin01)..."
qm set 300 --tags "workstation;admin;privileged-access;ubuntu;vlan-130;monitored"
pvesh set /pools/production --vms 300 2>/dev/null || log_warn "Pool not found"

# DMZ (VLAN 150)
log_info "VM 410 (vpn-gw)..."
qm set 410 --tags "infrastructure;vpn;security;debian;vlan-150;monitored"
pvesh set /pools/dmz --vms 410 2>/dev/null || log_warn "Pool not found"

log_info "VM 420 (mail-relay)..."
qm set 420 --tags "production;mail-relay;smtp;public-facing;debian;vlan-150;monitored"
pvesh set /pools/dmz --vms 420 2>/dev/null || log_warn "Pool not found"

echo ""
echo "Tags and pools applied!"
echo ""
echo "Verification:"
for vmid in 110 111 112 113 200 201 210 220 230 240 300 410 420; do
    tags=$(qm config $vmid | grep "^tags:" | cut -d' ' -f2- || echo "NO TAGS")
    printf "VM %3d: %s\n" $vmid "$tags"
done
