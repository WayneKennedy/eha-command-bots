# EHA Command Bots - Deployment Guide

This project uses Docker and GitHub Actions for automated deployment to a Hostinger VPS.

## Architecture

```
GitHub Repository (main branch)
    ↓
GitHub Actions CI/CD
    ↓
Hostinger VPS (Ubuntu + Docker)
    ├── PostgreSQL (Database)
    ├── n8n (Workflow automation)
    └── Gen. Vance Bot (Discord)
```

## Deployment Methods

### Method 1: Automatic (Recommended)
**Every push to `main` branch automatically deploys to VPS via GitHub Actions**

1. Make changes to code
2. Commit and push to main:
   ```bash
   git add .
   git commit -m "Your changes"
   git push origin main
   ```
3. GitHub Actions automatically:
   - Creates .env on VPS from GitHub Secrets
   - Pulls latest code
   - Rebuilds Docker images
   - Restarts containers
   - Verifies deployment

### Method 2: Manual Deployment
**SSH to VPS and run deployment script**

```bash
ssh ehaadmin@your-vps-ip
cd ~/eha-command-bots
./scripts/deploy.sh
```

## Initial Setup

### 1. Set Up VPS
Follow [docs/VPS-SETUP-HOSTINGER.md](docs/VPS-SETUP-HOSTINGER.md) to:
- Configure Ubuntu server
- Install Docker and Docker Compose
- Clone repository
- Set up SSH keys for GitHub Actions

### 2. Configure GitHub Secrets
Add these secrets in GitHub: Settings → Secrets and variables → Actions

**VPS Connection:**
- `VPS_SSH_PRIVATE_KEY` - SSH private key for deployment
- `VPS_HOST` - VPS IP address
- `VPS_USER` - `ehaadmin`

**Database:**
- `POSTGRES_PASSWORD` - PostgreSQL password

**n8n:**
- `N8N_BASIC_AUTH_USER` - n8n login username
- `N8N_BASIC_AUTH_PASSWORD` - n8n login password
- `N8N_HOST` - Your domain or VPS IP
- `N8N_WEBHOOK_URL` - `http://your-vps-ip:5678`

**Discord:**
- `DISCORD_GUILD_ID` - Server ID
- `DISCORD_BOT_TOKEN_VANCE` - Gen. Vance bot token
- `DISCORD_CLIENT_ID_VANCE` - Gen. Vance client ID
- `CHANNEL_GENERAL_VANCE` - Channel ID for Gen. Vance
- `CHANNEL_COMMAND_BRIEFING` - Optional command channel

**Claude API:**
- `ANTHROPIC_API_KEY` - Claude API key

### 3. Deploy
Push to main branch or run manual deployment

## Services

After deployment, these services run on VPS:

| Service | Port | Access |
|---------|------|--------|
| n8n Web UI | 5678 | `http://your-vps-ip:5678` |
| PostgreSQL | 5432 | Internal only |
| Gen. Vance Bot | - | Discord (always online) |

## Monitoring

### View Logs
```bash
# All services
docker-compose logs -f

# Specific service
docker-compose logs -f bot-general-vance
docker-compose logs -f n8n
docker-compose logs -f postgres
```

### Check Status
```bash
docker-compose ps
```

### Resource Usage
```bash
docker stats
```

## Troubleshooting

### Deployment Failed
1. Check GitHub Actions logs: Repository → Actions → Failed workflow
2. SSH to VPS and check logs:
   ```bash
   cd ~/eha-command-bots
   docker-compose logs
   ```

### Bot Offline
```bash
# Check bot container
docker-compose logs bot-general-vance

# Restart bot
docker-compose restart bot-general-vance
```

### n8n Not Accessible
```bash
# Check n8n container
docker-compose logs n8n

# Verify port is open
sudo ufw status
sudo ufw allow 5678/tcp

# Restart n8n
docker-compose restart n8n
```

### Database Issues
```bash
# Check database logs
docker-compose logs postgres

# Access database console
docker-compose exec postgres psql -U eha_user -d eha_command
```

## Useful Commands

### Restart Everything
```bash
docker-compose restart
```

### Rebuild from Scratch
```bash
docker-compose down
docker-compose build --no-cache
docker-compose up -d
```

### Update Without Downtime
```bash
git pull origin main
docker-compose up -d --build
```

### Clean Up Old Images
```bash
docker system prune -a
```

## Cost

**Monthly:** £8 (Hostinger KVM 2)
**Yearly:** £96 + ~£10 domain (optional)

## Security

- ✅ Secrets stored in GitHub Secrets (never in repo)
- ✅ `.env` file not committed (in .gitignore)
- ✅ UFW firewall enabled on VPS
- ✅ SSH key authentication (no passwords)
- ✅ Non-root user for deployments
- ✅ Docker containers run as non-root users

## Scaling

To add more officer bots:
1. Copy `discord-bot-general-vance` folder
2. Update bot name and config
3. Add service to `docker-compose.yml`
4. Add secrets to GitHub Secrets
5. Push to deploy

## Backup

### Database Backup
```bash
# Manual backup
docker-compose exec postgres pg_dump -U eha_user eha_command > backup.sql

# Automated daily backups (add to crontab)
0 2 * * * cd ~/eha-command-bots && docker-compose exec -T postgres pg_dump -U eha_user eha_command > backups/backup-$(date +\%Y\%m\%d).sql
```

### n8n Workflows Backup
Workflows are stored in `n8n_data` volume and in the repository under `n8n-workflows/`

## Support

If deployment fails:
1. Check GitHub Actions logs
2. SSH to VPS and check container logs
3. Verify GitHub Secrets are configured correctly
4. Check VPS firewall settings
5. Verify Discord bot tokens are valid
