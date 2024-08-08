$DebugPreference = "Continue"
$InformationPreference = "Continue"
$ErrorActionPreference = "Stop"

# For now, we will read from csv

$Programs = Get-Content -Path ./programs.csv | ConvertFrom-Csv
$Patches = Get-Content -Path ./patches.csv | ConvertFrom-Csv

$Programs[0] | Out-Host
$Patches[0] | format-list | Out-Host

$Whitelist = @(
  "Windows Store"
  "Windows SDK ARM64"
  "Microsoft Visual C++"
  "Adobe "
  "Microsoft .NET"
  "Microsoft Office"
  "Microsoft Word"
  "Microsoft Lync"
  "Microsoft Groove"
  "Microsoft Publisher"
  "Microsoft PowerPoint"
  "Microsoft SharePoint"
  "Microsoft Excel"
  "Microsoft Access"
  "Microsoft InfoPath"
  "Microsoft OneNote"
  "Microsoft X"
  "Microsoft DCF"
  "MSI Development Tools"
)


$ProgramsToClean = $Programs `
| Where-Object DisplayName -ne "" `
| Select-Object DisplayName,InstallLocation,LocalPackage `
| Where-Object {
  foreach ($filter in $Whitelist)
  {
    $PSItem.DisplayName -like "*$filter*"
  }
}

# Get sizes
$ProgramsToClean | ForEach-Object {
  $PSItem | 
}
