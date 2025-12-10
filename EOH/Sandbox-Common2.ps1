Function Set-OnTop {
    Param (
        [Parameter(Mandatory=$False, Position=1)]
        [Int64] $ProcessID, `
        [Parameter(Mandatory=$False, Position=2)]
        [Switch] $TopMost, 
        [Parameter(Mandatory=$False, Position=3)]
        [Switch] $RemoveTopMost)
$signature = @’ 
[DllImport("user32.dll")] 
    public static extern bool SetWindowPos( 
    IntPtr hWnd, 
    IntPtr hWndInsertAfter, 
    int X, 
    int Y, 
    int cx, 
    int cy, 
    uint uFlags); 
‘@ 
    $type = Add-Type -MemberDefinition $signature -Name SetWindowPosition -Namespace SetWindowPos -Using System.Text -PassThru
    If ($ProcessID -eq 0) { $ProcessID = $Global:PID }
    $handle = (Get-Process -ID $ProcessID).MainWindowHandle 
    $alwaysOnTop = New-Object -TypeName System.IntPtr -ArgumentList (-1) 

    If ($TopMost -eq $True)       { $type::SetWindowPos($handle, $alwaysOnTop, 0, 0, 0, 0, 0x0003) | Out-Null }
    If ($RemoveTopMost -eq $True) { $type::SetWindowPos($handle, 2, 0, 0, 0, 0, 0x0003) | Out-Null}
}
#Set-OnTop -TopMost -ProcessID 3096
Set-OnTop -RemoveTopMost -ProcessID 3096