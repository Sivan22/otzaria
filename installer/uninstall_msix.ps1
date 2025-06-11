# Uninstall the MSIX package with the specified package name

$packageName = "sivan22.Otzaria"

# Get the package
$package = Get-AppxPackage -Name $packageName

if ($null -ne $package) {
    Write-Host "Uninstalling package: $packageName"
    Remove-AppxPackage -Package $package.PackageFullName
    Write-Host "Uninstallation complete."
} else {
    Write-Host "Package '$packageName' not found."
}