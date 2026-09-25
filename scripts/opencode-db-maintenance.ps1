#requires -Version 7
<#
.SYNOPSIS
  Higiene de opencode.db: backup verificado + retencion por edad + VACUUM (R11-S5).
.DESCRIPTION
  DRY-RUN por defecto (cero escrituras): reporta sesiones viejas y dependientes.
  Con -Apply exige backup verificado (VACUUM INTO + quick_check) y ABORTA si no
  puede verificarlo. Fail-closed: cualquier fallo no toca nada y sale con error.
  NUNCA contra la DB real sin ventana owner (-AllowProduction + runbook).
.PARAMETER DatabasePath
  DB sqlite a tratar. Default: la DB real (protegida por el guard AllowProduction).
.PARAMETER BackupDir
  Destino del backup. Default: <dbdir>/backups. Solo se crea con -Apply.
.PARAMETER RetentionDays
  Borra sesiones con time_created (ms epoch) mas viejo que hoy-RetentionDays. Default 90.
.PARAMETER Apply
  Sin el switch solo reporta (dry-run). Con el switch: backup + DELETE + VACUUM.
.PARAMETER AllowProduction
  Requerido si DatabasePath resuelve a la DB real de opencode.
.EXAMPLE
  ./scripts/opencode-db-maintenance.ps1 -DatabasePath ./copia.db
.EXAMPLE
  ./scripts/opencode-db-maintenance.ps1 -DatabasePath ./copia.db -Apply -BackupDir ./bk
#>
[CmdletBinding(SupportsShouldProcess)]
param(
    [string]$DatabasePath = (Join-Path $env:USERPROFILE '.local/share/opencode/opencode.db'),
    [string]$BackupDir = '',
    [ValidateRange(1, 3650)][int]$RetentionDays = 90,
    [switch]$Apply,
    [switch]$AllowProduction
)
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

# Dependientes de session (hijos -> padre). Medido read-only R11-S5:
# event/event_sequence via aggregate_id (= session.id, 100% linked); resto via session_id.
$script:ChildTables = @(
    @{ Table = 'event'; Column = 'aggregate_id' },
    @{ Table = 'event_sequence'; Column = 'aggregate_id' },
    @{ Table = 'part'; Column = 'session_id' },
    @{ Table = 'message'; Column = 'session_id' },
    @{ Table = 'todo'; Column = 'session_id' },
    @{ Table = 'session_message'; Column = 'session_id' },
    @{ Table = 'session_input'; Column = 'session_id' },
    @{ Table = 'session_share'; Column = 'session_id' },
    @{ Table = 'session_context_epoch'; Column = 'session_id' }
)

function Get-ProductionDbPath {
    [System.IO.Path]::GetFullPath((Join-Path $env:USERPROFILE '.local/share/opencode/opencode.db'))
}

function Invoke-DbQuery {
    param([string]$Db, [string]$Sql)
    $out = sqlite3 $Db $Sql 2>&1
    if ($LASTEXITCODE -ne 0) { throw "sqlite3 fallo ($LASTEXITCODE): $out" }
    return @($out)
}

function Get-RowsToDelete {
    param([string]$Db, [long]$CutoffMs)
    $rows = @{}
    $where = "time_created < $CutoffMs"
    $rows['session'] = [long]((Invoke-DbQuery $Db "SELECT COUNT(*) FROM session WHERE $where;") | Select-Object -First 1)
    foreach ($dep in $script:ChildTables) {
        $q = "SELECT COUNT(*) FROM $($dep.Table) WHERE $($dep.Column) IN (SELECT id FROM session WHERE $where);"
        $rows[$dep.Table] = [long]((Invoke-DbQuery $Db $q) | Select-Object -First 1)
    }
    return $rows
}

# 1. Guard produccion: corre ANTES de cualquier contacto con sqlite.
$resolvedDb = [System.IO.Path]::GetFullPath($DatabasePath)
if ($resolvedDb -eq (Get-ProductionDbPath) -and -not $AllowProduction) {
    throw "REFUSING: DatabasePath es la DB real de opencode. Solo en ventana owner con -AllowProduction. Ver docs/operations/RUNBOOK.md."
}
if (-not (Test-Path -LiteralPath $resolvedDb -PathType Leaf)) { throw "DB no encontrada: $resolvedDb" }

# 2. Prereq sqlite3 CLI (fail limpio si falta).
$sqliteCmd = Get-Command sqlite3 -CommandType Application -ErrorAction SilentlyContinue | Select-Object -First 1
if (-not $sqliteCmd) {
    throw "PREREQ: sqlite3 CLI no encontrado en PATH. Instalar (winget install SQLite.SQLite) y reintentar. Cero cambios realizados."
}

if ([string]::IsNullOrWhiteSpace($BackupDir)) { $BackupDir = Join-Path ([System.IO.Path]::GetDirectoryName($resolvedDb)) 'backups' }
$cutoffMs = [DateTimeOffset]::UtcNow.AddDays(-$RetentionDays).ToUnixTimeMilliseconds()
$sizeBefore = (Get-Item -LiteralPath $resolvedDb).Length
$walPath = "$resolvedDb-wal"
$walBytes = if (Test-Path -LiteralPath $walPath) { (Get-Item -LiteralPath $walPath).Length } else { 0 }
$rows = Get-RowsToDelete -Db $resolvedDb -CutoffMs $cutoffMs
$totalRows = [long]((Invoke-DbQuery $resolvedDb 'SELECT COUNT(*) FROM session;') | Select-Object -First 1)
$approxReclaim = if ($totalRows -gt 0) { [long]($sizeBefore * ($rows['session'] / $totalRows)) } else { 0 }

$report = [PSCustomObject]@{
    Mode               = 'DryRun'
    DatabasePath       = $resolvedDb
    RetentionDays      = $RetentionDays
    CutoffMs           = $cutoffMs
    RowsToDelete       = $rows
    SizeBeforeBytes    = $sizeBefore
    WalBytes           = $walBytes
    ApproxReclaimBytes = $approxReclaim
    BackupPath         = $null
    SizeAfterBytes     = $null
}

if ($Apply -and $PSCmdlet.ShouldProcess($resolvedDb, "retencion>${RetentionDays}d + VACUUM")) {
    $precheck = (Invoke-DbQuery $resolvedDb 'PRAGMA quick_check;') | Select-Object -First 1
    if ($precheck -ne 'ok') { throw "ABORT: quick_check origen = '$precheck'. Nada modificado." }
    New-Item -ItemType Directory -Path $BackupDir -Force -ErrorAction Stop | Out-Null
    $stamp = Get-Date -Format 'yyyyMMdd-HHmmss'
    $backupPath = Join-Path $BackupDir "opencode-$stamp.db"
    Invoke-DbQuery $resolvedDb ("VACUUM INTO '" + ($backupPath -replace "'", "''") + "';") | Out-Null
    $bk = Get-Item -LiteralPath $backupPath -ErrorAction Stop
    if ($bk.Length -le 0) { throw 'ABORT: backup vacio. Nada modificado.' }
    $bkCheck = (Invoke-DbQuery $backupPath 'PRAGMA quick_check;') | Select-Object -First 1
    if ($bkCheck -ne 'ok') { throw "ABORT: backup no verificado ('$bkCheck'). Nada modificado en el original." }
    Invoke-DbQuery $resolvedDb 'PRAGMA wal_checkpoint(TRUNCATE);' | Out-Null
    $where = "time_created < $cutoffMs"
    foreach ($dep in $script:ChildTables) {
        Invoke-DbQuery $resolvedDb "DELETE FROM $($dep.Table) WHERE $($dep.Column) IN (SELECT id FROM session WHERE $where);" | Out-Null
    }
    Invoke-DbQuery $resolvedDb "DELETE FROM session WHERE $where;" | Out-Null
    Invoke-DbQuery $resolvedDb 'VACUUM;' | Out-Null
    $report.Mode = 'Applied'
    $report.BackupPath = $backupPath
    $report.SizeAfterBytes = (Get-Item -LiteralPath $resolvedDb).Length
}

return $report
