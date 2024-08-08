<#
  .SYNOPSIS

  Fetch the list of programs artefacts from windows installer to be cleaned up.

  Can be filtered with paramters

  .PARAMETER MatchTextFilters

  Filter the list of programs using `-like "*$MatchTextFiler*"` syntax

  .PARAMETER ExcludeTextFilters

  Text match to exclude (can use globs)

  .PARAMETER WhereObjectFilters

  List of scriptblock to filter the list of programs

  .EXAMPLE

  Plan-Cleanup.ps1 -WhereObjectFilters $({ $PSItem.Name -notlike "*Microsoft*" }) `
    -MatchTextFilters "Windows Store", "Office" `
    -ExcludeTextFilters "*.NET*"

  .EXAMPLE

  # You can pipe directly to apply after

  Plan-Cleanup.ps1 -WhereObjectFilters $({ $PSItem.Name -notlike "*Microsoft*" }) `
    -MatchTextFilters "Windows Store", "Office" `
    -ExcludeTextFilters "*.NET*" | Apply-Cleanup.ps1

  .EXAMPLE

  # Using parameter splattings
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

  Plan-Cleanup.ps1 @Params

#>

param(
  [Parameter(Mandatory = $false)]
  [string[]] $MatchTextFilters,

  [Parameter(Mandatory = $false)]
  [string[]] $ExcludeTextFilters,

  [Parameter(Mandatory = $false)]
  [ScriptBlock[]] $WhereObjectFilters
)

. .\Types.ps1
. .\Get-Programs.ps1

$InformationPreference = "Continue"
$ErrorActionPreference = "Stop"

[Program[]] $Programs = Get-Programs
[Program[]] $ProgramPlan = @()

foreach ($matchFilter in $MatchTextFilters)
{
  $ProgramPlan += $Programs | Where-Object Name -like "*$matchFilter*"
}

foreach ($whereFilter in $WhereObjectFilters)
{
  $ProgramPlan = $ProgramPlan | Where-Object -FilterScript $whereFilter
}

foreach ($excludeFilter in $ExcludeTextFilters)
{
  $ProgramPlan = $ProgramPlan | Where-Object Name -NotLike "$excludeFilter"
}

# Display plan
$DisplayPlan = $ProgramPlan `
| Format-Table Name, `
@{Label="Size (MB)"; Expression={[math]::Round($PSItem.Size / 1MB, 2)}}, `
@{Label="Patch Size (MB)"; Expression={[math]::Round($PSItem.PatchSize / 1MB, 2) } }

$TotalSize = $($ProgramPlan | Measure-Object -Property Size -Sum).Sum + $($ProgramPlan | Measure-Object -Property PatchSize -Sum).Sum
if ($TotalSize -gt 1GB)
{
  $ScaleText = "GB"
  $RoundedTotalSize = [math]::Round($TotalSize / 1GB, 2)
} else
{

  $RoundedTotalSize = [math]::Round($TotalSize / 1MB, 2)
  $ScaleText = "MB"
}

$DisplayPlan | Out-Host
"Total to be freed: $RoundedTotalSize $ScaleText" | Out-Host

return $ProgramPlan
