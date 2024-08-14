#---------------------------------------- 
# Custom types
Add-Type @"
public struct patch {
  public string ID;
  public string LocalPackage;
  public string PSPath;
  public long Size;
}

public struct program {
  public string Name;
  public string InstallLocation;
  public string InstallSource;
  public string LocalPackage;
  public string PsParentPath;
  public string PsPath;
  public patch[] Patches;
  public long Size;
  public long PatchSize;
}
"@

#---------------------------------------- 
# Fetch all current installed programs installation in the registry
function Get-Programs
{
  [CmdletBinding()]
  param (
    # Custom program selection filter
    # filters the output of the following command:
    # Get-ItemProperty "Registry::HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Installer\UserData\*\Products\*\InstallProperties"
    [Parameter(Mandatory = $false)]
    [ScriptBlock] $FilterCondition = {
      $_.LocalPackage -ne "" -And $_.InstallSource -ne ""
    }
  )

  # We retrieve the list of Products in the registry
  $ProgramsProperties = Get-ItemProperty "Registry::HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Installer\UserData\*\Products\*\InstallProperties" `
  | Where-Object $FilterCondition

  $AllPrograms = New-Object System.Collections.Generic.List[Program]

  # Retrieve Programs informations
  foreach ($InstallProperties in $ProgramsProperties)
  {
    if ($InstallProperties.LocalPackage.Length -eq 0)
    {
      Write-Verbose "Skipping $($InstallProperties.DisplayName), no local package found."
      continue
    }

    Write-Debug "Processing $InstallProperties"
    [Program] $ProgramData = [Program]@{ }

    $ProgramData.Name = $InstallProperties.DisplayName
    $ProgramData.InstallLocation = $InstallProperties.InstallLocation
    $ProgramData.InstallSource = $InstallProperties.InstallSource
    $ProgramData.LocalPackage = $InstallProperties.LocalPackage
    $ProgramData.PsPath = $InstallProperties.PSPath
    $ProgramData.PsParentPath = $InstallProperties.PSParentPath

    # Calculate size of package
    try
    {
      $ProgramData.Size = Get-ItemProperty -Path $InstallProperties.LocalPackage | Select-Object -ExpandProperty Length
    } catch
    {
      Write-Warning "Didn't found localpackage for '$($InstallProperties.DisplayName)' on path '$($InstallProperties.LocalPackage)' on filesystem."
      Write-Warning "This probably means it has already been deleted."
      $ProgramData.Size = 0
    }

    Write-Debug "Checking patches for $($InstallProperties.DisplayName)"
    Get-ItemProperty -Path $InstallProperties.PSParentPath `
    | Select-Object -ExpandProperty AllPatches `
    | ForEach-Object {
      try
      {
        # Each PSItem represent a Patch ID
        # We fetch the propeties in the registry
        $Patch = Get-ItemProperty -Path "Registry::HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Installer\UserData\*\Patches\${PSItem}"
        $ProgramData.Patches += [Path]@{
          ID = $PSItem
          LocalPackage = $Patch.LocalPackage
          PSPath = $Patch.PSPath
          Size = $(Get-ItemProperty -Path $Patch.LocalPackage | Select-Object -ExpandProperty Length)
        }
      } catch 
      {
        # This means this software has no patch or that its path is empty, so we do nothing.
        # I expose the error in debug in case of weird behaviour
        Write-Debug "Failed to get patch: $Patch"
        Write-Debug $_
      }
    }

    # Calculate total patch size
    $ProgramData.PatchSize = $($ProgramData.Patches | Measure-Object -Property Size -Sum).Sum
    $AllPrograms.Add($ProgramData)
  }

  return $AllPrograms
}

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

  Get-CleanupPlan -WhereObjectFilters $({ $PSItem.Name -notlike "*Microsoft*" }) `
    -MatchTextFilters "Windows Store", "Office" `
    -ExcludeTextFilters "*.NET*"

  .EXAMPLE

  # You can pipe directly to apply after

  Get-CleanupPlan -WhereObjectFilters $({ $PSItem.Name -notlike "*Microsoft*" }) `
    -MatchTextFilters "Windows Store", "Office" `
    -ExcludeTextFilters "*.NET*" | Invoke-CleanupPlan.ps1

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

  Get-CleanupPlan.ps1 @Params

#>
function Get-CleanupPlan
{
  [CmdletBinding()]
  param (
    [Parameter(Mandatory = $false)]
    [string[]] $MatchTextFilters,

    [Parameter(Mandatory = $false)]
    [string[]] $ExcludeTextFilters,

    [Parameter(Mandatory = $false)]
    [ScriptBlock[]] $WhereObjectFilters
  )

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

  return ,$ProgramPlan
}

function Remove-InstallerProgram
{
  [CmdletBinding(SupportsShouldProcess, ConfirmImpact = "High")]
  param (
    [Parameter(Mandatory = $true, ValueFromPipeline = $true)]
    [Program] $Program,

    [switch] $Force
  )
  
  if ($Force -and -not $Confirm)
  {
    $ConfirmPreference = 'None'
  }
  
  try
  {
    if ($Program.Patches.Length -ne 0)
    {
      if ($PSCmdlet.ShouldProcess($Program.Name, "delete all patches for program"))
      {
        Remove-InstallerProgramPatches -Program $Program -Force:$Force
      }
    }

    if ($PSCmdlet.ShouldProcess($Program.LocalPackage, "delete LocalPackage file"))
    {
      Remove-Item -Path $Program.LocalPackage -Force
    }

    if ($PSCmdlet.ShouldProcess($Program.PSPath, "delete LocalPackage path from registry"))
    {
      Set-ItemProperty -Path $Program.PsPath -Name "LocalPackage" -Value ""
    }
  } catch
  {
    Write-Warning "Failed to clean $($Program.Name)"
    Write-Warning "You may need to check manually, see object info below"
    $Program | Out-Host
    exit 1
  }

  return
}

function Remove-InstallerProgramPatches
{
  [CmdletBinding(SupportsShouldProcess)]
  param(
    [Parameter(Mandatory = $true, ValueFromPipeline = $true)]
    [Program] $Program,

    [Parameter(Mandatory = $false)]
    [switch] $Force
  )

  if ($Force -and -not $Confirm)
  {
    $ConfirmPreference = 'None'
  }
  
  $Program.Patches | ForEach-Object {
    {
      try
      {
        if ($PSCmdlet.ShouldProcess($_.ID, "delete patch"))
        {
          Remove-Item -Path $_.LocalPackage -Force
        }

        if ($PSCmdlet.ShouldProcess($_.PSPath, "remove LocalPackage on registry key"))
        {
          Set-ItemProperty -Path $_.PSPath -Name "LocalPackage" -Value ""
        }
      } catch
      {
        Write-Warning "Failed to clean patch $($_.ID) for program $($Program.Name)"
        Write-Warning "Faulty patch:"
        $PSItem | Out-Host

        Write-Warning "Used in program:"
        $Program | Out-Host
        exit 1
      }
    }
  }
}

<#

  .SYNOPSIS

  Script that will purge remaining .msi and .msp files in windows installs
  from a plan generated by Get-CleanupPlan.ps1

  Should be compatible for at least Windows server 2012 using Powershell v3.4

  .PARAMETER ProgramsToDelete

  List of programs to delete, generate using Get-CleanupPlan.ps1

  .PARAMETER DryRun

  Do not delete anything, just print what would have been deleted

  .EXAMPLE

  Get-CleanupPlan | .\Invoke-CleanupPlan -DryRun
#>

function Invoke-CleanupPlan
{
  [CmdletBinding(SupportsShouldProcess, ConfirmImpact = "High")]
  param (
    [Parameter(ValueFromPipeline = $true)]
    [Program[]] $ProgramsToDelete = @(),

    [Switch]$Force
  )

  if ($ProgramsToDelete.Length -eq 0)
  {
    return
  }

  # Define delete command to be real or not
  # depending on the -DryRun switch
  if (-not $WhatIfPreference)
  {
    Write-Warning "Delete mode is active, this is irreversible, you can cancel within 3 seconds."
    Start-Sleep -Seconds 3
  }

  if ($Force -and -not $Confirm)
  {
    $ConfirmPreference = 'None'
  }
  
  # Execute order 66
  foreach ($ProgramToDelete in $ProgramsToDelete)
  {
    Remove-InstallerProgram -Program $ProgramToDelete -WhatIf:$WhatIfPreference -Force:$Force
  }
}

<#
  .SYNOPSIS Scan registry for entry with absent LocalPackage .msi path and remove them from registry.
#>
function Remove-OrphanedLocalPackageRef
{
  [CmdletBinding(SupportsShouldProcess, ConfirmImpact = "High")]
  param (
    [switch] $Force
  )

  if ($Force -and -not $Confirm)
  {
    $ConfirmPreference = 'None'
  }

  $OrphanedPackages = Get-ItemProperty "Registry::HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Installer\UserData\*\Products\*\InstallProperties" `
  | Where-Object { $_.LocalPackage -ne "" -and $(-not $(Test-Path $_.LocalPackage)) }

  foreach ($OrphanedPackage in $OrphanedPackages)
  {
    "Remove orphaned package $($OrphanedPackage.LocalPackage) from registry key $($OrphanedPackage.PSPath)" | Out-Host
    Set-ItemProperty -Path $OrphanedPackage.PSPath -Name "LocalPackage" -Value "" `
      -WhatIf:$WhatIfPreference -Force:$Force
  }
}

<#
  .SYNOPSIS
  Remove orphaned .msi and .msp files in 'C:\Windows\Installer' that don't have references in the registry.
#>
function Remove-OrphanInstallerFiles
{
  [CmdletBinding(SupportsShouldProcess, ConfirmImpact = "High")]
  param (
    [switch] $Force
  )

  $ReferencedPackages = Get-ItemProperty "Registry::HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Installer\UserData\*\Products\*\InstallProperties" `
  | Where-Object { $_.LocalPackage -ne "" } | Select-Object -ExpandProperty LocalPackage
    
  $ReferencedPatches = Get-ItemProperty "Registry::HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Installer\UserData\*\Patches\*" | Select-Object -ExpandProperty LocalPackage

  # Get all .msi and .msp files in C:\Windows\installer
  $InstallerFiles = Get-ChildItem -Recurse -Path "C:\Windows\installer\" -Filter *.ms* `
  | Where-Object { $_.Extension -in ".msi",".msp" }

  $OrphanFile = $InstallerFiles | Where-Object {
    switch ($_.Extension)
    {
      ".msi"
      { $_.FullName -notin $ReferencedPackages 
      }
      ".msp"
      { $_.FullName -notin $ReferencedPatches 
      }
    }
  }

  if ($WhatIfPreference -eq $True)
  {
    $OrphanFile `
    | Format-Table -AutoSize FullName,@{Label="Size (MB)"; Expression={[math]::Round($PSItem.Length / 1MB, 2)}} `
    | Out-Host
    $TotalSize = [math]::Round(($OrphanFile | Measure-Object -Property Length -Sum).Sum / 1MB, 2)
    "Total to be freed: $TotalSize MB" | Out-Host
  }

  if ($PSCmdlet.ShouldProcess("Remove $($OrphanFile.Count) files from C:\Windows\Installer","",""))
  {
    foreach ($File in $OrphanFile)
    {
      Remove-Item -Path $File.FullName -Force:$Force
      Write-Verbose "Freed $([math]::Round($File.Length / 1MB, 2))"
    }
  }
}

Export-ModuleMember -Function @(
  "Invoke-CleanupPlan"
  "Get-CleanupPlan"
  "Remove-OrphanedLocalPackageRef"
  "Remove-OrphanInstallerFiles"
)
