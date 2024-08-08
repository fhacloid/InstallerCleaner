# Check if we are on repo root:
if ((Get-Location).Path -ne ".git")
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

Get-ChildItem *.ps1 | ForEach-Object {
  Write-Host "Linting $($PSItem.Name)."
  Invoke-ScriptAnalyzer -Path $PSItem.Name -Settings $settings
}
