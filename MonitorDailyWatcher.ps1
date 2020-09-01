#requires -version 5.1
#requires -module CimCmdlets,BurntToast

#verify the scheduled task exists and bail out if it doesn't.
$name = "DailyWatcher"
Try {
    $task = Get-ScheduledTask -TaskName $Name -ErrorAction Stop
}
catch {
    Throw $_
    #make sure we bail out
    return
}

#if by chance the task is not running, go ahead and start it.
if ($task.State -ne 'running') {
    $task | Start-ScheduledTask
    
    #send a toast notification
    $params = @{
        Text    = "Starting scheduled task $($task.taskname)"
        Header  = $(New-BTHeader -Id 1 -Title "Daily Watcher")
        Applogo = "c:\scripts\db.png"
    }

    New-BurntToastNotification @params
}

<#
the scheduled task object is of this CIM type
Microsoft.Management.Infrastructure.CimInstance#Root/Microsoft/Windows/TaskScheduler/MSFT_ScheduledTask
#>

$query = "Select * from __InstanceModificationEvent WITHIN 10 WHERE TargetInstance ISA 'MSFT_ScheduledTask' AND TargetInstance.TaskName='$Name'"
$NS = 'Root\Microsoft\Windows\TaskScheduler'

#define a scriptblock to execute if the event fires
$Action = {
 $previous =  $Event.SourceEventArgs.NewEvent.PreviousInstance
 $current =  $Event.SourceEventArgs.NewEvent.TargetInstance
 if ($previous.state -eq 'Running' -AND $current.state -ne 'Running') {
    Write-Host "[$(Get-Date)] Restarting the DailyWatcher task" -ForegroundColor green
    Get-ScheduledTask -TaskName DailyWatcher | Start-ScheduledTask
 }
}
Register-CimIndicationEvent -SourceIdentifier "TaskChange" -Namespace $NS -query $query -MessageData "The task $Name has changed" -MaxTriggerCount 7 -Action $action

