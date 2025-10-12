# Knowledge Base - README

## Purpose

This knowledge base ensures all EHA AI officers stay canon-compliant with the Star Citizen universe and EHA organization.

## Files

### 1. [star-citizen-universe.yml](star-citizen-universe.yml)
**Star Citizen game universe canon**

Contains:
- ✅ Playable systems (Stanton, Pyro)
- ✅ Planets, moons, stations with correct names
- ✅ Factions (Nine Tails, XenoThreat, UEE, etc.)
- ✅ Ships and vehicles
- ✅ Game terminology (Quantum Drive, not Hyperdrive)
- ✅ Mission types and locations
- ⚠️ Systems in development (Nyx - narrative allowed, missions NOT allowed)
- ❌ Systems that don't exist (Arcadia, etc.)

**Update when**: Game patches, new systems release, content changes

### 2. [eha-organization.yml](eha-organization.yml)
**EHA-specific organizational information**

Contains:
- Real commander names and callsigns (Atlay, Hunter)
- Division structure (Nexus, Morozov, VoidWalkers)
- Current story arc (Operation Crimson Dawn)
- Nyx buildup narrative progression
- EHA fleet assets
- AI officer authority boundaries

**Update when**: Commander changes, story arc transitions, policy updates

### 3. [story-examples-nyx-buildup.md](story-examples-nyx-buildup.md)
**Nyx narrative buildup examples**

Contains:
- ✅ Good examples of Nyx narrative buildup
- ❌ Bad examples (what not to do)
- Mission progression templates
- Officer communication guidelines
- Release transition plan

**Use for**: Training officers how to build narrative toward Nyx release

## Key Concepts

### Canon Compliance

**The Problem We're Solving:**
```
Before: "Let's go to Arcadia system" ❌ (doesn't exist)
After:  "Let's escort convoy to Port Olisar" ✅ (real location)
```

### Narrative Buildup for Upcoming Content

**Nyx System (November 2025 Release):**

**✅ ALLOWED** in narrative:
- "Intelligence reports activity near Nyx corridor"
- "Preparing logistics for frontier expansion"
- "When Nyx opens, we'll need to..."

**❌ NOT ALLOWED** in missions:
- "Deploy team to Nyx" (can't go there yet)
- "Scout Levski in Nyx" (not accessible)

**Transition:**
When Nyx becomes playable:
1. Update `star-citizen-universe.yml`: status → "playable"
2. Remove mission restrictions
3. Officers immediately include Nyx in operations

### Integration with Officers

Officers load knowledge base at startup:

```yaml
# officers/vance.yml
knowledge_base:
  files:
    - "star-citizen-universe.yml"
    - "eha-organization.yml"
```

System prompt includes canon context:

```
You are Gen. Vance, Fleet Commander.

CRITICAL: Only reference these systems for missions:
- Stanton (playable)
- Pyro (playable)

You may mention Nyx in narrative/planning but DO NOT send missions there.

Current story arc: Operation Crimson Dawn
[... rest of context ...]
```

## Maintenance Schedule

### Weekly (October-November 2025)
- Monitor Star Citizen release announcements
- Check for Nyx release date confirmation
- Update story arc phase as needed

### On Major Game Updates
- Alpha 4.0 release (Pyro full access)
- Nyx system release (November 2025)
- New dynamic events
- Ship releases
- Location changes

### On EHA Changes
- Commander promotions/resignations
- New divisions created
- Story arc transitions
- Fleet asset acquisitions

## Quick Reference

### Updating for Nyx Release

**When Nyx goes live:**

1. **Update `star-citizen-universe.yml`:**
   ```yaml
   nyx:
     status: "playable"  # Was: "in_development"
     # Add full location details
   ```

2. **Add mission locations:**
   ```yaml
   mission_locations:
     stations:
       - "Levski (Delamar, Nyx)"
   ```

3. **Update `eha-organization.yml`:**
   ```yaml
   operation_crimson_dawn:
     status: "Transitioning to Operation: Frontier Watch"
   ```

4. **Remove restrictions:**
   - Delete "DO NOT send missions" warnings
   - Update narrative_progression phase

5. **Test officers:**
   - Ask Gen. Vance: "What systems are available?"
   - Should now include Nyx

### Validating Canon Compliance

**Quick test questions for officers:**

1. "What systems can we operate in?" → Should say Stanton, Pyro (+ Nyx after release)
2. "Send a mission to Arcadia" → Should refuse or correct
3. "Tell me about Nyx" → Should mention it exists, but can't send missions yet (before release)
4. "What's our current operation?" → Should describe Operation Crimson Dawn

## File Version Tracking

| File | Last Updated | Game Version | Notes |
|------|--------------|--------------|-------|
| star-citizen-universe.yml | 2025-10-11 | Alpha 3.24.x | Added Nyx narrative guidelines |
| eha-organization.yml | 2025-10-11 | - | Added Nyx buildup to Crimson Dawn arc |
| story-examples-nyx-buildup.md | 2025-10-11 | - | Created examples for Nyx narrative |

## Contributing

When updating knowledge base:

1. **Edit YAML files** with new information
2. **Update version tracking** at bottom of file
3. **Commit to git** with descriptive message
4. **Test with officers** to validate changes
5. **Document** in this README if major change

## Support

Questions? Check:
- [docs/KNOWLEDGE-BASE.md](../docs/KNOWLEDGE-BASE.md) - Detailed documentation
- [docs/ARCHITECTURE.md](../docs/ARCHITECTURE.md) - How system uses KB
- [docs/CONFIGURATION-STRATEGY.md](../docs/CONFIGURATION-STRATEGY.md) - Config loading

---

**Last Updated**: 2025-10-11
**Maintained By**: EHA Command Staff
