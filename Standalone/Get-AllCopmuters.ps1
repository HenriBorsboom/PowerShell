Clear-Host
Write-Host "Creating BCX Cloud Credentials"
$Domain1 = New-Object PSCredential("DOMAIN1\username",(ConvertTo-SecureString "YourPasswordHere" -AsPlainText -Force))
Write-Host "Getting BCX Online Computer Objects in AD"
$Domain2Computers = Get-ADComputer -Filter { ObjectClass -eq "computer" } | Select Name
Write-Host "Getting BCX Cloud Computer Objects in AD"
$Domain1Computers = Invoke-Command -ComputerName VMSERVER112 -Credential $Domain1 -ScriptBlock { Get-ADComputer -Filter { ObjectClass -eq "computer" } | Select Name }
Write-Host "Sorting BCX Online Computers"
$Domain2Computers = $Domain2Computers | Sort Name
Write-Host "Sorting BCX Cloud Computers"
$Domain1Computers = $Domain1Computers | Select Name | Sort Name

$Domain2Hosts = @(
"NRAZUREVMH101", `
"NRAZUREVMH102", `
"NRAZUREVMH103", `
"NRAZUREVMH104", `
"NRAZUREVMH105")

$Domain1Hosts = @(
"NRAPCDBS101.domain1.local", `
"NRAPCDBS201.domain1.local")

$Domain2VMs = @()
$Domain1VMs = @()

ForEach ($Server in $Domain2Hosts) {
    Write-Host "Getting VMs on $Server"
    $VMs = Get-VM -ComputerName $Server | Select Name
    $Domain2VMs = $Domain2VMs + $VMs
}

ForEach ($Server in $Domain1Hosts) {
    Write-Host "Getting VMs on $Server"
    $VMs = Invoke-Command -ComputerName $Server -Credential $Domain1 -ScriptBlock { Get-VM -ComputerName $env:COMPUTERNAME | Select Name }
    $VMs = $VMs | Select Name
    $Domain1VMs = $Domain1VMs + $VMs
}

$AllServers = @()
$AllServers = $AllServers + $Domain2Computers
ForEach ($Server in $Domain1Computers) { If ($AllServers.Contains($Server)) { } Else { $AllServers = $AllServers + $Server } }
#$AllServers = $AllServers + $Domain1Computers
ForEach ($Server in $Domain2Hosts) { If ($AllServers.Contains($Server)) { } Else { $AllServers = $AllServers + $Server } }
#$AllServers = $AllServers + $Domain2Hosts
ForEach ($Server in $Domain1Hosts) { If ($AllServers.Contains($Server)) { } Else { $AllServers = $AllServers + $Server } }
#$AllServers = $AllServers + $Domain1Hosts
ForEach ($Server in $Domain2VMs) { If ($AllServers.Contains($Server)) { } Else { $AllServers = $AllServers + $Server } }
#$AllServers = $AllServers + $Domain2VMs
ForEach ($Server in $Domain1VMs) { If ($AllServers.Contains($Server)) { } Else { $AllServers = $AllServers + $Server } }
#$AllServers = $AllServers + $Domain1VMs

#$AllServers = $AllServers | Select
$AllServers = $AllServers | Sort Name
$AllServers | Out-File $Env:TEMP\computers.txt -Encoding ascii -Force
notepad $Env:TEMP\computers.txt