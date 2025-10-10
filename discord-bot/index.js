const { Client, GatewayIntentBits, REST, Routes } = require('discord.js');
const config = require('./config');

// Create Discord client with minimal required intents
const client = new Client({
  intents: [
    GatewayIntentBits.Guilds,
    GatewayIntentBits.GuildMessages,
    GatewayIntentBits.MessageContent,
  ],
});

// Store for tracking conversations and state
const conversationState = new Map();

// Initialize bot
client.once('ready', () => {
  console.log(`✅ Bot logged in as ${client.user.tag}`);
  console.log(`📡 Monitoring ${client.guilds.cache.size} server(s)`);
  console.log(`🔗 n8n webhook URL: ${config.n8n.webhookUrl}`);
  console.log('🚀 EHA Command Bots Discord handler ready\n');
});

// Handle incoming messages
client.on('messageCreate', async (message) => {
  // Ignore bot messages
  if (message.author.bot) return;

  // Debug logging
  if (config.settings.debugMode) {
    console.log(`📨 Message from ${message.author.tag} in #${message.channel.name}: ${message.content}`);
  }

  // Determine which officer channel this is (if any)
  const officerRole = getOfficerRoleFromChannel(message.channel.id);

  // Prepare payload for n8n
  const payload = {
    type: 'discord_message',
    timestamp: new Date().toISOString(),
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
    },
    officer: officerRole,
    conversationContext: conversationState.get(message.channel.id) || {},
  };

  // Send to n8n webhook
  try {
    await sendToN8n(payload);

    // Update conversation state
    updateConversationState(message.channel.id, {
      lastMessageId: message.id,
      lastMessageTime: Date.now(),
      messageCount: (conversationState.get(message.channel.id)?.messageCount || 0) + 1,
    });

  } catch (error) {
    console.error('❌ Error sending to n8n:', error.message);
  }
});

// Helper function to determine officer role from channel
function getOfficerRoleFromChannel(channelId) {
  for (const [role, configChannelId] of Object.entries(config.officerChannels)) {
    if (configChannelId === channelId) {
      return role;
    }
  }
  return 'unknown';
}

// Send payload to n8n webhook
async function sendToN8n(payload) {
  const webhookUrl = config.n8n.prodUrl || config.n8n.webhookUrl;

  // In development, just log the payload
  if (!webhookUrl || webhookUrl === 'http://localhost:5678') {
    console.log('📤 [DEV MODE] Would send to n8n:', JSON.stringify(payload, null, 2));
    return;
  }

  const response = await fetch(`${webhookUrl}/webhook/discord-message`, {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
    },
    body: JSON.stringify(payload),
  });

  if (!response.ok) {
    throw new Error(`n8n webhook returned ${response.status}: ${response.statusText}`);
  }

  const result = await response.json();
  console.log('✅ Sent to n8n:', result);
  return result;
}

// Update conversation state
function updateConversationState(channelId, updates) {
  const current = conversationState.get(channelId) || {};
  conversationState.set(channelId, { ...current, ...updates });
}

// Utility function to send a message to a channel (called by n8n)
async function sendMessage(channelId, content, options = {}) {
  try {
    const channel = await client.channels.fetch(channelId);

    if (!channel || !channel.isTextBased()) {
      throw new Error('Invalid channel or not a text channel');
    }

    // Optional typing indicator
    if (options.typing) {
      await channel.sendTyping();
      // Delay to appear more natural
      await new Promise(resolve => setTimeout(resolve, config.settings.responseDelayMs));
    }

    const message = await channel.send(content);
    return {
      success: true,
      messageId: message.id,
      channelId: channel.id,
    };
  } catch (error) {
    console.error('❌ Error sending message:', error);
    return {
      success: false,
      error: error.message,
    };
  }
}

// Export helper for n8n to call (if we add an API endpoint)
module.exports = { sendMessage };

// Error handling
client.on('error', (error) => {
  console.error('❌ Discord client error:', error);
});

process.on('unhandledRejection', (error) => {
  console.error('❌ Unhandled promise rejection:', error);
});

// Login to Discord
if (!config.discord.token) {
  console.error('❌ DISCORD_BOT_TOKEN not found in environment variables');
  console.error('📝 Please create a .env file with your Discord bot token');
  process.exit(1);
}

client.login(config.discord.token);
