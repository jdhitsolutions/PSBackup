#requires -version 5.1
#requires -module BurntToast,PSScriptTools

#only do a full backup if there was an incremental

[CmdletBinding(SupportsShouldProcess)]
Param(
    [Parameter(Position = 0, HelpMessage = "Path to a text file with folders to backup.")]
    [ValidateNotNullOrEmpty()]
    [ValidateScript( { Test-Path $_ })]
    [String]$PathList = "c:\scripts\PSBackup\mybackupPaths.txt",

    [Parameter(Position = 1, HelpMessage = "The destination folder for the backup files")]
    [ValidateNotNullOrEmpty()]
    [String]$Destination = "\\DSTulipwood\backup"
)

#verify credential
C:\scripts\Test-DSTulipwood.ps1
$VerbosePreference = "Continue"

Write-Verbose "[$(Get-Date)] Starting $($MyInvocation.MyCommand)"
Write-Verbose "[$(Get-Date)] Creating Sets list"
$sets = C:\scripts\PSBackup\BuildList.ps1 -PathList $PathList -Destination $Destination

#it is possible there will be no backup set
if ($sets.count -gt 0) {
    foreach ($set in $sets) {
        Write-Verbose "[$(Get-Date)] Invoking backup for $set"
        #8/17/2024 Pass the destination to the backup script
        c:\scripts\PSBackup\Invoke-FullBackup.ps1 -path $set -Destination $Destination
    }
}
#1/26/2024 Remove Box Sync Folder

<# # 8/4/2022 Copy Quickbook Backups to Box
if (Test-Path 'C:\users\jeff\Box\Default Sync Folder\') {
    Get-ChildItem D:\OneDrive\Backup\*.qbb | Copy-Item -Destination 'C:\users\jeff\Box\Default Sync Folder\'
}
else {
    Write-Warning "[$(Get-Date)] Can't verify Box folder."
} #>

Write-Verbose "[$(Get-Date)] Ending $($MyInvocation.MyCommand)"

$VerbosePreference = "SilentlyContinue"