#requires -Version 5.1
<#
.SYNOPSIS
  Pre-execution reviewer: analyzes a command WITHOUT running it.
.DESCRIPTION
  Filosofia: maxima autonomia. Red anti-accidentes propios, no defensa
  anti-atacantes. Solo analisis regex/AST-free. Nunca ejecuta el comando.
  NOTA TOCTOU: las subexpresiones literales del llamador (p. ej. $(...))
  se evaluan por PowerShell ANTES de que este script corra. Para que la
  revision sea efectiva, pasa el comando por variable
  ($c = '...'; & script -Command $c). El uso literal con subexpresiones
  se ejecuta pre-revision: ningun analisis posterior puede evitarlo.
   Cobertura de confusables Unicode: best-effort v3. La normalizacion cubre
   latin extendido (FormKD + marcas Mn) y una tabla explicita de
   homoglifos cirilicos/griegos/IPA frecuentes (defensa en profundidad
   para lookalikes dentro del bloque Latin). El gate mixed-script marca
   FAIL todo token (delimitado por whitespace) que mezcle Latin con otro
   script (Cyrillic, Greek, Armenian, Cherokee, IPA/Phonetic Extensions):
   cubre homoglifos presentes y futuros. LIMITES: confusables intra-Latin
   fuera de tabla = best-effort (cobertura perfecta imposible, ver UTS #39);
   surrogates (>U+FFFF, p. ej. emoji o simbolos matematicos) no testeables
   en 5.1 ([char] solo cubre el BMP).
.EXAMPLE
  & "./scripts/pre-exec-review.ps1" -Command "Get-ChildItem scripts"
#>
[CmdletBinding()]
param(
  # Pasa el comando por variable ($c = '...'; -Command $c): los literales con
  # subexpresiones $(...) se ejecutan por el llamador ANTES de esta revision (TOCTOU).
  [Parameter(Mandatory = $true, Position = 0)]
  [ValidateNotNullOrEmpty()]
  [string]$Command,

  [ValidateSet('permissive', 'strict')]
  [string]$Mode = 'permissive',

  [switch]$Json,

  [switch]$Quiet
)

$failHits = @()
$warnHits = @()
$failReasons = @()
$warnReasons = @()

# ---------- NORMALIZACION ANTI-HOMOGLIFOS (v2, best-effort) ----------
# FormKD descompone latin extendido; el strip Mn elimina diacriticos. Los
# homoglifos cirilicos/griegos y letras IPA confusables no se descomponen,
# asi que se mapean con tabla explicita. Cobertura perfecta imposible (UTS #39).
$n = $Command.Normalize([Text.NormalizationForm]::FormKD) -replace '\p{Mn}', ''
# NOTA: no se usa hashtable @{ } porque PowerShell la crea case-insensitive
# y colisionaria (p. ej. U+0430 'а' == U+0410 'А'). Dos strings paralelos + IndexOf Ordinal.
$cfCodes = @(0x0430,0x0410,0x0441,0x0421,0x0435,0x0415,0x0456,0x0406,0x0458,0x0408,0x043E,0x041E,0x0440,0x0420,0x0455,0x0405,0x0445,0x0425,0x0443,0x0423,0x03B1,0x0391,0x03B5,0x0395,0x03B9,0x0399,0x03BF,0x039F,0x03C1,0x03A1,0x03C7,0x03A7,0x03BD,0x039D,0x0262,0x026A,0x0280,0x043C,0x041C)
$cfFrom = -join ($cfCodes | ForEach-Object { [string][char]$_ })
$cfTo = 'aAcCeEiIjJoOpPsSxXyYaAeEiIoOpPxXvNGIRmM'
$sb = New-Object Text.StringBuilder ($n.Length)
foreach ($ch in $n.ToCharArray()) {
  $s = [string]$ch
  $idx = $cfFrom.IndexOf($s, [StringComparison]::Ordinal)
  if ($idx -ge 0) { [void]$sb.Append($cfTo[$idx]) }
  else { [void]$sb.Append($s) }
}
$n = $sb.ToString()
Write-Debug ('pre-exec-review normalized len={0}' -f $n.Length)

# ---------- MIXED-SCRIPT GATE (v3: reemplaza whack-a-mole de codepoints) ----------
# Si un mismo token (delimitado por whitespace) mezcla Latin con otro script,
# es homoglifo presente o futuro -> FAIL con hit mixed-script. Fullwidth ya
# plegado por NFKD da igual. La tabla explicita se MANTIENE (defensa en
# profundidad para lookalikes dentro del bloque Latin: U+0262/U+026A/U+0280).
$mixedFound = $false
$gateTokens = $Command -split '\s+'
foreach ($tok in $gateTokens) {
  if ($tok -match '[A-Za-z]') {
    if ($tok -match '\p{IsCyrillic}|\p{IsGreek}|\p{IsArmenian}|\p{IsCherokee}|\p{IsIPAExtensions}|[\u1D00-\u1D7F]') {
      $mixedFound = $true
      break
    }
  }
}
if ($mixedFound) {
  $failHits += 'mixed-script'
  $failReasons += 'token mezcla Latin con otro script (posible homoglifo)'
}

# ---------- FAIL PATTERNS (v1, case-insensitive; -match already is) ----------

if ($n -match '\brm\b[^\n;|&]*-[A-Za-z]*r[A-Za-z]*f[^\n;|&]*[/~*]') {
  $failHits += 'rm-rf-destructive'
  $failReasons += 'rm -rf con objetivo /, ~ o *'
}
elseif ($n -match '\brm\b[^\n;|&]*-[A-Za-z]*f[A-Za-z]*r[^\n;|&]*[/~*]') {
  $failHits += 'rm-rf-destructive'
  $failReasons += 'rm -rf con objetivo /, ~ o *'
}

# ri solo cuenta en posicion de comando (inicio o tras ; & |): asi $ri=1,
# Write-Output ri y Get-Item -Path ri quedan PASS. Remove-Item (nombre
# completo) es inequivoco y usa match amplio.
$hasRemoveFull = $n -match '\bRemove-Item\b'
$riCmdStart = $n -match '(^|[;&|]\s*)ri(\s|[;&|]|/|-|$)'
$hasRecurse = $n -match '-Recurse'
$hasForce = $n -match '-Force'
$hasWildcard = $n -match '\*'

if ((($hasRemoveFull) -or ($riCmdStart)) -and ($hasRecurse) -and ($hasForce)) {
  $failHits += 'remove-item-recurse-force'
  $failReasons += 'Remove-Item/ri con -Recurse + -Force'
}

if (($riCmdStart) -and ($hasRecurse)) {
  $failHits += 'ri-recurse'
  $failReasons += 'ri con -Recurse (alias destructivo aun sin -Force)'
}

if ((($hasRemoveFull) -or ($riCmdStart)) -and ($hasRecurse) -and ($hasWildcard)) {
  $failHits += 'remove-item-recurse-wildcard'
  $failReasons += 'Remove-Item/ri con -Recurse + wildcard * (mass delete sin -Force)'
}

if ($n -match '\bgit\s+push\b[^\n;|&]*--force') {
  $failHits += 'git-push-force'
  $failReasons += 'git push --force reescribe remoto'
}
elseif ($n -match '\bgit\s+push\b[^\n;|&]*\s-f(\s|$|;|&)') {
  $failHits += 'git-push-force'
  $failReasons += 'git push -f reescribe remoto'
}

if ($n -match '\bgit\s+reset\s+--hard\b') {
  $failHits += 'git-reset-hard'
  $failReasons += 'git reset --hard descarta cambios'
}

if ($n -match '\bgit\s+checkout\s+--[^\n;|&]*') {
  $failHits += 'git-checkout-dot'
  $failReasons += 'git checkout -- <ruta> descarta cambios (incluye -- . y --*)'
}

if (($n -match '\bgit\s+clean\b[^\n;|&]*-[A-Za-z]*f') -and ($n -match '\bgit\s+clean\b[^\n;|&]*-[A-Za-z]*d')) {
  $failHits += 'git-clean-fd'
  $failReasons += 'git clean con -f + -d borra archivos sin seguimiento (cualquier orden)'
}

if ($n -match '\b(del|erase)\b[^\n;|&]*/s\b') {
  $failHits += 'del-s'
  $failReasons += 'del/erase /s borra recursivo'
}

if ($n -match '\b(rd|rmdir)\b[^\n;|&]*/s\b') {
  $failHits += 'rd-s'
  $failReasons += 'rd/rmdir /s borra recursivo (cualquier combinacion /s /q)'
}

if ($n -match '\bdeltree\b') {
  $failHits += 'deltree'
  $failReasons += 'deltree borra recursivo'
}

if (($n -match '\bgit\s+restore\b') -and ($n -notmatch '--staged')) {
  $failHits += 'git-restore-unstaged'
  $failReasons += 'git restore sin --staged destruye worktree (con --staged queda permitido)'
}

if ($n -match '\bgit\s+stash\b[^\n;|&]*\b(drop|pop)\b') {
  $failHits += 'git-stash-drop-pop'
  $failReasons += 'git stash drop/pop descarta stash'
}

if ($n -match '\bClear-Content\b') {
  $failHits += 'clear-content'
  $failReasons += 'Clear-Content vacia archivos'
}

if ($n -match '\bNew-Item\b[^\n;|&]*-Force\b') {
  $failHits += 'new-item-force'
  $failReasons += 'New-Item -Force sobrescribe'
}

if ($n -match '\bMove-Item\b[^\n;|&]*-Force\b') {
  $failHits += 'move-item-force'
  $failReasons += 'Move-Item -Force sobrescribe'
}

if ($n -match '(^|[\s;&|])format(\.exe|\.com)?(?![-\w])') {
  $failHits += 'format'
  $failReasons += 'format borra disco'
}

if ($n -match '\bdiskpart\b') {
  $failHits += 'diskpart'
  $failReasons += 'diskpart manipula discos'
}

if ($n -match '\bmkfs\b') {
  $failHits += 'mkfs'
  $failReasons += 'mkfs formatea volumen'
}

if ($n -match '\s-(EncodedCommand|enc(odedcommand)?)\b') {
  $failHits += 'encoded-command'
  $failReasons += '-EncodedCommand oculta el payload'
}

$hasIex = $false
if ($n -match '\biex\b') { $hasIex = $true }
if ($n -match '\bInvoke-Expression\b') { $hasIex = $true }
$hasNet = $false
if ($n -match '\b(irm|iwr)\b') { $hasNet = $true }
if ($n -match '\bInvoke-WebRequest\b') { $hasNet = $true }
if ($n -match '\bInvoke-RestMethod\b') { $hasNet = $true }
if ($n -match 'https?://') { $hasNet = $true }
if ($hasIex -and $hasNet) {
  $failHits += 'iex-remote'
  $failReasons += 'iex/Invoke-Expression sobre contenido de red'
}

if ($n -match '\b(curl|wget)\b[^\n|]*\|\s*(sh|bash|pwsh|powershell|iex|Invoke-Expression)\b') {
  $failHits += 'curl-pipe-shell'
  $failReasons += 'curl|wget entubado a shell'
}

if ($n -match '\b(Set|Add)-MpPreference\b') {
  $failHits += 'mp-preference'
  $failReasons += 'Set-/Add-MpPreference debilita Defender'
}

if ($n -match '\bnet\b\s+user\b') {
  $failHits += 'net-user'
  $failReasons += 'net user manipula cuentas'
}

if ($n -match '\bNew-Service\b') {
  $failHits += 'new-service'
  $failReasons += 'New-Service instala servicio'
}

if ($n -match '\bsc(\.exe)?\b[^\n;|&]*\b(create|config|delete|failure)\b') {
  $failHits += 'sc-service-mutate'
  $failReasons += 'sc create/config/delete/failure muta servicios (sc query sigue permitido)'
}

if ($n -match '\bschtasks\b[^\n;|&]*/create\b') {
  $failHits += 'schtasks-create'
  $failReasons += 'schtasks /create crea tarea programada'
}

if ($n -match '\b[xi]?cacls\b') {
  $failHits += 'icacls'
  $failReasons += 'icacls/cacls/xcacls cambia permisos'
}

if ($n -match '\b(nc|ncat)(\.exe)?\b[^\n;|&]*\s-e\b') {
  $failHits += 'nc-bind-shell'
  $failReasons += 'nc/ncat con -e abre shell remota'
}

# ---------- WARN PATTERNS (v1) ----------

if (($n -match '\b(npm|pip|pip3|bun|yarn|pnpm)\b\s+(install|add|exec|dlx)\b') -or ($n -match '\bnpm\s+i(\s|$|;|&)')) {
  $warnHits += 'pkg-install'
  $warnReasons += 'instalacion de paquetes de terceros (npm i = shorthand de install; "in" excluido: ambiguo con init)'
}

if ($n -match '\bnpx\b') {
  $warnHits += 'npx'
  $warnReasons += 'npx ejecuta paquete remoto'
}

$hasFetch = $false
if ($n -match '\b(irm|iwr)\b') { $hasFetch = $true }
if ($n -match '\bInvoke-WebRequest\b') { $hasFetch = $true }
if ($n -match '\bInvoke-RestMethod\b') { $hasFetch = $true }
if ($n -match '\bcurl\b') { $hasFetch = $true }
if ($n -match '\bwget\b') { $hasFetch = $true }
if ($hasFetch) {
  $warnHits += 'fetch-remote'
  $warnReasons += 'descarga contenido de red'
}

if (($n -match '\bdocker\b\s+(run|pull)\b') -or ($n -match '--privileged\b')) {
  $warnHits += 'docker-risk'
  $warnReasons += 'docker run/pull/--privileged'
}

if ($n -match '\bgh\b\s+release\s+delete\b') {
  $warnHits += 'gh-release-delete'
  $warnReasons += 'gh release delete borra release'
}

# ri solo WARN en contexto de comando con objetivo (espacio + no-=) o solo:
# ri <target> -> WARN; $ri=1, Write-Output ri, Get-Item -Path ri -> nada.
$riWarnCtx = $n -match '(^|[;&|]\s*)ri\s+[^=\s]'
$riBare = $n -match '(^|[;&|]\s*)ri\s*$'
$removeFailed = $false
if ($failHits -contains 'remove-item-recurse-force') { $removeFailed = $true }
if ($failHits -contains 'ri-recurse') { $removeFailed = $true }
if ($failHits -contains 'remove-item-recurse-wildcard') { $removeFailed = $true }
if ($hasRemoveFull) {
  if (-not ($removeFailed)) {
    $warnHits += 'remove-item'
    $warnReasons += 'Remove-Item/ri borra archivos'
  }
}
if (($riWarnCtx) -or ($riBare)) {
  if (-not ($removeFailed)) {
    if (-not ($warnHits -contains 'remove-item')) {
      $warnHits += 'remove-item'
      $warnReasons += 'Remove-Item/ri borra archivos'
    }
  }
}

$hasGitDanger = $false
if ($n -match '\bgit\s+rebase\b') { $hasGitDanger = $true }
if ($n -match '\bgit\s+reset\b') { $hasGitDanger = $true }
if ($n -match '\bgit\s+push\b') { $hasGitDanger = $true }
if ($hasGitDanger) {
  $isGitFail = $false
  if ($failHits -contains 'git-push-force') { $isGitFail = $true }
  if ($failHits -contains 'git-reset-hard') { $isGitFail = $true }
  if ($failHits -contains 'git-checkout-dot') { $isGitFail = $true }
  if ($failHits -contains 'git-clean-fd') { $isGitFail = $true }
  if (-not $isGitFail) {
    $warnHits += 'git-mutating'
    $warnReasons += 'git rebase/reset/push muta historial o remoto'
  }
}

if ($n -match 'Start-Process\b[^\n;|&]*-Verb\s+RunAs\b') {
  $warnHits += 'runas'
  $warnReasons += 'Start-Process con -Verb RunAs eleva privilegios'
}

if ($n -match '\bSet-ExecutionPolicy\b') {
  $warnHits += 'execution-policy'
  $warnReasons += 'Set-ExecutionPolicy cambia politica de ejecucion'
}

$hasWrite = $false
if ($n -match '\b(Set-Content|Add-Content|Out-File|New-Item|Copy-Item|Move-Item)\b') { $hasWrite = $true }
if ($n -match '>>?') {
  if ($n -match '>') { $hasWrite = $true }
}
$hasAbsPath = $false
if ($n -match '[A-Za-z]:[\\/]') { $hasAbsPath = $true }
if ($n -match '\\\\') { $hasAbsPath = $true }
if ($n -match '/(tmp|etc|usr|var|home|root)\b') { $hasAbsPath = $true }
if ($n -match '~[\\/]') { $hasAbsPath = $true }
if ($n -match '\$env:') { $hasAbsPath = $true }
if ($hasWrite -and $hasAbsPath) {
  $warnHits += 'outside-write'
  $warnReasons += 'escritura a ruta fuera del repo root'
}

# ---------- VERDICT ----------

$verdict = 'PASS'
$reasons = @()
$patterns = @()

if ($failHits.Count -gt 0) {
  $verdict = 'FAIL'
  $reasons = $failReasons
  $patterns = $failHits
  if ($warnHits.Count -gt 0) {
    foreach ($w in $warnHits) { $patterns += $w }
  }
}
elseif ($warnHits.Count -gt 0) {
  $verdict = 'WARN'
  $reasons = $warnReasons
  $patterns = $warnHits
}
else {
  $reasons = @('sin patrones peligrosos')
  $patterns = @()
}

if (($Mode -eq 'strict') -and ($verdict -eq 'WARN')) {
  $verdict = 'FAIL'
  $reasons = @('strict: WARN escala a FAIL') + $reasons
}

Write-Debug ("pre-exec-review mode={0} verdict={1} patterns={2}" -f $Mode, $verdict, ($patterns -join ','))
if ($verdict -eq 'WARN') {
  Write-Warning (($reasons -join '; '))
}

if ($Quiet) {
  Write-Output $verdict
}
elseif ($Json) {
  $obj = [pscustomobject]@{
    verdict  = $verdict
    reasons  = $reasons
    patterns = $patterns
  }
  Write-Output ($obj | ConvertTo-Json -Compress)
}
else {
  $reasonText = $reasons -join '; '
  Write-Output ("VERDICT: {0} — {1}" -f $verdict, $reasonText)
}

if ($verdict -eq 'FAIL') { exit 2 } else { exit 0 }
