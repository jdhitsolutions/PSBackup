# PSBackup ChangeLog

## January 24, 2021

+ Modified `Add-BackupEntry` to define an alias `abe`.
+ Modified `BackupSet` parameter in `Add-BackupEntry` to be position 0 since I am mostly piping files to the command.
+ Updated `mybackupfile.format.ps1xml` to display set grouping with an ANSI color sequence.

## January 19, 2021

+ Fixed incorrect property name in `MyBackupReport.ps1`.
+ Added a `Last` parameter to the `Raw` parameter set in `MyBackupReport.ps1`.
+ Created `Get-MyBackupFile` function and `mybackupfile.format.ps1xml` format file. The function has an alias of `gbf`.
+ Updated `LICENSE`.

## January 12, 2021

+ Fixed another bug in `UpdateBackupPending.ps1` to handle situations where CSV only has 1 item.

## December 29, 2020

+ Added more explicit WhatIf code to `DailyIncrementalBackup.ps1`.
+ Fixed bug in `DailyIncrementalBackup.ps1` that wasn't archiving the proper path.

## December 22, 2020

+ Modified `UpdateBackupPending.ps1` to handle situations where CSV only has 1 item.

## November 19, 2020

+ Added `Archive-Oldest.ps1` to rename the oldest file per backup set in a location as an Archive. The goal is to keep at least one archive for a longer period. You might run this quarterly or every 6 months.
+ Modified `LogBackupEntry.ps1` to archive the log file when it is 10MB in size and reset the file.
+ Adding an exclusion file to skip certain paths.
+ Modified `RarBackup.ps1` to set the location via a parameter and not be hardcoded.
+ Modified `myBackupReport.ps1` to include the path in the report header.
+ Modified `myBackupReport.ps1` to include a `-SummaryOnly` parameter. This added parameter sets to the script.

## November 5, 2020

+ Modified `myBackupPending.ps1` to include files with zero size as these might be new files that haven't been updated yet.
+ Updated `myBackupPaths.txt` to use full filesystem paths.
+ Added `UpdateBackupPending.ps1` to update pending CSV files. This will remove deleted files and update file sizes.

## October 17, 2020

+ Fixed bad OneDrive reference in `WeeklyFullBackup.ps1`.
+ Added ValidatePath() to Path parameter in `DailyIncrementalBackup.ps1`.
+ Added error handling to `DailyIncrementalBackup.ps1` and `WeeklyFullBackup.ps1` to abort if the PSRar module can't be loaded.
+ Minor code reformatting.

## October 10, 2020

+ Modified references to OneDrive to use `$ENV:OneDriveConsumer`.
+ Modified `MonitorDailyWatcher.ps1` to use splatting and support `-WhatIf`.

## September 18, 2020

+ Added new paths to `myBackupPaths.txt`
+ Minor changes in backup scripts with `Write-Host` commands to reflect progress and aid in troubleshooting errors.

## September 9, 2020

+ Added transcript log files to incremental and weekly backup scripts. The transcript name uses the `New-CustomFileName` command from the [PSScriptTools](https://github.com/jdhitsolutions/PSScriptTools) module.
+ Modified `MyBackupReport` to show decimal points if the backup file is smaller than 1MB in size.
+ Code reformatting to make some scripts and functions easier to read.

## September 1, 2020

+ Modified `LogBackupEntry.ps1` to only add the file if it doesn't exist in the CSV file and to make logging optional.
+ Modified `myBackupReport.ps1` to format values as MB. Added a header to the report.
+ Modified `myBackupPending.ps1` to pass the backup folder as a parameter.
+ Code cleanup in `PSRar.psm1`.

## August 23, 2020

+ Added BurntToast notifications to some of my commands. This requires the [BurntToast](https://github.com/Windos/BurntToast) module.
+ Updated `README.md`.

## July 14, 2020

+ Reduced OneDrive backup copies to 2.
+ Renamed `Dev-PSRar.psm1` to `PSRar.psm1` so it can be included in the GitHub repo.
+ Changed relative paths in `WeeklyFullBackup.ps1` to use `$PSScriptRoot`.

## April 10, 2020

+ Added the `Dev-PSRar.psm1` file to the module for reference purposes.
+ Added time stamps to trace messages in `DailyIncrementalBackup.ps1`
+ Modified `DailyIncrementalBackup.ps1` to better cleanup temporary backup folder.

## March 31, 2020

+ Modified `WeeklyFullBackup.ps1` to allow backing up a single directory.
+ Added `Add-BackupEntry.ps1` to the project.

## February 8, 2020

+ Bug fixes in `WeeklyBackup.ps1` from changes I made to variable names and paths
+ Moved `RarBackup.ps1` to this repository

## February 7, 2020

+ Initial file upload
+ Revised files to reflect the new location
+ New `README.md`
