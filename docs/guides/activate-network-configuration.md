# Activating Proxmox Network Configuration

**Last Updated:** 2025-12-27

## Overview

After running the `configure-proxmox-network.yml` playbook, the network configuration has been written to `/etc/network/interfaces` but is not yet active. This guide walks you through safely activating the new network configuration with vmbr1 and VLAN interfaces.

## Pre-Activation Checklist

Before activating the network configuration, verify:

- [ ] Backup exists: Check `backups/network/interfaces.<timestamp>.backup`
- [ ] You have console access to Proxmox (in case SSH breaks)
- [ ] No VMs are currently running (optional but recommended)
- [ ] You understand you may temporarily lose connectivity

## Step 1: Verify Configuration File

SSH to the Proxmox host and review the configuration:

```bash
ssh root@192.168.35.20

# View the network configuration
cat /etc/network/interfaces
```

**Look for:**
- `# BEGIN ANSIBLE MANAGED BLOCK - vmbr1` section
- `# BEGIN ANSIBLE MANAGED BLOCK - VLANs` section
- vmbr1 bridge configuration with `bridge-vlan-aware yes`
- VLAN interfaces (vmbr1.10, vmbr1.20, vmbr1.30, vmbr1.40, vmbr1.50)

**Example of what you should see:**

```
# BEGIN ANSIBLE MANAGED BLOCK - vmbr1
# Internal isolated network bridge (VLAN-aware)
auto vmbr1
iface vmbr1 inet manual
        bridge-ports none
        bridge-stp off
        bridge-fd 0
        bridge-vlan-aware yes
        bridge-vids 2-4094
#       Internal network for VMs - isolated from vmbr0/lab network
# END ANSIBLE MANAGED BLOCK - vmbr1

# BEGIN ANSIBLE MANAGED BLOCK - VLANs
# VLAN 10: Management - Infrastructure management and monitoring
auto vmbr1.10
iface vmbr1.10 inet static
        address 192.168.10.1
        netmask 255.255.255.0
#       Infrastructure management and monitoring

# VLAN 20: Servers - Production application servers
auto vmbr1.20
iface vmbr1.20 inet static
        address 192.168.20.1
        netmask 255.255.255.0
#       Production application servers

# ... (more VLANs)
# END ANSIBLE MANAGED BLOCK - VLANs
```

## Step 2: Test Configuration Syntax

Before applying, test the configuration for syntax errors:

```bash
# Dry run - tests configuration without applying
ifup --no-act --all
```

**Expected Output:**
- No errors about syntax
- May show warnings about already configured interfaces (normal)

**If you see errors:**
- Review the error messages
- Check `/etc/network/interfaces` for typos
- Restore from backup if needed (see "Emergency Rollback" section)

## Step 3: Apply Network Configuration

Apply the new network configuration:

```bash
# Method 1: Reload all network interfaces (recommended)
ifreload -a

# Method 2: Bring up individual interfaces
# ifup vmbr1
# ifup vmbr1.10
# ifup vmbr1.20
# ifup vmbr1.30
# ifup vmbr1.40
# ifup vmbr1.50
```

**What `ifreload -a` does:**
- Reads `/etc/network/interfaces`
- Brings down interfaces that changed
- Brings up interfaces with new configuration
- Does NOT restart existing interfaces that didn't change (vmbr0 stays up)

**Expected behavior:**
- Command should complete in 2-5 seconds
- You should remain connected via SSH (vmbr0 unchanged)
- No error messages

## Step 4: Verify Network Interfaces

Check that all interfaces came up correctly:

```bash
# 1. Check vmbr1 bridge is up
ip link show vmbr1
```

**Expected output:**
```
3: vmbr1: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc noqueue state UNKNOWN mode DEFAULT group default qlen 1000
    link/ether XX:XX:XX:XX:XX:XX brd ff:ff:ff:ff:ff:ff
```

**Look for:** `UP,LOWER_UP` (means interface is active)

```bash
# 2. List all vmbr1 VLAN interfaces
ip link show | grep vmbr1
```

**Expected output:**
```
3: vmbr1: <BROADCAST,MULTICAST,UP,LOWER_UP> ...
4: vmbr1.10@vmbr1: <BROADCAST,MULTICAST,UP,LOWER_UP> ...
5: vmbr1.20@vmbr1: <BROADCAST,MULTICAST,UP,LOWER_UP> ...
6: vmbr1.30@vmbr1: <BROADCAST,MULTICAST,UP,LOWER_UP> ...
7: vmbr1.40@vmbr1: <BROADCAST,MULTICAST,UP,LOWER_UP> ...
8: vmbr1.50@vmbr1: <BROADCAST,MULTICAST,UP,LOWER_UP> ...
```

```bash
# 3. Check IP addresses on VLAN interfaces
ip addr show vmbr1.10
ip addr show vmbr1.20
```

**Expected output for vmbr1.10:**
```
4: vmbr1.10@vmbr1: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc noqueue state UP group default qlen 1000
    link/ether XX:XX:XX:XX:XX:XX brd ff:ff:ff:ff:ff:ff
    inet 192.168.10.1/24 brd 192.168.10.255 scope global vmbr1.10
       valid_lft forever preferred_lft forever
```

**Look for:** `inet 192.168.10.1/24` (IP address assigned)

**Expected output for vmbr1.20:**
```
5: vmbr1.20@vmbr1: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc noqueue state UP group default qlen 1000
    link/ether XX:XX:XX:XX:XX:XX brd ff:ff:ff:ff:ff:ff
    inet 192.168.20.1/24 brd 192.168.20.255 scope global vmbr1.20
       valid_lft forever preferred_lft forever
```

```bash
# 4. Verify VLAN interfaces with no IP (should still be UP)
ip addr show vmbr1.30
ip addr show vmbr1.40
ip addr show vmbr1.50
```

**Expected:** Interfaces show `UP,LOWER_UP` but no `inet` line (no IP configured, by design)

```bash
# 5. List all bridges
brctl show
```

**Expected output:**
```
bridge name     bridge id               STP enabled     interfaces
vmbr0          8000.xxxxxxxxxxxx       no              eth0
vmbr1          8000.xxxxxxxxxxxx       no
```

```bash
# 6. Check bridge VLAN awareness
bridge vlan show
```

**Expected:** Shows VLAN information for vmbr1

## Step 5: Test Connectivity

Test that the new interfaces are reachable:

```bash
# Ping management VLAN gateway (Proxmox host itself)
ping -c 3 192.168.10.1

# Ping server VLAN gateway
ping -c 3 192.168.20.1

# Verify your lab network still works (vmbr0 unchanged)
ping -c 3 8.8.8.8
```

**All pings should succeed.**

## Step 6: Make Configuration Persistent (Reboot Test)

The configuration is already persistent (saved in `/etc/network/interfaces`), but it's good to verify it survives a reboot:

```bash
# Optional: Reboot Proxmox host to ensure config persists
reboot

# Wait 2-3 minutes, then SSH back in
ssh root@192.168.35.20

# Verify all interfaces came up automatically
ip link show | grep vmbr1
ip addr show vmbr1.10
ip addr show vmbr1.20
```

**Note:** Rebooting is optional. The configuration will persist without a reboot since it's written to `/etc/network/interfaces`.

## Step 7: Verify in Proxmox Web UI

1. Open Proxmox Web UI: `https://192.168.35.20:8006`
2. Navigate to: **Datacenter → <Your Node> → System → Network**
3. You should see:
   - `vmbr0` (existing - unchanged)
   - `vmbr1` (new - VLAN aware bridge)
   - `vmbr1.10` through `vmbr1.50` (VLAN interfaces)

**All should show as "Active" with green checkmarks.**

## Verification Checklist

After activation, verify:

- [ ] `vmbr1` bridge is UP
- [ ] All 5 VLAN interfaces (10, 20, 30, 40, 50) are UP
- [ ] `vmbr1.10` has IP 192.168.10.1/24
- [ ] `vmbr1.20` has IP 192.168.20.1/24
- [ ] `vmbr1.30`, `vmbr1.40`, `vmbr1.50` have no IPs (expected)
- [ ] `vmbr0` still works (lab network unchanged)
- [ ] Can ping 192.168.10.1 and 192.168.20.1
- [ ] Proxmox Web UI shows all interfaces as Active
- [ ] No error messages in `journalctl -xe`

## Troubleshooting

### Issue: vmbr1 interface not showing up

**Cause:** Interface didn't come up during `ifreload`

**Solution:**
```bash
# Manually bring up vmbr1
ifup vmbr1

# Check for errors
journalctl -xe | grep vmbr1
```

### Issue: VLAN interfaces not created

**Cause:** vmbr1 must be up before VLAN interfaces can be created

**Solution:**
```bash
# Bring up vmbr1 first
ifup vmbr1

# Then bring up VLAN interfaces
ifup vmbr1.10
ifup vmbr1.20
ifup vmbr1.30
ifup vmbr1.40
ifup vmbr1.50

# Or reload all at once
ifreload -a
```

### Issue: IP addresses not assigned to VLAN interfaces

**Cause:** Interface came up but IP configuration failed

**Solution:**
```bash
# Check interface configuration
cat /etc/network/interfaces | grep -A 5 "vmbr1.10"

# Manually assign IP
ip addr add 192.168.10.1/24 dev vmbr1.10

# Or reload the interface
ifdown vmbr1.10 && ifup vmbr1.10
```

### Issue: Lost SSH connection during activation

**Cause:** Unlikely if vmbr0 wasn't modified, but possible

**Solution:**
1. Access Proxmox console directly (physical or IPMI/iLO)
2. Login as root
3. Check network status: `ip addr`
4. Restore from backup if needed (see Emergency Rollback below)

### Issue: "Cannot find device vmbr1"

**Cause:** Bridge wasn't created or configuration error

**Solution:**
```bash
# Check if bridge exists
ip link show vmbr1

# If not, create manually
ip link add name vmbr1 type bridge

# Then reload config
ifreload -a
```

## Emergency Rollback

If something goes wrong and you need to restore the original configuration:

### Option 1: Use the Restore Script (Recommended)

```bash
# Find the restore script (created by playbook)
ls ~/Documents/claude/projects/smb-office-it-blueprint/backups/network/

# Run the restore script
bash ~/Documents/claude/projects/smb-office-it-blueprint/backups/network/restore-network-<timestamp>.sh
```

### Option 2: Manual Restore

```bash
# On your workstation (not Proxmox host)
cd ~/Documents/claude/projects/smb-office-it-blueprint/backups/network/

# Find the backup file
ls -lt interfaces.*

# Copy backup to Proxmox and restore
scp interfaces.<timestamp>.backup root@192.168.35.20:/tmp/interfaces.backup

# On Proxmox host
ssh root@192.168.35.20

# Backup current (broken) config
cp /etc/network/interfaces /etc/network/interfaces.broken

# Restore original
cp /tmp/interfaces.backup /etc/network/interfaces

# Apply restored configuration
ifreload -a

# If still broken, reboot
reboot
```

### Option 3: Remove Just the Ansible Blocks

If you want to keep vmbr0 changes but remove vmbr1:

```bash
# Edit the file
nano /etc/network/interfaces

# Delete everything between:
#   # BEGIN ANSIBLE MANAGED BLOCK - vmbr1
#   ...
#   # END ANSIBLE MANAGED BLOCK - vmbr1
#
# And between:
#   # BEGIN ANSIBLE MANAGED BLOCK - VLANs
#   ...
#   # END ANSIBLE MANAGED BLOCK - VLANs

# Save and reload
ifreload -a
```

## Common Questions

### Q: Will activating vmbr1 affect my existing VMs?

**A:** No. Existing VMs on vmbr0 are completely unaffected. vmbr1 is a new, isolated bridge.

### Q: Do I need to reboot for changes to take effect?

**A:** No. `ifreload -a` applies changes immediately. Reboot is optional for verification only.

### Q: What if I lose SSH access during activation?

**A:** This is very unlikely since vmbr0 (your management interface) is not modified. However, always have console access available as a backup.

### Q: Can I activate interfaces one at a time?

**A:** Yes, use `ifup <interface>` for individual interfaces, but `ifreload -a` is safer and faster.

### Q: How do I check if VLAN tagging is working?

**A:** After creating VMs on vmbr1, use `tcpdump` to see VLAN tags:
```bash
tcpdump -i vmbr1 -e -n
```

### Q: Can I modify the configuration after activation?

**A:** Yes. Edit `/etc/network/interfaces`, then run `ifreload -a` to apply changes.

## Next Steps After Activation

Once the network is active and verified:

1. **Create OPNsense VM** - Run `create-opnsense-vm.sh` to create the firewall
2. **Create VM Templates** - Run template creation scripts
3. **Deploy VMs** - Clone from templates to create infrastructure VMs
4. **Configure OPNsense** - Set up routing, NAT, DHCP, firewall rules
5. **Test Inter-VLAN Routing** - Verify VMs can communicate through OPNsense

## Reference Commands Quick List

```bash
# Activate all interfaces
ifreload -a

# Check interface status
ip link show vmbr1
ip addr show vmbr1.10

# Test connectivity
ping 192.168.10.1
ping 192.168.20.1

# View all interfaces
ip addr

# Check bridges
brctl show

# View configuration
cat /etc/network/interfaces

# Bring up individual interface
ifup vmbr1.10

# Bring down individual interface
ifdown vmbr1.10

# Restart networking (use with caution!)
systemctl restart networking

# View network logs
journalctl -u networking -xe
```

## Backup Locations

- **Original config backup:** `~/Documents/claude/projects/smb-office-it-blueprint/backups/network/interfaces.<timestamp>.backup`
- **Restore script:** `~/Documents/claude/projects/smb-office-it-blueprint/backups/network/restore-network-<timestamp>.sh`
- **Broken config (if restored):** `/etc/network/interfaces.broken.<timestamp>`

## Support

If you encounter issues not covered in this guide:

1. Check `/var/log/syslog` for network errors
2. Run `journalctl -xe` for systemd errors
3. Verify configuration syntax: `ifup --no-act --all`
4. Review Proxmox network documentation
5. Restore from backup and start over if needed

---

**Remember:** The vmbr1 network is completely isolated from your lab network (vmbr0). Changes to vmbr1 cannot affect your existing infrastructure.
