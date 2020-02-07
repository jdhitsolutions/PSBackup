#requires -version 5.1
#requires -module PSScheduledJob

#create incremental scheduled job

import-module PSScheduledJob

$filepath = "C:\scripts\PSBackup\DailyIncrementalBackup.ps1"

if (Test-Path $filepath) {
    $trigger = New-JobTrigger -At 10:00PM -DaysOfWeek Saturday,Sunday,Monday,Tuesday,Wednesday,Thursday -Weekly
    $jobOpt = New-ScheduledJobOption -RunElevated -RequireNetwork -WakeToRun

    Register-ScheduledJob -FilePath $filepath -Name "DailyIncremental" -Trigger $trigger -ScheduledJobOption $jobOpt -MaxResultCount 7 -Credential jeff
}
else {
    Write-Warning "Can't find $filepath"
}

# Unregister-ScheduledJob DailyIncremental