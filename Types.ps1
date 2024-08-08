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
