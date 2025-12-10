$s3location = 'https://s3.dualstack.af-south-1.amazonaws.com/aws-patch-manager-af-south-1-bdd5f65a9/patchbaselineoperations/Amazon.PatchBaselineOperations-1.65.zip'
$downloadpath = 'c:\temp\ssm.zip'
$wc = New-Object System.Net.WebClient
$wc.Proxy = [System.Net.WebRequest]::DefaultWebProxy
$wc.Proxy.Credentials = [System.Net.CredentialCache]::DefaultNetworkCredentials
$wc.DownloadFile($s3location, $downloadpath)