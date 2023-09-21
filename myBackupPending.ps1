#requires -version 5.1

#get a report of pending files to be backed up

[CmdletBinding()]

Param(
    [parameter(position = 0)]
    [ValidateNotNullOrEmpty()]
    [String]$Backup = "*",

    [Parameter(HelpMessage = "Specify the location for the backup-log.csv files.")]
    [ValidateNotNullOrEmpty()]
    [ValidateScript({Test-Path $_})]
    [String]$BackupFolder = "D:\Backup"
)

$csv = Join-Path -Path $BackupFolder -ChildPath "$backup-log.csv"
Write-Verbose "Parsing CSV files $csv"

$f = Get-ChildItem -path $csv | ForEach-Object {
    $p = $_.FullName
    Write-Verbose "Processing $p"
    Import-Csv -Path $p -OutVariable in | Add-Member -MemberType NoteProperty -Name Log -value $p -PassThru
} | Where-Object { $_.IsFolder -eq 'False' }

Write-Verbose "Found $($in.count) files to import"
Write-Verbose "Getting unique file names from $($f.count) files"
$files = ($f.name | Select-Object -Unique).Foreach({
    $n = $_;
    $f.where({ $_.name -eq $n }) |
Sort-Object -Property {$_.date -as [DateTime] } | Select-Object -last 1 })

Write-Verbose "Found $($files.count) unique files"

$files | ForEach-Object {
    #insert a new TypeName
    $_.PSObject.TypeNames.insert(0,'pendingFile')
    $_ | Add-Member -MemberType ScriptProperty -Name Set -value {(split-path $this.log -Leaf).split("-")[0] }
    $_ | Add-Member -MemberType ScriptProperty -Name FileName -Value {Split-Path $this.path -leaf} -PassThru
} | Sort-Object -Property Log, Directory, Name

Write-Verbose "Pending report finished"
