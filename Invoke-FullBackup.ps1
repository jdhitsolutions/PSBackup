#requires -version 5.1
#requires -module BurntToast,PSScriptTools

[CmdletBinding(SupportsShouldProcess, DefaultParameterSetName = "list")]
Param(
    [Parameter(Position = 0, HelpMessage = "Path to a text file with folders to backup.", ParameterSetName = "List")]
    [ValidateNotNullOrEmpty()]
    [ValidateScript( { Test-Path $_ })]
    [String]$PathList = "c:\scripts\PSBackup\mybackupPaths.txt",

    [Parameter(Position = 0, HelpMessage = "Specify a single folder to backup", ParameterSetName = "Single")]
    [ValidateScript( { Test-Path $_ })]
    [String]$Path,

    [Parameter(Position = 0, HelpMessage = "The destination folder for the backup files")]
    [ValidateNotNullOrEmpty()]
    [String]$Destination = "\\DSTulipwood\backup"
)

<#
I am hardcoding the path to scripts because when I
run this as a scheduled job, there is no $PSScriptRoot or $MyInvocation
#>
#create a transcript log file
$log = New-CustomFileName -Template "WeeklyFull_%year%month%day%hour%minute%seconds-%###.txt"
#11/6/2023 Changed Backup log path so the files don't get removed on reboot
$LogPath = Join-Path -Path D:\backupLogs -ChildPath $log
Start-Transcript -Path $LogPath

#refresh NAS Credential
cmdkey /add:DSTulipwood /user:Jeff /pass:(Get-Content C:\scripts\tulipwood.txt | Unprotect-CmsMessage)

$codeDir = "C:\scripts\PSBackup"

Write-Host "[$(Get-Date)] Starting Weekly Full Backup" -ForegroundColor green
Write-Host "[$(Get-Date)] Setting location to $codeDir" -ForegroundColor yellow
Set-Location $CodeDir

#import my custom module
Try {
    Import-Module $codeDir\PSRar.psm1 -Force -ErrorAction Stop
}
Catch {
    Write-Warning "Failed to import PSRar module at $codeDir\PSRar.psm1."
    #bail out if the module fails to load
    return
}

If ($PSCmdlet.ParameterSetName -eq "list") {
    Write-Host "[$(Get-Date)] Getting backup paths" -ForegroundColor yellow
    #filter out blanks and commented lines
    $paths = Get-Content $PathList | Where-Object { $_ -match "(^[^#]\S*)" -and $_ -notmatch "^\s+$" }
} #if mybackup paths file
elseif ($PSCmdlet.ParameterSetName -eq 'single') {
    $paths = $Path
}

$paths | ForEach-Object {
    if ($PSCmdlet.ShouldProcess($_)) {
        Try {
            #invoke a control script using my custom module
            Write-Host "[$(Get-Date)] Backing up $_" -ForegroundColor yellow
            #this is my wrapper script using WinRar to create the archive.
            #you can use whatever tool you want in its place.
            &"$CodeDir\RarBackup.ps1" -Path $_ -ErrorAction Stop -Verbose
            $ok = $True
        }
        Catch {
            $ok = $False
            Write-Warning $_.exception.message
        }
    } #what if

    #clear corresponding incremental log files
    $name = ((Split-Path $_ -Leaf).replace(' ', ''))
    #specify the directory for the CSV log files
    $log = "D:\Backup\{0}-log.csv" -f $name

    if ($OK -AND (Test-Path $log) -AND ($PSCmdlet.ShouldProcess($log, "Clear Log"))) {
        Write-Host "[$(Get-Date)] Removing $log" -ForegroundColor yellow
        Remove-Item -Path $log
    } #WhatIf

    #clear incremental backups
    $target = Join-Path -Path $Destination -ChildPath "*_$name-incremental.rar"
    if ($ok -AND ($PSCmdlet.ShouldProcess($target, "Clear Incremental BackUps"))) {
        Write-Host "[$(Get-Date)] Removing $Target" -ForegroundColor yellow
        Remove-Item $target
    } #WhatIf

    #trim old backups
    Write-Host "[$(Get-Date)] Trimming backups from $Destination" -ForegroundColor yellow
    if ($OK -and ($PSCmdlet.ShouldProcess($Destination, "Trim backups"))) {
        &"$CodeDir\mybackuptrim.ps1" -path $Destination -count 2
    } #WhatIf

    #I am also backing up a smaller subset to OneDrive
    Write-Host "[$(Get-Date)] Trimming backups from $env:OneDriveConsumer\backup" -ForegroundColor yellow
    if ($OK -and ($PSCmdlet.ShouldProcess("OneDrive", "Trim backups"))) {
        &"$CodeDir\mybackuptrim.ps1" -path $env:OneDriveConsumer\backup -count 1
    }
} #foreach path

#send a toast notification
$params = @{
    Text    = "Backup Task Complete. View log at $LogPath"
    Header  = $(New-BTHeader -Id 1 -Title "Weekly Full Backup")
    AppLogo = "c:\scripts\db.png"
}

Write-Host "[$(Get-Date)] Ending Weekly Full Backup" -ForegroundColor green

#don't run if using -WhatIf
if (-Not $WhatIfPreference) {
    New-BurntToastNotification @params
    Stop-Transcript
}
