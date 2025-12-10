<#  This is a test PS script that runs a Server Report using PowerShell 5.1 #>
<#  PowerShell may need to run as an Administrator the lines are enabled to edit the registry enabling TLS 1.2 #>
<#  The server report uses the LiveVault ID, which can be the Customer or Group ID.

<# Show version of PowerShell #>
write-host " "
write-host "---------------------------------------------------------------------------------------- "
write-host "---------------------------------------------------------------------------------------- "
write-host "---------------------------------------------------------------------------------------- "
write-host "PowerShell version "
$PSVersionTable.PSVersion
write-host " "
Write-host "Note: You may need to enable TLS 1.2 in the registry to use the APIs."
Write-host " "
<# Enable the following line to allow this script to update the registry enabling TLS 1.2 #>
<# 
Set-ItemProperty -Path HKLM:\Software\Microsoft\.NETFramework\"v4.0.30319\" -Name "SchUseStrongCrypto" -value 1
Set-ItemProperty -Path HKLM:\Software\Wow6432Node\Microsoft\.NETFramework\"v4.0.30319\" -Name "SchUseStrongCrypto" -value 1
#>


$user=Read-Host -Prompt "Enter LV-Login"
$passwordSec=Read-Host -Prompt "Enter LV-Password"  -AsSecureString
$password= [Runtime.InteropServices.Marshal]::PtrToStringAuto([Runtime.InteropServices.Marshal]::SecureStringToBSTR($passwordSec))

<# Retrieve the  token.  #>
$auth=Invoke-RestMethod https://api.livevault.com/api/authorize -Method Post -Body "grant_type=password&username=$user&password=$password"

$headers = New-Object "System.Collections.Generic.Dictionary[[String],[String]]"
$headers.Add("Authorization", 'Bearer ' + $auth.access_token)


Invoke-RestMethod https://api.livevault.com/api/v1/customers -Headers $headers 

<# Generate a server report for the Customer or Group  using its LiveVailt ID  #>

$ID=Read-Host -Prompt "Enter Customer or Group ID"
Invoke-RestMethod https://api.livevault.com/api/v1/customers/$ID -Headers $headers 

$ID2=Read-Host -Prompt "Enter customer or partner ID"
Invoke-RestMethod https://api.livevault.com/api/v1/customers/$ID2 -Headers $headers 
