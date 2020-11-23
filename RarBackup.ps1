#requires -version 5.1

[cmdletbinding(SupportsShouldProcess)]
Param(
    [Parameter(Mandatory)]
    [ValidateScript( { Test-Path $_ })]
    [string]$Path,

    [Parameter(HelpMessage = "The final location for the backup files.")]
    [ValidateScript( { Test-Path $_ })]
    [string]$Destination = "\\DS416\backup",

    [ValidateScript( { Test-Path $_ })]
    #my temporary work area with plenty of free disk space
    [string]$TempPath = "D:\Temp",

    [ValidateSet("FULL", "INCREMENTAL")]
    [string]$Type = "FULL",

    [Parameter(HelpMessage = "Specify the path to a text file with a list of paths to exclude from backup")]
    [ValidateScript( { Test-Path $_ })]
    [string]$ExclusionList = "c:\scripts\PSBackup\Exclude.txt"
)

Write-Verbose "[$(Get-Date)] Starting $($myinvocation.MyCommand)"
Write-Host "[$(Get-Date)] Starting $($myinvocation.MyCommand) $Type for $Path" -foreground green

if (-Not (Get-Module Dev-PSRar)) {
    Import-Module C:\scripts\PSRAR\Dev-PSRar.psm1 -Force
}

#replace spaces in path names
$name = "{0}_{1}-{2}.rar" -f (Get-Date -Format "yyyyMMdd"), (Split-Path -Path $Path -Leaf).replace(' ', ''), $Type
$target = Join-Path -Path $TempPath -ChildPath $name

#I have hard coded my NAS backup. Would be better as a parameter with a default value.
$nasPath = Join-Path -Path $Destination -ChildPath $name
Write-Host "[$(Get-Date)] Archiving $path to $target" -foreground green

$rarParams = @{
    path             = $Path
    Archive          = $target
    CompressionLevel = 5
    Comment          = "$Type backup of $(($Path).ToUpper()) from $env:Computername"
}

if (Test-Path $ExclusionList) {
    Write-Verbose "[$(Get-Date)] Using exclusion list from $ExclusionList"
    $rarParams.Add("ExcludeFile", $ExclusionList)
}

$rarParams | Out-String | Write-Verbose

if ($pscmdlet.ShouldProcess($Path)) {
    #Create the RAR archive -you can use any archiving technique you want
    [void](Add-RARContent @rarParams)

    Try {
        #copy the RAR file to the NAS for offline storage
        Write-Verbose "[$(Get-Date)] Copying $target to $nasPath"
        Copy-Item -Path $target -Destination $NASPath -ErrorAction Stop

        #copy to OneDrive
        Write-Verbose "[$(Get-Date)] Copying $target to OneDrive\Backup"
        Copy-Item -Path $Target -Destination "$ENV:OneDriveConsumer\Backup" -ErrorAction SilentlyContinue
    }
    Catch {
        Write-Warning "Failed to copy $target. $($_.exception.message)"
        Throw $_
    }
    #verify the file was copied successfully
    Write-Verbose "[$(Get-Date)] Validating file hash"

    $here = Get-FileHash $Target
    $there = Get-FileHash $nasPath
    if ($here.hash -eq $there.hash) {
        #delete the file if the hashes match
        Write-Verbose "[$(Get-Date)] Deleting $target"
        Remove-Item $target
    }
    else {
        Write-Warning "File hash difference detected."
        Throw "File hash difference detected"
    }
}

Write-Verbose "[$(Get-Date)] Ending $($myinvocation.MyCommand)"
Write-Host "[$(Get-Date)] Ending $($myinvocation.MyCommand)" -foreground green

#end of script file
