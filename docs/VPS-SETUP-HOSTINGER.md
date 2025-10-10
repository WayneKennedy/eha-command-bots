# VPS Setup Guide - Hostinger KVM 2

This guide walks you through setting up your Hostinger VPS for EHA Command Bots with Docker and GitHub Actions CI/CD.

## Prerequisites

- Hostinger KVM 2 VPS (£8/month)
- Ubuntu 22.04 LTS installed
- SSH access to VPS
- Domain name (optional, for HTTPS)

---

## Part 1: Initial VPS Setup

### Step 1: Connect to VPS

```bash
ssh root@your-vps-ip
```

### Step 2: Update System

```bash
apt update && apt upgrade -y
```

### Step 3: Create Deploy User

```bash
# Create user for deployments
adduser ehaadmin
usermod -aG sudo ehaadmin

# Switch to new user
su - ehaadmin
```

### Step 4: Set Up SSH Key for GitHub Actions

```bash
# Generate SSH key for GitHub Actions
ssh-keygen -t ed25519 -C "github-actions@eha-bots" -f ~/.ssh/github_actions

# Add to authorized_keys
cat ~/.ssh/github_actions.pub >> ~/.ssh/authorized_keys
chmod 600 ~/.ssh/authorized_keys

# Display private key (copy this for GitHub Secrets)
cat ~/.ssh/github_actions
```

**Important:** Copy the entire private key output - you'll add this to GitHub Secrets as `VPS_SSH_PRIVATE_KEY`

---

## Part 2: Install Docker

### Step 5: Install Docker

```bash
# Install dependencies
sudo apt install -y apt-transport-https ca-certificates curl software-properties-common

# Add Docker's GPG key
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg

# Add Docker repository
echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

# Install Docker
sudo apt update
sudo apt install -y docker-ce docker-ce-cli containerd.io

# Add user to docker group
sudo usermod -aG docker $USER

# Log out and back in for group change to take effect
exit
# SSH back in
ssh ehaadmin@your-vps-ip
```

### Step 6: Install Docker Compose

```bash
# Download Docker Compose
sudo curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose

# Make executable
sudo chmod +x /usr/local/bin/docker-compose

# Verify installation
docker --version
docker-compose --version
```

---

## Part 3: Clone Repository

### Step 7: Set Up Git

```bash
# Install git
sudo apt install -y git

# Configure git
git config --global user.name "EHA Admin"
git config --global user.email "admin@eha.local"
```

### Step 8: Clone Repository

```bash
# Clone your repository
cd ~
git clone https://github.com/WayneKennedy/eha-command-bots.git
cd eha-command-bots
```

### Step 9: Create .env File

```bash
# Copy example
cp .env.example .env

# Edit with your secrets
nano .env
```

Add your actual secrets:
```bash
# PostgreSQL
POSTGRES_DB=eha_command
POSTGRES_USER=eha_user
POSTGRES_PASSWORD=your_secure_password_here

# n8n Configuration
N8N_BASIC_AUTH_USER=admin
N8N_BASIC_AUTH_PASSWORD=your_n8n_password
N8N_HOST=your-domain.com
N8N_PROTOCOL=http
N8N_WEBHOOK_URL=http://your-vps-ip:5678

# Discord Configuration
DISCORD_GUILD_ID=your_guild_id
DISCORD_BOT_TOKEN_VANCE=your_bot_token
DISCORD_CLIENT_ID_VANCE=your_client_id
CHANNEL_GENERAL_VANCE=your_channel_id
CHANNEL_COMMAND_BRIEFING=

# Claude API
ANTHROPIC_API_KEY=your_claude_api_key

# Bot Settings
DEBUG_MODE=false
RESPONSE_DELAY_MS=1500
```

Save (Ctrl+O, Enter, Ctrl+X)

---

## Part 4: GitHub Secrets Setup

### Step 10: Add Secrets to GitHub

Go to your GitHub repository → Settings → Secrets and variables → Actions → New repository secret

Add these secrets:

| Secret Name | Value | Description |
|-------------|-------|-------------|
| `VPS_SSH_PRIVATE_KEY` | *(private key from Step 4)* | SSH key for deployment |
| `VPS_HOST` | `your-vps-ip` | VPS IP address |
| `VPS_USER` | `ehaadmin` | VPS username |
| `POSTGRES_PASSWORD` | *(your password)* | Database password |
| `N8N_BASIC_AUTH_USER` | `admin` | n8n username |
| `N8N_BASIC_AUTH_PASSWORD` | *(your password)* | n8n password |
| `N8N_HOST` | `your-domain.com` or `your-vps-ip` | n8n host |
| `N8N_WEBHOOK_URL` | `http://your-vps-ip:5678` | n8n webhook URL |
| `DISCORD_GUILD_ID` | *(your server ID)* | Discord server ID |
| `DISCORD_BOT_TOKEN_VANCE` | *(your bot token)* | Gen. Vance bot token |
| `DISCORD_CLIENT_ID_VANCE` | *(your client ID)* | Gen. Vance client ID |
| `CHANNEL_GENERAL_VANCE` | *(your channel ID)* | Gen. Vance channel |
| `CHANNEL_COMMAND_BRIEFING` | *(optional)* | Command briefing channel |
| `ANTHROPIC_API_KEY` | *(your Claude key)* | Claude API key |

---

## Part 5: Initial Deployment

### Step 11: Test Manual Deployment

```bash
cd ~/eha-command-bots

# Make deploy script executable
chmod +x scripts/deploy.sh

# Run initial deployment
./scripts/deploy.sh
```

This will:
1. Pull latest code
2. Build Docker images
3. Start all services
4. Show container status

### Step 12: Verify Services Running

```bash
# Check container status
docker-compose ps

# Should show:
# - eha-postgres (healthy)
# - eha-n8n (healthy)
# - eha-bot-vance (healthy)

# View logs
docker-compose logs -f
```

---

## Part 6: Firewall Configuration

### Step 13: Configure UFW Firewall

```bash
# Install UFW
sudo apt install -y ufw

# Allow SSH (important!)
sudo ufw allow 22/tcp

# Allow n8n web interface
sudo ufw allow 5678/tcp

# Allow HTTP/HTTPS (if using nginx)
sudo ufw allow 80/tcp
sudo ufw allow 443/tcp

# Enable firewall
sudo ufw enable

# Check status
sudo ufw status
```

---

## Part 7: Test GitHub Actions Deployment

### Step 14: Trigger Deployment

1. Make a small change to your repository (edit README)
2. Commit and push to main branch:
   ```bash
   git add .
   git commit -m "Test deployment"
   git push origin main
   ```

3. Go to GitHub → Actions tab
4. Watch the deployment workflow run
5. Verify success

### Step 15: Verify on VPS

```bash
# SSH to VPS
ssh ehaadmin@your-vps-ip

# Check containers
cd ~/eha-command-bots
docker-compose ps
docker-compose logs --tail=50
```

---

## Useful Commands

### Managing Services

```bash
# View all logs
docker-compose logs -f

# View specific service logs
docker-compose logs -f bot-general-vance
docker-compose logs -f n8n

# Restart services
docker-compose restart

# Stop all services
docker-compose down

# Start services
docker-compose up -d

# Rebuild and restart
docker-compose up -d --build
```

### Monitoring

```bash
# Check resource usage
docker stats

# Check disk space
df -h

# Check logs size
du -sh ~/eha-command-bots
```

### Troubleshooting

```bash
# If deployment fails, check logs
cd ~/eha-command-bots
docker-compose logs

# Rebuild from scratch
docker-compose down -v
docker-compose build --no-cache
docker-compose up -d

# Check GitHub Actions logs on GitHub
# Repository → Actions → Latest workflow run
```

---

## Security Checklist

- ✅ SSH key authentication (no password login)
- ✅ Firewall enabled (UFW)
- ✅ Non-root user for deployments
- ✅ Secrets in GitHub Secrets (not in repo)
- ✅ .env file not committed to git
- ✅ Regular system updates

---

## Next Steps

Once everything is running:
1. Access n8n at `http://your-vps-ip:5678`
2. Import General Vance workflow
3. Test Discord bot functionality
4. Set up domain and HTTPS (optional)
5. Configure monitoring and alerts

---

## Cost Optimization

**Current Setup:**
- Hostinger KVM 2: £8/month
- Domain (optional): ~£10/year

**Tips:**
- Monitor resource usage with `docker stats`
- Set up log rotation to save disk space
- Use Docker image cleanup: `docker system prune -a`
