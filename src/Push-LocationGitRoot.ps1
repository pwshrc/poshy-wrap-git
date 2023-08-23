#!/usr/bin/env pwsh
$ErrorActionPreference = "Stop"
Set-StrictMode -Version Latest


function Push-LocationGitRoot() {
    Push-Location (Get-LocationGitRoot) @args | Out-Null
}
