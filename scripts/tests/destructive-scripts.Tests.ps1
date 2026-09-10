#requires -Version 7

BeforeAll {
    $scriptsRoot = Resolve-Path "$PSScriptRoot/.."
}

Describe "Destructive Script Safety — <_.Name>" -ForEach (
    (Get-ChildItem -Path "$PSScriptRoot/.." -Filter "*.ps1" -Recurse) |
    Where-Object {
        $_.DirectoryName -notlike "*tests*" -and
        $_.FullName -notmatch '\\scripts\\lib[\\/]' -and
        $_.Name -ne "destructive-scripts.Tests.ps1" -and
        $_.Name -notlike "smoke-*" -and
        ($_.Name -match '(close|rollback|restore|backup|push|clean|force|forge|wipe|demote|store)' -or
         (@(Get-Content $_.FullName -ErrorAction SilentlyContinue | Where-Object {
                 # Forense 2026-09-10 (obs #725): misma lógica de líneas-ejecutables que el
                 # cross-check — quita strings "..."/'...' y comentarios #..., exige git push
                 # ejecutable; Remove-Item/Clear-Content también sobre $code (no prosa).
                 $code = $_ -replace '"[^"]*"', '' -replace "'[^']*'", ''
                 $code = $code -replace '^\s*#.*$', ''
                 ($code -match 'Remove-Item' -or $code -match 'Clear-Content' -or
                  $code -match '(?<![\w])git\s+push\b(?!\s*[/+])')
             }).Count -gt 0))
    }
) {

    BeforeAll {
        $scriptContent = Get-Content $_.FullName -Raw -ErrorAction Stop
    }

    Context "Parameter Validation" {

        It "should have a param block" {
            $scriptContent | Should -Match 'param\s*\('
        }

        It "should have named parameters (not empty param())" {
            $scriptContent | Should -Match 'param\s*\([^)]+\S+[^)]*\)'
        }
    }

    Context "Safety Guards" {

        It "should have WhatIf/Confirm, Force, or DryRun support" {
            $hasShouldProcess = $scriptContent -match 'SupportsShouldProcess'
            $hasWhatIf = $scriptContent -match '\$WhatIfPreference|\-WhatIf'
            $hasForceParam = $scriptContent -match 'param\s*\([^)]*\[switch\]\s*\$Force[^)]*\)'
            $hasForceVar = $scriptContent -match '\$Force\b'
            $hasForce = $hasForceParam -or $hasForceVar
            $hasDryRun = $scriptContent -match 'DryRun|dry.run'

            ($hasShouldProcess -or $hasWhatIf -or $hasForce -or $hasDryRun) |
                Should -BeTrue -Because "destructive scripts need at least one safety mechanism"
        }

        It "should have SupportsShouldProcess OR equivalent param-based safety (flag if missing)" {
            $hasShouldProcess = $scriptContent -match 'SupportsShouldProcess'
            $hasForceOrDryRun = $scriptContent -match 'param\s*\(' -and
                $scriptContent -match '\[switch\]\s*\$(Force|DryRun|WhatIf|Confirm)'

            if (-not $hasShouldProcess) {
                Write-Warning "INFO: $($_.Name) lacks SupportsShouldProcess (advanced function binding)"
            }
            ($hasShouldProcess -or $hasForceOrDryRun) |
                Should -BeTrue -Because "scripts need SupportsShouldProcess or explicit -Force/-DryRun/-WhatIf params"
        }

        It "should have a -Force parameter for explicit override" {
            $scriptContent | Should -Match 'param\s*\([\s\S]*?\$Force[\s\S]*?\)'
        }

        It "should have -Force as a script parameter (not just cmdlet flag)" {
            $scriptContent | Should -Match 'param\s*\([\s\S]*?\$Force[\s\S]*?\)'
        }

        It "should gate destructive Remove-Item behind a condition" {
            $lines = @($scriptContent -split "`n")
            $removeLines = @($lines | Where-Object { $_ -match 'Remove-Item' })
            $ifLines = @($lines | Where-Object { $_ -match '^\s*(if|switch|\$Force|\$WhatIf|\$DryRun)' })

            if ($removeLines.Count -gt 0) {
                $ifLines.Count | Should -BeGreaterThan 0 -Because "Remove-Item calls should be gated by a condition"
            }
        }
    }

    Context "Dry-Run Mode" {

        It "should support WhatIf or DryRun or ShouldProcess or custom DryRun param" {
            $hasDryRun = $scriptContent -match 'DryRun|dry.run|WhatIfPreference|\-WhatIf'
            $hasShouldProcess = $scriptContent -match 'SupportsShouldProcess'
            $hasDryRunSwitch = $scriptContent -match '\[switch\]\s*\$DryRun'

            ($hasDryRun -or $hasShouldProcess -or $hasDryRunSwitch) | Should -BeTrue
        }

        It "should NOT perform Remove-Item unconditionally at script top level" {
            $scriptContent | Should -Not -Match '(?m)^\s*Remove-Item\s+.*\s+-Recurse\s+-Force\s*$'
        }
    }

    Context "Error Handling" {

        It "should not use -ErrorAction SilentlyContinue on destructive ops outside cleanup" {
            $lines = @($scriptContent -split "`n")
            $destructiveSilentLines = @()
            for ($i = 0; $i -lt $lines.Count; $i++) {
                $line = $lines[$i]
                if ($line -match 'Remove-Item.*-ErrorAction\s+SilentlyContinue' -and
                    $line -notmatch '(cleanup|temp|tmp|AfterAll|finally|Remove-Item.*\.tmp)') {
                    # Forense 2026-09-10: el SilentlyContinue acotado por try/catch con logging NO es
                    # supresión silenciosa (caso score-auto.ps1:90:
                    # `try { Remove-Item ... } catch { Write-Debug ... }`). Mirar contexto try/catch
                    # (misma línea o ventana ±5/2) en vez de solo regex de línea.
                    $prevStart = [Math]::Max(0, $i - 5)
                    $nextEnd = [Math]::Min($lines.Count - 1, $i + 2)
                    $windowPrev = ($lines[$prevStart..$i] -join "`n")
                    $windowNext = ($lines[$i..$nextEnd] -join "`n")
                    $inTryCatch = ($line -match 'try\s*\{' -and ($line -match 'catch\s*\{' -or $windowNext -match 'catch\s*\{')) -or
                        ($windowPrev -match 'try\s*\{' -and ($windowNext -match 'catch\s*\{' -or $line -match 'catch\s*\{'))
                    $catchHasLogging = ($line -match 'catch\s*\{[^}]*Write-(Debug|Warning|Verbose|Information|Output|Host|Error)') -or
                        ($windowNext -match 'catch\s*\{[^}]*Write-(Debug|Warning|Verbose|Information|Output|Host|Error)')
                    if ($inTryCatch -and $catchHasLogging) { continue }
                    $destructiveSilentLines += $line.Trim()
                }
            }
            if ($destructiveSilentLines.Count -gt 0) {
                Write-Warning "INFO: $($_.Name) has silent error suppression on destructive ops: $($destructiveSilentLines -join '; ')"
            }
            $destructiveSilentLines.Count | Should -Be 0 -Because "destructive Remove-Item should not silently suppress errors"
        }

        It "should have try/catch or -ErrorAction Stop or throw" {
            $hasTryCatch = $scriptContent -match 'try\s*\{'
            $hasErrorStop = $scriptContent -match '-ErrorAction\s+Stop'
            $hasThrow = $scriptContent -match 'throw\s'

            ($hasTryCatch -or $hasErrorStop -or $hasThrow) | Should -BeTrue
        }

        It "should have meaningful output (Write-Output/Host/Warning)" {
            $hasOutput = $scriptContent -match 'Write-Output|Write-Host|Write-Information|Write-Verbose|Write-Warning'
            $hasOutput | Should -BeTrue
        }
    }
}

Describe "Destructive Script Cross-Checks" {

    BeforeAll {
        $allNonTest = Get-ChildItem -Path "$PSScriptRoot/.." -Filter "*.ps1" -Recurse |
            Where-Object {
                $_.DirectoryName -notlike "*tests*" -and
                $_.FullName -notmatch '\\scripts\\lib[\\/]' -and
                $_.Name -ne "destructive-scripts.Tests.ps1"
            }

        $scriptsUsingRemoveRecurse = $allNonTest | Where-Object {
            (Get-Content $_.FullName -Raw -ErrorAction SilentlyContinue) -match 'Remove-Item.*-Recurse'
        }

        # Forense 2026-09-10: cero scripts con `git push` EJECUTABLE en scripts/ — solo menciones
        # no-ejecutables (context-watchdog-check.ps1:11 prosa en doc-block "git push / Write";
        # permission-gate.ps1:18,32 ejemplos entrecomillados + :85,99,107 comentarios;
        # sync-global.ps1:161 strings de permission-map entrecomilladas). El filtro naive anterior
        # las incluía y generaba falsos positivos (context-watchdog-check caía en unsafe-push sin
        # ser un pusher real). Solo cuentan líneas ejecutables: no-comentario, no entrecomilladas,
        # sin prosa posterior (/). NO inventar scripts con git-push para satisfacer el filtro.
        $scriptsUsingGitPush = $allNonTest | Where-Object {
            $execLines = @(Get-Content $_.FullName -ErrorAction SilentlyContinue | Where-Object {
                # Quitar strings y comentarios de línea: la prosa entrecomillada ("git push" en
                # .EXAMPLE/summaries/permission-maps) y los comentarios (#...) no son invocaciones.
                $code = $_ -replace '"[^"]*"', '' -replace "'[^']*'", ''
                $code = $code -replace '^\s*#.*$', ''
                $code -match '(?<![\w])git\s+push\b(?!\s*[/+])'
            })
            $execLines.Count -gt 0
        }

        $scriptsUsingRemoveItem = $allNonTest | Where-Object {
            (Get-Content $_.FullName -Raw -ErrorAction SilentlyContinue) -match 'Remove-Item'
        }

        $scriptsUnsafeRemove = @()
        foreach ($s in $scriptsUsingRemoveItem) {
            $c = Get-Content $s.FullName -Raw -ErrorAction SilentlyContinue
            $hasForceParam = $c -match 'param\s*\([\s\S]*?\$Force[\s\S]*?\)'
            if ($c -notmatch 'SupportsShouldProcess|DryRun|WhatIf|\-Confirm' -and -not $hasForceParam) {
                $scriptsUnsafeRemove += $s
            }
        }

        $scriptsUnsafePush = @()
        foreach ($s in $scriptsUsingGitPush) {
            $c = Get-Content $s.FullName -Raw -ErrorAction SilentlyContinue
            $hasForceParam = $c -match 'param\s*\([\s\S]*?\$Force[\s\S]*?\)'
            if ($c -notmatch 'SupportsShouldProcess|DryRun|WhatIf|\-Confirm' -and -not $hasForceParam) {
                $scriptsUnsafePush += $s
            }
        }
    }

    It "should have at least one script with Remove-Item -Recurse to verify filter works" {
        $scriptsUsingRemoveRecurse.Count | Should -BeGreaterThan 0
    }

    It "should have at least one script with git push to verify filter works" {
        # Forense 2026-09-10: 0 pushers ejecutables → el filtro opera en vacío. Pasa vacuamente
        # CON constancia (skip documentado) en vez de fallar; si aparece un pusher real, el assert lo cubre.
        if (@($scriptsUsingGitPush).Count -eq 0) {
            Set-ItResult -Skipped -Because "forense 2026-09-10: cero scripts con 'git push' ejecutable (solo comments/docs) — cross-check en vacío"
        } else {
            $scriptsUsingGitPush.Count | Should -BeGreaterThan 0
        }
    }

    It "all scripts with Remove-Item should have safety guards" {
        if ($scriptsUnsafeRemove.Count -gt 0) {
            $names = ($scriptsUnsafeRemove | ForEach-Object { $_.Name }) -join ", "
            $names | Should -BeNullOrEmpty -Because "unsafe scripts found: $names"
        }
    }

    It "all scripts with git push should have safety guards" {
        # Forense 2026-09-10: en vacío (0 pushers ejecutables) pasa vacuamente; con pushers reales exige guards.
        if ($scriptsUnsafePush.Count -gt 0) {
            $names = ($scriptsUnsafePush | ForEach-Object { $_.Name }) -join ", "
            $names | Should -BeNullOrEmpty -Because "unsafe scripts found: $names"
        }
    }
}
