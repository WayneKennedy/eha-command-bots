# Discord Bot Setup - Quick Start Guide

This simplified guide walks you through setting up the Discord bot for Gen. Vance. The code is already created - you just need to configure Discord and add your credentials.

## What's Already Done ✅

The bot code files are already in `discord-bot-general-vance/`:
- ✅ `index.js` - Main bot code
- ✅ `config.js` - Configuration
- ✅ `package.json` - Dependencies

You just need to:
1. Create the Discord application
2. Create your `.env` file with credentials
3. Install dependencies and run

---

## Step 1: Create Discord Application

### 1.1 Go to Discord Developer Portal
1. Visit https://discord.com/developers/applications
2. Log in with your Discord account
3. Click **"New Application"**
4. Name it: `Gen. Vance`
5. Click **"Create"**

### 1.2 Create Bot User
1. In left sidebar, click **"Bot"**
2. Click **"Add Bot"**
3. Confirm **"Yes, do it!"**

### 1.3 Enable Required Intents (IMPORTANT!)
1. Scroll to **"Privileged Gateway Intents"**
2. Enable these three:
   - ✅ **PRESENCE INTENT**
   - ✅ **SERVER MEMBERS INTENT**
   - ✅ **MESSAGE CONTENT INTENT** ← **Critical!**
3. Click **"Save Changes"**

### 1.4 Copy Bot Token
1. Scroll to **"TOKEN"** section
2. Click **"Reset Token"** (or "Copy" if first time)
3. Click **"Copy"**
4. **Save this somewhere temporarily** - you'll add it to `.env` next
5. ⚠️ **NEVER share this token publicly!**

### 1.5 Get Application ID
1. In left sidebar, click **"OAuth2"** → **"General"**
2. Copy the **"CLIENT ID"**
3. Save this too - you'll need it for `.env`

---

## Step 2: Set Bot Permissions

### 2.1 Generate Invite URL
1. In left sidebar, click **"OAuth2"** → **"URL Generator"**
2. Under **"SCOPES"**, check:
   - ✅ `bot`
   - ✅ `applications.commands`
3. Under **"BOT PERMISSIONS"**, check:
   - ✅ View Channels
   - ✅ Send Messages
   - ✅ Send Messages in Threads
   - ✅ Embed Links
   - ✅ Read Message History
   - ✅ Add Reactions

### 2.2 Invite Bot to Your Server
1. Scroll down and copy the **"GENERATED URL"**
2. Open that URL in a new tab
3. Select your **EHA Discord server**
4. Click **"Continue"** → **"Authorize"**
5. Complete CAPTCHA if prompted

### 2.3 Verify Bot Added
1. Go to your Discord server
2. Check member list - you should see **"Gen. Vance"** with a BOT tag (offline/gray)
3. This is normal - bot isn't running yet

---

## Step 3: Create .env File

### 3.1 Copy the Example File
In the **project root** directory (eha-command-bots), create a new file called `.env`:

**Windows:**
```bash
copy .env.example .env
```

**Mac/Linux:**
```bash
cp .env.example .env
```

### 3.2 Edit .env File
Open `.env` in your editor and fill in these values:

```bash
# Discord Configuration
DISCORD_GUILD_ID=your_server_id_here

# Gen. Vance Discord Bot
DISCORD_BOT_TOKEN_VANCE=paste_bot_token_here
DISCORD_CLIENT_ID_VANCE=paste_application_id_here
CHANNEL_GENERAL_VANCE=
CHANNEL_COMMAND_BRIEFING=

# Claude API (you'll need this later for n8n)
ANTHROPIC_API_KEY=your_claude_api_key_here

# n8n Configuration
N8N_WEBHOOK_URL=http://localhost:5678

# Bot Settings
DEBUG_MODE=true
RESPONSE_DELAY_MS=1500
```

### 3.3 Get Discord IDs

**To get your Server ID (DISCORD_GUILD_ID):**
1. In Discord, go to User Settings → Advanced
2. Enable **"Developer Mode"**
3. Right-click your server name → **"Copy Server ID"**
4. Paste into `.env` as `DISCORD_GUILD_ID`

**To get Channel IDs:**
1. Create a channel called `#gen-vance` (or use existing)
2. Right-click the channel → **"Copy Channel ID"**
3. Paste into `.env` as `CHANNEL_GENERAL_VANCE`

---

## Step 4: Install Dependencies

```bash
cd discord-bot-general-vance
npm install
```

This installs:
- discord.js (Discord API)
- dotenv (environment variables)
- node-fetch (HTTP requests to n8n)

---

## Step 5: Test the Bot

```bash
npm start
```

You should see:
```
🔐 Logging in Gen. Vance...
✅ General Vance online
📡 Rank: General
🎯 Role: Fleet Commander
📻 Callsign: Horizon Actual
🔗 n8n webhook: http://localhost:5678/webhook/general-vance
🚀 General Vance ready for operations
```

In Discord, Gen. Vance should now show **online** (green dot)!

---

## Step 6: Test Message Handling

1. Go to your `#gen-vance` channel in Discord
2. Send a message: "General, requesting status report"
3. You should see Gen. Vance show "typing..."
4. Check the bot terminal - you'll see debug output showing the message was received

**Note:** The bot won't respond yet because n8n workflow isn't set up. That's the next step!

---

## Troubleshooting

**Bot shows offline:**
- Verify bot token is correct in `.env`
- Check that Message Content Intent is enabled
- Make sure the bot is actually running (check terminal)

**Bot doesn't respond to messages:**
- Verify channel IDs are correct in `.env`
- Check that Developer Mode is enabled to copy IDs
- Look at terminal for error messages

**Permission errors:**
- Check bot has proper permissions in server
- Verify bot role is high enough in role hierarchy

**Can't find .env file:**
- The `.env` file is in the **root** directory (`eha-command-bots/`), not in `discord-bot-general-vance/`
- It's hidden by default - make sure to show hidden files in your editor
- Create it by copying `.env.example` if it doesn't exist

---

## Next Steps

Once Gen. Vance is running:
1. ✅ Bot receives messages
2. ⏭️ Set up n8n workflow to process messages with Claude AI
3. ⏭️ Configure personality responses
4. ⏭️ Test end-to-end conversation

---

## Summary of Files

```
eha-command-bots/
├── .env                          ← YOU CREATE THIS (secrets, not in git)
├── .env.example                  ← Template (in git)
└── discord-bot-general-vance/
    ├── index.js                  ← Bot code (already created)
    ├── config.js                 ← Configuration (already created)
    ├── package.json              ← Dependencies (already created)
    └── README.md                 ← Documentation (already created)
```

**Key Point:** `.env` goes in the **root directory**, contains your secrets, and is **NOT committed to git**.
