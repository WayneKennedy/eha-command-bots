# EHA Command Bots

## Project Overview

AI-powered command officers for a space military simulation (MILSIM) organization, built with n8n workflows and Claude API. These autonomous officers interact with org members via Discord to generate evolving story arcs, issue mission briefs, and maintain an immersive command structure.

## Concept

Instead of static scripted missions, this system creates a **living command hierarchy** where AI officers:

- **Generate dynamic storylines** - Long-running narrative arcs that evolve based on player actions and mission outcomes
- **Issue mission briefs** - Regular operations tailored to the current story state and player capabilities
- **Role-play command positions** - Each officer has a distinct personality, specialty, and command style
- **Coordinate between roles** - Officers communicate and collaborate to maintain story coherence
- **Respond to player interactions** - Handle questions, debrief completions, and adapt to player decisions

## Architecture

```
┌─────────────────────────────────────────────┐
│            Discord Interface                 │
│  - Mission briefs                            │
│  - Officer interactions                      │
│  - Player communications                     │
└──────────────┬──────────────────────────────┘
               │
       ┌───────┴────────┐
       │                │
┌──────▼──────┐  ┌─────▼────────┐
│     n8n     │  │  Claude API   │
│  Workflows  │  │   - Story gen │
│             │  │   - Responses │
│  - Officer  │  │   - Planning  │
│    logic    │  └───────────────┘
│  - Story    │
│    state    │  ┌───────────────┐
│  - Mission  │  │   Database    │
│    triggers │◄─┤   - Story     │
│             │  │   - Missions  │
└─────────────┘  │   - Players   │
                 └───────────────┘
```

### Technology Stack

- **n8n**: Workflow automation engine (primary logic layer)
- **Claude API**: AI-powered officer intelligence and narrative generation
- **Discord**: User interface and interaction platform
- **Database**: Story state, mission tracking, player data (SQLite/PostgreSQL)
- **Minimal Discord.js**: Lightweight bot for webhook/event handling only

## Command Structure

### Proposed Officer Roles

Each officer is an autonomous n8n workflow with distinct personality and responsibilities:

1. **Commander (CO)** - Overall strategic direction, high-level story decisions
2. **Executive Officer (XO)** - Day-to-day operations, coordinates other officers
3. **Intelligence Officer (S2)** - Enemy analysis, threat briefings, recon missions
4. **Operations Officer (S3)** - Mission planning, tactical operations, combat missions
5. **Logistics Officer (S4)** - Supply missions, resource management, base operations
6. **Communications Officer** - Information warfare, signals intelligence, hacking ops

### Officer Interaction Model

- Each officer has a dedicated Discord channel or thread
- Officers can "talk" to each other (n8n workflow triggers)
- Story state is shared across all officers via database
- Mission generation considers current arc, player stats, and officer specialties

## File Structure

```
/eha-command-bots
├── n8n-workflows/
│   ├── officers/
│   │   ├── commander.json
│   │   ├── executive-officer.json
│   │   ├── intelligence-officer.json
│   │   ├── operations-officer.json
│   │   ├── logistics-officer.json
│   │   └── comms-officer.json
│   ├── story/
│   │   ├── arc-generator.json
│   │   ├── mission-creator.json
│   │   └── event-trigger.json
│   └── shared/
│       ├── discord-sender.json
│       └── state-manager.json
├── discord-bot/
│   ├── index.js (minimal webhook handler)
│   └── config.js
├── prompts/
│   ├── officer-personalities/
│   │   ├── commander.md
│   │   ├── xo.md
│   │   └── ...
│   ├── story-generation/
│   │   ├── arc-template.md
│   │   └── mission-template.md
│   └── system-prompts/
├── database/
│   ├── schema.sql
│   └── seed-data.sql
├── docs/
│   ├── SETUP.md
│   ├── WORKFLOW-GUIDE.md
│   └── STORY-DESIGN.md
└── utils/
    └── helpers.js
```

## Current Status

**Version**: 0.1.0-alpha
**Status**: Phase 1 Complete - Ready for Phase 2

### What's Implemented

**Database Layer**: Complete SQL schema with 9 tables tracking story arcs, missions, officers, players, events, communications, and workflow executions. Includes indexes, views, and seed data with the initial "Vanaar Incursion" story arc.

**Officer Personalities**: Six fully-developed officers with detailed backgrounds, distinct voices, and current story context:
- Commander Hayes - Strategic CO ("The Iron Hand")
- Lt. Commander Chen - Operational XO
- Major Barrett - Tactical Operations ("The Hammer")
- Lt. Rodriguez - Intelligence ("The Oracle")
- Captain Morrison - Logistics ("The Quartermaster")
- Lt. Singh - Communications/Cyber ("Ghost")

**Discord Bot**: Minimal bot implementation focused on webhook handling, message routing to n8n, conversation state tracking, and environment-based configuration.

**n8n Workflows**: Commander Hayes prototype workflow with Discord webhook trigger, Claude API integration, personality-driven responses, and Discord message delivery.

**Documentation**: Comprehensive setup guide covering Discord bot creation, Claude API setup, database initialization, n8n workflow import, and troubleshooting.

### Phase 1: Foundation ✅ COMPLETED
- [x] Project structure setup
- [x] Database schema design (9 tables with indexes and views)
- [x] Officer personality definitions (all 6 officers)
- [x] Basic Discord bot skeleton
- [x] First n8n workflow prototype (Commander Hayes)

### Phase 2: Core Officers (Next)
- [x] Commander workflow
- [ ] XO workflow
- [ ] Operations Officer workflow
- [ ] Intelligence Officer workflow
- [ ] Logistics Officer workflow
- [ ] Communications Officer workflow
- [ ] Story arc generator
- [ ] Mission creation system
- [ ] Inter-officer communication

### Phase 3: Story Engine
- [ ] Dynamic arc generation
- [ ] Mission outcome tracking
- [ ] Player action responses
- [ ] Story state persistence
- [ ] Arc progression triggers

### Phase 4: Enhancement
- [ ] All officer roles implemented
- [ ] Complex multi-officer coordination
- [ ] Player statistics and adaptation
- [ ] Emergency/special event system
- [ ] Debrief and feedback loops

## Development Setup

### Prerequisites
- **n8n** (local WSL installation for development)
- **Node.js** 18+ (for minimal Discord bot)
- **Discord Bot Token** (from Discord Developer Portal)
- **Claude API Key** (Anthropic)
- **Database** (SQLite for dev, PostgreSQL for production)

### Installation

1. Clone the repository:
```bash
git clone https://github.com/WayneKennedy/eha-command-bots.git
cd eha-command-bots
```

2. Install Discord bot dependencies:
```bash
cd discord-bot
npm install
```

3. Set up environment variables:
```bash
cp .env.example .env
# Edit .env with your API keys and configuration
```

4. Initialize database:
```bash
cd database
sqlite3 eha_command.db < schema.sql
sqlite3 eha_command.db < seed-data.sql
```

5. Import n8n workflows:
```bash
# Import workflow JSON files into your local n8n instance
# Start with n8n-workflows/officers/commander.json
# See docs/SETUP.md for detailed instructions
```

6. Start the Discord bot:
```bash
cd discord-bot
npm start
```

### n8n Development Workflow

- Develop workflows locally in WSL n8n
- Export workflows as JSON and commit to `/n8n-workflows`
- Test in development Discord server
- Promote stable workflows to hosted n8n for production

## Configuration

Key environment variables (`.env`):

```bash
# Discord
DISCORD_BOT_TOKEN=your_discord_bot_token
DISCORD_GUILD_ID=your_server_id

# Claude API
ANTHROPIC_API_KEY=your_claude_api_key

# n8n
N8N_WEBHOOK_URL=http://localhost:5678
N8N_PROD_URL=https://your-hosted-n8n.com

# Database
DATABASE_URL=postgresql://user:pass@host:5432/eha_command

# Story Configuration
STORY_ARC_LENGTH_DAYS=30
MISSION_FREQUENCY_HOURS=72
```

## Story & Mission Design Philosophy

### Dynamic Story Arcs

- **Duration**: 30-90 day story arcs with major plot points
- **Branching**: Player actions influence story direction
- **Coherence**: Officers maintain consistent narrative across interactions
- **Escalation**: Tension builds toward arc climax, then resets with new arc

### Mission Generation

- **Variety**: Combat, stealth, logistics, intel gathering, special ops
- **Difficulty**: Adapts based on player performance and participation
- **Integration**: Each mission advances current story arc
- **Frequency**: Regular cadence (e.g., 2-3 missions per week)

### Officer Personalities

Each officer has a complete personality definition including:
- **Background**: Military history, specialties, quirks, and nicknames
- **Voice**: Distinct communication style and vocabulary
- **Relationships**: Dynamics with other officers
- **Decision-making**: Preferences for mission types and tactics
- **Story Context**: Current perspective on the active story arc

See [prompts/officer-personalities/](prompts/officer-personalities/) for detailed definitions of all 6 officers.

## Contributing

This is an open-source project. Contributions welcome!

### How to Contribute

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-officer`)
3. Commit your changes (`git commit -m 'Add new Intel officer behavior'`)
4. Push to the branch (`git push origin feature/amazing-officer`)
5. Open a Pull Request

### Development Guidelines

- Keep Discord bot code minimal - logic belongs in n8n
- Document all workflow changes
- Test officer interactions for consistency
- Maintain story coherence across changes
- Use descriptive commit messages

## License

[To be determined - suggest MIT or Apache 2.0 for open source]

## Roadmap

### Near Term
- ✅ Complete Phase 1 foundation
- Deploy first working officer (Commander Hayes)
- Complete Phase 2 officer workflows
- Run alpha test with small player group

### Medium Term
- All core officers operational
- Advanced story generation with branching
- Player statistics and adaptive difficulty
- Mission outcome analysis and story impact

### Long Term
- Community-contributed officer templates
- Multi-org support (different story universes)
- Web dashboard for story/mission management
- Integration with other space sim tools

## Resources

- **n8n Documentation**: https://docs.n8n.io
- **Claude API Docs**: https://docs.anthropic.com
- **Discord.js Guide**: https://discordjs.guide

## Acknowledgments

Built for the space MILSIM community. Special thanks to org members who playtest and provide feedback.

---

**Last Updated**: October 10, 2025
**Version**: 0.1.0-alpha
**Status**: Active Development