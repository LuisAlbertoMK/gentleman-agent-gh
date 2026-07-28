#requires -Version 5.1
Describe "mock" { It "mocks Read-Host" { $null = Mock Read-Host { 'y' } -ParameterFilter { $Prompt -like '*Restore*' } } }
