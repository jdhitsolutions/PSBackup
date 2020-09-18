# PSBackup ChangeLog

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
