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

    [CmdletBinding(DefaultParameterSetName = "default")]
    [alias("gbf")]
    [OutputType("myBackupFile")]

    Param(
        [Parameter(Position = 0, HelpMessage = "Enter the path where the backup files are stored.", ParameterSetName = "default")]
        [ValidateNotNullOrEmpty()]
        [ValidateScript( { Test-Path $_ })]
        #This is my NAS device
        [String]$Path = "\\DSTulipwood\backup",
        [Parameter(HelpMessage = "Get only Incremental backup files")]
        [Switch]$IncrementalOnly,
        [Parameter(HelpMessage = "Get the last X number of raw files")]
        [ValidateScript({$_ -ge 1})]
        [Int]$Last,
        [Parameter(HelpMessage = "Get files created yesterday")]
        [Switch]$Yesterday
        )

        #convert path to a full filesystem path
        $Path = Convert-Path $path
        Write-Verbose "Starting $($MyInvocation.MyCommand)$ReportVer"
        Write-Verbose "Using parameter set $($PSCmdlet.ParameterSetName)"

        [regex]$rx = "^20\d{6}_(?<set>\w+)-(?<type>\w+)\.((rar)|(zip))$"

        <#
        I am doing some 'pre-filtering' on the file extension and then using the regular
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
            $item.PSObject.TypeNames.Insert(0,"myBackupFile")
        }

        if ($Yesterday) {
            $yd = (Get-Date).AddDays(-1).Date
            $files = $files | Where-Object {$_.LastWriteTime -ge $yd}
        }
        if ($Last -gt 0) {
            $files | Sort-Object Created | Select-Object -Last $last
        }
        else {
            $files | Sort-Object BackupSet,Created
        }
} #end Get-MyBackupFile

#define some alias properties for the custom object type
Update-TypeData -TypeName "myBackupFile" -MemberType AliasProperty -memberName Size -Value Length -force
Update-TypeData -TypeName "myBackupFile" -MemberType AliasProperty -memberName Created -Value CreationTime -force

#load the custom format file
Update-FormatData $PSScriptRoot\mybackupfile.format.ps1xml
