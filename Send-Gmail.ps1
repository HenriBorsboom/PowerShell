Function Get-Credentials {

    $Username = "AzurePr0xy"
    $Password = ConvertTo-SecureString -String "YourProxyPassword" -AsPlainText -Force
    $ProxyCreds = New-Object pscredential ($Username,$Password)
    Return $ProxyCreds
}


Function Send-Gmail {
    $From = "user@gmail.com"
    $To = "henri.borsboom@company.com"
    $Subject = "Email Subject"
    $Body = "Insert body text here"
    $SMTPServer = "smtp.gmail.com"
    $SMTPPort = "587"
    
    $Username = "user@gmail.com"
    $Password = ConvertTo-SecureString "YourEmailPassword" -AsPlainText -Force
        
    $GmailCred = New-Object PSCredential ($Username,$Password)

    Send-MailMessage -From $From `
                     -to $To `
                     -Subject $Subject `
                     -Body $Body `
                     -SmtpServer $SMTPServer `
                     -port $SMTPPort -UseSsl `
                     -Credential $GmailCred
                 
}

Get-Credentials
$browser = New-Object System.Net.WebClient
$browser.Proxy.Credentials = $Credentials
Send-Gmail