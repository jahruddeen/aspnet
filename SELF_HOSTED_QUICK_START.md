# Self-Hosted GitHub Actions Runner - Quick Start

Your CI/CD pipeline has been configured for **self-hosted runners**. This means your builds will run on your own servers instead of GitHub's infrastructure.

## What Changed?

All workflow files now use `runs-on: [self-hosted, linux, x64]` instead of `runs-on: ubuntu-latest`.

## Files Created/Modified

### New Workflow
- **[.github/workflows/ci-cd-self-hosted.yml](.github/workflows/ci-cd-self-hosted.yml)** - Optimized version for self-hosted runners
  - Removes unnecessary setup steps
  - Adds Docker cleanup job
  - Includes automatic rollback on failed health checks

### Original Workflow (Updated)
- **[.github/workflows/ci-cd.yml](.github/workflows/ci-cd.yml)** - Now uses self-hosted runners

### Documentation
- **[SELF_HOSTED_RUNNER_SETUP.md](SELF_HOSTED_RUNNER_SETUP.md)** - Complete setup guide

## Quick Setup (5 Steps)

### 1. Prepare Your Server

```bash
# Install dependencies
sudo apt-get update && sudo apt-get upgrade -y
sudo apt-get install -y docker.io git curl wget

# Install .NET 8.0
wget https://dot.net/v1/dotnet-install.sh
chmod +x dotnet-install.sh
./dotnet-install.sh --channel 8.0

# Install Docker Compose
sudo curl -L "https://github.com/docker/compose/releases/download/v2.20.0/docker-compose-$(uname -s)-$(uname -m)" \
  -o /usr/local/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-compose
```

### 2. Register Runner with GitHub

1. Go to: **GitHub → Repository → Settings → Actions → Runners**
2. Click **New self-hosted runner**
3. Copy the setup commands and run them:

```bash
mkdir -p /opt/actions-runner
cd /opt/actions-runner
curl -o actions-runner-linux-x64.tar.gz \
  -L https://github.com/actions/runner/releases/download/v2.311.0/actions-runner-linux-x64-2.311.0.tar.gz
tar xzf actions-runner-linux-x64.tar.gz

# Configure with your GitHub token
./config.sh --url https://github.com/yourname/aspnet --token YOUR_TOKEN
```

### 3. Install as Service

```bash
cd /opt/actions-runner
sudo ./svc.sh install
sudo ./svc.sh start
sudo ./svc.sh status
```

### 4. Verify Connection

Go back to GitHub → Settings → Actions → Runners

You should see your runner with a **green dot** (online).

### 5. Choose Your Workflow

**Option A: Use the original workflow (simpler)**
- Action: No changes needed, use `.github/workflows/ci-cd.yml`
- Best for: Starting out with self-hosted runners

**Option B: Use the optimized workflow (recommended)**
- Action: Rename or switch to `.github/workflows/ci-cd-self-hosted.yml`
- Best for: Production deployments with auto-rollback
- Steps:
  ```bash
  # Option 1: Rename the file
  mv .github/workflows/ci-cd.yml .github/workflows/ci-cd-old.yml
  mv .github/workflows/ci-cd-self-hosted.yml .github/workflows/ci-cd.yml
  git add -A && git commit -m "Use optimized self-hosted workflow"
  git push origin main
  
  # Option 2: Or delete the old one and use the new one explicitly
  ```

## Key Differences from GitHub-Hosted

| Aspect | GitHub-Hosted | Self-Hosted |
|--------|---------------|-------------|
| **Runner** | `ubuntu-latest` | `[self-hosted, linux, x64]` |
| **Cost** | Pay per minute | Free (use your server) |
| **Speed** | Standard VM startup | Instant (pre-installed) |
| **Customization** | Limited | Full control |
| **Capacity** | Parallel runs | Depends on your hardware |
| **Storage** | Temporary | Persistent |

## Performance Tips

1. **Pre-install tools** on your runner to skip setup steps
2. **Use Docker volumes** to cache dependencies between runs
3. **Enable DOCKER_BUILDKIT=1** for faster Docker builds
4. **Schedule cleanup** to remove old images: Use the `cleanup` job

## Troubleshooting

### Runner not appearing in GitHub

```bash
# Check service status
sudo systemctl status actions-runner

# View logs
sudo journalctl -u actions-runner -f

# Restart
sudo systemctl restart actions-runner
```

### Build fails with "No runner available"

1. Check runner is **online** in GitHub
2. Verify labels match between workflow and runner:
   ```yaml
   runs-on: [self-hosted, linux, x64]  # Must have these labels
   ```
3. Check runner logs for errors

### Docker permission issues

```bash
# Add runner user to docker group
sudo usermod -aG docker actions-runner
newgrp docker

# Restart runner
sudo systemctl restart actions-runner
```

## Security Considerations

✅ **Use SSH keys** for authentication (add to GitHub Secrets)  
✅ **Restrict network access** to runner machine  
✅ **Keep runner updated** - GitHub notifies about new versions  
✅ **Run as non-root** user (recommended)  
✅ **Monitor logs** regularly  
✅ **Never commit secrets** - use GitHub Secrets

## Next Steps

1. ✅ Follow the setup steps above
2. ✅ Test with a simple push to `develop` branch
3. ✅ Check GitHub Actions to verify it runs on your runner
4. ✅ Review the [detailed setup guide](SELF_HOSTED_RUNNER_SETUP.md)
5. ✅ Configure SSH keys for staging/production deployment
6. ✅ Add GitHub Secrets (see [DEPLOYMENT.md](DEPLOYMENT.md))

## Workflow Selection

```bash
# Use optimized workflow (recommended for production)
cp .github/workflows/ci-cd-self-hosted.yml .github/workflows/ci-cd.yml

# Or keep both and manually trigger the optimized one
# Then rename when ready
```

## Monitor Your Runner

```bash
# Check runner status
curl https://api.github.com/repos/YOUR_USERNAME/aspnet/actions/runners

# View runner logs
sudo journalctl -u actions-runner --no-pager | tail -50

# Check disk usage
df -h
du -sh /var/lib/docker

# Clean up Docker
docker image prune -a -f
docker volume prune -f
```

## Support

For more details, see:
- [Full Self-Hosted Runner Setup Guide](SELF_HOSTED_RUNNER_SETUP.md)
- [CI/CD Quick Reference](CI_CD_QUICK_REFERENCE.md)
- [Deployment Guide](DEPLOYMENT.md)
- [GitHub Actions Self-Hosted Documentation](https://docs.github.com/en/actions/hosting-your-own-runners)

## Questions?

Review the [SELF_HOSTED_RUNNER_SETUP.md](SELF_HOSTED_RUNNER_SETUP.md) file for comprehensive troubleshooting and advanced configuration options.
