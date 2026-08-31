Describe "test-compaction-ab" {
  It "exists" { Test-Path "$PSScriptRoot/../test-compaction-ab.ps1" | Should -Be $true }
  It "parses" { $e=$null; [System.Management.Automation.Language.Parser]::ParseFile("$PSScriptRoot/../test-compaction-ab.ps1",[ref]$null,[ref]$e) | Out-Null; $e.Count | Should -Be 0 }
}
