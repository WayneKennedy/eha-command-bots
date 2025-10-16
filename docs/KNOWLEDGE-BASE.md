# Knowledge Base System

## Purpose

The knowledge base system ensures all AI officers stay **canon-compliant** with:
1. **Star Citizen universe** - Real locations, factions, ships, gameplay
2. **EHA organization** - Command structure, operations, culture
3. **Current story arcs** - Active missions and narrative continuity

## Problem Being Solved

**Before Knowledge Base:**
```
Officer: "Let's run a mission to the Arcadia system"
         ^^^^^^^^^^^^^^^^^
         ❌ Doesn't exist in Star Citizen
```

**After Knowledge Base:**
```
Officer: "Let's escort a convoy from Port Olisar to Area18"
         ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
         ✅ Both locations exist in Stanton system
```

## Knowledge Base Files

### 1. Star Citizen Universe (`knowledge-base/star-citizen-universe.yml`)

**Contains:**
- ✅ Systems that exist in-game (Stanton, Pyro)
- ✅ Planets, moons, stations (with correct names)
- ✅ Factions and organizations (Nine Tails, XenoThreat, etc.)
- ✅ Ships and vehicles (Gladius, C2 Hercules, etc.)
- ✅ Game terminology (Quantum Drive, not Hyperdrive)
- ❌ Systems NOT yet in game (with warnings)
- ❌ Features not yet implemented

**Purpose:** Prevent hallucinations about game locations/features

### 2. EHA Organization (`knowledge-base/eha-organization.yml`)

**Contains:**
- Real commander names and callsigns (Atlay, Hunter)
- Division structure (Nexus, Morozov, Alpha Squad)
- Current story arc (Operation Crimson Dawn)
- EHA fleet assets (what ships we have)
- Operational guidelines and culture
- AI officer authority boundaries

**Purpose:** Maintain organizational consistency and respect player authority

## Integration with Officer Configs

### Officer Config References Knowledge Base

```yaml
# officers/vance.yml
officer:
  id: "vance"
  name: "Gen. Vance"

# Knowledge base files this officer should load
knowledge_base:
  - "star-citizen-universe.yml"   # Universe canon
  - "eha-organization.yml"         # Org-specific info

claude:
  system_prompt: |
    You are {{ officer.name }}, {{ officer.role }}.

    CRITICAL: Use only the following canonical information for missions:
    {{ knowledge_base.star_citizen_universe }}

    Your organization context:
    {{ knowledge_base.eha_organization }}

    When creating missions:
    - Only reference systems: Stanton, Pyro
    - Use locations from the approved list
    - Reference real EHA assets and commanders
    - Stay within current story arc context
```

## How It Works

### Config Loader Integration

```javascript
// config-loader.js
async function loadOfficerConfig(officerId) {
  // 1. Load officer YAML
  const officerConfig = yaml.load(
    fs.readFileSync(`./officers/${officerId}.yml`, 'utf8')
  );

  // 2. Load knowledge base files
  const knowledgeBase = {};
  for (const kbFile of officerConfig.knowledge_base || []) {
    const kbPath = `./knowledge-base/${kbFile}`;
    knowledgeBase[kbFile.replace('.yml', '')] = yaml.load(
      fs.readFileSync(kbPath, 'utf8')
    );
  }

  // 3. Merge into config
  officerConfig.knowledge_base_loaded = knowledgeBase;

  return officerConfig;
}
```

### n8n Workflow Integration

The n8n workflow builds the Claude system prompt with knowledge base context:

```javascript
// In n8n "Build System Prompt" node
const config = $input.first().json.config;

// Extract relevant knowledge
const starCitizen = config.knowledge_base_loaded['star-citizen-universe'];
const ehaOrg = config.knowledge_base_loaded['eha-organization'];

// Build canon-compliant context
const systemPrompt = `
You are ${config.officer.name}, ${config.officer.role}.

CRITICAL CANON COMPLIANCE:
You must only reference locations, systems, and features that exist in Star Citizen.

VALID SYSTEMS (use only these):
${starCitizen.systems.stanton.name} - ${starCitizen.systems.stanton.status}
${starCitizen.systems.pyro.name} - ${starCitizen.systems.pyro.status}

DO NOT reference systems in development: ${Object.keys(starCitizen.future_systems.systems).join(', ')}

VALID MISSION LOCATIONS:
${starCitizen.mission_locations.stations.join(', ')}
${starCitizen.mission_locations.cities.join(', ')}

EHA COMMAND STRUCTURE:
${ehaOrg.command_structure.nexus_logistics_corps.commander} - ${ehaOrg.command_structure.nexus_logistics_corps.focus}
${ehaOrg.command_structure.morozov_battalion.commander} - ${ehaOrg.command_structure.morozov_battalion.focus}

CURRENT OPERATION:
${ehaOrg.current_operations.operation_crimson_dawn.name}
Status: ${ehaOrg.current_operations.operation_crimson_dawn.status}
Background: ${ehaOrg.current_operations.operation_crimson_dawn.background}

YOUR ROLE:
${config.personality.background}

Respond to the following message in character and canon-compliant:
`;

return { systemPrompt };
```

## Validation

### Pre-Mission Validation Check

Add a validation step before missions are posted:

```javascript
// mission-validator.js
function validateMission(missionText, knowledgeBase) {
  const errors = [];
  const sc = knowledgeBase['star-citizen-universe'];

  // Check for invalid systems
  const invalidSystems = sc.future_systems.systems;
  for (const system of invalidSystems) {
    if (missionText.toLowerCase().includes(system.toLowerCase())) {
      errors.push(`Invalid system referenced: ${system} (not in game yet)`);
    }
  }

  // Check for invalid terminology
  const avoidTerms = sc.terminology.avoid_terms;
  for (const term of avoidTerms) {
    if (missionText.toLowerCase().includes(term.toLowerCase())) {
      errors.push(`Avoid term: "${term}". ${getCorrectTerm(term)}`);
    }
  }

  return {
    valid: errors.length === 0,
    errors
  };
}

function getCorrectTerm(wrongTerm) {
  const corrections = {
    'hyperdrive': 'Use "Quantum Drive" instead',
    'warp': 'Use "Quantum Travel" instead',
    'sectors': 'Use "Systems" instead',
    'arcadia': 'System does not exist in Star Citizen'
  };
  return corrections[wrongTerm.toLowerCase()] || 'Invalid term';
}
```

## Maintenance

### When to Update Knowledge Base

**Star Citizen Universe:**
- ✅ New system released (e.g., Nyx in November)
- ✅ New planet/moon added
- ✅ Major location changes (stations added/removed)
- ✅ Game patch with new features
- ✅ Terminology changes

**EHA Organization:**
- ✅ Commander changes (promotion, resignation, new member)
- ✅ New division created
- ✅ Story arc transitions
- ✅ Fleet assets acquired
- ✅ Policy changes

### Update Process

1. **Edit YAML file**
   ```bash
   vim knowledge-base/star-citizen-universe.yml
   ```

2. **Update version tracking**
   ```yaml
   game_version:
     current: "Alpha 4.0"
     last_verified: "2025-11-15"
   ```

3. **Commit to git**
   ```bash
   git add knowledge-base/
   git commit -m "Update universe KB: Add Nyx system (4.0 release)"
   ```

4. **Restart bots** (or wait for hot reload)
   ```bash
   docker-compose restart bot-vance bot-morrison
   ```

5. **Test in Discord**
   ```
   Ask officer: "What systems are available for operations?"
   Should now mention Nyx if added
   ```

## Benefits

### For Canon Compliance
✅ Officers only reference real game locations
✅ Consistent terminology across all officers
✅ No missions to non-existent places
✅ Accurate faction and ship references

### For Immersion
✅ Players trust the AI officers
✅ Missions feel authentic to Star Citizen
✅ Story arcs align with game reality
✅ Reduces "breaking immersion" moments

### For Maintenance
✅ Single source of truth for universe facts
✅ Easy to update when game updates
✅ All officers benefit from one update
✅ Version tracking built-in

### For Open Source
✅ Users can customize for their org
✅ Different settings possible (Elite Dangerous, EVE Online, etc.)
✅ Community can contribute updates
✅ Clear separation: code vs. content vs. canon

## Example: Customizing for Another Game

### Elite Dangerous Version

```yaml
# knowledge-base/elite-dangerous-universe.yml
universe:
  name: "Elite Dangerous"
  developer: "Frontier Developments"

systems:
  sol:
    name: "Sol"
    status: "playable"
    permit_required: true
    planets: ["Earth", "Mars", "Jupiter"]

  shinrarta_dezhra:
    name: "Shinrarta Dezhra"
    status: "playable"
    permit_required: true
    notes: "Pilots Federation HQ"

# ... rest of Elite Dangerous universe
```

## Example: Testing Canon Compliance

### Test Cases

```yaml
# tests/canon-compliance-tests.yml
test_cases:
  - input: "Let's run a mission to Arcadia"
    expected: "INVALID - Arcadia does not exist"
    validation: "Must reject or correct to valid system"

  - input: "Escort convoy from Port Olisar to Area18"
    expected: "VALID - Both locations in Stanton"
    validation: "Should accept"

  - input: "Engage hyperdrive for faster travel"
    expected: "INVALID TERMINOLOGY - Use 'Quantum Drive'"
    validation: "Should correct terminology"

  - input: "Commander Atlay, new logistics mission"
    expected: "VALID - Real commander, correct division"
    validation: "Should accept and route correctly"
```

## Summary

The knowledge base system provides:

1. **Canon Compliance** - Officers stay true to Star Citizen
2. **Consistency** - All officers reference same facts
3. **Maintainability** - Update once, affects all officers
4. **Immersion** - Players trust the AI accuracy
5. **Flexibility** - Easy to adapt for other games/settings

**Key Files:**
- [knowledge-base/star-citizen-universe.yml](../knowledge-base/star-citizen-universe.yml)
- [knowledge-base/eha-organization.yml](../knowledge-base/eha-organization.yml)

**Integration Points:**
- Officer configs reference KB files
- Config loader includes KB in officer config
- n8n workflow builds system prompt with KB context
- Optional validation step checks mission text

**Maintenance:**
- Update YAML when game updates
- Track version numbers
- Commit to git for history
- Hot reload supported
