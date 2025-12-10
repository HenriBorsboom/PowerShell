$SMTPServer = "royalmail.gold.co.za"
$From       = "vcheck@gold.co.za"
$To         = "henri.borsboom@eoh.com"
$Subject    = "Testing SMTP relay"
$Body       = "Test email"

Send-MailMessage -SmtpServer $SMTPServer -Body $Body -From $From -Subject $Subject -To $To 