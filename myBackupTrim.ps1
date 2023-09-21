#requires -version 5.1

#MyBackupTrim.ps1

#trim full backups to the last X number of files

[CmdletBinding(SupportsShouldProcess)]
Param(
    [Parameter(Position = 0, HelpMessage = "Specify the backup folder location")]
    [ValidateNotNullOrEmpty()]
    [ValidateScript( { Test-Path $_ })]
    [String]$Path = "\\ds416\backup",

    [Parameter(HelpMessage = "Specify a file pattern")]
    [ValidateNotNullOrEmpty()]
    [String]$Pattern = "*-FULL.rar",

    [Parameter(HelpMessage = "Specify the number of the most recent files to keep")]
    [ValidateScript({ $_ -ge 1 })]
    [Int]$Count = 4
)

$find = Join-Path -Path $path -ChildPath $pattern
Write-Verbose "Finding backup files from $Find"
Try {
    $files = Get-ChildItem -Path $find -File -ErrorAction Stop
}
Catch {
    Throw $_
}

if ($files.count -gt 0) {
    Write-Verbose "Found $($files.count) backup files"
    <#
        group the files based on the naming convention
        like 20191108_documents-FULL.rar and 20191108_Scripts-FULL.rar
        but make sure there are at least $Count number of files
    #>

    $grouped = $files |
        Group-Object -Property { ([regex]"(?<=_)\w+(?=-)").match($_.BaseName).value } |
        Where-Object { $_.count -gt $count }

    if ($grouped) {
        foreach ($item in $grouped) {
            Write-Verbose "Trimming $($item.name)"
            $item.group |
                Sort-Object -Property LastWriteTime -Descending |
                Select-Object -Skip $count | Remove-Item
        }
    }
    else {
        Write-Host "Not enough files to justify cleanup." -ForegroundColor magenta
    }
}

#End of script
