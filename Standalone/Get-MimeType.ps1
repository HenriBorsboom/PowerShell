#way 1: using pinvoke  
<#  
  .NOTES  
      Author: greg zakahrov  
#>  
param(  
  [Parameter(Mandatory=$true, ValueFromPipeline=$true)]  
  [ValidateScript({Test-Path $_})]  
  [String]$File  
)  
  
Write-Host ($File = cvpa $File) -fo Yellow -no  
':' + (Add-Type -Mem @'  
  [DllImport("urlmon.dll", CharSet = CharSet.Unicode)]  
  internal static extern Int32 FindMimeFromData(  
      IntPtr pBC,  
      String pwzUrl,  
      [MarshalAs(UnmanagedType.LPArray, ArraySubType=UnmanagedType.I1, SizeParamIndex = 3)]  
      Byte[] pBuffer,  
      UInt32 cbSize,  
      String pwzMimeProposed,  
      UInt32 dwMimeFlags,  
      out IntPtr ppwzMimeOut,  
      Int32 dwReserved  
  );  
    
  public static String GetMimeType(String file) {  
    IntPtr mimeout;  
    UInt32 content;  
    Byte[] buf;  
    String mime = null;  
      
    FileStream fs = null;  
      
    try {  
      content = (UInt32)new FileInfo(file).Length;  
      if (content > 4096) content = 4096;  
        
      fs = File.OpenRead(file);  
      buf = new Byte[content];  
      fs.Read(buf, 0, buf.Length);  
        
      if (FindMimeFromData(IntPtr.Zero, file, buf, content, null, 0, out mimeout, 0) != 0) {  
        throw new Win32Exception();  
      }  
        
      mime = Marshal.PtrToStringUni(mimeout);  
      Marshal.FreeCoTaskMem(mimeout);  
    }  
    catch (Exception e) {  
      Console.WriteLine(e.Message);  
    }  
    finally {  
      if (fs != null) fs.Close();  
    }  
      
    return mime;  
  }  
'@ -Name UrlmonWrap -NameSpace Urlmon -Using System.IO, `  
System.ComponentModel -PassThru)::GetMimeType($File)  
  
#way 2: using incapsulated method GetMimeMapping  
function Get-MimeType {  
  <#  
    .NOTES  
        Author: greg zakharov  
  #>  
  param(  
    [Parameter(Mandatory=$true, ValueFromPipeline=$true)]  
    [ValidateScript({Test-Path $_})]  
    [String]$File  
  )  
    
  Add-Type -AssemblyName System.Web  
  $File = cvpa $File  
    
  Write-Host $File`: -f Yellow -no  
  ([AppDomain]::CurrentDomain.GetAssemblies() | ? {  
    $_.ManifestModule.ScopeName.Equals('System.Web.dll')  
  }).GetType(  
    'System.Web.MimeMapping'  
  ).GetMethod(  
    'GetMimeMapping', [Reflection.BindingFlags]40  
  ).Invoke(  
    $null, @($File)  
  )  
}  
  
#way 3: using registry  
function Get-MimeType {  
  <#  
    .NOTES  
        Author: greg zakharov  
  #>  
  param(  
    [Parameter(Mandatory=$true, ValueFromPipeline=$true)]  
    [ValidateScript({Test-Path $_})]  
    [String]$File  
  )  
    
  $res = 'application/unknown'  
    
  try {  
    $rk = [Microsoft.Win32.Registry]::ClassesRoot.OpenSubKey(  
      ($ext = ([IO.FileInfo](($File = cvpa $File))).Extension.ToLower())  
    )  
  }  
  finally {  
    if ($rk -ne $null) {  
      if (![String]::IsNullOrEmpty(($cur = $rk.GetValue('Content Type')))) {  
        $res = $cur  
      }  
      $rk.Close()  
    } #if  
  }  
    
  Write-Host $File`: -f Yellow -no  
  $res  
} 