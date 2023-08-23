#!/usr/bin/env pwsh
$ErrorActionPreference = "Stop"
Set-StrictMode -Version Latest


function Format-GitRepository {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$false)]
        [string] $LiteralPath
    )
    Begin {
        if ([string]::IsNullOrWhiteSpace($LiteralPath)) {
            $LiteralPath = $PWD.Path
        }
    }
    Process {
        Push-Location -LiteralPath $LiteralPath | Out-Null
        try {
            [bool] $likelyHasInitialCommit = $false
            if (-not (Get-ChildItem -Filter .git -Hidden)) {
                git init --quiet
                if ($LASTEXITCODE -ne 0) {
                    throw "Failure to 'git init', exited with $LASTEXITCODE."
                }
                $likelyHasInitialCommit = $false
            } else {
                git log 2>&1 | Out-Null
                $likelyHasInitialCommit = $?
            }

            [string] $porcelainGitStatus = git status --porcelain
            if (-not [string]::IsNullOrWhiteSpace($porcelainGitStatus)) {
                git reset
            }

            if (-not $likelyHasInitialCommit) {
                [string] $epoch = "01 Jan 1970 00:00:00 +0000"
                $Env:GIT_AUTHOR_DATE = $epoch
                $Env:GIT_COMMITTER_DATE = $epoch
                git commit --message="🎉 Initial Commit" --allow-empty --no-edit --quiet 2>&1 | Out-Null
                if ($LASTEXITCODE -ne 0) {
                    throw "Failure to 'git commit --message=`"🎉 Initial Commit`" --allow-empty', exited with $LASTEXITCODE."
                }
            }
        } finally {
            Pop-Location | Out-Null
            Remove-Item Env:\GIT_AUTHOR_DATE -Force
            Remove-Item Env:\GIT_COMMITTER_DATE -Force
        }
    }
}
