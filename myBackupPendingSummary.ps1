#requires -version 5.1

#get a report of pending files to be backed up

[CmdletBinding()]
[OutputType("pendingBackupSummary")]

Param(
    [parameter(position = 0)]
    [ValidateNotNullOrEmpty()]
    [String]$Backup = "*",

    [Parameter(HelpMessage = "Specify the location for the backup-log.csv files.")]
    [ValidateNotNullOrEmpty()]
    [ValidateScript( { Test-Path $_ })]
    [String]$BackupFolder = "D:\Backup"
)

$csv = Join-Path -Path $BackupFolder -ChildPath "$backup-log.csv"
Write-Verbose "Parsing CSV files $csv"

$f = Get-ChildItem -Path $csv | ForEach-Object {
    $p = $_.FullName
    Write-Verbose "Processing $p"
    Import-Csv -Path $p -OutVariable in | Add-Member -MemberType NoteProperty -Name Log -Value $p -PassThru
} | Where-Object { $_.IsFolder -eq 'False' }

Write-Verbose "Found $($in.count) files to import"
Write-Verbose "Getting unique file names from $($f.count) files"
$files = ($f.name | Select-Object -Unique).Foreach( { $n = $_; $f.where( { $_.name -eq $n }) |
        Sort-Object -Property { $_.date -as [DateTime] } | Select-Object -Last 1 })

Write-Verbose "Found $($files.count) unique files"

Write-Verbose "Grouping files"
$grouped = $files | Group-Object Log

$pendingFiles = foreach ($item in $grouped) {
    [PSCustomObject]@{
        PSTypeName = "pendingBackupFiles"
        Backup = (Get-Item $item.Name).basename.split("-")[0]
        Files  = $item.Count
        Size   = ($item.group | Measure-Object -Property size -Sum).sum
    }
} #foreach item

$totSize = ($pendingFiles.Size | Measure-Object -sum ).sum
[PSCustomObject]@{
    PSTypeName = "pendingBackupSummary"
    TotalFiles  = ($grouped | Measure-Object -Property count -Sum).sum
    TotalSizeKB = [math]::round($totSize/ 1KB, 4)
    PendingFiles = $pendingFiles
}


Write-Verbose "Pending report finished"
