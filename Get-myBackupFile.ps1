Function Get-MyBackupFile {

<# PSFunctionInfo

Version 1.0.0
Author Jeffery Hicks
CompanyName JDH IT Solutions, Inc.
Copyright (c) 2021 JDH IT Solutions, Inc.
Description Get my backup files.
Guid 74dc584d-a1e1-43e5-a5c9-b494d1971f8d
Tags profile,backup
LastUpdate 1/19/2021 3:14 PM
Source C:\scripts\PSBackup\Get-MyBackupFile.ps1

#>

    [cmdletbinding(DefaultParameterSetName = "default")]
    [alias("gbf")]
    [outputType("myBackupFile")]

    Param(
        [Parameter(Position = 0, HelpMessage = "Enter the path where the backup files are stored.", ParameterSetName = "default")]
        [ValidateNotNullOrEmpty()]
        [ValidateScript( { Test-Path $_ })]
        #This is my NAS device
        [string]$Path = "\\ds416\backup",
        [Parameter(HelpMessage = "Get only Incremental backup files")]
        [switch]$IncrementalOnly,
        [Parameter(HelpMessage = "Get the last X number of raw files")]
        [ValidateScript({$_ -ge 1})]
        [int]$Last
        )

        #convert path to a full filesystem path
        $Path = Convert-Path $path
        Write-Verbose "Starting $($myinvocation.mycommand)$ReportVer"
        Write-Verbose "Using parameter set $($pscmdlet.ParameterSetName)"

        [regex]$rx = "^20\d{6}_(?<set>\w+)-(?<type>\w+)\.((rar)|(zip))$"

        <#
        I am doing so 'pre-filtering' on the file extension and then using the regular
        expression filter to fine tune the results
        #>
        Write-Verbose "Getting zip and rar files from $Path"
        $all = Get-ChildItem $Path\*.zip, $Path\*.rar
        if ($IncrementalOnly) {
            $files = $all.Where({ $_.name -match "Incremental" })
        }
        else {
            $files = $all.where({ $rx.IsMatch($_.name)})
        }

        if ($files.count -eq 0) {
            Write-Warning "No backup files found in $Path"
            return
        }

        Write-Verbose "Found $($files.count) matching files in $Path"
        foreach ($item in $files) {
            $BackupSet = $rx.matches($item.name).groups[4].value
            $settype = $rx.matches($item.name).groups[5].value

            #add some custom properties to be used with formatted results based on named captures
            $item | Add-Member -MemberType NoteProperty -Name BackupSet -Value $BackupSet -force
            $item | Add-Member -MemberType NoteProperty -Name SetType -Value $setType -force
            #insert a custom type name
            $item.psobject.TypeNames.Insert(0,"myBackupFile")
        }

        if ($Last -gt 0) {
            $files | Sort-object Created | Select-object -Last $last
        }
        else {
            $files | Sort-Object BackupSet,Created
        }
} #end Get-MyBackupFile

#define some alias properties for the custom object type
Update-TypeData -typename "myBackupFile" -MemberType AliasProperty -memberName Size -Value Length -force
Update-TypeData -typename "myBackupFile" -MemberType AliasProperty -memberName Created -Value CreationTime -force
#load the custom format file
Update-FormatData $PSScriptRoot\mybackupfile.format.ps1xml