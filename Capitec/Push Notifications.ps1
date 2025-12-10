# Pushbullet API Token
$apiKey = "o.UB6yGbEcWBblTcsRPmOSCHgHpxMeq9fu"

# Notification Message
$message = "Your PowerShell script has completed."

# Send Notification
Invoke-RestMethod -Uri "https://api.pushbullet.com/v2/pushes" `
                  -Method Post `
                  -Headers @{ "Access-Token" = $apiKey } `
                  -Body @{ "type" = "note"; "title" = "PowerShell Script"; "body" = $message }
