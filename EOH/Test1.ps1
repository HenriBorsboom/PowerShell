#&lt;# .SYNOPSIS Script Settings File Demo #&gt;

[CmdletBinding()]
Param ()

#--
# Variables
# --

$mydir = Split-Path -Parent $MyInvocation.MyCommand.path

# import email settings from config file
[xml]$ConfigFile = get-content "$myDirSettings.xml"

$Smtpsettings = @{
    To = $ConfigFile.Settings.EmailSettings.Mailto
    From = $ConfigFile.Settings.EmailSettings.MailFrom
    Subject = "Email subject line goes here"
    Smtpserver = $ConfigFile.Settings.EmailSettings.SMTPServer
    }

$Body = "Email Body goes here"

#---
# script
# --

Try {
    Send-MailMessage @smtpsettings -Body $body -ErrorAction Stop
}
Catch {
    Write-Warning $_.Exception.Message
}

#---
# End
#----