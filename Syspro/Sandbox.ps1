[console]::TreatControlCAsInput = $true
while ($true)
{
    write-host "Processing..."
    if ([console]::KeyAvailable)
    {
        $key = [system.console]::readkey($true)
        if (($key.modifiers -band [consolemodifiers]"control") -and ($key.key -eq "C"))
        {
            Add-Type -AssemblyName System.Windows.Forms
            if ([System.Windows.Forms.MessageBox]::Show("Are you sure you want to exit?", "Exit Script?", [System.Windows.Forms.MessageBoxButtons]::YesNo) -eq "Yes")
            {
                "Terminating..."
                break
            }
        }
    }
}