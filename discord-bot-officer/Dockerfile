# Generic Officer Discord Bot - Production Dockerfile
FROM node:20-alpine

# Set working directory
WORKDIR /app

# Install dependencies first (for better caching)
COPY package*.json ./
RUN npm install --only=production

# Copy application code
COPY . .

# Create directories for mounted volumes
RUN mkdir -p /app/officers /app/knowledge-base

# Create non-root user for security
RUN addgroup -g 1001 -S nodejs && \
    adduser -S nodejs -u 1001 && \
    chown -R nodejs:nodejs /app

USER nodejs

# Health check - verify node process is running
HEALTHCHECK --interval=30s --timeout=10s --start-period=10s --retries=3 \
  CMD pgrep node || exit 1

# Run the bot
CMD ["node", "index.js"]
