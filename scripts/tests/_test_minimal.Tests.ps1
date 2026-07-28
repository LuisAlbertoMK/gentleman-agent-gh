#requires -Version 5.1
BeforeAll { }
Describe "minimal" { It "works" { & ".\scripts\restore.ps1" -Revision "HEAD~1" } }
