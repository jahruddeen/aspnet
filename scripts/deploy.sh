#!/bin/bash

# Deployment Script for ASP.NET Application
# This script handles deployment on the server side

set -e

echo "=== Starting Deployment Process ==="

# Color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Deployment directory
DEPLOY_DIR="/app/website"
BACKUP_DIR="/app/backups"
LOG_FILE="/var/log/deployment.log"

# Function to log messages
log() {
    echo -e "${GREEN}[$(date +'%Y-%m-%d %H:%M:%S')]${NC} $1" | tee -a "$LOG_FILE"
}

error() {
    echo -e "${RED}[ERROR]${NC} $1" | tee -a "$LOG_FILE"
    exit 1
}

warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1" | tee -a "$LOG_FILE"
}

# Check if deployment directory exists
if [ ! -d "$DEPLOY_DIR" ]; then
    error "Deployment directory does not exist: $DEPLOY_DIR"
fi

# Create backup directory if it doesn't exist
mkdir -p "$BACKUP_DIR"

cd "$DEPLOY_DIR"

log "Pulling latest changes from repository..."
git fetch origin || error "Failed to fetch from repository"
git checkout "$BRANCH" || error "Failed to checkout branch"
git pull origin "$BRANCH" || error "Failed to pull changes"

# Backup current state
BACKUP_NAME="backup-$(date +%Y%m%d-%H%M%S)"
log "Creating backup: $BACKUP_NAME"
if docker-compose ps -q web > /dev/null 2>&1; then
    docker-compose exec -T web tar -czf - /app/publish > "$BACKUP_DIR/$BACKUP_NAME.tar.gz" || warning "Backup creation had issues"
fi

log "Pulling Docker images..."
docker-compose pull || error "Failed to pull Docker images"

log "Stopping running containers..."
docker-compose down || warning "Failed to stop some containers"

log "Starting services..."
docker-compose up -d || error "Failed to start services"

log "Waiting for services to be healthy..."
sleep 10

# Check health
log "Checking application health..."
for i in {1..30}; do
    if curl -sf http://localhost/health > /dev/null 2>&1; then
        log "Application is healthy!"
        break
    fi
    if [ $i -eq 30 ]; then
        error "Application failed health check after 30 attempts"
    fi
    sleep 2
done

# Run database migrations if needed
log "Running database migrations..."
docker-compose exec -T web dotnet migrate || warning "Database migration had issues"

# Clean up old backups (keep last 7)
log "Cleaning up old backups..."
ls -t "$BACKUP_DIR"/backup-*.tar.gz 2>/dev/null | tail -n +8 | xargs -r rm

log "=== Deployment completed successfully! ==="
