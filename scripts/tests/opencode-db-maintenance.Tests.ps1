#requires -Version 7
# R11-S5: test del script de higiene en DB COPIA temporal. NUNCA la DB real.
# Convencion: los tests de scripts/*.ps1 viven en scripts/tests/ (ej. restore.Tests.ps1).
# Requiere python (stdlib sqlite3) para armar el fixture y el shim sqlite3 CLI.
BeforeAll {
    $script:Sut = Join-Path $PSScriptRoot '..' 'opencode-db-maintenance.ps1'
    $script:Temp = Join-Path ([System.IO.Path]::GetTempPath()) "pester-dbhyg-$(Get-Random)"
    New-Item -ItemType Directory -Path $script:Temp -Force | Out-Null
    $script:OldPath = $env:PATH
    $nowMs = [DateTimeOffset]::UtcNow.ToUnixTimeMilliseconds()
    $script:OldMs = $nowMs - (200 * 86400 * 1000)
    $script:NewMs = $nowMs - (5 * 86400 * 1000)
    $builder = Join-Path $script:Temp 'fixture.py'
    @'
import sqlite3, sys
db, old, new = sys.argv[1], int(sys.argv[2]), int(sys.argv[3])
con = sqlite3.connect(db, isolation_level=None)
c = con.cursor()
c.execute("CREATE TABLE session (id TEXT PRIMARY KEY, project_id TEXT NOT NULL, time_created INTEGER NOT NULL, time_updated INTEGER NOT NULL)")
c.execute("CREATE TABLE message (id TEXT PRIMARY KEY, session_id TEXT NOT NULL, time_created INTEGER NOT NULL, time_updated INTEGER NOT NULL, data TEXT NOT NULL)")
c.execute("CREATE TABLE part (id TEXT PRIMARY KEY, message_id TEXT NOT NULL, session_id TEXT NOT NULL, time_created INTEGER NOT NULL, time_updated INTEGER NOT NULL, data TEXT NOT NULL)")
c.execute("CREATE TABLE event (id TEXT PRIMARY KEY, aggregate_id TEXT NOT NULL, seq INTEGER NOT NULL, type TEXT NOT NULL, data TEXT NOT NULL)")
c.execute("CREATE TABLE event_sequence (aggregate_id TEXT PRIMARY KEY, seq INTEGER NOT NULL, owner_id TEXT)")
c.execute("CREATE TABLE todo (session_id TEXT NOT NULL, content TEXT NOT NULL, status TEXT NOT NULL, priority TEXT NOT NULL, position INTEGER NOT NULL, time_created INTEGER NOT NULL, time_updated INTEGER NOT NULL)")
c.execute("CREATE TABLE session_message (id TEXT PRIMARY KEY, session_id TEXT NOT NULL, type TEXT NOT NULL, seq INTEGER NOT NULL, time_created INTEGER NOT NULL, time_updated INTEGER NOT NULL, data TEXT NOT NULL)")
c.execute("CREATE TABLE session_input (id TEXT PRIMARY KEY, session_id TEXT NOT NULL, prompt TEXT NOT NULL, delivery TEXT NOT NULL, admitted_seq INTEGER NOT NULL, promoted_seq INTEGER, time_created INTEGER NOT NULL)")
c.execute("CREATE TABLE session_share (session_id TEXT PRIMARY KEY, id TEXT NOT NULL, secret TEXT NOT NULL, url TEXT NOT NULL, time_created INTEGER NOT NULL, time_updated INTEGER NOT NULL)")
c.execute("CREATE TABLE session_context_epoch (session_id TEXT PRIMARY KEY, baseline TEXT NOT NULL, snapshot TEXT NOT NULL, baseline_seq INTEGER NOT NULL)")
for tag, ts in (("old", old), ("new", new)):
    c.execute("INSERT INTO session VALUES (?,?,?,?)", ("s-" + tag, "p1", ts, ts))
    c.execute("INSERT INTO message VALUES (?,?,?,?,?)", ("m-" + tag, "s-" + tag, ts, ts, "{}"))
    c.execute("INSERT INTO part VALUES (?,?,?,?,?,?)", ("pt-" + tag, "m-" + tag, "s-" + tag, ts, ts, "{}"))
    c.execute("INSERT INTO event VALUES (?,?,?,?,?)", ("e-" + tag, "s-" + tag, 1, "session.created.1", "{}"))
    c.execute("INSERT INTO event_sequence VALUES (?,?,?)", ("s-" + tag, 1, None))
    c.execute("INSERT INTO todo VALUES (?,?,?,?,?,?,?)", ("s-" + tag, "t", "pending", "high", 0, ts, ts))
con.close()
'@ | Set-Content -LiteralPath $builder -Encoding UTF8
    $script:Fixture = Join-Path $script:Temp 'fixture.db'
    & python $builder $script:Fixture $script:OldMs $script:NewMs
    if ($LASTEXITCODE -ne 0) { throw 'no se pudo crear el fixture (python+sqlite3 requerido)' }
    $script:FixtureHash = (Get-FileHash -LiteralPath $script:Fixture -Algorithm SHA256).Hash
    $shim = Join-Path $script:Temp 'shim.py'
    @'
import sqlite3, sys
db, sql = sys.argv[1], " ".join(sys.argv[2:])
con = sqlite3.connect(db, isolation_level=None)
con.execute("PRAGMA busy_timeout=5000")
cur = con.cursor()
try:
    cur.execute(sql)
    rows = cur.fetchall() if cur.description else []
    for r in rows:
        print("|".join("" if v is None else str(v) for v in r))
except Exception as e:
    print("Error: %s" % e, file=sys.stderr)
    sys.exit(1)
con.commit()
con.close()
'@ | Set-Content -LiteralPath $shim -Encoding UTF8
    "@echo off`r`npython `"%~dp0shim.py`" %*" | Set-Content -LiteralPath (Join-Path $script:Temp 'sqlite3.cmd') -Encoding Ascii
    $env:PATH = "$($script:Temp)$([System.IO.Path]::PathSeparator)$env:PATH"
    function script:New-CopyDb {
        $copy = Join-Path $script:Temp ("copy-$(Get-Random).db")
        Copy-Item -LiteralPath $script:Fixture -Destination $copy
        return $copy
    }
}

AfterAll {
    $env:PATH = $script:OldPath
    if (Test-Path -LiteralPath $script:Temp) { Remove-Item -LiteralPath $script:Temp -Recurse -Force -ErrorAction SilentlyContinue }
}

Describe 'opencode-db-maintenance.ps1 (R11-S5, solo copias)' {
    It 'falla limpio si falta sqlite3 y no escribe nada' {
        $copy = New-CopyDb
        $h0 = (Get-FileHash -LiteralPath $copy -Algorithm SHA256).Hash
        $env:PATH = 'C:\Windows\System32'
        try {
            { & $Sut -DatabasePath $copy } | Should -Throw '*sqlite3*'
        } finally { $env:PATH = "$($script:Temp)$([System.IO.Path]::PathSeparator)$($script:OldPath)" }
        (Get-FileHash -LiteralPath $copy -Algorithm SHA256).Hash | Should -Be $h0
    }

    It 'dry-run (default) reporta sin escribir' {
        $copy = New-CopyDb
        $h0 = (Get-FileHash -LiteralPath $copy -Algorithm SHA256).Hash
        $r = & $Sut -DatabasePath $copy -RetentionDays 90
        $r.Mode | Should -Be 'DryRun'
        $r.RowsToDelete['session'] | Should -Be 1
        $r.RowsToDelete['message'] | Should -Be 1
        $r.RowsToDelete['part'] | Should -Be 1
        $r.RowsToDelete['event'] | Should -Be 1
        $r.SizeAfterBytes | Should -BeNullOrEmpty
        (Get-FileHash -LiteralPath $copy -Algorithm SHA256).Hash | Should -Be $h0
    }

    It '-Apply aborta si el backup es imposible y no toca nada' {
        $copy = New-CopyDb
        $blocker = Join-Path $script:Temp 'blocker'
        'x' | Set-Content -LiteralPath $blocker
        $h0 = (Get-FileHash -LiteralPath $copy -Algorithm SHA256).Hash
        { & $Sut -DatabasePath $copy -RetentionDays 90 -Apply -BackupDir $blocker } | Should -Throw
        (Get-FileHash -LiteralPath $copy -Algorithm SHA256).Hash | Should -Be $h0
    }

    It '-Apply borra solo lo viejo con backup verificado' {
        $copy = New-CopyDb
        $bkdir = Join-Path $script:Temp 'bk'
        $r = & $Sut -DatabasePath $copy -RetentionDays 90 -Apply -BackupDir $bkdir
        $r.Mode | Should -Be 'Applied'
        $r.BackupPath | Should -Exist
        $ids = & python $script:Temp/shim.py $copy 'SELECT id FROM session;'
        $ids | Should -Be 's-new'
        $ev = & python $script:Temp/shim.py $copy 'SELECT COUNT(*) FROM event;'
        $ev | Should -Be '1'
        $r.SizeAfterBytes | Should -BeLessOrEqual $r.SizeBeforeBytes
    }

    It 'rehusa la DB real sin -AllowProduction (cero contacto)' {
        $prod = Join-Path $env:USERPROFILE '.local/share/opencode/opencode.db'
        { & $Sut -DatabasePath $prod } | Should -Throw '*AllowProduction*'
    }

    It 'el fixture origen nunca se modifica' {
        (Get-FileHash -LiteralPath $script:Fixture -Algorithm SHA256).Hash | Should -Be $script:FixtureHash
    }
}
