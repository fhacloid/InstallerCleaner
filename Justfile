# set shell := ["powershell.exe", "-Version", "3.0", "-ExecutionPolicy", "Bypass", "-NoProfile", "-NonInteractive", "-NoLogo", "-Command"]
set shell := ["pwsh", "-ExecutionPolicy", "Bypass", "-NoProfile", "-NonInteractive", "-NoLogo", "-Command"]

check:
  #! powershell.exe
  Write-Host "Linting files"
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

  Import-Module -Name PSScriptAnalyzer

  Get-ChildItem Procedure.ps1 | % {
    Write-Host "Linting $($PSItem.Name)."
    Invoke-ScriptAnalyzer -Path $PSItem.Name -Settings $settings
  }

test: check
  .\Procedure.ps1

test-plan:
  .\Plan.ps1

commit:
  git add .
  git commit -m "Update files"
  git push origin main

watch +command:
  watchexec -w . -e Justfile -e ps1 -c -r just {{command}}

setup:
  Install-Module -Name PSScriptAnalyzer -Force
