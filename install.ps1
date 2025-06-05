@echo off
# This is a PowerShell script for Windows installation. Save as install.ps1 and run with PowerShell.

# Set variables
$APP_DIR = "$env:USERPROFILE\.ssh_router"
$SCRIPT_URL = "https://raw.githubusercontent.com/AlexMolio/ssh_router/main/app.py"

# 1. Create directory
New-Item -ItemType Directory -Force -Path $APP_DIR

# 2. Download script
Invoke-WebRequest -Uri $SCRIPT_URL -OutFile "$APP_DIR\app.py"

# 3. Create virtual environment and install dependencies
python -m venv "$APP_DIR\venv"
& "$APP_DIR\venv\Scripts\activate.ps1"
pip install --upgrade pip
pip install textual

# 4. Create shortcut
$BIN_PATH = "$env:USERPROFILE\.local\bin\s.bat"  # Create a batch file for launching
New-Item -ItemType Directory -Force -Path "$env:USERPROFILE\.local\bin"
Set-Content -Path $BIN_PATH -Value "@echo off`ncall $APP_DIR\venv\Scripts\activate.bat`npython $APP_DIR\app.py"

# Add to PATH if not already (user must run this in their profile or session)
$PATH_UPDATED = [Environment]::GetEnvironmentVariable("PATH", "User") + ";" + "$env:USERPROFILE\.local\bin"
[Environment]::SetEnvironmentVariable("PATH", $PATH_UPDATED, "User")

Write-Output "Shortcut installed as 's'. You can run: s"
Write-Output "Note: You may need to restart your terminal for PATH changes to take effect."

Write-Output "Installation complete!" 