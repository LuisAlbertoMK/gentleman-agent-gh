Describe "benchmark-core" {
  It "exists" { Test-Path "$PSScriptRoot/../benchmark-core.ps1" | Should -Be $true }
  It "parses" { $e=$null; [System.Management.Automation.Language.Parser]::ParseFile("$PSScriptRoot/../benchmark-core.ps1",[ref]$null,[ref]$e) | Out-Null; $e.Count | Should -Be 0 }
}
