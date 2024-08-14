# set shell := ["powershell.exe", "-Version", "3.0", "-ExecutionPolicy", "Bypass", "-NoProfile", "-NonInteractive", "-NoLogo", "-Command"]
set shell := ["pwsh", "-ExecutionPolicy", "Bypass", "-NoProfile", "-NonInteractive", "-NoLogo", "-Command"]

help:
  just --list

# Sync files to windows wm
sync:
  rsync --delete --exclude .git -avr . win-work:~/projects/altavia/windows_installer_cleaner

# Sync files and lint psm1 files
check: sync
  ssh win-work 'cd "C:\Users\work\projects\altavia\windows_installer_cleaner" ; .\ci\Lint-PSFiles.ps1'

# Sync files and run tests
test-plan-remote: sync check
  ssh win-work 'cd "C:\Users\work\projects\altavia\windows_installer_cleaner" ; .\ci\Test-Plan.ps1'

# Commit the whole repo
commit:
  git add .
  git commit -m "Update files"
  git push origin main

# Upload the powershell module to
upload:
  curl -F @module/InstallerCleaner.psm1 https://pastefile.owl.cycloid.io

# Watch for filechange and execute the just {{command}}
watch +command:
  watchexec -w . -w ci -e psm1 -e ps1 -c -r just {{command}}

# Install dependencies
setup:
  Install-Module -Name PSScriptAnalyzer -Force
