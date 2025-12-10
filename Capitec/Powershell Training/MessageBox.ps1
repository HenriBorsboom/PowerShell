Add-Type -AssemblyName PresentationCore,PresentationFramework

$msgBody = "Reboot the computer now?"
$msgTitle = "Confirm Reboot"
$msgButton = 'YesNoCancel'
$msgImage = 'Warning'
$Result = [System.Windows.MessageBox]::Show($msgBody,$msgTitle,$msgButton,$msgImage)
Write-Host "The user chose: $Result [" ($result).value__ "]"