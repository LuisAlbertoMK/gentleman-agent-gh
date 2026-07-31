#requires -Version 5.1
<#
.SYNOPSIS
  Validate mem_save content before persisting to Engram — schema, injection, field completeness.
.DESCRIPTION
  Post-save gate that validates mem_save content structure. Checks for:
  - Required **What** field
  - Injection patterns (poisoning guard)
  - Field completeness per type
  - Domain-specific field extensions
  Works as pipeline filter or standalone.
.PARAMETER Content
  The content string to validate.
.PARAMETER Title
  The mem_save title (used for error messages).
.PARAMETER Type
  Observation type: bugfix|decision|pattern|learning|discovery|config.
.PARAMETER TopicKey
  Topic key for the save (checked for injection patterns).
.PARAMETER Strict
  Require all 4 canonical fields: What, Why, Where, Learned.
.PARAMETER DomainFields
  Additional valid field names beyond the canonical set (e.g. @("Exit code","Output") for command-wrapper).
.PARAMETER PassThru
  Return the input object if valid, $null if invalid.
.PARAMETER Quiet
  Exit code only: 0=valid, 1=warnings, 2=errors.
.PARAMETER Fix
  Auto-fix: prefix bare content with "**What**: Auto-detected" if missing.
.PARAMETER InputObject
  Supports pipeline: @{Title="..."; Content="..."; Type="..."; TopicKey="..."}
.EXAMPLE
  .\scripts\engram-validate.ps1 -Content "**What**: Fixed N+1 query" -Type bugfix
.EXAMPLE
  "**What**: test" | .\scripts\engram-validate.ps1 -Strict -Quiet
.EXAMPLE
  .\scripts\engram-validate.ps1 -Content "**What**: cmd | **Exit code**: 0 | **Output**: ok" -DomainFields @("Exit code","Output")
#>
param(
    [Parameter(ValueFromPipeline = $true)]
    [object]$Content,
    [string]$Title = "",
    [ValidateSet('bugfix','decision','pattern','learning','discovery','config','')]
    [string]$Type = "",
    [string]$TopicKey = "",
    [switch]$Strict,
    [string[]]$DomainFields,
    [switch]$PassThru,
    [switch]$Quiet,
    [switch]$Fix
)
Set-StrictMode -Version Latest

begin {
    $script:exitCode = 0
    function Write-ErrorMsg { param([string]$Msg) $script:exitCode = 2; if (-not $Quiet) { Write-Warning "ERR: $Msg" } }
    function Write-WarnMsg  { param([string]$Msg) if ($script:exitCode -lt 1) { $script:exitCode = 1 }; if (-not $Quiet) { Write-Warning "WARN: $Msg" } }
}

process {
    $contentStr = ""
    $titleStr = $Title
    $typeStr = $Type
    $topicStr = $TopicKey

    if ($Content -is [string]) {
        $contentStr = $Content
    } elseif ($Content -is [hashtable]) {
        if ($Content.ContainsKey('Content')) { $contentStr = $Content['Content'] }
    }

    $errors = @()
    $warnings = @()
    $foundFields = @()

    # --- 1. Content empty check ---
    if ([string]::IsNullOrWhiteSpace($contentStr)) {
        if ($PassThru) { return $null }
        if (-not $Quiet) {
            Write-ErrorMsg "Content is empty"
            $result = [PSCustomObject]@{ valid = $false; errors = @("Content is empty"); warnings = @(); fields = @(); fixed = $false; content = $null }
            Write-Output $result
        }
        return
    }

    # --- 2. Extract **fields** (names + values) ---
    $fieldNameRegex = [regex]'\*\*([^*]+)\*\*'
    $fieldRegex = [regex]'\*\*([^*]+)\*\*\s*:\s*([^\n]*(?:\n(?!\*\*)[^\n]*)*)'
    $foundFields = @($fieldNameRegex.Matches($contentStr) | ForEach-Object { $_.Groups[1].Value.Trim() })
    $fieldValues = @{}
    foreach ($m in $fieldRegex.Matches($contentStr)) {
        $fname = $m.Groups[1].Value.Trim()
        $fvalue = $m.Groups[2].Value.Trim()
        if (-not $fieldValues.ContainsKey($fname)) { $fieldValues[$fname] = @() }
        $fieldValues[$fname] += $fvalue
    }

    # --- 3. Injection patterns ---
    $injectionPatterns = @("ignore previous", "forget instructions", "system prompt", "new instructions", "ignore all", "override", "new rule", "disregard", "you are now", "ignore everything", "forget previous", "system message", "ignore instructions", "forget all", "you are not", "disregard previous")
    # Homoglyph check: unicode chars that visually resemble ASCII (injection bypass defense)
    $homoglyphChars = @{
        [char]0x0430 = 'a'; # Cyrillic а → Latin a
        [char]0x0435 = 'e'; # Cyrillic е → Latin e
        [char]0x043E = 'o'; # Cyrillic о → Latin o
        [char]0x0441 = 'c'; # Cyrillic с → Latin c
        [char]0x0440 = 'p'; # Cyrillic р → Latin p
        [char]0x0445 = 'x'; # Cyrillic х → Latin x
        [char]0x0456 = 'i'; # Cyrillic і → Latin i
        [char]0x043A = 'k'; # Cyrillic к → Latin k
        [char]0x043C = 'm'; # Cyrillic м → Latin m
        [char]0x0432 = 'v'; # Cyrillic в → Latin v
        [char]0x043D = 'h'; # Cyrillic н → Latin h
        [char]0x0442 = 't'; # Cyrillic т → Latin t
    }
    foreach ($kv in $homoglyphChars.GetEnumerator()) {
        if ($contentStr -match [regex]::Escape($kv.Key)) {
            $errors += "Homoglyph detected: '$($kv.Key)' (looks like '$($kv.Value)') — injection bypass attempt"
            if (-not $Quiet) { Write-ErrorMsg "Homoglyph character U+$('{0:X4}' -f [int]$kv.Key) (looks like '$($kv.Value)') — possible injection bypass" }
        }
    }
    # Strategy A: normalize whitespace + check raw (catches single-field, multi-space, tab variants)
    $normalized = $contentStr -replace '\s+', ' '
    # Strategy B: join field values (catches split-across-fields: "ignore" in What + "previous" in Why)
    $fieldValueRegex = [regex]'\*\*[^*]+\*\*\s*:\s*((?:(?!\*\*|\n).)*)'
    $allValues = @($fieldValueRegex.Matches($contentStr) | ForEach-Object { $_.Groups[1].Value.Trim() }) -join ' '
    foreach ($pat in $injectionPatterns) {
        if (($normalized -match [regex]::Escape($pat)) -or ($allValues -match [regex]::Escape($pat))) {
            $errors += "Injection pattern detected: '$pat'"
            if (-not $Quiet) { Write-ErrorMsg "Injection pattern detected in content: '$pat'" }
        }
    }
    # Check topic_key
    if ($topicStr) {
        foreach ($pat in $injectionPatterns) {
            if ($topicStr -match [regex]::Escape($pat)) {
                $errors += "Injection pattern in topic_key: '$pat'"
                if (-not $Quiet) { Write-ErrorMsg "Injection pattern in topic_key: '$pat'" }
            }
        }
    }

    # --- 3. Extract **fields** ---
    $fieldRegex = [regex]'\*\*([^*]+)\*\*'
    # --- 4. Check canonical fields ---
    $canonical = @("What")
    if ($Strict) { $canonical = @("What", "Why", "Where", "Learned") }

    # Add domain-specific fields if provided
    $validFields = $canonical + @($DomainFields | Where-Object { $_ -and $_ -ne "" })

    foreach ($req in $canonical) {
        if ($foundFields -notcontains $req) {
            if ($req -eq "What") {
                $warnings += "Missing required field: **$req**"
                if (-not $Quiet) { Write-WarnMsg "Missing required field: **$req**" }
            } else {
                $wMsg = "Missing canonical field: **$req** - $typeStr saves richer with full schema"
                $warnings += $wMsg
                if (-not $Quiet) { Write-WarnMsg $wMsg }
            }
        }
    }

    # --- 5. Type-specific field count check ---
    $typeMinFields = @{
        'bugfix' = 2; 'decision' = 2; 'pattern' = 2
        'learning' = 2; 'discovery' = 1; 'config' = 1
    }
    if ($typeStr -and $typeMinFields.ContainsKey($typeStr)) {
        $minF = $typeMinFields[$typeStr]
        if ($foundFields.Count -lt $minF) {
            $warnings += "Type '$typeStr' expects >=$minF fields (found $($foundFields.Count))"
            if (-not $Quiet) { Write-WarnMsg "Type '$typeStr' expects >=$minF fields (found $($foundFields.Count))" }
        }
    }

    # --- 6. Fix mode ---
    if ($Fix -and $foundFields -notcontains "What") {
        $contentStr = "**What**: Auto-detected`n$contentStr"
        $foundFields = @($fieldRegex.Matches($contentStr) | ForEach-Object { $_.Groups[1].Value.Trim() })
        if (-not $Quiet) { Write-Host "  🔧 Auto-fixed: prepended **What**: Auto-detected" -ForegroundColor DarkYellow }
    }

    # --- 7. Output ---
    if ($PassThru) {
        if ($errors.Count -gt 0) {
            return $null
        }
        return $Content
    }

    if (-not $Quiet) {
        if ($errors.Count -eq 0 -and $warnings.Count -eq 0) {
            Write-Host "  ✅ Engram content valid" -ForegroundColor Green
        } elseif ($errors.Count -eq 0) {
            Write-Host "  ⚠️  Engram content valid with $($warnings.Count) warning(s)" -ForegroundColor Yellow
        } else {
            Write-Host "  ❌ Engram content invalid: $($errors.Count) error(s)" -ForegroundColor Red
        }

        $result = [PSCustomObject]@{
            valid    = ($errors.Count -eq 0)
            errors   = $errors
            warnings = $warnings
            fields   = $foundFields
            fixed    = $Fix -and ($foundFields -contains "What") -and ($Content -is [string]) -and ($contentStr -ne $Content)
            content  = if ($Fix) { $contentStr } else { $null }
        }
        Write-Output $result
    }
}

end {
    # In Quiet mode, output nothing — caller reads $LASTEXITCODE from outside Pester
}
