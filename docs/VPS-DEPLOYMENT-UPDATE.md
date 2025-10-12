# VPS Deployment Update Guide

## Overview

This guide walks you through updating your Hostinger VPS deployment from the old hardcoded General Vance bot to the new generic officer system.

## What Changed

The docker-compose.yml has been updated to:
- Use `discord-bot-officer` (generic bot) instead of `discord-bot-general-vance` (removed)
- Mount `officers/` and `knowledge-base/` directories as volumes
- Pass `OFFICER_ID=vance` environment variable
- Load YAML configuration dynamically

## Deployment Steps

### 1. Connect to Your VPS

```bash
ssh root@zappfyre.cloud
cd /root/eha-command-bots
```

### 2. Pull Latest Changes

```bash
git pull origin main
```

### 3. Update VPS .env File

Edit the `.env` file on the VPS and change:

```bash
# Change this:
DEBUG_MODE=true

# To this:
DEBUG_MODE=false
```

This enables the bot to actually send requests to n8n.

```bash
nano .env
# or
vi .env
```

### 4. Import New n8n Workflow

1. Open n8n in your browser: `http://zappfyre.cloud:5678`
2. Login with credentials from `.env`:
   - User: `admin`
   - Password: `Coops2025!`
3. Import the new workflow:
   - Click **Workflows** → **Add workflow**
   - Click **⋮** (three dots) → **Import from URL**
   - Paste: `https://raw.githubusercontent.com/WayneKennedy/eha-command-bots/main/n8n-workflows/generic-officer-workflow.json`
   - Click **Import**

### 5. Configure n8n Workflow Credentials

#### 5.1 Anthropic API Credential

1. Click **Credentials** in left sidebar
2. Click **Add credential**
3. Select **Header Auth**
4. Configure:
   - **Name**: `Anthropic API Key`
   - **Header Name**: `x-api-key`
   - **Header Value**: Your Anthropic API key from `.env` (starts with `sk-ant-`)
5. Click **Save**

#### 5.2 Discord Bot Token Credential

1. Click **Add credential** again
2. Select **Header Auth**
3. Configure:
   - **Name**: `Discord Bot Token - Vance`
   - **Header Name**: `Authorization`
   - **Header Value**: `Bot ` + your Discord token from `.env`
   - **IMPORTANT**: Include the word "Bot " before the token with a space after it
4. Click **Save**

### 6. Link Credentials to Workflow Nodes

Open the imported workflow and configure these nodes:

1. **Call Claude** node:
   - Click the node
   - Select `Anthropic API Key` credential
   - Click **Save**

2. **Send to Discord** node:
   - Click the node
   - Select `Discord Bot Token - Vance` credential
   - Click **Save**

### 7. Verify Webhook Path

1. Click the **Webhook** node
2. Verify the **Path** is: `webhook/vance`
3. If not, update it to match
4. Click **Save**

### 8. Activate the Workflow

1. In the workflow editor, click the **Inactive** toggle in top right
2. It should change to **Active**
3. The webhook is now listening

### 9. Deactivate Old Workflow (if present)

If you have the old "General Vance - Discord Bot" workflow:

1. Open that workflow
2. Click **Active** toggle to deactivate it
3. This prevents conflicts with the new workflow

### 10. Rebuild and Restart Docker Containers

```bash
# Stop and remove old containers
docker-compose down

# Rebuild the Discord bot with new code
docker-compose build bot-general-vance

# Start all services
docker-compose up -d

# Check logs to verify startup
docker-compose logs -f bot-general-vance
```

You should see output like:
```
🎖️  Initializing Gen. Vance
📋 Officer ID: vance
⚔️  Division: Command
✅ Gen. Vance online
📡 Rank: General
🎯 Role: Fleet Commander
📻 Callsign: Horizon Actual
🔗 n8n webhook: http://n8n:5678/webhook/vance
🚀 Gen. Vance ready for operations
```

### 11. Test the System

In Discord, send a message to the bot:

```
@General Vance Hello General, what's our current status?
```

Expected behavior:
- ✅ Bot shows typing indicator
- ✅ Bot responds in character
- ✅ Response reflects personality from `officers/vance.yml`
- ✅ Response respects Star Citizen canon (only mentions playable systems)
- ✅ Execution appears in n8n executions list

### 12. Validate Canon Compliance

Test with a Nyx question:

```
@General Vance What operations do we have in the Nyx system?
```

Expected response:
- ✅ Mentions Nyx in strategic/lore context
- ✅ Does NOT send missions to Nyx
- ✅ Explains Nyx is not yet accessible for operations

## Troubleshooting

### Issue: Bot container fails to start

**Check logs:**
```bash
docker-compose logs bot-general-vance
```

**Common causes:**
- Missing YAML files (should be mounted as volumes)
- Invalid YAML syntax in `officers/vance.yml`
- Missing environment variables

**Fix:**
```bash
# Verify volumes are mounted correctly
docker inspect eha-bot-vance | grep -A 10 Mounts

# Should show:
# /root/eha-command-bots/officers → /app/officers
# /root/eha-command-bots/knowledge-base → /app/knowledge-base
```

### Issue: Bot connects but no response in Discord

**Check n8n executions:**
1. Open n8n: `http://zappfyre.cloud:5678`
2. Click **Executions** in left sidebar
3. Look for failed executions

**If no executions appear:**
- Check `DEBUG_MODE=false` in `.env`
- Verify webhook URL in bot logs
- Check n8n workflow is **Active**

**If executions fail:**
- Click on failed execution to see error
- Check credentials are configured correctly
- Verify Anthropic API key is valid

### Issue: Bot responds but mentions non-existent locations

**Cause:** Knowledge base not loaded or workflow not using it

**Fix:**
1. Check bot logs for knowledge base loading:
   ```bash
   docker-compose logs bot-general-vance | grep "knowledge base"
   ```
2. Verify volumes are mounted in docker-compose
3. Check n8n workflow "Build System Prompt" node includes knowledge base context

### Issue: "Cannot find module 'js-yaml'" error

**Cause:** Dependencies not installed during Docker build

**Fix:**
```bash
# Rebuild without cache
docker-compose build --no-cache bot-general-vance
docker-compose up -d bot-general-vance
```

### Issue: n8n credential "Invalid API Key"

**Cause:** Header name or format incorrect

**Fix:**
1. Go to **Credentials** in n8n
2. Edit the credential
3. Anthropic: Header name must be `x-api-key` (lowercase, with dash)
4. Discord: Header value must be `Bot TOKEN` (with space after "Bot")
5. Re-save credential

## Verification Checklist

Before marking deployment complete:

- [ ] Latest code pulled from GitHub
- [ ] `.env` updated with `DEBUG_MODE=false`
- [ ] New generic workflow imported into n8n
- [ ] Anthropic API credential configured
- [ ] Discord bot token credential configured
- [ ] Credentials linked to workflow nodes
- [ ] Webhook path is `/webhook/vance`
- [ ] Workflow is **Active**
- [ ] Old workflow is **Inactive** (if present)
- [ ] Docker containers rebuilt and restarted
- [ ] Bot connects to Discord successfully
- [ ] Bot responds to messages in character
- [ ] Responses reflect YAML personality config
- [ ] Canon compliance validated (Nyx test passed)
- [ ] n8n executions show successful runs

## Rollback Plan (if needed)

If the new system has issues:

```bash
# Revert to previous commit
git log --oneline -5  # Find commit hash before update
git checkout <previous-commit-hash>

# Rebuild and restart
docker-compose down
docker-compose build
docker-compose up -d

# Re-import and activate old workflow in n8n
```

## Next Steps After Successful Deployment

1. **Monitor for 24 hours**: Watch logs and Discord interactions
2. **Update knowledge base**: Edit YAML files, restart bot (no n8n changes needed)
3. **Add more officers**: Create new YAML configs, add to docker-compose
4. **Create story arcs**: Update `eha-organization.yml` with new operations

## Support

If you encounter issues not covered here:

1. Check bot logs: `docker-compose logs bot-general-vance`
2. Check n8n logs: `docker-compose logs n8n`
3. Check n8n executions for detailed error messages
4. Review [N8N-DEPLOYMENT.md](./N8N-DEPLOYMENT.md) for detailed workflow documentation
