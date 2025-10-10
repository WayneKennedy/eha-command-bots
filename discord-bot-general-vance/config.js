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
    ].filter(Boolean), // Remove undefined values

    // Response delay to appear more natural
    responseDelayMs: parseInt(process.env.RESPONSE_DELAY_MS) || 2000,

    // Debug mode
    debugMode: process.env.DEBUG_MODE === 'true',
  },
};
