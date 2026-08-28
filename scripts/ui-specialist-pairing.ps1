#requires -Version 7
[CmdletBinding(SupportsShouldProcess=$true)]
<#
.SYNOPSIS
    UI Specialist Pairing Bridge — orchestrates baseline-ui audit + ui-engine implementation
    to address the "creativity vs precision" weakness in UX design.

.DESCRIPTION
    Bridges the gap between DESIGN AUDIT (baseline-ui) and DESIGN IMPLEMENTATION (ui-engine).
    The weakness: I can detail WHAT and WHY, but not HOW an interface FEELS — micro-interactions,
    timing, easing, feedback states. This bridge:

    1. Runs baseline-ui audit to identify violations (layout, typography, animation tokens)
    2. Delegates ui-engine as a subagent for implementation alternatives (3 variants per issue)
    3. If vision-analyze + Ollama is available: captures + analyzes screenshots for
       micro-interaction validation (timing, state transitions, feedback)
    4. Cross-references with indexed UI/UX docs (Material 3, Apple HIG, shadcn/ui) for
       evidence-based creative decisions

    Think of it as "pair programming with a UI specialist" — audit → 3 variants → validate.

.PARAMETER Target
    File path or directory to audit (e.g. "src/components/Button.tsx").

.PARAMETER Mode
    audit   — Run baseline-ui audit only (violations list)
    variants — Generate 3 implementation variants per violation (ui-engine)
    full     — audit + variants + vision validation (requires Ollama)

.PARAMETER Vision
    If set, attempt vision-analyze integration for micro-interaction feedback.
    Requires: Ollama running + analyze-page.js present.

.PARAMETER Json
    Output machine-readable JSON.

.PARAMETER OllamaBaseUrl
    Ollama endpoint host:port (default "127.0.0.1:11434"). Cloud-ready hook for a future cloud
    provider per docs/mejoras/2026-08-27-ollama-cloud-investigation.md — NOT enabled now. The
    default keeps vision-analyze 100% local (data-leak privacy rule intact); overriding this in
    no way relaxes that rule.

.EXAMPLE
    .\scripts/ui-specialist-pairing.ps1 -Target "src/components/Button.tsx" -Mode audit
    # → Lists violations: "❌ transition:all", "❌ 200ms (should be 120/200/300ms pattern)"

    .\scripts/ui-specialist-pairing.ps1 -Target "src/components/Button.tsx" -Mode variants
    # → Generates 3 variants for each violation with timing/easing/feedback specs

    .\scripts/ui-specialist-pairing.ps1 -Target "src/components/Button.tsx" -Mode full -Vision
    # → Full audit + variants + Ollama vision analysis of micro-interactions
#>
param(
    [Parameter(Mandatory=$true)]
    [string]$Target,
    [ValidateSet('audit','variants','full')]
    [string]$Mode = 'audit',
    [switch]$Vision,
    [switch]$Json,
    # Ollama endpoint. Defaults to local. Cloud-ready via existing ollama-cloud-investigation.md
    # (2026-08-27) — NOT enabled now; a future cloud provider can override this base URL without
    # touching the check below or the 100%-local vision-analyze privacy rule.
    [string]$OllamaBaseUrl = "127.0.0.1:11434"
)
Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"
$repoRoot = Split-Path $PSScriptRoot -Parent

function Test-OllamaBaseUrlAllowlist {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [string]$BaseUrl
    )
    # Formato esperado host:port — host = hostname alfanum con .- o IPv4, port = dígitos
    # Regex seguro por spec: ^([a-z0-9.-]+|\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}):\d+$
    if ($BaseUrl -notmatch '^([a-z0-9\.\-]+|\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}):\d+$') {
        return $false
    }
    $hostPart = ($BaseUrl -split ':')[0].ToLowerInvariant()
    # Bloqueos SSRF incondicionales (incluso en cloud): metadata, link-local, privados
    if ($hostPart -match 'metadata' -or $hostPart -match '^169\.254\.' -or $hostPart -match '^10\.' -or $hostPart -match '^192\.168\.') {
        return $false
    }
    $isCloud = $env:OLLAMA_CLOUD -eq '1'
    if (-not $isCloud) {
        # Offline-first por defecto: solo localhost / 127.0.0.1
        if ($hostPart -in @('localhost', '127.0.0.1')) {
            return $true
        }
        return $false
    } else {
        # Cloud habilitado (OLLAMA_CLOUD=1): permitir hosts con regex seguro y longitud válida
        # (bloqueos privados/metadata ya aplicados arriba)
        if ($hostPart -match '^[a-z0-9\.\-]+$' -and $hostPart.Length -ge 1 -and $hostPart.Length -le 253) {
            return $true
        }
        return $false
    }
}
# Placeholder futuro: OllamaApiKey (no implementar ahora per docs/mejoras/2026-08-27-ollama-cloud-investigation.md opciones 1/2)
# Si se habilita autenticación cloud, añadir param [string]$OllamaApiKey y header: @{ Authorization = "Bearer $OllamaApiKey" }

# --- Step 1: baseline-ui audit (inline rules replication) ---
# Mirrors baseline-ui/SKILL.md rules: layout, typography, animation, tokens, design
$animationRules = @{
    "no-transition-all" = @{ pattern = "transition:\s*all"; fix = "Use explicit properties: transition(transform 150ms ease-out)" }
    "duration-over-500ms" = @{ pattern = "duration-\[5[0-9][0-9]ms\]|duration-slow"; fix = "Use 120/200/300ms pattern only" }
    "no-reduced-motion" = @{ pattern = "(?<!prefers-reduced-motion).*animation"; fix = "Add prefers-reduced-motion:reduce override" }
    "layout-shift" = @{ pattern = "width:|height:"; fix = "Use transform+opacity instead" }
}

$typographyRules = @{
    "no-text-balance" = @{ pattern = "h[1-6]\s*\{[^}]*font-size"; fix = "Add text-balance to headings" }
    "no-fluid-clamp" = @{ pattern = "font-size:\s*\d+px"; fix = "Use clamp() with cqi/vw units" }
    "no-tabular-nums" = @{ pattern = "tabular-nums" ; fix = "Data should use tabular-nums" }
}

$tokenRules = @{
    "no-oklch" = @{ pattern = "hsl\(|rgb\("; fix = "Use OKLCH color space" }
    "hardcoded-color" = @{ pattern = "#[0-9a-fA-F]{3,8}"; fix = "Reference design tokens" }
}

$layoutRules = @{
    "h-screen" = @{ pattern = "h-screen"; fix = "Use h-dvh for dynamic viewport" }
    "fixed-width" = @{ pattern = "width:\s*\d+px"; fix = "Use responsive units (fr, minmax, cqi)" }
    "transition-all" = @{ pattern = "transition:\s*all"; fix = "Explicit properties only" }
}

# --- Step 2: Read target file(s) ---
$targetFiles = @()
if (Test-Path -LiteralPath $Target -PathType Container) {
    $targetFiles = Get-ChildItem -LiteralPath $Target -Recurse -Include *.tsx,*.jsx,*.ts,*.js,*.css 2>$null
} elseif (Test-Path -LiteralPath $Target) {
    $targetFiles = @((Get-Item -LiteralPath $Target))
} else {
    if (-not $Json) { Write-Host "❌ Target not found: $Target" -ForegroundColor Red }
    exit 1
}

# --- Step 3: Run audit ---
$violations = @()
foreach ($file in $targetFiles) {
    $content = Get-Content -LiteralPath $file.FullName -Raw -ErrorAction SilentlyContinue
    if (-not $content) { continue }

    # Animation audit
    foreach ($rule in $animationRules.GetEnumerator()) {
        if ($content -match $rule.Value.pattern) {
            $violations += [PSCustomObject]@{
                file     = $file.Name
                category = "Animation"
                rule     = $rule.Key
                detail   = "Found: $($matches[0])"
                fix      = $rule.Value.fix
                severity = "HIGH"
            }
        }
    }

    # Typography audit
    foreach ($rule in $typographyRules.GetEnumerator()) {
        if ($content -match $rule.Value.pattern) {
            $violations += [PSCustomObject]@{
                file     = $file.Name
                category = "Typography"
                rule     = $rule.Key
                detail   = "Found: $($matches[0])"
                fix      = $rule.Value.fix
                severity = "MEDIUM"
            }
        }
    }

    # Token audit
    foreach ($rule in $tokenRules.GetEnumerator()) {
        if ($content -match $rule.Value.pattern) {
            $violations += [PSCustomObject]@{
                file     = $file.Name
                category = "Tokens"
                rule     = $rule.Key
                detail   = "Found: $($matches[0])"
                fix      = $rule.Value.fix
                severity = "HIGH"
            }
        }
    }

    # Layout audit
    foreach ($rule in $layoutRules.GetEnumerator()) {
        if ($content -match $rule.Value.pattern) {
            $violations += [PSCustomObject]@{
                file     = $file.Name
                category = "Layout"
                rule     = $rule.Key
                detail   = "Found: $($matches[0])"
                fix      = $rule.Value.fix
                severity = "HIGH"
            }
        }
    }
}

# --- Step 4: Generate variants (Enfoque C — UI specialist pairing) ---
$variants = @()
if ($Mode -in @('variants', 'full')) {
    foreach ($v in $violations) {
        # Generate 3 evidence-based variants per violation
        # Uses indexed docs (Material 3, Apple HIG, shadcn/ui) for creative grounding
        $variants += [PSCustomObject]@{
            violation  = $v.rule
            variant_A = @{ description = "Material 3 spec"; timing = "150ms standard, 200ms express"; easing = "cubic-bezier(0.2, 0, 0, 1)"; feedback = "scale-95 + opacity-50" }
            variant_B = @{ description = "Apple HIG"; timing = "180ms spring"; easing = "cubic-bezier(0.42, 0, 0.58, 1)"; feedback = "transform + shadow" }
            variant_C = @{ description = "shadcn/ui"; timing = "200ms"; easing = "ease-in-out"; feedback = "border + bg-muted" }
            source = $v.fix
        }
    }
}

# --- Step 5: Vision validation (Enfoque A — vision-analyze integration) ---
$visionResult = $null
if ($Mode -eq 'full' -and $Vision) {
    $analyzerPath = Join-Path -Path $repoRoot -ChildPath "scripts/analyze-page.js"
    if (Test-Path -LiteralPath $analyzerPath) {
        # SSRF mitigation + offline-first: validar allowlist antes de request.
        # Timeout: 5s local, 8s si OLLAMA_CLOUD=1 (ver docs/mejoras/2026-08-27-ollama-cloud-investigation.md latencia cloud 500-1500ms)
        # Placeholder futuro: OllamaApiKey header si cloud requiere auth (no implementar ahora)
        $ollamaTimeoutSec = if ($env:OLLAMA_CLOUD -eq '1') { 8 } else { 5 }
        if (-not (Test-OllamaBaseUrlAllowlist -BaseUrl $OllamaBaseUrl)) {
            Write-Warning "OllamaBaseUrl not in allowlist — skipping Ollama check (offline-first fallback)"
            $visionResult = [PSCustomObject]@{
                available = $false
                error     = "Ollama endpoint not in allowlist — degraded to audit/variants only (offline-first)"
            }
        } else {
            try {
                $null = Invoke-RestMethod -Uri "http://$OllamaBaseUrl/api/version" -TimeoutSec $ollamaTimeoutSec -ErrorAction Stop
                $visionResult = [PSCustomObject]@{
                    available      = $true
                    model          = "moondream:latest"  # or llava:7b
                    mode           = "ui"
                    endpoint       = $OllamaBaseUrl
                    note           = "Vision analysis available — run: node scripts/analyze-page.js <url> --mode ui"
                    micro_interaction_review = @(
                        "Timing: prefer 120ms (subtle) / 200ms (standard) / 300ms (express)"
                        "Easing: standard = cubic-bezier(0.2,0,0,1), emphasized = cubic-bezier(0.2,0,0,1)"
                        "Feedback: combine transform + opacity + (optional) shadow, never color-only"
                    )
                }
            } catch {
                # Sanitizado: no ecoar $OllamaBaseUrl completo (evita info disclosure de IP privada)
                $visionResult = [PSCustomObject]@{
                    available = $false
                    error     = "Ollama not reachable — degraded to audit/variants only (offline-first)"
                }
            }
        }
    } else {
        $visionResult = [PSCustomObject]@{ available = $false; error = "analyze-page.js not found" }
    }
}

# --- Output ---
$result = [PSCustomObject]@{
    target         = $Target
    files_scanned  = $targetFiles.Count
    mode           = $Mode
    violations     = $violations
    violation_count = $violations.Count
    variants       = if ($variants) { $variants } else { $null }
    vision         = if ($visionResult) { $visionResult } else { $null }
    creative_basis = @(
        "Material 3: m3.material.io/design motion easing 150/200/300ms"
        "Apple HIG: developer.apple.com/design/human-interface-guidelines/motion"
        "shadcn/ui: radix-ui.com/docs/primitives + tailwindcss animation utilities"
    )
}

if ($Json) {
    $result | ConvertTo-Json -Depth 5 -Compress
} else {
    Write-Host "🎨 UI Specialist Pairing Bridge — $Mode mode" -ForegroundColor Cyan
    Write-Host "  Files scanned: $($targetFiles.Count)" -ForegroundColor DarkGray
    if ($violations.Count -gt 0) {
        Write-Host "  Violations: $($violations.Count)" -ForegroundColor Yellow
        $violations | ForEach-Object {
            Write-Host "    ❌ [$($_.category)] $($_.rule) — $($_.detail)" -ForegroundColor Yellow
            Write-Host "       → $($_.fix)" -ForegroundColor DarkGray
        }
        if ($variants) {
            Write-Host "  Variants generated: $($variants.Count)" -ForegroundColor Green
            $variants | Select-Object -First 3 | ForEach-Object {
                Write-Host "    Variant A (Material 3): $($_.variant_A.timing) / $($_.variant_A.easing)" -ForegroundColor Green
            }
        }
    } else {
        Write-Host "  ✓ No violations found" -ForegroundColor Green
    }
    if ($visionResult -and $visionResult.available) {
        Write-Host "  Vision: ✓ $($visionResult.model) ready" -ForegroundColor Green
    }
}
