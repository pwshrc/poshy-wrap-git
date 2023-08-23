#!/usr/bin/env pwsh
$ErrorActionPreference = "Stop"
Set-StrictMode -Version Latest


# Adapted from: https://stackoverflow.com/a/44036771/12553250
function Split-GitHistory {
    [CmdletBinding()]
    param(
        [Parameter(Position = 0, Mandatory = $true)]
        [ValidateScript({Test-Path $_ })]
        [string] $source,

        [Parameter(Position = 1, Mandatory = $true)]
        [string[]] $destination
    )

    Begin {
        $ErrorActionPreference = "Stop"
    }

    Process {
        [string] $currentOperation

        [string[]] $commitsToMerge = @()
        [int] $opNumberMax = 3 + $destination.Length

        [int] $opNumber = 1
        $currentOperation = "♻🖇 Git History Split ($opNumber/$opNumberMax): 📎 Sidelines Original File"
        Write-Progress -Activity "Splitting Git History of File" -CurrentOperation $currentOperation
        [string] $sourceCopy = $source + "-" + $(git rev-parse HEAD)
        git mv $source $sourceCopy
        git commit -m $currentOperation
        $commitsToMerge += $(git rev-parse HEAD)
        git reset --hard HEAD^

        [int] $destinationNumber = 1
        foreach ($singleDestination in $destination) {
            $opNumber += 1
            $currentOperation = "♻🖇 Git History Split ($opNumber/$opNumberMax): 🔤 Renames Original File to Destination $destinationNumber of $($destination.Length)"
            Write-Progress -Activity "Splitting Git History of File" -CurrentOperation $currentOperation
            git mv $source $destination
            git commit -m $currentOperation
            $commitsToMerge += $(git rev-parse HEAD)
            git reset --hard HEAD^
            $destinationNumber += 1
        }

        $opNumber += 1
        $currentOperation = "♻🖇 Git History Split ($opNumber/$opNumberMax): 🔀 Merges Divergent Commits"
        Write-Progress -Activity "Splitting Git History of File" -CurrentOperation $currentOperation
        [string] $mergeStartCommit = $commitsToMerge | select -first 1
        [string[]] $remainingCommitsToMerge = $commitsToMerge | select -skip 1
        git reset --hard $mergeStartCommit
        git merge @remainingCommitsToMerge # This will generate conflicts
        git commit -a -m $currentOperation # Trivially resolve conflicts like this

        $opNumber += 1
        $currentOperation = "♻🖇 Git History Split ($opNumber/$opNumberMax): ◀ Restores Original File"
        Write-Progress -Activity "Splitting Git History of File" -CurrentOperation $currentOperation
        git mv $sourceCopy $source
        git commit -m $currentOperation

        Write-Progress -Activity "Splitting Git History of File" -Completed
    }
}
