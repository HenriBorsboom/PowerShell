$apiImports = @"
    [DllImport("user32.dll")]
    public static extern bool SetWindowPos(IntPtr hWnd, IntPtr hWndInsertAfter, int X,int Y, int cx, int cy, uint uFlags);

    [DllImport("user32.dll")]
    public static extern IntPtr GetForegroundWindow();

    static readonly IntPtr HWND_TOPMOST = new IntPtr(-1);
    static readonly IntPtr HWND_NOTOPMOST = new IntPtr(-2);

    const UInt32 SWP_NOSIZE = 0x0001;
    const UInt32 SWP_NOMOVE = 0x0002;

    const UInt32 TOPMOST_FLAGS = SWP_NOMOVE | SWP_NOSIZE;

    public static void MakeTopMost (IntPtr fHandle) {
        SetWindowPos(fHandle, HWND_TOPMOST, 0, 0, 0, 0, TOPMOST_FLAGS);
    }
"@;

# Import the necessary Win32 API functions and IDs we need.
$app = Add-Type -MemberDefinition $apiImports -Name Win32Window -Namespace Sandbox -ReferencedAssemblies System.Windows.Forms -PassThru;
Add-Type -AssemblyName System.Windows.Forms

try
{
    # Write basic instructions.
    Write-Host "Select a window to pin on top by clicking on it and wait for 5 seconds...";
    $clipboardText = [System.Windows.Forms.Clipboard]::GetText()

    # Initiate the 5 second sleep timer.
    Start-Sleep -Seconds 5;

    # Get the current foreground window handle.
    #$activeHandle = $app::GetForegroundWindow();

    # Set that as the topmost window using the Win32 API.
    [System.Windows.Forms.SendKeys]::SendWait($clipboardText)
    
    # Debug output for the active handle.
    Write-Verbose "Setting handle: $activeHandle to TOPMOST state...";
}
catch
{
    # In case of an error, print out the basic details.
    Write-Error "Failed to get active Window details. More info: $_";    
}

# Load the .NET assembly for SendKeys


# Get the clipboard text


# Simulate typing the clipboard content



