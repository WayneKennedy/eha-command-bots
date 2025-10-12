# EHA Command Bots - Architecture

## Design Philosophy

**Multiple Discord Bots, One Configurable Backend**

This project uses a unique architecture where each AI officer has their own Discord bot (for immersion and distinct personalities), but all bots share the same generic, configurable codebase. This provides:

1. **Immersion**: Each officer appears as a separate Discord user with their own name, avatar, and personality
2. **Maintainability**: One codebase to update, not six separate bot implementations
3. **Flexibility**: Easy to add new officers or customize existing ones via YAML configuration
4. **Open Source Friendly**: Users can create custom officers without writing code

## System Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                    Discord Server (EHA)                      │
│                                                               │
│  👤 Gen. Vance        👤 Lt. Col. Morrison    👤 Major Chen  │
│  (Bot Instance 1)     (Bot Instance 2)         (Bot Instance 3)│
└───────┬────────────────────┬──────────────────────┬──────────┘
        │                    │                      │
        │   Each bot uses the same generic code    │
        │   but loads different YAML configs       │
        │                    │                      │
┌───────▼────────────────────▼──────────────────────▼──────────┐
│              Generic Discord Bot (Shared Code)                │
│                                                               │
│  - Reads officer config from /officers/{id}.yml              │
│  - Connects to Discord with officer-specific token           │
│  - Forwards messages to n8n with officer context             │
│  - Handles rate limiting, errors, typing indicators          │
└───────────────────────────┬───────────────────────────────────┘
                            │
                    ┌───────┴────────┐
                    │                │
            ┌───────▼──────┐  ┌─────▼─────────┐
            │ n8n Workflow │  │  Claude API   │
            │              │  │               │
            │ Generic      │  │ Receives      │
            │ workflow     │  │ officer       │
            │ uses officer │  │ personality   │
            │ config to    │  │ from config   │
            │ build prompts│  │               │
            └──────┬───────┘  └───────────────┘
                   │
            ┌──────▼──────┐
            │  Database   │
            │             │
            │ - Stories   │
            │ - Missions  │
            │ - Officers  │
            └─────────────┘
```

## Component Breakdown

### 1. Officer Configuration Files (`/officers/*.yml`)

Each officer is defined by a YAML file that specifies:
- Identity (name, rank, role, callsign)
- Discord bot settings (token, channels, roles)
- n8n webhook configuration
- AI personality (background, traits, voice, examples)
- Operational parameters (capabilities, limitations, authority)
- Story generation settings (themes, tone, frequency)

**Example**: [officers/vance.yml](../officers/vance.yml)

### 2. Generic Discord Bot (`/discord-bot-officer/`)

A single, reusable Discord bot implementation that:
1. Loads officer configuration via `OFFICER_ID` environment variable
2. Connects to Discord using officer-specific token
3. Listens in officer-specific channels
4. Forwards messages to n8n with full officer context
5. Handles errors with officer-appropriate messaging

**Key Feature**: Same code runs for all officers - personality comes from config.

### 3. Generic n8n Workflow (`/n8n-workflows/generic-officer.json`)

A single n8n workflow that:
1. Receives webhook from Discord bot with officer context
2. Loads officer configuration from database or file
3. Builds Claude system prompt using officer personality template
4. Calls Claude API with officer-specific parameters
5. Returns response to Discord

**Key Feature**: Workflow is officer-agnostic - it uses provided configuration.

### 4. Database Schema (`/database/schema.sql`)

Stores:
- Officer configurations (can override file-based configs)
- Story arcs and missions
- Conversation history per officer
- Player interactions and statistics

Officers can be stored in database OR loaded from YAML files (or both).

## Deployment Models

### Model 1: Multiple Bot Instances (Recommended for Production)

Each officer runs as a separate Docker container:

```yaml
# docker-compose.yml
services:
  bot-vance:
    build: ./discord-bot-officer
    environment:
      OFFICER_ID: vance
      DISCORD_BOT_TOKEN: ${DISCORD_BOT_TOKEN_VANCE}

  bot-morrison:
    build: ./discord-bot-officer
    environment:
      OFFICER_ID: morrison
      DISCORD_BOT_TOKEN: ${DISCORD_BOT_TOKEN_MORRISON}
```

**Benefits**:
- Each officer can restart independently
- Easy to scale by adding/removing officers
- Clear separation in logs and monitoring

### Model 2: Single Bot Instance with Multi-Officer Support

One bot process manages multiple officers (advanced):

```yaml
services:
  bot-multi:
    build: ./discord-bot-officer
    environment:
      OFFICER_IDS: vance,morrison,chen
```

**Benefits**:
- Lower resource usage
- Simpler deployment for small setups

## Configuration Loading Priority

The system uses a cascading configuration approach:

1. **YAML File** (`/officers/{id}.yml`) - Base configuration
2. **Database Override** - Stored configurations (optional)
3. **Environment Variables** - Runtime overrides
4. **n8n Workflow Variables** - Workflow-specific settings

Example:
```
officers/vance.yml          (Base: formality_level: 9)
    ↓
Database (table: officers)  (Override: formality_level: 8)
    ↓
ENV: VANCE_FORMALITY=7      (Runtime: formality_level: 7)
    ↓
Final Config: formality_level = 7
```

## Communication Flow

### Typical Message Flow

1. **User sends message** in Discord channel
2. **Discord bot** (e.g., Gen. Vance instance) receives message
3. **Bot validates**: Is this in my active channels?
4. **Bot loads** officer configuration from `/officers/vance.yml`
5. **Bot forwards** to n8n webhook `/webhook/vance` with payload:
   ```json
   {
     "officer": { "id": "vance", "name": "Gen. Vance", ... },
     "message": { "content": "...", "author": "..." },
     "config": { "personality": {...}, "claude": {...} }
   }
   ```
6. **n8n workflow** receives webhook
7. **n8n builds** Claude system prompt using officer personality template
8. **n8n calls** Claude API with officer-specific parameters
9. **Claude responds** in character
10. **n8n sends** response back to Discord channel
11. **User sees** response from Gen. Vance bot

## Adding a New Officer

To add a new officer, you need:

1. **Create configuration file**: `officers/new-officer.yml`
2. **Create Discord bot**: In Discord Developer Portal
3. **Set environment variables**:
   ```bash
   DISCORD_BOT_TOKEN_NEWOFFICER=...
   DISCORD_CLIENT_ID_NEWOFFICER=...
   ```
4. **Add to docker-compose.yml**:
   ```yaml
   bot-newofficer:
     build: ./discord-bot-officer
     environment:
       OFFICER_ID: newofficer
   ```
5. **Deploy**: `docker-compose up -d bot-newofficer`

**That's it!** No code changes required.

## Benefits of This Architecture

### For Users
- ✅ Immersive multi-officer experience in Discord
- ✅ Each officer has distinct personality and purpose
- ✅ Easy to add custom officers for their own organization

### For Developers
- ✅ One codebase to maintain
- ✅ Changes apply to all officers simultaneously
- ✅ Easy to test (swap config files)
- ✅ Version control for personalities (YAML in git)

### For Open Source
- ✅ No hardcoded content specific to EHA
- ✅ Users can create officers for any setting (not just Star Citizen)
- ✅ Configuration is self-documenting
- ✅ Easy to contribute new officer templates

## Example Use Cases

### Military Organization (Default)
- Create officers with military ranks and formal communication
- Story arcs focused on missions and operations
- Example: EHA (Event Horizon Armada)

### Corporate Organization
- Create executives with business titles
- Story arcs focused on projects and quarterly goals
- Example: Tech startup with AI department heads

### Fantasy Guild
- Create guild officers with fantasy roles
- Story arcs focused on quests and adventures
- Example: D&D guild with AI dungeon masters

### Educational Institution
- Create professors with academic titles
- Story arcs focused on lessons and assignments
- Example: Virtual academy with AI instructors

## Technical Specifications

### Technologies Used
- **Node.js 18+**: Bot runtime
- **Discord.js**: Discord API wrapper
- **js-yaml**: YAML configuration parsing
- **n8n**: Workflow automation
- **Claude API**: AI personality engine
- **PostgreSQL**: Data persistence
- **Docker**: Containerization

### System Requirements
- **Per Bot Instance**: ~50MB RAM, minimal CPU
- **n8n**: ~200MB RAM
- **PostgreSQL**: ~100MB RAM
- **Total for 6 officers**: ~800MB RAM

### Scalability
- **Officers**: Tested up to 10 concurrent officers
- **Messages**: Rate-limited per officer (configurable)
- **Response Time**: ~1-3 seconds typical (depends on Claude API)

## Security Considerations

1. **Discord Tokens**: Stored in environment variables, never in config files
2. **API Keys**: Centralized in environment, not per-officer
3. **Rate Limiting**: Prevents abuse, configurable per officer
4. **Channel Restrictions**: Officers only respond in designated channels
5. **Role-Based Access**: Commander roles checked before certain operations

## Future Enhancements

- [ ] Web UI for creating/editing officer configurations
- [ ] Officer personality versioning and A/B testing
- [ ] Multi-language support via configuration
- [ ] Voice channel integration
- [ ] Cross-officer memory and coordination
- [ ] Community officer template marketplace
