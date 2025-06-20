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
