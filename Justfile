# set shell := ["powershell.exe", "-Version", "3.0", "-ExecutionPolicy", "Bypass", "-NoProfile", "-NonInteractive", "-NoLogo", "-Command"]
set shell := ["pwsh", "-ExecutionPolicy", "Bypass", "-NoProfile", "-NonInteractive", "-NoLogo", "-Command"]

sync:
  rsync --exclude .git -avr . win-work:~/projects/altavia/windows_installer_cleaner

check: sync
  ssh win-work 'cd "C:\Users\work\projects\altavia\windows_installer_cleaner" ; .\ci\Lint-PSFiles.ps1'

test-plan-remote: sync check
  ssh win-work 'cd "C:\Users\work\projects\altavia\windows_installer_cleaner" ; .\ci\Test-Plan.ps1'

commit:
  git add .
  git commit -m "Update files"
  git push origin main

watch +command:
  watchexec -w . -w Justfile -e psm1 -c -r just {{command}}

setup:
  Install-Module -Name PSScriptAnalyzer -Force
