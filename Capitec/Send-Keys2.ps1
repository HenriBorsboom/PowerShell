Add-Type -AssemblyName System.Windows.Forms

# Define the text you want to type
$typedText = "Hello, world!"
Start-Sleep -Seconds 5
# Send the keystrokes to the active application
[System.Windows.Forms.SendKeys]::SendWait($typedText)