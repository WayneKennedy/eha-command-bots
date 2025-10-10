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

  // Only respond in configured channels (if any are set)
  if (config.settings.activeChannels.length > 0) {
    if (!config.settings.activeChannels.includes(message.channel.id)) {
      return;
    }
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
