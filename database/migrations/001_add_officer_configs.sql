-- Migration: Add officer configuration support
-- Supports YAML-first development with optional database overrides

-- Officer Configurations Table
-- Stores runtime overrides for officer configs (YAML is the source of truth)
CREATE TABLE officer_configs (
    id SERIAL PRIMARY KEY,
    officer_id TEXT NOT NULL UNIQUE,  -- Must match YAML filename (e.g., 'vance', 'morrison')

    -- Full configuration as JSON (if you want to override entire YAML)
    config_json JSONB,

    -- Partial overrides (more common - just override specific fields)
    config_overrides JSONB,

    -- Metadata
    source TEXT CHECK(source IN ('yaml', 'database', 'hybrid')) DEFAULT 'hybrid',
    is_active BOOLEAN DEFAULT true,

    -- Audit trail
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_by TEXT,  -- Who made the change (via web UI)

    -- Version tracking
    config_version INTEGER DEFAULT 1,

    CONSTRAINT valid_config CHECK (config_json IS NOT NULL OR config_overrides IS NOT NULL)
);

-- Officer Conversations Table
-- Track conversation history per officer for context and learning
CREATE TABLE officer_conversations (
    id SERIAL PRIMARY KEY,
    officer_id TEXT NOT NULL,
    discord_channel_id TEXT NOT NULL,
    discord_message_id TEXT NOT NULL,
    discord_user_id TEXT NOT NULL,
    discord_username TEXT NOT NULL,

    -- Message content
    user_message TEXT NOT NULL,
    officer_response TEXT,

    -- Context used for this response
    system_prompt_used TEXT,
    config_snapshot JSONB,  -- Configuration at time of response

    -- Metadata
    response_time_ms INTEGER,
    claude_model TEXT,
    tokens_used INTEGER,

    -- Quality tracking (for A/B testing)
    user_reaction TEXT,  -- emoji reactions from user
    feedback_score INTEGER CHECK(feedback_score BETWEEN 1 AND 5),

    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Officer Config History Table
-- Track all changes to officer configurations for rollback and auditing
CREATE TABLE officer_config_history (
    id SERIAL PRIMARY KEY,
    officer_id TEXT NOT NULL,
    config_json JSONB NOT NULL,  -- Full config snapshot
    change_description TEXT,
    changed_by TEXT,
    changed_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,

    FOREIGN KEY (officer_id) REFERENCES officer_configs(officer_id) ON DELETE CASCADE
);

-- Indexes for performance
CREATE INDEX idx_officer_configs_officer_id ON officer_configs(officer_id);
CREATE INDEX idx_officer_configs_active ON officer_configs(is_active);
CREATE INDEX idx_officer_conversations_officer ON officer_conversations(officer_id);
CREATE INDEX idx_officer_conversations_channel ON officer_conversations(discord_channel_id);
CREATE INDEX idx_officer_conversations_created ON officer_conversations(created_at DESC);
CREATE INDEX idx_officer_config_history_officer ON officer_config_history(officer_id);
CREATE INDEX idx_officer_config_history_changed_at ON officer_config_history(changed_at DESC);

-- Function to automatically update updated_at timestamp
CREATE OR REPLACE FUNCTION update_officer_config_timestamp()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = CURRENT_TIMESTAMP;
    NEW.config_version = OLD.config_version + 1;

    -- Archive old config to history
    INSERT INTO officer_config_history (officer_id, config_json, change_description, changed_by)
    VALUES (
        OLD.officer_id,
        COALESCE(OLD.config_json, OLD.config_overrides),
        'Auto-archived on update',
        NEW.updated_by
    );

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Trigger to track config changes
CREATE TRIGGER trigger_officer_config_timestamp
    BEFORE UPDATE ON officer_configs
    FOR EACH ROW
    EXECUTE FUNCTION update_officer_config_timestamp();

-- View: Merged officer configurations
-- Combines YAML defaults with database overrides
CREATE VIEW officer_configs_merged AS
SELECT
    oc.officer_id,
    oc.config_json,
    oc.config_overrides,
    oc.source,
    oc.is_active,
    oc.config_version,
    oc.updated_at,
    oc.updated_by,
    -- Stats
    (SELECT COUNT(*) FROM officer_conversations WHERE officer_id = oc.officer_id) as total_conversations,
    (SELECT COUNT(*) FROM officer_config_history WHERE officer_id = oc.officer_id) as config_change_count
FROM officer_configs oc
WHERE oc.is_active = true;

-- Seed data: Register all YAML-based officers
-- These entries indicate officers are defined in YAML files
INSERT INTO officer_configs (officer_id, source, config_overrides) VALUES
    ('vance', 'yaml', NULL),
    ('morrison', 'yaml', NULL),
    ('vandermerwe', 'yaml', NULL),
    ('reeves', 'yaml', NULL),
    ('singh', 'yaml', NULL),
    ('chen', 'yaml', NULL)
ON CONFLICT (officer_id) DO NOTHING;

-- Example: How to override specific fields via database
-- COMMENT: Uncomment to test database overrides
-- UPDATE officer_configs
-- SET
--     config_overrides = '{"personality": {"voice": {"formality_level": 8}}}'::jsonb,
--     source = 'hybrid',
--     updated_by = 'admin'
-- WHERE officer_id = 'vance';

COMMENT ON TABLE officer_configs IS 'Stores runtime configuration overrides for AI officers. YAML files are the source of truth; database provides optional overrides.';
COMMENT ON TABLE officer_conversations IS 'Conversation history for context, analytics, and A/B testing.';
COMMENT ON TABLE officer_config_history IS 'Audit trail of all configuration changes for rollback and compliance.';
COMMENT ON COLUMN officer_configs.config_json IS 'Full configuration override (replaces YAML entirely). Rarely used.';
COMMENT ON COLUMN officer_configs.config_overrides IS 'Partial overrides (common). Merged with YAML config at runtime.';
