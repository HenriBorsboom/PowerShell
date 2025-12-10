Clear-Host 

$OutFile = ('C:\DiskShadows\' + $env:COMPUTERNAME + " - " + '{0:yyyy-MM-dd}' -f (Get-Date) + ".txt") 
diskshadow -s C:\DiskShadows\DiskShadowScript.txt | Out-File $OutFile -Encoding ascii -Force -NoClobber 
$SMTPServer = 'za-smtp-outbound-1.mimecast.co.za' 
$SMTPPort = 587 
$To = 'msbackups@eoh.com' 
$From = 'eohrt_backups@eoh.com' 
$Subject = ('Disk Shadows - ' + $env:COMPUTERNAME + " - " + '{0:yyyy-MM-dd}' -f (Get-Date)) 
$Credential = New-Object -TypeName PSCredential($From, (ConvertTo-SecureString -String 'v3Rystr0nGP@ssword2019' -AsPlainText -Force)) 
[String] $Body = Get-Content $OutFile 
Send-MailMessage -SmtpServer $SMTPServer -From $From -To $To -Subject $Subject -Attachments $OutFile -Body $Body -Credential $Credential 