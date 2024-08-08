<#
$classes = $(
    "Win32_Bios"
    "Win32_Patch"
    "Win32_PatchFile"
    "Win32_PatchPackage"
    "Win32_Product"
    "Win32_Binary"
    "Win32_SoftwareElement"
)

foreach ($class in $classes) {
    Write-Output "Querying $class"
    Measure-Command {
        Get-CimInstance -ClassName $class -Verbose | ConvertTo-Json | Set-Content -Force -Path "${class}.json"
    }
}

Write-Output "Done at $(Get-Date)."
#>

$DebugPreference = 'Continue'
$ErrorActionPreference = "Stop"

# Get-ItemProperty -Path HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersio‌​n\Installer\UserData‌​  #<InternalUserId>\Pr‌​oducts\<ProductGUID>‌​\InstallProperties
# Get-Item -Path  "Registry::HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Installer\UserData\S-1-5-18\Products\00005109001001400000000000F01FEC\InstallProperties" |
#     Select-Object -ExpandProperty Property

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
            { "InstallPropertiesPsPath" 
            }
            "PsParentPath"
            { "PsPath" 
            }
            default
            { $PSItem 
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

$ProgramsFilename = "./programs.csv"
Write-Host "Found $($AllPrograms.Count) programs on this system."
Write-Host "Writing output to $ProgramsFilename"
$AllPrograms | ConvertTo-Csv | Set-Content -Force -Path $ProgramsFilename

$PatchesFilename = "./patches.csv"
Write-Host "Found $($AllPatches.Count) patches on this system."
Write-Host "Writing output to $PatchesFilename"
$AllPatches | ConvertTo-Csv | Set-Content -Force -Path $PatchesFilename
