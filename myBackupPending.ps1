#requires -version 5.1

#get a report of pending files to be backed up

[cmdletbinding()]

Param(
    [parameter(position = 0)]
    [ValidateNotNullOrEmpty()]
    [string]$Backup = "*",

    [Parameter(HelpMessage = "Show raw objects, not a formatted report.")]
    [switch]$Raw,

    [Parameter(HelpMessage = "Specify the location for the backup-log.csv files.")]
    [ValidateNotNullOrEmpty()]
    [ValidateScript({Test-Path $_})]
    [string]$BackupFolder = "D:\Backup"
)

$csv = Join-Path -Path $BackupFolder -ChildPath "$backup-log.csv"
Write-Verbose "Parsing CSV files $csv"

$f = Get-ChildItem -path $csv | ForEach-Object {
    $p = $_.fullname
    Write-Verbose "Processing $p"
    Import-Csv -Path $p | Add-Member -MemberType NoteProperty -Name Log -value $p -PassThru
} | Where-Object { ([int32]$_.Size -gt 0) -AND ($_.IsFolder -eq 'False') }

Write-Verbose "Getting unique file names from $($f.count) files"
$files = ($f.name | Select-Object -Unique).Foreach( {$n = $_; $f.where( { $_.name -eq $n }) |
Sort-Object -Property {$_.date -as [datetime] } | Select-Object -last 1 })

Write-Verbose "Found $($files.count) unique files"

if ($raw) {
    Write-Verbose "Displaying raw file data"
    $files
}
else {
    Write-Verbose "Grouping files"
    $grouped = $files | Group-Object Log
    
    Write-Verbose "Display formatted results"
    $files |
    Sort-Object -Property Log, Directory, Name |
    Format-Table -GroupBy log -Property Date, Name, Size, Directory

    $summary = foreach ($item in $grouped) {
        [PSCustomObject]@{
            Backup = (Get-Item $item.Name).basename.split("-")[0]
            Files  = $item.Count
            Size   = ($item.group | Measure-Object -Property size -sum).sum
        }
    } #foreach item

    $total = [PSCustomObject]@{
        TotalFiles  = ($grouped | Measure-Object -property count -sum).sum
        TotalSizeMB = [math]::round(($summary.size | Measure-Object -sum).sum / 1MB, 4)
    }
    Write-Host "Incremental Pending Backup Summary" -ForegroundColor cyan
    ($summary | Format-Table | Out-String).TrimEnd() | Write-Host -ForegroundColor cyan

    $total | Format-Table  | Out-String | Write-Host -ForegroundColor cyan
}

Write-Verbose "Pending report finished"
