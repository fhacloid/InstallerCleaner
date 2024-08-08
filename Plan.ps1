. .\Types.ps1
. .\Get-Programs.ps1

$DebugPreference = "Continue"
$InformationPreference = "Continue"
$ErrorActionPreference = "Stop"

# [Program[]] $Programs = Get-Content -Path ./programs.csv | ConvertFrom-Csv
# [Patch[]] $Patches = Get-Content -Path ./patches.csv | ConvertFrom-Csv
#
[Program[]] $Programs = Get-Programs

$TextFilter = @(
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

$WhereFilter = $(
  { $PSItem.DisplayName -notlike "*Microsoft*" }
)


$ProgramsToClean = @()
foreach ($filter in $TextFilter)
{
  $ProgramsToClean += $Programs | Where-Object DisplayName -like "*$filter*"
}

foreach ($filter in $WhereFilter)
{
  $ProgramsToClean = $ProgramsToClean | Where-Object -FilterScript $filter
}

# Get sizes
$ProgramsToClean | ForEach-Object {
  $size = Get-Item $PSItem.LocalPackage | Select-Object -Property Length
  $PSItem.Size = $size.Length
}

$ProgramsToClean `
| Format-Table DisplayName, @{Label="Size (MB)"; Expression={[math]::Round($PSItem.Size / 1MB, 2)}} `
| Out-Host

$TotalSize = $($ProgramsToClean | Measure-Object -Property Size -Sum).Sum
if ($TotalSize -gt 1GB)
{
  $ScaleText = "GB"
  $RoundedTotalSize = [math]::Round($TotalSize / 1GB, 2)
} else
{

  $RoundedTotalSize = [math]::Round($TotalSize / 1MB, 2)
  $ScaleText = "MB"
}

Write-Host "Total to be freed: $RoundedTotalSize $ScaleText"
