# EHA Command Bots - Setup Guide

This guide will walk you through setting up the EHA Command Bots system from scratch.

## Prerequisites

Before you begin, ensure you have the following:

- **Node.js 18+** installed
- **n8n** (self-hosted or cloud instance)
- **Discord Bot** created in Discord Developer Portal
- **Claude API Key** from Anthropic
- **SQLite** (included with Node.js) or **PostgreSQL** for production

## Part 1: Discord Bot Setup

### 1.1 Create Discord Application

1. Go to [Discord Developer Portal](https://discord.com/developers/applications)
2. Click "New Application"
3. Name it "EHA Command Bots"
4. Go to the "Bot" section
5. Click "Add Bot"
6. Enable these **Privileged Gateway Intents**:
   - Message Content Intent
   - Server Members Intent (optional, for member tracking)
7. Copy the **Bot Token** (you'll need this later)

### 1.2 Invite Bot to Your Server

1. Go to "OAuth2" → "URL Generator"
2. Select scopes:
   - `bot`
   - `applications.commands`
3. Select bot permissions:
   - Read Messages/View Channels
   - Send Messages
   - Embed Links
   - Read Message History
4. Copy the generated URL and open it to invite the bot to your server

### 1.3 Create Officer Channels

In your Discord server, create dedicated channels for each officer:

- `#commander-hayes` - Commander Hayes channel
- `#xo-chen` - Executive Officer channel
- `#intel-rodriguez` - Intelligence Officer channel
- `#ops-barrett` - Operations Officer channel
- `#logistics-morrison` - Logistics Officer channel
- `#comms-singh` - Communications Officer channel
- `#mission-briefings` - General mission announcements

Right-click each channel and copy the Channel ID (enable Developer Mode in Discord settings first).

## Part 2: Claude API Setup

1. Sign up for [Anthropic Claude API](https://console.anthropic.com/)
2. Create an API key
3. Copy the key (starts with `sk-ant-`)

## Part 3: Database Setup

### 3.1 SQLite (Development)

SQLite is perfect for development and testing. No installation required.

```bash
# Initialize the database
cd database
sqlite3 eha_command.db < schema.sql
sqlite3 eha_command.db < seed-data.sql
```

### 3.2 PostgreSQL (Production)

For production, use PostgreSQL:

```bash
# Install PostgreSQL (Ubuntu/Debian)
sudo apt-get install postgresql postgresql-contrib

# Create database and user
sudo -u postgres psql
CREATE DATABASE eha_command;
CREATE USER eha_user WITH PASSWORD 'your_secure_password';
GRANT ALL PRIVILEGES ON DATABASE eha_command TO eha_user;
\q

# Initialize schema
psql -U eha_user -d eha_command -f database/schema.sql
psql -U eha_user -d eha_command -f database/seed-data.sql
```

## Part 4: Environment Configuration

1. Copy the example environment file:
```bash
cp .env.example .env
```

2. Edit `.env` with your configuration:

```bash
# Discord Configuration
DISCORD_BOT_TOKEN=your_bot_token_here
DISCORD_GUILD_ID=your_server_id
DISCORD_CLIENT_ID=your_bot_client_id

# Officer Channel IDs
CHANNEL_COMMANDER=123456789012345678
CHANNEL_XO=123456789012345678
CHANNEL_INTELLIGENCE=123456789012345678
CHANNEL_OPERATIONS=123456789012345678
CHANNEL_LOGISTICS=123456789012345678
CHANNEL_COMMUNICATIONS=123456789012345678

# Claude API
ANTHROPIC_API_KEY=sk-ant-your-key-here

# n8n Configuration
N8N_WEBHOOK_URL=http://localhost:5678
# For production:
# N8N_PROD_URL=https://your-n8n-instance.com

# Database
DATABASE_URL=./database/eha_command.db
# For PostgreSQL:
# DATABASE_URL=postgresql://eha_user:password@localhost:5432/eha_command
```

## Part 5: Discord Bot Installation

```bash
# Navigate to discord-bot directory
cd discord-bot

# Install dependencies
npm install

# Test the bot
npm start
```

You should see:
```
✅ Bot logged in as EHA Command Bots#1234
📡 Monitoring 1 server(s)
🔗 n8n webhook URL: http://localhost:5678
🚀 EHA Command Bots Discord handler ready
```

## Part 6: n8n Setup

### 6.1 Install n8n (Self-Hosted)

**Option A: Using npm**
```bash
npm install -g n8n
n8n start
```

**Option B: Using Docker**
```bash
docker run -it --rm \
  --name n8n \
  -p 5678:5678 \
  -v ~/.n8n:/home/node/.n8n \
  n8nio/n8n
```

**Option C: WSL Installation (Windows)**
```bash
# In WSL terminal
curl -fsSL https://deb.nodesource.com/setup_18.x | sudo -E bash -
sudo apt-get install -y nodejs
npm install -g n8n
n8n start
```

### 6.2 Import Workflows

1. Open n8n at `http://localhost:5678`
2. Click "Import from File" or "Workflows" → "Import"
3. Import `n8n-workflows/officers/commander.json`
4. Configure credentials:
   - Add Anthropic API credentials
   - Add Discord webhook URL

### 6.3 Configure Workflow

1. Open the imported "Commander Hayes" workflow
2. Click on "Call Claude API" node
3. Add credentials:
   - Name: Anthropic API Key
   - Header Name: `x-api-key`
   - Header Value: Your Claude API key
4. Update Discord webhook URL in "Send to Discord" node
5. Activate the workflow

## Part 7: Testing

### 7.1 Test Discord Bot

1. Go to your Discord server
2. Navigate to `#commander-hayes` channel
3. Send a message: "Commander, what's our current status?"
4. The bot should forward this to n8n

### 7.2 Test n8n Workflow

1. Check n8n executions panel for the webhook trigger
2. Verify Claude API call was successful
3. Check that response was sent back to Discord

### 7.3 End-to-End Test

Send a message in a commander channel and verify:
- Discord bot receives the message
- n8n workflow triggers
- Claude generates a response in-character as Commander Hayes
- Response appears in Discord channel

## Part 8: Production Deployment

### 8.1 Deploy Discord Bot

**Option A: VPS/Cloud Server**
```bash
# Use PM2 for process management
npm install -g pm2
cd discord-bot
pm2 start index.js --name eha-discord-bot
pm2 save
pm2 startup
```

**Option B: Docker**
```dockerfile
FROM node:18-alpine
WORKDIR /app
COPY discord-bot/package*.json ./
RUN npm install --production
COPY discord-bot/ ./
CMD ["node", "index.js"]
```

### 8.2 Deploy n8n

Consider using:
- [n8n Cloud](https://n8n.io/cloud/) (easiest)
- Self-hosted on VPS with Docker
- Railway, Render, or similar platforms

## Troubleshooting

### Bot won't start
- Check `.env` file exists and has correct values
- Verify Discord bot token is valid
- Ensure bot has been invited to server

### n8n workflow not triggering
- Verify webhook URL in Discord bot matches n8n webhook
- Check n8n is running and accessible
- Look at n8n execution logs for errors

### Claude API errors
- Verify API key is correct
- Check API key has sufficient credits
- Ensure request format matches Claude API requirements

### Database errors
- Verify database file exists (SQLite) or server is running (PostgreSQL)
- Check database permissions
- Ensure schema has been initialized

## Next Steps

Once basic setup is complete:

1. Import additional officer workflows
2. Configure officer personalities in database
3. Test inter-officer communication
4. Create your first story arc
5. Generate initial missions

See [WORKFLOW-GUIDE.md](./WORKFLOW-GUIDE.md) for workflow development.
See [STORY-DESIGN.md](./STORY-DESIGN.md) for creating story arcs.
