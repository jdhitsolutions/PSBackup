#build the full backup list

[CmdletBinding()]
Param(
    [Parameter(Position = 0, HelpMessage = "Path to a text file with folders to backup.")]
    [ValidateNotNullOrEmpty()]
    [ValidateScript( { Test-Path $_ })]
    [String]$PathList = "c:\scripts\PSBackup\mybackupPaths.txt",

    [Parameter(Position = 1, HelpMessage = "The destination folder for the backup files")]
    [ValidateNotNullOrEmpty()]
    [String]$Destination = "\\DSTulipwood\backup"
)

#regex to match on set name from RAR file
[regex]$rx = "(?<=_)\w+(?=\-)"

$sets = Get-ChildItem $Destination\*incremental.rar |
Select-Object -Property @{Name = "Set"; Expression = { $rx.Match($_.name).Value } } |
Select-Object -expand Set | Select-Object -Unique

Write-Verbose "Found incremental backups for $($sets -join ',') "
#get set name from pending log that may not have been backed up yet

Write-Verbose "Checking pending backups"

$csv = Get-ChildItem D:\Backup\*.csv | ForEach-Object { $_.BaseName.split("-")[0]}
foreach ($item in $csv) {
    if ($sets -notcontains $item) {
        Write-Verbose "Adding $item to backup set"
        $sets+=$item
    }
}

#build the list
foreach ($set in $sets) {
    Write-Verbose "Searching for $set path"
    #match on the first 4 characters of the set name
    $mtch = $set.substring(0,4)
    $Path = (Get-Content C:\scripts\psbackup\myBackupPaths.txt | Select-String $mtch).line
    Write-Verbose "Backing up $Path"
    $Path
}
