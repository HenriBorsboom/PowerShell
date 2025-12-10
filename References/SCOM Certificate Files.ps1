Function New-CertConfig {
    Param (
        [Parameter(Mandatory=$True, Position=1)]
        [String] $GatewayFQDN)

    If (Test-Path -Path "$Env:HOMEDRIVE\Temp") {
        $CertConfigFile = ( "$Env:HOMEDRIVE\Temp\$GatewayFQDN " + ( '{0:dd-MM-yyyy HH.mm.ss}' -f (Get-Date) ) + ".inf" )
    }
    Else {
        New-Item -Path "$Env:HOMEDRIVE\Temp" -ItemType Directory
        $CertConfigFile = ( "$Env:HOMEDRIVE\Temp\$GatewayFQDN " + ( '{0:dd-MM-yyyy HH.mm.ss}' -f (Get-Date) ) + ".inf" )
    }

    $Configuration = @(        '[NewRequest]'        'Subject="CN=' + $GatewayFQDN + '"'        'Exportable=TRUE'        'KeyLength=2048'        'KeySpec=1'        'KeyUsage=0xf0'        'MachineKeySet=TRUE'        '[EnhancedKeyUsageExtension]'        'OID=1.3.6.1.5.5.7.3.1'        'OID=1.3.6.1.5.5.7.3.2') | Out-File $CertConfigFile -Encoding ascii -Force -NoClobber -ErrorAction Stop

    Return $CertConfigFile
}
Function New-CertRequest {
    Param (
        [Parameter(Mandatory=$True, Position=1)]
        [String] $CertConfigFile)

    $CertRequestFile = ($CertConfigFile.Replace(".inf",".req"))
    CertReq –New –f $CertConfigFile $CertRequestFile
    Get-Content -Path $CertRequestFile
    Get-Content -Path $CertRequestFile | clip.exe
    Write-Host
    Write-Host "Copied content of $CertRequestFile to clipboard"
}
New-CertRequest -CertConfigFile (New-CertConfig -GatewayFQDN "test1.lab.local")