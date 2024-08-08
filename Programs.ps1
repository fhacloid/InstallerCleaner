function Get-Programs
{
  $Users = Get-ChildItem "Registry::HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Installer\UserData" -Name

  $Products = @{}

  foreach ($User in $Users)
  {
    $Products[$User] = Get-ChildItem "Registry::HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Installer\UserData\${user}\Products\" -Name
  }


  $AllPrograms = New-Object System.Collections.Generic.List[System.Object]
  $AllPatches = New-Object System.Collections.Generic.List[System.Object]
  # Retrieve Programs informations
  $Products.GetEnumerator() | ForEach-Object {
    $User = $_.Key

    # Get Programs
    foreach ($ProductGUID in $_.Value)
    {
      #$HKey = "HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Installer\UserData\S-1-5-18\Products\00005109001001400000000000F01FEC\InstallProperties"
      $HKey = "HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Installer\UserData\${User}\Products\${ProductGUID}"
      Write-Debug "Fetching installation informations from User ${User} for program $ProductGUID"

      $Data = [PSCustomObject]@{}
      $Keys = Get-ChildItem "Registry::$HKey" -Name
      switch( $Keys )
      {
        "InstallProperties"
        {
          Write-Debug "Checking $PSItem for $HKey"
          $InstallProperties = Get-ItemProperty -Path "Registry::$HKey\$PSItem"
          $InstallProperties `
          | Select-Object -Property DisplayName,LocalPackage,InstallSource,InstallLocation,PSPath,PSParentPath `
          | Get-Member -MemberType "`*Property" `
          | ForEach-Object {
            # Here we rename some properties to be relevant for the object we are creating.
            $PName = switch ($PSItem.Name)
            {
              "PsPath"
              {
                "InstallPropertiesPsPath"
              }
              "PsParentPath"
              {
                "PsPath"
              }
              default
              {
                $PSItem
              }
            }
            $Data | Add-Member -Type "NoteProperty" -Name $PName -Value $InstallProperties.($PSItem.Name)
          }
        }

        "Patches"
        {
          Write-Debug "Checking $PSItem for $HKey"
          $Patches = Get-ItemProperty -Path "Registry::$HKey\$PSItem"
          $Data | Add-Member -Type "NoteProperty" -Name "Patches" -Value $Patches.AllPatches
          $Data | Add-Member -Type "NoteProperty" -Name "PatchPSPath" -Value $Patches.PSPath
        }

        Default
        {
        }
      }

      $AllPrograms.Add($Data)
    }

    # Get Patches
    try
    {
      $UserPatches = Get-ChildItem Registry::HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Installer\UserData\${User}\Patches
    } catch [System.Management.Automation.ItemNotFoundException]
    {
      # Some users don't have patches, we don't care
      $UserPatches = @()
    }

    ForEach ($Patch in $UserPatches)
    {
      $PatchData = [PSCustomObject]@{}
      $PatchData | Add-Member -Type NoteProperty -Name Name -Value $Patch.Name
      $PatchData | Add-Member -Type NoteProperty -Name LocalPackage -Value $($Patch | Get-ItemProperty | Select-Object -Property LocalPackage)
      $AllPatches.Add($PatchData)
    }
  }

  return @{
    Programs = $AllPrograms
    Patches = $AllPatches
  }
}

