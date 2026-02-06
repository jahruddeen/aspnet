# CI/CD Quick Reference Guide

## Pipeline Triggers

### Automatic Triggers
- **Push to `main`** → Builds, tests, and deploys to production
- **Push to `develop`** → Builds, tests, and deploys to staging
- **Pull Request** → Builds and runs tests only (no deployment)

## Local Testing

### Test Locally Before Pushing

```bash
# Build locally
dotnet build -c Release

# Run tests
dotnet test -c Release

# Build Docker image
docker build -t my-app:latest .

# Test Docker image
docker-compose up -d
docker-compose logs -f web
```

## GitHub Actions Commands

### View Workflow Status
1. Go to GitHub repository
2. Click "Actions" tab
3. Select workflow run to view logs

### Manually Trigger Workflow

```bash
# Using GitHub CLI
gh workflow run ci-cd.yml --ref main

# Or trigger via GitHub UI:
# Actions → Select Workflow → Run workflow → Choose branch
```

### View Workflow Logs

```bash
# List recent workflow runs
gh run list --workflow ci-cd.yml

# View specific run
gh run view <RUN_ID> --log

# Watch live logs
gh run watch <RUN_ID> --exit-status
```

## Server Commands

### View Application Status

```bash
# Check running containers
docker-compose ps

# Check application health
curl http://localhost/health

# Check specific service
docker-compose logs -f web    # Application logs
docker-compose logs -f db     # Database logs
docker-compose logs -f nginx  # Reverse proxy logs
```

### Manual Deployment

```bash
cd /app/website

# Pull latest code
git pull origin main

# Update containers
docker-compose pull
docker-compose up -d

# Run migrations
docker-compose exec -T web dotnet migrate

# View deployment log
tail -f /var/log/deployment.log
```

### Rollback to Previous Version

```bash
# Restore from backup
cd /app/backups
tar -xzf backup-YYYYMMDD-HHMMSS.tar.gz -C /app/website/

# Restart services
cd /app/website
docker-compose restart web
```

### Scale Application

```bash
# Run multiple instances
docker-compose up -d --scale web=3

# Deploy behind load balancer (update nginx.conf)
upstream aspnet_backend {
    server web:80;
    server web:80;
    server web:80;
}
```

## Common Issues & Solutions

### Issue: Docker image not found

```bash
# Solution: Check image name
docker-compose config | grep image

# Verify image exists
docker images | grep your-repo
```

### Issue: Health check fails

```bash
# Solution: Check application logs
docker logs $(docker ps -q -f "ancestor=your-image")

# Verify endpoint exists
docker exec <container-id> curl http://localhost/health
```

### Issue: Permission denied on SSH

```bash
# Solution: Fix SSH key permissions
chmod 600 ~/.ssh/deploy_key
ssh-keyscan -H your-host >> ~/.ssh/known_hosts
```

### Issue: Database connection fails

```bash
# Solution: Check database status
docker-compose logs db

# Verify connection string
echo $DB_CONNECTION_STRING

# Test connection
docker-compose exec -T db sqlcmd -S 127.0.0.1 -U sa -P $SA_PASSWORD
```

## Performance Optimization

### View Build Time
- Check GitHub Actions logs for each step timing
- Click on the workflow run to see detailed timing

### Optimize Dockerfile
```dockerfile
# Use layer caching efficiently
FROM mcr.microsoft.com/dotnet/sdk:8.0 AS build
COPY ["*.csproj", "./"]
RUN dotnet restore    # Cache this layer
COPY . .
RUN dotnet build      # This layer updates more often
```

### Enable Docker BuildKit

```bash
# On server
export DOCKER_BUILDKIT=1

# In docker-compose.yml
DOCKER_BUILDKIT=1 docker-compose build
```

## Monitoring & Logging

### Application Insights (optional)

```bash
# Add to .env
APPLICATIONINSIGHTS_CONNECTION_STRING="<your-connection-string>"

# Update Program.cs to enable
builder.Services.AddApplicationInsightsTelemetry();
```

### Cloudflare Logs

```bash
# View access logs
docker-compose exec -T nginx cat /var/log/nginx/access.log

# View error logs
docker-compose exec -T nginx cat /var/log/nginx/error.log
```

### Real-time Monitoring

```bash
# Watch all logs
docker-compose logs -f

# Watch specific service
docker-compose logs -f web --tail=100

# Search logs
docker-compose logs web | grep "ERROR"
```

## Security Checks

### Scan Docker Image for Vulnerabilities

```bash
# Using Trivy
trivy image your-username/your-repo:latest

# Fix vulnerabilities
docker pull your-username/your-repo:latest
# Update base image version in Dockerfile
```

### View Security Alerts

1. GitHub → Security → Code scanning alerts
2. Trivy scans in GitHub Actions logs

## Deployment Checklist

- [ ] All tests passing in CI
- [ ] Security scan passes
- [ ] Docker image builds successfully
- [ ] Staging deployment successful
- [ ] Health checks passing
- [ ] Manual testing completed
- [ ] Ready for production push

## Useful git Commands

```bash
# Create feature branch
git checkout -b feature/my-feature

# Commit changes
git commit -am "Add feature"

# Push to develop (for staging test)
git push origin feature/my-feature
git checkout develop
git merge feature/my-feature
git push origin develop

# Create release branch
git checkout -b release/1.0.0
git push origin release/1.0.0

# Merge to main (triggers production deploy)
git checkout main
git merge release/1.0.0
git push origin main
git tag -a v1.0.0 -m "Version 1.0.0"
git push origin v1.0.0
```

## Emergency Procedures

### Quick Rollback

```bash
# SSH into server
ssh deploy@your-server

# Stop application
cd /app/website
docker-compose down

# Restore from backup
tar -xzf /app/backups/backup-latest.tar.gz -C .

# Start services
docker-compose up -d

# Verify health
curl http://localhost/health
```

### Disable Auto-Deploy Temporarily

1. Go to GitHub → Settings → Branch protection rules
2. Require status checks to pass
3. Temporarily pause the workflow

```bash
# Or disable via CLI
gh workflow disable ci-cd.yml
gh workflow enable ci-cd.yml
```

## Support & Debugging

```bash
# Collect diagnostics
docker-compose version
docker version
git version
dotnet --version

# Generate support bundle
tar -czf debug-$(date +%s).tar.gz \
  docker-compose logs \
  /var/log/deployment.log \
  .env

# Check disk space
df -h
du -sh /app/website
du -sh /var/lib/docker
```
