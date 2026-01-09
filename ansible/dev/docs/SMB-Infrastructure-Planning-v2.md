# Stop Rebuilding Your Infrastructure From Scratch Every Time

## The SMB IT Problem Nobody Talks About

You've been hired to "set up IT" for a 25-person company. They need:
- File shares that actually work
- Active Directory so users stop sharing passwords
- Backups that you can actually restore from
- Something that won't fall apart when Carol in accounting accidentally clicks that phishing link

You know what you need to build. But here's the problem:

**Every time you start a new engagement, you're building the same infrastructure from scratch.**

You waste 40 hours (or more) on basic setup:
- Manually installing Ubuntu Server... again
- Googling "how to configure Samba AD DC" for the 10th time
- Forgetting which firewall ports AD actually needs
- Realizing 3 weeks later that you didn't segment the network properly
- Explaining to the owner why the printer on the user VLAN just ransomwared your domain controller

And the worst part? **You don't get paid for those 40 hours of repetitive setup work.** You get paid for the value you deliver, not the time you waste rebuilding the same infrastructure you built last month for a different client.

## What If You Had a Blueprint?

Imagine this instead:

**Day 1:** You run 3 Ansible commands. By lunch, you have:
- Two redundant domain controllers running Samba AD
- Centralized file server with proper permissions
- Network segmentation (users can't attack servers)
- SSH hardening on every system
- Automated backups configured
- Monitoring and alerting running

**Day 2-5:** You spend time on **actual value-add work**:
- Creating user accounts and group policies
- Configuring line-of-business applications
- Training the team on the new systems
- Writing runbooks for their staff

**Result:** You deliver a production-ready infrastructure in 1 week instead of 1 month, and you actually got paid for work that matters.

---

## This is That Blueprint

This article documents a **repeatable, automated, production-tested** infrastructure design for SMBs that you can deploy in hours instead of weeks.

### What You're Getting

**The Architecture:**
- 11-VM infrastructure designed for 10-100 users
- Complete network segmentation (6 VLANs)
- Zero Windows Server licensing costs
- High availability for critical services
- Security that actually passes audits

**The Automation:**
- Ansible playbooks for entire deployment
- Infrastructure-as-Code (rebuild in disaster scenarios)
- Repeatable across clients (change 3 variables, deploy)
- Tested and documented (no "figure it out" moments)

**The Cost Savings:**
- $13,000+ saved vs Windows Server licensing (3-year TCO)
- 80% reduction in deployment time
- Repeatable = predictable billing
- Professional = fewer 2am emergency calls

### Who This is For

✅ **You are an MSP or consultant** who deploys infrastructure for multiple SMB clients
✅ **You're tired of reinventing the wheel** every time you start a new project
✅ **You want to use Linux** but your clients expect "enterprise features" (AD, file shares, etc.)
✅ **You're sick of Windows Server licensing costs** eating your profit margins
✅ **You want infrastructure you can actually maintain** 6 months from now

❌ **You're not:** Someone who wants to click through GUI installers and hope it works

---

## The Real-World Problem This Solves

### Client Scenario: 25-Person Law Firm

**What They Need:**
- Secure document storage (client confidentiality)
- User accounts with Single Sign-On
- Remote access (VPN)
- Compliance (data retention, audit trails)
- Actually works on Monday morning

**The Old Way (Windows Server):**
- 2x Windows Server Standard licenses: $1,800
- 25 CALs (User + Device): $2,500
- Exchange/M365: $1,500/year
- Your time (manual setup): 60 hours @ $100/hr = $6,000
- **Total Year 1: $11,800 + $6,000 labor**
- **Client billed:** $20,000 (they negotiate down to $15,000)
- **Your actual profit:** $3,200 (after your time)

**The New Way (This Blueprint):**
- Linux infrastructure: $0 licensing
- Proxmox host: $3,000 (one-time hardware)
- Your time (automated): 15 hours @ $100/hr = $1,500
- **Total Year 1: $4,500**
- **Client billed:** $12,000 (50% cheaper than Windows, easy sell)
- **Your actual profit:** $7,500 (you delivered in 1 week not 1 month)

**And:** You just created a repeatable playbook. Next client? 10 hours instead of 15. Profit goes up.

---

## What Makes This Different From "Just Install Linux"

**This is not a homelab tutorial.** This is a production infrastructure blueprint used by real businesses.

### The Problem with Most Linux Infrastructure Guides

**They tell you:**
1. Install Ubuntu
2. `apt install samba`
3. "Configure it to your needs"
4. ???
5. Profit!

**They don't tell you:**
- How to design network segmentation that actually stops lateral movement
- Which Samba AD DC version doesn't break on Ubuntu (it's complicated)
- How to automate this so you can deploy to Client #2, #3, #4...
- What firewall rules Active Directory actually needs (it's not just 135,389,445)
- How to recover when the DC crashes at 2am
- Why your IP cameras just became a botnet when you put them on the user VLAN

**This blueprint tells you all of that.**

### What's Actually Included

#### 1. The Architecture (Designed by Someone Who's Been Burned)

11 VMs, each with a specific job:
- **dc01 + dc02**: Redundant domain controllers (HA, not "whoops single point of failure")
- **file-server01**: Centralized storage with AD-integrated permissions
- **ansible-ctrl**: Your automation hub (rebuild everything from code)
- **monitoring01**: Know when things break before users call you
- **backup-server**: Actually tested restores (not "we think backups work?")
- **ws-admin01**: Admin workstation (privileged access separate from users)
- **jump-box01**: Bastion host (security, audit trail)
- **app-server01**: Business applications (don't put these on the DC!)
- **dev-test01**: Test changes before breaking production
- **web-dmz01**: Public services in DMZ (don't expose your DCs to internet)

#### 2. The Network Design (Because Flat Networks Get You Hacked)

**6 VLANs with actual security:**
- Management (110): Proxmox, backups - **attackers don't get here from user network**
- Servers (120): Domain controllers, file server - **critical services isolated**
- Workstations (130): User computers - **contained if compromised**
- Admin (131): IT workstations - **privileged access separated**
- IoT (140): Printers, cameras - **isolated, can't attack anything**
- DMZ (150): Public web server - **breaches don't touch internal network**

**Default firewall rule:** Deny all. Every connection justified.

#### 3. The Automation (Deploy Once, Use Forever)

**Ansible playbooks for everything:**
```bash
# New client? Change 3 variables:
domain: "clientname.local"
ip_subnet: "10.1.0.0/16"
admin_user: "client-admin"

# Run 2 commands:
ansible-playbook deploy-infrastructure.yml    # 20 minutes
ansible-playbook configure-ad.yml             # 10 minutes

# Done. Invoice client.
```

**What this actually does:**
- Clones VMs from templates on Proxmox
- Configures static IPs and VLANs
- Installs and configures Samba AD DC (both DCs)
- Sets up file shares with AD permissions
- Deploys SSH keys and hardens security
- Configures monitoring and backups
- Runs verification tests
- Generates documentation

**Without automation, this is 40+ hours of manual work. With automation: 30 minutes of your actual time.**

#### 4. The Documentation (For Your 2am Self)

- Disaster recovery runbooks
- Common issues and fixes
- How to add users/groups/OUs
- Firewall rule justifications
- Client handoff documentation
- Why you made each architectural decision

**Because 6 months from now, you won't remember why you did it that way.**

---

## The "But What About..." Section

### "My Clients Expect Windows Server"

**Your clients expect:**
- File shares that work
- Centralized user management
- Things that "just work"

**They don't care about the OS.** They care about results.

**Samba AD DC provides:**
- Full Active Directory compatibility (Windows clients join the domain)
- Group Policy support
- Kerberos authentication
- DNS and LDAP
- SMB file shares with Windows ACLs

**Your clients will never know it's not Windows Server.** And you saved them $13,000 in licensing.

### "I Don't Know Ansible"

**You don't need to.**

The playbooks are written. You just:
1. Change variables (domain name, IP addresses, admin user)
2. Run the command
3. Verify it worked

**Learning to customize:** 2-4 hours of reading the playbooks
**Learning to write from scratch:** Not necessary for this use case

**Ansible is easier than PowerShell DSC**, and you've probably written PowerShell scripts.

### "What If Something Breaks?"

**That's why there are 2 DCs.**

If dc01 fails:
- dc02 handles all authentication and DNS automatically
- Users keep working
- You fix dc01 when convenient (not at 2am)

**Plus:**
- Automated backups (tested restores)
- Infrastructure-as-Code (rebuild from playbooks)
- Monitoring alerts you before users notice
- Runbooks for common issues

**You're actually better positioned than a Windows Server environment** where "rebuild the DC" means 8 hours of panic.

### "My Client Needs [Specific Windows Thing]"

**Legitimate Windows-only requirements:**
- Exchange Server (use M365 or Zimbra instead)
- SQL Server with specific app dependency (run on Windows VM in environment)
- Software with hard Windows Server dependency (evaluate if client actually needs it)

**Most "Windows requirements" are actually:**
- File shares → Samba works perfectly
- Active Directory → Samba AD DC is AD-compatible
- Print server → Samba handles this
- DHCP/DNS → Samba or other Linux solutions
- VPN → OpenVPN, WireGuard, pfSense

**Reality:** 80% of SMB "Windows Server" deployments can be Linux. For the remaining 20%, add a Windows VM to this infrastructure.

---

## The Actual Infrastructure Design

### High-Level Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                        INTERNET                              │
└───────────────────┬─────────────────────────────────────────┘
                    │
          ┌─────────▼──────────┐
          │  pfSense Firewall  │
          │   (UTM/IDS/IPS)    │
          └────────┬───────────┘
                   │
    ┌──────────────┼──────────────┬────────────┐
    │              │              │            │
VLAN 150 (DMZ)  VLAN 110 (Mgmt)  VLAN 120    VLAN 130/131
    │              │          (Servers)        (Users/Admin)
    │              │              │             │
┌───▼───┐     ┌───▼───┐    ┌────▼─────┐  ┌───▼───┐
│  Web  │     │Proxmox│    │DC01/DC02 │  │Workst.│
│ DMZ01 │     │Backup │    │File Srvr │  │Admin  │
└───────┘     └───────┘    │Ansible   │  └───────┘
                            │Monitor   │
                            └──────────┘
```

**Why This Design:**
- **Security:** Compromise in one zone doesn't spread
- **Simplicity:** Each VM has one job
- **Reliability:** Redundancy where it matters (DCs)
- **Scalability:** Add VMs without redesigning network
- **Maintainability:** Clear separation, easy to troubleshoot

### The 11 VMs Explained

#### Critical Infrastructure (Boot These First)

**1. dc01 - Primary Domain Controller**
- **Why:** All authentication flows through here
- **Ubuntu 22.04 + Samba AD DC**
- **IP:** 10.0.120.10
- **Resources:** 2 vCPU, 4GB RAM, 100GB disk
- **RTO:** 1 hour (business stops without this)

**2. dc02 - Secondary Domain Controller**
- **Why:** If dc01 dies, business continues
- **Ubuntu 22.04 + Samba AD DC**
- **IP:** 10.0.120.11
- **Resources:** 2 vCPU, 4GB RAM, 100GB disk
- **RTO:** 4 hours (running on dc01 only is fine short-term)

**The DC conversation you need to have with clients:**

**Client:** "Why do we need two domain controllers?"

**You:** "Remember when your server crashed last year and nobody could work for 8 hours? With two DCs, if one fails, the other takes over automatically. Nobody even notices. Worth the extra $50/month?"

**Client:** "Yes."

#### Business Services

**3. file-server01 - Centralized File Storage**
- **Why:** Users need to share files securely
- **Ubuntu 22.04 + Samba File Server**
- **IP:** 10.0.120.20
- **Resources:** 2 vCPU, 8GB RAM, 500GB-2TB disk
- **Shares:** Company shared drive, departmental folders, user home directories

**4. app-server01 - Business Applications**
- **Why:** Don't run your business apps on the domain controller
- **Ubuntu 22.04 + Docker**
- **IP:** 10.0.120.30
- **Use cases:** Internal web apps, databases, custom LOB software

#### Management Infrastructure

**5. ansible-ctrl - Automation Hub**
- **Why:** Rebuild entire infrastructure from code
- **Rocky Linux 9 + Ansible**
- **IP:** 10.0.120.50
- **Value:** Deploy next client in 30 minutes instead of 40 hours

**6. monitoring01 - Observability**
- **Why:** Know about problems before users do
- **Rocky Linux 9 + Prometheus + Grafana**
- **IP:** 10.0.120.60
- **Alerts:** Disk space, service failures, security events

**7. backup-server - Disaster Recovery**
- **Why:** Backups you can actually restore from
- **Rocky Linux 9 + Proxmox Backup Server**
- **IP:** 10.0.110.20 (Management VLAN - access to all VLANs)
- **Critical:** Test restores quarterly

#### Security Infrastructure

**8. ws-admin01 - Admin Workstation**
- **Why:** Privileged access separated from user network
- **Rocky Linux 9 Desktop**
- **IP:** 10.0.131.10 (Admin VLAN)
- **Security:** If users get compromised, attackers can't reach admin tools

**9. jump-box01 - SSH Bastion Host**
- **Why:** Single point of entry for SSH (audit trail, 2FA)
- **Ubuntu 22.04 Minimal**
- **IP:** 10.0.131.20
- **Security:** All SSH access logged and monitored

#### Optional but Recommended

**10. dev-test01 - Testing Environment**
- **Why:** Test changes before breaking production
- **Ubuntu 22.04**
- **IP:** 10.0.120.31
- **Use:** Test OS updates, software changes, etc.

**11. web-dmz01 - Public Web Server**
- **Why:** Internet-facing services isolated from internal network
- **Ubuntu 22.04 + Nginx**
- **IP:** 10.0.150.10 (DMZ)
- **Security:** Breach doesn't touch domain controllers or file server

---

## The Cost Reality Check

### Scenario: 30-Person Company, 3-Year TCO

#### Option 1: Windows Server (Traditional)

**Year 1:**
- 2x Windows Server 2022 Standard: $1,800
- 30 CALs (user): $2,100
- 30 Device CALs: $1,400
- Backup software (Veeam): $800
- Your labor (120 hours): $12,000
- **Total Year 1: $18,100**

**Year 2-3:**
- M365 Business Basic (email): $1,800/year
- Backup software renewal: $600/year
- Maintenance (20 hours/year): $2,000/year
- **Total Year 2-3: $8,800**

**3-Year Total: $35,700**
**Your labor: 160 hours**
**Client perceives value:** "IT is expensive"

#### Option 2: This Linux Blueprint

**Year 1:**
- Proxmox host (hardware): $3,000
- Linux licensing: $0
- Backup storage (NAS): $800
- Your labor (30 hours): $3,000
- **Total Year 1: $6,800**

**Year 2-3:**
- Electricity: $400/year
- Internet: $800/year (business line)
- Maintenance (10 hours/year): $1,000/year
- **Total Year 2-3: $4,400**

**3-Year Total: $15,600**
**Your labor: 50 hours**
**Client perceives value:** "Our IT person is efficient"

**Savings: $20,100 over 3 years**
**Your time saved: 110 hours**

**At $100/hour billing rate:** You saved 110 hours that you can bill to other clients = $11,000 more revenue.

### The MSP Multiplier

If you manage 10 SMB clients:
- **Time saved:** 1,100 hours over 3 years
- **Revenue opportunity:** $110,000
- **Client savings:** $201,000 (happy clients, more referrals)

**This is why MSPs are moving to Linux.** Not ideology, **economics**.

---

## The Migration Path

**You don't have to rip-and-replace existing infrastructure.**

### Phase 1: Deploy Alongside (30 Days)

**Month 1:**
- Deploy this infrastructure in parallel to existing Windows Server
- Migrate file shares (users access both during transition)
- Test authentication and file access
- Train a few pilot users

**Risk:** Low (old system still running)
**Client disruption:** Minimal

### Phase 2: Cut Over (Next 30 Days)

**Month 2:**
- Move user authentication to Samba AD DC
- Migrate remaining file shares
- Cut over DNS to new DCs
- Decommission Windows Server (or repurpose as backup)

**Risk:** Medium (managed with testing)
**Client disruption:** One weekend cutover

### Phase 3: Enhance (Ongoing)

**Months 3+:**
- Add monitoring and alerting
- Implement automated backups
- Deploy additional services as needed
- Document for client handoff

**For new clients:** Deploy directly, no migration needed.

---

## What You Get (The Actual Deliverables)

### 1. Complete Ansible Playbooks

```
smb-office-it-blueprint/
├── inventory/
│   ├── hosts.yml              # Your client inventory
│   └── group_vars/
│       └── all.yml            # Global settings (change these)
├── host_vars/
│   ├── dc01.yml               # Per-VM configuration
│   ├── dc02.yml
│   ├── file-server01.yml
│   └── ...                    # All 11 VMs defined
├── roles/                     # Reusable components
│   ├── samba_ad_dc/          # Domain controller setup
│   ├── file_server/          # Samba file shares
│   ├── network_config/       # Static IPs, VLANs
│   ├── ssh_hardening/        # Security policies
│   └── ...                   # 15+ tested roles
└── playbooks/
    ├── deploy-infrastructure.yml       # Main deployment
    ├── configure-ad.yml               # AD setup
    ├── configure-file-server.yml      # File shares
    └── ...                            # Task-specific playbooks
```

**Usage:**
```bash
# Customize for new client (5 minutes)
vim inventory/group_vars/all.yml

# Deploy (30 minutes runtime)
ansible-playbook playbooks/deploy-infrastructure.yml

# Configure AD (10 minutes)
ansible-playbook playbooks/configure-ad.yml

# Done. Invoice client.
```

### 2. Architecture Documentation

- Network diagrams (VLANs, firewall rules)
- Service dependency maps
- Disaster recovery procedures
- Security audit checklist
- Client handoff documentation

**These sell projects.** Show a prospective client the diagram, explain the security, they understand you're not just "some IT guy."

### 3. Runbooks for Common Scenarios

- "User can't log in" troubleshooting
- "File server is slow" diagnostics
- "DC crashed" recovery steps
- "Add a new user" procedures
- "Client needs new file share" process

**These save you time.** Your junior tech can follow these instead of calling you at 2am.

### 4. Security Hardening Configs

- SSH hardening (CVE-2024-6387 mitigation, key-only auth, network restrictions)
- UFW firewall rules (deny all, permit by exception)
- Samba security settings (SMB3 minimum, signing enforced)
- SELinux/AppArmor policies
- Fail2ban configurations

**These pass audits.** Client's cyber insurance audit? You're ready.

---

## The "This Sounds Too Good To Be True" Section

### Why Isn't Everyone Doing This?

**Three reasons:**

**1. Learning Curve (Perceived)**
- Sysadmins learn Windows Server in school/certs
- Samba AD DC has a reputation for being finicky (it was, 5 years ago)
- Ansible looks scary if you've never used it

**Reality:** Modern Samba AD DC is rock-solid. Ansible is easier than Group Policy + PowerShell DSC. This blueprint handles the complexity.

**2. "Nobody Got Fired For Buying Microsoft"**
- Safe bet for conservative IT managers
- Familiar vendor relationship
- Clear support path (expensive, but clear)

**Reality:** Your clients don't care about your vendor relationships. They care about value and uptime.

**3. First-Mover Disadvantage**
- You'd have to figure all this out yourself
- Trial and error with real client data (scary)
- No blueprint to follow (until now)

**Reality:** The blueprint exists. You're not the first mover anymore.

### What Can Go Wrong?

**Scenario 1: "Samba AD DC breaks in a weird way"**

**Mitigation:**
- Two DCs (one fails, other works)
- Automated backups (restore from last night)
- Infrastructure-as-Code (rebuild from playbooks)
- Community support (Samba mailing list, r/LinuxForBusiness)

**Reality:** Samba AD DC is mature software used by thousands of organizations. Edge cases are documented.

**Scenario 2: "Client needs something only Windows Server can do"**

**Mitigation:**
- Add a Windows Server VM to this infrastructure
- Most "Windows-only" apps run on Windows 10 Pro VM
- Evaluate if client actually needs that specific feature

**Reality:** 90% of SMB Windows Server use cases work fine with Samba. For the 10% that don't, you add a Windows VM.

**Scenario 3: "I can't support this long-term"**

**Mitigation:**
- Documentation included
- Runbooks for common tasks
- Infrastructure-as-Code means "rebuild if confused"
- Active community (r/LinuxForBusiness, mailing lists)

**Reality:** Supporting Linux servers is easier than Windows. Fewer updates, more stability, better logging.

---

## How to Get Started

### Step 1: Deploy in Your Own Lab (Weekend Project)

**Hardware needed:**
- Old desktop/workstation with 32GB RAM (or cloud VM)
- Proxmox installed
- Time: 8-12 hours to deploy and test

**Goal:** Understand how it works before deploying for clients

**Checklist:**
- [ ] Deploy all 11 VMs
- [ ] Configure Active Directory
- [ ] Join a Windows 10 VM to domain
- [ ] Test file shares
- [ ] Break something and restore it
- [ ] Document what you learned

### Step 2: Pick a Friendly Client (First Deployment)

**Ideal first client:**
- Small (10-25 users)
- Trusting relationship
- Simple requirements (file shares, users)
- Not mission-critical (or has good backup plan)

**Approach:**
> "I'd like to propose a new infrastructure design that will save you $8,000 over 3 years and give you better security. I'll do the first deployment at a reduced rate while I refine the process. Interested?"

**Expectation:** First client takes 2-3x longer than automated. Use this to refine your customizations.

### Step 3: Iterate and Templatize (Clients 2-5)

Each client, you'll:
- Refine your playbooks
- Add client-specific customizations to your template
- Document gotchas
- Build confidence

**By client #5:** You can quote 1-week deployments confidently.

### Step 4: Scale (Clients 6+)

**You now have:**
- Battle-tested playbooks
- Client deployment checklist
- Realistic time estimates
- Portfolio of successful deployments

**You can now:**
- Charge premium rates (you're efficient)
- Take on more clients (less time per deployment)
- Focus on value-add services (consulting, training)
- Build a real business (not just trading time for money)

---

## The Bottom Line

**This blueprint is not about technology. It's about business.**

**Time savings:**
- 40 hours → 10 hours per client deployment
- 30 hours saved × $100/hour = $3,000 more profit per client
- Or: Use that time to land 3 more clients per year

**Cost savings (for clients):**
- $13,000 saved on licensing per client (3-year TCO)
- Clients happy, more referrals

**Competitive advantage:**
- You can quote lower prices than Windows shops
- You deliver faster (1 week vs 1 month)
- You differentiate yourself (not just another Windows sysadmin)

**Scalability:**
- Infrastructure-as-Code means you can hire junior techs
- Playbooks document your process (not all in your head)
- You build a service offering, not a time-for-money trade

---

## Next Steps

### For Skeptics: Start Small

**Just deploy the DCs:**
- Takes 2 hours
- Costs $0 (licensing)
- Proves Samba AD DC works
- Join a Windows client to test

**If it works (it will):** Add file server.
**If that works (it will):** Deploy the full blueprint for next client.

### For Believers: Go All In

**Download the full blueprint:**
- Complete Ansible playbooks
- Network diagrams
- Documentation
- Runbooks

**Deploy in lab this weekend.**
**Land first client next month.**

### For MSPs: This is Your Differentiator

**Every MSP offers:**
- "Managed IT services"
- "24/7 support"
- "Cloud solutions"

**You can offer:**
- "Infrastructure deployment in 1 week, not 1 month"
- "50% lower licensing costs than our competitors"
- "Automated rebuilds (disaster recovery in hours, not days)"
- "Infrastructure-as-Code (we can recreate your entire environment from our Git repo)"

**That wins contracts.**

---

## Frequently Asked Questions

**Q: What if my client's industry requires Windows Server for compliance?**

**A:** Ask them to show you the specific requirement. Most compliance frameworks (HIPAA, PCI-DSS, SOC 2) are OS-agnostic. They care about controls (access logs, encryption, patching), not vendor. If they truly need Windows for a specific app, add a Windows VM to this infrastructure.

**Q: Can I charge the same rate even though it takes less time?**

**A:** **Yes.** You're charging for value delivered, not hours worked. If you can deliver a full infrastructure in 1 week that used to take 1 month, you're providing MORE value (faster time-to-production). Price based on value, not time.

**Q: What if I break something and the client's business goes down?**

**A:** That's why you:
1. Deploy in phases (parallel first, then cutover)
2. Test in dev-test01 before production
3. Have automated backups and disaster recovery
4. Keep the old Windows Server running during initial rollout

Same risk as any infrastructure change. Mitigate with testing and backups.

**Q: What's the catch?**

**A:** Learning curve (2-4 weeks to get comfortable). Client education ("Why isn't this Windows?"). Occasional edge case requiring Windows VM. That's it. The technology is proven, the savings are real, the automation works.

**Q: Where do I get support if something breaks?**

**A:**
- r/LinuxForBusiness (community of sysadmins doing this)
- Samba mailing lists (very active)
- Ubuntu/Rocky Linux forums
- This blueprint's documentation
- Your own runbooks (you build as you go)

Better question: Where do you get support for Windows Server that doesn't cost $5,000/year for a support contract?

---

## Conclusion: Stop Wasting Time on Repetitive Setup

You became a sysadmin to solve interesting problems, not to install the same domain controller for the 50th time.

**This blueprint gives you back your time.**

Use it to:
- Take on more clients
- Charge more for faster delivery
- Focus on valuable work (strategy, training, consulting)
- Build a real business instead of trading time for money

**The infrastructure design is here. The automation is written. The documentation exists.**

You just have to use it.

---

**Ready to stop rebuilding infrastructure from scratch?**

- 📥 **Download the complete blueprint:** [GitHub - smb-office-it-blueprint]
- 💬 **Join the community:** [r/LinuxForBusiness]
- 📧 **Questions?** Ask in the community

**Stop billing hourly. Start delivering value.**

---

*This article is part of the SMB Office IT Blueprint series. Next article: "Active Directory with Samba - Windows Server Compatibility Without Windows Server Licensing."*

---

**Document Version:** 2.0
**Last Updated:** 2026-01-04
**Author:** SMB Office IT Blueprint Project
**License:** CC BY-SA 4.0
