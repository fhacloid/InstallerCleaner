
$Params = @{
  MatchTextFilter = @(
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
    "Alacritty"
    "Python"
  )

  WhereObjectFilter = $(
    { $PSItem.Name -notlike "*Microsoft*" }
  )

  ExcludeTextFilter = @(
    "*Launcher*"
  )
}

.\Plan-Cleanup.ps1 @Params -ToCsvFile "Plan.csv"

Get-Content -Path "Plan.csv" | Out-Host
