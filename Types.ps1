Add-Type @"
public struct patch {
  public string ID;
  public string LocalPackage;
  public string PSPath;
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
}
"@

$PreviousErrorActionPreference = $ErrorActionPreference
$ErrorActionPreference = "Continue"

# Add types as class for my LSP

class Program
{
  [string] $Name
  [string] $InstallLocation
  [string] $InstallSource
  [string] $LocalPackage
  [string] $PsPath
  [string] $InstallPropertiesPsPath
  [string] $Patches
  [string] $PatchPSPath
  [long] $Size
}

class Patch
{
  [string] $ID
  [string] $LocalPackage
  [string] $PSPath
}

$ErrorActionPreference = $PreviousErrorActionPreference
