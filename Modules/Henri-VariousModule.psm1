# Various Functions

Function Create-Credentials {
        Param(
            [Parameter(Mandatory=$true,Position=1)]
            [String] $DomainUser, `
            [Parameter(Mandatory=$true,Position=2)]
            [String] $DomainPassword)

        $creds = New-Object System.Management.Automation.PSCredential($DomainUser,$DomainPassword)
        Return $creds
    }

Function Send-Mail {
    Param(
        [Parameter(Mandatory=$true,Position=1)]
        [String] $From, `
        [Parameter(Mandatory=$true,Position=2)]
        [String] $To, `
        [Parameter(Mandatory=$true,Position=3)]
        [String] $Subject, `
        [Parameter(Mandatory=$true,Position=4)]
        [String] $Body, `
        [Parameter(Mandatory=$true,Position=5)]
        [String] $SMTPServer, `
        [Parameter(Mandatory=$true,Position=6)]
        [String] $SMTPPort)

    Send-MailMessage -From $From `
                     -To $To `
                     -Subject $Subject `
                     -Body $Body `
                     -SmtpServer $SMTPServer `
                     -Port $SMTPPort `
                     -UseSsl `
                     -Credential (Get-Credential)
}
