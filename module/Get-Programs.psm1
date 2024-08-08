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
  foreach ($HashItem in $Products.GetEnumerator())
  {
    $User = $HashItem.Key
    $Products = $HashItem.Value

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
          $ProgramData.Size = $(Get-ItemPropertyValue -Path $InstallProperties.LocalPackage -Name "Length")
        }

        "Patches"
        {
          Write-Debug "Checking $PSItem for $HKey"
          $(Get-ItemProperty -Path "Registry::$HKey\$PSItem").AllPatches | ForEach-Object {
            try
            {
              # Each PSItem represent a Patch ID
              # We fetch the propeties in the registry
              $Patch = Get-ItemProperty -Path "Registry::HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Installer\UserData\${User}\Patches\${PSItem}"
              $ProgramData.Patches += [Path]@{
                ID = $PSItem
                LocalPackage = $Patch.LocalPackage
                PSPath = $Patch.PSPath
                Size = $(Get-ItemPropertyValue -Path $Patch.LocalPackage -Name "Length")
              }
            } catch [System.Management.Automation.ItemNotFoundException]
            {
              # This means this software has no patch, so we do nothing
            }
          }
        }

        Default
        {
        }
      }

      # Calculate total patch size
      $ProgramData.PatchSize = $($ProgramData.Patches | Measure-Object -Property Size -Sum).Sum
      $AllPrograms.Add($ProgramData)
    }
  }

  return $AllPrograms
}

