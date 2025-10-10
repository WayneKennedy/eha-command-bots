# EHA Command Bots

## Project Overview

AI-powered command officers for **Event Horizon Armada (EHA)**, a Star Citizen private military company, built with n8n workflows and Claude API. These autonomous AI officers work alongside real commanders to generate evolving story arcs, issue mission briefs, and maintain an immersive command structure for the org.

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

### Real EHA Leadership (Human Commanders)

EHA is led by three founding Commanders who each lead a division:

| Rank | Callsign | Name | Focus Area | Division |
|------|----------|------|------------|----------|
| **Commander** | NEXUS 1 | Atlay | Logistics and Engineering | Nexus Logistics Corps |
| **Commander** | BRAVO 1 | Hunter | Foot Combat | Morozov Battalion |
| **Commander** | ~~WALKER 1~~ | ~~Psykes~~ (Resigned) | Ship Combat | VoidWalkers |

### AI Officer Structure

AI officers augment the real command structure with two tiers:

#### High Command (AI - Strategic/Story Authority)
**General (O-10) - Fleet Commander** - Top-level AI officer who sets strategic objectives and story arcs that all three real Commanders follow. Maintains overarching narrative and coordinates between divisions.

#### Division Support Officers (AI - Tactical/Operational)

**For Nexus Logistics Corps:**
- **Lt. Colonel (AI) - Logistics Operations** - Supply chain missions, engineering projects, resource management

**For Morozov Battalion:**
- **Lt. Colonel (AI) - Tactical Operations** - Combat mission planning, training exercises, ground operations

**For VoidWalkers:**
- **Lt. Colonel (AI) - Flight Operations** - Ship combat missions, fleet coordination, space operations

#### Specialized Staff Officers (AI - Cross-Division Support)

- **Lt. Colonel (AI) - Intelligence Officer** - Intel analysis, threat briefings, reconnaissance missions (supports all divisions)
- **Major (AI) - Communications Officer** - Signals intel, cyber ops, information warfare (supports all divisions)

Additional Lt. Commander positions may be filled for:
- Search & Rescue
- Dropship Operations
- Vehicle Combat
- Recon

### Officer Interaction Model

- AI High Command (General) issues strategic directives and story arcs
- Real Commanders receive orders and direct their divisions
- AI Division Officers provide tactical mission support to their respective Commanders
- AI Staff Officers provide cross-division intelligence and communications support
- All officers can communicate and coordinate through Discord channels
- Story state is shared across all officers via database

## File Structure

```
/eha-command-bots
├── .github/
│   └── workflows/
│       └── deploy.yml (GitHub Actions CI/CD)
├── n8n-workflows/
│   ├── officers/
│   │   ├── fleet-commander.json (General - High Command)
│   │   ├── logistics-operations.json (Lt. Col - Nexus)
│   │   ├── tactical-operations.json (Lt. Col - Morozov)
│   │   ├── flight-operations.json (Lt. Col - VoidWalkers)
│   │   ├── intelligence-officer.json (Lt. Col - Staff)
│   │   └── communications-officer.json (Major - Staff)
│   ├── story/
│   │   ├── arc-generator.json
│   │   ├── mission-creator.json
│   │   └── event-trigger.json
│   └── shared/
│       ├── discord-sender.json
│       └── state-manager.json
├── discord-bot-general-vance/
│   ├── index.js (Discord bot for Gen. Vance)
│   ├── config.js
│   ├── package.json
│   └── Dockerfile
├── prompts/
│   ├── officer-personalities/
│   │   ├── fleet-commander.md (General Vance)
│   │   ├── logistics-operations.md (Lt. Col Morrison)
│   │   ├── tactical-operations.md (Lt. Col Van Der Merwe)
│   │   ├── flight-operations.md (Lt. Col Reeves)
│   │   ├── intelligence-officer.md (Lt. Col Singh)
│   │   └── communications-officer.md (Major Chen)
│   ├── story-generation/
│   │   ├── arc-template.md
│   │   └── mission-template.md
│   └── system-prompts/
├── database/
│   ├── schema.sql
│   └── seed-data.sql
├── docs/
│   ├── VPS-SETUP-HOSTINGER.md (Production VPS setup)
│   ├── DISCORD-BOT-SETUP-WSL.md (Local development)
│   ├── DISCORD-BOT-SETUP-SIMPLIFIED.md
│   ├── EHA-HISTORY.md
│   ├── EHA-HISTORY-RSI-FORMAT.txt
│   ├── EHA-MANIFESTO-RSI-FORMAT.txt
│   └── EHA-CHARTER-RSI-FORMAT.txt
├── scripts/
│   └── deploy.sh (Manual deployment script)
├── docker-compose.yml (Production stack)
├── DEPLOYMENT.md (Deployment guide)
└── .env.example
```

## Current Status

**Version**: 0.1.0-alpha
**Status**: Phase 1.5 Complete - Deployment Ready

### What's Implemented

**Database Layer**: Complete SQL schema with 9 tables tracking story arcs, missions, officers, players, events, communications, and workflow executions. Includes indexes, views, and seed data with the "Operation: Crimson Dawn" story arc (Star Citizen themed).

**Officer Personalities**: Six fully-developed AI officers aligned with EHA's structure:
- **General Vance** - Fleet Commander (High Command - Story Authority)
- **Lt. Colonel Morrison** - Logistics Operations (Nexus Logistics Corps support)
- **Lt. Colonel Van Der Merwe** - Tactical Operations (Morozov Battalion support)
- **Lt. Colonel Reeves** - Flight Operations (VoidWalkers support)
- **Lt. Colonel Singh** - Intelligence Officer (Cross-division intelligence)
- **Major Chen** - Communications Officer (Cross-division cyber/comms)

**Discord Bot (Gen. Vance)**: Production-ready Discord bot with webhook handling, n8n integration, conversation state tracking, and Docker containerization.

**Production Deployment**: Complete Docker Compose stack with PostgreSQL, n8n, and Gen. Vance bot. Automated CI/CD via GitHub Actions deploying to Hostinger VPS (£8/month).

**Documentation**:
- Discord bot setup guides (WSL and simplified)
- VPS setup guide for Hostinger Ubuntu 22.04
- Complete deployment documentation
- RSI landing page content (History, Manifesto, Charter)

### Phase 1: Foundation ✅ COMPLETED
- [x] Project structure setup
- [x] Database schema design (9 tables with indexes and views)
- [x] Initial officer personality definitions (6 AI officers)
- [x] Basic Discord bot skeleton
- [x] First n8n workflow prototype (Fleet Commander)

### Phase 1.5: EHA Alignment ✅ COMPLETED
- [x] Update officer personalities for EHA structure and Star Citizen universe
- [x] Revise database schema for EHA divisions and real commanders
- [x] Update Fleet Commander workflow with proper rank and authority
- [x] Create story arcs aligned with Star Citizen lore
- [x] Create RSI landing page content (History, Manifesto, Charter)
- [x] Docker + GitHub Actions CI/CD deployment system

### Phase 2: Core Officers (Next)
- [x] Fleet Commander workflow (General - High Command)
- [ ] Logistics Operations workflow (Lt. Col - Nexus)
- [ ] Tactical Operations workflow (Lt. Col - Morozov)
- [ ] Flight Operations workflow (Lt. Col - VoidWalkers)
- [ ] Intelligence Officer workflow (Lt. Col - Staff)
- [ ] Communications Officer workflow (Major - Staff)
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

## Deployment

### Production Deployment (Recommended)

**Platform**: Hostinger KVM 2 VPS (£8/month) with Ubuntu 22.04 LTS

**Deployment Method**: Automated CI/CD via GitHub Actions

Every push to `main` automatically deploys to production. See [DEPLOYMENT.md](DEPLOYMENT.md) for complete deployment guide.

#### Quick Start

1. **Provision VPS**: Sign up for Hostinger KVM 2, select Ubuntu 22.04 LTS
2. **Follow Setup Guide**: Complete [docs/VPS-SETUP-HOSTINGER.md](docs/VPS-SETUP-HOSTINGER.md)
3. **Configure GitHub Secrets**: Add all required secrets to repository settings
4. **Push to Deploy**: `git push origin main` triggers automatic deployment

**Services Running**:
- PostgreSQL (database) - Internal only
- n8n (workflow engine) - `http://your-vps-ip:5678`
- Gen. Vance Bot - Discord (always online)

### Cost Breakdown

- **Monthly**: £8 (Hostinger KVM 2)
- **Yearly**: £96 + ~£10 domain (optional)
- **Claude API**: Pay-as-you-go (estimated £5-15/month depending on usage)

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

Each AI officer has a complete personality definition including:
- **Background**: Military history, specialties, and command style
- **Voice**: Distinct communication style appropriate to rank and role
- **Relationships**: Dynamics with real commanders and other AI officers
- **Decision-making**: Strategic or tactical preferences based on role
- **Story Context**: Current perspective on active story arcs
- **Authority Level**: Clear delineation of AI vs real commander authority

The AI officers serve the real EHA commanders (Atlay, Hunter, and future VoidWalkers commander) and help maintain immersive gameplay through mission briefings, story progression, and operational support.

See [prompts/officer-personalities/](prompts/officer-personalities/) for detailed definitions of all 6 AI officers.

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
- ✅ Complete Phase 1.5 EHA alignment
- ✅ Production deployment system (Docker + GitHub Actions)
- Deploy first working officer (General Vance)
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