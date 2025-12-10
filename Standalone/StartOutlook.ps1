$ErrorActionPreference = "SilentlyContinue"
If (Get-Process -Name OUTLOOK) {
    $sig = '[DllImport("user32.dll")] public static extern bool ShowWindowAsync(IntPtr hWnd, int nCmdShow);'
    Add-Type -MemberDefinition $sig -name NativeMethods -namespace Win32
    $hwnd = @(Get-Process OUTLOOK)[0].MainWindowHandle
    # Restore window
    [Win32.NativeMethods]::ShowWindowAsync($hwnd, 3)
}
Else {
    Start-Process OUTLOOK
}