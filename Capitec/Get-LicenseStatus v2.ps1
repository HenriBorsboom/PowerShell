Function Get-LicenseStatus {
    Param (
        [Parameter(Mandatory=$false)]
        [String] $Server = $env:COMPUTERNAME)

    try
    {
        $NameSpace = "Root\CIMV2"
        $wmi = [WMISearcher]""
        $wmi.options.timeout = '0:0:05' #set timeout to 30 seconds
        $query = "Select Name, LicenseFamily, PartialProductKey, LicenseStatus from SoftwareLicensingProduct Where name LIKE '%windows%'"
        $wmi.scope.path = "\\$Server\$NameSpace"
        $wmi.query = $query
        $WMIResult = $wmi.Get() |  Where-Object {$_.name -match ‘windows’ -AND $_.licensefamily -AND $_.PartialProductKey} 
        $LicenseStatus = ""
        Switch ($WMIResult.LicenseStatus) {
            0 {$LicenseStatus = “Unlicensed”} 
            1 {$LicenseStatus = “Licensed”} 
            2 {$LicenseStatus = “Out-Of-Box Grace Period”} 
            3 {$LicenseStatus = “Out-Of-Tolerance Grace Period”} 
            4 {$LicenseStatus = “Non-Genuine Grace Period”} 
            5 {$LicenseStatus = “Notification”} 
            6 {$LicenseStatus = “Extended Grace Period”} 
        }

        $Result = New-Object -TypeName PSObject -Property @{
            Server = $Server
            Name =  $WMIResult.Name
            LicenseStatus = $LicenseStatus
        }
        Return $True, $Result | Select-Object Server, Name, LicenseStatus
    }
    catch {
        Return $False, $_
    }
}

Write-Host "Getting Servers - " -NoNewline
$LastLogonDate = (Get-Date).AddMonths(-3)
$Servers = (Get-ADComputer -Filter {OperatingSystem -like '*server*' -and Enabled -eq $True -and LastLogonDate -gt $LastLogonDate} | Sort-Object Name).Name
Write-host ($Servers.Count.ToString() + ' found') -ForegroundColor Cyan
$FailedServers = @()
$Licenses = @()
For ($i = 0; $i -lt $Servers.Count; $i ++) {
    Write-Host (($i + 1).ToString() + '/' + $Servers.Count.ToString() + ' - Getting license for ' + $Servers[$i] + ' - ') -NoNewline
    $LicenseDetails = Get-LicenseStatus -Server $Servers[$i]
    If ($LicenseDetails[0] -eq $false) {
        Write-Host $LicenseDetails[1] -ForegroundColor Red
        $FailedServers += ,($LicenseDetails)
    }
    Else {
        Write-Host "Complete" -ForegroundColor Green
        $Licenses += ,($LicenseDetails[1])
    }
}
#$FailedServers | Out-GridView
$Licenses | Out-GridView
$Licenses | Where-Object LicenseStatus -eq 'Notification' | Select-Object Server | Out-GridView
$Licenses | Out-File C:\temp\licenses.txt
$Licenses | Export-Csv -Delimiter ";" -Path c:\temp\licenses.csv

#Get-LicenseStatus