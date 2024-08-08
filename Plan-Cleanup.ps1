param(
  [Parameter(Mandatory = $false)]
  [string[]] $MatchTextFilter,

  [Parameter(Mandatory = $false)]
  [string[]] $ExcludeTextFilter,

  [Parameter(Mandatory = $false)]
  [ScriptBlock[]] $WhereObjectFilter,

  [Parameter(Mandatory = $false)]
  [string] $ToCsvFile
)

. .\Types.ps1
. .\Get-Programs.ps1

$InformationPreference = "Continue"
$ErrorActionPreference = "Stop"

[Program[]] $Programs = Get-Programs
[Program[]] $ProgramPlan = @()

foreach ($matchFilter in $MatchTextFilter)
{
  $ProgramPlan += $Programs | Where-Object Name -like "*$matchFilter*"
}

foreach ($whereFilter in $WhereObjectFilter)
{
  $ProgramPlan = $ProgramPlan | Where-Object -FilterScript $whereFilter
}

foreach ($excludeFilter in $ExcludeTextFilter)
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

if ($PSBoundParameters.ContainsKey('ToCsvFile'))
{
  try
  {
    Write-Host "Exporting to $ToCsvFile"
    $DisplayPlan | Export-Csv -Path $ToCsvFile -Force
  } catch
  {
    Write-Warning "Failed to export to $ToCsvFile"
  }
}

return $ProgramPlan
