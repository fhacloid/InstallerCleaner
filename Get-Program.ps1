$DebugPreference = 'Continue'
$ErrorActionPreference = "Stop"

. .\Types.ps1

function Get-Programs
{
  # First list all users that have installed programs on this machine
  $Users = Get-ChildItem "Registry::HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Installer\UserData" -Name

  # We retrieve the list of Products in the registry for each user
  $Products = @{}
  foreach ($User in $Users)
  {
    $Products[$User] = Get-ChildItem "Registry::HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Installer\UserData\${user}\Products\" -Name
  }


  $AllPrograms = New-Object System.Collections.Generic.List[Program]

  # Retrieve Programs informations
  $Products.GetEnumerator() | ForEach-Object {
    $User = $PSItem.Key
    $Products = $PSItem.Value

    # Get Programs
    foreach ($ProductGUID in $Products)
    {
      $HKey = "HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Installer\UserData\${User}\Products\${ProductGUID}"
      Write-Debug "Fetching installation informations from User ${User} for program $ProductGUID"

      $Keys = Get-ChildItem "Registry::$HKey" -Name
      [Program] $ProgramData = [Program]@{ }
      switch( $Keys )
      {
        "InstallProperties"
        {
          Write-Debug "Checking $PSItem for $HKey"
          $InstallProperties = Get-ItemProperty -Path "Registry::$HKey\$PSItem"
          $ProgramData.Name = $InstallProperties.DisplayName
          $ProgramData.InstallLocation = $InstallProperties.InstallLocation
          $ProgramData.InstallSource = $InstallProperties.InstallSource
          $ProgramData.LocalPackage = $InstallProperties.LocalPackage
          $ProgramData.PsPath = $InstallProperties.PSPath
          $ProgramData.PsParentPath = $InstallProperties.PSParentPath
        }

        "Patches"
        {
          Write-Debug "Checking $PSItem for $HKey"
          $(Get-ItemProperty -Path "Registry::$HKey\$PSItem").AllPatches | ForEach-Object {
            # Each PSItem represent a Patch ID
            # We fetch the propeties in the registry
            $Patch = Get-ItemProperty -Path "Registry::HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Installer\UserData\${User}\Patches\${PSItem}"
            $ProgramData.Patches += [Path]@{
              ID = $PSItem
              LocalPackage = $Patch.LocalPackage
              PSPath = $Patch.PSPath
            }
          }
        }

        Default
        {
        }
      }

      $AllPrograms.Add($ProgramData)
    }
  }

  return $AllPrograms
}

# $ProgramsFilename = "./programs.csv"
# Write-Host "Found $($AllPrograms.Count) programs on this system."
# Write-Host "Writing output to $ProgramsFilename"
# $AllPrograms | ConvertTo-Csv | Set-Content -Force -Path $ProgramsFilename
# 
# $PatchesFilename = "./patches.csv"
# Write-Host "Found $($AllPatches.Count) patches on this system."
# Write-Host "Writing output to $PatchesFilename"
# $AllPatches | ConvertTo-Csv | Set-Content -Force -Path $PatchesFilename
