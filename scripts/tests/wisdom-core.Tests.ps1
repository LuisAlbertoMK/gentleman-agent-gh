Describe "wisdom-core" {
  It "exists" { Test-Path "$PSScriptRoot/../wisdom-core.ps1" | Should -Be $true }
  It "parses" { $e=$null; [System.Management.Automation.Language.Parser]::ParseFile("$PSScriptRoot/../wisdom-core.ps1",[ref]$null,[ref]$e) | Out-Null; $e.Count | Should -Be 0 }
}