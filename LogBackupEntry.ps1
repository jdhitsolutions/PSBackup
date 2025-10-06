#requires -version 5.1

[CmdletBinding()]
[alias('lbe')]
param(
  [Parameter(Mandatory)]
  [ValidateNotNullOrEmpty()]
  [object]$Event,

  [Parameter(Mandatory)]
  [ValidateNotNullOrEmpty()]
  [String]$CSVPath,

  [Parameter(HelpMessage = 'Specify the path to a text file with a list of paths to exclude from backup')]
  [ValidateScript( { Test-Path $_ })]
  [String]$ExclusionList = 'c:\scripts\PSBackup\Exclude.txt'
)

if (Test-Path $ExclusionList) {
  $excludes = Get-Content -Path $ExclusionList | Where-Object { $_ -match '\w+' -and $_ -notmatch '^#' }
}

#log activity. Comment out the line to disable logging
$LogFile = 'D:\temp\watcherlog.txt'

#if log is enabled and it is over 10MB in size, archive the file and start a new file.
$ChkFile = Get-Item -Path $LogFile -ErrorAction SilentlyContinue
if ($ChkFile.length -ge 10MB) {
  $ChkFile | Copy-Item -Destination d:\temp\archive-watcherlog.txt -Force
  Remove-Item -Path $LogFile
}

#uncomment for debugging and testing
# this will create a serialized version of each fired event
# $event | Export-Clixml ([System.IO.Path]::GetTempFileName()).replace("tmp","xml")

if ($LogFile) {
  "$(Get-Date) LogBackupEntry fired" | Out-File -FilePath $LogFile -Append
}
if ($LogFile) {
  "$(Get-Date) Verifying path $($event.SourceEventArgs.FullPath)" | Out-File -FilePath $LogFile -Append
}
if (Test-Path $event.SourceEventArgs.FullPath) {
  $f = Get-Item -Path $event.SourceEventArgs.FullPath -Force
  if ($LogFile) {
    "$(Get-Date) Detected $($f.FullName)" | Out-File -FilePath $LogFile -Append
  }

  #test if the path is in the excluded list and skip the file
  $test = $excludes | where { $f -like "$($_)*" }
  <#   $test = @()
  foreach ($x in $excludes) {
    $test += $f.directory -like "$($x)*"
  } #>
  #if ($test -NotContains $True) {
  if (-not $test) {
    $OKBackup = $True
  }
  else {
    if ($LogFile) {
      "$(Get-Date) EXCLUDED ENTRY $($f.FullName) LIKE $Test" | Out-File -FilePath $LogFile -Append
    }
    $OKBackup = $false
  }
  if ($OKBackup) {
    #get current contents of CSV file and only add the file if it doesn't exist
    if (Test-Path $CSVPath) {
      $in = (Import-Csv -Path $CSVPath).path | Get-Unique -AsString
      if ($in -contains $f.FullName) {
        if ($LogFile) { "$(Get-Date) DUPLICATE ENTRY $($f.FullName)" | Out-File -FilePath $LogFile -Append }
      }
    }
    #only save files and not a temp file
    if (($in -notcontains $f.FullName) -and (-not $f.PSIsContainer) -and ($f.basename -notmatch '(^(~|__rar).*)|(.*\.tmp$)')) {

      if ($LogFile) {
        "$(Get-Date) Saving to $CSVPath" | Out-File -FilePath $LogFile -Append
      }

      #write the object to the CSV file
      [PSCustomObject]@{
        ID        = $event.EventIdentifier
        Date      = $event.timeGenerated
        Name      = $event.sourceEventArgs.Name
        IsFolder  = $f.PSIsContainer
        Directory = $f.DirectoryName
        Size      = $f.length
        Path      = $event.sourceEventArgs.FullPath
      } | Export-Csv -NoTypeInformation -Path $CSVPath -Append

    } #if not a container and not a temp file
  } #if OKBackup
} #if test-path

if ($LogFile) {
  "$(Get-Date) Ending LogBackupEntry.ps1" | Out-File -FilePath $LogFile -Append
}

#end of script
