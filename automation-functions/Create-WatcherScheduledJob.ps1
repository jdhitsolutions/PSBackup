#requires -version 5.1
#requires -module PSScheduledJob

#create FileSystemWatcher job for my incremental backups.

#scheduled job scriptblock
$action = {

  if (Test-Path c:\scripts\PSBackup\myBackupPaths.txt) {
    #filter out commented lines and lines with just white space
    $paths = Get-Content c:\scripts\PSBackup\myBackupPaths.txt |
    Where-Object {$_ -match "(^[^#]\S*)" -and $_ -notmatch "^\s+$"}
  }
  else {
    Throw "Failed to find c:\scripts\PSBackup\myBackupPaths.txt"
    #bail out
    Return
  }

  #trim leading and trailing white spaces in each path
  Foreach ($Path in $Paths.Trim()) {

    #get the directory name from the list of paths
    $name = ((Split-Path $path -Leaf).replace(' ', ''))

    #specify the directory for the CSV log files
    $log = "D:\Backup\{0}-log.csv" -f $name

    #define the watcher object
    Write-Host "Creating a FileSystemWatcher for $Path" -ForegroundColor green
    $watcher = [System.IO.FileSystemWatcher]($path)
    $watcher.IncludeSubdirectories = $True
    #enable the watcher
    $watcher.EnableRaisingEvents = $True

    #the Action scriptblock to be run when an event fires
    $sbText = "c:\scripts\PSBackup\LogBackupEntry.ps1 -event `$event -CSVPath $log"

    $sb = [scriptblock]::Create($sbText)

    #register the event subscriber

    #possible events are Changed,Deleted,Created
    $params = @{
      InputObject      = $watcher
      EventName        = "changed"
      SourceIdentifier = "FileChange-$Name"
      MessageData      = "A file was created or changed in $Path"
      Action           = $sb
    }

    $params.MessageData | Out-String | Write-Host -ForegroundColor cyan
    $params.Action | Out-String | Write-Host -ForegroundColor Cyan
    Register-ObjectEvent @params

  } #foreach path

  Get-EventSubscriber | Out-String | Write-Host -ForegroundColor yellow

  #keep the job alive
  Do {
    Start-Sleep -Seconds 1
  } while ($True)

} #close job action

$trigger = New-JobTrigger -AtStartup
$cred = Get-Credential Jeff
Register-ScheduledJob -Name "DailyWatcher" -ScriptBlock $action -Trigger $trigger -RunNow -MaxResultCount 5 -credential $cred

# manually start the task in Task Scheduler

# Unregister-ScheduledJob "DailyWatcher"
