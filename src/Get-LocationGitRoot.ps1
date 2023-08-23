#!/usr/bin/env pwsh
$ErrorActionPreference = "Stop"
Set-StrictMode -Version Latest


function Get-LocationGitRoot {
    [CmdletBinding(DefaultParameterSetName = 'Path')]
    param(
        [Parameter(Mandatory = $false, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true, ParameterSetName = 'Path')]
        [string[]] $Path = @(Get-Location -PSProvider FileSystem).ProviderPath,

        [Parameter(Mandatory = $true, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true, ParameterSetName = 'LiteralPath')]
        [string[]] $LiteralPath,

        [Parameter(Mandatory = $true, ValueFromPipeline = $true, ParameterSetName = 'InputObject')]
        [System.IO.FileSystemInfo[]] $InputObject,

        [Parameter(Mandatory = $false)]
        [switch] $Force
    )
    if ($Path) {
        $InputObject = $Path | ForEach-Object { Get-Item -Path $_ -Force:$Force }
    } elseif ($LiteralPath) {
        $InputObject = $LiteralPath | ForEach-Object { Get-Item -LiteralPath $_ -Force:$Force }
    }
    foreach ($item in $InputObject) {
        if ($item -is [System.IO.FileInfo]) {
            $item = $item.Directory
        }
        Push-Location -LiteralPath $item | Out-Null
        try {
            Get-Item (git root)
            if ($LASTEXITCODE -ne 0) {
                Write-Error "Operation ``git root`` failed with exit code '$LASTEXITCODE' at path '$item'."
            }
        } finally {
            Pop-Location
        }
    }
}
