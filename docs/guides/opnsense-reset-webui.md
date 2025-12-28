# Reset OPNsense Web Interface to WAN Access

**Project:** SMB Office IT Blueprint
**Last Updated:** 2025-12-27
**Purpose:** Enable web UI access via WAN interface

## Quick Fix - Enable Web UI on WAN

### Method 1: Via Console Menu (Easiest)

```bash
# On Proxmox host
ssh root@192.168.35.20

# Access OPNsense console
qm terminal 100
```

**Login:** `root` / (your password)

The console will show the current interface status:

```
*** OPNsense.localdomain: OPNsense 24.7 ***

  WAN (wan) -> vtnet0 -> v4/DHCP4: 192.168.35.XXX/24
  LAN (lan) -> vtnet1 -> v4: 192.168.10.254/24

Enter an option: _
```

**Note the WAN IP address shown** (192.168.35.XXX)

**Select:** `8` (Shell)

Press `Enter`

You'll get a command prompt:

```
root@OPNsense:~ #
```

Run this command to allow web UI access on all interfaces:

```bash
# Allow web UI on all interfaces (including WAN)
configctl webgui restart wan

# OR edit the configuration directly
pfSsh.php playback enablesshd
```

**Better approach - Use the configuration file:**

```bash
# Edit the config to allow WAN access
vi /conf/config.xml
```

Find the `<system>` section and look for `<disablenatreflection>` or add this section if it doesn't exist:

Actually, the **easiest way** is to use the built-in option in the menu.

**Exit shell:** Type `exit` and press Enter

From the console menu:

**Select:** `12` (Update from console)

This will refresh services. Then try accessing the web UI again.

### Method 2: Reconfigure Interface IP (Forces Web UI Restart)

From the console menu:

**Select:** `2` (Set interface IP address)

**Select:** `1` (WAN)

Answer all the prompts with the current settings (just press Enter to keep defaults), but when you see:

```
Do you want to revert to HTTP as the web GUI protocol? (y/n): _
```

**Answer:** `n` (keep HTTPS)

This will restart the web GUI service.

### Method 3: Via Shell - Disable "Disable Web GUI on WAN" Rule

From console menu, select `8` (Shell)

Run these commands:

```bash
# Check current web GUI configuration
grep -A 5 "<webgui>" /conf/config.xml

# Disable the "disable web GUI redirect rule" if it's enabled
# This requires editing the XML config
vi /conf/config.xml
```

Find this section:
```xml
<system>
  ...
  <disablewebredirect>yes</disablewebredirect>
  ...
</system>
```

Change to:
```xml
<system>
  ...
  <!-- disablewebredirect>yes</disablewebredirect -->
  ...
</system>
```

Or delete the line entirely.

Save the file (`:wq` in vi)

Restart the web GUI:
```bash
/usr/local/etc/rc.restart_webgui
```

### Method 4: Factory Reset Web GUI Settings (Nuclear Option)

**WARNING:** This resets web GUI settings to defaults.

From console menu, select `8` (Shell)

```bash
# Reset web GUI to defaults
/usr/local/etc/rc.restart_webgui
```

Or for a full web GUI reset:

```bash
# Remove web GUI certificates (forces regeneration)
rm /var/etc/cert.pem
rm /var/etc/cert.key

# Restart web GUI
/usr/local/etc/rc.restart_webgui
```

## Verify Web UI is Accessible

### Check if Web Service is Running

From console shell (`option 8`):

```bash
# Check if nginx is running (web GUI uses nginx)
ps aux | grep nginx

# Check listening ports
sockstat -4 -l | grep :443
```

**Expected output:**
```
www      nginx      12345  3  tcp4   *:443                 *:*
```

This shows nginx is listening on port 443 (HTTPS).

### Check Firewall Rules

The WAN interface might have a firewall rule blocking access to the web UI.

From console shell:

```bash
# Check if there's an anti-lockout rule
pfctl -sr | grep -A 2 "anti-lockout"

# Check WAN rules
pfctl -sr | grep "vtnet0"
```

### Test from Proxmox Host

```bash
# Exit console (Ctrl+O if using qm terminal)

# From Proxmox host, test HTTPS connection
curl -k https://192.168.35.XXX

# Or test if port 443 is open
nc -zv 192.168.35.XXX 443

# Or use telnet
telnet 192.168.35.XXX 443
```

**Expected output from curl:**
- HTML content from OPNsense login page
- Or SSL/certificate errors (normal with -k flag)

**Expected output from nc/telnet:**
- "Connection succeeded" or similar

## Access Web UI

Once verified, access from your workstation browser:

```
https://192.168.35.XXX
```

Replace `XXX` with the actual WAN IP shown in the console.

**Login:**
- Username: `root`
- Password: (the password you set during installation)

## Permanent Solution - Configure Web UI Interface Binding

Once you're in the web UI:

Navigate: **System → Settings → Administration**

```
Listen Interfaces: Select "WAN" (or "All" to listen on all interfaces)
```

Click **Save**

This ensures the web UI is always accessible on WAN.

## Alternative - Access via LAN Instead

If you have a VM on VLAN 10 (management network), you can access OPNsense via LAN:

```
https://192.168.10.254
```

This is actually the **recommended** approach for security reasons (don't expose web UI on WAN).

To do this:
1. Create a VM on VLAN 10
2. Access OPNsense from that VM: `https://192.168.10.254`
3. Once in web UI, disable WAN access: **System → Settings → Administration** → Check "Disable web GUI redirect rule"

## Troubleshooting

### Still Can't Access After Reset

**Problem:** Web UI still not accessible after all attempts

**Check these:**

1. **VM firewall enabled?**
   ```bash
   # On Proxmox host
   qm config 100 | grep firewall
   ```

   If you see `firewall: 1`, disable it:
   ```bash
   qm set 100 --firewall 0
   qm reboot 100
   ```

2. **Your workstation firewall blocking?**
   ```bash
   # From your workstation
   telnet 192.168.35.XXX 443
   ```

   If this times out, your workstation firewall might be blocking outbound HTTPS.

3. **OPNsense not getting IP via DHCP?**

   From console menu, check the WAN IP. If it shows "not assigned":

   **Select:** `2` (Set interface IP address)
   **Select:** `1` (WAN)

   Configure with static IP:
   ```
   Configure IPv4 address WAN interface via DHCP? n
   Enter IPv4 address: 192.168.35.150
   Subnet bit count: 24
   Upstream gateway: 192.168.35.1 (or your lab gateway)
   ```

4. **Web service crashed?**

   From console shell:
   ```bash
   # Check web GUI status
   /usr/local/etc/rc.restart_webgui

   # Check logs
   tail -f /var/log/nginx/error.log
   ```

### Getting Certificate Errors

**This is normal!** OPNsense uses a self-signed certificate.

- **Firefox:** Click "Advanced" → "Accept the Risk and Continue"
- **Chrome:** Click "Advanced" → "Proceed to 192.168.35.XXX (unsafe)"
- **Safari:** Click "Show Details" → "visit this website"

You can configure a trusted certificate later via:
**System → Trust → Certificates**

## Quick Command Reference

```bash
# Access console
qm terminal 100

# Restart web GUI
/usr/local/etc/rc.restart_webgui

# Check web GUI is listening
sockstat -4 -l | grep :443

# Check WAN IP
ifconfig vtnet0 | grep inet

# Check LAN IP
ifconfig vtnet1 | grep inet

# View web GUI logs
tail -f /var/log/nginx/error.log

# Test from Proxmox
curl -k https://192.168.35.XXX
nc -zv 192.168.35.XXX 443
```

## Summary

The easiest method to enable web UI on WAN:

1. Access console: `qm terminal 100`
2. Login as `root`
3. Select option `2` (Set interface IP)
4. Select `1` (WAN)
5. Keep all settings the same (just press Enter through prompts)
6. This restarts the web GUI service
7. Access from browser: `https://<WAN-IP>`

If still not working, check:
- VM firewall (should be disabled)
- WAN has valid IP address
- Web service is running (`ps aux | grep nginx`)
- Port 443 is listening (`sockstat -4 -l | grep :443`)

---

**Need more help?** Check the full installation guide: `docs/guides/install-opnsense.md`
