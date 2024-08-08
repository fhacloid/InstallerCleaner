<#
  .SYNOPSIS

  Script that helps purge .msi and .msp files in windows installs

  SHould be compatible for at least Windows server 2012 using Powershell v3.4
#>

$DebugPreference = "Continue"
$InformationPreference = "Continue"
$ErrorActionPreference = "Stop"

# Check version
if ($PSVersionTable.PSVersion.Major -lt 3 -and $PSVersionTable.PSVersion.Minor -lt 4)
{
  Write-Error "This script is compatible with powershell >= 3.4, please update your powershell version."
}

. .\Programs.ps1

$Programs = Get-Programs

Write-Host $Programs.Programs[0]
