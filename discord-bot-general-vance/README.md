# General Vance Discord Bot

Discord bot for General Vance, Fleet Commander of Event Horizon Armada.

## Officer Details

- **Name**: General Vance
- **Rank**: General (O-10)
- **Role**: Fleet Commander
- **Callsign**: Horizon Actual
- **Authority**: Strategic direction and story arc generation

## Setup

1. Follow the Discord bot creation guide in [docs/DISCORD-BOT-SETUP.md](../docs/DISCORD-BOT-SETUP.md)

2. Add bot token to `.env` file in project root:
   ```bash
   DISCORD_BOT_TOKEN_VANCE=your_bot_token_here
   DISCORD_CLIENT_ID_VANCE=your_application_id_here
   CHANNEL_GENERAL_VANCE=channel_id_here
   ```

3. Install dependencies:
   ```bash
   npm install
   ```

4. Run the bot:
   ```bash
   npm start
   ```

   For development with auto-restart:
   ```bash
   npm run dev
   ```

## Configuration

Bot configuration is in `config.js`. Key settings:

- **activeChannels**: Channels where the bot responds
- **n8n.webhookPath**: Path for n8n webhook (`/webhook/general-vance`)
- **officer details**: Name, rank, role, callsign

## How It Works

1. Bot listens for messages in configured Discord channels
2. When a message is received, it shows typing indicator
3. Message is forwarded to n8n webhook with officer context
4. n8n processes with Claude API using General Vance personality
5. n8n sends response back to Discord channel

## Testing

Run in debug mode by setting in `.env`:
```bash
DEBUG_MODE=true
```

This will log all message processing to console.

## Troubleshooting

**Bot shows offline:**
- Check bot token is correct
- Verify Message Content Intent is enabled in Discord Developer Portal

**Bot doesn't respond:**
- Check channel IDs in `.env`
- Verify bot has proper permissions in Discord server
- Check console for error messages

**n8n errors:**
- Verify n8n is running
- Check webhook URL in `.env`
- Test webhook manually with curl/Postman

## Next Steps

After bot is running:
1. Set up n8n workflow for General Vance
2. Test end-to-end message flow
3. Configure personality responses
4. Deploy to production server
