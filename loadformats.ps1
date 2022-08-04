# load the format files

<# Get-ChildItem $PSScriptroot\*format.ps1xml |
Foreach-Object {
    Update-FormatData -AppendPath $_.FullName
} #>

Update-FormatData $PSScriptroot\mybackupfile.format.ps1xml
Update-FormatData $PSScriptroot\pending.format.ps1xml