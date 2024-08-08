
$Params = @{
  MatchTextFilters = @(
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

  WhereObjectFilters = $(
    { $PSItem.Name -notlike "*Microsoft*" }
  )

  ExcludeTextFilters = @(
    "*Launcher*"
  )
}

Import-Module -Name ./module/InstallerCleaner.psm1
Apply-Cleanup -DryRun -ProgramsToDelete $(Plan-Cleanup @Params )
