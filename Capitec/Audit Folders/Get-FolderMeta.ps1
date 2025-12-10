Add-Type -MemberDefinition @"
  using System;
  using System.Runtime.InteropServices;
  using Microsoft.Win32.SafeHandles;
  [StructLayout(LayoutKind.Sequential)]
  public struct FILE_BASIC_INFO {
    public long CreationTime, LastAccessTime, LastWriteTime, ChangeTime;
    public uint FileAttributes;
  }
  public class Win32 {
    [DllImport("kernel32.dll", SetLastError=true)]
    public static extern SafeFileHandle CreateFile(
      string lpFileName, uint dwDesiredAccess, uint dwShareMode,
      IntPtr lpSecurityAttributes, uint dwCreationDisposition,
      uint dwFlagsAndAttributes, IntPtr hTemplateFile);
    [DllImport("kernel32.dll", SetLastError=true)]
    public static extern bool GetFileInformationByHandleEx(
      SafeFileHandle hFile, int FileInformationClass,
      out FILE_BASIC_INFO fileInformation, int bufferSize);
    [DllImport("advapi32.dll", SetLastError=true)]
    public static extern uint GetSecurityInfo(
      SafeFileHandle handle, uint objectType, uint securityInfo,
      out IntPtr ppsidOwner, out IntPtr ppsidGroup,
      out IntPtr ppDacl, out IntPtr ppSacl, out IntPtr ppSecurityDescriptor);
  }
"@ -Name "RawMeta" -Namespace RawFS

function Get-RawFolderMeta {
  param([string]$Path)
  # open dir handle
  $GENERIC_READ = 0x80000000; $FILE_FLAG_BACKUP_SEMANTICS=0x02000000
  $h = [RawFS.Win32]::CreateFile($Path, $GENERIC_READ,3,0,3,$FILE_FLAG_BACKUP_SEMANTICS,0)
  if($h.IsInvalid){ throw "Handle error: $([Runtime.InteropServices.Marshal]::GetLastWin32Error())" }

  # basic times
  $info = New-Object RawFS.FILE_BASIC_INFO
  [RawFS.Win32]::GetFileInformationByHandleEx($h,0,[ref]$info,[Runtime.InteropServices.Marshal]::SizeOf($info)) | Out-Null

  # owner SID
  $pOwner= [IntPtr]::Zero; $pGrp=$pDacl=$pSacl=$pSec= [IntPtr]::Zero
  [RawFS.Win32]::GetSecurityInfo($h,1,1,[ref]$pOwner,[ref]$pGrp,[ref]$pDacl,[ref]$pSacl,[ref]$pSec) | Out-Null
  $sid   = New-Object System.Security.Principal.SecurityIdentifier($pOwner)
  $who   = $sid.Translate([System.Security.Principal.NTAccount]).Value

  [PSCustomObject]@{
    FolderPath     = $Path
    CreatedDate    = [DateTime]::FromFileTimeUtc($info.CreationTime)
    LastAccessDate = [DateTime]::FromFileTimeUtc($info.LastAccessTime)
    CreatedBy      = $who
  }
}

# usage:
Get-ChildItem C:\Temp -Directory -Recurse |
  Where-Object {($_.FullName -split '\\').Count -le 5} |
  ForEach-Object { Get-RawFolderMeta $_.FullName }
