# CI/CD Pipeline Setup Guide

This guide walks you through setting up the CI/CD pipeline for your ASP.NET application.

## Architecture Overview

```
GitHub Repository
       ↓
   GitHub Actions
       ↓
   ├─ Build & Test
   ├─ Security Scan
   ├─ Docker Image Build
       ↓
   ├─ Deploy to Staging
   ├─ Deploy to Production
       ↓
   Slack Notification
```

## Prerequisites

- GitHub repository with administrative access
- Two servers (staging and production) with Docker installed
- SSH key pairs for server access
- Slack workspace (optional, for notifications)
- Docker Hub or GitHub Container Registry account

## Step 1: Configure GitHub Secrets

Go to your GitHub repository → Settings → Secrets and variables → Actions

Add the following secrets:

### Staging Environment
- `STAGING_HOST`: Your staging server hostname/IP
- `STAGING_USER`: SSH username (e.g., `deploy`)
- `STAGING_DEPLOY_KEY`: SSH private key (base64 encoded)

### Production Environment
- `PROD_HOST`: Your production server hostname/IP
- `PROD_USER`: SSH username (e.g., `deploy`)
- `PROD_DEPLOY_KEY`: SSH private key (base64 encoded)

### Database Credentials
- `DB_PASSWORD`: Strong SQL Server password

### Slack (Optional)
- `SLACK_WEBHOOK`: Your Slack incoming webhook URL

## Step 2: Generate SSH Keys

On your local machine:

```bash
ssh-keygen -t rsa -b 4096 -f deploy_key -N ""
```

Add the public key to your servers:

```bash
# On the server
mkdir -p ~/.ssh
cat deploy_key.pub >> ~/.ssh/authorized_keys
chmod 600 ~/.ssh/authorized_keys
```

Encode the private key for GitHub:

```bash
cat deploy_key | base64
# Copy output to STAGING_DEPLOY_KEY / PROD_DEPLOY_KEY
```

## Step 3: Server Setup

### On both servers, create deploy user:

```bash
sudo useradd -m -s /bin/bash deploy
sudo usermod -aG docker deploy
```

### Set up deployment directory:

```bash
sudo mkdir -p /app/website
sudo chown deploy:deploy /app/website
```

### Copy your project:

```bash
cd /app/website
git clone <your-repo-url> .
```

### Create .env file:

```bash
cp .env.example .env
# Edit .env with actual values
```

## Step 4: Update Configuration Files

### 1. Update Docker image name in docker-compose.yml

Replace `${GITHUB_REPOSITORY}` with your actual image name:

```bash
sed -i 's|${GITHUB_REPOSITORY}|your-username/your-repo|g' docker-compose.yml
sed -i 's|${GITHUB_SHA}|latest|g' docker-compose.yml
```

### 2. Update Dockerfile

Replace `YourAppName.dll` with your actual assembly name:

```bash
sed -i 's|YourAppName.dll|YourActualAppName.dll|g' Dockerfile
```

### 3. Update nginx.conf

Replace `your-domain.com` with your actual domain:

```bash
sed -i 's|your-domain.com|your-actual-domain.com|g' nginx.conf
```

### 4. Update .env files

```bash
# Copy example file
cp .env.example .env

# Edit with your values
nano .env
```

## Step 5: Set Up SSL Certificates

### Using Let's Encrypt (Recommended):

```bash
sudo apt-get update
sudo apt-get install certbot python3-certbot-nginx

sudo certbot certonly --standalone -d your-domain.com -d www.your-domain.com

# Copy certificates to deployment directory
sudo cp /etc/letsencrypt/live/your-domain.com/fullchain.pem ./certs/cert.pem
sudo cp /etc/letsencrypt/live/your-domain.com/privkey.pem ./certs/key.pem
sudo chown deploy:deploy ./certs/*
```

## Step 6: Initialize Deployment

First manual deployment:

```bash
cd /app/website
docker-compose up -d
docker-compose logs -f
```

## Step 7: Create Systemd Service (Optional)

Create `/etc/systemd/system/aspnet-app.service`:

```ini
[Unit]
Description=ASP.NET Application
After=docker.service
Requires=docker.service

[Service]
Type=simple
User=deploy
WorkingDirectory=/app/website
ExecStart=/usr/bin/docker-compose up
ExecStop=/usr/bin/docker-compose down
Restart=always
RestartSec=10

[Install]
WantedBy=multi-user.target
```

Enable the service:

```bash
sudo systemctl daemon-reload
sudo systemctl enable aspnet-app
```

## Step 8: Monitoring and Logs

### View pipeline logs:
- Go to GitHub → Actions → Select workflow

### View application logs:
```bash
docker-compose logs -f web
```

### View application health:
```bash
curl http://localhost/health
```

## Troubleshooting

### Build Fails
- Check GitHub Actions logs
- Ensure .csproj file dependencies are correct
- Verify .NET SDK version

### Deployment Fails
- Check SSH connectivity: `ssh -i deploy_key deploy@your-server`
- Verify secrets are correctly set in GitHub
- Check Docker daemon is running: `docker ps`

### Health Check Fails
- Check application logs: `docker-compose logs web`
- Verify health endpoint exists: `/health`
- Check port mappings: `docker-compose ps`

### SSL Certificate Issues
- Verify certificate paths in nginx.conf
- Check certificate expiry: `openssl x509 -in cert.pem -noout -dates`
- Renew with: `certbot renew`

## Pipeline Stages

### 1. Build & Test
- Restores NuGet packages
- Builds application in Release configuration
- Runs unit tests
- Collects code coverage

### 2. Security Scan
- Scans for vulnerabilities using Trivy
- Reports security issues to GitHub

### 3. Docker Build
- Creates Docker image
- Pushes to container registry
- Tags with branch, version, and commit SHA

### 4. Deploy Staging
- Triggered on `develop` branch pushes
- Pulls latest code and Docker images
- Restarts services with new version

### 5. Deploy Production
- Triggered on `main` branch pushes
- Rolls back on failure
- Runs database migrations
- Sends Slack notification

## Best Practices

1. **Use semantic versioning** for releases
2. **Always test** in staging before production
3. **Monitor logs** regularly
4. **Keep backups** for quick rollback
5. **Use environment variables** for secrets
6. **Health checks** should be comprehensive
7. **Document deployments** in commit messages
8. **Review security policies** regularly

## Next Steps

1. Update your .csproj with test project
2. Add health endpoint to your ASP.NET application
3. Configure database connection strings
4. Set up monitoring (Application Insights, Datadog, etc.)
5. Create runbooks for common issues
