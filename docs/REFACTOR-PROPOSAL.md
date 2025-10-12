# Refactor Proposal: Generic Configurable Officer System

## Executive Summary

This proposal outlines a refactoring of the EHA Command Bots system to use a **generic, configurable architecture** that allows multiple Discord bot instances (one per officer) to share the same backend codebase, with all personality and behavior defined via YAML configuration files.

## Current State vs. Proposed State

### Current Implementation (PoC)
- ✅ **General Vance bot works** - Discord bot, n8n workflow, Claude integration
- ❌ **Hardcoded personality** - Officer details embedded in code
- ❌ **One-off implementation** - Would need to duplicate for each officer
- ❌ **Not OSS-friendly** - EHA-specific content baked into code
- ❌ **Difficult to customize** - Requires code changes for new officers

### Proposed Implementation
- ✅ **Multiple bots, one codebase** - Each officer is separate Discord bot
- ✅ **Configuration-driven** - All personality defined in YAML files
- ✅ **Generic and reusable** - Works for any organization/setting
- ✅ **OSS-friendly** - No hardcoded EHA content
- ✅ **Easy to customize** - Add officers without coding

## Architecture Overview

```
Discord Bots (Multiple Instances)          Generic Backend (Shared)
┌─────────────────────────────┐            ┌──────────────────────┐
│ 👤 Gen. Vance (Bot #1)      │───┐        │                      │
│    Config: officers/vance.yml│   │        │  discord-bot-officer │
├─────────────────────────────┤   ├───────▶│  (One codebase)      │
│ 👤 Lt. Col. Morrison (Bot #2)│   │        │                      │
│    Config: officers/morrison.yml│         │  Loads config from   │
├─────────────────────────────┤   │        │  /officers/{id}.yml  │
│ 👤 Major Chen (Bot #3)      │───┘        │                      │
│    Config: officers/chen.yml │            └──────────┬───────────┘
└─────────────────────────────┘                       │
                                                      │
                                              ┌───────▼────────┐
                                              │ n8n + Claude   │
                                              │ (Generic)      │
                                              └────────────────┘
```

## Key Design Decisions

### 1. Multiple Discord Bots (for Immersion)
Each officer appears as a **separate Discord user** with:
- Their own username (Gen. Vance, Lt. Col. Morrison, etc.)
- Their own avatar/profile picture
- Their own online status
- Their own message history

**Why**: Immersion and user experience. Players interact with distinct personalities.

### 2. Shared Codebase (for Maintainability)
All bots run the **same generic code**:
- One implementation to maintain
- One place to fix bugs
- One place to add features
- Updates apply to all officers simultaneously

**Why**: Maintainability and scalability. Don't want to manage 6+ separate codebases.

### 3. YAML Configuration (for Flexibility)
Officer personalities defined in **YAML files**:
```yaml
officer:
  name: "Gen. Vance"
  rank: "General"
  callsign: "Horizon Actual"

personality:
  background: "25 years of distinguished service..."
  voice:
    tone: "formal"
    formality_level: 9
```

**Why**: Non-developers can create officers. Configuration is version-controlled and self-documenting.

## Implementation Plan

### Phase 1: Create Generic Bot ✅
- [x] Design configuration schema
- [x] Create example configs (vance.yml, morrison.yml)
- [x] Document architecture
- [ ] Refactor discord-bot-general-vance → discord-bot-officer
- [ ] Test with multiple configurations

### Phase 2: Create Generic n8n Workflow
- [ ] Extract hardcoded personality from current workflow
- [ ] Add configuration loading step
- [ ] Build dynamic system prompt from config
- [ ] Test with multiple officers

### Phase 3: Multi-Officer Deployment
- [ ] Update docker-compose.yml for multiple instances
- [ ] Create deployment documentation
- [ ] Test 2-3 officers running simultaneously
- [ ] Validate inter-officer interactions

### Phase 4: Database Integration (Optional)
- [ ] Update database schema to store officer configs
- [ ] Allow database to override YAML configs
- [ ] Create admin interface for editing officers

## Example: Adding a New Officer

**Before Refactor** (would require):
1. Copy discord-bot-general-vance folder
2. Find/replace all "Vance" references in code
3. Modify personality in multiple files
4. Copy n8n workflow
5. Edit workflow personality nodes
6. Update docker-compose.yml
7. Test everything

**After Refactor** (only requires):
1. Create `officers/newofficer.yml` file
2. Set environment variable: `DISCORD_BOT_TOKEN_NEWOFFICER`
3. Add to docker-compose.yml:
   ```yaml
   bot-newofficer:
     build: ./discord-bot-officer
     environment:
       OFFICER_ID: newofficer
   ```
4. Deploy: `docker-compose up -d bot-newofficer`

**Result**: ~90% less work, no code changes, fully tested backend.

## Benefits

### For EHA Project
- ✅ Deploy all 6 officers quickly
- ✅ Easy to tweak personalities (just edit YAML)
- ✅ Consistent behavior across all officers
- ✅ One place to add features (inter-officer communication, story engine, etc.)

### For Open Source
- ✅ Users can create officers for any setting (not just Star Citizen)
- ✅ No EHA-specific hardcoded content
- ✅ Clear separation: code (generic) vs. content (config)
- ✅ Easy to contribute officer templates to community

### Example Use Cases Beyond EHA
- **Fantasy Guild**: AI guild officers for World of Warcraft
- **Corporate Startup**: AI department heads for a virtual company
- **Educational**: AI professors for a learning community
- **Sports Team**: AI coaching staff for team coordination

## Risk Mitigation

### Risk: Over-engineering
**Mitigation**: Keep it simple. YAML configs, basic templating, no complex logic.

### Risk: Configuration complexity
**Mitigation**: Provide excellent examples and documentation. Validation errors with helpful messages.

### Risk: Breaking existing Gen. Vance bot
**Mitigation**: Keep original as backup. Incremental refactoring. Test thoroughly before replacing.

## Success Criteria

### Minimum Viable Product
- [ ] Generic bot can run as multiple officers from different configs
- [ ] Gen. Vance maintains same personality/behavior as current PoC
- [ ] Can deploy 2+ officers simultaneously without conflicts
- [ ] Documentation for adding custom officers

### Stretch Goals
- [ ] Web UI for creating/editing officers
- [ ] Officer template marketplace/gallery
- [ ] Auto-validation of configuration files
- [ ] Multi-language support

## Timeline Estimate

| Phase | Tasks | Estimated Time |
|-------|-------|----------------|
| Phase 1 | Refactor Discord bot | 3-4 hours |
| Phase 2 | Refactor n8n workflow | 2-3 hours |
| Phase 3 | Multi-officer deployment | 2 hours |
| Phase 4 | Database integration | 4-5 hours (optional) |
| **Total** | | **7-9 hours (11-14 with Phase 4)** |

## Recommendation

**Proceed with refactor** for the following reasons:

1. **Better foundation**: This architecture scales to 10+ officers easily
2. **OSS-friendly**: Generic system appeals to broader audience
3. **Maintainability**: One codebase is much easier than six
4. **Flexibility**: Users can customize without forking the project
5. **Time investment**: ~8 hours of work saves weeks of duplication later

The current Gen. Vance PoC proves the concept works. Refactoring now (before building 5 more officers) is the right time to do it.

## Next Steps

1. **Review this proposal** - Discuss any concerns or questions
2. **Start Phase 1** - Refactor discord-bot-general-vance to be generic
3. **Test with Vance config** - Ensure behavior unchanged
4. **Test with Morrison config** - Validate multi-officer support
5. **Move to Phase 2** - Refactor n8n workflow

## Questions for Discussion

1. Should we keep the original discord-bot-general-vance as a backup?
2. Do we want database storage for configs, or YAML files only?
3. Should officer configs be in a separate repository for sharing?
4. Do we need a configuration validation tool/script?
5. What's the priority for Phase 4 (database integration)?

---

**Author**: Claude (with Wayne)
**Date**: 2025-10-11
**Status**: Proposal - Awaiting approval
