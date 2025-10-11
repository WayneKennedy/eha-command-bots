-- EHA Command Bots Database Schema
-- PostgreSQL compatible

-- Story Arcs Table
-- Tracks major narrative arcs over time
CREATE TABLE story_arcs (
    id SERIAL PRIMARY KEY,
    title TEXT NOT NULL,
    description TEXT,
    start_date TIMESTAMP NOT NULL,
    end_date TIMESTAMP,
    status TEXT CHECK(status IN ('planning', 'active', 'completed', 'archived')) DEFAULT 'planning',
    difficulty_level INTEGER CHECK(difficulty_level BETWEEN 1 AND 10) DEFAULT 5,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Officers Table
-- AI command officers with personalities
CREATE TABLE officers (
    id SERIAL PRIMARY KEY,
    name TEXT NOT NULL UNIQUE,
    rank TEXT NOT NULL,
    role TEXT CHECK(role IN ('commander', 'xo', 'intelligence', 'operations', 'logistics', 'communications')),
    personality_prompt_file TEXT, -- Reference to personality definition file
    discord_channel_id TEXT,
    status TEXT CHECK(status IN ('active', 'inactive', 'on_leave')) DEFAULT 'active',
    missions_issued INTEGER DEFAULT 0,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Missions Table
-- Individual missions within story arcs
CREATE TABLE missions (
    id SERIAL PRIMARY KEY,
    story_arc_id INTEGER,
    title TEXT NOT NULL,
    description TEXT,
    mission_type TEXT CHECK(mission_type IN ('combat', 'stealth', 'intel', 'logistics', 'special_ops', 'rescue', 'escort')),
    difficulty INTEGER CHECK(difficulty BETWEEN 1 AND 10) DEFAULT 5,
    officer_id INTEGER, -- Officer who issued the mission
    status TEXT CHECK(status IN ('draft', 'briefed', 'in_progress', 'completed', 'failed', 'cancelled')) DEFAULT 'draft',
    briefing_date TIMESTAMP,
    completion_date TIMESTAMP,
    outcome TEXT,
    player_count INTEGER DEFAULT 0,
    success_rating INTEGER CHECK(success_rating BETWEEN 0 AND 100),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (story_arc_id) REFERENCES story_arcs(id),
    FOREIGN KEY (officer_id) REFERENCES officers(id)
);

-- Players Table
-- Org members who participate in missions
CREATE TABLE players (
    id SERIAL PRIMARY KEY,
    discord_user_id TEXT NOT NULL UNIQUE,
    discord_username TEXT NOT NULL,
    display_name TEXT,
    missions_completed INTEGER DEFAULT 0,
    missions_failed INTEGER DEFAULT 0,
    total_participation INTEGER DEFAULT 0,
    performance_rating REAL DEFAULT 50.0, -- 0-100 scale
    last_active TIMESTAMP,
    joined_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    notes TEXT
);

-- Mission Participants Table
-- Many-to-many relationship between missions and players
CREATE TABLE mission_participants (
    id SERIAL PRIMARY KEY,
    mission_id INTEGER NOT NULL,
    player_id INTEGER NOT NULL,
    participation_status TEXT CHECK(participation_status IN ('signed_up', 'confirmed', 'completed', 'absent', 'dropped')) DEFAULT 'signed_up',
    performance_notes TEXT,
    joined_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (mission_id) REFERENCES missions(id) ON DELETE CASCADE,
    FOREIGN KEY (player_id) REFERENCES players(id) ON DELETE CASCADE,
    UNIQUE(mission_id, player_id)
);

-- Story Events Table
-- Key events and plot points within story arcs
CREATE TABLE story_events (
    id SERIAL PRIMARY KEY,
    story_arc_id INTEGER NOT NULL,
    event_title TEXT NOT NULL,
    event_description TEXT,
    event_type TEXT CHECK(event_type IN ('plot_point', 'player_action', 'officer_decision', 'random_event', 'climax')),
    trigger_condition TEXT, -- What caused this event
    occurred_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    impact_level INTEGER CHECK(impact_level BETWEEN 1 AND 10) DEFAULT 5,
    FOREIGN KEY (story_arc_id) REFERENCES story_arcs(id) ON DELETE CASCADE
);

-- Officer Communications Table
-- Messages and interactions between officers (for narrative consistency)
CREATE TABLE officer_communications (
    id SERIAL PRIMARY KEY,
    from_officer_id INTEGER NOT NULL,
    to_officer_id INTEGER,
    subject TEXT,
    message_content TEXT,
    communication_type TEXT CHECK(communication_type IN ('briefing', 'coordination', 'report', 'discussion')),
    related_mission_id INTEGER,
    sent_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (from_officer_id) REFERENCES officers(id),
    FOREIGN KEY (to_officer_id) REFERENCES officers(id),
    FOREIGN KEY (related_mission_id) REFERENCES missions(id)
);

-- Story State Table
-- Key-value store for dynamic story state
CREATE TABLE story_state (
    id SERIAL PRIMARY KEY,
    story_arc_id INTEGER NOT NULL,
    state_key TEXT NOT NULL,
    state_value TEXT,
    value_type TEXT CHECK(value_type IN ('string', 'number', 'boolean', 'json')) DEFAULT 'string',
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (story_arc_id) REFERENCES story_arcs(id) ON DELETE CASCADE,
    UNIQUE(story_arc_id, state_key)
);

-- Workflow Executions Table
-- Track n8n workflow executions for debugging and auditing
CREATE TABLE workflow_executions (
    id SERIAL PRIMARY KEY,
    workflow_name TEXT NOT NULL,
    execution_id TEXT UNIQUE,
    officer_id INTEGER,
    mission_id INTEGER,
    status TEXT CHECK(status IN ('running', 'success', 'error', 'cancelled')) DEFAULT 'running',
    error_message TEXT,
    started_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    completed_at TIMESTAMP,
    execution_data TEXT, -- JSON data
    FOREIGN KEY (officer_id) REFERENCES officers(id),
    FOREIGN KEY (mission_id) REFERENCES missions(id)
);

-- Create indexes for common queries
CREATE INDEX idx_missions_arc ON missions(story_arc_id);
CREATE INDEX idx_missions_officer ON missions(officer_id);
CREATE INDEX idx_missions_status ON missions(status);
CREATE INDEX idx_mission_participants_mission ON mission_participants(mission_id);
CREATE INDEX idx_mission_participants_player ON mission_participants(player_id);
CREATE INDEX idx_story_events_arc ON story_events(story_arc_id);
CREATE INDEX idx_story_state_arc ON story_state(story_arc_id);
CREATE INDEX idx_officer_comms_from ON officer_communications(from_officer_id);
CREATE INDEX idx_officer_comms_to ON officer_communications(to_officer_id);
CREATE INDEX idx_workflow_executions_workflow ON workflow_executions(workflow_name);
CREATE INDEX idx_players_discord_id ON players(discord_user_id);

-- Views for common queries
CREATE VIEW active_missions AS
SELECT
    m.id,
    m.title,
    m.mission_type,
    m.difficulty,
    o.name as officer_name,
    o.rank as officer_rank,
    sa.title as story_arc_title,
    m.status,
    m.briefing_date,
    COUNT(mp.id) as participant_count
FROM missions m
LEFT JOIN officers o ON m.officer_id = o.id
LEFT JOIN story_arcs sa ON m.story_arc_id = sa.id
LEFT JOIN mission_participants mp ON m.id = mp.mission_id
WHERE m.status IN ('briefed', 'in_progress')
GROUP BY m.id, m.title, m.mission_type, m.difficulty, o.name, o.rank, sa.title, m.status, m.briefing_date;

CREATE VIEW player_stats AS
SELECT
    p.id,
    p.discord_username,
    p.display_name,
    p.missions_completed,
    p.missions_failed,
    p.total_participation,
    p.performance_rating,
    p.last_active,
    COUNT(mp.id) as total_missions_signed_up
FROM players p
LEFT JOIN mission_participants mp ON p.id = mp.player_id
GROUP BY p.id, p.discord_username, p.display_name, p.missions_completed, p.missions_failed, p.total_participation, p.performance_rating, p.last_active;

CREATE VIEW current_story_arc AS
SELECT
    sa.id,
    sa.title,
    sa.description,
    sa.start_date,
    sa.end_date,
    sa.status,
    sa.difficulty_level,
    sa.created_at,
    sa.updated_at,
    COUNT(DISTINCT m.id) as total_missions,
    COUNT(DISTINCT se.id) as total_events
FROM story_arcs sa
LEFT JOIN missions m ON sa.id = m.story_arc_id
LEFT JOIN story_events se ON sa.id = se.story_arc_id
WHERE sa.status = 'active'
GROUP BY sa.id, sa.title, sa.description, sa.start_date, sa.end_date, sa.status, sa.difficulty_level, sa.created_at, sa.updated_at;
