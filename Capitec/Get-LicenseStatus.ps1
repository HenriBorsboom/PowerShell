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

Get-LicenseStatus