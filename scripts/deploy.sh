#!/bin/bash

# EHA Command Bots - Manual Deployment Script
# Use this script to manually deploy to VPS if GitHub Actions isn't working

set -e

echo "🚀 EHA Command Bots - Manual Deployment"
echo "========================================"

# Check if .env exists
if [ ! -f .env ]; then
  echo "❌ Error: .env file not found!"
  echo "Please create .env file with your secrets"
  exit 1
fi

# Pull latest changes
echo "📥 Pulling latest code..."
git pull origin main

# Stop existing containers
echo "🛑 Stopping containers..."
docker-compose down

# Build bot image
echo "🏗️  Building Gen. Vance bot..."
docker-compose build bot-general-vance

# Start all services
echo "▶️  Starting all services..."
docker-compose up -d

# Wait for services to start
echo "⏳ Waiting for services to start..."
sleep 10

# Check status
echo ""
echo "📊 Container Status:"
docker-compose ps

echo ""
echo "📋 Recent Logs:"
docker-compose logs --tail=30

echo ""
echo "✅ Deployment complete!"
echo ""
echo "Useful commands:"
echo "  View logs:       docker-compose logs -f"
echo "  Restart:         docker-compose restart"
echo "  Stop:            docker-compose down"
echo "  Check status:    docker-compose ps"
