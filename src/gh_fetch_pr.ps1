#!/usr/bin/env pwsh
$ErrorActionPreference = "Stop"
Set-StrictMode -Version Latest


# Fetch pull request
function gh_fetch_pr {
    param(
        [Parameter(Mandatory = $true, Position = 0, ParameterSetName = "RepoParam_UserParam_BranchParam")]
        [string] $Repo = $null,

        [Parameter(Mandatory = $true, Position = 1, ParameterSetName = "RepoParam_UserParam_BranchParam")]
        [Parameter(Mandatory = $true, Position = 0, ParameterSetName = "GuessRepo_UserParam_BranchParam")]
        [string] $User = $null,

        [Parameter(Mandatory = $true, Position = 2, ParameterSetName = "RepoParam_UserParam_BranchParam")]
        [Parameter(Mandatory = $true, Position = 1, ParameterSetName = "GuessRepo_UserParam_BranchParam")]
        [string] $Branch = $null,

        [Parameter(Mandatory = $true, Position = 0, ParameterSetName = "GuessRepo_BranchUserParam")]
        [string] $BranchUser = $null
    )

    git rev-parse --git-dir | Out-Null
    if ($?) {
        throw "gh_fetch_pr must be executed from within a git repository."
    }

    Set-LocationGitRoot

    if (-not $Repo) {
        $Repo = (Get-Location).Name
    }
    if ($BranchUser) {
        if (-not $Branch) {
            $Branch = ($BranchUser -split ":") | Select-Object -First 1
        }
        if (-not $User) {
            $User = ($BranchUser -split ":") | Select-Object -Last 1
        }
    }

    git fetch "git@github.com:${User}/${Repo}" "${Branch}:${User}/${Branch}"
}
