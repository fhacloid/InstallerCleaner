# set shell := ["powershell.exe", "-Version", "3.0", "-ExecutionPolicy", "Bypass", "-NoProfile", "-NonInteractive", "-NoLogo", "-Command"]
set shell := ["pwsh", "-ExecutionPolicy", "Bypass", "-NoProfile", "-NonInteractive", "-NoLogo", "-Command"]

sync:
  rsync --delete --exclude .git -avr *.ps1 win-work:~/projects/altavia\windows_installer_cleaner

check: sync
  ssh win-work 'cd "C:\Users\work\projects\altavia\windows_installer_cleaner" ; .\ci\Lint-PSFiles.ps1'

test: check
  .\Procedure.ps1

test-plan:
  .\Plan.ps1

test-plan-remote: sync check
  ssh win-work 'cd "C:\Users\work\projects\altavia\windows_installer_cleaner" ; .\Plan.ps1'

commit:
  git add .
  git commit -m "Update files"
  git push origin main

watch +command:
  watchexec -w . -e Justfile -e ps1 -c -r just {{command}}

setup:
  Install-Module -Name PSScriptAnalyzer -Force
