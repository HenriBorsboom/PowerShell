# Function to simulate key press
function Send-Keys {
    param (
        [string]$keys
    )
    Add-Type -AssemblyName System.Windows.Forms
    [System.Windows.Forms.SendKeys]::SendWait($keys)
}

# Function to get clipboard text
function Get-ClipboardText {
    Add-Type -AssemblyName System.Windows.Forms
    return [System.Windows.Forms.Clipboard]::GetText()
}

# Register the hotkey (F3)
Add-Type @"
using System;
using System.Runtime.InteropServices;
public class Hotkey {
    [DllImport("user32.dll")]
    public static extern bool RegisterHotKey(IntPtr hWnd, int id, uint fsModifiers, uint vk);
    [DllImport("user32.dll")]
    public static extern bool UnregisterHotKey(IntPtr hWnd, int id);
}
"@

$global:hotkeyId = 1
$null = [Hotkey]::RegisterHotKey([IntPtr]::Zero, $global:hotkeyId, 0, 0x72) # 0x72 is the virtual key code for F3

# Event handler for hotkey press
$hotkeyHandler = {
    $clipboardText = Get-ClipboardText
    Send-Keys $clipboardText
}

# Register the event
$hotkeyEvent = Register-ObjectEvent -InputObject $global:hotkeyId -EventName "HotkeyPressed" -Action $hotkeyHandler

# Keep the script running
Write-Host "Press F3 to type clipboard text. Press Escape to exit."
while ($true) {
    if ([System.Console]::KeyAvailable) {
        $key = [System.Console]::ReadKey($true)
        if ($key.Key -eq 'Escape') {
            Write-Host "Script execution stopped by user."
            break
        }
    }
}

# Unregister the hotkey and clean up
[Hotkey]::UnregisterHotKey([IntPtr]::Zero, $global:hotkeyId)
Unregister-Event -SourceIdentifier $hotkeyEvent.Name