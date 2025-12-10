Function Send-Report {
    Param (
        [Parameter(Mandatory=$true, Position=1)]
        [String] $To, `
        [Parameter(Mandatory=$true, Position=2)]
        [String] $From, `
        [Parameter(Mandatory=$true, Position=3)]
        [String] $Subject, `
        [Parameter(Mandatory=$true, Position=4)]
        [String] $Report)
        
    $SMTPServer = "10.10.16.146"
    $Message = New-Object System.Net.Mail.MailMessage ($From, $To)
    $Message.Subject = $Subject
    $Message.IsBodyHTML = $true
    $Message.Body = $Report
    
    $SMTP = New-Object Net.Mail.SmtpClient($smtpServer)
    $SMTP.Send($Message)
}