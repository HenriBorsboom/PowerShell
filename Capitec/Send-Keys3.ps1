# Define the C# class
$source = @"
using System;
using System.Runtime.InteropServices;
using System.Threading;

public class KeyboardSimulator
{
    [DllImport("user32.dll")]
    private static extern void keybd_event(byte bVk, byte bScan, uint dwFlags, UIntPtr dwExtraInfo);

    private const int KEYEVENTF_KEYUP = 0x0002;

    public static void SimulateKeyPress(string text)
    {
        foreach (char c in text)
        {
            byte keyCode = (byte)char.ToUpper(c);
            keybd_event(keyCode, 0, 0, UIntPtr.Zero);
            keybd_event(keyCode, 0, KEYEVENTF_KEYUP, UIntPtr.Zero);
            Thread.Sleep(50); // Adjust the delay as needed
        }
    }
}
"@

# Compile the C# class
Add-Type -TypeDefinition $source
write-host "starting sleep"
start-sleep -Seconds 5
# Use the custom class to simulate typing
[KeyboardSimulator]::SimulateKeyPress("Hello, world!")