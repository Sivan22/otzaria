# Fix encoding for Inno Setup files to properly display Hebrew text
# This script converts the installer files to UTF-8 with BOM

$files = @(
    "installer\otzaria.iss",
    "installer\otzaria_full.iss"
)

foreach ($file in $files) {
    if (Test-Path $file) {
        Write-Host "Processing $file..."
        
        # Read the file content
        $content = Get-Content -Path $file -Raw -Encoding UTF8
        
        # Write it back with UTF-8 BOM
        $utf8BOM = New-Object System.Text.UTF8Encoding $true
        [System.IO.File]::WriteAllText((Resolve-Path $file), $content, $utf8BOM)
        
        Write-Host "Fixed encoding for $file"
    } else {
        Write-Host "File not found: $file"
    }
}

Write-Host "Encoding fix completed. Please rebuild the installer."