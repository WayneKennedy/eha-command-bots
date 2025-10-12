# EHA Officer Bot - Generic Configurable Discord Bot

Generic Discord bot for EHA AI Officers. Loads personality and behavior from YAML configuration files.

## Features

- **Configurable via YAML** - No code changes needed to add new officers
- **Knowledge Base Integration** - Officers stay canon-compliant with Star Citizen universe
- **Multiple Bot Support** - Run multiple officers from same codebase
- **n8n Integration** - Forwards messages to n8n workflow for AI processing

## Quick Start

### 1. Install Dependencies

```bash
npm install
```

### 2. Set Environment Variables

Create a `.env` file in the project root:

```bash
# Officer to load (matches YAML filename in /officers/)
OFFICER_ID=vance

# Discord credentials (matches token_env in YAML)
DISCORD_BOT_TOKEN_VANCE=your_bot_token_here
DISCORD_CLIENT_ID_VANCE=your_client_id_here
DISCORD_GUILD_ID=your_guild_id_here

# n8n webhook
N8N_WEBHOOK_URL=http://localhost:5678

# Optional: Channel restrictions
CHANNEL_GENERAL_VANCE=channel_id_here
CHANNEL_COMMAND_BRIEFING=channel_id_here

# Debug mode
DEBUG_MODE=false
```

### 3. Run the Bot

```bash
npm start
```

## Environment Variables

| Variable | Description | Required |
|----------|-------------|----------|
| `OFFICER_ID` | Officer config to load (e.g., `vance`) | Yes |
| `DISCORD_BOT_TOKEN_{OFFICER}` | Discord bot token | Yes |
| `DISCORD_CLIENT_ID_{OFFICER}` | Discord application ID | Yes |
| `DISCORD_GUILD_ID` | Discord server ID | Yes |
| `N8N_WEBHOOK_URL` | n8n base URL | Yes |
| `DEBUG_MODE` | Enable debug logging | No |

## Adding a New Officer

1. Create YAML config: `/officers/new-officer.yml`
2. Create Discord bot in Discord Developer Portal
3. Set environment variables
4. Run: `OFFICER_ID=newofficer npm start`

No code changes needed!

## Documentation

- Full README: `/docs/ARCHITECTURE.md`
- Officer schema: `/officers/officer-config-schema.md`
- Knowledge base: `/knowledge-base/README.md`

**Version**: 2.0.0
