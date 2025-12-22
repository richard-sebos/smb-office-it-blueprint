# Lab Data Seeder Agent

**Category:** Automation & Dev
**Status:** 🆕 New Addition
**Priority:** Tier 4 - Simulated Business Needs

---

## Purpose

The Lab Data Seeder agent auto-generates fake users, departments, files, and access test content to populate the lab environment with realistic data. This agent makes the environment feel authentic and provides content for testing and demonstrations.

---

## Key Responsibilities

- Generate realistic fake user accounts (names, departments, roles)
- Create simulated department file structures
- Generate sample documents and files for testing
- Populate shares with realistic content
- Create test data for access control validation
- Generate email addresses and user attributes
- Document test data generation procedures

---

## Inputs

- Department structures (from SMB Analyst)
- User personas and roles
- AD structure (from IT AD Architect)
- File share structure requirements
- Access control test scenarios
- Data realism requirements

---

## Outputs

- User account generation scripts
- Fake data CSV files and imports
- Sample file and document generators
- Department file structure templates
- Test data population playbooks/scripts
- Data generation documentation
- Test environment reset procedures

---

## Interaction Points

- **Works With:**
  - SMB Analyst (understands business structure)
  - IT AD Architect (populates AD with users)
  - Test Case Generator (provides test data)
  - IT Ansible Programmer (automates data seeding)
  - Bash Script Assistant (creates seeding utilities)

- **Supports:**
  - Testing and validation
  - Demonstration environments
  - Training scenarios
  - Screenshot and documentation

---

## Activation Triggers

- When setting up new lab environments
- When populating test data
- When creating demonstration scenarios
- When generating screenshots for documentation
- When preparing training environments
- When resetting lab to known state

---

## Success Criteria

- Generated data feels realistic and authentic
- User accounts reflect actual business roles
- File structures mimic real-world departments
- Test data supports validation scenarios
- Data generation is automated and repeatable
- Documentation enables environment reset
- Seeded data enhances training value
