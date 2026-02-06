# Self-Hosted GitHub Actions Runner Setup - Windows

This guide walks you through setting up a self-hosted GitHub Actions runner on Windows Server or Windows 11/10 for the CI/CD pipeline.

## Prerequisites

- **Windows Server 2019+** or **Windows 10/11 Pro/Enterprise**
- Administrator access
- At least 4GB RAM and 30GB disk space
- Internet connectivity
- PowerShell 7+ (optional but recommended)

## Step 1: Install Required Software

### 1.1 Install Git

```powershell
# Using Chocolatey
choco install git -y

# OR download from https://git-scm.com/download/win

# Verify installation
git --version
```

### 1.2 Install .NET 8.0 SDK

```powershell
# Using Chocolatey
choco install dotnet-sdk -y

# OR download from https://dotnet.microsoft.com/download

# Verify installation
dotnet --version
```

### 1.3 Install Docker Desktop (Windows)

```powershell
# Using Chocolatey
choco install docker-desktop -y

# OR download from https://www.docker.com/products/docker-desktop

# Note: Requires Windows Pro/Enterprise and virtualization enabled

# Start Docker Desktop and wait for it to initialize
# Then verify:
docker --version
docker ps
```

### 1.4 Install Docker Compose (if not included)

```powershell
# Download the latest release
$url = "https://github.com/docker/compose/releases/download/v2.20.0/docker-compose-Windows-x86_64.exe"
$output = "$env:ProgramFiles\Docker\Docker\resources\bin\docker-compose.exe"

Invoke-WebRequest -Uri $url -OutFile $output
(Get-Item $output).VersionInfo
```

### 1.5 Install SSH (Windows 10/11 1909+)

```powershell
# Check if OpenSSH Client is installed
Get-WindowsCapability -Online | Where-Object {$_.Name -like 'OpenSSH*'}

# Install OpenSSH Client if needed
Add-WindowsCapability -Online -Name OpenSSH.Client~~~~0.0.1.0

# Install OpenSSH Server (optional, if managing this Windows machine remotely)
Add-WindowsCapability -Online -Name OpenSSH.Server~~~~0.0.1.0

# Verify
ssh -V
```

### 1.6 Optional: Install PowerShell 7+

```powershell
# Using Chocolatey
choco install powershell-core -y

# OR download from https://github.com/PowerShell/PowerShell/releases

# Verify
pwsh --version
```

## Step 2: Create Runner Directory

```powershell
# Create runner directory
New-Item -ItemType Directory -Path "C:\actions-runner" -Force | Out-Null
Set-Location "C:\actions-runner"

# Verify
Get-Location
```

## Step 3: Download and Register Runner

### 3.1 Download the Runner

```powershell
# Navigate to runner directory
cd "C:\actions-runner"

# Download the latest Windows runner
# Visit: https://github.com/actions/runner/releases
# Download the latest Windows x64 release (e.g., actions-runner-win-x64-2.311.0.zip)

$url = "https://github.com/actions/runner/releases/download/v2.311.0/actions-runner-win-x64-2.311.0.zip"
Invoke-WebRequest -Uri $url -OutFile "actions-runner.zip"

# Extract
Expand-Archive -Path "actions-runner.zip" -DestinationPath "."

# Remove zip
Remove-Item "actions-runner.zip"

# Verify
Get-ChildItem
```

### 3.2 Configure the Runner

```powershell
# Go to GitHub → Repository → Settings → Actions → Runners
# Click "New self-hosted runner" → Windows → x64
# Copy the configuration command shown

# Run configuration (replace with your token and repository URL)
cd "C:\actions-runner"

.\config.cmd --url https://github.com/YOUR_USERNAME/aspnet --token YOUR_GITHUB_TOKEN
```

When prompted:
- **Enter name of runner**: `windows-runner-01` (or your preferred name)
- **Enter any labels**: `windows,x64,docker,dotnet` (optional)
- **Enter name of work folder**: Press Enter to accept default (`_work`)
- **Enter additional labels**: Leave blank

### 3.3 Verify Configuration

```powershell
# Check if .runner config file exists
Get-Content ".\.runner"
```

## Step 4: Install Runner as Windows Service

### 4.1 Install Service

```powershell
# Run as Administrator!
# Right-click PowerShell → Run as administrator

cd "C:\actions-runner"

# Install as service
.\svc.cmd install

# Start service
.\svc.cmd start

# Check status
.\svc.cmd status
```

### 4.2 Verify in GitHub

1. Go to GitHub → Repository Settings → Actions → Runners
2. You should see your runner with a **green dot** (online status)

## Step 5: Verify Runner Works

### Test with Simple Workflow

Push code to your repository to trigger the CI/CD pipeline:

```powershell
cd "C:\path\to\your\aspnet\repo"

git checkout -b test/runner
git push origin test/runner

# Go to GitHub → Actions and watch the workflow run
```

## Step 6: Manage the Service

### Start/Stop Runner Service

```powershell
# Check service status
Get-Service actions-runner

# Start service
Start-Service actions-runner

# Stop service
Stop-Service actions-runner

# Restart service
Restart-Service actions-runner

# View service logs
Get-EventLog -LogName System | Where-Object {$_.Source -eq "actions-runner"}
```

### Using Command Line

```powershell
cd "C:\actions-runner"

# Start runner
.\svc.cmd start

# Stop runner
.\svc.cmd stop

# Check status
.\svc.cmd status

# Uninstall service
.\svc.cmd uninstall
```

## Step 7: Configure Firewall (if needed)

```powershell
# Allow GitHub to communicate with runner
# Usually not needed if outbound HTTPS is allowed

# Check current firewall rules
Get-NetFirewallProfile

# Allow PowerShell remoting (if needed)
Enable-PSRemoting -Force
```

## Step 8: Important Windows-Specific Settings

### 8.1 Docker Desktop Configuration

```powershell
# Ensure Docker Desktop is set to:
# Settings → General → Start Docker Desktop when you log in (checked)
# Settings → Resources → Assign sufficient CPU and Memory
```

### 8.2 User Login (Required for Docker)

```powershell
# If running as a user service, ensure the user:
# 1. Has password set
# 2. Has Docker Desktop installed for that user
# 3. Has accepeted Docker license

# For service account approach:
# Services cannot run Docker Desktop GUI version
# Use Docker Engine on WSL2 or Docker Server instead
```

### 8.3 Long Path Support (if needed)

```powershell
# Enable long path support for Windows
New-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\FileSystem" `
  -Name "LongPathsEnabled" -Value 1 -PropertyType DWORD -Force

# Restart may be required
```

## Step 9: Testing Your Setup

### Test .NET Build

```powershell
cd "C:\path\to\your\aspnet\repo"

# Trigger workflow
git push origin main

# Check GitHub Actions for workflow execution
```

### Test Docker

```powershell
# Verify Docker works
docker ps
docker run hello-world
```

### Test Git

```powershell
# Verify Git works
git --version
git status
```

## Step 10: Troubleshooting Windows Runner

### Runner Not Showing in GitHub

```powershell
# Check if service is running
Get-Service actions-runner

# Check service logs
Get-EventLog -LogName System | Where-Object {$_.Source -eq "actions-runner"} | Select-Object -Last 20

# Check runner registration
cat "C:\actions-runner\.runner"

# Re-register if needed
cd "C:\actions-runner"
.\config.cmd remove --token YOUR_TOKEN_HERE
.\config.cmd --url https://github.com/YOUR_USERNAME/aspnet --token YOUR_NEW_TOKEN
```

### Docker Permission Issues

```powershell
# Ensure user running service has Docker access
# Restart Docker Desktop
Restart-Service Docker

# Or via GUI:
# Right-click Docker → Restart

# Add user to docker-users group (if using Windows Pro/Enterprise)
net localgroup docker-users "your-username" /add
```

### Build Fails with Path Issues

```powershell
# Windows uses backslashes, but Docker expects forward slashes
# PowerShell or cmd may have different path handling

# Solution: Use proper escaping in workflow
# Use shell: powershell to handle paths correctly
```

### Out of Disk Space

```powershell
# Check disk usage
Get-PSDrive C

# Clean Docker
docker system prune -a --volumes

# Clean runner work directory
Remove-Item "C:\actions-runner\_work\*" -Recurse -Force

# Clean Windows temp
Remove-Item "$env:TEMP\*" -Recurse -Force -ErrorAction SilentlyContinue
```

### Runner Crashes or Stops

```powershell
# Check Windows Event Viewer
eventvwr.msc

# View runner logs
tail -f "C:\actions-runner\_diag\*.log" # If using WSL2

# Restart runner service
Restart-Service actions-runner

# Check system resources
Get-ComputerInfo | Select-Object CsPhysicalMemory, OsArchitecture

# Monitor processes
Get-Process | Sort-Object WorkingSet -Descending | Select-Object -First 10
```

## Step 11: Workflow Selection

Choose the appropriate workflow for your setup:

### For Windows Runners:

**Use this file**: `.github/workflows/ci-cd-windows.yml`

This workflow is optimized for Windows with:
- PowerShell shell for scripts
- Windows-compatible Docker commands
- Proper path handling for Windows

### Migration Steps:

```powershell
# Option 1: Replace the main workflow
cd "C:\path\to\your\aspnet\repo"

# Rename current workflow
Rename-Item ".\.github\workflows\ci-cd.yml" ".\.github\workflows\ci-cd-old.yml"

# Copy Windows workflow to main
Copy-Item ".\.github\workflows\ci-cd-windows.yml" ".\.github\workflows\ci-cd.yml"

# Commit and push
git add -A
git commit -m "Use Windows self-hosted runner workflow"
git push origin main
```

```
# Option 2: Keep both and choose manually
# Keep `.github/workflows/ci-cd.yml` for Linux runners
# Use `.github/workflows/ci-cd-windows.yml` for Windows runners
# Rename the Windows file and adjust as needed
```

## Step 12: Performance Optimization

### Reduce Build Time

```powershell
# 1. Use SSD for runner directory
#    Ensure C:\ is SSD, not HDD

# 2. Allocate sufficient Docker resources
#    Docker Desktop → Settings → Resources
#    CPUs: 4+, Memory: 8GB+

# 3. Cache NuGet packages
#    Reuse node_modules or NuGet cache between builds

# 4. Use docker layer caching
#    Update Dockerfile to leverage caching
```

### Monitor Resources

```powershell
# Check CPU usage
Get-Counter "\Processor(_Total)\% Processor Time" -Continuous

# Check Memory usage
Get-Counter "\Memory\Available MBytes" -Continuous

# Check Disk I/O
Get-Counter "PhysicalDisk(_Total)\Disk Read Bytes/sec" -Continuous
```

## Step 13: Security Best Practices

### 1. Firewall Configuration

```powershell
# Allow GitHub to reach this machine
# Outbound HTTPS (443) should be allowed

# Test connectivity
Invoke-WebRequest https://api.github.com
```

### 2. Keep Software Updated

```powershell
# Update Windows
```powershell
Get-WindowsUpdate
Install-WindowsUpdate -AcceptAll
```

# Update Docker
# Docker Desktop → Check for Updates

# Update .NET
# Download new version from dotnet.microsoft.com
```

### 3. Manage Secrets Securely

```powershell
# Never hardcode secrets in workflows
# Always use GitHub Secrets

# Add secrets via GitHub UI:
# Settings → Secrets and variables → Actions → New repository secret
```

### 4. Restrict Network Access

```powershell
# Limit inbound traffic to runner machine
netsh advfirewall firewall add rule name="Allow GitHub" direction=in action=allow protocol=TCP remoteport=22

# Allow only necessary ports
```

## Useful Commands Reference

```powershell
# Service Management
Get-Service actions-runner
Start-Service actions-runner
Stop-Service actions-runner
Restart-Service actions-runner

# Runner Configuration
cd "C:\actions-runner"
Get-Content ".\.runner"
.\config.cmd --url <url> --token <token>
.\svc.cmd install
.\svc.cmd start
.\svc.cmd status
.\svc.cmd uninstall

# Docker Commands
docker ps
docker images
docker system prune -a
docker logs <container_id>

# System Information
Get-ComputerInfo
Get-PSDrive
Get-Process | Sort-Object WorkingSet -Descending | Select-Object -First 10

# View Logs
Get-EventLog -LogName System | Where-Object {$_.Source -eq "actions-runner"} | Select-Object -Last 50
```

## Support & Resources

- [GitHub Actions Self-Hosted Runners](https://docs.github.com/en/actions/hosting-your-own-runners)
- [Windows Server Setup](https://docs.github.com/en/actions/hosting-your-own-runners/managing-self-hosted-runners/creating-a-self-hosted-runner)
- [Docker Desktop for Windows](https://docs.docker.com/desktop/install/windows-install/)
- [GitHub Actions Runner Releases](https://github.com/actions/runner/releases)

## Checklist

- [ ] .NET 8.0 SDK installed
- [ ] Docker Desktop installed and running
- [ ] Git installed
- [ ] OpenSSH Client installed
- [ ] Runner directory created (`C:\actions-runner`)
- [ ] Runner downloaded and extracted
- [ ] Runner configured with GitHub token
- [ ] Service installed and starting on boot
- [ ] Runner appears online in GitHub
- [ ] Test workflow runs successfully
- [ ] Firewall rules configured
- [ ] Secrets added to GitHub repository
- [ ] Docker layer caching verified
