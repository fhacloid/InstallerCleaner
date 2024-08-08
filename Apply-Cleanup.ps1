. .\Types.ps1

params (
  [Parameter(Mandatory = $true)]
  [params[]] $ProgramsToDelete
)

foreach ($ProgramToDelete in $ProgramsToDelete)
{
  Write-Host "Removing $ProgramToDelete patches"
  foreach ($Patch in $ProgramToDelete.Patches)
  {
    Remove-Item -Path $Patch.LocalPackage -Force
  }

  Write-Host "Removing $ProgramToDelete"
  Remove-Item -Path $ProgramToDelete.LocalPackage -Force
}
