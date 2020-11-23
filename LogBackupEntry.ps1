#requires -version 5.1

[cmdletbinding()]
[alias("lbe")]
Param(
  [Parameter(Mandatory)]
  [ValidateNotNullOrEmpty()]
  [object]$Event,

  [Parameter(Mandatory)]
  [ValidateNotNullOrEmpty()]
  [string]$CSVPath,

  [Parameter(HelpMessage = "Specify the path to a text file with a list of paths to exclude from backup")]
  [ValidateScript( { Test-Path $_ })]
  [string]$ExclusionList = "c:\scripts\PSBackup\Exclude.txt"
)

if (Test-Path $ExclusionList) {
  $excludes = Get-Content -Path $ExclusionList | Where-Object { $_ -match "\w+" -AND $_ -notmatch "^#" }
}

#log activity. Comment out the line to disable logging
$logfile = "D:\temp\watcherlog.txt"

#if log is enabled and it is over 10MB in size, archive the file and start a new file.
$chkfile = Get-Item -Path $logfile -ErrorAction SilentlyContinue
if ($chkFile.length -ge 10MB) {
  $chkFile | Copy-Item -Destination d:\temp\archive-watcherlog.txt -Force
  Remove-Item -Path $logfile
}

#uncomment for debugging and testing
# this will create a serialized version of each fired event
# $event | Export-Clixml ([System.IO.Path]::GetTempFileName()).replace("tmp","xml")

if ($logfile) { "$(Get-Date) LogBackupEntry fired" | Out-File -FilePath $logfile -Append }
if ($logfile) { "$(Get-Date) Verifying path $($event.SourceEventArgs.fullpath)" | Out-File -FilePath $logfile -Append }
if (Test-Path $event.SourceEventArgs.fullpath) {
  $f = Get-Item -Path $event.SourceEventArgs.fullpath -Force
  if ($logfile) { "$(Get-Date) Detected $($f.FullName)" | Out-File -FilePath $logfile -Append }

  #test if the path is in the excluded list and skip the file
  $test = @()
  foreach ($x in $excludes) {
    $test += $f.directory -like "$($x)*"
  }
  if ($test -notcontains $True) {
    $OKBackup = $True
  }
  else {
    if ($logfile) { "$(Get-Date) EXCLUDED ENTRY $($f.FullName)" | Out-File -FilePath $logfile -Append }
    $OKBackup = $false
  }
  if ($OKBackup) {
    #get current contents of CSV file and only add the file if it doesn't exist
    If (Test-Path $CSVPath) {
      $in = (Import-Csv -Path $CSVPath).path | Get-Unique -AsString
      if ($in -contains $f.fullname) {
        if ($logfile) { "$(Get-Date) DUPLICATE ENTRY $($f.FullName)" | Out-File -FilePath $logfile -Append }
      }
    }
    #only save files and not a temp file
    if (($in -notcontains $f.fullname) -AND (-Not $f.psiscontainer) -AND ($f.basename -notmatch "(^(~|__rar).*)|(.*\.tmp$)")) {

      if ($logfile) { "$(Get-Date) Saving to $CSVPath" | Out-File -FilePath $logfile -Append }

      #write the object to the CSV file
      [pscustomobject]@{
        ID        = $event.EventIdentifier
        Date      = $event.timeGenerated
        Name      = $event.sourceEventArgs.Name
        IsFolder  = $f.PSisContainer
        Directory = $f.DirectoryName
        Size      = $f.length
        Path      = $event.sourceEventArgs.FullPath
      } | Export-Csv -NoTypeInformation -Path $CSVPath -Append

    } #if not a container and not a temp file
  } #if OKBackup
} #if test-path

if ($logfile) { "$(Get-Date) Ending LogBackupEntry.ps1" | Out-File -FilePath $logfile -Append }

#end of script