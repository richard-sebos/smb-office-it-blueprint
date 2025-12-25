---
title: "Proxmox VM Planning and Best Practices for SMB Infrastructure"
description: "Learn how to properly plan, size, and configure virtual machines in Proxmox for a production-ready small business IT environment with 11 VMs running Active Directory, file services, and workstations."
---

# Proxmox VM Planning and Best Practices for SMB Infrastructure

## Why Proper VM Planning Matters

You can't just throw virtual machines at Proxmox and hope for the best. I've seen too many environments where someone said "just give everything 4GB of RAM" and then wondered why their file server crawled or their domain controller randomly locked up during user authentication.

**Here's the reality:** A poorly planned virtualization environment will perform worse than bare metal servers, cost more in hardware, and create operational headaches that make you question why you virtualized in the first place.

But when done right, virtualization on Proxmox gives you:

- **Resource efficiency:** Run 11+ servers on hardware that couldn't support 3 bare metal systems
- **Flexibility:** Migrate VMs, create snapshots, test changes without risk
- **Cost savings:** One good server instead of a rack full of hardware
- **Management simplicity:** Single interface for your entire infrastructure

This article walks through the **exact planning process** for our 11-VM SMB infrastructure, with resource calculations, storage decisions, and network design that you can adapt to your own environment.

## The 11-VM Architecture Overview

Our SMB environment includes:

### Infrastructure Services (Critical - Must Stay Running)
1. **DC01** - Primary Samba AD Domain Controller
2. **DC02** - Secondary Domain Controller (redundancy)
3. **FILES01** - File server with departmental shares
4. **PRINT01** - Print server (CUPS)

### Workstation VMs (User-Facing)
5. **ADMIN-WS01** - Admin Assistant workstation
6. **HR-WS01** - HR Manager workstation
7. **FIN-WS01** - Finance Manager workstation
8. **EXEC-WS01** - Executive/Managing Partner workstation
9. **PROJ-WS01** - Project/Consulting professional workstation
10. **INTERN-WS01** - Intern/temporary worker workstation

### Management/Monitoring
11. **MGMT01** - Ansible control node, monitoring, backups

**Why 11 VMs?** This represents a realistic small business with:
- Department separation (HR, Finance, Operations)
- Role variety (executives, managers, assistants, interns)
- Redundancy where it matters (dual domain controllers)
- Real-world complexity without being overwhelming

## Hardware Requirements: What You Actually Need

Let's start with reality: You don't need a $10,000 server to run this lab.

### Minimum Viable Hardware

**For Learning/Lab Environment:**
- **CPU:** 6-core (12 threads) - Intel i5/i7 or AMD Ryzen 5/7
- **RAM:** 32GB DDR4
- **Storage:** 500GB NVMe SSD (or 1TB SATA SSD)
- **Network:** Gigabit NIC (onboard is fine)

**Cost:** ~$800-1200 used enterprise server or custom build

**For Production/Heavier Workloads:**
- **CPU:** 8-core (16 threads) - Intel Xeon or AMD EPYC/Threadripper
- **RAM:** 64GB DDR4 ECC
- **Storage:** 1TB NVMe SSD + 2TB SATA for backups
- **Network:** Dual gigabit NICs (for redundancy/VLANs)

**Cost:** ~$1500-2500 for used enterprise or custom build

### Why These Specs?

**CPU:** Modern virtualization relies on CPU overcommitment. With 6 cores (12 threads), you can assign 2 vCPUs to each of 11 VMs because most VMs aren't CPU-intensive simultaneously. Domain controllers and file servers spend most of their time waiting for I/O, not computing.

**RAM:** This is your constraint. RAM cannot be overcommitted safely. Our 11 VMs need:
- 2x Domain Controllers: 2GB each = 4GB
- 1x File Server: 4GB
- 1x Print Server: 2GB
- 6x Workstations: 2-3GB each = 15GB
- 1x Management: 2GB
- Proxmox host: 4GB

**Total: ~31GB** (32GB works, 64GB gives headroom)

**Storage:** Modern SSDs make this viable. You'll store:
- VM disks: ~200-300GB (thin provisioned)
- Templates: ~20GB
- ISO images: ~10GB
- Backups: ~150GB (using thin snapshots)
- Proxmox system: ~20GB

500GB is minimum, 1TB is comfortable.

## VM Resource Allocation Strategy

Here's the detailed breakdown for our 11-VM environment:

### Domain Controllers (DC01, DC02)

**Purpose:** Samba AD authentication, DNS, Kerberos

| Resource | Allocation | Reasoning |
|----------|------------|-----------|
| vCPU | 2 cores | AD is single-threaded for most operations; 2 cores handle concurrent auth requests |
| RAM | 2GB | Samba AD + DNS + Kerberos; generous for <100 users |
| Disk | 32GB | OS (20GB) + AD database (5GB) + logs (5GB) + growth |
| Network | 1 NIC (virtio) | Dedicated bridge, low bandwidth needs |

**Best Practices:**
- Use virtio drivers for network and disk (much faster than emulated)
- Enable CPU "host" type for better performance
- Place both DCs on different Proxmox storage pools if possible (redundancy)
- **DO NOT** overcommit CPU or RAM on domain controllers - they need guaranteed resources

**Storage Type:** Local SSD (fastest)

### File Server (FILES01)

**Purpose:** Departmental shares (HR, Finance, Projects, Shared)

| Resource | Allocation | Reasoning |
|----------|------------|-----------|
| vCPU | 2-4 cores | Samba file serving benefits from multiple cores for concurrent connections |
| RAM | 4GB | 2GB for OS, 2GB for Samba + file caching |
| Disk | 100GB | OS (20GB) + shares (60GB) + growth (20GB) |
| Network | 1 NIC (virtio) | Can add second NIC for isolated backup network |

**Best Practices:**
- Allocate extra disk via second virtual disk if shares grow
- Enable "discard" on VM disk to reclaim space from deleted files
- Use qcow2 format with thin provisioning
- Monitor I/O - file servers are I/O intensive
- Consider passing through a dedicated disk controller if you have heavy file I/O

**Storage Type:** Local SSD preferred, SATA acceptable

### Print Server (PRINT01)

**Purpose:** CUPS print queue management

| Resource | Allocation | Reasoning |
|----------|------------|-----------|
| vCPU | 1-2 cores | Print spooling is lightweight |
| RAM | 2GB | CUPS + print job spooling |
| Disk | 32GB | OS (20GB) + spool space (10GB) |
| Network | 1 NIC (virtio) | Low bandwidth |

**Best Practices:**
- Minimal resources - print servers don't need much
- Can be combined with file server if resources are tight
- Set disk cache mode to "writethrough" for print queue integrity

**Storage Type:** Any (even spinning disk acceptable)

### Workstations (Various)

**Purpose:** Linux desktop VMs for different user roles

| Resource | Standard | Power User | Reasoning |
|----------|----------|------------|-----------|
| vCPU | 2 cores | 4 cores | Desktop needs: 2 sufficient, 4 for responsiveness |
| RAM | 2-3GB | 4GB | Gnome/KDE desktop + apps; executives get more |
| Disk | 32GB | 40GB | OS (20GB) + apps (5GB) + user data (minimal, on file shares) |
| Network | 1 NIC | 1 NIC | Standard throughput |

**Role-Specific Allocations:**
- **ADMIN-WS01:** 2 vCPU, 2GB RAM (basic office tasks)
- **HR-WS01:** 2 vCPU, 3GB RAM (HR software, documents)
- **FIN-WS01:** 2 vCPU, 4GB RAM (accounting software, spreadsheets)
- **EXEC-WS01:** 4 vCPU, 4GB RAM (smooth experience, multiple apps)
- **PROJ-WS01:** 2 vCPU, 3GB RAM (project tools, documentation)
- **INTERN-WS01:** 2 vCPU, 2GB RAM (minimal, temporary)

**Best Practices:**
- Enable VirtIO-GPU for better graphics performance
- Use SPICE or VNC for remote console (not for daily use - users should RDP/SSH)
- Workstations should authenticate via SSSD, store data on file server
- Use thin provisioning - actual disk usage will be much less than allocated

**Storage Type:** Local SSD recommended for desktop responsiveness

### Management Node (MGMT01)

**Purpose:** Ansible control node, monitoring, scripts

| Resource | Allocation | Reasoning |
|----------|------------|-----------|
| vCPU | 2 cores | Script execution, Ansible playbooks |
| RAM | 2-4GB | Depends on monitoring stack |
| Disk | 40GB | OS (20GB) + Ansible roles (5GB) + logs/backups (15GB) |
| Network | 1 NIC | Management traffic only |

**Best Practices:**
- SSH access to all other VMs
- Store Ansible inventory, playbooks, scripts
- Can run monitoring (Prometheus, Grafana) if RAM increased to 4-6GB
- Keep backed up - this VM contains your automation

**Storage Type:** Local SSD

## Complete Resource Matrix

Here's the full allocation table:

| VM Name | vCPU | RAM (GB) | Disk (GB) | Purpose | Priority |
|---------|------|----------|-----------|---------|----------|
| DC01 | 2 | 2 | 32 | Primary Domain Controller | **CRITICAL** |
| DC02 | 2 | 2 | 32 | Secondary Domain Controller | **CRITICAL** |
| FILES01 | 4 | 4 | 100 | File Server | **HIGH** |
| PRINT01 | 2 | 2 | 32 | Print Server | MEDIUM |
| ADMIN-WS01 | 2 | 2 | 32 | Admin Assistant Workstation | MEDIUM |
| HR-WS01 | 2 | 3 | 32 | HR Manager Workstation | MEDIUM |
| FIN-WS01 | 2 | 4 | 32 | Finance Manager Workstation | HIGH |
| EXEC-WS01 | 4 | 4 | 40 | Executive Workstation | HIGH |
| PROJ-WS01 | 2 | 3 | 32 | Project Professional Workstation | MEDIUM |
| INTERN-WS01 | 2 | 2 | 32 | Intern Workstation | LOW |
| MGMT01 | 2 | 3 | 40 | Management/Ansible Node | HIGH |
| **TOTAL** | **26 vCPU** | **31 GB** | **436 GB** | | |

**With Proxmox Host Overhead:** ~32GB RAM, ~500GB disk, 6-8 physical cores

## Storage Strategy: Where to Put What

Proxmox supports multiple storage types. Here's how to use them effectively:

### Storage Types Explained

**Local (Proxmox Host Disk):**
- Best for: VM disks, templates, ISOs
- Performance: Excellent (if SSD)
- Redundancy: None (single host)
- Format: Directory, LVM, LVM-thin, ZFS

**Network Storage (NFS, iSCSI, Ceph):**
- Best for: Shared storage, live migration
- Performance: Good (depends on network)
- Redundancy: Yes (if configured)
- Format: Various

**For This Project:** We'll use **local SSD storage** with **LVM-thin** provisioning.

### Why LVM-Thin?

**Thin Provisioning** means you allocate 100GB to a VM, but it only uses disk space for data actually written. Benefits:

- Allocate 436GB across VMs, actually use ~200GB
- Snapshots are fast and efficient
- Easy to extend volumes when needed

**Alternative:** ZFS gives you compression, snapshots, and better data integrity, but requires more RAM and CPU overhead. For a learning lab, LVM-thin is simpler.

### Storage Layout

```
/dev/sda (500GB NVMe SSD)
├── 100GB - Proxmox root filesystem (ext4)
├── 400GB - VM storage pool (LVM-thin)
    └── VMs stored here with thin provisioning
```

**Configuration in Proxmox:**
1. Datacenter → Storage
2. Create LVM-Thin volume group
3. Set as default for VM disks
4. Enable thin provisioning

### Disk Performance Tuning

**For each VM, set these disk options:**

| Setting | Value | Why |
|---------|-------|-----|
| Cache | Write-through | Prevents data corruption on host crashes |
| Discard | Enabled | Allows TRIM/discard for thin provisioning |
| IO Thread | Enabled | Offloads I/O to dedicated thread |
| SSD Emulation | Enabled | Guest OS can use TRIM |

**For domain controllers and file server, use:**
- Cache: None (direct I/O, better for databases)
- AIO: Native (better performance)

## Network Architecture: VLANs and Bridges

Proper network segmentation is critical for security and performance.

### Network Design

We'll use **three network segments:**

1. **Management Network (VLAN 10):** Proxmox host, SSH access, Ansible
   - Subnet: 10.0.10.0/24
   - Gateway: 10.0.10.1

2. **Server Network (VLAN 20):** Domain controllers, file/print servers
   - Subnet: 10.0.20.0/24
   - Gateway: 10.0.20.1

3. **Workstation Network (VLAN 30):** User workstations
   - Subnet: 10.0.30.0/24
   - Gateway: 10.0.30.1

**Why Separate Networks?**
- **Security:** Segment workstations from infrastructure
- **Traffic Control:** Prevent broadcast storms
- **Troubleshooting:** Isolate network issues
- **Compliance:** Separate financial/HR systems from general workstations

### Proxmox Network Bridge Configuration

**Create Linux Bridges in Proxmox:**

```bash
# Management Bridge (vmbr0)
auto vmbr0
iface vmbr0 inet static
    address 10.0.10.10/24
    gateway 10.0.10.1
    bridge-ports eno1
    bridge-stp off
    bridge-fd 0

# Server VLAN Bridge (vmbr1)
auto vmbr1
iface vmbr1 inet manual
    bridge-ports eno1.20
    bridge-stp off
    bridge-fd 0
    bridge-vlan-aware yes

# Workstation VLAN Bridge (vmbr2)
iface vmbr2 inet manual
    bridge-ports eno1.30
    bridge-stp off
    bridge-fd 0
    bridge-vlan-aware yes
```

**VM Network Assignments:**

| VM | Bridge | VLAN | IP Address |
|----|--------|------|------------|
| DC01 | vmbr1 | 20 | 10.0.20.11 |
| DC02 | vmbr1 | 20 | 10.0.20.12 |
| FILES01 | vmbr1 | 20 | 10.0.20.21 |
| PRINT01 | vmbr1 | 20 | 10.0.20.22 |
| ADMIN-WS01 | vmbr2 | 30 | 10.0.30.31 |
| HR-WS01 | vmbr2 | 30 | 10.0.30.32 |
| FIN-WS01 | vmbr2 | 30 | 10.0.30.33 |
| EXEC-WS01 | vmbr2 | 30 | 10.0.30.34 |
| PROJ-WS01 | vmbr2 | 30 | 10.0.30.35 |
| INTERN-WS01 | vmbr2 | 30 | 10.0.30.36 |
| MGMT01 | vmbr0 | 10 | 10.0.10.20 |

**DNS Configuration:**
- Primary DNS: 10.0.20.11 (DC01)
- Secondary DNS: 10.0.20.12 (DC02)
- All VMs point to DCs for name resolution

## VM Template Strategy

Don't create VMs from scratch every time. Build **templates** once, clone forever.

### Creating Base Templates

**Template 1: Oracle Linux 9 (Server)**

1. Install minimal Oracle Linux 9
2. Update all packages: `dnf update -y`
3. Install base tools: `dnf install -y vim wget curl net-tools`
4. Configure cloud-init (for Proxmox customization)
5. Remove SSH host keys: `rm /etc/ssh/ssh_host_*`
6. Clear machine ID: `truncate -s 0 /etc/machine-id`
7. Clean yum cache: `dnf clean all`
8. Power down
9. Convert to template in Proxmox

**Use for:** DC01, DC02, FILES01, PRINT01, MGMT01

**Template 2: Ubuntu Server 22.04 LTS**

1. Install minimal Ubuntu Server
2. Update: `apt update && apt upgrade -y`
3. Install base tools: `apt install -y vim wget curl net-tools`
4. Install cloud-init: `apt install -y cloud-init`
5. Clean cloud-init: `cloud-init clean`
6. Remove SSH host keys: `rm /etc/ssh/ssh_host_*`
7. Clear machine ID: `truncate -s 0 /etc/machine-id`
8. Clean apt cache: `apt clean`
9. Power down
10. Convert to template

**Use for:** Workstation VMs (with desktop environment added post-clone)

### Cloning VMs from Templates

**Proxmox GUI:**
1. Right-click template → Clone
2. Select "Full Clone" (linked clones have dependencies)
3. Set new VM ID and name
4. Customize resources (CPU, RAM, disk)

**Proxmox CLI (Faster for Multiple VMs):**

```bash
# Clone template 100 to create DC01 (VM ID 101)
qm clone 100 101 --name DC01 --full

# Resize disk if needed
qm resize 101 scsi0 +20G

# Set CPU and RAM
qm set 101 --cores 2 --memory 2048

# Set network
qm set 101 --net0 virtio,bridge=vmbr1,tag=20
```

**Ansible Automation (Coming in Later Article):**
We'll automate VM cloning, customization, and provisioning using Ansible's Proxmox modules.

## Performance Best Practices

### CPU Configuration

**CPU Type:** Set to "host" for best performance
- Exposes all host CPU features to guest
- Better than emulated CPU types (kvm64, qemu64)
- VMs can use hardware virtualization extensions

**CPU Units:** Weight CPU allocation
- Default: 1024
- Critical VMs (DC01, DC02): 2048 (2x priority)
- Workstations: 1024 (standard)
- Low priority (INTERN-WS01): 512

**NUMA:** Not needed for our host size
- Only matters with >2 CPU sockets
- Our single CPU doesn't benefit

### Memory Configuration

**Ballooning:** Disabled for production VMs
- Ballooning allows Proxmox to reclaim "unused" RAM
- Can cause performance issues if guest needs RAM suddenly
- **Disable for:** DC01, DC02, FILES01
- **Enable for:** Workstations (can tolerate brief delays)

**Minimum RAM:** Set minimum guaranteed RAM
- Ensures VM always has minimum resources
- Set to 75% of allocated RAM

**Example:**
- Allocated: 4GB
- Minimum: 3GB
- Allows Proxmox to balloon 1GB if host is under pressure

### Disk I/O

**I/O Threads:** Enable for all VMs
- Offloads disk I/O to dedicated threads
- Reduces CPU overhead
- Noticeable improvement on SSDs

**I/O Limits:** Set for fairness
- Prevents single VM from saturating disk
- Example limits (MB/s):
  - Domain Controllers: 200 MB/s
  - File Server: 300 MB/s
  - Workstations: 100 MB/s

**SSD Emulation:** Enable
- Allows guest to use TRIM/discard
- Keeps thin provisioning efficient
- Guest sees SSD, uses appropriate I/O scheduler

### Network Performance

**VirtIO Drivers:** Always use VirtIO
- Paravirtualized network driver
- 3-5x faster than emulated e1000
- Supported by all modern Linux distros

**Multi-Queue:** Enable for high-traffic VMs
- Allows network I/O across multiple CPU cores
- Set queues = number of vCPUs (up to 8)
- Enable on: FILES01, Domain Controllers

**Firewall:** Disable on Proxmox bridges (if using VM firewalls)
- Reduces overhead
- Configure firewalls inside VMs instead

## Backup Strategy

You will lose data. Plan for it.

### Proxmox Built-in Backup

**Backup Schedule:**
- **Critical VMs (DC01, DC02, FILES01):** Daily
- **Important VMs (Workstations, MGMT01):** Weekly
- **Low Priority (INTERN-WS01):** Monthly or none

**Backup Modes:**

| Mode | Downtime | Speed | Use Case |
|------|----------|-------|----------|
| Snapshot | None | Fast | Running VMs, LVM-thin storage |
| Suspend | Brief pause | Fast | VMs that can tolerate pause |
| Stop | Full shutdown | Fastest | VMs you can stop |

**Use Snapshot mode** for all VMs (requires LVM-thin or ZFS)

**Retention:**
- Daily backups: Keep 7 days
- Weekly backups: Keep 4 weeks
- Monthly backups: Keep 3 months

**Backup Storage:**
- **Best:** External NAS via NFS (separate from Proxmox host)
- **Acceptable:** Second local disk (not the same as VM storage)
- **Last Resort:** Same disk (better than nothing, but doesn't protect from disk failure)

### Backup Testing

**Monthly:** Restore one VM from backup to verify integrity
- Don't just assume backups work
- Restore to test VM ID, boot, verify

## High Availability Considerations

Our single-host setup isn't truly "highly available," but we can improve resilience:

### Redundancy Within Single Host

**Dual Domain Controllers:** If DC01 fails, DC02 takes over
- Users can still authenticate
- DNS still resolves
- No single point of failure for authentication

**Snapshot Before Changes:** Before major changes, snapshot VMs
- Quick rollback if something breaks
- Snapshots are cheap with LVM-thin

**UPS:** Invest in a good UPS
- Protects from power failures
- Gives time for graceful shutdown
- ~$200-400 for quality unit

### Future: Multi-Host Clustering

If you grow beyond one server:
- Add second Proxmox host
- Create Proxmox cluster
- Enable HA (VMs auto-migrate on host failure)
- Shared storage (Ceph, NFS) for live migration

**For now:** Document everything so you can rebuild quickly if hardware fails.

## Monitoring and Maintenance

### Built-in Proxmox Monitoring

**Watch These Metrics:**
- Host CPU utilization (should average <60%)
- Host RAM usage (should stay <80%)
- Disk I/O wait (should be <5%)
- Network throughput (should not saturate gigabit)

**Warning Signs:**
- CPU steal time >10% (VMs contending for CPU)
- RAM ballooning aggressive (host under-provisioned)
- High I/O wait (disk bottleneck)

### VM-Level Monitoring

**Install on MGMT01:**
- Prometheus (metrics collection)
- Grafana (visualization)
- Node Exporter on each VM (system metrics)

**Track:**
- VM CPU/RAM usage over time
- Disk space trends
- Authentication failures (from auditd)
- Samba connection counts

### Maintenance Windows

**Monthly Tasks:**
1. Apply OS updates to all VMs (Ansible playbook)
2. Review backup logs
3. Test one backup restore
4. Review disk usage, expand if needed
5. Check Proxmox updates

**Quarterly Tasks:**
1. Review VM resource allocations (right-sizing)
2. Clean old snapshots
3. Rotate backup retention
4. Security audit (covered in future article)

## Common Mistakes to Avoid

### Over-Provisioning Everything

**Mistake:** "I'll give every VM 8GB RAM and 4 CPUs just to be safe"

**Reality:** You run out of host resources and can't start VMs

**Solution:** Start conservative, monitor, adjust based on actual usage

### Under-Provisioning Critical Systems

**Mistake:** "Domain controller only needs 512MB RAM"

**Reality:** Authentication delays, random lockups, user complaints

**Solution:** Give infrastructure VMs (DCs, file servers) guaranteed resources

### No Network Segmentation

**Mistake:** All VMs on same flat network

**Reality:** Security issues, broadcast storms, difficult troubleshooting

**Solution:** Use VLANs and bridges to segment traffic

### Skipping Backups

**Mistake:** "I'll set up backups later"

**Reality:** Data loss after accidental deletion, corruption, or host failure

**Solution:** Configure backups on day 1, test them monthly

### Using Emulated Hardware

**Mistake:** Default to e1000 network, IDE disk

**Reality:** Terrible performance, wasted host resources

**Solution:** Always use VirtIO for network and disk

### No Documentation

**Mistake:** "I'll remember how I configured this"

**Reality:** Six months later, you have no idea what VM 117 is for

**Solution:** Document VM purposes, IP addresses, resource allocations (we'll cover this with Ansible inventory)

## Practical Example: Creating DC01

Let's walk through creating the first domain controller using best practices:

### Step 1: Clone from Template

```bash
# Clone Oracle Linux 9 template (VM 100) to create DC01 (VM 101)
qm clone 100 101 --name DC01 --full --storage local-lvm
```

### Step 2: Configure Resources

```bash
# Set CPU
qm set 101 --cores 2 --cpu host --cpuunits 2048

# Set RAM (2GB, no ballooning)
qm set 101 --memory 2048 --balloon 0

# Set disk options
qm set 101 --scsi0 local-lvm:vm-101-disk-0,cache=none,discard=on,iothread=1,ssd=1
```

### Step 3: Configure Network

```bash
# Add network interface on server VLAN
qm set 101 --net0 virtio,bridge=vmbr1,tag=20,firewall=0,queues=2
```

### Step 4: Set Boot Options

```bash
# Set boot order, enable QEMU guest agent
qm set 101 --boot order=scsi0 --agent enabled=1
```

### Step 5: Configure Cloud-Init (Optional but Recommended)

```bash
# Set IP configuration via cloud-init
qm set 101 --ipconfig0 ip=10.0.20.11/24,gw=10.0.20.1

# Set DNS servers
qm set 101 --nameserver "10.0.20.11 10.0.20.12"

# Set SSH key (replace with your public key)
qm set 101 --sshkey ~/.ssh/id_rsa.pub

# Set user
qm set 101 --ciuser administrator
```

### Step 6: Start VM

```bash
qm start 101
```

### Step 7: Verify and Connect

```bash
# Check status
qm status 101

# Get VNC access (for console)
qm terminal 101

# Or SSH (once cloud-init completes)
ssh administrator@10.0.20.11
```

**Repeat this process** for all 11 VMs, adjusting resources, networks, and IP addresses per the matrix above.

**Or better:** Use Ansible to automate all of this (upcoming article).

## Conclusion: Plan First, Deploy Confidently

Proper VM planning is the difference between a lab you're proud of and a frustrating mess you want to rebuild.

**Key Takeaways:**

1. **Size appropriately:** Not too much, not too little - monitor and adjust
2. **Segment networks:** Use VLANs/bridges for security and performance
3. **Use templates:** Build once, clone many
4. **Enable VirtIO:** Always, for network and disk
5. **Backup from day 1:** And test those backups regularly
6. **Document everything:** Your future self will thank you

With this foundation, you're ready to build a professional virtualization environment that performs well, uses resources efficiently, and provides the flexibility to experiment without risk.

**Next in this series:** We'll dive into Proxmox installation, initial configuration, and creating our VM templates from scratch.

---

## Quick Reference: VM Resource Matrix

| VM | vCPU | RAM | Disk | Network | Priority |
|----|------|-----|------|---------|----------|
| DC01 | 2 | 2GB | 32GB | vmbr1 (VLAN20) | CRITICAL |
| DC02 | 2 | 2GB | 32GB | vmbr1 (VLAN20) | CRITICAL |
| FILES01 | 4 | 4GB | 100GB | vmbr1 (VLAN20) | HIGH |
| PRINT01 | 2 | 2GB | 32GB | vmbr1 (VLAN20) | MEDIUM |
| ADMIN-WS01 | 2 | 2GB | 32GB | vmbr2 (VLAN30) | MEDIUM |
| HR-WS01 | 2 | 3GB | 32GB | vmbr2 (VLAN30) | MEDIUM |
| FIN-WS01 | 2 | 4GB | 32GB | vmbr2 (VLAN30) | HIGH |
| EXEC-WS01 | 4 | 4GB | 40GB | vmbr2 (VLAN30) | HIGH |
| PROJ-WS01 | 2 | 3GB | 32GB | vmbr2 (VLAN30) | MEDIUM |
| INTERN-WS01 | 2 | 2GB | 32GB | vmbr2 (VLAN30) | LOW |
| MGMT01 | 2 | 3GB | 40GB | vmbr0 (VLAN10) | HIGH |

**Total Resources:** 26 vCPU, 31GB RAM, 436GB disk

**Recommended Host:** 6-8 cores, 32-64GB RAM, 500GB-1TB SSD

---

## Additional Resources

**Proxmox Documentation:**
- [Official Proxmox VE Documentation](https://pve.proxmox.com/pve-docs/)
- [Proxmox VE Best Practices](https://pve.proxmox.com/wiki/Performance_Tweaks)

**Community Resources:**
- [r/Proxmox](https://reddit.com/r/Proxmox) - Active community
- [Proxmox Forums](https://forum.proxmox.com/) - Official support

**Our Series:**
- Article 01: Introduction to the SMB IT Blueprint
- Article 02: Proxmox VM Planning (this article)
- Article 03: Proxmox Installation and Initial Configuration (coming next)

---

**Author:** Richard Chamberlain
**Series:** SMB Office IT Blueprint
**Last Updated:** December 2025
**Contact:** [info@sebostechnology.com](mailto:info@sebostechnology.com)
