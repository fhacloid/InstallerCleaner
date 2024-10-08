# Check if we are on repo root:
if (-not (Test-Path -Path ".git"))
{
  Write-Error "Please run this script from the repository root."
  exit
}

Import-Module -Name PSScriptAnalyzer

# Add settings for linter
$settings = @{
  Rules = @{
    PSUseCompatibleSyntax = @{
      Enable = $true
      TargetVersions = @(
        '3.4'
        '5.1'
      )
    }
  }
}

Get-ChildItem ./module/*.p*1 | ForEach-Object {
  Write-Host "Linting $($PSItem.Name)."
  Invoke-ScriptAnalyzer -Path "module/$($PSItem.Name)" -Settings $settings -Severity @("Error", "Warning")
}
