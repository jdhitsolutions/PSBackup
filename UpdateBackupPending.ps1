#requires -version 5.1

#update backup pending CSV file with updates sizes and deleting files that are gone

[cmdletbinding(SupportsShouldProcess)]

Param(
    [parameter(position = 0, Mandatory, ValueFromPipeline, ValueFromPipelineByPropertyName)]
    [ArgumentCompleter({ $(Get-ChildItem d:\backup\*.csv).fullname })]
    [ValidateScript({ Test-Path $_ })]
    [string[]]$Path
)

Begin {
    Write-Verbose "Starting $($myinvocation.mycommand)"
}
Process {
    Foreach ($item in $Path) {
        Write-Verbose "Importing data from $item"
        $csv = [System.Collections.generic.list[object]]::new()
        [object[]]$imported = Import-Csv -Path $item -OutVariable in
        if ($imported.count -eq 0) {
            Return "No items found."
        }
        elseif ($imported.count -eq 1) {
            $csv.Add($imported)
        }
        else {
            $csv.AddRange($imported)
        }

        Write-Verbose "Processing $($csv.count) items"
        $updated = $csv.where({ Test-Path $_.Path }).foreach({
                $now = Get-Item $_.path -Force
                if ($now.length -ne $_.Size) {
                    Write-Verbose "Updating file size for $($_.path) from $($_.size) to $($now.length)"
                    if ($in.count -eq 1) {
                        $_[0].size = $now.length
                    }
                    else {
                        $_.size = $now.length
                    }
                }
                $_
            })

        $remove = $in.where( { $updated.path -notcontains $_.path }).path
        if ($remove.count -gt 0) {
            Write-Verbose "Removing these files"
            $remove | Write-Verbose
        }
        Write-Verbose "Updated list to $($updated.count) items"

        #update the CSV
        Write-Verbose "Updating CSV $item"
        $updated | ConvertTo-Csv | Write-Verbose
        $updated | Export-Csv -Path $item -NoTypeInformation
    } #foreach item
} #process
end {
    Write-Verbose "Ending $($myinvocation.MyCommand)"
} #end

# New-Item -path 'C:\Program Files\WindowsPowerShell\Scripts\' -name UpdateBackupPending.ps1 -itemtype symbolicLink -value (Convert-Path .\UpdateBackupPending.ps1) -force

