#requires -version 5.1
#requires -module BurntToast,PSScriptTools

#backup files from CSV change logs
#the CSV files should already follow path exclusions in Exclude.txt

<#
option to get last version of each file as an alternative to using Group-Object

foreach ($name in (Import-CSV D:\Backup\Scripts-log.csv -OutVariable in | Select-Object Name -Unique).name) {
 $in | where {$_.name -EQ $name} | sort-object -Property ID | Select-Object -last 1
}
#>

[cmdletbinding(SupportsShouldProcess)]
Param(
    [Parameter(HelpMessage = "Specify the location of the CSV files with incremental backup changes.")]
    [ValidateScript({Test-Path $_})]
    [string]$BackupPath = "D:\Backup"
)
#create a transcript log file
$log = New-CustomFileName -Template "DailyIncremental_%year%month%day%hour%minute.txt"
$logpath = Join-Path -Path D:\temp -ChildPath $log
$codeDir = "C:\scripts\PSBackup"
Start-Transcript -Path $logpath

Write-Host "[$(Get-Date)] Starting Daily Incremental" -ForegroundColor Cyan

#this is my internal archiving code. You can use whatever you want.
Try {
    #Import-Module C:\scripts\PSRAR\Dev-PSRar.psm1 -Force -ErrorAction Stop
    Import-Module $codeDir\PSRar.psm1 -Force -ErrorAction Stop
}
Catch {
    Write-Warning "Failed to import PSRar module at $codeDir\PSRar.psm1."
    #bail out if the module fails to load
    return
}

#get the CSV files
$paths = (Get-ChildItem -Path "$BackupPath\*.csv").Fullname

foreach ($path in $paths) {

    $name = (Split-Path -Path $Path -Leaf).split("-")[0]
    $files = Import-Csv -Path $path |
        Where-Object { ($_.name -notmatch "~|\.tmp") -AND ($_.size -gt 0) -AND ($_.IsFolder -eq 'False') -AND (Test-Path $_.path) } |
        Select-Object -Property path, size, directory, isfolder, ID | Group-Object -Property Path

    foreach ($file in $files) {
        $parentFolder = $file.group[0].directory
        #Create a temporary folder for backing up the day's files
        $relPath = Join-Path -Path "D:\backtemp\$Name" -ChildPath $parentFolder.Substring(3)

        if (-Not (Test-Path -Path $relpath)) {
            Write-Host "[$(Get-Date)] Creating $relpath" -ForegroundColor cyan
            $new = New-Item -Path $relpath -ItemType directory -Force
            Start-Sleep -Milliseconds 100

            #copy hidden attributes
            $attrib = (Get-Item $parentfolder -Force).Attributes
            if ($attrib -match "hidden") {
                Write-Host "[$(Get-Date)] Copying attributes from $parentfolder to $($new.FullName)" -ForegroundColor yellow
                Write-Host $attrib -ForegroundColor yellow
                (Get-Item $new.FullName -Force).Attributes = $attrib
            }
        }
        Write-Host "[$(Get-Date)] Copying $($file.name) to $relpath" -ForegroundColor green
        $f = Copy-Item -Path $file.Name -Destination $relpath -Force -PassThru
        #copy attributes
        $f.Attributes = (Get-Item $file.name -Force).Attributes
    } #foreach file

    #create a RAR archive or substitute your archiving code
    $archive = Join-Path -Path D:\BackTemp -ChildPath "$(Get-Date -Format yyyyMMdd)_$name-INCREMENTAL.rar"
    Add-RARContent -Object $relPath -Archive $archive -CompressionLevel 5 -Comment "Incremental backup $(Get-Date)"
    Write-Host "[$(Get-Date)] Moving $archive to NAS" -fore green
    Move-Item -Path $archive -Destination \\ds416\backup -Force

    Write-Host "[$(Get-Date)] Removing $path" -fore yellow
    Remove-Item $path

} #foreach path

Write-Host "[$(Get-Date)] Removing temporary Backup folders" -fore yellow
Get-ChildItem -Path D:\BackTemp -Directory | Remove-Item -Force -Recurse

$newFiles = Get-ChildItem -Path \\ds416\backup\*incremental.rar | Where-Object LastWriteTime -GE (Get-Date).Date
#send a toast notification
$btText = @"
Backup Task Complete

Created $($newfiles.count) files.
View log at $logpath
"@

#$newfiles | Foreach-Object { $btText+= "$($_.name)`n"}

$params = @{
    Text    = $btText
    Header  = $(New-BTHeader -Id 1 -Title "Daily Incremental Backup")
    Applogo = "c:\scripts\db.png"
}

New-BurntToastNotification @params

Write-Host "[$(Get-Date)] Ending Daily Incremental" -ForegroundColor cyan
Stop-Transcript