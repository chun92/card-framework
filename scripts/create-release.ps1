# Release creation script for Card Framework (PowerShell)
# Usage: .\scripts\create-release.ps1 <version>
# Example: .\scripts\create-release.ps1 1.3.1

param(
    [Parameter(Mandatory=$true)]
    [string]$Version
)

$ErrorActionPreference = "Stop"

# Validate version format
if ($Version -notmatch '^\d+\.\d+\.\d+$') {
    Write-Host "Error: Version must be in format X.Y.Z (e.g., 1.3.1)" -ForegroundColor Red
    exit 1
}

Write-Host "==========================================" -ForegroundColor Cyan
Write-Host "Creating release for version v$Version" -ForegroundColor Cyan
Write-Host "==========================================" -ForegroundColor Cyan

# Check if we're in the project root
if (!(Test-Path "project.godot")) {
    Write-Host "Error: Must run from project root directory" -ForegroundColor Red
    exit 1
}

# Check for uncommitted changes
$gitStatus = git status --porcelain
if ($gitStatus) {
    Write-Host "Warning: Uncommitted changes detected" -ForegroundColor Yellow
    $continue = Read-Host "Continue anyway? (y/n)"
    if ($continue -ne 'y') {
        exit 1
    }
}

# Create releases directory
if (!(Test-Path "releases")) {
    New-Item -ItemType Directory -Path "releases" | Out-Null
}

$outputFile = "releases\card-framework-v$Version-full.zip"

Write-Host ""
Write-Host "Step 1: Creating full project archive..." -ForegroundColor Yellow

# Remove old file if exists
if (Test-Path $outputFile) {
    Remove-Item $outputFile
}

# Create zip archive
$exclude = @(
    '.git',
    '.godot',
    '*.import',
    '.taskmaster',
    '.vscode',
    '.env',
    'releases',
    '.claude'
)

# Get all files except excluded patterns
$files = Get-ChildItem -Recurse -File | Where-Object {
    $file = $_
    $shouldExclude = $false
    foreach ($pattern in $exclude) {
        if ($file.FullName -like "*$pattern*") {
            $shouldExclude = $true
            break
        }
    }
    -not $shouldExclude
}

# Create zip
Add-Type -Assembly System.IO.Compression.FileSystem
$compressionLevel = [System.IO.Compression.CompressionLevel]::Optimal
$zip = [System.IO.Compression.ZipFile]::Open($outputFile, 'Create')

foreach ($file in $files) {
    $relativePath = $file.FullName.Substring($PWD.Path.Length + 1)
    [System.IO.Compression.ZipFileExtensions]::CreateEntryFromFile($zip, $file.FullName, $relativePath, $compressionLevel) | Out-Null
}

$zip.Dispose()

Write-Host "✓ Created: $outputFile" -ForegroundColor Green

# Get file size
$size = (Get-Item $outputFile).Length / 1MB
Write-Host "  File size: $([math]::Round($size, 2)) MB" -ForegroundColor Gray

Write-Host ""
Write-Host "Step 2: Verifying archive contents..." -ForegroundColor Yellow

# Verify archive contents
Add-Type -Assembly System.IO.Compression.FileSystem
$zipArchive = [System.IO.Compression.ZipFile]::OpenRead($outputFile)
$entries = $zipArchive.Entries.FullName

$requiredPaths = @(
    "addons/card-framework/",
    "example1/",
    "freecell/",
    "docs/"
)

foreach ($path in $requiredPaths) {
    if ($entries -like "*$path*") {
        Write-Host "  ✓ $path found" -ForegroundColor Green
    } else {
        Write-Host "  ✗ $path missing!" -ForegroundColor Red
        $zipArchive.Dispose()
        exit 1
    }
}

$zipArchive.Dispose()

Write-Host ""
Write-Host "==========================================" -ForegroundColor Cyan
Write-Host "Release archive created successfully!" -ForegroundColor Green
Write-Host "==========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Next steps:" -ForegroundColor Yellow
Write-Host "1. Test the archive:" -ForegroundColor White
Write-Host "   Expand-Archive $outputFile -DestinationPath test-extract" -ForegroundColor Gray
Write-Host "   cd test-extract; godot project.godot" -ForegroundColor Gray
Write-Host ""
Write-Host "2. Create git tag:" -ForegroundColor White
Write-Host "   git tag -a v$Version -m `"Release v$Version`"" -ForegroundColor Gray
Write-Host "   git push origin v$Version" -ForegroundColor Gray
Write-Host ""
Write-Host "3. Create GitHub Release:" -ForegroundColor White
Write-Host "   - Go to: https://github.com/chun92/card-framework/releases/new" -ForegroundColor Gray
Write-Host "   - Tag: v$Version" -ForegroundColor Gray
Write-Host "   - Title: Card Framework v$Version" -ForegroundColor Gray
Write-Host "   - Upload: $outputFile" -ForegroundColor Gray
Write-Host ""
Write-Host "4. Add release notes describing:" -ForegroundColor White
Write-Host "   - New features" -ForegroundColor Gray
Write-Host "   - Bug fixes" -ForegroundColor Gray
Write-Host "   - Breaking changes" -ForegroundColor Gray
Write-Host ""
Write-Host "Archive location: $outputFile" -ForegroundColor Cyan
Write-Host "==========================================" -ForegroundColor Cyan
