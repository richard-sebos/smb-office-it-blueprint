#!/bin/bash
################################################################################
# Script: troubleshoot-opnsense.sh
# Purpose: Diagnose OPNsense VM connectivity issues
# Author: SMB Office IT Blueprint Project
# Created: 2025-12-27
################################################################################

set -u

# Configuration
VMID=100
WAN_BRIDGE="vmbr0"
LAN_BRIDGE="vmbr1"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

log_info() { echo -e "${GREEN}[INFO]${NC} $1"; }
log_warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1"; }
log_step() { echo -e "${BLUE}[STEP]${NC} $1"; }

echo "╔════════════════════════════════════════════════════════════════════╗"
echo "║          OPNSENSE VM TROUBLESHOOTING                              ║"
echo "╚════════════════════════════════════════════════════════════════════╝"
echo ""

################################################################################
# Step 1: Check VM Status
################################################################################
log_step "1. Checking VM status..."
if ! qm status $VMID &>/dev/null; then
    log_error "VM $VMID does not exist!"
    echo "Run: bash create-opnsense-vm.sh"
    exit 1
fi

VM_STATUS=$(qm status $VMID | awk '{print $2}')
if [ "$VM_STATUS" = "running" ]; then
    log_info "VM $VMID is running"
else
    log_error "VM $VMID is NOT running (status: $VM_STATUS)"
    echo ""
    echo "To start the VM:"
    echo "  qm start $VMID"
    exit 1
fi

################################################################################
# Step 2: Check VM Configuration
################################################################################
log_step "2. Checking VM network configuration..."

echo ""
echo "Network Interfaces:"
qm config $VMID | grep -E "^net" | while read line; do
    echo "  $line"
done

echo ""
echo "Current VM hardware configuration:"
qm config $VMID | grep -E "^(cores|memory|net0|net1|scsi0)"

################################################################################
# Step 3: Check Bridge Status
################################################################################
log_step "3. Checking bridge status..."

if ip link show $WAN_BRIDGE &>/dev/null; then
    WAN_STATUS=$(ip link show $WAN_BRIDGE | grep -o 'state [A-Z]*' | awk '{print $2}')
    if [ "$WAN_STATUS" = "UP" ] || [ "$WAN_STATUS" = "UNKNOWN" ]; then
        log_info "WAN bridge ($WAN_BRIDGE) is UP"
    else
        log_warn "WAN bridge ($WAN_BRIDGE) is $WAN_STATUS"
    fi
else
    log_error "WAN bridge ($WAN_BRIDGE) not found!"
fi

if ip link show $LAN_BRIDGE &>/dev/null; then
    LAN_STATUS=$(ip link show $LAN_BRIDGE | grep -o 'state [A-Z]*' | awk '{print $2}')
    if [ "$LAN_STATUS" = "UP" ] || [ "$LAN_STATUS" = "UNKNOWN" ]; then
        log_info "LAN bridge ($LAN_BRIDGE) is UP"
    else
        log_warn "LAN bridge ($LAN_BRIDGE) is $LAN_STATUS"
    fi
else
    log_error "LAN bridge ($LAN_BRIDGE) not found!"
fi

################################################################################
# Step 4: Try to detect OPNsense IP
################################################################################
log_step "4. Attempting to detect OPNsense IP addresses..."

echo ""
echo "Checking ARP table for devices on lab network..."
ip neigh show dev $WAN_BRIDGE | grep -v FAILED | head -5

echo ""
log_info "If you see any MAC addresses above, those might be the OPNsense WAN interface"

################################################################################
# Step 5: Check if web service is responding
################################################################################
log_step "5. Testing common OPNsense IPs..."

echo ""
echo "Testing if OPNsense is reachable on common addresses:"
echo ""

# Test WAN potential IPs (lab network range)
for ip in 192.168.35.{100..110}; do
    if timeout 1 ping -c 1 $ip &>/dev/null; then
        echo -e "${GREEN}✓${NC} $ip is reachable (ping)"

        # Test HTTPS
        if timeout 2 curl -k -s https://$ip &>/dev/null; then
            echo -e "  ${GREEN}✓ HTTPS responding on https://$ip${NC}"
        else
            echo -e "  ${YELLOW}✗ HTTPS not responding on $ip${NC}"
        fi
    fi
done

# Test LAN IP (should be 192.168.10.254 after configuration)
echo ""
echo "Testing LAN IP (if configured):"
if timeout 1 ping -c 1 192.168.10.254 &>/dev/null; then
    echo -e "${GREEN}✓${NC} 192.168.10.254 is reachable (ping)"

    if timeout 2 curl -k -s https://192.168.10.254 &>/dev/null; then
        echo -e "  ${GREEN}✓ HTTPS responding on https://192.168.10.254${NC}"
    else
        echo -e "  ${YELLOW}✗ HTTPS not responding on 192.168.10.254${NC}"
    fi
else
    echo -e "${YELLOW}✗${NC} 192.168.10.254 not reachable (not configured yet)"
fi

################################################################################
# Step 6: Console Access Instructions
################################################################################
echo ""
log_step "6. Console access options..."

echo ""
echo "To access OPNsense console directly:"
echo ""
echo "Option 1: Proxmox Web UI"
echo "  1. Open browser: https://192.168.35.20:8006"
echo "  2. Navigate: Datacenter → pve → 100 (opnsense-firewall)"
echo "  3. Click 'Console' button"
echo ""
echo "Option 2: Command line"
echo "  qm terminal 100"
echo "  (Press Ctrl+O to exit)"
echo ""

################################################################################
# Step 7: Check Installation Status
################################################################################
log_step "7. Checking installation status..."

echo ""
echo "To check if OPNsense is installed, access the console and look for:"
echo ""
echo "  NOT INSTALLED:"
echo "    'OPNsense 24.7 - OpenBSD Secure Shell server'"
echo "    'console login: _'"
echo "    → Login with: installer / opnsense"
echo ""
echo "  INSTALLED:"
echo "    '*** OPNsense.localdomain: OPNsense 24.7 ***'"
echo "    Shows WAN/LAN interface status"
echo "    Menu with options 0-13"
echo "    → Login with: root / (your-password)"
echo ""

################################################################################
# Summary
################################################################################
echo ""
echo "╔════════════════════════════════════════════════════════════════════╗"
echo "║                    TROUBLESHOOTING SUMMARY                         ║"
echo "╚════════════════════════════════════════════════════════════════════╝"
echo ""
echo "Next steps to try:"
echo ""
echo "1. Access the console (qm terminal 100)"
echo "   - Check if installation is complete"
echo "   - Check interface assignments and IP addresses"
echo ""
echo "2. If not installed:"
echo "   - Login: installer / opnsense"
echo "   - Select option 1 (Install UFS)"
echo "   - Follow installation prompts"
echo ""
echo "3. If installed but no IP on WAN:"
echo "   - From console menu, select option 2"
echo "   - Configure WAN interface with DHCP or static IP"
echo ""
echo "4. If WAN has IP but web UI not accessible:"
echo "   - Check firewall on your workstation"
echo "   - Try: curl -k https://<wan-ip>"
echo "   - Access console and verify services are running"
echo ""
echo "5. If you see 'vtnet0' and 'vtnet1' but no IPs:"
echo "   - From console menu, select option 1"
echo "   - Assign interfaces: WAN=vtnet0, LAN=vtnet1"
echo "   - Then select option 2 to configure IP addresses"
echo ""

echo "For detailed installation guide, see:"
echo "  docs/guides/install-opnsense.md"
echo ""
