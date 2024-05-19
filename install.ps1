$pwsh = "powershell.exe"

if ((New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator) -ne $true) {
    Set-ExecutionPolicy -Scope CurrentUser -ExecutionPolicy Bypass -Force
    $Proc = Start-Process -PassThru -Verb RunAs $pwsh -Args "-ExecutionPolicy Bypass -Command Set-Location '$PSScriptRoot'; &'$PSCommandPath' EVAL"
    if ($null -ne $Proc) {
        $Proc.WaitForExit()
    }
    if ($null -eq $Proc -or $Proc.ExitCode -ne 0) {
        Write-Warning "`r`nFailed to launch start as Administrator`r`nPress any key to exit"
        $null = $Host.UI.RawUI.ReadKey('NoEcho,IncludeKeyDown');
    }
    exit
}
elseif (($args.Count -eq 1) -and ($args[0] -eq "EVAL")) {
    Start-Process $pwsh -NoNewWindow -Args "-ExecutionPolicy Bypass -Command Set-Location '$PSScriptRoot'; &'$PSCommandPath'"
    exit
}
# Define the path to your CRT file
$certPath = "sivan22.crt"

# Check if the file exists
if (Test-Path -Path $certPath) {
    # Import the certificate to the Local Machine's Trusted Root store
    Import-Certificate -FilePath $certPath -CertStoreLocation "Cert:\LocalMachine\Root"

    Write-Host "Certificate successfully installed as a Trusted Root."
}
else {
    # Error message if file not found
    Write-Error "Error: Certificate file not found at '$certPath'"
}

# Define the path to your MSIX package
$msixPath = "otzaria.msix"

# Silent installation with logging disabled
$LASTEXITCODE = Add-AppxPackage -Path $msixPath 

Write-Host "MSIX package installed successfully."


# Define the target directory path using environment variable
$targetPath = "${env:APPDATA}\com.example\otzaria"

# Check if the path exists
if (Test-Path -Path $targetPath) {
    # Remove all items recursively (including subfolders)
    Remove-Item -Path $targetPath -Force -Recurse

    Write-Host "Successfully erased contents of '$targetPath'."
}
else {
    Write-Host "Directory '$targetPath' not found. Skipping deletion."
}

# Define the source and destination paths
$sourceFile = "app_preferences.isar"
$destinationPath = "${env:APPDATA}\com.example\otzaria"

# Create the destination folder if it doesn't exist
if (-not (Test-Path $destinationPath)) {
    New-Item -ItemType Directory -Path $destinationPath
}

# Copy the file
Copy-Item -Path $sourceFile -Destination $destinationPath -Force
Write-Host "File copied successfully!"
