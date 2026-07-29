# ============================================
# Post-Provision Software Installation Script
# ============================================

# Winget application list
$wingetFile = "C:\Users\clcutshaw\OneDrive - Granite School District\Documents\Scripts\Powershell Post-Provision installs\WingetApps.txt"

# PowerShell module list
$moduleFile = "C:\Users\clcutshaw\OneDrive - Granite School District\Documents\Scripts\Powershell Post-Provision installs\PwshApps.txt"

# ============================================
# Verify Winget Availability
# ============================================

Write-Host ""
Write-Host "========================================" -ForegroundColor Green -BackgroundColor Black
Write-Host "Checking Winget Availability" -ForegroundColor Green -BackgroundColor Black
Write-Host "========================================" -ForegroundColor Green -BackgroundColor Black

if (-not (Get-Command winget -ErrorAction SilentlyContinue)) {

    Write-Host "Winget was not found in the current user context." -ForegroundColor Red -BackgroundColor Black
    Write-Host "Verify App Installer is installed and Winget is available." -ForegroundColor Red -BackgroundColor Black

    exit 1
}

Write-Host "Winget found." -ForegroundColor Green -BackgroundColor Black

# ============================================
# Update Winget Sources
# ============================================

Write-Host ""
Write-Host "========================================" -ForegroundColor Green -BackgroundColor Black
Write-Host "Updating Winget Sources" -ForegroundColor Green -BackgroundColor Black
Write-Host "========================================" -ForegroundColor Green -BackgroundColor Black

winget source update

# ============================================
# Winget Applications
# ============================================

Write-Host ""
Write-Host "========================================" -ForegroundColor Green -BackgroundColor Black
Write-Host "Installing / Updating Winget Applications" -ForegroundColor Green -BackgroundColor Black
Write-Host "========================================" -ForegroundColor Green -BackgroundColor Black

$apps = @(Get-Content $wingetFile |
    Where-Object {
        $_.Trim() -ne "" -and
        -not $_.Trim().StartsWith("#")
    })

$totalApps = $apps.Count
$currentApp = 0

foreach ($app in $apps) {

    $currentApp++
    $app = $app.Trim()

    Write-Host ""
    Write-Host "[$currentApp/$totalApps] Processing: $app" -ForegroundColor Green -BackgroundColor Black

    winget install --id $app -e --silent --accept-package-agreements --accept-source-agreements

    winget upgrade --id $app -e --silent --accept-package-agreements --accept-source-agreements
}

# ============================================
# PowerShell Module Prerequisites
# ============================================

Write-Host ""
Write-Host "========================================" -ForegroundColor Green -BackgroundColor Black
Write-Host "Checking PowerShell Repositories" -ForegroundColor Green -BackgroundColor Black
Write-Host "========================================" -ForegroundColor Green -BackgroundColor Black

$psGallery = Get-PSRepository -Name PSGallery -ErrorAction SilentlyContinue

if ($null -eq $psGallery) {

    Write-Host "PSGallery repository not found." -ForegroundColor Yellow -BackgroundColor Black
}
elseif ($psGallery.InstallationPolicy -ne "Trusted") {

    try {

        Write-Host "Trusting PSGallery..." -ForegroundColor Green -BackgroundColor Black

        Set-PSRepository -Name PSGallery -InstallationPolicy Trusted
    }
    catch {

        Write-Host "Unable to modify PSGallery trust settings. Continuing..." -ForegroundColor Yellow -BackgroundColor Black
    }
}
else {

    Write-Host "PSGallery already trusted." -ForegroundColor Yellow -BackgroundColor Black
}

$nugetProvider = Get-PackageProvider -Name NuGet -ErrorAction SilentlyContinue

if ($null -eq $nugetProvider) {

    Write-Host "Installing NuGet provider..." -ForegroundColor Green -BackgroundColor Black

    try {

        Install-PackageProvider -Name NuGet -Force
    }
    catch {

        Write-Host "Unable to install NuGet provider. Continuing..." -ForegroundColor Yellow -BackgroundColor Black
    }
}
else {

    Write-Host "NuGet provider already installed." -ForegroundColor Yellow -BackgroundColor Black
}

# ============================================
# PowerShell Modules
# ============================================

Write-Host ""
Write-Host "========================================" -ForegroundColor Green -BackgroundColor Black
Write-Host "Installing / Updating PowerShell Modules" -ForegroundColor Green -BackgroundColor Black
Write-Host "========================================" -ForegroundColor Green -BackgroundColor Black

$modules = @(Get-Content $moduleFile |
    Where-Object {
        $_.Trim() -ne "" -and
        -not $_.Trim().StartsWith("#")
    })

$totalModules = $modules.Count
$currentModule = 0

foreach ($module in $modules) {

    $currentModule++
    $module = $module.Trim()

    Write-Host ""
    Write-Host "[$currentModule/$totalModules] Processing Module: $module" -ForegroundColor Green -BackgroundColor Black

    if (Get-Module -ListAvailable -Name $module) {

        try {

            Update-Module -Name $module -Force -ErrorAction Stop

            Write-Host "$module updated successfully." -ForegroundColor Green -BackgroundColor Black
        }
        catch {

            Write-Host "$module is already current or cannot be updated." -ForegroundColor Yellow -BackgroundColor Black
        }
    }
    else {

        try {

            Install-Module -Name $module `
                -Scope CurrentUser `
                -Force `
                -AllowClobber

            Write-Host "$module installed successfully." -ForegroundColor Green -BackgroundColor Black
        }
        catch {

            Write-Host "Failed to install $module" -ForegroundColor Red -BackgroundColor Black
        }
    }
}

# ============================================
# Complete
# ============================================

Write-Host ""
Write-Host "========================================" -ForegroundColor Green -BackgroundColor Black
Write-Host "Provisioning Complete" -ForegroundColor Green -BackgroundColor Black
Write-Host "========================================" -ForegroundColor Green -BackgroundColor Black