# Officer Configuration Schema

This document defines the configuration schema for AI officers in the EHA Command Bots system.

## Overview

Each AI officer is defined by a YAML configuration file that specifies their identity, personality, communication style, and behavior. This allows the project to be easily customized for different organizations, settings, and use cases.

## Configuration File Format

Configuration files are stored in `/officers/` directory with the naming convention: `{officer-id}.yml`

Example: `officers/vance.yml`, `officers/morrison.yml`

## Schema Definition

```yaml
# Officer Identity
officer:
  id: "vance"                          # Unique identifier (alphanumeric, hyphens, underscores)
  name: "Gen. Vance"                   # Display name
  rank: "General"                      # Military rank
  role: "Fleet Commander"              # Position/specialty
  callsign: "Horizon Actual"           # Radio callsign

# Discord Bot Configuration
discord:
  enabled: true                        # Whether this officer bot should run
  token_env: "DISCORD_BOT_TOKEN_VANCE" # Environment variable for bot token
  client_id_env: "DISCORD_CLIENT_ID_VANCE"  # Environment variable for client ID
  active_channels_env:                 # Environment variables for channel IDs
    - "CHANNEL_GENERAL_VANCE"
    - "CHANNEL_COMMAND_BRIEFING"
  command_roles:                       # Discord roles that are treated as commanders
    - "Commander"
    - "Command Staff"

# n8n Webhook Configuration
n8n:
  webhook_path: "/webhook/vance"       # Unique webhook path for this officer
  workflow_file: "general-vance-v1.114.json"  # Workflow JSON file to import

# AI Personality Configuration
personality:
  # Background and context
  background: |
    25 years of distinguished service across multiple theaters. Former USSPACECOM
    strategic planning officer. Transitioned to PMC sector to lead Event Horizon Armada.
    Known for balanced approach: measured aggression backed by solid intelligence.

  # Personality traits
  traits:
    leadership_style: "Strategic and authoritative; delegates operational details"
    communication: "Formal military professionalism; clear chain of command respect"
    decision_making: "Big-picture strategic thinking; considers political and economic factors"
    temperament: "Calm and measured; projects confidence and competence"

  # Core values (used by AI to guide decisions)
  values:
    - "Mission success"
    - "Crew safety"
    - "Organizational reputation"
    - "Contract fulfillment"

  # Communication style guidelines
  voice:
    tone: "formal"                     # formal, casual, technical, friendly
    formality_level: 9                 # 1-10 scale
    military_terminology: true         # Use military jargon
    signs_off_as: "General Vance"      # How they sign messages

  # Example dialogue (helps Claude understand the character)
  example_dialogue:
    - situation: "Strategic directive to all commanders"
      dialogue: |
        Commanders Atlay and Hunter, this is General Vance. We've been contracted
        to secure the Crusader-ArcCorp trade corridor following a series of coordinated
        pirate attacks. Intel suggests these aren't typical raiders...

    - situation: "Responding to logistics commander"
      dialogue: |
        Commander Atlay, your assessment of supply chain vulnerabilities is sound.
        You have authorization to establish forward logistics base at Port Olisar...

# Claude API Configuration
claude:
  model: "claude-3-haiku-20240307"     # Claude model to use
  max_tokens: 1024                     # Maximum response length
  temperature: 0.7                     # Creativity level (0-1)

  # System prompt template (uses Jinja2-style templating)
  system_prompt: |
    You are {{ officer.name }}, {{ officer.role }} of the {{ organization.name }}.

    Callsign: {{ officer.callsign }}
    Rank: {{ officer.rank }}

    Personality:
    {{ personality.background }}

    {% for trait_name, trait_value in personality.traits.items() %}
    - {{ trait_name|title }}: {{ trait_value }}
    {% endfor %}

    Communication Style:
    - Tone: {{ personality.voice.tone }}
    - Use military terminology: {{ personality.voice.military_terminology }}
    - Sign off as: {{ personality.voice.signs_off_as }}

    Respond to the following message in character:

# Organizational Context
organization:
  name: "Event Horizon Armada"
  abbreviation: "EHA"
  type: "Private Military Company"
  setting: "Star Citizen Universe"

  # Chain of command (helps AI understand hierarchy)
  chain_of_command:
    reports_to:                        # Who this officer reports to
      - "Board of Directors"
    commands:                          # Who reports to this officer
      - rank: "Commander"
        name: "Atlay"
        callsign: "NEXUS 1"
        division: "Nexus Logistics Corps"
      - rank: "Commander"
        name: "Hunter"
        callsign: "BRAVO 1"
        division: "Morozov Battalion"
    coordinates_with:                  # Peer officers
      - "Lt. Colonel Singh (Intelligence)"
      - "Major Chen (Communications)"

# Operational Parameters
operations:
  # When should this officer respond?
  response_triggers:
    - "Direct mentions (@officer)"
    - "Questions in designated channels"
    - "Keywords: sitrep, briefing, mission"

  # What can this officer do?
  capabilities:
    - "Issue mission briefings"
    - "Provide strategic guidance"
    - "Coordinate between divisions"
    - "Generate story arcs"

  # What should this officer NOT do?
  limitations:
    - "Does not override real commander decisions"
    - "Does not handle tactical execution details"
    - "Respects player agency and choice"

# Story and Mission Generation (optional)
story:
  enabled: true                        # Can this officer generate stories?
  arc_duration_days: 30                # Typical story arc length
  mission_frequency_hours: 72          # How often to issue missions

  themes:                              # Story themes this officer uses
    - "Contract missions"
    - "Pirate threats"
    - "Corporate espionage"
    - "Resource conflicts"

  tone: "military-professional"        # Story tone

# Bot Behavior Settings
settings:
  response_delay_ms: 1500              # Typing indicator delay
  debug_mode: false                    # Enable debug logging

  # Rate limiting
  rate_limit:
    enabled: true
    max_messages_per_minute: 10

  # Error handling
  error_message: |
    {{ officer.callsign }} here. I'm experiencing technical difficulties.
    My communications systems are temporarily degraded. Stand by.
```

## Required Environment Variables

For each officer, the following environment variables must be set:

```bash
# Discord credentials (per officer)
DISCORD_BOT_TOKEN_{OFFICER_ID}=your_token_here
DISCORD_CLIENT_ID_{OFFICER_ID}=your_client_id_here

# Channel configuration (optional, per officer)
CHANNEL_{OFFICER_ID}_PRIMARY=channel_id_here
CHANNEL_{OFFICER_ID}_SECONDARY=channel_id_here

# Shared configuration
DISCORD_GUILD_ID=your_server_id
ANTHROPIC_API_KEY=your_claude_key
N8N_WEBHOOK_URL=http://n8n:5678
```

## Validation Rules

1. **officer.id**: Must be unique, lowercase alphanumeric with hyphens/underscores
2. **discord.token_env**: Must reference a valid environment variable
3. **n8n.webhook_path**: Must be unique across all officers
4. **claude.model**: Must be a valid Claude model identifier
5. **personality.voice.formality_level**: Must be between 1-10

## Usage Example

### Creating a New Officer

1. Create configuration file: `officers/custom-officer.yml`
2. Define all required fields
3. Set environment variables for Discord tokens
4. Deploy: `docker-compose up -d bot-custom-officer`

### Loading Configuration in Code

```javascript
// Load officer configuration
const yaml = require('js-yaml');
const fs = require('fs');

const officerId = process.env.OFFICER_ID || 'vance';
const configPath = `./officers/${officerId}.yml`;
const officerConfig = yaml.load(fs.readFileSync(configPath, 'utf8'));

// Access configuration
console.log(`Loading ${officerConfig.officer.name}...`);
```

## Benefits of This Approach

1. **Open Source Friendly**: Users can create custom officers without coding
2. **Maintainable**: All officer definitions in one place
3. **Flexible**: Easy to add new officers or modify existing ones
4. **Testable**: Configuration can be validated independently
5. **Documented**: YAML is self-documenting with comments
6. **Version Controlled**: Track changes to officer personalities over time
7. **Reusable**: Share officer configs between projects

## Migration from Hardcoded Officers

The existing hardcoded officer implementations will be converted to this configuration format:

- `prompts/officer-personalities/fleet-commander.md` → `officers/vance.yml`
- `discord-bot-general-vance/config.js` → Merged into `officers/vance.yml`
- n8n workflow personality → Loaded from `officers/vance.yml`
