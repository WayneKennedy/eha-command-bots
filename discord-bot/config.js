require('dotenv').config({ path: '../.env' });

module.exports = {
  // Discord configuration
  discord: {
    token: process.env.DISCORD_BOT_TOKEN,
    guildId: process.env.DISCORD_GUILD_ID,
    clientId: process.env.DISCORD_CLIENT_ID,
  },

  // n8n webhook configuration
  n8n: {
    webhookUrl: process.env.N8N_WEBHOOK_URL || 'http://localhost:5678',
    prodUrl: process.env.N8N_PROD_URL,
  },

  // Officer channel IDs (to be configured)
  officerChannels: {
    commander: process.env.CHANNEL_COMMANDER,
    xo: process.env.CHANNEL_XO,
    intelligence: process.env.CHANNEL_INTELLIGENCE,
    operations: process.env.CHANNEL_OPERATIONS,
    logistics: process.env.CHANNEL_LOGISTICS,
    communications: process.env.CHANNEL_COMMUNICATIONS,
    general: process.env.CHANNEL_GENERAL,
  },

  // Bot behavior settings
  settings: {
    // Prefix for commands (if needed)
    commandPrefix: '!',

    // Whether to log all messages to console
    debugMode: process.env.DEBUG_MODE === 'true',

    // Response delay (ms) to appear more natural
    responseDelayMs: parseInt(process.env.RESPONSE_DELAY_MS) || 1000,
  },
};
