Function pause ($message)
{
    # Check if running Powershell ISE
    if ($psISE)
    {
        Add-Type -AssemblyName System.Windows.Forms
        [System.Windows.Forms.MessageBox]::Show("$message")
    }
    else
    {
        Write-Host "$message" -ForegroundColor Yello
        $x = $host.ui.RawUI.ReadKey("NoEcho,IncludeKeyDown")
    }
}
pause "message"

