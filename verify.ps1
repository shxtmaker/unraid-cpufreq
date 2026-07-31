# Verify script: validate the built .plg (CDATA plain-text format)
$ErrorActionPreference = "Stop"

$plgPath = Join-Path (Split-Path -Parent $MyInvocation.MyCommand.Path) "archive\cpufreq.plg"
$plg = Get-Content $plgPath -Raw

$fail = $false

# 1. All placeholders must be replaced
$leftover = [regex]::Matches($plg, '@[a-z.]+\.content@')
if ($leftover.Count -gt 0) {
    Write-Host "[FAIL] Unreplaced placeholders found: $($leftover.Value -join ', ')"
    $fail = $true
} else {
    Write-Host "[OK] All placeholders replaced"
}

# 2. No CRLF anywhere (UNRAID requires LF)
if ($plg.Contains("`r")) {
    Write-Host "[FAIL] File contains CRLF line endings"
    $fail = $true
} else {
    Write-Host "[OK] Unix (LF) line endings"
}

# 3. FILE blocks use capitalized Name attribute
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

# 5. Structural sanity
foreach ($tag in @('<PLUGIN ', '</PLUGIN>', '<CHANGES>', '</CHANGES>')) {
    if (-not $plg.Contains($tag)) {
        Write-Host "[FAIL] Missing: $tag"
        $fail = $true
    }
}
if (-not $fail) { Write-Host "[OK] Structure complete" }

# 6. Payload spot-check: page header must be present inside the plg
if ($plg.Contains('Menu="Tasks:130"') -and $plg.Contains('<?PHP')) {
    Write-Host "[OK] Payload content embedded (page header + PHP found)"
} else {
    Write-Host "[FAIL] Payload content missing"
    $fail = $true
}

Write-Host ""
if ($fail) { Write-Host "RESULT: FAILED"; exit 1 } else { Write-Host "RESULT: ALL CHECKS PASSED" }
