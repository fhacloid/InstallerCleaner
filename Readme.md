# Windows Installer Cleaner

This is a Powershell Module meant help to clean up Windows Installer files.

Windows installer keeps a copy of all .msi or .msp files in the `C:\Windows\Installer` folder.

Thoses files are used to repair the installation and can take a lot of space on a server.

This script will help you clean them, at your own risk.

## Dependencies

- Powershell 3.4 or higher
- [just](https://just.systems/) for development purposes

## Usage

See command help in the module for more informations.

```powershell
Import-Module InstallerCleaner

Get-Help Plan-Cleanup
```
