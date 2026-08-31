Describe "wisdom-maintenance" {
  It "exists" { Test-Path "$PSScriptRoot/../wisdom-maintenance.ps1" | Should -Be $true }
  It "parses" { $e=$null; [System.Management.Automation.Language.Parser]::ParseFile("$PSScriptRoot/../wisdom-maintenance.ps1",[ref]$null,[ref]$e) | Out-Null; $e.Count | Should -Be 0 }
}
