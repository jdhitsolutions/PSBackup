#requires -version 5.1

[cmdletbinding()]
[alias("lbe")]
Param(
  [Parameter(Mandatory)]
  [ValidateNotNullOrEmpty()]
  [object]$Event,

  [Parameter(Mandatory)]
  [ValidateNotNullOrEmpty()]
  [string]$CSVPath
)

#log activity. Comment out the line to disable logging
# $logfile = "D:\temp\watcherlog.txt"

#uncomment for debugging and testing
# this will create a serialized version of each fired event
# $event | export-clixml ([System.IO.Path]::GetTempFileName()).replace("tmp","xml")

if ($logfile) {"$(Get-Date) LogBackupEntry fired" | Out-File -FilePath $logfile -append}
if ($logfile) {"$(Get-Date) Verifying path $($event.SourceEventArgs.fullpath)" | Out-File -FilePath $logfile -append}
if (Test-Path $event.SourceEventArgs.fullpath) {
  $f = Get-Item -path $event.SourceEventArgs.fullpath -force
  if ($logfile) {"$(Get-Date) Detected $($f.FullName)" | Out-File -FilePath $logfile -append}
  #get current contents of CSV file and only add the file if it doesn't exist
  If (Test-Path $CSVPath) {
    $in = (Import-Csv -path $CSVPath).path | Get-Unique -AsString
    if ($in -contains $f.fullname) {
      if ($logfile) {"$(Get-Date) DUPLICATE ENTRY $($f.FullName)" | Out-File -FilePath $logfile -append}
    }
  }
  #only save files and not a temp file
  if (($in -notcontains $f.fullname) -AND (-Not $f.psiscontainer) -AND ($f.basename -notmatch "(^(~|__rar).*)|(.*\.tmp$)")) {

    if ($logfile) {"$(Get-Date) Saving to $CSVPath" | Out-File -FilePath $logfile -append}
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

} #if test-path
 if ($logfile) {"$(Get-Date) Ending LogBackupEntry.ps1" | Out-File -FilePath $logfile -append}
#end of script