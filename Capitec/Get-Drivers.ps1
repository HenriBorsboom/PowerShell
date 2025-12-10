$Properties = @()
$Properties += ,('DeviceName')
$Properties += ,('Description')
$Properties += ,('FriendlyName')
$Properties += ,('Manufacturer')
$Properties += ,('DriverProviderName')
$Properties += ,('DriverVersion')
$Properties += ,('DriverDate')
$Properties += ,('DeviceClass')
$Properties += ,('IsSigned')
$Properties += ,('Signer')

$Drivers = Get-WmiObject -Class Win32_PnPSignedDriver | Select-Object $Properties
$MyDrivers = @()
ForEach ($Driver in $Drivers) {
    Try {
        $DriverDate = [DateTime]::new((([wmi]"").ConvertToDateTime($Driver.DriverDate)).Ticks, 'Local')
    }
    Catch {
        $DriverDate= ''
    }
    $MyDrivers += ,(New-Object -TypeName PSObject -Property @{
        DeviceName = $Driver.DeviceName
        Description = $Driver.Description
        FriendlyName = $Driver.FriendlyName
        Manufacturer = $Driver.Manufacturer
        DriverProviderName = $Driver.DriverProviderName
        DriverVersion = $Driver.DriverVersion
        DriverDate = $DriverDate
        DeviceClass = $Driver.DeviceClass
        IsSigned = $Driver.IsSigned
        Signer = $Driver.Signer})
        $DriverDate = $null
}
$MyDrivers | Select-Object $Properties | Out-GridView
$MyDrivers #| Export-Csv ('\\CBFP01\Temp\Henri\' + $env:COMPUTERNAME + '_Drivers_' + (Get-Date -Format 'yyyy-MM-dd') + '.csv') -NoTypeInformation -Encoding ascii -Delimiter ','
