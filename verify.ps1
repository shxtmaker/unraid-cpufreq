# Verify script: validate the built .plg (CDATA plain-text format)
$ErrorActionPreference = "Stop"

$plgPath = Join-Path (Split-Path -Parent $MyInvocation.MyCommand.Path) "archive\cpufreq.plg"
$plg = Get-Content $plgPath -Raw

$fail = $false

# 1. All placeholders must be replaced.
$leftover = [regex]::Matches($plg, '@[a-z.]+\.content@')
if ($leftover.Count -gt 0) {
    Write-Host "[FAIL] Unreplaced placeholders found: $($leftover.Value -join ', ')"
    $fail = $true
} else {
    Write-Host "[OK] All placeholders replaced"
}

# 2. No CRLF anywhere (UNRAID requires LF).
if ($plg.Contains("`r")) {
    Write-Host "[FAIL] File contains CRLF line endings"
    $fail = $true
} else {
    Write-Host "[OK] Unix (LF) line endings"
}

# 3. FILE blocks use capitalized attributes.
$fileBlocks = [regex]::Matches($plg, '<FILE\s+([^>]+)>')
Write-Host "[OK] Found $($fileBlocks.Count) FILE blocks:"
foreach ($m in $fileBlocks) {
    $attrs = $m.Groups[1].Value
    if ($attrs -cmatch '\bname=' -or $attrs -cmatch '\brun=') {
        Write-Host "     [FAIL] lowercase attribute in: <FILE $attrs>"
        $fail = $true
    } else {
        Write-Host "     <FILE $attrs>"
    }
}

# 4. CDATA balance: every <![CDATA[ must have matching ]]>
$cdataOpen = ([regex]::Matches($plg, '<!\[CDATA\[')).Count
$cdataClose = ([regex]::Matches($plg, '\]\]>')).Count
if ($cdataOpen -ne $cdataClose) {
    Write-Host "[FAIL] CDATA mismatch: $cdataOpen open vs $cdataClose close"
    $fail = $true
} else {
    Write-Host "[OK] CDATA balanced ($cdataOpen blocks)"
}

# 5. Structural sanity.
foreach ($tag in @('<PLUGIN ', '</PLUGIN>', '<CHANGES>', '</CHANGES>')) {
    if (-not $plg.Contains($tag)) {
        Write-Host "[FAIL] Missing: $tag"
        $fail = $true
    }
}
if (-not $fail) { Write-Host "[OK] Structure complete" }

# 6. Dashboard hook and API payload must be embedded.
if ($plg.Contains('Menu="Dashboard"') -and $plg.Contains('AJAX endpoint') -and $plg.Contains('data-cpufreq-average')) {
    Write-Host "[OK] Dashboard hook and API payload embedded"
} else {
    Write-Host "[FAIL] Dashboard hook or API payload missing"
    $fail = $true
}

# 7. The removed standalone UI must not be embedded.
if ($plg.Contains('Menu="Tasks:130"') -or $plg.Contains('Title="CPU Frequency"')) {
    Write-Host "[FAIL] Standalone CPU Frequency page is still embedded"
    $fail = $true
} else {
    Write-Host "[OK] Standalone page is not embedded"
}

# 8. Periodic Dashboard work must use the compact API and stop in the background.
if ($plg.Contains('cpufreq.php?compact=1') -and
    $plg.Contains("visibilitychange") -and
    $plg.Contains("clearInterval") -and
    $plg.Contains("pending.abort()")) {
    Write-Host "[OK] Dashboard polling lifecycle and compact API enabled"
} else {
    Write-Host "[FAIL] Dashboard polling lifecycle or compact API is incomplete"
    $fail = $true
}

# 9. Release metadata must identify the repository owner as author.
if ($plg.Contains('<!ENTITY author    "shxtmaker">')) {
    Write-Host "[OK] Release author is shxtmaker"
} else {
    Write-Host "[FAIL] Release author is not shxtmaker"
    $fail = $true
}

# 10. Upgrade cleanup must remove both legacy standalone tile forms.
if ($plg.Contains('rm -f /usr/local/emhttp/plugins/cpufreq/dashboard.page') -and
    $plg.Contains('rm -rf /usr/local/emhttp/plugins/cpufreq/dashboard')) {
    Write-Host "[OK] Legacy standalone Dashboard tile cleanup enabled"
} else {
    Write-Host "[FAIL] Legacy standalone Dashboard tile cleanup is incomplete"
    $fail = $true
}

# 11. Frequency colors must be refreshed from the native load fields on every update.
if ($plg.Contains('syncFrequencyColor(fields.average, fields.averageLoad)') -and
    $plg.Contains('syncFrequencyColor(fields.cores[id], fields.coreLoads[id])')) {
    Write-Host "[OK] Frequency colors track native load-field colors"
} else {
    Write-Host "[FAIL] Frequency color synchronization is incomplete"
    $fail = $true
}

Write-Host ""
if ($fail) { Write-Host "RESULT: FAILED"; exit 1 } else { Write-Host "RESULT: ALL CHECKS PASSED" }
