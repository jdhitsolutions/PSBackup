#requires -version 5.1

<#
These are wrapper functions for RAR.EXE, which is the command line
version of WinRAR.

https://www.rarlab.com/
using v5.71

This is an old module that hasn't been updated in years.
#>

Function Get-RARExe {

    Param()

    #get winrar folder
    $open = Get-ItemProperty -Path HKLM:\SOFTWARE\Classes\WinRar\Shell\Open\Command | Select-Object -ExpandProperty "(default)"
    #strip off the "%1" and quotes
    $opencmd = $open.Replace('"', "").Replace("%1", "")
    #$opencmd = $open.replace("""%1""","")
    #escape spaces
    $opencmd = $opencmd -replace ' ', '` '
    #get the executable name from the
    $parent = Split-Path -Path $opencmd -Parent

    #now join path for command line RAR.EXE
    Join-Path -Path $parent -ChildPath 'rar.exe'

}


#don't run this in the ISE. Redirection doesn't work.
Function Add-RARContent {

    <#
.Synopsis
Add files to an archive
.Description
Add a folder to a RAR archive.
.Example
PS C:\> Add-Rarcontent c:\work e:\MyArchive.zip
.Notes
Last Updated:
Version     : 0.9.1

.Link
http://jdhitsolutions.com/blog
#>

    [cmdletbinding(SupportsShouldProcess)]

    Param(
        [Parameter(Position = 0, Mandatory,
            HelpMessage = "Enter the path to the objects to be archived.")]
        [ValidateNotNullOrEmpty()]
        [SupportsWildCards()]
        [alias("path")]
        [string]$Object,
        [Parameter(Position = 1, Mandatory, HelpMessage = "Enter the path to RAR archive.")]
        [ValidateNotNullOrEmpty()]
        [string]$Archive,
        [switch]$MoveFiles,
        [ValidateSet(1, 2, 3, 4, 5)]
        [int]$CompressionLevel = 5,
        [string]$Comment = ("Archive created {0} by {1}\{2}" -f (Get-Date), $env:userdomain, $env:username)
    )

    Begin {
        $ProgressPreference = "Continue"
        Write-Verbose "Starting $($MyInvocation.MyCommand)"
        Write-Verbose "Using $rar"

        <#
    add|move files using update method
    dictionary size is 4k
    store paths
    store NTFS streams
    use a recovery record
    set compression level
    test archive
    recurse subfolders
    use quiet mode
    -id[c,d,p,q]
        Disable messages.
        Switch -idc disables the copyright string.
        Switch -idd disables “Done” string at the end of operation.
        Switch -idp disables the percentage indicator.
        Switch -idq turns on the quiet mode, so only error messages
        and questions are displayed.
    Use $env:temp as the temp folder
   #>

        #if delete files
        if ($MoveFiles) {
            Write-Verbose "Using command to move files after archiving"
            $action = "m"
            $verb = "Move"  #used with Write-Progress
        }
        else {
            Write-Verbose "Using command to add files after archiving"
            $action = "a"
            $verb = "Add" #Used with Write-Progress
        }

        $rarparam = @"
{1} -u -ep1 -os -rr -m{0} -t -r -iddc -w{2}
"@ -f $CompressionLevel, $action, $env:temp

    } #begin

    Process {
        $rarparam += (" {0} {1}" -f """$archive""", """$object""")

        #Write-Verbose "$($rar) $($rarparam)"

        if ($PSCmdlet.ShouldProcess("$($Archive) from $($object)")) {
            Write-Progress -Activity "RAR" -Status "$Verb content to $archive" -CurrentOperation $object

            $sb = [scriptblock]::Create("$rar $rarparam")
            $sb | Out-String | Write-Verbose
            Invoke-Command -ScriptBlock $sb

        } #should process
        #give the archive a moment to close
        Start-Sleep -Seconds 5
    } #process

    End {
        #create temp file if there is a comment and the archive was created
        if ($Comment -AND (Test-Path $Archive)) {
            Write-Verbose "Creating temp file comment"
            $tmpComment = [System.IO.Path]::GetTempFileName()

            Write-Progress -Activity "RAR" -Status "Adding comment to $archive" -CurrentOperation $tmpComment -PercentComplete 90

            #comment file must be ASCII
            $comment | Out-File -FilePath $tmpComment -Encoding ascii

            #use the some of the same params
            $rarparam = @"
c -z{0} {1} -rr -idq
"@ -f $tmpComment, """$Archive"""

            # Write-Verbose "$($rar) $($rarparam)"
            #add the comment to the archive
            if ($PSCmdlet.ShouldProcess("Archive Comment from $tmpComment")) {
                Write-Verbose "Adding Comment: $(Get-Content $tmpComment | Out-String)"

                $sb = [scriptblock]::Create("$rar $rarparam")
                Write-Verbose ($sb | Out-String)
                Invoke-Command -ScriptBlock $sb

            } #should process

            Write-Verbose "Deleting comment temp file"
            Remove-Item -Path $tmpComment
        } #if comment

        #Write-Progress -Activity "RAR" -Status "Adding content to $archive" -CurrentOperation "Complete" -Completed

        Write-Verbose "Ending $($MyInvocation.MyCommand)"
    } #end

} #end function

Function Test-RARFile {
    [cmdletbinding()]

    Param (
        [Parameter(Position = 0, Mandatory = $True,
            HelpMessage = "Enter the path to a .RAR file.",
            ValueFromPipeline = $True)]
        [string]$Path
    )

    Begin {
        Write-Verbose -Message "Starting $($MyInvocation.Mycommand)"
    } #begin

    Process {
        if ($path -is [System.IO.FileInfo]) {
            $Path = $path.FullName
        }

        Write-Verbose "Testing $path"

        $sb = [scriptblock]::Create("$rar t '$path' -idp")
        $a = Invoke-Command -scriptblock $sb

        Write-Verbose "Parsing results into objects"
        #this is a matchinfo object
        $b = $a | Select-String testing | Select-Object -Skip 1

        foreach ($item in $b) {
            Write-Verbose $item
            #remove Testing
            $c = $item.ToString().Replace("Testing", "").Trim()

            #split it on at least 2 spaces
            [regex]$r = "\s{2}"
            $d = $r.Split($c) | Where-Object { $_ }

            #create a custom object for each archive entry
            [pscustomobject][ordered]@{
                Archive = $path
                File    = $d[0].Trim()
                Status  = $d[1].Trim()
            }
        } #foreach

    } #Process

    End {
        Write-Verbose -Message "Ending $($MyInvocation.Mycommand)"
    } #end
} #end Test-RARFile

Function Show-RARContent {
    [cmdletbinding()]

    Param (
        [Parameter(Position = 0, Mandatory = $True,
            HelpMessage = "Enter the path to a .RAR file.",
            ValueFromPipeline = $True)]
        [string]$Path,
        [switch]$Detailed
    )

    Begin {
        Write-Verbose -Message "Starting $($MyInvocation.Mycommand)"

    } #begin

    Process {
        if (-Not $Detailed) {
            Write-Verbose -Message "Getting bare listing for $path"
            $sb = [scriptblock]::Create("$rar lb '$path'")
            [pscustomobject][ordered]@{
                Path     = $path
                FileSize = (Get-Item -Path $path).Length
                Files    = Invoke-Command -ScriptBlock $sb
            }
        }
        else {
            Write-Verbose -Message "Getting technical details for $path"

            $sb = [scriptblock]::Create("$rar vl '$path'")
            Invoke-Command -scriptblock $sb

        } #else technical
    } #process

    End {
        Write-Verbose -Message "Ending $($MyInvocation.Mycommand)"
    } #end
} #end Show-RARContent



Function Show-RARContent2 {
    [cmdletbinding()]

    Param (
        [Parameter(Position = 0, Mandatory = $True,
            HelpMessage = "Enter the path to a .RAR file.",
            ValueFromPipeline = $True)]
        [string]$Path,
        [switch]$Detailed
    )

    Begin {
        Write-Verbose -Message "Starting $($MyInvocation.Mycommand)"

    } #begin

    Process {
        if (-Not $Detailed) {
            Write-Verbose -Message "Getting bare listing for $path"
            $sb = [scriptblock]::Create("$rar lb '$path'")
            [pscustomobject][ordered]@{
                Path     = $path
                FileSize = (Get-Item -Path $path).Length
                Files    = Invoke-Command -ScriptBlock $sb
            }
        }
        else {
            Write-Verbose -Message "Getting technical details for $path"

            $sb = [scriptblock]::Create("$rar vl '$path'")
            $out = Invoke-Command -scriptblock $sb
            $total = ($out | Where-Object { $_ -match "%" } | Select-Object -Last 1).Trim()
            $details = $out | Where-Object { $_ -match "\d{4}-\d{2}-\d{2}" }

            Write-Verbose "Parsing $Total"
            #parse details out of totals
            $totalSplit = $total.split() | Where-Object { $_ }
            [int32]$totalsize = $totalSplit[0].trim()
            [int32]$totalPacked = $totalSplit[1].trim()
            [string]$totalRatio = $totalSplit[2].trim()
            [int32]$totalFiles = $totalSplit[3].trim()


            #parse out the comment line
            #   $comment = (($out | Where-Object { $_ -match "^Comment:" }) -split "Comment: ")[1]

            #create master object for the archive
            [pscustomobject][ordered]@{
                Path        = $Path
                #  Comment     = $comment
                #  Files       = $Files
                TotalFiles  = $totalfiles
                TotalSize   = $totalsize
                TotalPacked = $totalpacked
                TotalRatio  = $totalratio
            }
        } #else technical
    } #process

    End {
        Write-Verbose -Message "Ending $($MyInvocation.Mycommand)"
    } #end
} #end Show-RARContent


$rar = Get-RARExe

Export-ModuleMember -Function Add-RARContent, Test-RARFile, Show-RARContent* -Variable rar

<#

RAR 5.71 x64   Copyright (c) 1993-2019 Alexander Roshal   28 Apr 2019
Registered to Jeffery D. Hicks

Usage:     rar <command> -<switch 1> -<switch N> <archive> <files...>
               <@listfiles...> <path_to_extract\>

<Commands>
  a             Add files to archive
  c             Add archive comment
  ch            Change archive parameters
  cw            Write archive comment to file
  d             Delete files from archive
  e             Extract files without archived paths
  f             Freshen files in archive
  i[par]=<str>  Find string in archives
  k             Lock archive
  l[t[a],b]     List archive contents [technical[all], bare]
  m[f]          Move to archive [files only]
  p             Print file to stdout
  r             Repair archive
  rc            Reconstruct missing volumes
  rn            Rename archived files
  rr[N]         Add data recovery record
  rv[N]         Create recovery volumes
  s[name|-]     Convert archive to or from SFX
  t             Test archive files
  u             Update files in archive
  v[t[a],b]     Verbosely list archive contents [technical[all],bare]
  x             Extract files with full path

<Switches>
  -             Stop switches scanning
  @[+]          Disable [enable] file lists
  ac            Clear Archive attribute after compression or extraction
  ad            Append archive name to destination path
  ag[format]    Generate archive name using the current date
  ai            Ignore file attributes
  ao            Add files with Archive attribute set
  ap<path>      Set path inside archive
  as            Synchronize archive contents
  c-            Disable comments show
  cfg-          Disable read configuration
  cl            Convert names to lower case
  cu            Convert names to upper case
  df            Delete files after archiving
  dh            Open shared files
  dr            Delete files to Recycle Bin
  ds            Disable name sort for solid archive
  dw            Wipe files after archiving
  e[+]<attr>    Set file exclude and include attributes
  ed            Do not add empty directories
  en            Do not put 'end of archive' block
  ep            Exclude paths from names
  ep1           Exclude base directory from names
  ep2           Expand paths to full
  ep3           Expand paths to full including the drive letter
  f             Freshen files
  hp[password]  Encrypt both file data and headers
  ht[b|c]       Select hash type [BLAKE2,CRC32] for file checksum
  id[c,d,p,q]   Disable messages
  ieml[addr]    Send archive by email
  ierr          Send all messages to stderr
  ilog[name]    Log errors to file.\ra
  inul          Disable all messages
  ioff[n]       Turn PC off after completing an operation
  isnd[-]       Control notification sounds
  iver          Display the version number
  k             Lock archive
  kb            Keep broken extracted files
  log[f][=name] Write names to log file
  m<0..5>       Set compression level (0-store...3-default...5-maximal)
  ma[4|5]       Specify a version of archiving format
  mc<par>       Set advanced compression parameters
  md<n>[k,m,g]  Dictionary size in KB, MB or GB
  ms[ext;ext]   Specify file types to store
  mt<threads>   Set the number of threads
  n<file>       Additionally filter included files
  n@            Read additional filter masks from stdin
  n@<list>      Read additional filter masks from list file
  o[+|-]        Set the overwrite mode
  oc            Set NTFS Compressed attribute
  oh            Save hard links as the link instead of the file
  oi[0-4][:min] Save identical files as references
  ol[a]         Process symbolic links as the link [absolute paths]
  oni           Allow potentially incompatible names
  or            Rename files automatically
  os            Save NTFS streams
  ow            Save or restore file owner and group
  p[password]   Set password
  p-            Do not query password
  qo[-|+]       Add quick open information [none|force]
  r             Recurse subdirectories
  r-            Disable recursion
  r0            Recurse subdirectories for wildcard names only
  ri<P>[:<S>]   Set priority (0-default,1-min..15-max) and sleep time in ms
  rr[N]         Add data recovery record
  rv[N]         Create recovery volumes
  s[<N>,v[-],e] Create solid archive
  s-            Disable solid archiving
  sc<chr>[obj]  Specify the character set
  sfx[name]     Create SFX archive
  si[name]      Read data from standard input (stdin)
  sl<size>      Process files with size less than specified
  sm<size>      Process files with size more than specified
  t             Test files after archiving
  ta[mcao]<d>   Process files modified after <d> YYYYMMDDHHMMSS date
  tb[mcao]<d>   Process files modified before <d> YYYYMMDDHHMMSS date
  tk            Keep original archive time
  tl            Set archive time to latest file
  tn[mcao]<t>   Process files newer than <t> time
  to[mcao]<t>   Process files older than <t> time
  ts[m,c,a]     Save or restore file time (modification, creation, access)
  u             Update files
  v<size>[k,b]  Create volumes with size=<size>*1000 [*1024, *1]
  vd            Erase disk contents before creating volume
  ver[n]        File version control
  vn            Use the old style volume naming scheme
  vp            Pause before each volume
  w<path>       Assign work directory
  x<file>       Exclude specified file
  x@            Read file names to exclude from stdin
  x@<list>      Exclude files listed in specified list file
  y             Assume Yes on all queries
  z[file]       Read archive comment from file

#>