Describe "bench-q4" {
  It "exists" { Test-Path "$PSScriptRoot/../bench-q4.ps1" | Should -Be $true }
  It "parses" { $e=$null; [System.Management.Automation.Language.Parser]::ParseFile("$PSScriptRoot/../bench-q4.ps1",[ref]$null,[ref]$e) | Out-Null; $e.Count | Should -Be 0 }
}
