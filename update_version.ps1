# PowerShell script to update version across all files
param(
    [string]$VersionFile = "version.json"
)

# Read version from JSON file
if (-not (Test-Path $VersionFile)) {
    Write-Error "Version file '$VersionFile' not found!"
    exit 1
}

$versionData = Get-Content $VersionFile | ConvertFrom-Json
$newVersion = $versionData.version

# Create different version formats for different files
$msixVersion = "$newVersion.0"  # MSIX needs 4 parts

Write-Host "Updating version to: $newVersion"
Write-Host "MSIX version will be: $msixVersion"

# Update .gitignore (lines 63-64)
$gitignoreContent = Get-Content ".gitignore"
for ($i = 0; $i -lt $gitignoreContent.Length; $i++) {
    if ($gitignoreContent[$i] -match "installer/otzaria-.*-windows\.exe") {
        $gitignoreContent[$i] = "installer/otzaria-$newVersion-windows.exe"
    }
    if ($gitignoreContent[$i] -match "installer/otzaria-.*-windows-full\.exe") {
        $gitignoreContent[$i] = "installer/otzaria-$newVersion-windows-full.exe"
    }
}
$gitignoreContent | Set-Content ".gitignore"
Write-Host "Updated .gitignore"

# Update pubspec.yaml (lines 13 and 39)
$pubspecContent = Get-Content "pubspec.yaml"
for ($i = 0; $i -lt $pubspecContent.Length; $i++) {
    if ($pubspecContent[$i] -match "^\s*msix_version:\s*") {
        $pubspecContent[$i] = "  msix_version: $msixVersion"
    }
    if ($pubspecContent[$i] -match "^\s*version:\s*") {
        $pubspecContent[$i] = "version: $newVersion"
    }
}
$pubspecContent | Set-Content "pubspec.yaml"
Write-Host "Updated pubspec.yaml"

# Update installer/otzaria_full.iss (line 5)
$fullIssContent = Get-Content "installer/otzaria_full.iss"
for ($i = 0; $i -lt $fullIssContent.Length; $i++) {
    if ($fullIssContent[$i] -match '^#define MyAppVersion\s+') {
        $fullIssContent[$i] = "#define MyAppVersion `"$newVersion`""
    }
}
$fullIssContent | Set-Content "installer/otzaria_full.iss"
Write-Host "Updated installer/otzaria_full.iss"

# Update installer/otzaria.iss (line 5)
$issContent = Get-Content "installer/otzaria.iss"
for ($i = 0; $i -lt $issContent.Length; $i++) {
    if ($issContent[$i] -match '^#define MyAppVersion\s+') {
        $issContent[$i] = "#define MyAppVersion `"$newVersion`""
    }
}
$issContent | Set-Content "installer/otzaria.iss"
Write-Host "Updated installer/otzaria.iss"

Write-Host "Version update completed successfully!"
Write-Host "All files have been updated to version: $newVersion"