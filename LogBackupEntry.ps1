#requires -version 5.1

[cmdletbinding()]
[alias("lbe")]
Param(
  [Parameter(Mandatory)]
  [object]$Event,
  [Parameter(Mandatory)]
  [string]$CSVPath
)

#uncomment for debugging and testing
# this will create a serialized version of each fired event
# $event | export-clixml ([System.IO.Path]::GetTempFileName()).replace("tmp","xml")

if (Test-Path $event.SourceEventArgs.fullpath) {

  $f = Get-Item -path $event.SourceEventArgs.fullpath -force

  #only save files and not a temp file
  if ((-Not $f.psiscontainer) -AND ($f.basename -notmatch "(^(~|__rar).*)|(.*\.tmp$)")) {

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

#end of script