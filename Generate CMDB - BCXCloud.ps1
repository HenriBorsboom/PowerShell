Function Domain1Credentials {
    $SecPWD = ConvertTo-SecureString "YourPasswordHere" -AsPlainText -Force
    $Creds = New-Object PSCredential("DOMAIN1\username", $SecPWD)
    Return $Creds
}
Function Domain1ADComputers {
    Param (
        [Parameter(Mandatory=$true, Position=1)]
        [PSCredential] $Creds)
    $Domain1Computers = Get-ADComputer -Filter {Name -like "N*"} -Credential $Creds -Server VMSERVER112
    $Domain1Computers = $Domain1Computers | Sort Name
    $Domain1Computers = $Domain1Computers.Name
    Return $Domain1Computers
}
Function Query-WMI {
    Param (
        [Parameter(Mandatory=$true, Position=1)]
        [String] $Server, `
        [Parameter(Mandatory=$true, Position=2)]
        [String] $WMIQuery, `
        [Parameter(Mandatory=$true, Position=3)]
        [PSCredential] $Creds)

    Try { 
        If ($Server -eq $env:COMPUTERNAME) {
            $WMIResults = Get-WmiObject -Query $WMIQuery -Credential $Creds
        }
        Else {
            $Server = (Resolve-DnsName -Name $Server).IPAddress
            $WMIResults = Get-WmiObject -Query $WMIQuery -ComputerName $Server -Credential $Creds
        }
        Return $WMIResults
    }
    Catch { Return $false }
}

Clear-Host

$Creds = Domain1Credentials
$Domain1Computers = Domain1ADComputers -Creds $Creds
ForEach ($Server in $Domain1Computers) {
    $WMIQuery = "Select SerialNumber from Win32_BIOS"
    Write-Host $Server
    $Test = Query-WMI -Server $Server -WMIQuery $WMIQuery -Creds $Creds
    Write-Host $Test.SerialNumber
}