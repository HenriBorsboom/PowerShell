[Reflection.Assembly]::LoadFile("C:\myAssemblies\ChilkatDotNet2.dll")

#  The mailman object is used for sending and receiving email.
$mailman = New-Object Chilkat.MailMan

#  Any string argument automatically begins the 30-day trial.
$success = $mailman.UnlockComponent("30-day trial")
if ($success -ne $true) {
    $($mailman.LastErrorText)
    exit
}

#  To connect through an HTTP proxy, set the HttpProxyHostname
#  and HttpProxyPort properties to the hostname (or IP address)
#  and port of the HTTP proxy.  Typical port numbers used by
#  HTTP proxy servers are 3128 and 8080.
$mailman.HttpProxyHostname = "www.my-http-proxy.com"
$mailman.HttpProxyPort = 3128

#  Important:  Your HTTP proxy server must allow non-HTTP
#  traffic to pass.  Otherwise this does not work.

#  Set the SMTP server.
$mailman.SmtpHost = "smtp.chilkatsoft.com"

#  Set the SMTP login/password (if required)
$mailman.SmtpUsername = "myUsername"
$mailman.SmtpPassword = "myPassword"

#  Create a new email object
$email = New-Object Chilkat.Email

$email.Subject = "This is a test"
$email.Body = "This is a test"
$email.From = "Chilkat Support <support@chilkatsoft.com>"
$email.AddTo("Chilkat Admin","admin@chilkatsoft.com")

#  Call SendEmail to connect to the SMTP server via the HTTP proxy and send.
#  The connection (i.e. session) to the SMTP server remains
#  open so that subsequent SendEmail calls may use the
#  same connection.
$success = $mailman.SendEmail($email)
if ($success -ne $true) {
    $($mailman.LastErrorText)
    exit
}

#  Some SMTP servers do not actually send the email until
#  the connection is closed.  In these cases, it is necessary to
#  call CloseSmtpConnection for the mail to be  sent.
#  Most SMTP servers send the email immediately, and it is
#  not required to close the connection.  We'll close it here
#  for the example:
$success = $mailman.CloseSmtpConnection()
if ($success -ne $true) {
    $("Connection to SMTP server not closed cleanly.")
}

$("Mail Sent!")