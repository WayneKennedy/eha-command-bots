# Discord Bot Setup - WSL Guide

This guide walks you through setting up Gen. Vance Discord bot in WSL (Windows Subsystem for Linux), where your n8n instance is already running.

## Prerequisites

- ✅ WSL installed and running
- ✅ n8n running in WSL
- ✅ Discord Developer Portal access

---

## Part 1: Create Discord Application

### Step 1: Go to Discord Developer Portal
1. Visit https://discord.com/developers/applications (in Windows browser)
2. Log in with your Discord account
3. Click **"New Application"**
4. Name it: `Gen. Vance`
5. Click **"Create"**

### Step 2: Create Bot User
1. In left sidebar, click **"Bot"**
2. Click **"Add Bot"**
3. Confirm **"Yes, do it!"**

### Step 3: Enable Required Intents (CRITICAL!)
1. Scroll to **"Privileged Gateway Intents"**
2. Enable these three:
   - ✅ **PRESENCE INTENT**
   - ✅ **SERVER MEMBERS INTENT**
   - ✅ **MESSAGE CONTENT INTENT** ← **Must enable this!**
3. Click **"Save Changes"**

### Step 4: Copy Bot Token
1. Scroll to **"TOKEN"** section
2. Click **"Reset Token"** (or "Copy" if first time)
3. Click **"Copy"**
4. **Save this somewhere temporarily** - you'll add it to `.env` next
5. ⚠️ **NEVER share this token publicly!**

### Step 5: Get Application ID
1. In left sidebar, click **"OAuth2"** → **"General"**
2. Copy the **"CLIENT ID"**
3. Save this too - you'll need it for `.env`

---

## Part 2: Set Bot Permissions & Invite

### Step 6: Generate Invite URL
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

### Step 7: Invite Bot to Your Server
1. Scroll down and copy the **"GENERATED URL"**
2. Open that URL in a new tab
3. Select your **EHA Discord server**
4. Click **"Continue"** → **"Authorize"**
5. Complete CAPTCHA if prompted

### Step 8: Verify Bot Added
1. Go to your Discord server
2. Check member list - you should see **"Gen. Vance"** with a BOT tag (offline/gray)
3. This is normal - bot isn't running yet

---

## Part 3: Setup in WSL

### Step 9: Open WSL Terminal
Open your WSL terminal (Ubuntu, Debian, etc.)

### Step 10: Navigate to Project
```bash
# Navigate to your Windows project folder from WSL
cd /mnt/c/Users/wkenn/git/eha-command-bots
```

**Note:** Windows drives are mounted at `/mnt/` in WSL:
- `C:\Users\wkenn\...` becomes `/mnt/c/Users/wkenn/...`
- `D:\` becomes `/mnt/d/`

### Step 11: Check/Install Node.js in WSL

Check if Node.js is installed:
```bash
node --version
npm --version
```

If you see version numbers (like `v20.10.0` and `10.2.3`), **skip to Step 12**.

If not installed, install Node.js:
```bash
# Install Node.js 20.x LTS
curl -fsSL https://deb.nodesource.com/setup_20.x | sudo -E bash -
sudo apt-get install -y nodejs

# Verify installation
node --version
npm --version
```

### Step 12: Create .env File

The `.env` file goes in the **project root** (not in discord-bot-general-vance folder):

```bash
# Still in /mnt/c/Users/wkenn/git/eha-command-bots
cp .env.example .env
```

### Step 13: Edit .env File

You can edit from WSL:
```bash
nano .env
```

Or from Windows (easier - use VS Code, Notepad++, etc.) and edit:
`C:\Users\wkenn\git\eha-command-bots\.env`

Add these values:

```bash
# Discord Configuration
DISCORD_GUILD_ID=your_server_id_here

# Gen. Vance Discord Bot
DISCORD_BOT_TOKEN_VANCE=paste_your_bot_token_here
DISCORD_CLIENT_ID_VANCE=paste_your_client_id_here
CHANNEL_GENERAL_VANCE=paste_channel_id_here
CHANNEL_COMMAND_BRIEFING=

# Claude API
ANTHROPIC_API_KEY=your_claude_api_key_here

# n8n Configuration
N8N_WEBHOOK_URL=http://localhost:5678

# Bot Settings
DEBUG_MODE=true
RESPONSE_DELAY_MS=1500
```

### Step 14: Get Discord IDs

**To get Server ID (DISCORD_GUILD_ID):**
1. In Discord (Windows), go to User Settings → Advanced
2. Enable **"Developer Mode"**
3. Right-click your server name → **"Copy Server ID"**
4. Paste into `.env`

**To get Channel IDs:**
1. Create channel `#gen-vance` in Discord (if not exists)
2. Right-click the channel → **"Copy Channel ID"**
3. Paste into `.env` as `CHANNEL_GENERAL_VANCE`

Save the `.env` file (Ctrl+O, Enter, Ctrl+X in nano, or just save in your Windows editor).

---

## Part 4: Install Bot Dependencies

```bash
# Navigate to bot directory
cd discord-bot-general-vance

# Install dependencies
npm install
```

This installs:
- discord.js (Discord API library)
- dotenv (environment variables)
- node-fetch (HTTP requests to n8n)

You should see output like:
```
added 50 packages in 5s
```

---

## Part 5: Run the Bot

```bash
# Make sure you're in discord-bot-general-vance directory
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

In Discord, **Gen. Vance** should now show **online** (green dot)! 🟢

---

## Part 6: Test Message Handling

1. In Discord, go to `#gen-vance` channel
2. Send a message: "General, requesting status report"
3. Gen. Vance should show "typing..." indicator
4. Check WSL terminal - you'll see debug output:

```
📨 Message from YourName#1234 in #gen-vance
   Content: General, requesting status report
📤 [DEV MODE] Would send to n8n: { ... }
```

**Note:** Bot won't actually respond yet because the n8n workflow isn't set up. That's next!

---

## Troubleshooting

**"node: command not found"**
- Node.js not installed in WSL - go back to Step 11

**Bot shows offline in Discord:**
- Check bot token is correct in `.env`
- Verify Message Content Intent is enabled
- Make sure bot is running (check WSL terminal)

**Bot doesn't show typing indicator:**
- Verify channel ID is correct in `.env`
- Check bot has permissions in that channel
- Look at WSL terminal for error messages

**Can't access Windows files from WSL:**
- Windows C: drive is at `/mnt/c/`
- Make sure path is correct

**Permission denied errors:**
- You might need to adjust file permissions:
  ```bash
  chmod +x discord-bot-general-vance/index.js
  ```

---

## Managing the Bot

**To stop the bot:**
Press `Ctrl+C` in the WSL terminal

**To run in background (keeps running when you close terminal):**
```bash
# Install PM2 process manager (one time)
npm install -g pm2

# Start bot with PM2
pm2 start index.js --name gen-vance

# See bot status
pm2 status

# View logs
pm2 logs gen-vance

# Stop bot
pm2 stop gen-vance

# Restart bot
pm2 restart gen-vance
```

---

## File Locations Summary

```
Windows Path:                          WSL Path:
C:\Users\wkenn\git\                   /mnt/c/Users/wkenn/git/
    eha-command-bots\                     eha-command-bots/
    ├── .env                              ├── .env           (you create this)
    ├── .env.example                      ├── .env.example   (template)
    └── discord-bot-general-vance\        └── discord-bot-general-vance/
        ├── index.js                          ├── index.js
        ├── config.js                         ├── config.js
        └── package.json                      └── package.json
```

**You can edit files in Windows, run the bot in WSL!**

---

## Next Steps

Once Gen. Vance is running and responding to messages:
1. ✅ Discord bot receiving messages
2. ⏭️ Set up n8n workflow to process with Claude AI
3. ⏭️ Configure General Vance personality responses
4. ⏭️ Test end-to-end conversation flow

---

## Quick Reference

**Start bot:**
```bash
cd /mnt/c/Users/wkenn/git/eha-command-bots/discord-bot-general-vance
npm start
```

**Edit .env from Windows:**
```
C:\Users\wkenn\git\eha-command-bots\.env
```

**Edit .env from WSL:**
```bash
nano /mnt/c/Users/wkenn/git/eha-command-bots/.env
```

**Check bot logs:**
Look at the WSL terminal where bot is running
