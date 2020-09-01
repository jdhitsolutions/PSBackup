#requires -version 5.1

[cmdletbinding(SupportsShouldProcess)]
Param(
    [Parameter(Mandatory)]
    [ValidateScript({Test-Path $_ })]
    [string]$Path,

    [ValidateScript({Test-Path $_ })]
    #my temporary work area with plenty of free disk space
    [string]$TempPath = "D:\Temp",

    [ValidateSet("FULL", "INCREMENTAL")]
    [string]$Type = "FULL"
)

Write-Verbose "[$(Get-Date)] Starting $($myinvocation.MyCommand)"
Write-Host "[$(Get-Date)] Starting $($myinvocation.MyCommand) $Type for $Path" -foreground green
if (-Not (Get-Module Dev-PSRar)) {
    Import-Module C:\scripts\PSRAR\Dev-PSRar.psm1 -force
}

#replace spaces in path names
$name = "{0}_{1}-{2}.rar" -f (Get-Date -format "yyyyMMdd"), (Split-Path -Path $Path -Leaf).replace(' ', ''), $Type
$target = Join-Path -Path $TempPath -ChildPath $name

#I have hard coded my NAS backup. Would be better as a parameter with a default value.
$nasPath = Join-Path -Path \\DS416\backup -ChildPath $name
Write-Host "[$(Get-Date)] Archiving $path to $target" -foreground green

if ($pscmdlet.ShouldProcess($Path)) {
    #Create the RAR archive -you can use any archiving technique you want
    Add-RARContent -path $Path -Archive $target -CompressionLevel 5 -Comment "$Type backup of $(($Path).ToUpper()) from $env:Computername" | Out-Null

    Write-Verbose "[$(Get-Date)] Copying $target to $nasPath"
    Try {
        #copy the RAR file to the NAS for offline storage
        Copy-Item -Path $target -Destination $NASPath -ErrorAction Stop
        #copy to OneDrive
        Copy-Item -Path $Target -Destination "c:\users\jeff\OneDrive\Backup" -ErrorAction SilentlyContinue
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
