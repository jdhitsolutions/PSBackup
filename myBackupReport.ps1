#requires -version 5.1
#requires -module PSScriptTools

#myBackupReport.ps1

# this script uses Format-Value from the PSScriptTools module.
[cmdletbinding(DefaultParameterSetName="default")]

Param(
    [Parameter(Position = 0, HelpMessage = "Enter the path where the backup files are stored.",ParameterSetName="default")]
    [Parameter(ParameterSetName = "raw")]
    [Parameter(ParameterSetName = "sumOnly")]
    [ValidateNotNullOrEmpty()]
    [ValidateScript({Test-Path $_ })]
    #This is my NAS device
    [string]$Path = "\\ds416\backup",

    [Parameter(HelpMessage = "Only display the summary",ParameterSetName = "sumOnly")]
    [switch]$SummaryOnly,

    [Parameter(HelpMessage = "Get backup files only with no formatted summary.",ParameterSetName = "raw")]
    [Switch]$Raw
)

$reportVer = "1.2.1"

#convert path to a full filesystem path
$Path = Convert-Path $path
Write-Verbose "Starting $($myinvocation.mycommand) v.$ReportVer"
Write-Verbose "Using parameter set $($pscmdlet.ParameterSetName)"

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
$files = Get-ChildItem $Path\*.zip, $Path\*.rar | Where-Object { $rx.IsMatch($_.name) }
Write-Verbose "Found $($files.count) files in $Path"

foreach ($item in $files) {
    $setpath = $rx.matches($item.name).groups[4].value
    $settype = $rx.matches($item.name).groups[5].value

    #add some custom properties to be used with formatted results based on named captures
    $item | Add-Member -MemberType NoteProperty -Name SetPath -Value $setpath
    $item | Add-Member -MemberType NoteProperty -Name SetType -Value $setType
}

if ($raw) {
    $Files | Sort-Object -Property LastWriteTime
}
else {
    Write-Verbose "Preparing report data"
    Write-Host "$([char]0x1b)[1;4;38;5;216m`nMy Backup Report - $Path`n$([char]0x1b)[0m"
    if ($pscmdlet.ParameterSetName -eq 'default') {
    $files | Sort-Object SetPath, SetType, LastWriteTime |
    Format-Table -GroupBy SetPath -Property @{Name = "Created"; Expression = { $_.LastWriteTime } },
    @{Name = "SizeMB"; Expression = {
        $size = $_.length
        if ($size -lt 1MB) {
            $d = 4
        }
        else {
            $d = 0
        }
        Format-Value -input $size -unit MB -decimal $d
         } },
    Name
        }
$grouped = $files | Group-Object SetPath
$summary = foreach ($item in $grouped) {
    [pscustomobject]@{
        BackupSet = $item.name
        Files     = $item.Count
        SizeMB    = ($item.group | Measure-Object -Property size -sum -outvariable m).sum | Format-Value -unit MB -Decimal 2
    }
}

$total = [PSCustomObject]@{
    TotalFiles  = ($summary.files | Measure-Object -sum).sum
    #($grouped | Measure-Object -property count -sum).sum
    TotalSizeMB = ($summary.sizeMB | Measure-Object -sum).sum
    #[math]::round(($summary.size | Measure-Object -sum).sum/1MB,4)
}
Write-Host "Backup Summary $((Get-Date).ToShortDateString())" -ForegroundColor yellow
Write-Host "Path: $Path" -ForegroundColor Yellow

($summary | Sort-Object Size -Descending | Format-Table | Out-String).TrimEnd() | Write-Host -ForegroundColor yellow

($total | Format-Table | Out-String).TrimEnd() | Write-Host -ForegroundColor yellow
}

if ($pscmdlet.ParameterSetName -ne 'raw') {
    Write-Host "$([char]0x1b)[38;5;216m`nReport version $reportver$([char]0x1b)[0m"
}
