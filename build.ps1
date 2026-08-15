# Build script for cpufreq UNRAID plugin (Windows PowerShell version)
# Embeds payload files as plain text (CDATA) into the final .plg file
# Usage: .\build.ps1

$ErrorActionPreference = "Stop"

$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$SourceDir = Join-Path $ScriptDir "source"
$PluginDir = Join-Path $SourceDir "plugins\cpufreq"
$OutputDir = Join-Path $ScriptDir "archive"
$Template = Join-Path $SourceDir "cpufreq.plg"
$Output = Join-Path $OutputDir "cpufreq.plg"
$OutputTemp = Join-Path $OutputDir (".cpufreq.plg." + [guid]::NewGuid().ToString("N"))

if (-not (Test-Path $OutputDir)) {
    New-Item -ItemType Directory -Path $OutputDir | Out-Null
}

Write-Host "Building cpufreq plugin..."

$PlgContent = Get-Content -Path $Template -Raw

function Read-PayloadFile {
    param([string]$FilePath)
    $content = [System.IO.File]::ReadAllText($FilePath)
    $content = $content.Replace("`r`n", "`n")
    if ($content.Contains("]]>")) {
        throw "File $FilePath contains ']]>' which breaks CDATA embedding!"
    }
    return $content.TrimEnd("`n")
}

Write-Host "  Embedding cpufreq.php..."
$php = Read-PayloadFile (Join-Path $PluginDir "cpufreq.php")
$PlgContent = $PlgContent.Replace("@cpufreq.php.content@", $php)

Write-Host "  Embedding cpufreqdash.page..."
$dash = Read-PayloadFile (Join-Path $PluginDir "cpufreqdash.page")
$PlgContent = $PlgContent.Replace("@cpufreqdash.page.content@", $dash)

$utf8NoBom = New-Object System.Text.UTF8Encoding($false)
$PlgContentLF = $PlgContent.Replace("`r`n", "`n")
if ($PlgContentLF -match '@[a-z.]+\.content@') {
    throw "Unreplaced payload placeholder found"
}

try {
    [System.IO.File]::WriteAllText($OutputTemp, $PlgContentLF, $utf8NoBom)
    Move-Item -Path $OutputTemp -Destination $Output -Force
} finally {
    if (Test-Path $OutputTemp) { Remove-Item $OutputTemp -Force }
}

Write-Host ""
Write-Host "Build complete: $Output"
Write-Host "Install: copy to /boot/config/plugins/ on your UNRAID server, then run:"
Write-Host "  plugin install /boot/config/plugins/cpufreq.plg"
