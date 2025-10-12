# n8n Workflow Guide - Generic Officer Support

## Overview

The n8n workflow needs to be updated to work with the generic officer bot that sends dynamic configuration instead of hardcoded personality.

## Current vs. New Architecture

### Before (Hardcoded):
```
Discord Bot → n8n Webhook
                ↓
              Hardcoded system prompt:
              "You are General Vance..."
                ↓
              Claude API
```

### After (Dynamic):
```
Discord Bot → n8n Webhook (includes config)
                ↓
              Extract officer config from payload
                ↓
              Build system prompt from:
              - config.personality
              - config.knowledge_base
              - config.organization
                ↓
              Claude API (with canon context)
```

## Payload Structure

The Discord bot now sends:

```json
{
  "type": "discord_message",
  "timestamp": "2025-10-12T10:30:00Z",

  "officer": {
    "id": "vance",
    "name": "Gen. Vance",
    "rank": "General",
    "role": "Fleet Commander",
    "callsign": "Horizon Actual",
    "division": "High Command"
  },

  "message": {
    "id": "1234567890",
    "content": "What's our current status?",
    "channelId": "...",
    "channelName": "general-vance"
  },

  "author": {
    "id": "...",
    "username": "PlayerName",
    "displayName": "Player Name",
    "isCommander": true
  },

  "config": {
    "personality": {
      "background": "25 years of distinguished service...",
      "traits": {
        "leadership_style": "Strategic and authoritative",
        "communication": "Formal military professionalism",
        "decision_making": "Big-picture strategic thinking",
        "temperament": "Calm and measured"
      },
      "values": ["Mission success", "Crew safety", ...],
      "voice": {
        "tone": "formal",
        "formality_level": 9,
        "military_terminology": true,
        "signs_off_as": "General Vance"
      }
    },

    "knowledge_base": {
      "star-citizen-universe": {
        "systems": {
          "stanton": { "status": "playable", ... },
          "pyro": { "status": "playable", ... },
          "nyx": {
            "status": "in_development",
            "narrative_guidelines": "..."
          }
        },
        "mission_locations": [...],
        "valid_mission_types": [...]
      },

      "eha-organization": {
        "command_structure": {...},
        "current_operations": {
          "operation_crimson_dawn": {...}
        },
        "base_of_operations": {...}
      }
    },

    "claude": {
      "model": "claude-3-haiku-20240307",
      "max_tokens": 1024,
      "temperature": 0.7
    },

    "organization": {
      "name": "Event Horizon Armada",
      "abbreviation": "EHA",
      "chain_of_command": {...}
    }
  }
}
```

## n8n Workflow Nodes

### 1. Webhook Node
**Type**: `n8n-nodes-base.webhook`
**Config**:
- Method: POST
- Path: `general-vance` (or generic `/webhook/{{officer_id}}`)
- Response Mode: Response Node

**Output**: Full payload from Discord bot

### 2. Extract Config Node
**Type**: `n8n-nodes-base.code` (JavaScript)

```javascript
// Extract data from webhook
const payload = $input.first().json.body;

const officer = payload.officer;
const message = payload.message;
const author = payload.author;
const config = payload.config;

// Make available to next nodes
return {
  json: {
    officer,
    message,
    author,
    config,
    // Convenience extractions
    userMessage: message.content,
    userName: author.displayName,
    isCommander: author.isCommander
  }
};
```

### 3. Build System Prompt Node
**Type**: `n8n-nodes-base.code` (JavaScript)

```javascript
const data = $input.first().json;
const config = data.config;
const officer = data.officer;
const knowledgeBase = config.knowledge_base;

// Build comprehensive system prompt
const systemPrompt = `You are ${officer.name}, ${officer.role} of ${config.organization.name}.

OFFICER IDENTITY:
- Rank: ${officer.rank}
- Callsign: ${officer.callsign}
- Division: ${officer.division}

PERSONALITY & BACKGROUND:
${config.personality.background}

PERSONALITY TRAITS:
${Object.entries(config.personality.traits).map(([key, value]) =>
  `- ${key.replace(/_/g, ' ')}: ${value}`
).join('\n')}

CORE VALUES:
${config.personality.values.map(v => `- ${v}`).join('\n')}

COMMUNICATION STYLE:
- Tone: ${config.personality.voice.tone}
- Formality Level: ${config.personality.voice.formality_level}/10
- Military Terminology: ${config.personality.voice.military_terminology ? 'Yes' : 'No'}
- Sign off as: ${config.personality.voice.signs_off_as}

CRITICAL - STAR CITIZEN CANON COMPLIANCE:
You must ONLY reference locations, systems, and features that exist in Star Citizen.

VALID SYSTEMS (missions only):
${Object.entries(knowledgeBase['star-citizen-universe'].systems)
  .filter(([_, sys]) => sys.status === 'playable')
  .map(([name, sys]) => `- ${name.charAt(0).toUpperCase() + name.slice(1)}: ${sys.status}`)
  .join('\n')}

NYX SYSTEM GUIDELINES:
${knowledgeBase['star-citizen-universe'].systems.nyx.narrative_guidelines || 'Nyx is not yet accessible'}

VALID MISSION LOCATIONS:
Stations: ${knowledgeBase['star-citizen-universe'].mission_locations.stations.slice(0, 5).join(', ')}
Cities: ${knowledgeBase['star-citizen-universe'].mission_locations.cities.join(', ')}

EHA ORGANIZATION:
- Base of Operations: ${knowledgeBase['eha-organization'].base_of_operations.primary}
- Current Operation: ${knowledgeBase['eha-organization'].current_operations.operation_crimson_dawn.name}
- Status: ${knowledgeBase['eha-organization'].current_operations.operation_crimson_dawn.status}

REAL COMMANDERS (respect their authority):
${Object.values(config.organization.chain_of_command.commands || [])
  .map(cmd => `- ${cmd.rank} ${cmd.name} (${cmd.callsign}) - ${cmd.division}`)
  .join('\n')}

IMPORTANT GUIDELINES:
- Only send missions to systems marked as "playable" (Stanton, Pyro)
- You may mention Nyx in strategic discussions but DO NOT send missions there yet
- Reference real EHA commanders by name and respect their authority
- Use proper military courtesy and rank protocol
- Stay in character based on your personality profile above

Respond to the following message in character:`;

return {
  json: {
    systemPrompt,
    userMessage: data.userMessage,
    userName: data.userName,
    officer: data.officer,
    claudeConfig: config.claude
  }
};
```

### 4. Call Claude API Node
**Type**: `n8n-nodes-base.httpRequest`

**Config**:
- Method: POST
- URL: `https://api.anthropic.com/v1/messages`
- Authentication: Header Auth
  - Header: `x-api-key`
  - Value: `{{$env.ANTHROPIC_API_KEY}}`
- Headers:
  - `anthropic-version`: `2023-06-01`
  - `Content-Type`: `application/json`

**Body** (JSON):
```json
{
  "model": "={{ $json.claudeConfig.model }}",
  "max_tokens": "={{ $json.claudeConfig.max_tokens }}",
  "temperature": "={{ $json.claudeConfig.temperature }}",
  "system": "={{ $json.systemPrompt }}",
  "messages": [
    {
      "role": "user",
      "content": "Message from {{ $json.userName }}: {{ $json.userMessage }}"
    }
  ]
}
```

### 5. Extract Response Node
**Type**: `n8n-nodes-base.code` (JavaScript)

```javascript
const claudeResponse = $input.first().json;
const previousData = $('Build System Prompt').first().json;

const responseText = claudeResponse.content[0].text;

return {
  json: {
    response: responseText,
    officer: previousData.officer,
    channelId: $('Extract Config').first().json.message.channelId
  }
};
```

### 6. Send to Discord Node
**Type**: `n8n-nodes-base.httpRequest`

**Config**:
- Method: POST
- URL: `https://discord.com/api/v10/channels/{{ $json.channelId }}/messages`
- Authentication: Header Auth
  - Header: `Authorization`
  - Value: `Bot {{$env.DISCORD_BOT_TOKEN_VANCE}}`
- Headers:
  - `Content-Type`: `application/json`

**Body** (JSON):
```json
{
  "content": "={{ $json.response }}"
}
```

### 7. Response Node
**Type**: `n8n-nodes-base.respondToWebhook`

**Config**:
- Response Code: 200
- Response Body:
```json
{
  "status": "success",
  "officer": "={{ $json.officer.name }}",
  "processed": true
}
```

## Testing the Workflow

### Test 1: Basic Response
**Input**: "Hello General Vance"
**Expected**: In-character greeting using personality config

### Test 2: Canon Compliance (Valid Location)
**Input**: "General, brief me on operations in Stanton"
**Expected**: Response referencing Stanton system (playable)

### Test 3: Canon Compliance (Nyx Buildup)
**Input**: "What about Nyx?"
**Expected**:
- ✅ Mentions Nyx in strategic context
- ❌ Does NOT send missions to Nyx
- ✅ References it's not accessible yet

### Test 4: Invalid Location
**Input**: "Send a team to Arcadia system"
**Expected**: Corrects user or refuses (Arcadia doesn't exist)

### Test 5: EHA Context
**Input**: "What's our current operation?"
**Expected**: References Operation Crimson Dawn from knowledge base

## Workflow Export

After building the workflow, export it as:
- `n8n-workflows/generic-officer-workflow.json`

This workflow can be used for ALL officers - just ensure they send the correct config payload.

## Environment Variables Needed

Add to n8n environment:
```bash
ANTHROPIC_API_KEY=your_claude_key
DISCORD_BOT_TOKEN_VANCE=your_bot_token
```

## Validation Checklist

Before deploying:
- [ ] Webhook receives full payload including config
- [ ] System prompt includes personality from config
- [ ] System prompt includes knowledge base context
- [ ] Canon compliance guidelines in prompt
- [ ] Claude API call uses config.claude settings
- [ ] Response sent back to correct Discord channel
- [ ] Works for different officers (just change payload.officer)

## Notes

- The workflow is now **generic** - same workflow for all officers
- Officer personality comes from YAML config, not hardcoded
- Knowledge base ensures canon compliance
- Easy to update: just change YAML, no workflow changes needed

## Next Steps

1. Build this workflow in n8n UI
2. Test with Gen. Vance Discord bot
3. Verify canon compliance with test messages
4. Export and save to repository
5. Deploy to production n8n instance
