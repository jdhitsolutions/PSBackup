#requires -version 5.1
#requires -module CimCmdlets,BurntToast

[CmdletBinding(SupportsShouldProcess)]
Param()

Write-Verbose "Starting $($MyInvocation.MyCommand)"
#verify the scheduled task exists and bail out if it doesn't.
$name = "DailyWatcher"

Try {
    Write-Verbose "Getting scheduled task $Name"
    $task = Get-ScheduledTask -TaskName $Name -ErrorAction Stop
}
catch {
    Write-Verbose "Scheduled task $Name not found. Aborting."
    Throw $_
    #make sure we bail out
    return
}

#if by chance the task is not running, go ahead and start it.
if ($task.State -ne 'running') {
    Write-Verbose "Starting scheduled task $Name"
    if ($PSCmdlet.ShouldProcess($Name, "Start-ScheduledTask")) {

        $task | Start-ScheduledTask

        #send a toast notification
        $params = @{
            Text    = "Starting scheduled task $($task.taskname)"
            Header  = $(New-BTHeader -Id 1 -Title "Daily Watcher")
            Applogo = "c:\scripts\db.png"
        }
        Write-Verbose "Sending Burnt Toast notification"
        New-BurntToastNotification @params

    } #if should process
}

#register an event subscriber if one doesn't already exist
Try {
    Write-Verbose "Testing for an existing event subscriber"
    Get-EventSubscriber -SourceIdentifier TaskChange -ErrorAction Stop
    Write-Verbose "An event subscriber has been detected. No further action is required."
}
Catch {

    <#
    the scheduled task object is of this CIM type
    Microsoft.Management.Infrastructure.CimInstance#Root/Microsoft/Windows/TaskScheduler/MSFT_ScheduledTask
    #>
    Write-Verbose "Registering a new CimIndicationEvent"

    $query = "Select * from __InstanceModificationEvent WITHIN 10 WHERE TargetInstance ISA 'MSFT_ScheduledTask' AND TargetInstance.TaskName='$Name'"
    $NS = 'Root\Microsoft\Windows\TaskScheduler'

    #define a scriptblock to execute if the event fires
    $Action = {
        $previous = $Event.SourceEventArgs.NewEvent.PreviousInstance
        $current = $Event.SourceEventArgs.NewEvent.TargetInstance
        if ($previous.state -eq 'Running' -AND $current.state -ne 'Running') {
            Write-Host "[$(Get-Date)] Restarting the DailyWatcher task" -ForegroundColor green
            Get-ScheduledTask -TaskName DailyWatcher | Start-ScheduledTask
        }
    }

    $regParams = @{
        SourceIdentifier = "TaskChange"
        Namespace        = $NS
        query            = $query
        MessageData      = "The task $Name has changed"
        MaxTriggerCount  = 7
        Action           = $action
    }

    $regParams | Out-String | Write-Verbose

    if ($PSCmdlet.ShouldProcess($regParams.SourceIdentifier, "Register-CimIndicationEvent")) {
        Register-CimIndicationEvent @regParams
    }
}

Write-Verbose "Ending $($MyInvocation.MyCommand)"
