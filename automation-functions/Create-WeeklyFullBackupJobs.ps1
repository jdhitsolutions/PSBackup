#requires -version 5.1
#requires -module PSScheduledJob

#create weekly full backups

$trigger = New-JobTrigger -At 10:00PM -DaysOfWeek Friday -WeeksInterval 1 -Weekly
$jobOpt = New-ScheduledJobOption -RunElevated -RequireNetwork -WakeToRun

$params = @{
    FilePath           = "C:\scripts\PSBackup\WeeklyFullBackup.ps1"
    Name               = "WeeklyFullBackup"
    Trigger            = $trigger
    ScheduledJobOption = $jobOpt
    MaxResultCount     = 5
    Credential         = "$env:computername\jeff"
}

Register-ScheduledJob @params

# Unregister-ScheduledJob WeeklyFullBackup.
