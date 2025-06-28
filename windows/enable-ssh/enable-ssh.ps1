# SSH setup script (must be run as Administrator)
if (-not ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole(
    [Security.Principal.WindowsBuiltInRole] "Administrator")) {
    Write-Host "[ERROR] Must run as Administrator." -ForegroundColor Red
    exit 1
}

Write-Host "[INFO] Checking OpenSSH installation..."
$sshCapability = Get-WindowsCapability -Online | Where-Object Name -like 'OpenSSH.Server*'
if ($sshCapability.State -ne 'Installed') {
    Write-Host "[INFO] Installing OpenSSH Server..."
    Add-WindowsCapability -Online -Name $sshCapability.Name
} else {
    Write-Host "[OK] OpenSSH Server already installed." -ForegroundColor Green
}

Write-Host "[INFO] Ensuring firewall rule..."
if (-not (Get-NetFirewallRule -Name "OpenSSH-Server-In-TCP" -ErrorAction SilentlyContinue)) {
    New-NetFirewallRule -Name "OpenSSH-Server-In-TCP" -DisplayName "OpenSSH Server (TCP-In)" `
        -Enabled True -Direction Inbound -Protocol TCP -Action Allow -LocalPort 22
} else {
    Write-Host "[OK] Firewall rule already exists." -ForegroundColor Green
}

function Ensure-ServiceRunning($name) {
    $svc = Get-Service -Name $name -ErrorAction SilentlyContinue
    if ($svc) {
        Set-Service -Name $name -StartupType Automatic
        if ($svc.Status -ne 'Running') {
            Start-Service -Name $name
        }
        Write-Host "[OK] Service '$name' running." -ForegroundColor Green
    } else {
        Write-Host "[WARNING] Service '$name' not found." -ForegroundColor Yellow
    }
}

Write-Host "[INFO] Starting required services..."
Ensure-ServiceRunning 'ssh-agent'
Ensure-ServiceRunning 'sshd'

# Make sure sshd_config exists
$sshdConfigPath = "$env:ProgramData\ssh\sshd_config"
if (-not (Test-Path $sshdConfigPath)) {
    Start-Service sshd; Start-Sleep -Seconds 2; Stop-Service sshd
    if (-not (Test-Path $sshdConfigPath)) {
        Write-Host "[ERROR] sshd_config still not found after triggering." -ForegroundColor Red
        exit 1
    }
}

# Load SSH public key from key.pub and trim it
$keyFilePath = Join-Path $PSScriptRoot "key.pub"
if (-not (Test-Path $keyFilePath)) {
    Write-Host "[ERROR] key.pub not found." -ForegroundColor Red
    exit 1
}
$publicKey = (Get-Content $keyFilePath -Raw).Trim()

# Add SSH key to Administrator
$sshDir = "C:\Users\Administrator\.ssh"
$authFile = "$sshDir\authorized_keys"

if (-not (Test-Path $sshDir)) {
    New-Item -ItemType Directory -Path $sshDir -Force | Out-Null
}
if (-not (Test-Path $authFile)) {
    New-Item -ItemType File -Path $authFile -Force | Out-Null
}

if (-not (Select-String -Path $authFile -Pattern ([regex]::Escape($publicKey)) -Quiet)) {
    $publicKey | Out-File -FilePath $authFile -Encoding ascii -Append
    Write-Host "[OK] SSH key added to authorized_keys." -ForegroundColor Green
} else {
    Write-Host "[OK] SSH key already present." -ForegroundColor Green
}

# Set permissions for .ssh and authorized_keys
icacls $authFile /inheritance:r /grant "Administrator:(F)" /grant "SYSTEM:(F)" | Out-Null
icacls $sshDir /inheritance:r /grant "Administrator:(F)" /grant "SYSTEM:(F)" /T | Out-Null

# Update sshd_config
Write-Host "[INFO] Updating sshd_config..."
$backup = "$sshdConfigPath.bak.$(Get-Date -Format yyyyMMdd_HHmmss)"
Copy-Item $sshdConfigPath $backup

$config = Get-Content $sshdConfigPath
$config = $config | Where-Object { $_ -notmatch 'authorized_keys' -and $_ -notmatch 'Administrator' }

if ($config -notmatch 'StrictModes\s+no') {
    $config = $config | Where-Object { $_ -notmatch 'StrictModes' }
    $config += 'StrictModes no'
}

$modified = $false
$config = $config | ForEach-Object {
    if ($_ -match '^\s*#\s*PasswordAuthentication\s+yes') {
        $modified = $true
        'PasswordAuthentication yes'
    } else { $_ }
}
if (-not $modified -and $config -notmatch '^\s*PasswordAuthentication\s+yes') {
    $config += 'PasswordAuthentication yes'
}

$config | Set-Content -Encoding ascii $sshdConfigPath

try {
    Restart-Service sshd -Force
    Write-Host "[OK] sshd restarted." -ForegroundColor Green
} catch {
    Write-Host "[WARNING] sshd restart failed." -ForegroundColor Yellow
}

Write-Host "`n[SUCCESS] SSH setup complete. You can now connect via SSH."
Write-Host "Press Ctrl+C or type 'exit' to close this window."
