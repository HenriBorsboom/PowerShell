Function Get-ConnectedNICs {
    Param (
        [Parameter(Mandatory=$true, Position=1)]
        [String] $Server)
        
    $WMIQuery = "Select NetConnectionID,MACAddress,InterfaceIndex from Win32_NetworkAdapter Where NetConnectionStatus = ""2"""
    Try { 
        If ($Server -eq $env:COMPUTERNAME) { $WMIResults = Get-WmiObject -Query $WMIQuery }
        Else                               { $WMIResults = Get-WmiObject -Query $WMIQuery -ComputerName $Server }
        Return $WMIResults
    }
    Catch { Return $false }
}
Function Get-IPDetails {
    Param (
        [Parameter(Mandatory=$true, Position=1)]
        [String] $Server, `
        [Parameter(Mandatory=$true, Position=2)]
        [String] $InterfaceIndex)

    $WMIQuery = "Select IPAddress,IPSubnet,DefaultIPGateway,DNSServerSearchOrder from Win32_NetworkAdapterConfiguration Where InterfaceIndex = ""$InterfaceIndex"""
    Try { 
        If ($Server -eq $env:COMPUTERNAME) { $WMIResults = Get-WmiObject -Query $WMIQuery }
        Else                               { $WMIResults = Get-WmiObject -Query $WMIQuery -ComputerName $Server }
        Return $WMIResults
    }
    Catch { Return $false }
}
Function New-HTML {
    Param (
        [Parameter(Mandatory=$true, Position=1)]
        [Object] $InputObject, `
        [Parameter(Mandatory=$true, Position=2)]
        [Object] $OutputFile, `
        [Parameter(Mandatory=$false, Position=3)]
        [Switch] $Launch, `
        [Parameter(Mandatory=$false, Position=4)]
        [Switch] $Overwrite)
    
    $HTMLHeader="<html>                                                               
                <style>                                               
                BODY{font-family: Arial; font-size: 8pt;}
                H1{font-size: 16px;}
                H2{font-size: 14px;}
                H3{font-size: 12px;}
                TABLE{border: 1px solid black; border-collapse: collapse; font-size: 8pt;}
                TH{border: 1px solid black; background: #dddddd; padding: 5px; color: #000000;}
                TD{border: 1px solid black; padding: 5px; }
                td.pass{background: #7FFF00;}
                td.warn{background: #FFE600;}
                td.fail{background: #FF0000; color: #ffffff;}
                </style>
                <body>
                <h1 align=""center"">Network Details</h1>
                <h2 align=""center""></h2>"
    $HTMLBody = "<H2>Network Details</H2>"

    $HTMLOutput = $InputObject | ConvertTo-HTML -Head $HTMLHeader -Body $HTMLBody
    Switch ($Overwrite) {
        $true  { If ((Get-ChildItem $OutputFile) -eq $true) { Remove-Item $OutputFile -Force -ErrorAction SilentlyContinue } $HTMLOutput = $HTMLOutput | Out-File $OutputFile -Encoding ascii }
        $False { $HTMLOutput = $HTMLOutput | Out-File $OutputFile -Encoding ascii }
    }
    Switch ($Launch) {
        $true { Invoke-Expression $OutputFile }
    }
}
Clear-Host
$ErrorActionPreference = "SilentlyContinue"
$NICDetails = @()
$OutputFile = "C:\temp\test.htm"

$Servers = Get-ADComputer -filter {Name -like "NRA*"}
ForEach ($Server in $Servers.Name) {
    Write-Host "$Server - " -NoNewline
    $ConnectedNICs = Get-ConnectedNICs -Server $Server
                                                            ForEach ($NIC in $ConnectedNICs) {
    $IPDetails  = Get-IPDetails -Server $Server -InterfaceIndex $NIC.InterfaceIndex
	For ($Index = 0; $Index -lt $IPDetails.IPAddress.Count; $Index ++) {
        If ([IPAddress]::TryParse([IPAddress] $IPDetails.IPAddress[$Index], [Ref] "0.0.0.0") -and (([IPAddress] $IPDetails.IPAddress[$Index]).IsIPv6LinkLocal) -eq $false) {
            #region Set Results to Variables
            $AdapterName          = $NIC.NetConnectionID
            $MACAddress           = $NIC.MACAddress
            $InterfaceIndex       = $NIC.InterfaceIndex
            $IPAddress            = $IPDetails.IPAddress[$Index]
            $IPSubnet             = $IPDetails.IPSubnet[$Index]
            $DefaultIPGateway     = $IPDetails.DefaultIPGateway[$Index]
            $DNSServerSearchOrder = $IPDetails.DNSServerSearchOrder -join ";"
            #endregion
            #region Verify Variables are not empty
            If ($AdapterName -eq $null)      {$AdapterName = ""}
            If ($MACAddress -eq $null)       {$MACAddress = ""}
            If ($InterfaceIndex -eq $null)   {$InterfaceIndex = ""}
            If ($IPAddress -eq $null)        {$IPAddress = ""}
            If ($IPSubnet -eq $null)         {$IPSubnet = ""}
            If ($DefaultIPGateway -eq $null) {$DefaultIPGateway = ""}
            #endregion
            #region Populate Output
            $NICDetail = New-Object PSObject -Property @{
                Server               = $Server
                AdapterName          = $AdapterName
                MACAddress           = $MACAddress
                InterfaceIndex       = $InterfaceIndex
                IPAddress            = $IPAddress
                IPSubnet             = $IPSubnet
                DefaultIPGateway     = $DefaultIPGateway
                DNSServerSearchOrder = $DNSServerSearchOrder
            }
            #endregion
            #region Reset Variables
            $AdapterName          = $null
            $MACAddress           = $null
            $InterfaceIndex       = $null
            $IPAddress            = $null
            $IPSubnet             = $null
            $DefaultIPGateway     = $null
            $DNSServerSearchOrder = $null
            #endregion
            $NICDetails += $NICDetail
            $NICDetail
        }
    }
    }
    Write-Host "Complete"
}
New-HTML -InputObject $NICDetails -OutputFile $OutputFile -Overwrite -Launch