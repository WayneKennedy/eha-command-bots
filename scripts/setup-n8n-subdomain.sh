#!/bin/bash

# EHA Command Bots - n8n Subdomain Setup Script
# Sets up n8n.zappfyre.cloud with Nginx reverse proxy and SSL

set -e

echo "🌐 Setting up n8n.zappfyre.cloud with Nginx and SSL"
echo "===================================================="
echo ""

# Configuration
DOMAIN="n8n.zappfyre.cloud"
EMAIL="wayne@zappfyre.com"  # Update this!
VPS_USER="root"        # Update this!
VPS_HOST="zappfyre.cloud"          # Update this!

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${YELLOW}📋 Prerequisites Check${NC}"
echo "1. DNS A record for $DOMAIN should point to $VPS_HOST"
echo "2. Ports 80 and 443 should be accessible"
echo ""
read -p "Have you configured the DNS A record? (y/n) " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo -e "${RED}❌ Please configure DNS first in Hostinger control panel${NC}"
    echo "   Add A record: n8n -> $VPS_HOST"
    exit 1
fi

echo ""
echo -e "${GREEN}✓${NC} DNS configured"
echo ""

# Test DNS resolution
echo -e "${YELLOW}🔍 Testing DNS resolution...${NC}"
if nslookup $DOMAIN > /dev/null 2>&1; then
    echo -e "${GREEN}✓${NC} DNS is resolving correctly"
else
    echo -e "${YELLOW}⚠${NC}  DNS not resolving yet (might take a few minutes to propagate)"
    echo "   You can continue, but SSL setup will fail if DNS isn't ready"
    read -p "Continue anyway? (y/n) " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        exit 1
    fi
fi

echo ""
echo -e "${YELLOW}📦 Step 1: Installing Nginx${NC}"
ssh $VPS_USER@$VPS_HOST << 'ENDSSH'
set -e
echo "Updating package list..."
sudo apt update -qq

echo "Installing Nginx..."
sudo apt install -y nginx

echo "Starting and enabling Nginx..."
sudo systemctl start nginx
sudo systemctl enable nginx

echo "✓ Nginx installed"
ENDSSH

echo -e "${GREEN}✓${NC} Nginx installed successfully"
echo ""

echo -e "${YELLOW}⚙️  Step 2: Configuring Nginx reverse proxy${NC}"
ssh $VPS_USER@$VPS_HOST << 'ENDSSH'
set -e

# Create Nginx config
echo "Creating Nginx configuration for n8n.zappfyre.cloud..."
sudo tee /etc/nginx/sites-available/n8n.zappfyre.cloud > /dev/null << 'NGINX_CONFIG'
server {
    listen 80;
    server_name n8n.zappfyre.cloud;

    location / {
        proxy_pass http://localhost:5678;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host $host;
        proxy_cache_bypass $http_upgrade;

        # Additional headers for n8n
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;

        # WebSocket support (important for n8n)
        proxy_read_timeout 86400;
    }
}
NGINX_CONFIG

# Enable site
echo "Enabling site..."
sudo ln -sf /etc/nginx/sites-available/n8n.zappfyre.cloud /etc/nginx/sites-enabled/

# Test configuration
echo "Testing Nginx configuration..."
sudo nginx -t

# Reload Nginx
echo "Reloading Nginx..."
sudo systemctl reload nginx

# Configure firewall
echo "Opening firewall ports..."
sudo ufw allow 80/tcp > /dev/null 2>&1 || true
sudo ufw allow 443/tcp > /dev/null 2>&1 || true

echo "✓ Nginx reverse proxy configured"
ENDSSH

echo -e "${GREEN}✓${NC} Nginx configured successfully"
echo ""

echo -e "${YELLOW}🔒 Step 3: Installing SSL certificate with Let's Encrypt${NC}"
ssh $VPS_USER@$VPS_HOST << ENDSSH
set -e

# Install Certbot
echo "Installing Certbot..."
sudo apt install -y certbot python3-certbot-nginx

# Obtain SSL certificate
echo "Obtaining SSL certificate for $DOMAIN..."
sudo certbot --nginx -d $DOMAIN --non-interactive --agree-tos --email $EMAIL --redirect

echo "Testing auto-renewal..."
sudo certbot renew --dry-run

echo "✓ SSL certificate installed"
ENDSSH

echo -e "${GREEN}✓${NC} SSL certificate installed successfully"
echo ""

echo -e "${YELLOW}🔧 Step 4: Updating n8n configuration${NC}"
ssh $VPS_USER@$VPS_HOST << 'ENDSSH'
set -e

cd ~/eha-command-bots

# Backup .env
cp .env .env.backup

# Update n8n configuration
echo "Updating .env file..."
sed -i 's|N8N_HOST=.*|N8N_HOST=n8n.zappfyre.cloud|' .env
sed -i 's|N8N_PROTOCOL=.*|N8N_PROTOCOL=https|' .env
sed -i 's|N8N_WEBHOOK_URL=.*|N8N_WEBHOOK_URL=https://n8n.zappfyre.cloud|' .env

# Restart n8n
echo "Restarting n8n..."
docker-compose restart n8n

echo "Waiting for n8n to start..."
sleep 10

echo "✓ n8n configuration updated"
ENDSSH

echo -e "${GREEN}✓${NC} n8n configuration updated"
echo ""

echo -e "${GREEN}✅ Setup complete!${NC}"
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "🎉 n8n is now accessible at: ${GREEN}https://$DOMAIN${NC}"
echo ""
echo "📝 Next steps:"
echo "   1. Visit https://$DOMAIN"
echo "   2. Log in with your n8n credentials"
echo "   3. Update any existing webhooks to use the new URL"
echo ""
echo "🔧 Useful commands:"
echo "   Check Nginx status:    sudo systemctl status nginx"
echo "   Check SSL cert:        sudo certbot certificates"
echo "   Renew SSL manually:    sudo certbot renew"
echo "   View Nginx logs:       sudo tail -f /var/log/nginx/error.log"
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
