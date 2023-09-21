#requires -version 5.1

<#
rename the oldest backup file for long term archiving
run this every quarter to rename a file like 20201023_Training-FULL.rar
to ARCHIVE_Training.rar
#>

[CmdletBinding(SupportsShouldProcess)]
Param(
    [Parameter(Position = 0, HelpMessage = "Specify the backup path")]
    [ValidateScript({Test-Path $_})]
    [String]$Path = "\\ds416\backup",
    [Parameter(HelpMessage = "Specify the filename prefix")]
    [String]$Prefix = "ARCHIVE"
)

#parse out backup set
[regex]$rx = "(?<=_)\w+(?=\-)"

Write-Verbose "Getting FULL backup rar files from $path"
$files = Get-ChildItem -Path "$path\*Full.rar"

if ($files) {
    Write-Verbose "Found $($files.count) file[s]"

    #get groups where there is more than 2 backup
    $Groups = $files | Group-Object { $rx.match($_.basename) } | Where-Object { $_.count -gt 2 }

    foreach ($item in $groups) {
        Write-Verbose "Processing backup set $($item.name)"
        $new = "{0}_{1}.rar" -f $prefix,$item.name
        Write-Verbose "Renaming oldest file to $new"

        #delete a previous file if found
        $target =(Join-Path -Path $path -ChildPath $new)
        if (Test-Path $target) {
            Write-Verbose "Removing previous file $target"
            Remove-Item $target
        }
        #rename the oldest file in the group
        $item.Group | Sort-Object -Property LastWriteTime | Select-Object -First 1 |
        Get-Item | Rename-Item -NewName $new -PassThru
    }
}
else {
    Write-Warning "No matching files found in $Path."
}
