# load the format files

Get-ChildItem $PSScriptroot\*format.ps1xml |
Foreach-Object {
    Update-FormatData -AppendPath $_.FullName
}