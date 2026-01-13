# Playbook Archive

This directory contains archived/replaced playbook files for historical reference.

## Archived Files

### `deploy-and-configure-ws-reception01.yml.backup`

**Original Date:** 2026-01-11
**Archived Date:** 2026-01-12
**Reason:** Replaced with split playbook architecture

**What it was:**
Monolithic playbook that combined VM deployment and system configuration in one large file (450+ lines).

**What replaced it:**
Split into three separate playbooks for better modularity:
1. `../deploy-ws-reception01.yml` - VM deployment only (~60 lines)
2. `../configure-ws-reception01.yml` - System configuration (~180 lines, role-based)
3. `../deploy-and-configure-ws-reception01.yml` - Wrapper that runs both (~20 lines)

**Key differences:**
- **Old:** 450+ lines with many inline tasks
- **New:** 180 lines using 11 roles (zero inline tasks)
- **Old:** Hard to maintain and reuse
- **New:** Modular, role-based, reusable for other workstations

**Why it was replaced:**
1. Too complex - mixed deployment and configuration concerns
2. Many inline tasks instead of roles
3. Hard to test individual components
4. Not reusable for other workstation types
5. Included Debian/Ubuntu tasks (not relevant for Fedora Silverblue)

**Changes in new version:**
- Split deployment from configuration
- Extracted all inline tasks into 4 new roles:
  - `silverblue_desktop_environment`
  - `silverblue_firewall`
  - `silverblue_logging`
  - `silverblue_finalize`
- Removed all Debian/Ubuntu-specific code
- Added comprehensive error handling (`ignore_errors: yes`)
- Added `any_errors_fatal: false` for resilient deployments

## How to Use Archived Files

### View the old playbook
```bash
cat archive/deploy-and-configure-ws-reception01.yml.backup
```

### Compare with new version
```bash
diff archive/deploy-and-configure-ws-reception01.yml.backup deploy-and-configure-ws-reception01.yml
```

### Restore if needed (not recommended)
```bash
# Backup current version first
cp deploy-and-configure-ws-reception01.yml deploy-and-configure-ws-reception01.yml.current

# Restore old version
cp archive/deploy-and-configure-ws-reception01.yml.backup deploy-and-configure-ws-reception01.yml
```

## Migration Timeline

| Date | Action | Details |
|------|--------|---------|
| 2026-01-11 | Created original monolithic playbook | 450+ lines, inline tasks |
| 2026-01-12 | Split into deploy + configure | Separated concerns |
| 2026-01-12 | Extracted inline tasks to roles | Created 4 new roles |
| 2026-01-12 | Cleaned Debian/Ubuntu tasks | Fedora Silverblue only |
| 2026-01-12 | Archived original | Moved to archive/ |

## Related Documentation

- `../README-ws-reception01-playbooks.md` - New split playbook documentation
- `../README-role-based-playbooks.md` - Role-based architecture guide
- `../../roles/silverblue_*/CHANGELOG.md` - Individual role changes

## Notes

- This archive is for reference only
- The new split architecture is the recommended approach
- Do not use archived playbooks in production
- If you need the old behavior, refer to this file but update to match current role structure

---

**Archive maintained by:** Richard
**Project:** SMB Office IT Blueprint
**Last Updated:** 2026-01-12
