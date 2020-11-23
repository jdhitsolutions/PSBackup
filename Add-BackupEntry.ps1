#requires -version 5.1

Function Add-BackupEntry {

<# PSFunctionInfo

Version 1.1.0
Author Jeffery Hicks
CompanyName JDH IT Solutions, Inc.
Copyright (c) 2020 JDH IT Solutions, Inc.
Description Add an entry to one of my backup CSV files
Guid a6c22223-4f16-4ad2-a3ff-b27e374ce52a
Tags profile,backup
LastUpdate 03/31/2020 12:30:08
Source C:\scripts\PSBackup\Add-BackupEntry.ps1

#>
    [cmdletbinding(SupportsShouldProcess)]
    Param(
        [Parameter(Position = 0, Mandatory, ValueFromPipeline)]
        [string]$Path,
        [Parameter(Mandatory)]
        #I'm using a dynamic argument completer instead of the old validate set
        #[ValidateSet("Scripts","Dropbox","Documents","GoogleDrive","jdhit")]
        [Argumentcompleter({(Get-Childitem D:\backup\*.csv).name.foreach( {($_ -split "-")[0]})})]
        [string]$BackupSet
    )

    Begin {
        Write-Verbose "[BEGIN  ] Starting: $($MyInvocation.Mycommand)"
        $csvFile = "D:\Backup\$BackupSet-log.csv"
        $add = @()
    } #begin

    Process {
        Write-Verbose "[PROCESS] Adding: $Path"

        $file = Get-Item $Path
        $add += [pscustomobject]@{
            ID        = 99999
            Date      = $file.LastWriteTime
            Name      = ($file.fullname -split "$BackupSet\\")[1]
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
        Write-Verbose "[END    ] Ending: $($MyInvocation.Mycommand)"
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
