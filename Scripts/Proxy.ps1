$webclient = New-Object System.Net.WebClient
$pwd = ConvertTo-SecureString "YourProxyPassword" -AsPlainText -Force
$creds = New-Object System.Management.Automation.PSCredential("AzurePr0xy",$pwd)
$webclient.Proxy.Credentials = $creds
update-help