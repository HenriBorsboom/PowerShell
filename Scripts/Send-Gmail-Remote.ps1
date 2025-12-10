Clear-Host

$Username = 'user@gmail.com'
$Password = '@Tomic321'
$From = 'user@gmail.com'
$To = 'henri.borsboom@company.com'
$Subject = 'Test3'
$Body = 'Test3'
$PSUsername = 'localhost\localadmin'
$PSPassword = ConvertTo-SecureString -String 'P@ssw0rd' -AsPlainText -Force
$Credentials = New-Object PSCredential($PSUsername,$PSPassword)
$SMTPServer = "smtp.gmail.com"
$SMTPPort = "587"

Invoke-Command -ComputerName RRAS-01 -Credential $Credentials -ArgumentList (,$Username,$Password,$From,$To,$Subject,$Body,$SMTPServer,$SMTPPort) -ScriptBlock {
    Param (
        $Username, `
        $Password, `
        $From, `
        $To, `
        $Subject, `
        $Body, `
        $SMTPServer, `
        $SMTPPort)
    
    #Write-Host $Username
    #Write-Host $Password
    #Write-Host $From
    #Write-Host $To
    #Write-Host $Subject
    #Write-Host $Body

    $SecuredPassword = ConvertTo-SecureString -String $Password -AsPlainText -Force
    $Credentials = New-Object pscredential ($Username,$SecuredPassword)

    Send-MailMessage -From $From `
                    -to $To `
                    -Subject $Subject `
                    -Body $Body `
                    -SmtpServer $SMTPServer `
                    -port $SMTPPort -UseSsl `
                    -Credential $Credentials
    
    #c:\temp\send-gmail.ps1 -Username $Username -Password $Password -From $From -To $To -Subject $Subject -Body $Body
}

