# requires -version 5.1

[cmdletbinding()]

Param(
    [Parameter(Position = 0, HelpMessage = "Enter the path where the backup files are stored.")]
    [ValidateNotNullOrEmpty()]
    [ValidateScript({Test-Path $_ })]
    #This is my NAS device
    [string]$Path = "\\ds416\backup",
    [Parameter(HelpMessage = "Get backup files only with no formatted output.")]
    [Switch]$Raw
)

$reportVer = "1.1"

Write-Verbose "Starting $($myinvocation.mycommand) ver. $ReportVer"
<#
 A regular expression pattern to match on backup file name with named captures
 to be used in adding some custom properties. My backup names are like:

  20191101_Scripts-FULL.rar
  20191107_Scripts-INCREMENTAL.rar

#>

[regex]$rx = "^20\d{6}_(?<set>\w+)-(?<type>\w+)\.((rar)|(zip))$"

<#
I am doing so 'pre-filtering' on the file extension and then using the regular
expression filter to fine tune the results
#>
$files = Get-ChildItem $Path\*.zip,$Path\*.rar | Where-Object {$rx.IsMatch($_.name) }
Write-Verbose "Found $($files.count) files in $Path"

#add some custom properties to be used with formatted results based on named captures
foreach ($item in $files) {
    $setpath = $rx.matches($item.name).groups[4].value
    $settype = $rx.matches($item.name).groups[5].value

    $item | Add-Member -MemberType NoteProperty -Name SetPath -Value $setpath
    $item | Add-Member -MemberType NoteProperty -Name SetType -Value $setType
}

if ($raw) {
    $Files | Sort-Object -Property LastWriteTime
}
else {
    Write-Verbose "Preparing report data"
    $files | Sort-Object SetPath, SetType, LastWriteTime | Format-Table -GroupBy SetPath -Property LastWriteTime, Length, Name
    $grouped = $files | Group-Object SetPath
    $summary = foreach ($item in $grouped) {
        [pscustomobject]@{
            BackupSet = $item.name
            Files  = $item.Count
            Size   = ($item.group | Measure-Object -Property size -sum).sum
        }
    }

    $total = [PSCustomObject]@{
        TotalFiles = ($grouped | Measure-Object -property count -sum).sum
        TotalSizeMB = [math]::round(($summary.size | Measure-Object -sum).sum/1MB,4)
    }
    Write-Host "Backup Summary $((Get-Date).ToShortDateString())" -ForegroundColor yellow
    ($summary | sort-object Size -Descending| Format-Table | Out-String).TrimEnd() | Write-Host -ForegroundColor yellow

    ($total | Format-Table  | Out-String).TrimEnd() | Write-Host -ForegroundColor yellow
}

"$([char]0x1b)[38;5;216mReport version $reportver$([char]0x1b)[0m"