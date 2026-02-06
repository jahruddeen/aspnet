# Windows Self-Hosted Runner - Quick Start

Your CI/CD pipeline is now configured for **Windows self-hosted runners**. All jobs will run on your Windows Server or Windows Pro/Enterprise machine.

## 🚀 Quick Setup (5 Minutes)

### Step 1: Install Prerequisites

**Run in PowerShell as Administrator:**

```powershell
# Install Chocolatey (if not already installed)
Set-ExecutionPolicy Bypass -Scope Process -Force; [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072; iex ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))

# Install required software
choco install git dotnet-sdk docker-desktop powershell-core -y

# Restart PowerShell after installation
```

Verify installations:
```powershell
git --version
dotnet --version
docker --version
pwsh --version
```

### Step 2: Create Runner Directory

```powershell
# Create directory for runner
New-Item -ItemType Directory -Path "C:\actions-runner" -Force
cd "C:\actions-runner"
```

### Step 3: Download Runner

```powershell
# Download latest Windows runner (currently v2.311.0)
$url = "https://github.com/actions/runner/releases/download/v2.311.0/actions-runner-win-x64-2.311.0.zip"
Invoke-WebRequest -Uri $url -OutFile "actions-runner.zip"

# Extract
Expand-Archive -Path "actions-runner.zip" -DestinationPath "."
Remove-Item "actions-runner.zip"
```

### Step 4: Register with GitHub

1. Go to: **GitHub Repository → Settings → Actions → Runners**
2. Click **New self-hosted runner**
3. Select **Windows** and **x64**
4. Copy the configuration token

In PowerShell (from `C:\actions-runner`):

```powershell
# Configure runner (replace TOKEN and URL)
.\config.cmd --url https://github.com/YOUR_USERNAME/aspnet --token YOUR_GITHUB_TOKEN_HERE
```

When prompted:
- **Runner name**: `windows-01`
- **Labels**: `windows,x64,docker,dotnet` (optional)
- **Work folder**: Press Enter
- **Additional labels**: Leave blank

### Step 5: Install as Service

```powershell
# Run as Administrator
cd "C:\actions-runner"
.\svc.cmd install

# Start the service
.\svc.cmd start

# Verify it's running
.\svc.cmd status
```

### Step 6: Verify in GitHub

Go back to GitHub → Settings → Actions → Runners

You should see your runner with a **green dot** ✅

## ✅ Workflow Files

### Current Workflow
- **[.github/workflows/ci-cd.yml](.github/workflows/ci-cd.yml)** - Updated for Windows runners

### Windows-Optimized Workflow (Recommended)
- **[.github/workflows/ci-cd-windows.yml](.github/workflows/ci-cd-windows.yml)** - Fully optimized for Windows with PowerShell

### Use Windows-Optimized Version:

```powershell
cd "C:\path\to\your\aspnet\repo"

# Backup current workflow
Copy-Item ".\.github\workflows\ci-cd.yml" ".\.github\workflows\ci-cd-old.yml"

# Use Windows-optimized version
Copy-Item ".\.github\workflows\ci-cd-windows.yml" ".\.github\workflows\ci-cd.yml"

# Commit
git add -A
git commit -m "Use Windows self-hosted runner workflow"
git push origin main
```

## 🔧 Common Tasks

### Check Runner Status

```powershell
# Via Windows Service
Get-Service actions-runner | Select-Object Status, Name

# Via runner directory
cd "C:\actions-runner"
.\svc.cmd status
```

### View Logs

```powershell
# View recent logs
Get-EventLog -LogName System | Where-Object {$_.Source -eq "actions-runner"} | Select-Object -Last 20

# View detailed logs
Get-ChildItem "C:\actions-runner\_diag" -Recurse | Get-Content
```

### Stop/Start Runner

```powershell
# Stop service
Stop-Service actions-runner

# Start service
Start-Service actions-runner

# Or via CLI
cd "C:\actions-runner"
.\svc.cmd stop
.\svc.cmd start
```

### Docker Commands

```powershell
# Check Docker status
docker ps

# View images
docker images

# Clean up unused resources
docker system prune -a -f

# View container logs
docker logs <container_id>
```

## 📊 Windows vs GitHub-Hosted

| Feature | GitHub-Hosted | Windows Self-Hosted |
|---------|--------------|-------------------|
| **Speed** | Medium (VM startup) | Fast (instant, pre-installed) |
| **Cost** | Per minute | Free |
| **OS** | Ubuntu | Windows Server/Pro |
| **Docker** | Pre-installed | You install |
| **Customization** | Limited | Full control |
| **Capacity** | Unlimited in GitHub | Depends on machine |
| **.NET** | Pre-installed | You install |

## 🆘 Troubleshooting

### Runner Not Appearing

```powershell
# Check service is running
Get-Service actions-runner

# If not, start it
Start-Service actions-runner

# Check configuration
Get-Content "C:\actions-runner\.runner"
```

### Docker Not Found

```powershell
# Verify Docker is installed
docker --version

# Start Docker Desktop (GUI) if not running
# Settings → General → Start Docker Desktop when you log in

# Or restart the service
Restart-Service Docker
```

### Permission Denied Errors

```powershell
# Add user to docker-users group
net localgroup docker-users "$(whoami)" /add

# Restart Docker
Restart-Service Docker

# Restart runner service
Restart-Service actions-runner
```

### Workflow Fails to Start

```powershell
# Check runner labels in workflow
# runs-on: [self-hosted, windows, x64]

# Verify runner has those labels
# GitHub → Settings → Actions → Runners → Your Runner

# If missing, re-register:
cd "C:\actions-runner"
.\config.cmd remove --token <TOKEN>
.\config.cmd --url https://github.com/YOUR_USERNAME/aspnet --token <NEW_TOKEN>
```

### No Disk Space

```powershell
# Check disk usage
Get-PSDrive C

# Clean Docker
docker system prune -a -f

# Clean runner work directory
Remove-Item "C:\actions-runner\_work\*" -Recurse -Force

# Clean Windows temp
Remove-Item "$env:TEMP\*" -Recurse -Force -ErrorAction SilentlyContinue
```

## 📚 Next Steps

1. ✅ Complete setup above
2. ✅ Test with a push to `develop` branch
3. ✅ Monitor GitHub Actions to verify it runs on your runner
4. ✅ Switch to Windows-optimized workflow if using PowerShell heavily
5. ✅ Read [WINDOWS_RUNNER_SETUP.md](WINDOWS_RUNNER_SETUP.md) for advanced configuration
6. ✅ Add deployment secrets (see [DEPLOYMENT.md](DEPLOYMENT.md))

## 📖 Full Documentation

For comprehensive setup and advanced configuration:
- [WINDOWS_RUNNER_SETUP.md](WINDOWS_RUNNER_SETUP.md) - Complete Windows setup guide
- [DEPLOYMENT.md](DEPLOYMENT.md) - Deployment configuration
- [CI_CD_QUICK_REFERENCE.md](CI_CD_QUICK_REFERENCE.md) - Command reference

## System Resources

Recommended for your Windows runner:

- **CPU**: 4+ cores
- **Memory**: 8GB+ RAM
- **Disk**: 30GB+ SSD (not HDD)
- **OS**: Windows Server 2019+ or Windows 10/11 Pro/Enterprise

Allocate to Docker Desktop:
- **CPUs**: 4
- **Memory**: 8GB
- **Disk**: 20GB

## ⚡ Performance Tips

1. **Use SSD** for best build performance
2. **Allocate sufficient Docker resources** in Docker Desktop settings
3. **Keep Docker images cached** to speed up builds
4. **Monitor disk space** - builds generate temporary files
5. **Restart services** after Windows updates

## 🔐 Security

✅ Always use **GitHub Secrets** for sensitive data
✅ Never commit SSH keys or passwords
✅ Keep Windows and Docker patched
✅ Use strong SSH key passphrases
✅ Restrict network access if possible

## Quick Commands

```powershell
# Essential commands
Get-Service actions-runner              # Check status
Start-Service actions-runner            # Start
Stop-Service actions-runner             # Stop
Restart-Service actions-runner          # Restart

cd "C:\actions-runner"
.\config.cmd --url <url> --token <token>  # Register
.\svc.cmd install                       # Install service
.\svc.cmd start                         # Start service
.\svc.cmd status                        # Check status

# Docker
docker ps                               # List containers
docker ps -a                            # All containers
docker system prune -a -f               # Clean everything
```

## Support

- **GitHub Actions Docs**: https://docs.github.com/en/actions
- **Self-Hosted Runners**: https://docs.github.com/en/actions/hosting-your-own-runners
- **Windows Setup Guide**: [WINDOWS_RUNNER_SETUP.md](WINDOWS_RUNNER_SETUP.md)

## Checklist

- [ ] Prerequisites installed (.NET, Docker, Git, SSH)
- [ ] Runner directory created (`C:\actions-runner`)
- [ ] Runner downloaded and registered
- [ ] Service installed and running
- [ ] Runner shows online in GitHub (green dot)
- [ ] Test workflow executes on your runner
- [ ] Docker is working properly
- [ ] SSH keys configured for deployments
- [ ] GitHub Secrets added
- [ ] Disk space monitored

You're all set! Your Windows self-hosted runner is ready for deployment. 🎉
