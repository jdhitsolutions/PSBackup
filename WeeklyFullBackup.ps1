#requires -version 5.1

[cmdletbinding(SupportsShouldProcess)]
Param(
    [Parameter(Position = 0, HelpMessage = "Path to a text file with folders to backup.")]
    [ValidateNotNullOrEmpty()]
    [string]$PathList = "c:\scripts\PSBackup\mybackupPaths.txt",
    [Parameter(Position = 0, HelpMessage = "The destination folder for the backup files")]
    [ValidateNotNullOrEmpty()]
    [string]$Destination = "\\ds416\backup"
)

Push-Location
Set-Location $PSScriptRoot

If (Test-Path -Path $pathList) {

    Write-Host "[$(Get-Date)] Getting backup paths" -ForegroundColor yellow
    #filter out blanks and commented lines
    $paths = Get-Content $PathList | Where-Object { $_ -match "(^[^#]\S*)" -and $_ -notmatch "^\s+$" }

    #import my custom module
    Import-Module C:\scripts\PSRAR\Dev-PSRar.psm1 -force

    $paths | ForEach-Object {

        if ($pscmdlet.ShouldProcess($_)) {
            Try {
                #invoke a control script using my custom module
                Write-Host "[$(Get-Date)] Backing up $_" -ForegroundColor yellow
                #this is my wrapper script using WinRar to create the archive.
                #you can use whatever tool you want in its place.
                [void](.\RarBackup.ps1 -Path $_ -ErrorAction Stop)
                $ok = $True
            }
            Catch {
                $ok = $False
                Write-Warning $_.exception.message
            }
        }

        #clear corresponding incremental log files
        $name = ((Split-Path $_ -Leaf).replace(' ', ''))
        #specify the directory for the CSV log files
        $log = "D:\Backup\{0}-log.csv" -f $name

        if ($OK -AND (Test-Path $log) -AND ($pscmdlet.ShouldProcess($log, "Clear Log"))) {
            Write-Host "[$(Get-Date)] Removing $log" -ForegroundColor yellow
            Remove-Item -path $log
        }

        #clear incrementals
        $target = Join-Path -Path $Destination -ChildPath "*_$name-incremental.rar"
        if ($ok -AND ($PScmdlet.ShouldProcess($target, "Clear Incrementals"))) {
            Write-Host "[$(Get-Date)] Removing $Target" -ForegroundColor yellow
            Remove-Item $target
        }

        <#
        if ($ok -AND ($PScmdlet.ShouldProcess("\\ds416\backup\*_$name-incremental.rar","Clear Incrementals"))) {
            Write-Host "[$(Get-Date)] Removing \\ds416\backup\*_$name-incremental.rar" -ForegroundColor yellow
            Remove-item "\\ds416\backup\*_$name-incremental.rar"
        }
        #>
    } #foreach path

    #trim old backups
    Write-Host "[$(Get-Date)] Trimming backups from $Destination" -ForegroundColor yellow
    if ($OK -and ($PSCmdlet.ShouldProcess($Destination, "Trim backups"))) {
        .\mybackuptrim.ps1 -path $Destination -count 4
    }
    #I am also backin up a smaller subset to OneDrive
    Write-Host "[$(Get-Date)] Trimming backups from  C:\Users\Jeff\OneDrive\backup" -ForegroundColor yellow
    if ($OK -and ($PSCmdlet.ShouldProcess("OneDrive", "Trim backups"))) {
        .\mybackuptrim.ps1 -path C:\Users\Jeff\OneDrive\backup -count 3
    }

} #if mybackup paths file
else {
    Write-Warning "Failed to find $PathList"
}

Pop-Location