
$Params = @{
  MatchTextFilters = @(
    "Alacritty"
    "Python"
  )

  WhereObjectFilters = $(
    { $PSItem.Name -notlike "*Microsoft*" }
  )

  ExcludeTextFilters = @(
    "*Launcher*"
  )
}

$Env:PSModulePath = $Env:PSModulePath + ";./module"

$DebugPreference = "Continue"
$VerbosePreference = "Continue"

Import-Module -Name ./module/InstallerCleaner.psm1 -ErrorAction Stop
Get-CleanupPlan @Params | Invoke-CleanupPlan -WhatIf



