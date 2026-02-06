# Self-Hosted GitHub Actions Runner Setup

This guide walks you through setting up a self-hosted GitHub Actions runner for the CI/CD pipeline.

## Prerequisites

- Linux server (Ubuntu 20.04+ recommended)
- Root or sudo access
- Git installed
- Docker installed
- .NET SDK 8.0+ installed
- At least 4GB RAM and 20GB disk space

## Step 1: Register Self-Hosted Runner with GitHub

### 1.1 Go to GitHub Repository Settings

1. Navigate to your repository: `https://github.com/your-username/aspnet`
2. Click **Settings** → **Actions** → **Runners**
3. Click **New self-hosted runner**

### 1.2 Download and Configure Runner

On your Linux server, execute these commands:

```bash
# Create runner directory
mkdir -p /opt/actions-runner
cd /opt/actions-runner

# Download the latest runner release
curl -o actions-runner-linux-x64.tar.gz \
  -L https://github.com/actions/runner/releases/download/v2.311.0/actions-runner-linux-x64-2.311.0.tar.gz

# Extract the installer
tar xzf actions-runner-linux-x64.tar.gz

# Remove the installer
rm actions-runner-linux-x64.tar.gz

# Configure the runner (follow prompts from GitHub)
./config.sh --url https://github.com/your-username/aspnet --token YOUR_TOKEN_HERE
```

When prompted:
- **Enter name of runner**: `self-hosted-01` (or your preferred name)
- **Enter any labels** (optional): `linux,x64,docker,dotnet`
- **Enter name of work folder** (default): Press enter to accept
- **Enter additional labels** (optional): Leave blank

### 1.3 Install Runner as a Service

```bash
# Install the runner as a systemd service
sudo ./svc.sh install

# Start the service
sudo ./svc.sh start

# Check status
sudo ./svc.sh status
```

### 1.4 Verify Runner is Connected

Go back to GitHub → Settings → Actions → Runners

You should see your runner with a green dot (online status).

## Step 2: Configure System for CI/CD

### 2.1 Ensure Required Tools are Installed

```bash
# Update system
sudo apt-get update && sudo apt-get upgrade -y

# Install .NET 8.0
wget https://dot.net/v1/dotnet-install.sh -O dotnet-install.sh
chmod +x dotnet-install.sh
./dotnet-install.sh --channel 8.0

# Add dotnet to PATH
echo 'export PATH=$PATH:/root/.dotnet' >> ~/.bashrc
source ~/.bashrc

# Verify .NET installation
dotnet --version

# Install Docker (if not already installed)
sudo apt-get install -y docker.io
sudo usermod -aG docker $USER
newgrp docker

# Install Docker Compose
sudo curl -L \
  "https://github.com/docker/compose/releases/download/v2.20.0/docker-compose-$(uname -s)-$(uname -m)" \
  -o /usr/local/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-compose

# Verify Docker installation
docker --version
docker-compose --version

# Install other dependencies
sudo apt-get install -y curl wget git ssh openssh-client
```

### 2.2 Configure Docker for Runner User

```bash
# If runner is running as non-root user
sudo usermod -aG docker actions-runner

# Test Docker access
docker ps
```

## Step 3: Managing the Self-Hosted Runner

### Start/Stop the Runner Service

```bash
# Start the runner
sudo systemctl start actions-runner

# Stop the runner
sudo systemctl stop actions-runner

# Check status
sudo systemctl status actions-runner

# View logs
sudo journalctl -u actions-runner -f
```

### Manage Runner from Directory

```bash
cd /opt/actions-runner

# Start runner (manual mode)
./run.sh

# Stop runner (Ctrl+C)

# Uninstall service
sudo ./svc.sh uninstall

# Remove runner from GitHub
./config.sh remove --token YOUR_TOKEN_HERE
```

## Step 4: GitHub Secrets for Self-Hosted

Ensure these secrets are set in your repository:

```
STAGING_HOST=staging.example.com
STAGING_USER=deploy
STAGING_DEPLOY_KEY=<base64-encoded-ssh-key>

PROD_HOST=prod.example.com
PROD_USER=deploy
PROD_DEPLOY_KEY=<base64-encoded-ssh-key>

DB_PASSWORD=<strong-password>
SLACK_WEBHOOK=<slack-webhook-url>
```

## Step 5: Optimize Workflow for Self-Hosted

### Skip Setup .NET (if pre-installed)

Edit `.github/workflows/ci-cd.yml` and remove or comment out:

```yaml
# - name: Setup .NET
#   uses: actions/setup-dotnet@v3
#   with:
#     dotnet-version: '8.0.x'
```

### Enable Docker BuildKit

Add to your environment or systemd service:

```bash
# In /etc/systemd/system/actions-runner.service
[Service]
Environment="DOCKER_BUILDKIT=1"
```

Or export in your shell:

```bash
echo 'export DOCKER_BUILDKIT=1' >> ~/.bashrc
source ~/.bashrc
```

## Step 6: Runner Labels

Labels help identify which runner should execute which job. You can:

### View Current Labels

```bash
# Check labels on GitHub
# Settings → Actions → Runners → Your Runner Name
```

### Add Custom Labels

```bash
cd /opt/actions-runner
./config.sh --unattended --replace-existing-config
```

Then use labels in workflow:

```yaml
jobs:
  build:
    runs-on: [self-hosted, linux, x64, docker]
    # Job will run on self-hosted runners with these labels
```

## Step 7: Monitor Runner Health

### Check Disk Space

```bash
df -h
# Ensure at least 20GB free space for builds and Docker images
```

### Clean Up Docker

```bash
# Remove dangling images
docker image prune -f

# Remove stopped containers
docker container prune -f

# Remove unused volumes
docker volume prune -f

# Full cleanup (warning: removes all unused resources)
docker system prune -a --volumes
```

### Monitor Runner Process

```bash
# View runner process
ps aux | grep "[r]un.sh"

# View memory usage
free -h

# View CPU usage
top -b -n 1 | head -20
```

## Step 8: Troubleshooting Self-Hosted Runners

### Runner Offline

```bash
# Check runner service status
sudo systemctl status actions-runner

# Restart runner
sudo systemctl restart actions-runner

# Check logs
sudo journalctl -u actions-runner -n 50 -f
```

### Workflow Fails with "No runners available"

1. Verify runner is registered:
   ```bash
   GitHub → Settings → Actions → Runners
   ```

2. Check labels match:
   ```yaml
   runs-on: [self-hosted, linux, x64]
   ```

3. Restart runner:
   ```bash
   sudo systemctl restart actions-runner
   ```

### Permission Denied Errors

```bash
# Check Docker permissions
sudo usermod -aG docker $USER
newgrp docker

# Check SSH key permissions
chmod 600 ~/.ssh/*
chmod 700 ~/.ssh

# Check runner directory permissions
sudo chown -R actions-runner:actions-runner /opt/actions-runner
```

### Out of Disk Space

```bash
# Check disk usage
du -sh /root/.cache
du -sh /var/lib/docker

# Clean up Docker
docker system prune -a --volumes

# Clean up runner work directory
rm -rf /opt/actions-runner/_work/*

# Extend disk (if using VM)
# Usually requires resizing the filesystem
```

### Network Connectivity Issues

```bash
# Test connectivity to GitHub
curl -I https://github.com

# Test DNS resolution
nslookup github.com

# Check firewall rules
sudo ufw status
sudo ufw allow 443  # HTTPS for GitHub API
```

## Step 9: Security Best Practices

### 1. Network Security

```bash
# Restrict access to runner machine
sudo ufw enable
sudo ufw allow ssh
sudo ufw allow from 10.0.0.0/8  # Allow from your network

# Use VPN for remote access
```

### 2. Runner Isolation

```bash
# Run runner as non-root user
sudo useradd -m -s /bin/bash actions-runner
sudo usermod -aG docker actions-runner

# Set up sudoers if needed
sudo visudo
# actions-runner ALL=(ALL) NOPASSWD: /usr/bin/systemctl
```

### 3. Secret Management

```bash
# Never commit secrets to repository
# Always use GitHub Secrets

# Verify secrets are masked in logs
# Looking at Actions logs, secrets should appear as ***
```

### 4. Keep Runner Updated

```bash
# Check for updates regularly
# GitHub will notify you in your repository

# Update steps:
cd /opt/actions-runner
sudo ./svc.sh stop
git pull origin main  # or download new version
sudo ./svc.sh start
```

## Step 10: Multiple Runners (Optional)

For high availability or load distribution:

### Setup Multiple Runners

```bash
# Runner 1
cd /opt/actions-runner-1
./config.sh --url ... --token ...
sudo ./svc.sh install --user actions-runner
sudo ./svc.sh start

# Runner 2
cd /opt/actions-runner-2
./config.sh --url ... --token ...
sudo ./svc.sh install --user actions-runner
sudo ./svc.sh start

# Both runners will handle jobs in parallel
```

### Load Balancing

```yaml
# They'll be automatically load balanced
# GitHub will distribute jobs across available runners
```

## Useful Commands

```bash
# View all runner processes
ps aux | grep actions

# Check runner configuration
cat /opt/actions-runner/.runner

# View recent logs
sudo journalctl -u actions-runner --no-pager | tail -100

# Restart runner
sudo systemctl restart actions-runner

# Stop runner gracefully (current jobs complete)
sudo systemctl stop actions-runner

# Force stop runner
sudo systemctl kill -9 actions-runner
```

## Support & Resources

- [GitHub Actions Self-Hosted Runners Documentation](https://docs.github.com/en/actions/hosting-your-own-runners)
- [GitHub Actions Runner Releases](https://github.com/actions/runner/releases)
- [Self-Hosted Runner Troubleshooting](https://docs.github.com/en/actions/hosting-your-own-runners/managing-self-hosted-runners/troubleshooting-self-hosted-runners)

## Checklist

- [ ] Runner downloaded and extracted
- [ ] Runner configured and registered
- [ ] Service installed and running
- [ ] Docker installed and accessible
- [ ] .NET 8.0 installed
- [ ] SSH keys configured for deployments
- [ ] GitHub Secrets added
- [ ] Workflow updated with self-hosted labels
- [ ] First workflow run successful
- [ ] Monitoring in place
