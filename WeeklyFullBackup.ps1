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

$sets = C:\scripts\PSBackup\BuildList.ps1 -PathList $PathList -Destination $Destination

foreach ($set in $sets) {
    c:\scripts\PSBackup\Invoke-FullBackup.ps1 -path $set
}

# 8/4/2022 Copy Quickbook Backups to Box
Get-ChildItem D:\OneDrive\Backup\*.qbb | Copy-Item -Destination 'C:\users\jeff\Box\Default Sync Folder\'
