# This script is to join multiple servers on a domain while the servers are online
# 
# This script is UNTESTED so please be aware that tweaking MAY be required
# This script was built from the TechNet reference at:
# https://technet.microsoft.com/en-us/library/hh849798(v=wps.620).aspx   (Example 5)
#
# As per the TechNet article, the DomainName variable can be in the following format:
# <Domain (NetBIOS Name)> OR <Domain (FQDN)>
# Example:
# Domain01 OR domain01.local
#
# The $Servers variable defined in the script, should contain all the Servers that needs to be
# joined to the domain. The computer name must be resolvable  via DNS from the server you are
# running the script. I would suggest running the script on a Domain Controller.
#
# The servers defined in the $Servers variable must also be able to resolve the domain name
# from the server itself.
#
# Although not specified on the TechNet article, Windows Remote Management should be running
# on both the target and source server

Param (
    [Parameter(Mandatory=$True, Position = 1)]
    [String] $DomainName)

Try {
    Write-Host "Local Administrator Credentials required for TARGET servers" -ForegroundColor Yellow
    $LocalUsername = Read-Host "Username: "
    $LocalPassword = Read-Host "Password: " -AsSecureString
    $LocalCredentials = New-Object PSCredential ($LocalUsername, $LocalPassword) -ErrorAction Stop
} # Obtain and create Local Administrator PSCredential
Catch {
    Write-Host "Unable to create Local Administrator PSCredentialObject" -ForegroundColor Red
    Break
}

Try {
    Write-Host "Domain Join Credentials required for the domain" -ForegroundColor Yellow
    $DomainUsername = Read-Host "Username: "
    $DoaminPassword = Read-Host "Password: " -AsSecureString
    $DomainJoinCredentials = New-Object PSCredential ($DomainUsername, $DoaminPassword) -ErrorAction Stop
} # Obtain and create Domain Join PSCredential
Catch {
    Write-Host "Unable to create Domain Join PSCredentialObject" -ForegroundColor Red
    Break
}

$Servers = @(
    "VIP-Cloud-SCCM", `
    "VIP-Cloud-CPGP", `
    "VIP-CLOUD-IDL", `
    "VIP-CLOUD-QLINK", `
    "VIP-Cloud-ESS", `
    "VIP-Cloud-Medscheme", `
    "VIP-CLOUD-SAMEngineering", `
    "VIP-Cloud_Citrix_Secure_Gateway1", `
    "VIP-CURO", `
    "VIP-CLOUD-BDC", `
    "VIP-Cloud-XenApp1", `
    "VIP-Cloud-XenApp2", `
    "VIP-Cloud-SQL", `
    "VIP-CLOUD-PPL", `
    "VIP-CLOUD-STORTECH", `
    "VIP-Cloud-MangolongoloTransport", `
    "VIP-Cloud-HRToolbox", `
    "VIP-CLOUD-FOCUS", `
    "VIP-CLOUD-QSA", `
    "VIP-CLOUD-MQA", `
    "VIP-CLOUD-GMT", `
    "VIP-CLOUD-IZAZI", `
    "VIP-CLOUD-FGF", `
    "VIP-LDE", `
    "VIP-MORE", `
    "VIP-CLOUD-BIC", `
    "VIP-CLOUD-ASCENT", `
    "VIP-CLOUD-BAR", `
    "VIP-CLOUD-H2R", `
    "VIP-CREATIVE", `
    "VIP-CLOUD-FFC", `
    "VIP-CLOUD-DEUTS", `
    "VIP-CLOUD-SRAS", `
    "VIP-CLOUD-DB", `
    "VIP-EFKON", `
    "VIP-PG_LABOUR", `
    "VIP-CLOUD-WPACK", `
    "VIP-CLOUD-PSC", `
    "VIP-CLOUD-MACSF", `
    "VIP-CLOUD-TEST", `
    "VIP-CONVISTA", `
    "VIP-TRIDENT", `
    "VIP-MRM", `
    "VIP-RUSMAR", `
    "VIP-GearHold", `
    "VIP-Limberger", `
    "VIP-ASSET", `
    "VIP-ELS", `
    "VIP-MOTION", `
    "VIP-VIKING", `
    "VIP-BINGO", `
    "VIP-PENFORD", `
    "VIP-WESTERN", `
    "VIP-RG_CONS", `
    "VIP-Cloud-Medscheme2", `
    "VIP-P-CORP", `
    "VIP-TFSE", `
    "VIP-VETUS", `
    "VIP-MEDSCHEME", `
    "VIP-CORREDOR", `
    "VIP-RECKITT", `
    "VIP-ARMADA", `
    "VIP-SPACE", `
    "VIP-FISHING", `
    "VIP-DUMMY", `
    "VIP-MOTHERS", `
    "VIP-SACLAWA", `
    "VIP-OCTOGEN", `
    "VIP-DEMO-ESS", `
    "VIP-COAL", `
    "VIP-TAXI", `
    "VIP-GPI", `
    "VIP-JWT", `
    "VIP-ENSIGHT", `
    "VIP-FCB", `
    "VIP-AXIOMATIC", `
    "VIP-FALCORP", `
    "VIP-SYNERGY", `
    "VIP-CLOUD-FTP", `
    "VIP-CLOUD-NAGIOS", `
    "VIP-HRM", `
    "VIP-PERNOD", `
    "VIP-AFB", `
    "VIP-GP_CONS", `
    "VIP-HERITAGE", `
    "VIP-GAUTENG", `
    "VIP-CAMBRIDGE", `
    "VIP-CLOUD-BCSG", `
    "VIP-DONAVENTA", `
    "VIP-STUDIO", `
    "VIP-LIQUID", `
    "VIP-LEAD", `
    "VIP-REALPAY", `
    "VIP-TERRASAN", `
    "VIP-VALE")

ForEach ($Server in $Servers) {
    Try {
        Write-Host "Attempting to add " -NoNewline
        Write-Host $Server -NoNewline -ForegroundColor Yellow
        Write-Host " to " -NoNewline
        Write-Host $DomainName -NoNewline -ForegroundColor Yellow
        Write-Host " - " -NoNewline
            $Empty = Add-Computer -ComputerName $Server -LocalCredential $LocalCredentials -DomainName $DomainName -Credential $DomainJoinCredentials -Restart -Force
        Write-Host "Complete" -ForegroundColor Green
    }
    Catch {
        Write-Host "Failed"
        Write-Output $_
    }
}