# n8n Workflow Deployment Guide

## Overview

This guide walks you through importing and configuring the generic officer workflow in n8n that works with the configurable Discord bot system.

## What Changed

### Old System (general-vance-v1.114.json):
- ❌ Hardcoded General Vance personality in workflow
- ❌ No knowledge base integration
- ❌ No canon compliance enforcement
- ❌ Separate workflow needed for each officer

### New System (generic-officer-workflow.json):
- ✅ Dynamic personality from YAML config
- ✅ Knowledge base integration (Star Citizen canon)
- ✅ Canon compliance in system prompts
- ✅ One workflow for all officers
- ✅ Easy to update: change YAML, not workflow

## Prerequisites

1. n8n instance running (Docker or self-hosted)
2. Anthropic API key (for Claude)
3. Discord bot token(s)
4. Access to n8n web interface

## Step 1: Import the Workflow

### Option A: Via n8n UI (Recommended)

1. Open your n8n instance in a browser
2. Click **Workflows** in the left sidebar
3. Click **Add workflow** (top right)
4. Click the **three-dot menu** (⋮) in the top right
5. Select **Import from File**
6. Upload `n8n-workflows/generic-officer-workflow.json`
7. Click **Import**

### Option B: Via File Copy (Docker)

If running n8n in Docker:

```bash
# Copy workflow file to n8n container
docker cp n8n-workflows/generic-officer-workflow.json n8n:/home/node/.n8n/workflows/

# Restart n8n to detect the new workflow
docker restart n8n
```

## Step 2: Configure Credentials

### 2.1 Add Anthropic API Credential

1. In n8n, click **Credentials** in the left sidebar
2. Click **Add credential**
3. Search for and select **Header Auth**
4. Configure:
   - **Name**: `Anthropic API Key`
   - **Header Name**: `x-api-key`
   - **Header Value**: `your-anthropic-api-key-here`
5. Click **Save**

### 2.2 Add Discord Bot Token Credential

1. Click **Add credential** again
2. Select **Header Auth**
3. Configure:
   - **Name**: `Discord Bot Token - Vance`
   - **Header Name**: `Authorization`
   - **Header Value**: `Bot YOUR_DISCORD_BOT_TOKEN_HERE`
   - Note: Include the word "Bot " before the token
4. Click **Save**

**Multiple Officers**: Create separate credentials for each officer:
- `Discord Bot Token - Vance`
- `Discord Bot Token - Van Der Merwe`
- etc.

## Step 3: Update Workflow Nodes

### 3.1 Link Credentials to Nodes

Open the imported workflow and update these nodes:

#### Call Claude Node
1. Click the **Call Claude** node
2. In the right panel, find **Credential to connect with**
3. Select `Anthropic API Key` from the dropdown
4. Click **Save**

#### Send to Discord Node
1. Click the **Send to Discord** node
2. In the right panel, find **Credential to connect with**
3. Select `Discord Bot Token - Vance` from the dropdown
4. Click **Save**

### 3.2 Configure Webhook Path

The webhook path should match the `n8n.webhook_path` in your officer YAML config.

1. Click the **Webhook** node
2. Update the **Path** field:
   - For Gen. Vance: `webhook/vance`
   - For other officers: `webhook/{officer_id}`
3. Click **Save**

### 3.3 Get Webhook URL

1. Click the **Webhook** node
2. Look for **Test URL** or **Production URL** in the right panel
3. Copy the URL (e.g., `https://your-n8n.com/webhook/vance`)
4. Update your `.env` file:
   ```bash
   N8N_WEBHOOK_BASE_URL=https://your-n8n.com
   ```

## Step 4: Test the Workflow

### 4.1 Enable the Workflow

1. In the workflow editor, click **Inactive** toggle in the top right
2. It should change to **Active**
3. The webhook is now listening

### 4.2 Test with Discord Bot

Start your Discord bot:

```bash
cd discord-bot-officer
OFFICER_ID=vance npm start
```

In Discord, send a test message:
```
@General Vance Hello General, what's our status?
```

### 4.3 Monitor n8n Executions

1. In n8n, click **Executions** in the left sidebar
2. You should see a new execution
3. Click on it to see the full execution log
4. Check each node's output:
   - **Extract Config**: Should show officer config, knowledge base
   - **Build System Prompt**: Should show the full system prompt with canon guidelines
   - **Call Claude**: Should show Claude's response
   - **Send to Discord**: Should show successful Discord API call

### 4.4 Validate Canon Compliance

Test with a message that mentions Nyx:

```
@General Vance What operations do we have in the Nyx system?
```

**Expected Response**:
- ✅ Mentions Nyx in strategic/lore context
- ✅ Does NOT send missions to Nyx
- ✅ References that Nyx is not yet accessible

**Incorrect Response** (if this happens, check system prompt):
- ❌ Talks about active operations in Nyx
- ❌ Sends missions to Nyx
- ❌ Treats Nyx as accessible

## Step 5: Deploy for Multiple Officers

The beauty of this system: **one workflow for all officers**.

### Option A: Multiple Webhooks (Recommended)

Create separate webhook paths for each officer:

1. **Duplicate the workflow** (or use the same one)
2. **Update webhook path**:
   - Vance: `/webhook/vance`
   - Van Der Merwe: `/webhook/vandermerwe`
   - Reeves: `/webhook/reeves`
3. **Update Discord bot token** credential in "Send to Discord" node
4. **Activate the workflow**

Each Discord bot sends to its own webhook path:

```bash
# Terminal 1: General Vance
cd discord-bot-officer
OFFICER_ID=vance npm start

# Terminal 2: Lt. Col Van Der Merwe
OFFICER_ID=vandermerwe npm start
```

### Option B: Dynamic Routing (Advanced)

Use a single workflow with dynamic routing based on `officer.id` in the payload. This requires more complex JavaScript in the nodes.

## Step 6: Production Configuration

### 6.1 Use Production Webhook URLs

n8n provides both test and production webhook URLs. For production:

1. Click the **Webhook** node
2. Copy the **Production URL** (not Test URL)
3. Update `.env`:
   ```bash
   N8N_WEBHOOK_BASE_URL=https://your-production-n8n.com
   ```

### 6.2 Set Environment Variables

Add to n8n environment (Docker Compose or system env):

```bash
# n8n Configuration
N8N_HOST=your-n8n-domain.com
N8N_PROTOCOL=https
N8N_PORT=443

# API Keys (already in credentials, but can be referenced)
ANTHROPIC_API_KEY=sk-ant-...
```

### 6.3 Enable Workflow Error Handling

1. In workflow settings (gear icon), configure:
   - **Error Workflow**: Create a separate error notification workflow
   - **Retry on Failure**: Enable (recommended: 2 retries)
   - **Wait Between Retries**: 5 seconds

## Troubleshooting

### Issue: Webhook Returns 404

**Cause**: Workflow is inactive or webhook path doesn't match

**Fix**:
1. Ensure workflow is **Active** (toggle in top right)
2. Check webhook path matches `.env` configuration
3. Restart n8n if needed

### Issue: "Invalid API Key" Error

**Cause**: Anthropic credential not configured correctly

**Fix**:
1. Go to **Credentials** → `Anthropic API Key`
2. Ensure header name is `x-api-key` (lowercase, with dash)
3. Ensure header value starts with `sk-ant-`
4. Re-save the credential

### Issue: Bot Responds but Ignores Canon

**Cause**: Knowledge base not being passed or system prompt not using it

**Fix**:
1. Check **Extract Config** node output in executions
2. Verify `config.knowledge_base` exists in the data
3. Check **Build System Prompt** node output
4. Ensure system prompt includes "CRITICAL - STAR CITIZEN CANON COMPLIANCE" section

### Issue: "Cannot read property 'systems' of undefined"

**Cause**: Knowledge base not loaded in Discord bot

**Fix**:
1. Check Discord bot logs for YAML loading errors
2. Ensure `knowledge-base/star-citizen-universe.yml` exists
3. Verify `officers/vance.yml` references correct KB files
4. Restart Discord bot

### Issue: Discord API Returns 401 Unauthorized

**Cause**: Discord bot token incorrect or missing "Bot " prefix

**Fix**:
1. Go to **Credentials** → Discord token
2. Ensure header value is: `Bot YOUR_TOKEN_HERE` (note space after "Bot")
3. Verify token is valid in Discord Developer Portal
4. Re-save credential

## Validation Checklist

Before marking deployment complete:

- [ ] Workflow imported and active
- [ ] Anthropic API credential configured
- [ ] Discord bot token credential configured
- [ ] Webhook URL added to `.env`
- [ ] Discord bot connects successfully
- [ ] Bot responds to messages in character
- [ ] System prompt includes knowledge base context
- [ ] Canon compliance validated (Nyx test passed)
- [ ] Multiple officers work with same workflow (if applicable)
- [ ] Error handling configured
- [ ] Production webhook URL used

## Next Steps

After successful deployment:

1. **Monitor Executions**: Check n8n executions regularly for errors
2. **Update Knowledge Base**: Edit YAML files, restart Discord bot (no n8n changes needed)
3. **Add More Officers**: Create new YAML configs, start new bot instances
4. **Create Story Arcs**: Update `eha-organization.yml` with new operations
5. **Iterate on Personality**: Adjust officer YAML configs based on feedback

## Workflow Architecture Reference

```
Discord Bot (YAML config + KB)
    ↓ (HTTP POST with full config)
n8n Webhook
    ↓
Extract Config (parse payload)
    ↓
Build System Prompt (personality + KB + canon rules)
    ↓
Call Claude API (with dynamic system prompt)
    ↓
Extract Response (get Claude's reply)
    ↓
Send to Discord (post to channel)
    ↓
Respond to Webhook (acknowledge receipt)
```

## Key Differences from Old Workflow

| Feature | Old Workflow | New Workflow |
|---------|--------------|--------------|
| Personality | Hardcoded in n8n | From YAML config |
| Canon Compliance | None | Knowledge base enforced |
| Scalability | 1 workflow per officer | 1 workflow for all |
| Updates | Edit workflow code | Edit YAML file |
| Testing | Must test in n8n | Can test YAML locally |
| Version Control | n8n export only | YAML in git |

## Support

If you encounter issues not covered here:

1. Check n8n execution logs for detailed error messages
2. Review Discord bot logs for payload issues
3. Verify YAML syntax with a validator
4. Consult the [N8N-WORKFLOW-GUIDE.md](./N8N-WORKFLOW-GUIDE.md) for detailed node documentation
