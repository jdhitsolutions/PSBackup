# load the format files

<# Get-ChildItem $PSScriptRoot\*format.ps1xml |
ForEach-Object {
    Update-FormatData -AppendPath $_.FullName
} #>

Update-FormatData $PSScriptRoot\formats\mybackupfile.format.ps1xml
Update-FormatData $PSScriptRoot\formats\pending.format.ps1xml
