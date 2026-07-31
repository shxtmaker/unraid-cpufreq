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

if (-not (Test-Path $OutputDir)) {
    New-Item -ItemType Directory -Path $OutputDir | Out-Null
}

Write-Host "Building cpufreq plugin..."

# Read template
$PlgContent = Get-Content -Path $Template -Raw

# Read a payload file, normalize CRLF -> LF, and validate it is CDATA-safe
function Read-PayloadFile {
    param([string]$FilePath)
    $content = [System.IO.File]::ReadAllText($FilePath)
    $content = $content.Replace("`r`n", "`n")
    if ($content.Contains("]]>")) {
        throw "File $FilePath contains ']]>' which breaks CDATA embedding!"
    }
    return $content.TrimEnd("`n")
}

# Embed each payload file into its placeholder
Write-Host "  Embedding CPUFreq.page..."
$page = Read-PayloadFile (Join-Path $PluginDir "CPUFreq.page")
$PlgContent = $PlgContent.Replace("@cpufreq.page.content@", $page)

Write-Host "  Embedding cpufreq.php..."
$php = Read-PayloadFile (Join-Path $PluginDir "cpufreq.php")
$PlgContent = $PlgContent.Replace("@cpufreq.php.content@", $php)

Write-Host "  Embedding cpufreqdash.page..."
$dash = Read-PayloadFile (Join-Path $PluginDir "cpufreqdash.page")
$PlgContent = $PlgContent.Replace("@cpufreqdash.page.content@", $dash)

# Write output with Unix line endings (LF) and no BOM - required for UNRAID/Linux
$utf8NoBom = New-Object System.Text.UTF8Encoding($false)
$PlgContentLF = $PlgContent.Replace("`r`n", "`n")
[System.IO.File]::WriteAllText($Output, $PlgContentLF, $utf8NoBom)

Write-Host ""
Write-Host "Build complete: $Output"
Write-Host "Install: copy to /boot/config/plugins/ on your UNRAID server, then run:"
Write-Host "  plugin install /boot/config/plugins/cpufreq.plg"
