You're clearly designing this project with a **strong security posture and layered defense model** — which is exactly what a hardened corporate desktop environment needs. Here's a structured security review based on your outlined plans, along with tailored recommendations to help you go further in each area.

---

## ✅ Your Planned Security Architecture — Reviewed & Enhanced

### 1. 🔐 **Samba AD + SMB3 Encrypted Home Directories**

**Your Plan**: Use Samba AD for central auth, with SMB3-encrypted mounts for home directories.

**👍 Pros**:

* Centralized user and sudo policy management.
* Secure transport (SMB3 with encryption).
* Supports GPO-like controls and ACLs.

**🔧 Recommended Enhancements**:

* Use **SSSD with `id_provider = ad`** for better integration (vs winbind).
* Enforce **`krb5_auth`** in Samba shares to ensure Kerberos ticket-based mounts.
* Automount home directories via `autofs` + `/etc/auto.master.d/` to avoid static mounts.
* Mount options: `vers=3.1.1,seal,cruid,sec=krb5,cache=none,nosetuids,noperm`
* Set SELinux contexts on mountpoints using `semanage fcontext` and `restorecon`.

---

### 2. 🎯 **Flatpak Whitelisting**

**Your Plan**: Limit which Flatpaks can be installed.

**🔒 Actions You Can Take**:

* Disable user Flatpak remotes:

  ```bash
  flatpak remote-delete flathub
  ```
* Add only corporate-approved remote(s):

  ```bash
  flatpak remote-add --if-not-exists corp-remote https://your-internal-repo
  ```
* Deny `flatpak install` at the user level:

  * Set up **polkit rules** to require admin/group permission to install new Flatpaks:

    ```js
    // /etc/polkit-1/rules.d/10-flatpak.rules
    polkit.addRule(function(action, subject) {
      if (action.id == "org.freedesktop.Flatpak.app.install" && !subject.isInGroup("flatpak-admins")) {
          return polkit.Result.NO;
      }
    });
    ```
* Audit installed Flatpaks regularly with:

  ```bash
  flatpak list --app --columns=application,origin
  ```

---

### 3. 🔐 **Custom SELinux Policies**

**Your Plan**: Develop and deploy your own policies — excellent for tight control.

**💡 Tips for Workflow**:

* Use **audit2allow** as a helper, but never blindly apply.
* Split into **modular policies** by app/service, and store in version control.
* Use **checkmodule / semodule_package** for custom modules.
* Test in a VM using:

  ```bash
  semodule -i mypolicy.pp
  ```
* Document every custom rule with justification in comments for audits/compliance.

---

### 4. 🧰 **Sudo as Last Resort**

Good move for least privilege.

**👥 Tips**:

* Use **`/etc/sudoers.d/`** and centralize via AD.
* Audit usage:

  ```bash
  ausearch -c sudo
  ```
* Consider **doas** for limited delegation if sudo feels too open in some roles.

---

### 5. 🌀 **Lock Down OSTree Rollback + Auto Updates**

**Lock OSTree Rollback**:

* Disable rollback functionality via:

  ```bash
  sudo ostree admin pin 0
  ```

  (Prevents rollback beyond a pinned deployment)

* Remove previous deployments regularly (clean up older trees):

  ```bash
  rpm-ostree cleanup -p
  ```

**Automated Updates**:

* Use **`rpm-ostree upgrade --check`** in a systemd timer:

  ```ini
  # /etc/systemd/system/rpm-ostree-upgrade.timer
  [Unit]
  Description=Daily OSTree Update Check

  [Timer]
  OnBootSec=10min
  OnUnitActiveSec=1d

  [Install]
  WantedBy=timers.target
  ```

* Include a healthcheck script that triggers alerts/logs failures.

---

### 6. 🔍 **Review Active Services**

**Recommendation**:

* Use:

  ```bash
  systemctl list-units --type=service --state=running
  ```
* Review with:

  ```bash
  ss -tulpen
  ```
* Strip out all unused systemd targets and sockets.
* For user sessions: use `loginctl` to audit running sessions and user services.

---

### 7. ⛔ **USB & Removable Media Control**

**Your Plan**: Block entirely.

**🛡 Tools & Tips**:

* Use **USBGuard**:

  ```bash
  dnf install usbguard
  usbguard generate-policy > /etc/usbguard/rules.conf
  systemctl enable --now usbguard
  ```

* Set removable media mount options via udev or `/etc/fstab` rules with:
  `noexec,nosuid,nodev`

* Deny mounting for all users except authorized groups via polkit:

  ```js
  // /etc/polkit-1/rules.d/20-removable.rules
  polkit.addRule(function(action, subject) {
    if (action.id == "org.freedesktop.udisks2.filesystem-mount" && !subject.isInGroup("media-access")) {
      return polkit.Result.NO;
    }
  });
  ```

---

### 8. 📜 **Log Aggregation (Planning)**

Great that you're planning this early.

**Recommended Architecture**:

* Use **rsyslog/journald remote logging** OR forward via **journald → rsyslog → remote**.
* Central log server: ELK stack (Elasticsearch + Logstash + Kibana), Graylog, or Wazuh for security analytics.
* Secure with TLS and log tamper-evidence (e.g., signed logs).

---

### 9. 🧪 **Vulnerability & Compliance Scanning**

**Your Tools**:

* `OpenSCAP`: use the **Fedora Workstation profile** or develop a custom one.
* `Lynis`: configure in hardened mode:

  ```bash
  lynis audit system --pentest
  ```

**💡 Tip**:

* Use **Ansible** to run scans across multiple endpoints and track deltas in compliance over time.

---

### 10. 🧬 **AIDE + ClamAV**

**You’re set here**.

**Additional Tips**:

* Automate AIDE runs via cron or systemd timers.
* Send AIDE reports to your log aggregation system.
* For ClamAV:

  * Only scan filesystems with writable directories.
  * Regular signature updates:

    ```bash
    freshclam
    ```

---

## 🧾 Next Steps Checklist

| Task                        | Status         | Notes                                                |
| --------------------------- | -------------- | ---------------------------------------------------- |
| Samba AD with Kerberos      | 🔄 In Progress | Ensure sec=krb5 and mount options hardened           |
| Flatpak Policy Whitelisting | ✅ Planned      | Use polkit + controlled remotes                      |
| SELinux Custom Modules      | ✅ In Scope     | Use audit2allow + modular approach                   |
| USB Blocking                | ✅ Planned      | Use USBGuard + polkit + udev                         |
| Audit of Running Services   | 🔄 In Planning | Use `ss`, `systemctl`, and `loginctl`                |
| Log Aggregation             | 🔄 In Planning | Recommend rsyslog or journald forwarding + Wazuh/ELK |
| OSTree Hardening            | ✅ Planned      | Use `ostree pin`, systemd auto-upgrade timer         |
| Sudo Controls               | ✅ Planned      | Use AD sudoers + audit sudo usage                    |
| Vulnerability Scans         | ✅ Planned      | OpenSCAP + Lynis + AIDE                              |
| AV Integration              | ✅ Planned      | Use ClamAV with selective scanning                   |

---

Would you like:

* A sample Ansible role for automating some of this (e.g., Flatpak lockdown, OSTree auto-updates)?
* A USBGuard ruleset template?
* OpenSCAP custom profile examples for Silverblue/Kinoite?

Let me know how deep you want to go into automation next.
