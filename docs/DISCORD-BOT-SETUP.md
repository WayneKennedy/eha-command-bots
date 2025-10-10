# Discord Bot Setup Guide - General Vance

This guide walks you through creating a Discord bot from scratch for General Vance (and later, other AI officers).

## Part 1: Create the Discord Application

### Step 1: Access Discord Developer Portal

1. Go to https://discord.com/developers/applications
2. Log in with your Discord account
3. Click the **"New Application"** button (top right)

### Step 2: Create Application

1. **Application Name**: Enter `General Vance` (this is the bot's name)
2. Click **"Create"**
3. You'll see the application overview page

### Step 3: Add Bot User

1. In the left sidebar, click **"Bot"**
2. Click **"Add Bot"** button
3. Confirm by clicking **"Yes, do it!"**
4. You now have a bot user!

### Step 4: Configure Bot Settings

1. **Username**: Should already be "General Vance" - leave it
2. **Icon**: Click on the bot's avatar circle to upload an image (we'll create this later)
3. Scroll down to **"Privileged Gateway Intents"** section
4. Enable these three intents:
   - ✅ **PRESENCE INTENT**
   - ✅ **SERVER MEMBERS INTENT**
   - ✅ **MESSAGE CONTENT INTENT** (This is critical!)
5. Click **"Save Changes"**

### Step 5: Copy Bot Token

1. Scroll back up to the **"TOKEN"** section
2. Click **"Reset Token"** (if this is first time, it may say "Copy")
3. Click **"Copy"** to copy the token
4. **IMPORTANT**: Save this token somewhere safe temporarily - you'll need it soon
5. **NEVER share this token publicly** - it's like a password for your bot

The token will be a long string like: `YOUR_BOT_TOKEN_HERE` (copy this from Discord)

## Part 2: Configure Bot Permissions

### Step 6: Set Bot Permissions

1. In the left sidebar, click **"OAuth2"** → **"URL Generator"**
2. In the **"SCOPES"** section, check:
   - ✅ `bot`
   - ✅ `applications.commands` (for future slash commands)
3. In the **"BOT PERMISSIONS"** section that appears below, check:
   - ✅ **View Channels**
   - ✅ **Send Messages**
   - ✅ **Send Messages in Threads**
   - ✅ **Embed Links**
   - ✅ **Attach Files**
   - ✅ **Read Message History**
   - ✅ **Add Reactions**
   - ✅ **Use Slash Commands**

### Step 7: Generate Invite URL

1. Scroll down to the **"GENERATED URL"** section
2. Click **"Copy"** to copy the invite URL
3. Save this URL - you'll use it to invite the bot to your server

The URL looks like: `https://discord.com/api/oauth2/authorize?client_id=1234567890&permissions=277025770560&scope=bot%20applications.commands`

## Part 3: Invite Bot to Your Server

### Step 8: Add Bot to EHA Discord

1. Open the invite URL you copied in a new browser tab
2. Select your **EHA Discord server** from the dropdown
3. Click **"Continue"**
4. Review the permissions and click **"Authorize"**
5. Complete the CAPTCHA if prompted
6. You should see "Authorized!" message

### Step 9: Verify Bot is in Server

1. Go to your EHA Discord server
2. Look at the member list on the right
3. You should see **"General Vance"** with an "BOT" tag, showing as **offline** (gray dot)
4. This is normal - the bot is added but not running yet

## Part 4: Configure the Bot Code

### Step 10: Create General Vance Bot Directory

In your terminal/command prompt:

```bash
cd eha-command-bots
mkdir discord-bot-general-vance
cd discord-bot-general-vance
```

### Step 11: Create Bot Files

Create `package.json`:

```json
{
  "name": "eha-general-vance-bot",
  "version": "1.0.0",
  "description": "Discord bot for General Vance - EHA Fleet Commander",
  "main": "index.js",
  "scripts": {
    "start": "node index.js",
    "dev": "nodemon index.js"
  },
  "keywords": ["discord", "bot", "eha", "general-vance"],
  "author": "Commander Atlay",
  "license": "MIT",
  "dependencies": {
    "discord.js": "^14.14.1",
    "dotenv": "^16.3.1",
    "node-fetch": "^3.3.2"
  },
  "devDependencies": {
    "nodemon": "^3.0.2"
  }
}
```

Create `config.js`:

```javascript
require('dotenv').config({ path: '../.env' });

module.exports = {
  // Discord configuration
  discord: {
    token: process.env.DISCORD_BOT_TOKEN_VANCE,
    clientId: process.env.DISCORD_CLIENT_ID_VANCE,
    guildId: process.env.DISCORD_GUILD_ID,
  },

  // Officer details
  officer: {
    name: 'General Vance',
    rank: 'General',
    role: 'Fleet Commander',
    callsign: 'Horizon Actual',
    personalityFile: 'prompts/officer-personalities/fleet-commander.md',
  },

  // n8n webhook configuration
  n8n: {
    webhookUrl: process.env.N8N_WEBHOOK_URL || 'http://localhost:5678',
    webhookPath: '/webhook/general-vance',
  },

  // Bot behavior settings
  settings: {
    // Channels where this bot should respond
    activeChannels: [
      process.env.CHANNEL_GENERAL_VANCE,
      process.env.CHANNEL_COMMAND_BRIEFING,
    ],

    // Response delay to appear more natural
    responseDelayMs: parseInt(process.env.RESPONSE_DELAY_MS) || 2000,

    // Debug mode
    debugMode: process.env.DEBUG_MODE === 'true',
  },
};
```

Create `index.js`:

```javascript
const { Client, GatewayIntentBits } = require('discord.js');
const config = require('./config');

// Create Discord client
const client = new Client({
  intents: [
    GatewayIntentBits.Guilds,
    GatewayIntentBits.GuildMessages,
    GatewayIntentBits.MessageContent,
  ],
});

// Initialize bot
client.once('ready', () => {
  console.log(`✅ ${config.officer.name} online`);
  console.log(`📡 Rank: ${config.officer.rank}`);
  console.log(`🎯 Role: ${config.officer.role}`);
  console.log(`📻 Callsign: ${config.officer.callsign}`);
  console.log(`🔗 n8n webhook: ${config.n8n.webhookUrl}${config.n8n.webhookPath}`);
  console.log(`🚀 ${config.officer.name} ready for operations\n`);
});

// Handle incoming messages
client.on('messageCreate', async (message) => {
  // Ignore bot messages (including our own)
  if (message.author.bot) return;

  // Only respond in configured channels
  if (!config.settings.activeChannels.includes(message.channel.id)) {
    return;
  }

  // Debug logging
  if (config.settings.debugMode) {
    console.log(`📨 Message from ${message.author.tag} in #${message.channel.name}`);
    console.log(`   Content: ${message.content}`);
  }

  // Show typing indicator
  await message.channel.sendTyping();

  // Prepare payload for n8n
  const payload = {
    type: 'discord_message',
    timestamp: new Date().toISOString(),
    officer: {
      name: config.officer.name,
      rank: config.officer.rank,
      role: config.officer.role,
      callsign: config.officer.callsign,
    },
    message: {
      id: message.id,
      content: message.content,
      channelId: message.channel.id,
      channelName: message.channel.name,
      guildId: message.guild?.id,
    },
    author: {
      id: message.author.id,
      username: message.author.username,
      displayName: message.member?.displayName || message.author.username,
      isCommander: checkIfCommander(message.member),
    },
  };

  try {
    // Send to n8n webhook
    const response = await sendToN8n(payload);

    if (config.settings.debugMode) {
      console.log(`✅ Message processed by n8n`);
    }

    // Note: n8n will send the response back to Discord directly
    // This bot just forwards messages to n8n

  } catch (error) {
    console.error(`❌ Error processing message:`, error.message);

    // Send error message in character
    await message.reply(
      `${config.officer.callsign} here. I'm experiencing technical difficulties. ` +
      `My communications systems are temporarily degraded. Stand by.`
    );
  }
});

// Check if user is a commander
function checkIfCommander(member) {
  if (!member) return false;

  const commanderRoles = ['Commander', 'Command Staff'];
  return member.roles.cache.some(role =>
    commanderRoles.some(cmdRole => role.name.includes(cmdRole))
  );
}

// Send payload to n8n webhook
async function sendToN8n(payload) {
  const webhookUrl = `${config.n8n.webhookUrl}${config.n8n.webhookPath}`;

  // In development without n8n running, just log
  if (config.settings.debugMode && config.n8n.webhookUrl === 'http://localhost:5678') {
    console.log('📤 [DEV MODE] Would send to n8n:', JSON.stringify(payload, null, 2));
    return { status: 'dev_mode' };
  }

  const fetch = (await import('node-fetch')).default;

  const response = await fetch(webhookUrl, {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
    },
    body: JSON.stringify(payload),
  });

  if (!response.ok) {
    throw new Error(`n8n webhook returned ${response.status}: ${response.statusText}`);
  }

  return await response.json();
}

// Error handling
client.on('error', (error) => {
  console.error('❌ Discord client error:', error);
});

process.on('unhandledRejection', (error) => {
  console.error('❌ Unhandled promise rejection:', error);
});

// Login to Discord
if (!config.discord.token) {
  console.error('❌ DISCORD_BOT_TOKEN_VANCE not found in environment variables');
  console.error('📝 Please add your bot token to the .env file');
  process.exit(1);
}

console.log(`🔐 Logging in ${config.officer.name}...`);
client.login(config.discord.token);
```

### Step 12: Update .env File

Add these new variables to your `.env` file (in the root directory):

```bash
# General Vance Discord Bot
DISCORD_BOT_TOKEN_VANCE=paste_your_bot_token_here
DISCORD_CLIENT_ID_VANCE=your_application_id_here
CHANNEL_GENERAL_VANCE=
CHANNEL_COMMAND_BRIEFING=
```

**To get the Application ID:**
1. Go back to Discord Developer Portal
2. Click on your "General Vance" application
3. Go to "OAuth2" → "General"
4. Copy the **"CLIENT ID"**
5. Paste it as `DISCORD_CLIENT_ID_VANCE`

**To get Channel IDs:**
1. In Discord, go to User Settings → Advanced
2. Enable **"Developer Mode"**
3. Right-click on the `#general-vance` channel (create it if needed)
4. Click **"Copy Channel ID"**
5. Paste it as `CHANNEL_GENERAL_VANCE`

### Step 13: Install Dependencies

```bash
cd discord-bot-general-vance
npm install
```

### Step 14: Test the Bot

```bash
npm start
```

You should see:
```
🔐 Logging in General Vance...
✅ General Vance online
📡 Rank: General
🎯 Role: Fleet Commander
📻 Callsign: Horizon Actual
🔗 n8n webhook: http://localhost:5678/webhook/general-vance
🚀 General Vance ready for operations
```

And in your Discord server, General Vance should now show as **online** (green dot)!

### Step 15: Test Message Handling

1. Go to your Discord server
2. Create or go to `#general-vance` channel
3. Send a test message: "General, requesting status report"
4. The bot should show typing indicator
5. In dev mode (no n8n yet), it will log the message to console

## Next Steps

Once the Discord bot is working:
1. Create the n8n workflow for General Vance
2. Configure webhook to send responses back to Discord
3. Test end-to-end message flow
4. Refine personality and responses

## Troubleshooting

**Bot shows offline:**
- Check that bot token is correct in `.env`
- Make sure you enabled Message Content Intent
- Verify the bot script is running

**Bot doesn't respond to messages:**
- Check channel IDs are correct in `.env`
- Verify Message Content Intent is enabled
- Check console for error messages

**Permission errors:**
- Verify bot has proper permissions in Discord server
- Check role hierarchy (bot role should be high enough)

---

**Need help?** Check the logs in the terminal where the bot is running for detailed error messages.
