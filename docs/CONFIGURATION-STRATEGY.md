# Configuration Strategy: YAML-First with Database Overrides

## Philosophy

**Development uses YAML, Production adds Database overrides**

This hybrid approach gives you the best of both worlds:
- Version-controlled configurations (YAML in git)
- Runtime customization (Database for web UI)

## Configuration Loading Priority

```
┌─────────────────────────────────────────┐
│ 1. Load YAML file (Source of truth)    │
│    /officers/vance.yml                  │
└──────────────┬──────────────────────────┘
               │
               ▼
┌─────────────────────────────────────────┐
│ 2. Load database overrides (Optional)   │
│    SELECT config_overrides              │
│    FROM officer_configs                 │
│    WHERE officer_id = 'vance'           │
└──────────────┬──────────────────────────┘
               │
               ▼
┌─────────────────────────────────────────┐
│ 3. Deep merge (Database wins)           │
│    finalConfig = merge(yaml, database)  │
└──────────────┬──────────────────────────┘
               │
               ▼
┌─────────────────────────────────────────┐
│ 4. Use merged config for bot behavior   │
└─────────────────────────────────────────┘
```

## Use Cases

### Use Case 1: Development (YAML Only)

**Scenario**: Developer tweaking General Vance's personality

```bash
# 1. Edit YAML file
vim officers/vance.yml

# Change formality_level from 9 to 8
personality:
  voice:
    formality_level: 8

# 2. Commit to git
git add officers/vance.yml
git commit -m "Reduce Gen. Vance formality slightly"

# 3. Restart bot to pick up changes
docker-compose restart bot-vance

# 4. Test in Discord
# Gen. Vance now uses formality_level: 8
```

**Benefits**:
- Changes are version controlled
- Easy to review in PRs
- Can rollback via git
- Shareable with other developers

### Use Case 2: Production Runtime Override (Database)

**Scenario**: Admin wants to temporarily increase formality for event

```javascript
// Via web UI or API
UPDATE officer_configs
SET
    config_overrides = jsonb_set(
        COALESCE(config_overrides, '{}'::jsonb),
        '{personality,voice,formality_level}',
        '10'
    ),
    updated_by = 'admin'
WHERE officer_id = 'vance';

// Bot picks up change automatically (no restart needed)
// YAML still says 8, but runtime behavior is 10
```

**Benefits**:
- No deployment needed
- Immediate effect
- Can be reverted easily
- YAML remains unchanged (safe baseline)

### Use Case 3: A/B Testing

**Scenario**: Test two personality variations on different servers

```sql
-- Server 1: Use YAML defaults
INSERT INTO officer_configs (officer_id, source)
VALUES ('vance', 'yaml');

-- Server 2: Override with more casual tone
INSERT INTO officer_configs (officer_id, source, config_overrides)
VALUES ('vance', 'hybrid', '{"personality": {"voice": {"formality_level": 6}}}');
```

Track results in `officer_conversations` table:
```sql
SELECT
    officer_id,
    AVG(feedback_score) as avg_rating,
    COUNT(*) as total_conversations
FROM officer_conversations
WHERE officer_id = 'vance'
GROUP BY officer_id;
```

### Use Case 4: Emergency Rollback

**Scenario**: Database override caused issues

```sql
-- Option 1: Clear database override (fall back to YAML)
UPDATE officer_configs
SET
    config_overrides = NULL,
    source = 'yaml'
WHERE officer_id = 'vance';

-- Option 2: Rollback to previous version from history
INSERT INTO officer_configs (officer_id, config_json, source)
SELECT officer_id, config_json, 'database'
FROM officer_config_history
WHERE officer_id = 'vance'
ORDER BY changed_at DESC
LIMIT 1
OFFSET 1;  -- Get 2nd most recent (1 version back)
```

## Implementation in Code

### Config Loader Module

```javascript
// config-loader.js
const yaml = require('js-yaml');
const fs = require('fs');
const deepMerge = require('deepmerge');

async function loadOfficerConfig(officerId) {
  // 1. Load YAML file (always present)
  const yamlPath = `./officers/${officerId}.yml`;

  if (!fs.existsSync(yamlPath)) {
    throw new Error(`Officer config not found: ${yamlPath}`);
  }

  const yamlConfig = yaml.load(fs.readFileSync(yamlPath, 'utf8'));

  // 2. Check for database overrides
  const dbOverrides = await loadDatabaseOverrides(officerId);

  // 3. Merge configurations (database wins)
  const finalConfig = dbOverrides
    ? deepMerge(yamlConfig, dbOverrides)
    : yamlConfig;

  // 4. Validate configuration
  validateConfig(finalConfig);

  // 5. Log source for debugging
  console.log(`📋 Loaded config for ${officerId}:`, {
    source: dbOverrides ? 'hybrid (YAML + DB)' : 'yaml',
    yaml_file: yamlPath,
    db_overrides: !!dbOverrides
  });

  return finalConfig;
}

async function loadDatabaseOverrides(officerId) {
  try {
    const result = await database.query(
      `SELECT config_overrides FROM officer_configs
       WHERE officer_id = $1 AND is_active = true`,
      [officerId]
    );

    return result.rows[0]?.config_overrides || null;
  } catch (error) {
    console.warn(`⚠️  Could not load DB overrides for ${officerId}:`, error.message);
    return null;  // Fall back to YAML only
  }
}

function validateConfig(config) {
  // Validate required fields
  if (!config.officer?.id) {
    throw new Error('officer.id is required');
  }

  if (!config.discord?.token_env) {
    throw new Error('discord.token_env is required');
  }

  // Validate ranges
  const formalityLevel = config.personality?.voice?.formality_level;
  if (formalityLevel && (formalityLevel < 1 || formalityLevel > 10)) {
    throw new Error('personality.voice.formality_level must be between 1-10');
  }

  return true;
}

module.exports = { loadOfficerConfig };
```

### Usage in Bot

```javascript
// index.js
const { loadOfficerConfig } = require('./config-loader');

const officerId = process.env.OFFICER_ID || 'vance';

// Load configuration on startup
const config = await loadOfficerConfig(officerId);

console.log(`✅ ${config.officer.name} loaded`);
console.log(`   Formality Level: ${config.personality.voice.formality_level}`);

// Optional: Watch for config changes (hot reload)
if (process.env.ENABLE_HOT_RELOAD === 'true') {
  setInterval(async () => {
    const newConfig = await loadOfficerConfig(officerId);
    if (JSON.stringify(newConfig) !== JSON.stringify(config)) {
      console.log('🔄 Configuration changed, reloading...');
      Object.assign(config, newConfig);
    }
  }, 60000);  // Check every minute
}
```

## Database Schema

See: [database/migrations/001_add_officer_configs.sql](../database/migrations/001_add_officer_configs.sql)

Key tables:
- `officer_configs` - Current configuration overrides
- `officer_config_history` - Audit trail of changes
- `officer_conversations` - Conversation history for analytics

## Web UI (Future)

Planned interface for editing officer configurations:

```
/admin/officers
  ├── List view (all officers)
  ├── Edit view (per officer)
  │   ├── Identity tab
  │   ├── Personality tab
  │   ├── Behavior tab
  │   ├── Preview (test personality)
  │   └── History (rollback)
  └── Analytics view
      ├── Conversation stats
      ├── User feedback
      └── A/B test results
```

## Migration Path

### Phase 1: YAML Only (Current) ✅
- All configs in YAML files
- Simple, version-controlled
- Perfect for development

### Phase 2: Add Database Schema (Next)
- Create `officer_configs` table
- Config loader checks database
- Falls back to YAML if no DB entry

### Phase 3: Basic Web UI
- View officer configurations
- Edit via web interface
- Save to database

### Phase 4: Advanced Features
- A/B testing framework
- Analytics dashboard
- Multi-server support
- Personality marketplace

## Best Practices

### Development
✅ **DO**: Edit YAML files and commit to git
✅ **DO**: Use descriptive commit messages for personality changes
✅ **DO**: Test changes locally before committing
❌ **DON'T**: Edit production database directly during development

### Production
✅ **DO**: Use database overrides for temporary changes
✅ **DO**: Document why you're overriding in `change_description`
✅ **DO**: Test in staging before production
❌ **DON'T**: Completely replace YAML configs in database (use overrides)

### Emergency
✅ **DO**: Clear database overrides to fall back to YAML
✅ **DO**: Use config history table to rollback
✅ **DO**: Check `officer_conversations` table for issues
❌ **DON'T**: Delete YAML files (they're your safety net)

## Example Scenarios

### Temporary Event Override

```sql
-- Holiday event: Make all officers more festive
UPDATE officer_configs
SET config_overrides = jsonb_set(
    COALESCE(config_overrides, '{}'::jsonb),
    '{personality,voice,tone}',
    '"festive"'
)
WHERE officer_id IN ('vance', 'morrison', 'chen');

-- After event: Revert
UPDATE officer_configs
SET config_overrides = config_overrides - 'personality'
WHERE officer_id IN ('vance', 'morrison', 'chen');
```

### Per-Server Customization

```sql
-- Different Discord servers, different personalities
INSERT INTO officer_configs (officer_id, config_overrides)
VALUES
  ('vance', '{"personality": {"voice": {"formality_level": 9}}}'),  -- Server 1
  ('vance', '{"personality": {"voice": {"formality_level": 6}}}');  -- Server 2
```

## Summary

| Aspect | YAML | Database |
|--------|------|----------|
| **Primary Use** | Development baseline | Production overrides |
| **Version Control** | ✅ Git tracked | ❌ Not in git |
| **Requires Restart** | ✅ Yes | ❌ No (hot reload) |
| **Easy Rollback** | ✅ Git revert | ⚠️ Requires history table |
| **Shareable** | ✅ Commit and push | ❌ Server-specific |
| **Best For** | Permanent changes | Temporary tweaks |

**Recommendation**: Use YAML for all baseline configurations. Use database only for:
- Temporary overrides
- A/B testing
- Per-server customization
- Quick fixes while developing permanent YAML changes

This gives you the flexibility of runtime changes WITHOUT losing the safety of version-controlled configurations.
