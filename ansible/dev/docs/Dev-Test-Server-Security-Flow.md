# Dev/Test Server Security Flow - SMB Office IT Blueprint

## Document Purpose
This document traces security flows through the development/test server in the SMB Office IT Blueprint. It demonstrates how isolated development environments, code deployment pipelines, and testing workflows work together while maintaining separation from production systems.

**Target Audience:** Security auditors, compliance officers, IT administrators creating test cases and validation playbooks.

---

## Infrastructure Context

### Dev/Test Server Role
- **Hostname:** `dev-test01`
- **OS:** Ubuntu 24.04 LTS (AppArmor enforcing)
- **VLAN:** 120 (Servers) - `10.0.120.70/24`
- **Purpose:** Isolated development and testing environment
- **Access:** IT Staff only (developers, sysadmins)
- **Services:** Docker, GitLab Runner, test databases, staging applications
- **Network Isolation:** Cannot directly access production data or systems
- **Data Classification:** Test data only (synthetic, anonymized, or public)

### Network Architecture
```
┌─────────────────────────────────────────────────────────────────┐
│                      pfSense Firewall                            │
│  VLAN 110 (Mgmt) │ VLAN 120 (Servers) │ VLAN 131 (Admin)       │
└─────────────────────────────────────────────────────────────────┘
         │                    │                     │
         │                    │                     │
    ┌────────────┐      ┌──────────────┐     ┌──────────┐
    │ansible-ctrl│      │dev-test01    │     │laptop-   │
    │10.0.120.50 │      │10.0.120.70   │     │dev-      │
    │(Config)    │      │Dev/Test      │     │alex-01   │
    └────────────┘      └──────────────┘     └──────────┘
                              │
                              │ (Isolated from production)
                              ├─ Docker containers (ephemeral)
                              ├─ GitLab Runner (CI/CD)
                              ├─ PostgreSQL (test database)
                              ├─ Test web applications
                              └─ Synthetic test data

         ✗ BLOCKED: dev-test01 → file-server01 (production data)
         ✗ BLOCKED: dev-test01 → domain controllers (production AD)
         ✓ ALLOWED: dev-test01 → Internet (package downloads)
         ✓ ALLOWED: IT Staff → dev-test01 (SSH, development access)
```

**Key Security Boundaries:**
1. **Production Isolation:** Dev/test CANNOT access production servers or data
2. **IT Staff Access:** Only IT-Staff AD group can SSH (developers + sysadmins)
3. **Ephemeral Containers:** Docker containers destroyed after each test run
4. **Test Data:** No production data (PII, financial, PHI) allowed on dev/test
5. **Internet Access:** Limited egress for package management (apt, pip, npm, Docker Hub)

---

## Security Requirements

| Requirement | Implementation | Verification |
|------------|---------------|--------------|
| **Production Isolation** | Firewall blocks dev-test → production servers | Test SSH from dev-test to file-server (should fail) |
| **No Production Data** | Synthetic data generation + anonymization scripts | Audit dev-test for PII (should find none) |
| **Authentication** | SSH with AD credentials (IT-Staff group) | Test SSH with non-IT user (should fail) |
| **Container Isolation** | Docker with AppArmor confinement + user namespaces | Test container breakout (should fail) |
| **CI/CD Pipeline** | GitLab Runner with isolated job execution | Test pipeline access to secrets (restricted) |
| **Audit Logging** | All development activity logged to monitoring01 | Verify all SSH sessions and deployments logged |
| **Ephemeral Workloads** | Containers destroyed after tests (no persistence) | Verify container cleanup after job completion |
| **Code Review** | All code changes require peer review before merge | Test direct push to main branch (should fail) |
| **Secret Management** | HashiCorp Vault for test credentials (not in code) | Test hardcoded secrets detection (should alert) |
| **Vulnerability Scanning** | Trivy scans all Docker images before deployment | Test deployment of vulnerable image (should block) |

---

## Development Workflow - Detailed Walkthrough

### Scenario 1: Developer Deploys Test Application via CI/CD Pipeline

**Context:**
- Developer: Alex (IT Staff, developer role)
- Task: Deploy new version of internal web app to dev-test01 for testing
- Repository: GitLab (self-hosted on dev-test01)
- Branch: feature/user-authentication
- CI/CD: GitLab Runner on dev-test01
- Date/Time: 2026-01-09 14:00:00

**Step-by-Step Security Flow:**

#### Step 1: Developer Pushes Code to GitLab
```bash
# On laptop-dev-alex-01 (10.0.131.25)
alex@laptop$ cd ~/projects/internal-webapp
alex@laptop$ git checkout -b feature/user-authentication
alex@laptop$ vim src/auth/login.py  # Make changes

alex@laptop$ git add src/auth/login.py
alex@laptop$ git commit -m "Add LDAP authentication for user login"
alex@laptop$ git push origin feature/user-authentication

# Git push over HTTPS with AD credentials
laptop-dev-alex-01 → dev-test01:443 (HTTPS)
  Authentication: Basic auth (alex@OFFICE.LOCAL + password)
  Certificate: TLS 1.3 with Let's Encrypt cert
```

**GitLab Authentication:**
```
GitLab (dev-test01) → dc01:389 (LDAP)
  Request: Verify alex@OFFICE.LOCAL credentials
  Response: User authenticated, groups: [IT-Staff, Developers]

GitLab authorization:
  alex is member of Developers group → ALLOW push to feature branches
  (Note: Push to main branch requires "Maintainer" role - Alex is "Developer")
```

**Timing:** 2 seconds (Git push + authentication)

#### Step 2: GitLab Triggers CI/CD Pipeline
```yaml
# .gitlab-ci.yml in repository root
stages:
  - build
  - test
  - security-scan
  - deploy-dev

variables:
  DOCKER_IMAGE: "internal-webapp:$CI_COMMIT_SHORT_SHA"

build:
  stage: build
  script:
    - docker build -t $DOCKER_IMAGE .
    - docker tag $DOCKER_IMAGE internal-webapp:latest
  only:
    - branches

test:
  stage: test
  script:
    - docker run --rm $DOCKER_IMAGE pytest /app/tests
  dependencies:
    - build

security-scan:
  stage: security-scan
  script:
    - trivy image --severity HIGH,CRITICAL --exit-code 1 $DOCKER_IMAGE
  allow_failure: false  # Block deployment if vulnerabilities found

deploy-dev:
  stage: deploy-dev
  script:
    - docker stop internal-webapp-dev || true
    - docker rm internal-webapp-dev || true
    - docker run -d --name internal-webapp-dev \
        --network dev-network \
        -p 8080:8080 \
        -e DATABASE_URL=$DEV_DATABASE_URL \
        $DOCKER_IMAGE
  environment:
    name: development
    url: http://dev-test01.office.local:8080
  only:
    - feature/*
    - develop
```

**GitLab Runner Execution:**
```
# On dev-test01 (GitLab Runner)
gitlab-runner[1234]: Job 42 started for project "internal-webapp"
  User: alex@OFFICE.LOCAL
  Branch: feature/user-authentication
  Commit: a1b2c3d4
  Pipeline: build → test → security-scan → deploy-dev
```

**Timing:** 0ms (immediate pipeline trigger)

#### Step 3: Build Stage - Docker Image Creation
```bash
# GitLab Runner executes build job
gitlab-runner → docker build -t internal-webapp:a1b2c3d4 .

# Dockerfile
FROM python:3.11-slim
WORKDIR /app
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt
COPY src/ /app/src/
USER nobody  # Non-root user in container
EXPOSE 8080
CMD ["python", "src/app.py"]
```

**Docker Image Layers:**
```
Step 1/7 : FROM python:3.11-slim
 ---> Pulling from library/python (Docker Hub)
Step 2/7 : WORKDIR /app
 ---> Running in container-123abc
Step 3/7 : COPY requirements.txt .
 ---> Running in container-456def
Step 4/7 : RUN pip install --no-cache-dir -r requirements.txt
 ---> Installing: flask, psycopg2, ldap3, prometheus-client
 ---> Running in container-789ghi
Step 5/7 : COPY src/ /app/src/
 ---> Running in container-012jkl
Step 6/7 : USER nobody
 ---> Running in container-345mno
Step 7/7 : CMD ["python", "src/app.py"]
 ---> Running in container-678pqr
Successfully built a1b2c3d4e5f6
Successfully tagged internal-webapp:a1b2c3d4
```

**AppArmor Confinement (Docker):**
```bash
# Check AppArmor profile for Docker containers
$ sudo aa-status | grep docker
  docker-default (enforce)

# Docker containers run with docker-default AppArmor profile
# Restricts: mount, pivot_root, ptrace, raw sockets, kernel module loading
```

**Timing:** 90 seconds (download base image + install dependencies)

#### Step 4: Test Stage - Run Unit Tests
```bash
# GitLab Runner executes test job
gitlab-runner → docker run --rm internal-webapp:a1b2c3d4 pytest /app/tests

# Inside ephemeral test container
container-test-789 $ pytest /app/tests
============================== test session starts ===============================
platform linux -- Python 3.11.7, pytest-7.4.3
collected 24 items

tests/test_auth.py::test_ldap_connection PASSED                           [  4%]
tests/test_auth.py::test_login_valid_user PASSED                          [  8%]
tests/test_auth.py::test_login_invalid_user PASSED                        [ 12%]
tests/test_api.py::test_get_users PASSED                                  [ 16%]
tests/test_api.py::test_create_user PASSED                                [ 20%]
... (20 more tests)
=============================== 24 passed in 2.34s ===============================

# Container automatically destroyed after test completion
docker ps -a | grep container-test-789
# (no results - ephemeral container removed)
```

**Test Database Connection:**
```
# Test container connects to PostgreSQL test database
container-test-789 (172.18.0.5) → dev-test01:5432 (PostgreSQL)
  Database: webapp_test
  User: test_user
  Password: (from $DEV_DATABASE_URL environment variable)

# Test database contains synthetic data only
SELECT COUNT(*) FROM users;
 count
-------
   100  (synthetic test users: test_user_001 through test_user_100)
```

**Timing:** 8 seconds (run 24 unit tests)

#### Step 5: Security Scan Stage - Trivy Vulnerability Scanning
```bash
# GitLab Runner executes security-scan job
gitlab-runner → trivy image --severity HIGH,CRITICAL --exit-code 1 internal-webapp:a1b2c3d4

# Trivy scans Docker image for vulnerabilities
2026-01-09T14:01:38.123Z	INFO	Vulnerability scanning is enabled
2026-01-09T14:01:38.456Z	INFO	Detected OS: debian
2026-01-09T14:01:38.789Z	INFO	Detecting Debian vulnerabilities...
2026-01-09T14:01:42.123Z	INFO	Number of language-specific files: 1
2026-01-09T14:01:42.456Z	INFO	Detecting python-pkg vulnerabilities...

internal-webapp:a1b2c3d4 (debian 12.4)
Total: 0 (HIGH: 0, CRITICAL: 0)

Python (python-pkg)
Total: 0 (HIGH: 0, CRITICAL: 0)

# Exit code 0 = No HIGH or CRITICAL vulnerabilities found
# Pipeline continues to deploy-dev stage
```

**Example: Vulnerable Image Blocked**
```bash
# If vulnerabilities were found:
trivy image --severity HIGH,CRITICAL --exit-code 1 internal-webapp:vulnerable

internal-webapp:vulnerable (debian 12.4)
Total: 3 (HIGH: 2, CRITICAL: 1)

┌─────────────────┬────────────────┬──────────┬───────────────────┬───────────────┐
│    Library      │ Vulnerability  │ Severity │ Installed Version │ Fixed Version │
├─────────────────┼────────────────┼──────────┼───────────────────┼───────────────┤
│ flask           │ CVE-2023-30861 │ HIGH     │ 2.0.1             │ 2.3.2         │
│ psycopg2-binary │ CVE-2024-12345 │ HIGH     │ 2.9.5             │ 2.9.9         │
│ openssl         │ CVE-2024-99999 │ CRITICAL │ 3.0.2             │ 3.0.13        │
└─────────────────┴────────────────┴──────────┴───────────────────┴───────────────┘

# Exit code 1 = Vulnerabilities found
# Pipeline FAILS, deploy-dev stage does NOT run
# Developer receives notification:
#   "Pipeline failed: HIGH/CRITICAL vulnerabilities detected. Update dependencies and retry."
```

**Timing:** 15 seconds (vulnerability scan + database lookup)

#### Step 6: Deploy-Dev Stage - Deploy to Development Environment
```bash
# GitLab Runner executes deploy-dev job
gitlab-runner → docker stop internal-webapp-dev
gitlab-runner → docker rm internal-webapp-dev

gitlab-runner → docker run -d --name internal-webapp-dev \
  --network dev-network \
  -p 8080:8080 \
  -e DATABASE_URL=postgresql://test_user:password@localhost:5432/webapp_dev \
  internal-webapp:a1b2c3d4

Container ID: 789xyz123abc (running)
```

**Docker Network Isolation:**
```bash
# dev-network is a bridge network (isolated from host)
$ docker network inspect dev-network
[
  {
    "Name": "dev-network",
    "Driver": "bridge",
    "IPAM": {
      "Config": [{"Subnet": "172.18.0.0/16", "Gateway": "172.18.0.1"}]
    },
    "Containers": {
      "789xyz123abc": {
        "Name": "internal-webapp-dev",
        "IPv4Address": "172.18.0.10/16"
      }
    }
  }
]

# Containers on dev-network can only communicate with each other
# NOT with production VLANs (10.0.120.0/24, 10.0.130.0/24)
```

**Container Security:**
```bash
# Container runs as non-root user (nobody)
$ docker exec internal-webapp-dev id
uid=65534(nobody) gid=65534(nogroup) groups=65534(nogroup)

# AppArmor profile enforced
$ docker inspect internal-webapp-dev | grep AppArmorProfile
"AppArmorProfile": "docker-default"

# User namespaces enabled (container UID 65534 maps to host UID 165534)
$ ps aux | grep "python src/app.py"
165534   12345  0.5  1.2  ... python src/app.py  # Host UID 165534 (not 65534)
```

**Timing:** 5 seconds (stop old container + start new container)

#### Step 7: Deployment Completion and Notification
```
# GitLab pipeline status: SUCCESS
Pipeline #42 for internal-webapp (feature/user-authentication) passed

Stages:
  ✓ build: 1m 30s
  ✓ test: 8s
  ✓ security-scan: 15s
  ✓ deploy-dev: 5s

Total duration: 1m 58s

Deployed to: http://dev-test01.office.local:8080
Environment: development
Commit: a1b2c3d4 (Add LDAP authentication for user login)
Deployed by: alex@OFFICE.LOCAL
```

**Auditd Log (dev-test01):**
```
type=CICD_DEPLOYMENT msg=audit(1736436118.456:7890):
  user="alex@OFFICE.LOCAL" pipeline_id=42 project="internal-webapp"
  branch="feature/user-authentication" commit="a1b2c3d4"
  image="internal-webapp:a1b2c3d4" environment="development"
  duration=118s result=success key="cicd_deployment"

type=CONTAINER_START msg=audit(1736436118.789:7891):
  container_id="789xyz123abc" image="internal-webapp:a1b2c3d4"
  ports="8080:8080" user="nobody" network="dev-network"
  key="container_lifecycle"
```

**Rsyslog Forward to monitoring01:**
```
Jan 09 14:01:58 dev-test01 gitlab-runner[1234]:
  Pipeline 42 completed successfully
    User: alex@OFFICE.LOCAL
    Project: internal-webapp
    Commit: a1b2c3d4
    Duration: 1m 58s

→ rsyslog (TCP/TLS) → monitoring01:514
→ Elasticsearch indexes
→ Wazuh SIEM: Development deployment logged (no alert, informational)
```

**Total Time:** ~2 minutes (build 90s + test 8s + scan 15s + deploy 5s)

---

### Scenario 2: Developer Attempts to Access Production Data (Blocked)

**Context:**
- Developer: Alex needs production data to debug an issue
- Attempts to SSH from dev-test01 to file-server01 (production)
- Expected result: BLOCKED by firewall (production isolation)

**Step-by-Step Flow:**

#### Step 1: Developer SSH to Dev/Test Server
```bash
# On laptop-dev-alex-01
alex@laptop$ ssh alex@dev-test01.office.local

# Kerberos authentication (same as other servers)
# AD group check: alex is member of IT-Staff → ALLOW SSH
```

#### Step 2: Attempt to Access Production File Server
```bash
# On dev-test01
alex@dev-test01$ ssh file-server01.office.local
ssh: connect to host file-server01.office.local port 22: Connection refused

alex@dev-test01$ smbclient //file-server01/finance -U alex@OFFICE.LOCAL
Connection to file-server01 failed (Error NT_STATUS_HOST_UNREACHABLE)
```

**Firewall Block (pfSense):**
```
Rule: block-dev-test-to-production
  Source: 10.0.120.70 (dev-test01)
  Destination: 10.0.120.20 (file-server01)
  Port: any
  Action: BLOCK

Log: Jan 09 14:10:00 pfsense filterlog: BLOCK,120,10.0.120.70,10.0.120.20,tcp,22
     Reason: dev-test-production-isolation
```

**Result:** Connection blocked at network layer (firewall)

#### Step 3: Alert Generated for Suspicious Access Attempt
```
# Wazuh SIEM on monitoring01 detects production access attempt from dev-test
Rule 100240: Development server attempting to access production system
  Severity: Medium
  Source: dev-test01 (10.0.120.70)
  Target: file-server01 (10.0.120.20)
  User: alex@OFFICE.LOCAL
  Action: Log for investigation + notify IT Manager

# Alert sent to sarah@office.local:
Subject: Security Alert - Dev/Test to Production Access Attempt
Body:
  User alex@OFFICE.LOCAL attempted to access production server file-server01
  from dev-test01 at 2026-01-09 14:10:00.

  This is blocked by firewall policy (dev/test isolation).

  If this was legitimate, please contact IT Security to request a one-time
  exception with business justification and approval from Data Owner.
```

**Timing:** <1 second (firewall block) + 30 seconds (alert generation)

#### Step 4: Correct Procedure - Request Anonymized Production Data
```bash
# Correct workflow for accessing production data:
# 1. Alex creates ticket: IT-2026-0025
#    "Need production data to debug authentication issue"
#
# 2. IT Manager approves: "Approved for anonymized data export"
#
# 3. IT Admin runs anonymization script on ansible-ctrl:
alex@ansible-ctrl$ ansible-playbook playbooks/export-anonymized-data.yml \
  --extra-vars "source=file-server01 destination=dev-test01 ticket=IT-2026-0025"

# Anonymization process:
# - Extract subset of production data (last 30 days)
# - Replace all PII with synthetic data:
#   * Names: John Smith → Test User 001
#   * Emails: john@office.local → testuser001@example.com
#   * SSN: 123-45-6789 → 000-00-0001
#   * Dates: Actual dates → Shifted dates (preserve relative timing)
# - Load anonymized data into dev-test01 PostgreSQL
# - Audit log: All anonymization steps + approvals

# 4. Alex can now debug with anonymized data on dev-test01
alex@dev-test01$ psql -d webapp_dev -c "SELECT * FROM users LIMIT 10;"
 id |    name       |          email
----+---------------+-------------------------
  1 | Test User 001 | testuser001@example.com
  2 | Test User 002 | testuser002@example.com
... (anonymized data)
```

**Auditd Log (anonymization):**
```
type=DATA_ANONYMIZATION msg=audit(1736436900.123:7900):
  user="alex@OFFICE.LOCAL" approval="sarah@OFFICE.LOCAL"
  source="file-server01" destination="dev-test01"
  records_anonymized=10000 pii_fields_replaced=35000
  ticket="IT-2026-0025" result=success key="data_anonymization"
```

---

### Scenario 3: Container Breakout Attempt (Blocked by AppArmor)

**Context:**
- Malicious code injected into Docker container (supply chain attack scenario)
- Container attempts to escape and access host system
- Expected result: BLOCKED by AppArmor + user namespaces

**Step-by-Step Flow:**

#### Step 1: Malicious Container Started
```bash
# Assume attacker compromised base Docker image (supply chain attack)
# Malicious code attempts to break out of container

# Inside container (malicious process)
container$ whoami
nobody  # UID 65534 inside container

container$ cat /etc/shadow
cat: /etc/shadow: Permission denied  # Cannot read shadow file

container$ mount /dev/sda1 /mnt
mount: /mnt: permission denied  # Mount blocked by AppArmor
```

**AppArmor Denial:**
```
# On dev-test01 host
$ sudo dmesg | grep apparmor | tail -5
[12345.678] audit: type=1400 audit(1736437200.123:7901): apparmor="DENIED"
  operation="mount" profile="docker-default" name="/mnt/" pid=12345
  comm="mount" requested_mask="w" denied_mask="w" fsuid=165534 ouid=0

# AppArmor policy blocks mount operation
# Even though container runs as UID 65534 (nobody), AppArmor restricts capabilities
```

**Timing:** <1ms (instant denial)

#### Step 2: Attempt to Access Host Filesystem
```bash
# Malicious container tries to access host files via volume mount
container$ ls /var/run/docker.sock
ls: cannot access '/var/run/docker.sock': No such file or directory

# Docker socket NOT mounted in container (intentional security decision)
# Cannot access Docker daemon from inside container
```

**User Namespace Protection:**
```bash
# Container runs with user namespaces enabled
# UID 65534 inside container maps to UID 165534 on host

# On host:
$ ps aux | grep "malicious-process"
165534   12345  ... malicious-process  # Host UID 165534 (unprivileged)

# UID 165534 has NO special privileges on host
# Cannot access /root, /etc/shadow, or other sensitive files
```

#### Step 3: Attempt Privilege Escalation
```bash
# Malicious container attempts setuid exploit
container$ cp /bin/bash /tmp/bash
container$ chmod 4755 /tmp/bash  # Attempt to set setuid bit
chmod: changing permissions of '/tmp/bash': Operation not permitted

# setuid blocked by nosuid mount option on /tmp inside container
```

**Docker Security Options:**
```bash
# Check container security configuration
$ docker inspect internal-webapp-dev | jq '.[0].HostConfig.SecurityOpt'
[
  "apparmor=docker-default",
  "no-new-privileges=true",  # Prevents privilege escalation
  "seccomp=default"  # Syscall filtering
]

# no-new-privileges=true prevents setuid/setgid from working
```

#### Step 4: Alert and Container Termination
```
# AppArmor denial logged to kernel
# rsyslog forwards to monitoring01

# Wazuh SIEM detects suspicious container activity
Rule 100241: Container attempting privilege escalation or breakout
  Severity: Critical
  Container: internal-webapp-dev (789xyz123abc)
  User: alex@OFFICE.LOCAL (container owner)
  Violations:
    - Mount operation denied by AppArmor (3 attempts)
    - Setuid operation denied (2 attempts)
  Action: Terminate container + alert security team + forensic analysis

# Automated response:
1. Kill container: docker kill internal-webapp-dev
2. Save container forensics: docker commit internal-webapp-dev forensic-image-001
3. Block image: docker tag internal-webapp:a1b2c3d4 QUARANTINE
4. Alert security team + IT Manager
5. Initiate incident response procedure
```

**Auditd Log:**
```
type=CONTAINER_BREACH_ATTEMPT msg=audit(1736437200.456:7902):
  container_id="789xyz123abc" image="internal-webapp:a1b2c3d4"
  user="alex@OFFICE.LOCAL" violations_detected=5
  apparmor_denials=3 setuid_attempts=2
  action="container_terminated" forensic_image="forensic-image-001"
  result=blocked key="container_security_violation"
```

**Total Time:** <5 seconds (detection to container termination)

---

## Firewall Configuration

### Dev/Test Server Inbound Rules
```bash
# Zone: server (VLAN 120)

# SSH from Admin VLAN only (IT Staff workstations)
firewall-cmd --permanent --zone=server --add-rich-rule='
  rule family="ipv4"
  source address="10.0.131.0/24"
  service name="ssh"
  accept'

# HTTP/HTTPS for GitLab (development access)
firewall-cmd --permanent --zone=server --add-rich-rule='
  rule family="ipv4"
  source address="10.0.131.0/24"
  port protocol="tcp" port="80"
  accept'

firewall-cmd --permanent --zone=server --add-rich-rule='
  rule family="ipv4"
  source address="10.0.131.0/24"
  port protocol="tcp" port="443"
  accept'

# Development application port (8080)
firewall-cmd --permanent --zone=server --add-rich-rule='
  rule family="ipv4"
  source address="10.0.131.0/24"
  port protocol="tcp" port="8080"
  accept'

# SSH from ansible-ctrl (automation)
firewall-cmd --permanent --zone=server --add-rich-rule='
  rule family="ipv4"
  source address="10.0.120.50/32"
  service name="ssh"
  accept'

# Default deny
firewall-cmd --permanent --zone=server --set-target=DROP

firewall-cmd --reload
```

### Dev/Test Server Outbound Rules
```bash
# Allow Internet access (package downloads)
firewall-cmd --permanent --direct --add-rule ipv4 filter OUTPUT 0 \
  -p tcp --dport 80 -j ACCEPT   # HTTP (apt, yum)
firewall-cmd --permanent --direct --add-rule ipv4 filter OUTPUT 0 \
  -p tcp --dport 443 -j ACCEPT  # HTTPS (pip, npm, Docker Hub)

# Allow DNS
firewall-cmd --permanent --direct --add-rule ipv4 filter OUTPUT 0 \
  -p udp --dport 53 -j ACCEPT

# Allow rsyslog to monitoring server
firewall-cmd --permanent --direct --add-rule ipv4 filter OUTPUT 0 \
  -d 10.0.120.40 -p tcp --dport 514 -j ACCEPT

# BLOCK all access to production servers
firewall-cmd --permanent --direct --add-rule ipv4 filter OUTPUT 1 \
  -d 10.0.120.10 -j DROP  # dc01 (production AD)
firewall-cmd --permanent --direct --add-rule ipv4 filter OUTPUT 1 \
  -d 10.0.120.11 -j DROP  # dc02 (production AD)
firewall-cmd --permanent --direct --add-rule ipv4 filter OUTPUT 1 \
  -d 10.0.120.20 -j DROP  # file-server01 (production data)
firewall-cmd --permanent --direct --add-rule ipv4 filter OUTPUT 1 \
  -d 10.0.120.30 -j DROP  # print-server01
firewall-cmd --permanent --direct --add-rule ipv4 filter OUTPUT 1 \
  -d 10.0.120.60 -j DROP  # backup-server

# BLOCK workstation VLANs (no lateral movement)
firewall-cmd --permanent --direct --add-rule ipv4 filter OUTPUT 1 \
  -d 10.0.130.0/24 -j DROP  # Workstation VLAN

# Default allow (Internet, monitoring)
firewall-cmd --permanent --direct --add-rule ipv4 filter OUTPUT 2 -j ACCEPT
```

**Key Point:** Dev/test can access Internet (package management) but NOT production servers or workstations.

---

## AppArmor Configuration

### Docker AppArmor Profile (/etc/apparmor.d/docker-default)
```
#include <tunables/global>

profile docker-default flags=(attach_disconnected,mediate_deleted) {
  #include <abstractions/base>

  # Network access
  network inet tcp,
  network inet udp,
  network inet icmp,

  # Allow reading most files (containers need to read application code)
  capability dac_override,
  capability dac_read_search,
  file,

  # Deny dangerous operations
  deny @{PROC}/* w,   # Deny write to /proc
  deny /sys/[^f]*/** w,  # Deny write to /sys
  deny /sys/f[^s]*/** w,  # Deny write to /sys
  deny /sys/fs/[^c]*/** w,  # Deny write to /sys/fs
  deny /sys/fs/c[^g]*/** w,  # Deny write to /sys/fs
  deny /sys/kernel/security/** w,  # Deny write to security

  # Deny mount operations
  deny mount,
  deny remount,
  deny pivot_root,

  # Deny raw sockets (prevent packet sniffing)
  deny network raw,

  # Deny ptrace (cannot attach to other processes)
  deny ptrace,

  # Deny loading kernel modules
  deny capability sys_module,

  # Deny changing AppArmor profiles
  deny @{PROC}/[0-9]*/attr/current w,
  deny /sys/kernel/security/apparmor/.* w,
}
```

**Key Restrictions:**
1. **No mount:** Cannot mount filesystems (prevents breakout via mount)
2. **No raw sockets:** Cannot sniff network traffic
3. **No ptrace:** Cannot attach debugger to host processes
4. **No kernel modules:** Cannot load malicious kernel modules
5. **No /proc write:** Cannot manipulate process information

---

## Auditd Rules

### Development Activity Auditing
```bash
# /etc/audit/rules.d/dev-test.rules

# Watch Docker operations
-w /usr/bin/docker -p x -k docker_exec
-w /var/lib/docker/ -p wa -k docker_data

# Watch GitLab Runner
-w /usr/bin/gitlab-runner -p x -k gitlab_runner

# Watch CI/CD deployments
-a always,exit -F arch=b64 -S execve -F exe=/usr/bin/gitlab-runner -k cicd_pipeline

# Watch container lifecycle
-a always,exit -F arch=b64 -S clone -k container_create
-a always,exit -F arch=b64 -S execve -F comm=dockerd -k container_lifecycle

# Watch AppArmor denials (container breakout attempts)
-w /var/log/kern.log -p wa -k apparmor_denials

# Watch test database access
-w /var/lib/postgresql/ -p wa -k test_database

# Watch code deployment
-w /opt/applications/ -p wa -k code_deployment

# Watch secret access (HashiCorp Vault)
-w /usr/bin/vault -p x -k vault_access

# Audit all SSH access (developers)
-a always,exit -F arch=b64 -S execve -F exe=/usr/sbin/sshd -k ssh_access
```

### Example Audit Log Output
```
# CI/CD pipeline execution
type=CICD_DEPLOYMENT msg=audit(1736436118.456:7890):
  user="alex@OFFICE.LOCAL" pipeline_id=42 project="internal-webapp"
  branch="feature/user-authentication" commit="a1b2c3d4"
  image="internal-webapp:a1b2c3d4" environment="development"
  duration=118s result=success key="cicd_deployment"

# Container started
type=CONTAINER_START msg=audit(1736436118.789:7891):
  container_id="789xyz123abc" image="internal-webapp:a1b2c3d4"
  ports="8080:8080" user="nobody" network="dev-network"
  key="container_lifecycle"

# AppArmor denial (container breakout attempt)
type=AVC msg=audit(1736437200.123:7901): apparmor="DENIED"
  operation="mount" profile="docker-default" name="/mnt/" pid=12345
  comm="mount" requested_mask="w" denied_mask="w" fsuid=165534 ouid=0
  key="apparmor_denials"
```

---

## GitLab Configuration

### GitLab Runner Configuration (/etc/gitlab-runner/config.toml)
```toml
concurrent = 4
check_interval = 0

[session_server]
  session_timeout = 1800

[[runners]]
  name = "dev-test01-docker-runner"
  url = "https://dev-test01.office.local/"
  token = "{{ gitlab_runner_token }}"  # From Ansible Vault
  executor = "docker"

  [runners.custom_build_dir]
  [runners.cache]
    [runners.cache.s3]
    [runners.cache.gcs]
    [runners.cache.azure]

  [runners.docker]
    tls_verify = false
    image = "ubuntu:22.04"
    privileged = false  # CRITICAL: No privileged containers
    disable_entrypoint_overwrite = false
    oom_kill_disable = false
    disable_cache = false
    volumes = ["/cache"]
    shm_size = 0
    network_mode = "dev-network"  # Isolated Docker network

    # Security options
    security_opt = [
      "apparmor=docker-default",
      "no-new-privileges=true",
      "seccomp=default"
    ]

    # User namespaces (map container UID to unprivileged host UID)
    userns_mode = "host"

    # Resource limits (prevent DoS)
    cpus = "2"
    memory = "4g"
    memory_swap = "4g"

    # Allowed images (prevent malicious base images)
    allowed_images = [
      "ubuntu:*",
      "python:*",
      "node:*",
      "internal-webapp:*"
    ]
```

**Key Security Settings:**
1. **privileged = false:** Containers run without host privileges
2. **no-new-privileges=true:** Prevents privilege escalation inside container
3. **apparmor=docker-default:** Enforces AppArmor confinement
4. **seccomp=default:** Syscall filtering (blocks dangerous syscalls)
5. **userns_mode = "host":** User namespace mapping for additional isolation
6. **Resource limits:** Prevents DoS attacks (CPU/memory exhaustion)

---

## HashiCorp Vault Integration

### Vault Configuration (Test Secrets)
```bash
# Vault runs on dev-test01 (dev mode, not for production)
vault server -dev -dev-root-token-id="dev-only-token"

# Store test database credentials
vault kv put secret/dev/database \
  username=test_user \
  password=test_password_not_production \
  host=localhost \
  port=5432 \
  database=webapp_dev

# Store test API keys
vault kv put secret/dev/api \
  github_token=ghp_test_token_not_real \
  slack_webhook=https://hooks.slack.com/services/TEST/WEBHOOK

# CI/CD pipeline retrieves secrets from Vault
# .gitlab-ci.yml:
deploy-dev:
  script:
    - export VAULT_ADDR="http://localhost:8200"
    - export VAULT_TOKEN="dev-only-token"
    - DATABASE_URL=$(vault kv get -field=connection_string secret/dev/database)
    - docker run -e DATABASE_URL=$DATABASE_URL internal-webapp:latest
```

**Key Point:** Secrets stored in Vault, NOT hardcoded in code or .gitlab-ci.yml

---

## Test Cases for Validation

### Test 1: Successful CI/CD Deployment
```bash
# Preconditions:
# - Alex pushes code to feature branch
# - Pipeline configured (.gitlab-ci.yml)
# - No vulnerabilities in Docker image

# Test:
alex@laptop$ git push origin feature/user-authentication

# Expected:
# ✓ Pipeline triggered automatically
# ✓ Build stage: Docker image created
# ✓ Test stage: 24 unit tests pass
# ✓ Security-scan stage: No vulnerabilities found
# ✓ Deploy-dev stage: Container deployed to dev-test01
# ✓ Application accessible at http://dev-test01:8080

# Validation:
# On dev-test01:
$ docker ps | grep internal-webapp-dev
789xyz123abc   internal-webapp:a1b2c3d4   "python src/app.py"   ...   Up 2 minutes

$ curl http://localhost:8080/health
{"status": "healthy", "version": "a1b2c3d4"}
```

### Test 2: Vulnerable Image Deployment Blocked
```bash
# Preconditions:
# - Base image has CRITICAL vulnerability (e.g., CVE-2024-99999 in OpenSSL)
# - Trivy security scan configured in pipeline

# Test:
alex@laptop$ vim Dockerfile
# Change: FROM python:3.11-slim
# To:     FROM python:3.9-slim  # Vulnerable version

alex@laptop$ git commit -m "Update base image"
alex@laptop$ git push origin feature/test-vulnerability

# Expected:
# ✓ Build stage: Docker image created
# ✓ Test stage: Tests pass
# ✗ Security-scan stage: CRITICAL vulnerability detected (CVE-2024-99999)
# ✗ Deploy-dev stage: SKIPPED (pipeline failed)
# ✓ Developer notified: "Pipeline failed: CRITICAL vulnerabilities detected"

# Validation:
# GitLab Pipeline UI shows:
Stage: security-scan
Job: security-scan
Status: Failed
Exit Code: 1
Error: "Found 1 CRITICAL vulnerability. Deployment blocked."
```

### Test 3: Production Access Attempt Blocked
```bash
# Preconditions:
# - Alex has SSH access to dev-test01
# - Production servers are firewalled from dev-test01

# Test:
alex@dev-test01$ ssh file-server01.office.local
ssh: connect to host file-server01.office.local port 22: Connection refused

alex@dev-test01$ smbclient //file-server01/finance -U alex
Connection to file-server01 failed (Error NT_STATUS_HOST_UNREACHABLE)

# Expected:
# ✗ Connection blocked by pfSense firewall
# ✓ Alert generated (Rule 100240: Dev/test to production access attempt)
# ✓ IT Manager notified

# Validation:
# On monitoring01 (Wazuh SIEM):
Rule 100240: Development server attempting to access production system
  Severity: Medium
  Source: dev-test01 (10.0.120.70)
  Target: file-server01 (10.0.120.20)
  User: alex@OFFICE.LOCAL
  Time: 2026-01-09 14:10:00
```

### Test 4: Container Breakout Attempt Blocked
```bash
# Preconditions:
# - Malicious Docker image with breakout exploit
# - AppArmor enabled on dev-test01

# Test (inside container):
container$ mount /dev/sda1 /mnt
mount: /mnt: permission denied

container$ cat /etc/shadow
cat: /etc/shadow: Permission denied

container$ chmod 4755 /tmp/bash
chmod: changing permissions of '/tmp/bash': Operation not permitted

# Expected:
# ✗ All privileged operations DENIED by AppArmor
# ✓ AppArmor denials logged
# ✓ Alert generated (Rule 100241: Container breakout attempt)
# ✓ Container terminated automatically

# Validation:
# On dev-test01:
$ sudo dmesg | grep apparmor | tail -3
[12345.678] audit: apparmor="DENIED" operation="mount" profile="docker-default"
[12346.789] audit: apparmor="DENIED" operation="open" profile="docker-default" name="/etc/shadow"
[12347.890] audit: apparmor="DENIED" operation="chmod" profile="docker-default" name="/tmp/bash"

# On monitoring01 (Wazuh SIEM):
Rule 100241: Container attempting privilege escalation or breakout
  Severity: Critical
  Container: internal-webapp-dev
  Violations: 3 AppArmor denials
  Action: Container terminated
```

### Test 5: Hardcoded Secrets Detection
```bash
# Preconditions:
# - git-secrets or similar tool configured as pre-commit hook
# - Developer accidentally commits AWS credentials

# Test:
alex@laptop$ vim config.py
# Add: AWS_SECRET_KEY = "AKIAIOSFODNN7EXAMPLE"

alex@laptop$ git add config.py
alex@laptop$ git commit -m "Add AWS config"

# Pre-commit hook runs git-secrets scan:
[ERROR] Prohibited pattern found:
  File: config.py
  Line 12: AWS_SECRET_KEY = "AKIAIOSFODNN7EXAMPLE"
  Pattern: AWS Secret Access Key detected

# Expected:
# ✗ Commit BLOCKED by pre-commit hook
# ✓ Developer warned about hardcoded secret
# ✓ Developer must use Vault instead

# Correct approach:
alex@laptop$ vim config.py
# Change to: AWS_SECRET_KEY = os.getenv("AWS_SECRET_KEY")  # From Vault

alex@laptop$ git commit -m "Use Vault for AWS credentials"
[feature/aws-integration 1234567] Use Vault for AWS credentials
 1 file changed, 1 insertion(+), 1 deletion(-)
```

### Test 6: Ephemeral Container Cleanup
```bash
# Preconditions:
# - CI/CD pipeline completes (success or failure)
# - Test containers should be automatically removed

# Test:
alex@laptop$ git push origin feature/test
# Pipeline runs, creates test containers

# During pipeline:
alex@dev-test01$ docker ps
CONTAINER ID   IMAGE                  STATUS
abc123def456   internal-webapp:test   Up 5 seconds

# After pipeline completion:
alex@dev-test01$ docker ps
CONTAINER ID   IMAGE   STATUS
# (no test containers - only persistent dev container)

alex@dev-test01$ docker ps -a | grep test
# (no results - ephemeral containers removed)

# Expected:
# ✓ Test containers automatically removed after job completion
# ✓ Only persistent dev containers remain
# ✓ No disk space wasted on old containers

# Validation:
$ docker system df
TYPE            TOTAL     ACTIVE    SIZE      RECLAIMABLE
Images          10        3         5.2GB     2.1GB (40%)
Containers      3         3         1.2MB     0B (0%)
Local Volumes   5         2         850MB     150MB (17%)

# Only 3 active containers (persistent dev environments)
```

---

## Compliance Benefits

### NIST 800-53 (Federal Information Security Management Act)
**Requirement:** CM-4 (Security Impact Analysis), SA-11 (Developer Security Testing)

**Implementation:**
- **CM-4:** All code changes go through CI/CD pipeline with security scans (Trivy)
- **SA-11:** Automated security testing in pipeline (unit tests, vulnerability scans)
- **SC-7:** Production isolation (firewall blocks dev/test → production)
- **AC-6:** Least privilege (containers run as nobody, AppArmor confinement)

**Compliance Evidence:**
- GitLab pipeline logs showing security scans for all deployments
- Firewall logs showing blocked dev/test → production connections
- AppArmor logs showing container confinement enforcement

---

### OWASP ASVS (Application Security Verification Standard)
**Requirement:** V14 (Configuration), V19 (Logging)

**Implementation:**
- **V14.2.6:** No hardcoded secrets (Vault integration, git-secrets pre-commit hook)
- **V14.4.4:** Container security (AppArmor, no-new-privileges, seccomp)
- **V19.2.1:** Comprehensive logging (all CI/CD deployments, container lifecycle)
- **V19.3.4:** Automated alerting (Wazuh SIEM for security violations)

**Compliance Evidence:**
- git-secrets blocks commits with hardcoded credentials
- Docker security options enforced (AppArmor, seccomp, no-new-privileges)
- All deployments logged to monitoring01 with full audit trail

---

### SOC 2 (Service Organization Control 2)
**Requirement:** CC6.6 (Logical and Physical Access Controls), CC7.2 (System Monitoring)

**Implementation:**
- **CC6.6:** Production isolation (dev/test cannot access production systems or data)
- **CC7.2:** Comprehensive monitoring (Wazuh SIEM alerts on suspicious activity)
- **CC8.1:** Change management (Git-based workflow, peer review for all code changes)

**Compliance Evidence:**
- Firewall configuration showing dev/test isolation
- Wazuh SIEM rules for unauthorized access attempts
- GitLab merge request history showing peer review for all changes

---

## Wazuh SIEM Rules for Dev/Test Security

### Rule 1: Dev/Test to Production Access Attempt
```xml
<!-- /var/ossec/etc/rules/local_rules.xml on monitoring01 -->
<group name="dev-test,production-isolation,">
  <rule id="100240" level="8">
    <if_sid>0</if_sid>
    <match>BLOCK.*10.0.120.70</match>  <!-- Source: dev-test01 -->
    <match>10.0.120.20|10.0.120.10|10.0.120.11</match>  <!-- Dest: production servers -->
    <description>Development server attempting to access production system</description>
    <mitre>
      <id>T1021</id>  <!-- Remote Services -->
    </mitre>
  </rule>
</group>
```

**Trigger:** Any connection attempt from dev-test01 to production servers
**Action:** Alert IT Manager + log for investigation

---

### Rule 2: Container Breakout Attempt
```xml
<rule id="100241" level="15">
  <if_sid>0</if_sid>
  <match>apparmor="DENIED"</match>
  <match>operation="mount"|operation="chmod"</match>
  <match>profile="docker-default"</match>
  <frequency>3</frequency>
  <timeframe>60</timeframe>
  <description>Container attempting privilege escalation or breakout</description>
  <mitre>
    <id>T1611</id>  <!-- Escape to Host -->
  </mitre>
</rule>
```

**Trigger:** 3+ AppArmor denials from same container in 60 seconds
**Action:** Critical alert + terminate container + forensic analysis

---

### Rule 3: Vulnerable Image Deployed
```xml
<rule id="100242" level="12">
  <if_sid>0</if_sid>
  <match>trivy.*CRITICAL</match>
  <description>Docker image with CRITICAL vulnerabilities deployed (pipeline failure expected)</description>
  <mitre>
    <id>T1525</id>  <!-- Implant Internal Image -->
  </mitre>
</rule>
```

**Trigger:** Trivy scan detects CRITICAL vulnerabilities
**Action:** Block deployment + alert developer + require fix before merge

---

### Rule 4: Hardcoded Secret Committed
```xml
<rule id="100243" level="13">
  <if_sid>0</if_sid>
  <match>git-secrets.*Prohibited pattern</match>
  <description>Hardcoded secret detected in code commit (blocked by pre-commit hook)</description>
  <mitre>
    <id>T1552.001</id>  <!-- Unsecured Credentials: Credentials In Files -->
  </mitre>
</rule>
```

**Trigger:** git-secrets detects hardcoded credential in commit
**Action:** Block commit + alert developer + security awareness training

---

### Rule 5: Production Data on Dev/Test Server
```xml
<rule id="100244" level="14">
  <if_sid>0</if_sid>
  <match>/dev-test01/</match>
  <match>PII_DETECTED|SSN_DETECTED|CREDIT_CARD_DETECTED</match>
  <description>Production data (PII) detected on dev/test server (policy violation)</description>
  <mitre>
    <id>T1005</id>  <!-- Data from Local System -->
  </mitre>
</rule>
```

**Trigger:** PII scanning tool detects production data on dev-test01
**Action:** Critical alert + immediate data removal + investigate how data arrived

---

## Summary

This document demonstrates comprehensive dev/test security with:

1. **Production Isolation:**
   - Firewall blocks dev/test → production servers (file-server, DC, etc.)
   - No production data allowed on dev/test (synthetic/anonymized only)
   - Network segmentation (dev/test cannot reach workstation VLAN)

2. **Container Security:**
   - AppArmor confinement (blocks mount, ptrace, raw sockets)
   - User namespaces (UID mapping for additional isolation)
   - no-new-privileges (prevents setuid privilege escalation)
   - seccomp filtering (blocks dangerous syscalls)
   - Resource limits (prevents DoS via CPU/memory exhaustion)

3. **CI/CD Security:**
   - Automated vulnerability scanning (Trivy blocks HIGH/CRITICAL vulns)
   - Secret management (HashiCorp Vault, no hardcoded credentials)
   - Pre-commit hooks (git-secrets blocks hardcoded secrets)
   - Peer review required (no direct push to main branch)
   - Ephemeral workloads (containers destroyed after tests)

4. **Access Control:**
   - SSH restricted to IT-Staff AD group
   - JIT elevation for sensitive operations (not implemented in dev/test, but documented)
   - Development environments isolated per developer (no shared containers)

5. **Compliance:**
   - NIST 800-53: Security impact analysis (CM-4), developer testing (SA-11)
   - OWASP ASVS: No hardcoded secrets (V14.2.6), container security (V14.4.4)
   - SOC 2: Production isolation (CC6.6), change management (CC8.1)

6. **Threat Detection:**
   - Wazuh SIEM rules for production access attempts
   - Container breakout detection (AppArmor denials)
   - Vulnerable image deployment blocked
   - Hardcoded secret detection (pre-commit)

**Total Security Layers for Dev/Test Workloads:** 6
1. pfSense firewall (production isolation)
2. firewalld (host-based firewall)
3. AppArmor (container confinement)
4. User namespaces (UID mapping)
5. seccomp (syscall filtering)
6. CI/CD security scanning (Trivy vulnerability scans)

**Key Insight:** The dev/test server is intentionally isolated from production to prevent accidental or malicious access to sensitive data. Even if a developer's workstation or the dev/test server itself is compromised, the firewall prevents lateral movement to production systems. This "assume breach" approach ensures that a compromise in the development environment does not lead to a production data breach.

---

**Document Version:** 1.0
**Last Updated:** 2026-01-10
**Author:** IT Security Team
**Next Review:** 2026-07-10 (6 months)
