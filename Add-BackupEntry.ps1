#requires -version 5.1

Function Add-BackupEntry {

<# PSFunctionInfo

Version 1.4.1
Author Jeffery Hicks
CompanyName JDH IT Solutions, Inc.
Copyright (c) 2020-2021 JDH IT Solutions, Inc.
Description Add an entry to one of my backup CSV files
Guid a6c22223-4f16-4ad2-a3ff-b27e374ce52a
Tags profile,backup
LastUpdate 1/24/2021 4:29 PM
Source C:\scripts\PSBackup\Add-BackupEntry.ps1

#>
    [CmdletBinding(SupportsShouldProcess)]
    [Alias("abe")]
    [OutputType("none")]
    Param(
        [Parameter(Position = 1, Mandatory, ValueFromPipeline)]
        [ValidateScript({Test-Path $_})]
        [String]$Path,

        [Parameter(Position = 0,Mandatory)]
        #I'm using a dynamic argument completer instead of the old validate set
        #[ValidateSet("Scripts","Dropbox","Documents","GoogleDrive","jdhit")]
        [ArgumentCompleter({(Get-ChildItem D:\backup\*.csv).name.foreach({($_ -split "-")[0]})})]
        [alias("set")]
        [ValidateNotNullOrEmpty()]
        [String]$BackupSet
    )

    Begin {
        Write-Verbose "[BEGIN  ] Starting: $($MyInvocation.MyCommand)"
        $csvFile = "D:\Backup\$BackupSet-log.csv"
        $add = @()
    } #begin

    Process {
        $cPath = Convert-Path $path
        Write-Verbose "[PROCESS] Adding: $cPath"

        $file = Get-Item $cPath
        #the Google Drive path is different than the BackupSet name
        if ($BackupSet -eq 'GoogleDrive') {
            $BackupSet = "Google Drive"
        }
        $add += [PSCustomObject]@{
            ID        = 99999
            Date      = $file.LastWriteTime
            Name      = ($file.FullName -split "$BackupSet\\")[1]
            IsFolder  = "False"
            Directory = $file.DirectoryName
            Size      = $file.length
            Path      = $file.FullName
        }
    } #process
    End {
        if ($add.count -gt 0) {
            Write-Verbose "[END    ] Exporting $($add.count) entries to $CSVFile"
            $add | Out-String | Write-Verbose
            $add | Export-Csv -Path $CSVFile -Append -NoTypeInformation
        }
        Write-Verbose "[END    ] Ending: $($MyInvocation.MyCommand)"
    } #end
}

<#
    ID        : 13669)
    Date      : 11/5/2019 5:02:32 PM
    Name      : ps-regex\Module-4
    IsFolder  : True
    Directory :
    Size      : 1
    Path      : C:\Scripts\ps-regex\Module-4
#>
