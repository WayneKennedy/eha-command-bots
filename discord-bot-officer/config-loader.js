const yaml = require('js-yaml');
const fs = require('fs');
const path = require('path');

/**
 * Load officer configuration from YAML file
 * Supports OFFICER_ID environment variable to select which officer to load
 */
async function loadOfficerConfig() {
  const officerId = process.env.OFFICER_ID || 'vance';

  console.log(`🔧 Loading configuration for officer: ${officerId}`);

  // 1. Load officer YAML configuration
  const officerConfigPath = path.join(__dirname, '..', 'officers', `${officerId}.yml`);

  if (!fs.existsSync(officerConfigPath)) {
    throw new Error(`Officer configuration not found: ${officerConfigPath}`);
  }

  const officerConfig = yaml.load(fs.readFileSync(officerConfigPath, 'utf8'));
  console.log(`   ✓ Loaded officer config: ${officerConfig.officer.name}`);

  // 2. Load knowledge base files
  const knowledgeBase = {};

  if (officerConfig.knowledge_base && officerConfig.knowledge_base.files) {
    for (const kbFile of officerConfig.knowledge_base.files) {
      const kbPath = path.join(__dirname, '..', 'knowledge-base', kbFile);

      if (fs.existsSync(kbPath)) {
        const kbName = kbFile.replace('.yml', '').replace('.yaml', '');
        knowledgeBase[kbName] = yaml.load(fs.readFileSync(kbPath, 'utf8'));
        console.log(`   ✓ Loaded knowledge base: ${kbFile}`);
      } else {
        console.warn(`   ⚠️  Knowledge base file not found: ${kbFile}`);
      }
    }
  }

  // 3. Add loaded knowledge base to config
  officerConfig.knowledge_base_loaded = knowledgeBase;

  // 4. Validate required fields
  validateConfig(officerConfig);

  console.log(`✅ Configuration loaded successfully for ${officerConfig.officer.name}`);
  console.log(`   Rank: ${officerConfig.officer.rank}`);
  console.log(`   Role: ${officerConfig.officer.role}`);
  console.log(`   Callsign: ${officerConfig.officer.callsign}`);

  return officerConfig;
}

/**
 * Validate officer configuration
 */
function validateConfig(config) {
  // Required fields
  if (!config.officer?.id) {
    throw new Error('officer.id is required in configuration');
  }

  if (!config.officer?.name) {
    throw new Error('officer.name is required in configuration');
  }

  if (!config.discord?.token_env) {
    throw new Error('discord.token_env is required in configuration');
  }

  // Validate formality level if present
  const formalityLevel = config.personality?.voice?.formality_level;
  if (formalityLevel && (formalityLevel < 1 || formalityLevel > 10)) {
    throw new Error('personality.voice.formality_level must be between 1-10');
  }

  return true;
}

/**
 * Get Discord token from environment based on config
 */
function getDiscordToken(config) {
  const tokenEnvVar = config.discord.token_env;
  const token = process.env[tokenEnvVar];

  if (!token) {
    throw new Error(`Discord token not found: ${tokenEnvVar} environment variable not set`);
  }

  return token;
}

/**
 * Get active channel IDs from environment based on config
 */
function getActiveChannels(config) {
  if (!config.discord.active_channels_env) {
    return [];
  }

  const channels = config.discord.active_channels_env
    .map(envVar => process.env[envVar])
    .filter(Boolean); // Remove undefined/null values

  return channels;
}

/**
 * Build configuration object compatible with old config.js format
 * This allows gradual migration from hardcoded to YAML config
 */
function buildLegacyConfig(officerConfig) {
  return {
    // Discord configuration
    discord: {
      token: getDiscordToken(officerConfig),
      clientId: process.env[officerConfig.discord.client_id_env],
      guildId: process.env.DISCORD_GUILD_ID,
    },

    // Officer details
    officer: {
      id: officerConfig.officer.id,
      name: officerConfig.officer.name,
      rank: officerConfig.officer.rank,
      role: officerConfig.officer.role,
      callsign: officerConfig.officer.callsign,
      division: officerConfig.officer.division,
    },

    // n8n webhook configuration
    n8n: {
      webhookUrl: process.env.N8N_WEBHOOK_URL || 'http://localhost:5678',
      webhookPath: officerConfig.n8n.webhook_path,
    },

    // Bot behavior settings
    settings: {
      activeChannels: getActiveChannels(officerConfig),
      responseDelayMs: officerConfig.settings?.response_delay_ms || 1500,
      debugMode: process.env.DEBUG_MODE === 'true',
      commandRoles: officerConfig.discord.command_roles || ['Commander', 'Command Staff'],
    },

    // Full officer config (for n8n webhook)
    fullConfig: officerConfig,
  };
}

module.exports = {
  loadOfficerConfig,
  validateConfig,
  getDiscordToken,
  getActiveChannels,
  buildLegacyConfig,
};
