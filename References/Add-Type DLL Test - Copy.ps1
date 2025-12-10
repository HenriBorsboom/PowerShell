# SetWindowText
$signature = @"
    [DllImport("user32.dll")]public static extern bool SetWindowText(IntPtr hWnd, String lpString);
"@
    $showWindowAsync = Add-Type -MemberDefinition $signature -Name "Win32SetWindowText" -Namespace Win32Functions -PassThru 
    # Minimize the Windows PowerShell console
    $showWindowAsync::SetWindowText((Get-Process -Id $pid).MainWindowHandle, "Test")
    # Restore it
    $showWindowAsync::SetWindowText((Get-Process -Id $pid).MainWindowHandle, "Fail")