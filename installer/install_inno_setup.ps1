# PowerShell Script to Install Inno Setup Directly

# 1. Define Inno Setup download URL and installer details
# The official site for Inno Setup is jrsoftware.org
$innoSetupUrl = "https://files.jrsoftware.org/is/6/innosetup-6.2.2.exe" # Link to a specific stable version
$installerFile = "$env:TEMP\innosetup_installer.exe"

# 2. Download the Inno Setup installer
Write-Host "Downloading Inno Setup..."
try {
    Invoke-WebRequest -Uri $innoSetupUrl -OutFile $installerFile
    Write-Host "Download complete."
}
catch {
    Write-Error "Failed to download Inno Setup installer. Please check the URL and your network connection."
    exit
}

# 3. Install Inno Setup silently
Write-Host "Installing Inno Setup..."
try {
    # Use Inno Setup's command-line switches for a silent installation
    # /VERYSILENT: Hides the installation wizard and progress window.
    # /SUPPRESSMSGBOXES: Prevents message boxes from appearing.
    # /NORESTART: Prevents any automatic restarts after installation.
    $installArgs = "/VERYSILENT /SUPPRESSMSGBOXES /NORESTART"

    # Start the installer process and wait for it to complete
    Start-Process -FilePath $installerFile -ArgumentList $installArgs -Wait -PassThru
    Write-Host "Inno Setup installed successfully."
}
catch {
    Write-Error "Failed to install Inno Setup."
    exit
}
finally {
    # Clean up the downloaded installer file
    if (Test-Path $installerFile) {
        Remove-Item $installerFile
    }
}

# 4. Add Inno Setup to the System PATH
Write-Host "Adding Inno Setup to the system PATH..."
try {
    # Default installation path for Inno Setup
    $innoSetupPath = "C:\Program Files (x86)\Inno Setup 6"

    if (Test-Path $innoSetupPath) {
        $currentPath = [System.Environment]::GetEnvironmentVariable("Path", "Machine")
        if (-not ($currentPath -like "*$innoSetupPath*")) {
            $newPath = "$currentPath;$innoSetupPath"
            [System.Environment]::SetEnvironmentVariable("Path", $newPath, "Machine")
            # Note: A system-wide PATH change requires a restart of the terminal/session to take effect.
            Write-Host "Inno Setup added to the system PATH. Please restart your terminal for the changes to take effect."
        } else {
            Write-Host "Inno Setup is already in the system PATH."
        }
    } else {
        Write-Warning "Could not find Inno Setup installation directory at '$innoSetupPath'. PATH not updated."
    }
}
catch {
    Write-Error "Failed to add Inno Setup to the PATH."
}

Write-Host "Script execution finished."