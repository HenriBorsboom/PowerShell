Function test {
    Param ($ProcessName)

    Add-Type @"
        using System;
        using System.Runtime.InteropServices;
        public class Window {
            [DllImport("user32.dll")]
            [return: MarshalAs(UnmanagedType.Bool)]
                public static extern bool GetWindowRect(IntPtr hWnd, out RECT lpRect);
            [DllImport("User32.dll")]
                public extern static bool MoveWindow(IntPtr handle, int x, int y, int width, int height, bool redraw);
            [DllImport("user32.dll")] 
                public static extern bool SetWindowPos(IntPtr hWnd, IntPtr hWndInsertAfter, int X, int Y, int cx, int cy, uint uFlags); 
        }
        public struct RECT
        {
            public int Left;        // x position of upper-left corner
            public int Top;         // y position of upper-left corner
            public int Right;       // x position of lower-right corner
            public int Bottom;      // y position of lower-right corner
        }
"@
    $Rectangle = New-Object RECT
    $Handle = (Get-Process -Name $ProcessName).MainWindowHandle
    $Return = [Window]::GetWindowRect($Handle,[ref]$Rectangle)
    
    If ($Return) {
        $Height = $Rectangle.Bottom - $Rectangle.Top
        $Width = $Rectangle.Right - $Rectangle.Left
        $TopLeft = New-Object System.Management.Automation.Host.Coordinates -ArgumentList $Rectangle.Left, $Rectangle.Top
        $BottomRight = New-Object System.Management.Automation.Host.Coordinates -ArgumentList $Rectangle.Right, $Rectangle.Bottom
        $Object = [pscustomobject]@{
            ProcessName = $ProcessName
            Height      = $Height
            Width       = $Width
            TopLeftX    = $TopLeft.X
            TopLeftY    = $TopLeft.Y
            BottomRightX = $BottomRight.X
            BottomRightY = $BottomRight.Y
        }
        $Object | Ft -AutoSize
        If ($OnTop -eq $True) { [Window]::SetWindowPos($Handle, -1, $Height, $Width, $TopLeftX, $BottomRightY, 0x0003) | Out-Null }
        If ($Normal -eq $True) { [Window]::SetWindowPos($Handle, -2, $Height, $Width, 0, 0, 0x0003) | Out-Null }
    }
}

Test -ProcessName "Notepad"