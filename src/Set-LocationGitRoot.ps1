#!/usr/bin/env pwsh
$ErrorActionPreference = "Stop"
Set-StrictMode -Version Latest


# cd to git root directory.
function Set-LocationGitRoot {
    param(
        [Parameter(Mandatory=$false, Position=0, HelpMessage="Returns a PathInfo object that represents the location. By default, this cmdlet does not generate any output.")]
        [switch] $PassThru
    )
    Set-Location @PSBoundParameters -LiteralPath (Get-LocationGitRoot)
}
