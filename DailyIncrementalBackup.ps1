#requires -version 5.1
#requires -module BurntToast,PSScriptTools

#backup files from CSV change logs
#the CSV files should already follow path exclusions in Exclude.txt

<#
this is another way to get last version of each file instead of using Group-Object

foreach ($name in (Import-CSV D:\Backup\Scripts-log.csv -OutVariable in | Select-Object Name -Unique).name) {
$in | where {$_.name -EQ $name} | sort-object -Property ID | Select-Object -last 1
}
#>

[CmdletBinding(SupportsShouldProcess)]
Param(
    [Parameter(HelpMessage = 'Specify the location of the CSV files with incremental backup changes.')]
    [ValidateScript({ Test-Path $_ })]
    [String]$BackupPath = 'D:\Backup'
)
#create a transcript log file
$log = New-CustomFileName -Template 'DailyIncremental_%year%month%day%hour%minute.txt'
#11/6/2023 Changed Backup log path so the files don't get removed on reboot
$LogPath = Join-Path -Path D:\backupLogs -ChildPath $log
$codeDir = 'C:\scripts\PSBackup'
Start-Transcript -Path $LogPath

#refresh NAS Credential
cmdkey /add:DSTulipwood /user:Jeff /pass:(Get-Content C:\scripts\tulipwood.txt | Unprotect-CmsMessage)

Write-Host "[$(Get-Date)] Starting Daily Incremental" -ForegroundColor Cyan

#this is my internal archiving code. You can use whatever you want.
Try {
    Import-Module $codeDir\PSRar.psm1 -Force -ErrorAction Stop
}
Catch {
    Write-Warning "Failed to import PSRar module at $codeDir\PSRar.psm1."
    #bail out if the module fails to load
    return
}

#get the CSV files
$paths = (Get-ChildItem -Path "$BackupPath\*.csv").FullName

foreach ($path in $paths) {
    $name = (Split-Path -Path $Path -Leaf).split('-')[0]
    $files = Import-Csv -Path $path |
    Where-Object { ($_.name -notmatch '~|\.tmp') -AND ($_.size -gt 0) -AND ($_.IsFolder -eq 'False') -AND (Test-Path $_.path) } |
    Select-Object -Property path, size, directory, IsFolder, ID | Group-Object -Property Path

    $tmpParent = Join-Path -Path D:\BackTemp -ChildPath $name

    foreach ($file in $files) {
        $ParentFolder = $file.group[0].directory
        #Create a temporary folder for backing up the day's files
        $RelPath = Join-Path -Path $tmpParent -ChildPath $ParentFolder.Substring(3)

        if (-Not (Test-Path -Path $RelPath)) {
            Write-Host "[$(Get-Date)] Creating $RelPath" -ForegroundColor cyan
            $new = New-Item -Path $RelPath -ItemType directory -Force
            Start-Sleep -Milliseconds 100

            #copy hidden attributes
            $attrib = (Get-Item $ParentFolder -Force).Attributes
            if ($attrib -match 'hidden') {
                Write-Host "[$(Get-Date)] Copying attributes from $ParentFolder to $($new.FullName)" -ForegroundColor yellow
                Write-Host $attrib -ForegroundColor yellow
                (Get-Item $new.FullName -Force).Attributes = $attrib
            }
        }
        Write-Host "[$(Get-Date)] Copying $($file.name) to $RelPath" -ForegroundColor green
        $f = Copy-Item -Path $file.Name -Destination $RelPath -Force -PassThru
        #copy attributes
        if ($PSCmdlet.ShouldProcess($f.name, 'Copy Attributes')) {
            $f.Attributes = (Get-Item $file.name -Force).Attributes
        }
    } #foreach file

    #create a RAR archive or substitute your archiving code
    $archive = Join-Path -Path D:\BackTemp -ChildPath "$(Get-Date -Format yyyyMMdd)_$name-INCREMENTAL.rar"
    #get some stats about the data to be archived
    $stats = Get-ChildItem -Path $tmpParent -File -Recurse | Measure-Object -Property length -Sum
    Write-Host "[$(Get-Date)] Creating $archive from $tmpParent" -fore green
    Write-Host "[$(Get-Date)] $($stats.count) files totaling $($stats.sum)" -fore green

    # for debugging
    #Pause

    $addParams = @{
        Object      = $tmpParent
        Archive     = $archive
        Comment     = "Incremental backup $(Get-Date)"
        excludeFile = 'C:\scripts\PSBackup\exclude.txt'
        verbose     = $True
    }
    Add-RARContent @addParams

    Write-Host "[$(Get-Date)] Moving $archive to NAS" -fore green
    if ($PSCmdlet.ShouldProcess($archive, 'Move file')) {
        if (Test-Path \\DSTulipwood\backup) {
            Try {
                Move-Item -Path $archive -Destination \\DSTulipwood\backup -Force -ErrorAction Stop
                #only remove the file if it was successfully moved to the NAS
                Write-Host "[$(Get-Date)] Removing $path" -fore yellow
                if ($PSCmdlet.ShouldProcess($path, 'Remove file')) {
                    Remove-Item $path
                }
            }
            Catch {
                Write-Warning "Failed to move $archive to \\DSTulipwood\Backup. $($_.Exception.Message)"
            }
        }
        else {
            #failed to connect to NAS
            Write-Host "[$(Get-Date)] Failed to verify \\DSTulipwood\Backup" -fore red
            Write-Verbose 'Failed to verify \\DSTulipwood\Backup'
        }
    } #whatIf

} #foreach path

Write-Host "[$(Get-Date)] Removing temporary Backup folders" -fore yellow
Get-ChildItem -Path D:\BackTemp -Directory | Remove-Item -Force -Recurse

$NewFiles = Get-ChildItem -Path \\DSTulipwood\backup\*incremental.rar | Where-Object LastWriteTime -GE (Get-Date).Date
#send a toast notification
$btText = @"
Backup Task Complete

Created $($NewFiles.count) files.
View log at $LogPath
"@

#$NewFiles | ForEach-Object { $btText+= "$($_.name)`n"}

$params = @{
    Text    = $btText
    Header  = $(New-BTHeader -Id 1 -Title 'Daily Incremental Backup')
    AppLogo = 'c:\scripts\db.png'
}

if ($PSCmdlet.ShouldProcess($LogPath, 'Send Toast Notification')) {
    New-BurntToastNotification @params
}

Write-Host "[$(Get-Date)] Ending Daily Incremental" -ForegroundColor cyan
Stop-Transcript
