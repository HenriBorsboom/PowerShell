Function Send-Email {
    Param(
        [Parameter(Mandatory=$True, Position=1)]
        [string]   $From = $(throw "Please specify from email address !"), `
        [Parameter(Mandatory=$True, Position=2)]
        [string[]] $To = $(throw "Please Specify a destination !"),
        [Parameter(Mandatory=$True, Position=3)]
        [string]   $Subject = "<No Subject>",
        [Parameter(Mandatory=$True, Position=4)]
        [string]   $Body = $(throw "Please specify a content !"),
        [Parameter(Mandatory=$True, Position=5)]
        [string]   $SMTPServer = $(throw "Please specify a SMTP server !"),
        [Parameter(Mandatory=$True, Position=6)]
        [Int16]    $SMTPPort = $(throw "Please specify a SMTP server !"))

    Try {
        Write-Host "Trying to send message with Send-MailMessage - " -NoNewline
        Send-MailMessage -From $From -To $To -Subject $Subject -Body $Body -SMTPServer $SMTPServer -Port $SMTPPort
        Write-Host "Complete" -ForegroundColor Green
    }
    Catch {
        Write-Host "Failed" -ForegroundColor Red
        Write-Host "Trying to send message with System.Net.Mail.MailMessage - " -NoNewline
        $Email = New-Object System.Net.Mail.MailMessage

        ## Fill the fields
        ForEach($MailTo in $To)
        {
          $Email.To.Add($MailTo)
        }

        $Email.From = $From
        $Email.Subject = $Subject
        $Email.Body = $Body

        ## Send the message
        $Client = New-Object System.Net.Mail.SmtpClient $smtpHost
        $client.UseDefaultCredentials = $true
        $client.Send($email)
        Write-Host "Complete" -ForegroundColor Green
    }
}

$Recipients = @()
$Recipients += ,("user1@domain.local")
$Recipients += ,("user2@domain.local")
$Recipients += ,("user3@domain.local")

$Body = @(
"This is a test email
with all the strange details"
)

Send-Email `
    -From "source.email@test.local" `
    -To $Recipients `
    -Subject "Subject Matter" `
    -Body $Body `
    -SMTPServer "SMTPServer1.test.local" `
    -SMTPPort 25