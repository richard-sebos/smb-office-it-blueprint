# Playbook Archive Information

## Archive Directory

Old/replaced playbook files have been moved to: `playbooks/archive/`

## What's Archived

### Replaced Files

| Original File | Archived As | Date | Reason |
|---------------|-------------|------|--------|
| `deploy-and-configure-ws-reception01.yml` | `archive/deploy-and-configure-ws-reception01.yml.backup` | 2026-01-12 | Replaced with split playbook architecture |

## Current Active Playbooks

### Receptionist Workstation (ws-reception01)

**Active playbooks:**
1. `deploy-ws-reception01.yml` - VM deployment only
2. `configure-ws-reception01.yml` - System configuration (role-based)
3. `deploy-and-configure-ws-reception01.yml` - Wrapper (runs both)

**Documentation:**
- `README-ws-reception01-playbooks.md` - Split playbook guide
- `README-role-based-playbooks.md` - Role architecture guide
- `README-ws-reception01.md` - Original comprehensive guide

### Other Playbooks

**Domain Controllers:**
- `deploy-domain-controllers.yml`
- `deploy-ad-dc.yml`
- `configure-active-directory.yml`

**Admin Workstation:**
- `deploy-and-configure-ws-admin01.yml`
- `configure-ws-admin01-roles.yml`

**Ansible Control Server:**
- `deploy-and-configure-ansible-ctrl.yml`

## Why Files Are Archived

Playbook files are archived (not deleted) when:
1. **Replaced with better architecture** - Split monolithic playbooks, role-based refactoring
2. **Major refactoring** - Significant changes that make old version incompatible
3. **Historical reference** - Keep for comparison and rollback if needed
4. **Documentation value** - Show evolution of infrastructure code

## Accessing Archived Files

### View archived file
```bash
cd playbooks/archive
cat deploy-and-configure-ws-reception01.yml.backup
```

### Compare with current version
```bash
diff archive/deploy-and-configure-ws-reception01.yml.backup \
     deploy-and-configure-ws-reception01.yml
```

### View archive README
```bash
cat archive/README.md
```

## Archive Policy

### What gets archived:
- ✅ Replaced playbooks (major refactoring)
- ✅ Old versions before significant changes
- ✅ Deprecated playbooks (no longer recommended)

### What does NOT get archived:
- ❌ Minor edits (use git history)
- ❌ Work-in-progress files
- ❌ Test files
- ❌ Generated files

## Git vs Archive

| Use Case | Solution |
|----------|----------|
| Track minor changes | Git commit history |
| Compare recent versions | Git diff |
| Major refactoring/replacement | Archive directory |
| Deprecated approach | Archive directory |
| Historical reference | Archive directory |

## Restoring Archived Files

⚠️ **Not recommended** - Archived files may be incompatible with current roles/configuration.

If you must restore:
```bash
# 1. Backup current version
cp playbooks/deploy-and-configure-ws-reception01.yml \
   playbooks/deploy-and-configure-ws-reception01.yml.current

# 2. Copy archived version
cp playbooks/archive/deploy-and-configure-ws-reception01.yml.backup \
   playbooks/deploy-and-configure-ws-reception01.yml

# 3. Note: You may need to update roles/variables to match
```

## Related Documentation

- `archive/README.md` - Detailed archive documentation
- `README-ws-reception01-playbooks.md` - Current playbook structure
- `README-role-based-playbooks.md` - Role-based architecture
- Git commit history - Complete version control

---

**Maintained by:** Richard
**Project:** SMB Office IT Blueprint
**Last Updated:** 2026-01-12
