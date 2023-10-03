#!/usr/bin/env pwsh
$ErrorActionPreference = "Stop"
Set-StrictMode -Version Latest


Get-ChildItem -Path "$PSScriptRoot/*.ps1" | ForEach-Object {
    . $_.FullName
}

if (Test-Path Function:\Invoke-Hub -ErrorAction SilentlyContinue) {
    Export-ModuleMember -Function Invoke-Hub
    Export-ModuleMember -Alias git
}

Export-ModuleMember -Function git_remote
Export-ModuleMember -Function git_first_push
Export-ModuleMember -Function git_pub
Export-ModuleMember -Function git_revert
Export-ModuleMember -Function git_rollback
Export-ModuleMember -Function git_remove_missing_files
Export-ModuleMember -Function local-ignore
Export-ModuleMember -Function git_info
Export-ModuleMember -Function git_stats
Export-ModuleMember -Function gittowork
Export-ModuleMember -Function gitignore-reload
Export-ModuleMember -Function git-changelog
Export-ModuleMember -Function Invoke-Git -Alias "g", "get", "gall"
Export-ModuleMember -Function Add-GitTrackedFilesVerbosely -Alias gav
Export-ModuleMember -Function Invoke-GitBranch -Alias "gb", "gbD", "gbl"
Export-ModuleMember -Function Get-GitBranchListAll -Alias "gbla"
Export-ModuleMember -Function Get-GitBranchListRemotes -Alias "gblr"
Export-ModuleMember -Function Rename-GitBranch -Alias "gbm"
Export-ModuleMember -Function Get-GitBranchRemotes -Alias "gbr"
Export-ModuleMember -Function New-GitBranchTracked -Alias "gbt"
Export-ModuleMember -Alias "gdel"
Export-ModuleMember -Function Get-GitRemoteBranchesAuthors -Alias gbc
Export-ModuleMember -Function Update-GitCommitFilesVerboselyAll -Alias gca
Export-ModuleMember -Function Update-GitCommitByHead -Alias gcaa
Export-ModuleMember -Function Update-GitCommit -Alias gcamd
Export-ModuleMember -Function Write-GitCommitInteractively -Alias gci
Export-ModuleMember -Function Write-GitCommitGpgSignedByKey -Alias gcsam
Export-ModuleMember -Function Use-GitBranchTracked -Alias gct
Export-ModuleMember -Function Invoke-GitClone -Alias gcl
Export-ModuleMember -Function Remove-GitUntrackedFiles -Alias gclean
Export-ModuleMember -Function Start-GitCherryPickExplained -Alias gcpx
Export-ModuleMember -Function Invoke-GitDifftool -Alias gdt
Export-ModuleMember -Function Export-GitRepositoryZip -Alias gexport
Export-ModuleMember -Function Update-GitRemoteChanges -Alias gfa
Export-ModuleMember -Function Update-GitRemoteChangesTags -Alias gft
Export-ModuleMember -Function Update-GitRemoteChangesTagsVerbose -Alias gftv
Export-ModuleMember -Function Update-GitRemoteChangesVerbose -Alias gfv
Export-ModuleMember -Function Merge-GitRepositoryFromUpstreamBranchMain -Alias gmu
Export-ModuleMember -Function Update-GitBranchBaseFromRemote -Alias gup
Export-ModuleMember -Function Get-GitLogGraphStylized -Alias gg
Export-ModuleMember -Function Get-GitLogGraphStylizedDated -Alias ggf
Export-ModuleMember -Function Get-GitLogGraphStylizedStat -Alias ggs
Export-ModuleMember -Function Get-GitLogBranchCommitsUnpushed -Alias ggup
Export-ModuleMember -Function Get-GitLogGraph -Alias gll
Export-ModuleMember -Function Get-GitLogCommitsPulledLast -Alias gnew
Export-ModuleMember -Function Invoke-GitWhatchanged -Alias gwc
Export-ModuleMember -Function Get-GitUntrackedFiles -Alias glsut
Export-ModuleMember -Function Get-GitConflictedFiles -Alias glsum
Export-ModuleMember -Function Invoke-GitGui -Alias ggui
Export-ModuleMember -Function Set-LocationGitHome -Alias ghm
Export-ModuleMember -Function New-GitPatchFile -Alias gpatch
Export-ModuleMember -Function Publish-GitCommitsToOriginFromHead -Alias gpo
Export-ModuleMember -Function Publish-GitCommitsToOriginMain -Alias gpom
Export-ModuleMember -Function Publish-GitCommitsSettingUpstream -Alias gpu
Export-ModuleMember -Alias gpunch
Export-ModuleMember -Function Publish-GitCommitsSettingUpstreamToOrigin -Alias gpuo
Export-ModuleMember -Function Publish-GitCommitsSettingUpstreamToOriginFromCurrent -Alias gpuoc
Export-ModuleMember -Function Invoke-GitPull
Export-ModuleMember -Function Update-GitBranchBaseFromUpstreamBranchMain -Alias glum
Export-ModuleMember -Function Invoke-GitRepositorySync
Export-ModuleMember -Alias gpp
Export-ModuleMember -Alias gpr
Export-ModuleMember -Alias gr
Export-ModuleMember -Alias gra
Export-ModuleMember -Alias grv
Export-ModuleMember -Function Remove-GitTrackedFiles -Alias grm
Export-ModuleMember -Function Invoke-GitRebase -Alias grb
Export-ModuleMember -Function Resume-GitBranchBaseUpdate -Alias grbc
Export-ModuleMember -Function Update-GitBranchBaseFromMain -Alias grmn
Export-ModuleMember -Function Update-GitBranchBaseFromMainInteractively -Alias grmi
Export-ModuleMember -Function Update-GitBranchBaseFromMainInteractivelyWithAutosquash -Alias grma
Export-ModuleMember -Function Update-GitBranchBaseFromOriginUpdatedBranchMain -Alias gprom
Export-ModuleMember -Function Reset-GitWorkingTreeToHead -Alias gus
Export-ModuleMember -Function Reset-GitWorkingTreeToLastCommitLoseChangesAndCleanFully -Alias gpristine
Export-ModuleMember -Function Get-GitStatusShort -Alias gss
Export-ModuleMember -Function Get-GitContributors -Alias "gcount", "gsl"
Export-ModuleMember -Function Publish-GitRepositoryToSvn -Alias gsd
Export-ModuleMember -Function Update-GitRepositoryFromSvn -Alias gsr
Export-ModuleMember -Function New-GitBranchFromStash -Alias gstb
Export-ModuleMember -Alias "gstpo", "gstpu", "gstpum", "gsts"
Export-ModuleMember -Function Push-GitStashEntryWithMessage -Alias gstsm
Export-ModuleMember -Function Update-GitSubmoduleInitRecursive -Alias gsu
Export-ModuleMember -Function Invoke-GitSwitch -Alias gsw
Export-ModuleMember -Function Switch-GitBranchNew -Alias gswc
Export-ModuleMember -Function Switch-GitBranchMain -Alias gswm
Export-ModuleMember -Function Switch-GitBranchAndTrack -Alias gswt
Export-ModuleMember -Function gdv
Export-ModuleMember -Function Add-GitTrackedFiles -Alias ga
Export-ModuleMember -Function Add-GitTrackedFilesAll -Alias gaa
Export-ModuleMember -Function Add-GitTrackedFilesInteractively -Alias gai
Export-ModuleMember -Alias galias
Export-ModuleMember -Function Update-GitCommitMessage -Alias gam
Export-ModuleMember -Function Update-GitCommitFilesAndMessage -Alias gama
Export-ModuleMember -Function Update-GitCommitFiles -Alias gan
Export-ModuleMember -Function Update-GitCommitFilesAll -Alias gana
Export-ModuleMember -Function Invoke-GitAddInteractivelyPatch -Alias gap
Export-ModuleMember -Function Get-GitBranchListAll -Alias gba
Export-ModuleMember -Function Remove-GitBranch -Alias gbd
Export-ModuleMember -Function Remove-GitBranchForcefully -Alias gbdf
Export-ModuleMember -Function Invoke-GitBlame -Alias gbl
Export-ModuleMember -Alias gbll
Export-ModuleMember -Function Get-GitBranchList -Alias gbls
Export-ModuleMember -Function Invoke-GitBisect -Alias gbs
Export-ModuleMember -Function Confirm-GitBisectCommitBad -Alias gbsb
Export-ModuleMember -Function Confirm-GitBisectCommitGood -Alias gbsg
Export-ModuleMember -Function Reset-GitBisect -Alias gbsr
Export-ModuleMember -Function Start-GitBisect -Alias gbss
Export-ModuleMember -Function Write-GitCommitHelpfullyVerbose -Alias gc
Export-ModuleMember -Function Write-GitCommitAll -Alias gcam
Export-ModuleMember -Function Write-GitCommitAllWithEmptyMessage -Alias gcame
Export-ModuleMember -Function Write-GitCommitAllGpgSigned -Alias gcamg
Export-ModuleMember -Function Write-GitCommitAllSignedoff -Alias gcams
Export-ModuleMember -Function Write-GitCommitAllAsUpdate -Alias gcamu
Export-ModuleMember -Function Write-GitCommitAllowEmpty -Alias gcem
Export-ModuleMember -Function Invoke-GitConfig -Alias gcf
Export-ModuleMember -Function Get-GitConfigList -Alias "gcfl", "gcfls"
Export-ModuleMember -Function Invoke-GitCloneWithSubmodulesRecursed -Alias gcls
Export-ModuleMember -Alias gclcd
Export-ModuleMember -Function Write-GitCommit -Alias gcm
Export-ModuleMember -Function Write-GitCommitGpgSigned -Alias gcmg
Export-ModuleMember -Function Write-GitCommitSignedoff -Alias gcms
Export-ModuleMember -Alias "gcnt", "gcnta"
Export-ModuleMember -Function Use-GitBranch -Alias gco
Export-ModuleMember -Function Use-GitBranchNew -Alias gcob
Export-ModuleMember -Function Use-GitBranchPrevious -Alias gcobb
Export-ModuleMember -Alias gcoc
Export-ModuleMember -Function Use-GitBranchDevelop -Alias gcod
Export-ModuleMember -Function Use-GitBranchMain -Alias gcom
Export-ModuleMember -Alias gcop
Export-ModuleMember -Function Start-GitCherryPick -Alias gcp
Export-ModuleMember -Function Stop-GitCherryPick -Alias gcpa
Export-ModuleMember -Function Resume-GitCherryPick -Alias gcpc
Export-ModuleMember -Function Get-GitDiff -Alias gd
Export-ModuleMember -Function Get-GitDiffStaged -Alias gds
Export-ModuleMember -Function Get-GitDiffStash -Alias gdst
Export-ModuleMember -Function Get-GitDiffStashHead -Alias gdsth
Export-ModuleMember -Function Get-GitDiffStashParent -Alias gdstp
Export-ModuleMember -Function Invoke-GitFetch -Alias gf
Export-ModuleMember -Function Invoke-GitFetchOrigin -Alias gfo
Export-ModuleMember -Function Get-GitLogGraphBranchesSimplifiedStylized -Alias ggb
Export-ModuleMember -Function Add-GitSkipWorktreeFlag -Alias gignore
Export-ModuleMember -Function Remove-GitSkipWorktreeFlag -Alias gunignore
Export-ModuleMember -Function Get-GitIgnoredFiles -Alias gignored
Export-ModuleMember -Function Get-GitLogStylizedNameStatus -Alias gl
Export-ModuleMember -Alias glf
Export-ModuleMember -Function Get-GitLogStylizedGraph -Alias glg
Export-ModuleMember -Function Get-GitLogGraphOnelineStylized -Alias glgo
Export-ModuleMember -Function Get-GitLogStylizedGraphStat -Alias glgs
Export-ModuleMember -Function Get-GitLogOnelineStylized -Alias glo
Export-ModuleMember -Alias gloc
Export-ModuleMember -Function Get-GitLogStylized -Alias glog
Export-ModuleMember -Function Get-GitLogStylizedReverseNameStatus -Alias glr
Export-ModuleMember -Function Get-GitTrackedFiles -Alias gls
Export-ModuleMember -Function Invoke-GitMerge -Alias gm
Export-ModuleMember -Function Merge-GitRepositoryFromOriginBranchMain -Alias gmom
Export-ModuleMember -Function Merge-GitRepositoryFromUpstreamBranchMain -Alias gmum
Export-ModuleMember -Function Move-GitTrackedFiles -Alias gmv
Export-ModuleMember -Function Invoke-GitPush -Alias gp
Export-ModuleMember -Function Remove-GitRemoteBranchOrigin -Alias gpdo
Export-ModuleMember -Function Publish-GitCommitsForcefullyWithLease -Alias gpf
Export-ModuleMember -Function Publish-GitCommitsWithTags -Alias gpt
Export-ModuleMember -Function Update-GitRepository -Alias gpl
Export-ModuleMember -Function Update-GitBranchBaseFromRemote -Alias gplr
Export-ModuleMember -Function Update-GitRepositoryAndSubmodules -Alias gplrs
Export-ModuleMember -Function Reset-GitWorkingTreeToLastCommitAndUnstageChanges -Alias gr
Export-ModuleMember -Function Reset-GitWorkingTreeToLastCommitLoseChanges -Alias grhard
Export-ModuleMember -Function Reset-GitWorkingTreeToLastCommitAndKeepChanges -Alias grk
Export-ModuleMember -Function Reset-GitStagedChanges -Alias grs
Export-ModuleMember -Function git_reset_head_mixed -Alias grh
Export-ModuleMember -Function git_reset_head_hard -Alias grhhard
Export-ModuleMember -Function git_reset_head_keep -Alias grhk
Export-ModuleMember -Function git_reset_head_soft -Alias grhs
Export-ModuleMember -Function Update-GitBranchBaseFromBranchMain -Alias grbm
Export-ModuleMember -Function Invoke-GitRemote -Alias grem
Export-ModuleMember -Function Add-GitRemote -Alias grema
Export-ModuleMember -Function Remove-GitRemote -Alias gremrm
Export-ModuleMember -Function Set-GitRemoteUrl -Alias gremset
Export-ModuleMember -Function Show-GitRemote -Alias gremsh
Export-ModuleMember -Function Get-GitRemotesList -Alias gremv
Export-ModuleMember -Function Invoke-GitReflog -Alias grl
Export-ModuleMember -Function Get-GitStatus -Alias gs
Export-ModuleMember -Function Invoke-GitShowStylized -Alias gsh
Export-ModuleMember -Alias "gshsf", "gssll"
Export-ModuleMember -Function Invoke-GitStash -Alias gst
Export-ModuleMember -Function Use-GitStashEntry -Alias gsta
Export-ModuleMember -Function Remove-GitStashEntry -Alias gstd
Export-ModuleMember -Function Get-GitStashList -Alias "gstl", "gstls"
Export-ModuleMember -Function Push-GitStashEntry -Alias gstp
Export-ModuleMember -Function Pop-GitStashEntry -Alias gstpop
Export-ModuleMember -Function Get-GitStashDiffFromWorkingTree -Alias gstsl
Export-ModuleMember -Function Get-GitStashDiffFromParent -Alias gstsp
Export-ModuleMember -Function Invoke-GitSubmodule -Alias gsub
Export-ModuleMember -Function Add-GitSubmodule -Alias gsuba
Export-ModuleMember -Function Update-GitSubmoduleInit -Alias gsubi
Export-ModuleMember -Function Invoke-GitSubmoduleAllPull -Alias gsubpl
Export-ModuleMember -Function Invoke-GitSubmoduleAllPullOrigin -Alias gsubplom
Export-ModuleMember -Function Get-GitSubmoduleStatus -Alias gsubs
Export-ModuleMember -Function Update-GitSubmoduleFromRemoteMerge -Alias gsubu
Export-ModuleMember -Function Invoke-GitTag -Alias gt
Export-ModuleMember -Function Add-GitTagAnnotated -Alias gtam
Export-ModuleMember -Function Add-GitTagGpgSigned -Alias gtsm
Export-ModuleMember -Function Remove-GitTag -Alias gtd
Export-ModuleMember -Function Get-GitTagList -Alias "gtl", "gtls"
Export-ModuleMember -Function Get-GitWhatChangedStylized -Alias gwch
Export-ModuleMember -Function git_blame_line
Export-ModuleMember -Function git_checkout_parent
Export-ModuleMember -Function git_checkout_child
Export-ModuleMember -Function git_clone_and_cd
Export-ModuleMember -Function git_count
Export-ModuleMember -Function git_count_all
Export-ModuleMember -Function git_locate_string
Export-ModuleMember -Function git_log_file
Export-ModuleMember -Function Get-GitBranchDefault
Export-ModuleMember -Function git_reset_head
Export-ModuleMember -Function git_show_stash_file
Export-ModuleMember -Function git_status_short_with_loglines
Export-ModuleMember -Alias "pushgr", "cdgr"
