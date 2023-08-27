#!/usr/bin/env pwsh
$ErrorActionPreference = "Stop"
Set-StrictMode -Version Latest


if (-not (Test-Command git) -and (-not (Get-Variable -Name PWSHRC_FORCE_MODULES_EXPORT_UNSUPPORTED -Scope Global -ValueOnly -ErrorAction SilentlyContinue))) {
    return
}

[string] $git_bin = $null
if (Test-Command hub) {
    $git_bin = "hub"

    function Invoke-Hub {
        hub @args
    }
    Set-Alias -Name git -Value hub
} elseif (Test-Command git) {
    $git_bin = "git"
}

<#
.SYNOPSIS
    Adds remote ${Env:GIT_HOSTING}:$repo to current repo.
.PARAMETER repo
    The name of the repo to add.
.COMPONENT
    Git
#>
function git_remote {
    param(
        [Parameter(Mandatory = $true, Position = 0)]
        [string] $repo
    )

    if (-not $Env:GIT_HOSTING) {
        throw "Please set the environment variable GIT_HOSTING to the hostname of your git hosting provider."
    }

	Write-Output "Running: git remote add origin ${Env:GIT_HOSTING}:$repo.git"
	& $git_bin remote add origin "${GIT_HOSTING}:${1}".git
}

<#
.SYNOPSIS
    Push into origin refs/heads/master.
.COMPONENT
    Git
#>
function git_first_push {
	Write-Output "Running: git push origin master:refs/heads/master"
	& $git_bin push origin master:refs/heads/master
}

<#
.SYNOPSIS
    Publishes current branch to remote origin.
.COMPONENT
    Git
#>
function git_pub() {
	$BRANCH=(git rev-parse --abbrev-ref HEAD)

	Write-Output "Publishing ${BRANCH} to remote origin"
	& $git_bin push -u origin "${BRANCH}"
}

<#
.SYNOPSIS
    Applies changes to HEAD that revert all changes after this commit.
.PARAMETER target
    The commit to revert to.
.COMPONENT
    Git
#>
function git_revert() {
    param(
        [Parameter(Mandatory = $true, Position = 0)]
        [string] $target
    )
	& $git_bin reset $target
	& $git_bin reset --soft "HEAD@{1}"
	& $git_bin commit -m "Revert to $target"
	& $git_bin reset --hard
}

<#
.SYNOPSIS
    Resets the current HEAD to this commit.
.PARAMETER target
    The commit to reset to.
.COMPONENT
    Git
#>
function git_rollback {
    param(
        [Parameter(Mandatory = $true, Position = 0)]
        [string] $target
    )

	function is_clean {
		if ((git diff --shortstat 2> $null | Select-Object -Last 1)) {
			throw "Your branch is dirty, please commit your changes"
        }
    }

	function commit_exists {
        param(
            [Parameter(Mandatory = $true, Position = 0)]
            [string] $target
        )
		if (git rev-list --quiet $target) {
			throw "Commit $target does not exist"
        }
	}

	function keep_changes {
        param(
            [Parameter(Mandatory = $true, Position = 0)]
            [string] $target
        )

        $userAccepts = $PSCmdlet.ShouldContinue("Do you want to keep all changes from rolled back revisions in your working tree?")
        if ($userAccepts) {
            Write-Output "Rolling back to commit $target with unstaged changes."
            & $git_bin reset $target
        } else {
            Write-Output "Rolling back to commit $target with a clean working tree."
            & $git_bin reset --hard $target
        }
    }

	if ((git symbolic-ref HEAD 2> $null)) {
		is_clean
		commit_exists $target

        $userAccepts = $PSCmdlet.ShouldContinue("WARNING: This will change your history and move the current HEAD back to commit $target, continue?")
        if ($userAccepts) {
            keep_changes $target
        }
    } else {
		Write-Error "you're currently not in a git repository"
	}
}

<#
.SYNOPSIS
    & $git_bin rm's missing files.
.COMPONENT
    Git
#>
function git_remove_missing_files() {
    [string[]] $files = (git ls-files -d)
	& $git_bin update-index --remove @files
}

<#
.SYNOPSIS
    Adds files to git's exclude file (same as .gitignore).
.PARAMETER file
    The file to add to the exclude file.
.COMPONENT
    Git
#>
function local-ignore() {
    param(
        [Parameter(Mandatory = $true, Position = 0)]
        [string] $file
    )
    $file | Out-File -Append .git/info/exclude
}

<#
.SYNOPSIS
    Get a quick overview for your git repo.
.COMPONENT
    Git
#>
function git_info() {


	if ((git symbolic-ref HEAD 2> $null)) {
		# print informations
		Write-Output "git repo overview"
		Write-Output "-----------------"
		Write-Output

		# print all remotes and thier details
		foreach ($remote in (git remote show)) {
            Write-Output "${remote}":
			& $git_bin remote show "${remote}"
			Write-Output
        }

		# print status of working repo
		Write-Output "status:"
		if ((git status -s 2> $null)) {
			& $git_bin status -s
        } else {
            Write-Output "working directory is clean"
        }

		# print at least 5 last log entries
		Write-Output
		Write-Output "log:"
		& $git_bin log -5 --oneline
		Write-Output
    } else {
		throw "you're currently not in a git repository"
    }
}

<#
.SYNOPSIS
    Display stats per author.
.COMPONENT
    Git
#>
function git_stats {
    param(
        [Parameter(Mandatory = $false, Position = 0)]
        [switch] $w,

        [Parameter(Mandatory = $false, Position = 1)]
        [switch] $M,

        [Parameter(Mandatory = $false, Position = 2)]
        [switch] $C,

        [Parameter(Mandatory = $false, Position = 3, ValueFromRemainingArguments = $true)]
        [string[]] $rest
    )

	# awesome work from https://github.com/esc/git-stats
	# including some modifications

    [string] $currentBranchName = (git symbolic-ref HEAD 2> $null)
	if ($currentBranchName) {
        Write-Output "Number of commits per author:"
		& $git_bin --no-pager shortlog -sn --all
		$AUTHORS=(git shortlog -sn --all | ConvertFrom-Csv -Delimiter "`t" -Header CommitsCount, Author | Select-Object -ExpandProperty Author)
		$LOGOPTS=""

        if ($w) {
            $LOGOPTS="${LOGOPTS} -w"
        }
        if ($M) {
            $LOGOPTS="${LOGOPTS} -M"
        }
        if ($C) {
            $LOGOPTS="${LOGOPTS} -C --find-copies-harder"
        }
		foreach ($a in $AUTHORS) {
			Write-Output '-------------------'
			Write-Output "Statistics for: ${a}"

            [PSObject[]] $authorChangesPerFile = (
                & $git_bin log ${LOGOPTS} --all --numstat --format="%n" --author="${a}" `
                | Select-Object -Unique `
                | ConvertFrom-Csv -Delimiter "`t" -Header LinesAdded, LinesDeleted, File
            )

            [int] $filesChangedCount = $authorChangesPerFile.Count
            [int] $linesAddedCount = $authorChangesPerFile | Measure-Object -Property LinesAdded -Sum | Select-Object -ExpandProperty Sum
            [int] $linesDeletedCount = $authorChangesPerFile | Measure-Object -Property LinesDeleted -Sum | Select-Object -ExpandProperty Sum
            [int] $mergeCommitsCount = (
                & $git_bin log --all --merges --author="Bruce Markham" | Where-Object { $_.StartsWith("commit") }
            ).Count

            Write-Output "Number of files changed: $filesChangedCount"
			Write-Output "Number of lines added: $linesAddedCount"
			Write-Output "Number of lines deleted: $linesDeletedCount"
			Write-Output "Number of merges: " $mergeCommitsCount
        }
	} else {
		Write-Error "you're currently not in a git repository"
	}
}
<#
.SYNOPSIS
    Places the latest .gitignore file for a given project type in the current directory, or concatenates onto an existing .gitignore.
.PARAMETER type
    The language/type of the project, used for determining the contents of the .gitignore file.
.EXAMPLE
    gittowork java
.COMPONENT
    Git
#>
function gittowork() {
    param(
        [Parameter(Mandatory = $true, Position = 0)]
        [string] $type
    )

	$result=(Invoke-RestMethod "https://www.gitignore.io/api/$type")

	if (-not $result) {
		Write-Output "Query '$type' has no match. See a list of possible queries with 'gittowork list'"
    } elif ($type -eq "list") {
		Write-Output "${result}"
    } else {
		if (Test-Path .gitignore -ErrorAction SilentlyContinue) {
			Write-Output ".gitignore already exists, appending..."
        }
		$result | Out-File -Append .gitignore
	}
}

<#
.SYNOPSIS
    Empties the git cache, and readds all files not blacklisted by .gitignore.
.COMPONENT
    Git
#>
function gitignore-reload() {
	# The .gitignore file should not be reloaded if there are uncommited changes.
	# Firstly, require a clean work tree. The function require_clean_work_tree()
	# was stolen with love from https://www.spinics.net/lists/git/msg142043.html

	# Begin require_clean_work_tree()

	# Update the index
	& $git_bin update-index -q --ignore-submodules --refresh
	$err=0

	# Disallow unstaged changes in the working tree
    & $git_bin diff-files --quiet --ignore-submodules --
	if ($LASTEXITCODE -ne 0) {
		Write-Error "Cannot reload .gitignore: Your index contains unstaged changes."
		& $git_bin diff-index --cached --name-status -r --ignore-submodules HEAD -- | Write-Error
		err=1
    }

	# Disallow uncommited changes in the index
    & $git_bin diff-index --cached --quiet HEAD --ignore-submodules
	if ($LASTEXITCODE -ne 0) {
		Write-Eror "Cannot reload .gitignore: Your index contains uncommited changes."
		& $git_bin diff-index --cached --name-status -r --ignore-submodules HEAD -- | Write-Error
		err=1
    }

	# Prompt user to commit or stash changes and exit
	if ($err -ne 0) {
		Write-Error "Please commit or stash them."
    }

	# End require_clean_work_tree()

	# If we're here, then there are no uncommited or unstaged changes dangling around.
	# Proceed to reload .gitignore
	if ($err -eq 0) {
		# Remove all cached files
		& $git_bin rm -r --cached .

		# Re-add everything. The changed .gitignore will be picked up here and will exclude the files
		# now blacklisted by .gitignore
		Write-Warning "Running git add ."
		& $git_bin add .
		Write-Warning "Files readded. Commit your new changes now."
    }
}

<#
.SYNOPSIS
    Creates the git changelog from one point to another by date.
.PARAMETER commit_range
    The range of commits to include in the changelog.
.PARAMETER format
    The format of the changelog. Can be either 'md' or 'txt'.
.EXAMPLE
    git-changelog origin/master...origin/release md
.COMPONENT
    Git
#>
function git-changelog() {
    param(
        [Parameter(Mandatory = $true, Position = 0)]
        [string] $commit_range,

        [Parameter(Mandatory = $false, Position = 1)]
        [ValidateSet("md", "txt")]
        [string] $format = "md"
    )

	# ---------------------------------------------------------------
	#  ORIGINAL ANSWER: https://stackoverflow.com/a/2979587/10362396 |
	# ---------------------------------------------------------------

    if(-not ($commit_range -like "*...*")) {
        throw "Please include the valid 'diff' to make changelog"
    }

	$NEXT=[DateTime]::Now.ToString("yyyy-MM-dd")

	if ($format -eq "md") {
		Write-Output "# CHANGELOG $commit_range"

		[string[]] $dates = (git log "$commit_range" --no-merges --format="%cd" --date=short | Sort-Object -Descending -Unique)
        foreach ($DATE in $dates) {
            Write-Output
			Write-Output "### ${DATE}"
			& $git_bin log --no-merges --format=" * (%h) %s by [%an](mailto:%ae)" --since="${DATE} 00:00:00" --until="${NEXT} 24:00:00"
			$NEXT=$DATE
		}
    } else {
		Write-Output "CHANGELOG $commit_range"
		Write-Output ----------------------


        [string[]] $dates = (git log "$commit_range" --no-merges --format="%cd" --date=short | Sort-Object -Descending -Unique)
        foreach ($DATE in $dates) {
			Write-Output
			Write-Output "[${DATE}]"
			& $git_bin log --no-merges --format=" * (%h) %s by %an <%ae>" --since="${DATE} 00:00:00" --until="${NEXT} 24:00:00"
			$NEXT=$DATE
        }
    }
}

function Invoke-Git {
    & $git_bin @args
}
Set-Alias -Name g -Value Invoke-Git
Set-Alias -Name get -Value Invoke-Git

Set-Alias -Name gall -Value Add-GitTrackedFilesAll

function Add-GitTrackedFilesVerbosely {
    & $git_bin add -v @args
}
Set-Alias -Name gav -Value Add-GitTrackedFilesVerbosely

function Invoke-GitBranch {
    & $git_bin branch @args
}
Set-Alias -Name gb -Value Invoke-GitBranch

Set-Alias -Name gbD -Value Remove-GitBranchForcefully

Set-Alias -Name gbl -Value Get-GitBranchList

function Get-GitBranchListAll {
    & $git_bin branch --list --all @args
}
Set-Alias -Name gbla -Value Get-GitBranchListAll

function Get-GitBranchListRemotes {
    & $git_bin branch --list --remotes @args
}
Set-Alias -Name gblr -Value Get-GitBranchListRemotes

function Rename-GitBranch {
    & $git_bin branch --move @args
}
Set-Alias -Name gbm -Value Rename-GitBranch

function Get-GitBranchRemotes {
    & $git_bin branch --remotes @args
}
Set-Alias -Name gbr -Value Get-GitBranchRemotes

function New-GitBranchTracked {
    & $git_bin branch --track @args
}
Set-Alias -Name gbt -Value New-GitBranchTracked

Set-Alias -Name gdel -Value Remove-GitBranchForcefully

# for-each-ref
function Get-GitRemoteBranchesAuthors {
    & $git_bin for-each-ref --format="%(authorname) %09 %(if)%(HEAD)%(then)*%(else)%(refname:short)%(end) %09 %(creatordate)" refs/remotes/ --sort=authorname DESC @args # FROM https://stackoverflow.com/a/58623139/1036239
}
Set-Alias -Name gbc -Value Get-GitRemoteBranchesAuthors

function Update-GitCommitFilesVerboselyAll {
    & $git_bin commit -v -a @args
}
Set-Alias -Name gca -Value Update-GitCommitFilesVerboselyAll

function Update-GitCommitByHead {
    & $git_bin commit -a --amend -C HEAD @args # Add uncommitted and unstaged changes to the last commit
}
Set-Alias -Name gcaa -Value Update-GitCommitByHead

function Update-GitCommit {
    & $git_bin commit --amend @args
}
Set-Alias -Name gcamd -Value Update-GitCommit

function Write-GitCommitInteractively {
    & $git_bin commit --interactive @args
}
Set-Alias -Name gci -Force -Value Write-GitCommitInteractively

function Write-GitCommitGpgSignedByKey {
    param(
        [Parameter(Mandatory = $true, Position = 0)]
        [string] $Message,

        [Parameter(Mandatory = $true, Position = 1)]
        [string] $KeyId,

        [Parameter(Mandatory = $false, Position = 2, ValueFromRemainingArguments = $true)]
        [string[]] $rest
    )
    & $git_bin commit -S -am $Message $KeyId @rest
}
Set-Alias -Name gcsam -Value Write-GitCommitGpgSignedByKey

function Use-GitBranchTracked {
    & $git_bin checkout --track @args
}
Set-Alias -Name gct -Value Use-GitBranchTracked

# clone
function Invoke-GitClone {
    & $git_bin clone @args
}
Set-Alias -Name gcl -Value Invoke-GitClone

# clean

function Remove-GitUntrackedFiles {
    & $git_bin clean -fd @args
}
Set-Alias -Name gclean -Value Remove-GitUntrackedFiles

# cherry-pick

function Start-GitCherryPickExplained {
    & $git_bin cherry-pick -x @args
}
Set-Alias -Name gcpx -Value Start-GitCherryPickExplained

function Invoke-GitDifftool {
    & $git_bin difftool @args
}
Set-Alias -Name gdt -Value Invoke-GitDifftool

# archive
function Export-GitRepositoryZip {
    & $git_bin archive --format zip --output @args
}
Set-Alias -Name gexport -Value Export-GitRepositoryZip

# fetch
function Update-GitRemoteChanges {
    & $git_bin fetch --all --prune @args
}
Set-Alias -Name gfa -Value Update-GitRemoteChanges

function Update-GitRemoteChangesTags {
    & $git_bin fetch --all --prune --tags @args
}
Set-Alias -Name gft -Value Update-GitRemoteChangesTags

function Update-GitRemoteChangesTagsVerbose {
    & $git_bin fetch --all --prune --tags --verbose @args
}
Set-Alias -Name gftv -Value Update-GitRemoteChangesTagsVerbose

function Update-GitRemoteChangesVerbose {
    & $git_bin fetch --all --prune --verbose @args
}
Set-Alias -Name gfv -Value Update-GitRemoteChangesVerbose

function Merge-GitRepositoryFromUpstreamBranchMain {
    & $git_bin fetch origin -v
    if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
    & $git_bin fetch upstream -v
    if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
    & $git_bin merge upstream/$(Get-GitBranchDefault) @args
}
Set-Alias -Name gmu -Value Merge-GitRepositoryFromUpstreamBranchMain

function Update-GitBranchBaseFromRemote {
    & $git_bin fetch
    if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
    & $git_bin rebase @args
}
Set-Alias -Name gup -Value Update-GitBranchBaseFromRemote

# log
function Get-GitLogGraphStylized {
    & $git_bin log --graph --pretty=format:'\''%C(bold)%h%Creset%C(magenta)%d%Creset %s %C(yellow)<%an> %C(cyan)(%cr)%Creset'\'' --abbrev-commit --date=relative @args
}
Set-Alias -Name gg -Value Get-GitLogGraphStylized

function Get-GitLogGraphStylizedDated {
    & $git_bin log --graph --date=short --pretty=format:'\''%C(auto)%h %Cgreen%an%Creset %Cblue%cd%Creset %C(auto)%d %s'\'' @args
}
Set-Alias -Name ggf -Value Get-GitLogGraphStylizedDated

function Get-GitLogGraphStylizedStat {
    Get-GitLogGraphStylized --stat @args
}
Set-Alias -Name ggs -Value Get-GitLogGraphStylizedStat

function Get-GitLogBranchCommitsUnpushed {
    & $git_bin log --branches --not --remotes --no-walk --decorate --oneline @args # FROM https://stackoverflow.com/questions/39220870/in-git-list-names-of-branches-with-unpushed-commits
}
Set-Alias -Name ggup -Value Get-GitLogBranchCommitsUnpushed

function Get-GitLogGraph {
    & $git_bin log --graph --pretty=oneline --abbrev-commit @args
}
Set-Alias -Name gll -Value Get-GitLogGraph

function Get-GitLogCommitsPulledLast {
    & $git_bin log HEAD@{1}..HEAD@{0} @args # Show commits since last pull, see http://blogs.atlassian.com/2014/10/advanced-git-aliases/
}
Set-Alias -Name gnew -Value Get-GitLogCommitsPulledLast

function Invoke-GitWhatchanged {
    & $git_bin whatchanged @args
}
Set-Alias -Name gwc -Value Invoke-GitWhatchanged

function Get-GitUntrackedFiles {
    & $git_bin ls-files . --exclude-standard --others @args # Show untracked files
}
Set-Alias -Name glsut -Value Get-GitUntrackedFiles

function Get-GitConflictedFiles {
    & $git_bin diff --name-only --diff-filter=U @args # Show unmerged (conflicted) files
}
Set-Alias -Name glsum -Value Get-GitConflictedFiles

function Invoke-GitGui {
    & $git_bin gui @args
}
Set-Alias -Name ggui -Value Invoke-GitGui

function Set-LocationGitHome {
    Set-Location "$(git rev-parse --show-toplevel)" @args # Git home
}
Set-Alias -Name ghm -Value Set-LocationGitHome

function New-GitPatchFile {
    & $git_bin format-patch -1 @args | Get-Item
}
Set-Alias -Name gpatch -Value New-GitPatchFile

function Publish-GitCommitsToOriginFromHead {
    & $git_bin push origin HEAD @args
}
Set-Alias -Name gpo -Value Publish-GitCommitsToOriginFromHead

function Publish-GitCommitsToOriginMain {
    & $git_bin push origin $(Get-GitBranchDefault) @args
}
Set-Alias -Name gpom -Value Publish-GitCommitsToOriginMain

function Publish-GitCommitsSettingUpstream {
    & $git_bin push --set-upstream @args
}
Set-Alias -Name gpu -Value Publish-GitCommitsSettingUpstream

Set-Alias -Name gpunch -Value Publish-GitCommitsForcefullyWithLease

function Publish-GitCommitsSettingUpstreamToOrigin {
    & $git_bin push --set-upstream origin @args
}
Set-Alias -Name gpuo -Value Publish-GitCommitsSettingUpstreamToOrigin

function Publish-GitCommitsSettingUpstreamToOriginFromCurrent {
    & $git_bin push --set-upstream origin $(git symbolic-ref --short HEAD) @args
}
Set-Alias -Name gpuoc -Value Publish-GitCommitsSettingUpstreamToOriginFromCurrent

# pull
function Invoke-GitPull {
    & $git_bin pull @args
}
# Set-Alias -Name gl -Value 'git pull'

function Update-GitBranchBaseFromUpstreamBranchMain {
    & $git_bin pull upstream $(Get-GitBranchDefault) @args
}
Set-Alias -Name glum -Value Update-GitBranchBaseFromUpstreamBranchMain

function Invoke-GitRepositorySync {
    & $git_bin pull
    if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
    & $git_bin push @args
}
Set-Alias -Name gpp -Value Invoke-GitRepositorySync

Set-Alias -Name gpr -Value Update-GitBranchBaseFromRemote

Set-Alias -Name gr -Value Invoke-GitRemote

Set-Alias -Name gra -Value Add-GitRemote

Set-Alias -Name grv -Value Get-GitRemotesList

# rm
function Remove-GitTrackedFiles {
    & $git_bin rm @args
}
Set-Alias -Name grm -Value Remove-GitTrackedFiles

# rebase
function Invoke-GitRebase {
    & $git_bin rebase @args
}
Set-Alias -Name grb -Value Invoke-GitRebase

function Resume-GitBranchBaseUpdate {
    & $git_bin rebase --continue @args
}
Set-Alias -Name grbc -Value Resume-GitBranchBaseUpdate

function Update-GitBranchBaseFromMain {
    & $git_bin rebase $(Get-GitBranchDefault) @args
}
Set-Alias -Name grmn -Value Update-GitBranchBaseFromMain

function Update-GitBranchBaseFromMainInteractively {
    & $git_bin rebase $(Get-GitBranchDefault) -i @args
}
Set-Alias -Name grmi -Value Update-GitBranchBaseFromMainInteractively

function Update-GitBranchBaseFromMainInteractivelyWithAutosquash {
    xwith @{
        GIT_SEQUENCE_EDITOR = ""
    } {
        & $git_bin rebase $(Get-GitBranchDefault) -i --autosquash @args
    } @args
}
Set-Alias -Name grma -Value Update-GitBranchBaseFromMainInteractivelyWithAutosquash

function Update-GitBranchBaseFromOriginUpdatedBranchMain {
    & $git_bin fetch origin $(Get-GitBranchDefault)
    if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
    & $git_bin rebase origin/$(Get-GitBranchDefault)
    if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
    & $git_bin update-ref refs/heads/$(Get-GitBranchDefault) origin/$(Get-GitBranchDefault) @args # Rebase with latest remote
}
Set-Alias -Name gprom -Value Update-GitBranchBaseFromOriginUpdatedBranchMain

# reset
function Reset-GitWorkingTreeToHead {
    & $git_bin reset HEAD @args
}
Set-Alias -Name gus -Value Reset-GitWorkingTreeToHead

function Reset-GitWorkingTreeToLastCommitLoseChangesAndCleanFully {
    Reset-GitWorkingTreeToLastCommitLoseChanges
    if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
    & $git_bin clean -dfx
}
Set-Alias -Name gpristine -Value Reset-GitWorkingTreeToLastCommitLoseChangesAndCleanFully

function Get-GitStatusShort {
    & $git_bin status -s @args
}
Set-Alias -Name gss -Value Get-GitStatusShort

# shortlog
function Get-GitContributors {
    & $git_bin shortlog -sn @args
}
Set-Alias -Name gcount -Value Get-GitContributors
Set-Alias -Name gsl -Value Get-GitContributors

# svn
function Publish-GitRepositoryToSvn {
    & $git_bin svn dcommit @args
}
Set-Alias -Name gsd -Value Publish-GitRepositoryToSvn

function Update-GitRepositoryFromSvn {
    & $git_bin svn rebase @args # Git SVN
}
Set-Alias -Name gsr -Value Update-GitRepositoryFromSvn

function New-GitBranchFromStash {
    & $git_bin stash branch @args
}
Set-Alias -Name gstb -Value New-GitBranchFromStash

# kept due to long-standing usage
Set-Alias -Name gstpo -Value Pop-GitStashEntry

## 'stash push' introduced in git v2.13.2
Set-Alias -Name gstpu -Value Push-GitStashEntry

Set-Alias -Name gstpum -Value Push-GitStashEntryWithMessage

## 'stash save' deprecated since git v2.16.0, alias is now push
Set-Alias -Name gsts -Value Push-GitStashEntry

function Push-GitStashEntryWithMessage {
    param(
        [Parameter(Mandatory = $true, Position = 0)]
        [string] $Message,

        [Parameter(Mandatory = $false, Position = 1, ValueFromRemainingArguments = $true)]
        [string[]] $rest
    )
    & $git_bin stash push -m $Message @rest
}
Set-Alias -Name gstsm -Value Push-GitStashEntryWithMessage

# submodules
function Update-GitSubmoduleInitRecursive {
    & $git_bin submodule update --init --recursive @args
}
Set-Alias -Name gsu -Value Update-GitSubmoduleInitRecursive

# switch
# these aliases requires git v2.23+
function Invoke-GitSwitch {
    & $git_bin switch @args
}
Set-Alias -Name gsw -Value Invoke-GitSwitch

function Switch-GitBranchNew {
    & $git_bin switch --create @args
}
Set-Alias -Name gswc -Value Switch-GitBranchNew

function Switch-GitBranchMain {
    & $git_bin switch $(Get-GitBranchDefault) @args
}
Set-Alias -Name gswm -Value Switch-GitBranchMain

function Switch-GitBranchAndTrack {
    & $git_bin switch --track @args
}
Set-Alias -Name gswt -Value Switch-GitBranchAndTrack

# functions
function gdv() {
	& $git_bin diff --ignore-all-space @args | vim -R -t
}

function Add-GitTrackedFiles {
    & $git_bin add @args
}
Set-Alias -Name ga -Value Add-GitTrackedFiles

function Add-GitTrackedFilesAll {
    & $git_bin add --all @args
}
Set-Alias -Name gaa -Value Add-GitTrackedFilesAll

function Add-GitTrackedFilesInteractively {
    & $git_bin add --interactive @args
}
Set-Alias -Name gai -Value Add-GitTrackedFilesInteractively

Set-Alias -Name galias -Value git_list_aliases

# Amend the most recent local commit:
function Update-GitCommitMessage {
    param(
        [Parameter(Mandatory = $true, Position = 0)]
        [string] $Message,

        [Parameter(Mandatory = $false, Position = 1, ValueFromRemainingArguments = $true)]
        [string[]] $rest
    )
    & $git_bin commit --amend -m $Message @rest # Only change commit message (optionally 'git add' files)
}
Set-Alias -Name gam -Value Update-GitCommitMessage

function Update-GitCommitFilesAndMessage {
    param(
        [Parameter(Mandatory = $true, Position = 0)]
        [string] $Message,

        [Parameter(Mandatory = $false, Position = 1, ValueFromRemainingArguments = $true)]
        [string[]] $rest
    )
    & $git_bin commit --amend -am $Message @rest # Add all modified files and change commit messag
}
Set-Alias -Name gama -Value Update-GitCommitFilesAndMessage

function Update-GitCommitFiles {
    & $git_bin commit --amend --no-edit @args # Keep commit message (optionally 'git add' files)
}
Set-Alias -Name gan -Value Update-GitCommitFiles

function Update-GitCommitFilesAll {
    & $git_bin commit --amend --no-edit -a @args # Add all modified files, but keep commit message
}
Set-Alias -Name gana -Value Update-GitCommitFilesAll

function Invoke-GitAddInteractivelyPatch {
    & $git_bin add --patch @args
}
Set-Alias -Name gap -Value Invoke-GitAddInteractivelyPatch

function Get-GitBranchListAll {
    & $git_bin branch --all @args
}
Set-Alias -Name gba -Value Get-GitBranchListAll

function Remove-GitBranch {
    & $git_bin branch --delete @args
}
Set-Alias -Name gbd -Value Remove-GitBranch

function Remove-GitBranchForcefully {
    & $git_bin branch --delete --force @args
}
Set-Alias -Name gbdf -Value Remove-GitBranchForcefully

function Invoke-GitBlame {
    & $git_bin blame @args
}
Set-Alias -Name gbl -Value Invoke-GitBlame

# 'git blame' that optionally takes line numbers:
# Usage: gbll <file> [<from line>] [<to line>]
#   E.g. gbll README.md 10
#      = gbll README.md 10 10
#      = gbll README.md 10,10
#      = git blame README.md -L 10,10
Set-Alias -Name gbll -Value 'git_blame_line'

function Get-GitBranchList {
    & $git_bin branch --list @args
}
Set-Alias -Name gbls -Value Get-GitBranchList

function Invoke-GitBisect {
    & $git_bin bisect @args
}
Set-Alias -Name gbs -Value Invoke-GitBisect

function Confirm-GitBisectCommitBad {
    & $git_bin bisect bad @args
}
Set-Alias -Name gbsb -Value Confirm-GitBisectCommitBad

function Confirm-GitBisectCommitGood {
    & $git_bin bisect good @args
}
Set-Alias -Name gbsg -Value Confirm-GitBisectCommitGood

function Reset-GitBisect {
    & $git_bin bisect reset @args
}
Set-Alias -Name gbsr -Value Reset-GitBisect

function Start-GitBisect {
    & $git_bin bisect start @args
}
Set-Alias -Name gbss -Value Start-GitBisect

function Write-GitCommitHelpfullyVerbose {
    & $git_bin commit --verbose @args
}
Set-Alias -Name gc -Force -Value Write-GitCommitHelpfullyVerbose

function Write-GitCommitAll {
    & $git_bin commit -am @args
}
Set-Alias -Name gcam -Value Write-GitCommitAll

function Write-GitCommitAllWithEmptyMessage {
    & $git_bin commit --allow-empty-message -am "" @args
}
Set-Alias -Name gcame -Value Write-GitCommitAllWithEmptyMessage

function Write-GitCommitAllGpgSigned {
    param(
        [Parameter(Mandatory = $true, Position = 0)]
        [string] $Message,

        [Parameter(Mandatory = $false, Position = 1, ValueFromRemainingArguments = $true)]
        [string[]] $rest
    )
    & $git_bin commit --gpg-sign -am $Message @rest
}
Set-Alias -Name gcamg -Value Write-GitCommitAllGpgSigned

function Write-GitCommitAllSignedoff {
    param(
        [Parameter(Mandatory = $true, Position = 0)]
        [string] $Message,

        [Parameter(Mandatory = $false, Position = 1, ValueFromRemainingArguments = $true)]
        [string[]] $rest
    )
    & $git_bin commit --signoff -am $Message @rest
}
Set-Alias -Name gcams -Value 'git commit --signoff -am'

function Write-GitCommitAllAsUpdate {
    & $git_bin commit -am "Update" @args
}
Set-Alias -Name gcamu -Value Write-GitCommitAllAsUpdate

function Write-GitCommitAllowEmpty {
    param(
        [Parameter(Mandatory = $true, Position = 0)]
        [string] $Message,

        [Parameter(Mandatory = $false, Position = 1, ValueFromRemainingArguments = $true)]
        [string[]] $rest
    )
    & $git_bin commit --allow-empty -m $Message @rest
}
Set-Alias -Name gcem -Value Write-GitCommitAllowEmpty

function Invoke-GitConfig {
    & $git_bin config @args
}
Set-Alias -Name gcf -Value Invoke-GitConfig

function Get-GitConfigList {
    & $git_bin config --list `
    | ForEach-Object {[PSCustomObject]@{
        Key=($_.Substring(0, $_.IndexOf('=')));
        Value=($_.Substring($_.IndexOf('=')+1))
    }}
}
Set-Alias -Name gcfl -Value Get-GitConfigList
Set-Alias -Name gcfls -Value Get-GitConfigList

function Invoke-GitCloneWithSubmodulesRecursed {
    & $git_bin clone --recurse-submodules @args
}
Set-Alias -Name gcls -Value Invoke-GitCloneWithSubmodulesRecursed

Set-Alias -Name gclcd -Value git_clone_and_cd

function Write-GitCommit {
    param(
        [Parameter(Mandatory = $true, Position = 0)]
        [string] $message,

        [Parameter(Mandatory = $false, Position = 1, ValueFromRemainingArguments = $true)]
        [string[]] $rest
    )
    & $git_bin commit -m $message @rest
}
Set-Alias -Name gcm -Force -Value Write-GitCommit

function Write-GitCommitGpgSigned {
    param(
        [Parameter(Mandatory = $true, Position = 0)]
        [string] $message,

        [Parameter(Mandatory = $false, Position = 1, ValueFromRemainingArguments = $true)]
        [string[]] $rest
    )
    & $git_bin commit --gpg-sign -m $message @rest
}
Set-Alias -Name gcmg -Value Write-GitCommitGpgSigned

function Write-GitCommitSignedoff {
    param(
        [Parameter(Mandatory = $true, Position = 0)]
        [string] $message,

        [Parameter(Mandatory = $false, Position = 1, ValueFromRemainingArguments = $true)]
        [string[]] $rest
    )
    & $git_bin commit --signoff -m $message @rest
}
Set-Alias -Name gcms -Value Write-GitCommitSignedoff

# Count the number of commits on a branch:
Set-Alias -Name gcnt -Value git_count

Set-Alias -Name gcnta -Value git_count_all

function Use-GitBranch {
    & $git_bin checkout @args
}
Set-Alias -Name gco -Value Use-GitBranch

function Use-GitBranchNew {
    & $git_bin checkout -b @args
}
Set-Alias -Name gcob -Value Use-GitBranchNew

function Use-GitBranchPrevious {
    & $git_bin checkout - @args # "checkout branch before"
}
Set-Alias -Name gcobb -Value Use-GitBranchPrevious

# Check out a child commit:
# Usage: gcoc [<number of commits after HEAD>]
#   E.g. gcoc = gcoc 1   => checks out direct child
#               gcoc 2   => checks out grandchild
Set-Alias -Name gcoc -Value git_checkout_child

function Use-GitBranchDevelop {
    & $git_bin checkout develop @args
}
Set-Alias -Name gcod -Value Use-GitBranchDevelop

function Use-GitBranchMain {
    & $git_bin checkout $(Get-GitBranchDefault) @args
}
Set-Alias -Name gcom -Value Use-GitBranchMain

# Check out a parent commit:
# Usage: gcop [<number of commits before HEAD>]
#   E.g. gcop = gcop 1   => checks out direct parent
#               gcop 2   => checks out grandparent
Set-Alias -Name gcop -Value git_checkout_parent

function Start-GitCherryPick {
    & $git_bin cherry-pick @args
}
Set-Alias -Name gcp -Value Start-GitCherryPick

function Stop-GitCherryPick {
    & $git_bin cherry-pick --abort @args
}
Set-Alias -Name gcpa -Value Stop-GitCherryPick

function Resume-GitCherryPick {
    & $git_bin cherry-pick --continue @args
}
Set-Alias -Name gcpc -Value Resume-GitCherryPick

function Get-GitDiff {
    & $git_bin diff @args
}
Set-Alias -Name gd -Value Get-GitDiff

function Get-GitDiffStaged {
    & $git_bin diff --staged @args
}
Set-Alias -Name gds -Value Get-GitDiffStaged

# Show the diff between latest stash and local working tree:
function Get-GitDiffStash {
    & $git_bin diff stash@{0} @args # = git stash show -l
}
Set-Alias -Name gdst -Value Get-GitDiffStash

# Show the diff between latest stash and HEAD:
function Get-GitDiffStashHead {
    & $git_bin diff stash@{0} HEAD @args
}
Set-Alias -Name gdsth -Value Get-GitDiffStashHead

# Show the diff between latest stash and its original parent commit:
function Get-GitDiffStashParent {
    & $git_bin diff stash@{0}^ stash@{0} @args # = git stash show -p
}
Set-Alias -Name gdstp -Value Get-GitDiffStashParent


function Invoke-GitFetch {
    & $git_bin fetch @args
}
Set-Alias -Name gf -Value Invoke-GitFetch

function Invoke-GitFetchOrigin {
    & $git_bin fetch origin @args
}
Set-Alias -Name gfo -Value Invoke-GitFetchOrigin

# git graph branches:
function Get-GitLogGraphBranchesSimplifiedStylized {
    & $git_bin log --graph --all --simplify-by-decoration --date=format:"%d/%m/%y" --pretty=format:"%C(yellow)%h%Creset%x09%C(bold green)%D%Creset%n%C(white)%ad%Creset%x09%C(bold)%s%Creset%n" @args
}
Set-Alias -Name ggb -Value Get-GitLogGraphBranchesSimplifiedStylized

# Ignore already tracked files:
function Add-GitSkipWorktreeFlag {
    & $git_bin update-index --skip-worktree @args
}
Set-Alias -Name gignore -Value Add-GitSkipWorktreeFlag

function Remove-GitSkipWorktreeFlag {
    & $git_bin update-index --no-skip-worktree @args
}
Set-Alias -Name gunignore -Value Remove-GitSkipWorktreeFlag

function Get-GitIgnoredFiles {
    & $git_bin ls-files -v | Where-Object { $_.StartsWith("S") }
}
Set-Alias -Name gignored -Value Get-GitIgnoredFiles

# Best default 'git log':
function Get-GitLogStylizedNameStatus {
    Get-GitLogStylized --name-status @args
}
Set-Alias -Name gl -Force -Value Get-GitLogStylizedNameStatus

# View the full change history of a single file:
# Usage: glf <file> [<from line>] [<to line>]
Set-Alias -Name glf -Value git_log_file

# Fancy 'git log --graph':
function Get-GitLogStylizedGraph {
    Get-GitLogStylized --graph @args
}
Set-Alias -Name glg -Value Get-GitLogStylizedGraph

# Fancy 'git log --graph --oneline':
function Get-GitLogGraphOnelineStylized {
    & $git_bin log --graph --date=format:"%d/%m/%y" --pretty=format:"%C(yellow)%h%Creset   %C(white)%ad%Creset   %C(bold)%s    %C(bold green)%D%Creset%n" @args
}
Set-Alias -Name glgo -Value Get-GitLogGraphOnelineStylized

# Fancy 'git log --graph --stat':
function Get-GitLogStylizedGraphStat {
    Get-GitLogStylized --graph --stat @args
}
Set-Alias -Name glgs -Value Get-GitLogStylizedGraphStat

# Fancy 'git log --oneline':
function Get-GitLogOnelineStylized {
    & $git_bin log --date=format:"%d/%m/%y" --pretty=format:"%C(yellow)%h%Creset   %C(white)%ad%Creset   %C(bold)%s    %C(bold green)%D%Creset" @args
}
Set-Alias -Name glo -Value Get-GitLogOnelineStylized

# Locate all commits in which a specific line of code (string) was first introduced:
# Usage: gloc <Line-of-Code> [<file>]
Set-Alias -Name gloc -Value git_locate_string

# Regular 'git log' in style:
function Get-GitLogStylized {
    & $git_bin log --date=format:"%A %B %d %Y at %H:%M" --pretty=format:"%C(yellow)%H%Creset%x09%C(bold green)%D%Creset%n%<|(40)%C(white)%ad%x09%an%Creset%n%n    %C(bold)%s%Creset%n%w(0,4,4)%n%-b%n" @args # %w(0,4,4): no line-wrap, indent first line 4 chars, subsequent lines also 4 lines
}
Set-Alias -Name glog -Value Get-GitLogStylized

function Get-GitLogStylizedReverseNameStatus {
    Get-GitLogStylized --reverse --name-status @args
}
Set-Alias -Name glr -Value Get-GitLogStylizedReverseNameStatus

function Get-GitTrackedFiles {
    & $git_bin ls-files @args
}
Set-Alias -Name gls -Value Get-GitTrackedFiles


function Invoke-GitMerge {
    & $git_bin merge @args
}
Set-Alias -Name gm -Force -Value Invoke-GitMerge

function Merge-GitRepositoryFromOriginBranchMain {
    & $git_bin merge origin/$(Get-GitBranchDefault) @args
}
Set-Alias -Name gmom -Value Merge-GitRepositoryFromOriginBranchMain

function Merge-GitRepositoryFromUpstreamBranchMain {
    & $git_bin merge upstream/$(Get-GitBranchDefault) @args
}
Set-Alias -Name gmum -Value Merge-GitRepositoryFromUpstreamBranchMain

function Move-GitTrackedFiles {
    & $git_bin mv @args
}
Set-Alias -Name gmv -Value Move-GitTrackedFiles

function Invoke-GitPush {
    & $git_bin push @args
}
Set-Alias -Name gp -Force -Value Invoke-GitPush

function Remove-GitRemoteBranch {
    & $git_bin push --delete @args
}
Set-Alias -Name gpd -Value Remove-GitRemoteBranch

function Remove-GitRemoteBranchOrigin {
    & $git_bin push --delete origin @args
}
Set-Alias -Name gpdo -Value Remove-GitRemoteBranchOrigin

function Publish-GitCommitsForcefullyWithLease {
    & $git_bin push --force-with-lease @args
}
Set-Alias -Name gpf -Value Publish-GitCommitsForcefullyWithLease

function Publish-GitCommitsWithTags {
    & $git_bin push
    if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
    & $git_bin push --tags @args
}
Set-Alias -Name gpt -Value Publish-GitCommitsWithTags

function Update-GitRepository {
    & $git_bin pull @args
}
Set-Alias -Name gpl -Value Update-GitRepository

function Update-GitBranchBaseFromRemote {
    & $git_bin pull --rebase @args
}
Set-Alias -Name gplr -Value Update-GitBranchBaseFromRemote

function Update-GitRepositoryAndSubmodules {
    & $git_bin pull --recurse-submodules @args
}
Set-Alias -Name gplrs -Value Update-GitRepositoryAndSubmodules

# `grhard` is intentionally more verbose because `--hard` is unsafe;
# there is no way to recover uncommitted changes.
# In general the `--keep` flag is preferable. It will do exactly the same,
# but abort if a file has uncommitted changes.
# Having to type 'grhard' in full will make us think twice
# about whether we REALLY want to get rid of all dirty files.
function Reset-GitWorkingTreeToLastCommitAndUnstageChanges {
    & $git_bin reset --mixed @args # Keep changes, but unstage them (`--mixed` = default behaviour)
}
Set-Alias -Name gr -Value Reset-GitWorkingTreeToLastCommitAndUnstageChanges

function Reset-GitWorkingTreeToLastCommitLoseChanges {
    [CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'High')]
    param(
        [Parameter(Mandatory = $false, Position = 0)]
        [string[]] $rest
    )
    [string] $action = "Resetting working tree to last commit, losing all changes."
    if ($PSCmdlet.ShouldProcess($action)) {
        & $git_bin reset --hard @rest # Remove changes, including anything uncommitted (Dangerous!)
    } else {
        Write-Warning "Not: $action"
    }
}
Set-Alias -Name grhard -Value Reset-GitWorkingTreeToLastCommitLoseChanges

function Reset-GitWorkingTreeToLastCommitAndKeepChanges {
    & $git_bin reset --keep @args # Safer version of `--hard`: reset is aborted if a file is dirty
}
Set-Alias -Name grk -Value Reset-GitWorkingTreeToLastCommitAndKeepChanges

function Reset-GitStagedChanges {
    & $git_bin reset --soft @args # Keep changes, and keep them staged
}
Set-Alias -Name grs -Value Reset-GitStagedChanges

# Reset HEAD to a previous commit:
# Usage: grh [<number of commits before HEAD>]
#   E.g. grh = grh 1   => Reset HEAD to previous commit
#              grh 2   => Reset HEAD 2 commits
function git_reset_head_mixed {
    git_reset_head --mixed @args
}
Set-Alias -Name grh -Value git_reset_head_mixed

function git_reset_head_hard {
    git_reset_head --hard @args
}
Set-Alias -Name grhhard -Value git_reset_head_hard

function git_reset_head_keep {
    git_reset_head --keep @args
}
Set-Alias -Name grhk -Value git_reset_head_keep

function git_reset_head_soft {
    git_reset_head --soft @args
}
Set-Alias -Name grhs -Value git_reset_head_soft

function Update-GitBranchBaseFromBranchMain {
    & $git_bin rebase $(Get-GitBranchDefault) @args
}
Set-Alias -Name grbm -Value Update-GitBranchBaseFromDefaultBranch

function Invoke-GitRemote {
    & $git_bin remote @args
}
Set-Alias -Name grem -Value Invoke-GitRemote

function Add-GitRemote {
    & $git_bin remote add @args
}
Set-Alias -Name grema -Value Add-GitRemote

function Remove-GitRemote {
    & $git_bin remote rm @args
}
Set-Alias -Name gremrm -Value Remove-GitRemote

function Set-GitRemoteUrl {
    & $git_bin remote set-url @args
}
Set-Alias -Name gremset -Value Set-GitRemoteUrl

function Show-GitRemote {
    & $git_bin remote show @args
}
Set-Alias -Name gremsh -Value Show-GitRemote

function Get-GitRemotesList {
    & $git_bin remote -v @args
}
Set-Alias -Name gremv -Value Get-GitRemotesList

function Invoke-GitReflog {
    & $git_bin reflog @args # Useful to restore lost commits after reset
}
Set-Alias -Name grl -Value Invoke-GitReflog

# Yes, I am aware gs is commonly aliased to ghostscript,
# but since my usage of ghostscript is rare compared to git,
# I can live with typing 'ghostscript' in full when necessary.
function Get-GitStatus {
    & $git_bin status @args
}
Set-Alias -Name gs -Value Get-GitStatus

function Invoke-GitShowStylized {
    & $git_bin show --date=format:"%A %B %d %Y at %H:%M" --pretty=format:"%C(yellow)%H%Creset%x09%C(bold green)%D%Creset%n%<|(40)%C(white)%ad%x09%an%Creset%n%n    %C(bold)%s%Creset%n%w(0,4,4)%+b%n" @args
}
Set-Alias -Name gsh -Value Invoke-GitShowStylized

Set-Alias -Name gshsf -Value git_show_stash_file

Set-Alias -Name gssll -Value git_status_short_with_loglines

function Invoke-GitStash {
    & $git_bin stash @args
}
Set-Alias -Name gst -Value Invoke-GitStash

function Use-GitStashEntry {
    & $git_bin stash apply @args
}
Set-Alias -Name gsta -Value Use-GitStashEntry

function Remove-GitStashEntry {
    & $git_bin stash drop @args
}
Set-Alias -Name gstd -Value Remove-GitStashEntry

function Get-GitStashList {
    & $git_bin stash list @args
}

Set-Alias -Name gstl -Value Get-GitStashList

Set-Alias -Name gstls -Value Get-GitStashList

function Push-GitStashEntry {
    & $git_bin stash push @args
}
Set-Alias -Name gstp -Value Push-GitStashEntry

function Pop-GitStashEntry {
    & $git_bin stash pop @args
}
Set-Alias -Name gstpop -Value Pop-GitStashEntry

# Show the diff between latest stash and local working tree:
function Get-GitStashDiffFromWorkingTree {
    & $git_bin stash show -l @args # = git diff stash@{0}
}
Set-Alias -Name gstsl -Value Get-GitStashDiffFromWorkingTree

# Show the diff between latest stash and its original parent commit:
function Get-GitStashDiffFromParent {
    & $git_bin stash show -p @args # = git diff stash@{0}^! = git diff stash@{0}^ stash@{0
}
Set-Alias -Name gstsp -Value Get-GitStashDiffFromParent

function Invoke-GitSubmodule {
    & $git_bin submodule @args
}
Set-Alias -Name gsub -Value Invoke-GitSubmodule

function Add-GitSubmodule {
    & $git_bin submodule add @args
}
Set-Alias -Name gsuba -Value Add-GitSubmodule

function Update-GitSubmoduleInit {
    & $git_bin submodule update --init @args # Initialize submodules
}
Set-Alias -Name gsubi -Value Update-GitSubmoduleInit

function Invoke-GitSubmoduleAllPull {
    & $git_bin submodule foreach git pull @args
}
Set-Alias -Name gsubpl -Value Invoke-GitSubmoduleAllPull

function Invoke-GitSubmoduleAllPullOrigin {
    & $git_bin submodule foreach git pull origin $(Get-GitBranchDefault) @args
}
Set-Alias -Name gsubplom -Value Invoke-GitSubmoduleAllPullOrigin

function Get-GitSubmoduleStatus {
    & $git_bin submodule status @args
}
Set-Alias -Name gsubs -Value Get-GitSubmoduleStatus

function Update-GitSubmoduleFromRemoteMerge {
    & $git_bin submodule update --remote --merge @args # Update submodules
}
Set-Alias -Name gsubu -Value Update-GitSubmoduleFromRemoteMerge


function Invoke-GitTag {
    & $git_bin tag @args
}
Set-Alias -Name gt -Value Invoke-GitTag

function Add-GitTagAnnotated {
    param(
        [Parameter(Mandatory = $true, Position = 0)]
        [string] $Message,

        [Parameter(Mandatory = $true, Position = 1)]
        [string] $Name,

        [Parameter(Mandatory = $false, Position = 2, ValueFromRemainingArguments = $true)]
        [string[]] $rest
    )
    & $git_bin tag -am $Message $Name @args # <- takes message before annotated tag name: e.g. gtam 'Release v1.0.0' v1.0.0
}
Set-Alias -Name gtam -Value Add-GitTagAnnotated

function Add-GitTagGpgSigned {
    param(
        [Parameter(Mandatory = $true, Position = 0)]
        [string] $Message,

        [Parameter(Mandatory = $true, Position = 1)]
        [string] $Name,

        [Parameter(Mandatory = $false, Position = 2, ValueFromRemainingArguments = $true)]
        [string[]] $rest
    )
    & $git_bin tag -sm $Message $Name @rest # GPG sign an annotated tag
}
Set-Alias -Name gtsm -Value Add-GitTagGpgSigned

function Remove-GitTag {
    param(
        [Parameter(Mandatory = $true, Position = 0)]
        [string] $Tag,

        [Parameter(Mandatory = $false, Position = 1, ValueFromRemainingArguments = $true)]
        [string[]] $rest
    )
    & $git_bin tag --delete $Tag @rest
}
Set-Alias -Name gtd -Value Remove-GitTag

function Get-GitTagList {
    & $git_bin tag --list @args
}

Set-Alias -Name gtl -Value Get-GitTagList

Set-Alias -Name gtls -Value Get-GitTagList


function Get-GitWhatChangedStylized {
    & $git_bin whatchanged -p --date=format:"%A %B %d %Y at %H:%M" --pretty=format:"%n%n%C(yellow)%H%Creset%x09%C(bold green)%D%Creset%n%<|(40)%C(white)%ad%x09%an%Creset%n%n    %C(bold)%s%Creset%n%w(0,4,4)%+b%n" @args
}
Set-Alias -Name gwch -Value Get-GitWhatChangedStylized


# Functions
################

# git blame that optionally takes line numbers:
# Usage: git_blame_line <file> [<from line>] [<to line>]
function git_blame_line {
    param(
        [Parameter(Mandatory=$true, Position=0)]
        [string] $File,

        [Parameter(Mandatory=$false, Position=1, ParameterSetName='FromLine')]
        [Parameter(Mandatory=$true, Position=1, ParameterSetName='FromLineToLine')]
        [Nullable[int]] $FromLine,

        [Parameter(Mandatory=$true, Position=1, ParameterSetName='LineRange')]
        [ValidateCount(2,2)]
        [int[]] $LineRange,

        [Parameter(Mandatory=$true, Position=2, ParameterSetName='FromLineToLine')]
        [Nullable[int]] $ToLine
    )
    if ($LineRange) {
        $FromLine = $LineRange[0]
        $ToLine = $LineRange[1]
    } elseif ($null -eq $FromLine) {
        $FromLine = 1
    }
    if ($null -eq $ToLine) {
        $ToLine = $FromLine
    }
    & $git_bin blame $File -L "$FromLine,$ToLine"
}

# Checkout parent/older commit:
function git_checkout_parent() {
  param(
    [Parameter(Mandatory=$false, Position=0)]
    [ValidateRange(1, [int]::MaxValue)]
    [int] $Offset = 1
  )
  & $git_bin checkout HEAD~$Offset
}

# Checkout child/newer commit:
function git_checkout_child {
  param(
    [Parameter(Mandatory=$false, Position=0)]
    [ValidateRange(1, [int]::MaxValue)]
    [int] $Offset = 1
  )
  [string[]] $children=(git log --all --ancestry-path ^HEAD --format=format:%H)
  if (-not $children) {
    Write-Output 'This commit does not have any children'
    Write-Output "HEAD remains at "+(git log -1 --oneline)
    return 1
  } else {
    # Take the first child, or the one specified by the input arg:
    $child=$children[$Offset-1]
    # If the child to checkout is at the branch's tip ...
    if ($children.Count -le $Offset) {
      [string[]] $branches=(git branch --contains $child) -split ' '
      # ... and there is only 1 branch with that commit ...
      if ($branches.Count -eq 1) {
        # ... checkout the branch itself instead of the specific hash:
        $child=$branch
      }
    }
  }

  & $git_bin checkout $child
}

function git_clone_and_cd {
  param(
    [Parameter(Mandatory=$true, Position=0)]
    [string] $Repo,

    [Parameter(Mandatory=$false, Position=1)]
    [string] $Name = $null
  )
  if (-not $Name) {
    $Name = $(basename $Repo .git)
  }

  & $git_bin clone --recurse-submodules $Repo $Name
  Set-Location $Name
}

function git_count {
  [int] $count = (git rev-list --count HEAD)
  Write-Output "$count commits total up to current HEAD"
}

function git_count_all {
  & $git_bin shortlog -sn
  Write-Output "+ _______________________________________"
  Write-Output
  Write-Output "  "+(git_count)
}

# Locate all commits in which a specific line of code (string) was first introduced:
function git_locate_string {
  param(
    [Parameter(Mandatory=$true, Position=0)]
    [string] $Text,

    [Parameter(Mandatory=$false, Position=1)]
    [string] $File = $null
  )
  Get-GitLogStylizedNameStatus -S $Text -- $File
}

# View the full change history of a single file:
function git_log_file {
  param(
    [Parameter(Mandatory=$true, Position=0)]
    [string] $File,

    [Parameter(Mandatory=$false, Position=1, ParameterSetName='FromLine')]
    [Parameter(Mandatory=$true, Position=1, ParameterSetName='FromLineToLine')]
    [Nullable[int]] $FromLine,

    [Parameter(Mandatory=$true, Position=1, ParameterSetName='LineRange')]
    [ValidateCount(2,2)]
    [int[]] $LineRange,

    [Parameter(Mandatory=$true, Position=2, ParameterSetName='FromLineToLine')]
    [Nullable[int]] $ToLine
  )

  if (-not $FromLine) {
    Get-GitLogStylized -p -- $File
    exit
  } elseif ( $LineRange ) {
    $FromLine = $LineRange[0]
    $ToLine = $LineRange[1]
  } elseif( -not $ToLine ) {
    $ToLine = $FromLine
  }
  Get-GitLogStylized -L ${FromLine},${ToLine}:${File}
}

# Check if main exists and use instead of master:
function Get-GitBranchDefault {
  [bool] $mainBranchExists = (-not [string]::IsNullOrWhiteSpace((git branch --list main)))

  if ($mainBranchExists) {
    return "main"
  } else {
    return "master"
  }
}

# Reset the head to a previous commit (defaults to direct parent):
function git_reset_head {
  param(
    [Parameter(Mandatory=$false, Position=0)]
    [ValidateSet('--hard', '--keep', '--soft', '--merge', '--keep', '')]
    [string] $Mode = '',

    [Parameter(Mandatory=$false, Position=1)]
    [Nullable[int]] $Count = $null
  )

  & $git_bin reset HEAD~$Count $Mode
  if ($LASTEXITCODE -ne 0) {
    # Failure case:
    Write-Output -n 'HEAD remains at '
    & $git_bin log -1 --oneline
    exit 1
  }
  elseif ($Mode -ne '--hard') {
    # Success case (unless --hard was specified):
    Write-Output -n 'HEAD is now at '
    & $git_bin log -1 --oneline
  }
}

# Show a specified file from stash x (defaults to lastest stash):
# Usage: git_show_stash_file <file> [<stash number>]
function git_show_stash_file {
  param() {
    [Parameter(Mandatory=$true, Position=0)] [string] $File
    [Parameter(Mandatory=$false, Position=1)] [int] $StashNumber = 0
  }
  & $git_bin show stash@{$StashNumber}:$File
}

# Print short status and log of latest commits:
function git_status_short_with_loglines {
  param(
    [Parameter(Mandatory=$false, Position=0)] [int] $Count = 3
  )
  [string] $gitStatus = (git status -s | Out-String)
  if (-not $gitStatus) {
    Write-Output 'Nothing to commit, working tree clean'
  } else {
    Write-Output $gitStatus
  }
  & $git_bin log -$Count --oneline
}

Set-Alias -Name pushgr -Value Push-LocationGitRoot

Set-Alias -Name cdgr -Value Set-LocationGitRoot
