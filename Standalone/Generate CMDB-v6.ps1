Function Export-Excel {
    Param (
        [Parameter(Mandatory = $True,  Position = 1)]
        [Object[]] $BasicDetails, `
        [Parameter(Mandatory = $True,  Position = 2)]
        [Object[]] $NetworkDetails, `
        [Parameter(Mandatory = $True,  Position = 3)]
        [Object[]] $DiskDetails, `
        [Parameter(Mandatory = $True,  Position = 4)]
        [String]   $Computer)

    $ExcelOutputFile = ($env:USERPROFILE + "\Desktop\CI\$Computer $([DateTime]::Now.ToString('yyyy-MM-dd')).xlsx")
    $ReferenceCI = (Get-Item -Path "C:\Temp\CI\ref.xlsm" -Verbose).FullName
    #region Excel
    Write-Host " - Exporting to - " -NoNewline; Write-Host $ExcelOutputFile -ForegroundColor Yellow -NoNewline; Write-Host " - " -NoNewline
    $ExcelObject = New-Object -ComObject Excel.Application  
    $ExcelObject.Visible = $false 
    $ExcelObject.DisplayAlerts =$false
    $Date= Get-Date -Format "dd-MM-yyyy"
    If ( Test-Path $ReferenceCI ) {  
        $ActiveWorkbook  = $ExcelObject.WorkBooks.Open($ReferenceCI)  
        $ActiveWorksheet = $ActiveWorkbook.Worksheets.Item(1)  
    }
    If ($BasicDetails.Model -like "*Virtual*") {
        $VMHostDetails = Get-RemoteRegistryDetails -Computer $Computer
        $ActiveWorksheet.Cells.Item(8,3)    = "Virtual"                                                     # Tier 1
        $ActiveWorksheet.Cells.Item(141,3)  = $VMHostDetails.PhysicalHost                                   # Physical Host
        $ActiveWorksheet.Cells.Item(142,3)  = $VMHostDetails.ClusterName                                    # Virtual Cluster
    }
    Else {
        $ActiveWorksheet.Cells.Item(8,3)    = "Hardware"                                      # Tier 1
    }
    $ActiveWorksheet.Cells.Item(9,3)    = "Processing Unit"                                                 # Tier 2
    $ActiveWorksheet.Cells.Item(10,3)   = "Server"                                                          # Tier 3
    $ActiveWorksheet.Cells.Item(11,3)   = $BasicDetails.Model                                               # Model
    $ActiveWorksheet.Cells.Item(12,3)   = $BasicDetails.Server                                              # Server
    $ActiveWorksheet.Cells.Item(13,3)   = $BasicDetails.Make                                                # Make
    $ActiveWorksheet.Cells.Item(15,3)   = $BasicDetails.SerialNumber                                        # SerialNumber
    $ActiveWorksheet.Cells.Item(18,3)   = $BasicDetails.SystemRole                                          # SystemRole
    $ActiveWorksheet.Cells.Item(19,5)   = $BasicDetails.Domain                                              # Domain
    $ActiveWorksheet.Cells.Item(87,3)   = $BasicDetails.TotalPhysicalMemory                                 # TotalPhysicalMemory
    $ActiveWorksheet.Cells.Item(91,3)   = $BasicDetails.OSVersion                                           # OSVersion
    $ActiveWorksheet.Cells.Item(92,3)   = $BasicDetails.OSServicePack                                       # OSServicePack
    $ActiveWorksheet.Cells.Item(90,3)   = $BasicDetails.CPUSpeed                                            # CPUSpeed
    $ActiveWorksheet.Cells.Item(88,3)   = $BasicDetails.CPUName                                             # CPUName
    $ActiveWorksheet.Cells.Item(89,3)   = $BasicDetails.NumberOfLogicalProcessors                           # NumberOfLogicalProcessors
        
    $DisksLine = 98
    ForEach ($Line in $DiskDetails){
        $ActiveWorksheet.cells.item($DisksLine, 2) = $Line.DriveLetter
        $ActiveWorksheet.cells.item($DisksLine, 3) = $Line.Size
        $ActiveWorksheet.cells.item($DisksLine, 4) = $Line.VolumeName
        $DisksLine ++
    }
        
    $ActiveWorksheet.Cells.Item(119,3) = [String[]] $NetworkDetails[0].AdapterName                          # NICName
    $ActiveWorksheet.Cells.Item(121,3) = [String[]] $NetworkDetails[0].MACAddress                           # MACAddress
    $ActiveWorksheet.Cells.Item(122,3) = [String[]] $NetworkDetails[0].IPAddress                            # IPEndPoint
    $ActiveWorksheet.Cells.Item(123,3) = [String[]] $NetworkDetails[0].IPSubnet                             # SubnetMask
    $ActiveWorksheet.Cells.Item(124,3) = [String[]] $NetworkDetails[0].DefaultIPGateway                     # Gateway
    $ActiveWorksheet.Cells.Item(125,3) = [String[]] ($NetworkDetails[0].DNSServerSearchOrder -split ";")[0] # DNSPrimary

    $ActiveWorksheet.Cells.Item(119,5) = [String[]] $NetworkDetails[1].AdapterName                          # NICName
    $ActiveWorksheet.Cells.Item(121,5) = [String[]] $NetworkDetails[1].MACAddress                           # MACAddress
    $ActiveWorksheet.Cells.Item(122,5) = [String[]] $NetworkDetails[1].IPAddress                            # IPEndPoint
    $ActiveWorksheet.Cells.Item(123,5) = [String[]] $NetworkDetails[1].IPSubnet                             # SubnetMask
    $ActiveWorksheet.Cells.Item(124,5) = [String[]] $NetworkDetails[1].DefaultIPGateway                     # Gateway
    $ActiveWorksheet.Cells.Item(125,5) = [String[]] ($NetworkDetails[1].DNSServerSearchOrder -split ";")[0] # DNSPrimary
        
    $ActiveWorkbook.SaveAs($ExcelOutputFile)
    $ExcelObject.Quit()
    #Invoke-Expression $OutputFile
    #endregion
}
Function Get-RemoteRegistryDetails {
    Param(
        [Parameter(Mandatory = $True, Position = 1)]
        [String] $Computer)

    Try {
        $Registry         = [Microsoft.Win32.RegistryKey]::OpenRemoteBaseKey('LocalMachine', $Computer)
        $RegistryKey      = $Registry.OpenSubKey("SOFTWARE\\Microsoft\\Virtual Machine\\Guest\\Parameters")
        $PhysicalHostName = $RegistryKey.GetValue("PhysicalHostName")
    }
    Catch { $PhysicalHostName = "Not found" }

    If ($PhysicalHostName -ne "Not found") {
        Try   { $Clustername = Invoke-Command -ComputerName $PhysicalHostName -ScriptBlock { (Get-Cluster).Name } }
        Catch { $Clustername -eq "N/A" }
    }
    Else { $Clustername = "N/A" }
    
    $VMHostDetails = New-Object PSObject @{
        PhysicalHost = $PhysicalHostName;
        ClusterName  = $Clustername;
    }
    
    Return $VMHostDetails
}
Function ComputerObjects-ConsoleUpdate {
    Param (
        [Parameter(Mandatory = $True, Position = 1)]
        [Int64] $Counter, `
        [Parameter(Mandatory = $True, Position = 2)]
        [Int64] $Count, `
        [Parameter(Mandatory = $True, Position = 3)]
        [String] $Computer)

    Write-Host "$Counter\$Count" -NoNewline -ForegroundColor Cyan; Write-Host " - Generating CI for - " -NoNewline; Write-Host $Computer -ForegroundColor Yellow -NoNewline; Write-Host " - " -NoNewline
}
Function Query-WMI {
    Param (
        [Parameter(Mandatory = $True,  Position=1)]
        [String]       $Computer, `
        [Parameter(Mandatory = $True,  Position=2)]
        [String]       $WMIQuery, `
        [Parameter(Mandatory = $False, Position=3)]
        [PSCredential] $DomainCredentials)

    $ErrorActionPreference = "Stop"
    Try { 
        If ($Computer -eq $env:COMPUTERNAME) { 
            $WMIResults = Get-WmiObject -Query $WMIQuery -Credential $DomainCredentials
        }
        Else {
            $ComputerIP = (Resolve-DnsName -Name $Computer).IPAddress; 
            $WMIResults = Get-WmiObject -Query $WMIQuery -ComputerName $ComputerIP -Credential $DomainCredentials
        }
        Return $WMIResults
    }
    Catch { Return $false }
}
Function Get-NICDetails {
    Param (
        [Parameter(Mandatory = $True,  Position = 1)]
        [String]       $Computer, `
        [Parameter(Mandatory = $True,  Position = 2)]
        [PSCredential] $DomainCredentials)
    
    $ConnectedNICs = Query-WMI -Computer $Computer -WMIQuery "Select NetConnectionID,MACAddress,InterfaceIndex from Win32_NetworkAdapter Where NetConnectionStatus = ""2""" -DomainCredentials $DomainCredentials
    
    $NICDetails = @()
    
    ForEach ( $NIC in $ConnectedNICs ) {
        $InterfaceIndex = $NIC.InterfaceIndex
        $IPDetails = Query-WMI -Computer $Computer -WMIQuery "Select IPAddress,IPSubnet,DefaultIPGateway,DNSServerSearchOrder from Win32_NetworkAdapterConfiguration Where InterfaceIndex = ""$InterfaceIndex""" -DomainCredentials $DomainCredentials
        
        For ( $Index = 0; $Index -lt $IPDetails.IPAddress.Count; $Index ++ ) {
            If ([IPAddress]::TryParse([IPAddress] $IPDetails.IPAddress[$Index], [Ref] "0.0.0.0") -and (([IPAddress] $IPDetails.IPAddress[$Index]).IsIPv6LinkLocal) -eq $false) {
                #region Verify Variables are not empty
                If ($NIC.NetConnectionID -eq $null)          { $AdapterName      = "" } Else { $AdapterName      = $NIC.NetConnectionID }
                If ($NIC.MACAddress -eq $null)               { $MACAddress       = "" } Else { $MACAddress       = $NIC.MACAddress }
                If ($NIC.InterfaceIndex -eq $null)           { $InterfaceIndex   = "" } Else { $InterfaceIndex   = $NIC.InterfaceIndex }
                If ($IPDetails.IPAddress.Count -lt 1)        { $IPAddress        = "" } Else { $IPAddress        = $IPDetails.IPAddress }
                If ($IPDetails.IPSubnet.Count -lt 1)         { $IPSubnet         = "" } Else { $IPSubnet         = $IPDetails.IPSubnet }
                If ($IPDetails.DefaultIPGateway.Count -lt 1) { $DefaultIPGateway = "" } Else { $DefaultIPGateway = $IPDetails.DefaultIPGateway }
                #endregion
                #region Populate Output
                $NICDetail = New-Object PSObject -Property @{
                    AdapterName          = $AdapterName
                    MACAddress           = $MACAddress
                    InterfaceIndex       = $InterfaceIndex
                    IPAddress            = $IPAddress
                    IPSubnet             = $IPSubnet
                    DefaultIPGateway     = $DefaultIPGateway
                    DNSServerSearchOrder = $IPDetails.DNSServerSearchOrder -join ";"
                }
                #endregion
                $NICDetails += $NICDetail
            }
        }
    }
    Return $NICDetails
}
Function Get-DiskDetails {
    Param (
        [Parameter(Mandatory = $True,  Position = 1)]
        [String]       $Computer, `
        [Parameter(Mandatory = $True,  Position = 2)]
        [PSCredential] $DomainCredentials)
    
    $Disks         = Query-WMI -Computer $Computer -WMIQuery "Select Caption,Size,VolumeName from Win32_LogicalDisk Where DriveType = 3"                                    -DomainCredentials $DomainCredentials
    $DisksDetails = @()
    
    ForEach ( $Disk in $Disks ) {
        $DiskDetails    = New-Object PSObject -Property @{
            DriveLetter = $Disk.Caption
            Size        = [Math]::Round($Disk.Size/1024/1024/1024)
            VolumeName  = $Disk.VolumeName
        }
        $DisksDetails += $DiskDetails
    }
    Return $DisksDetails
}

Clear-Host
$Domain = Read-Host "Domain Name"
#$Domain = "domain2.local"

$DomainController = Read-Host "Domain Controller"
#$DomainController = "NRAZUREGCS102"
$DomainCredentials = Get-Credential -Message "Enter the credentials for $Domain"

$ComputerObjects = Invoke-Command -ComputerName $DomainController -Credential $DomainCredentials -ScriptBlock { Get-ADComputer -Filter { ObjectClass -eq "computer" } }
$ComputerObjects = $ComputerObjects | Sort Name
$ComputerObjects = $ComputerObjects.Name

$ComputerObjectsCounter = 1
$ComputerObjectsCount   = $ComputerObjects.Count

Write-Host "Total Computer Objects Found: " -NoNewline
Write-Host $ComputerObjectsCount -ForegroundColor Cyan

If (!(Test-Path ($env:USERPROFILE + "\Desktop\CI"))) { New-Item ($env:USERPROFILE + "\Desktop\CI") -ItemType Directory | Out-Null}

ForEach ( $Computer in $ComputerObjects ) {
    ComputerObjects-ConsoleUpdate -Counter $ComputerObjectsCounter -Count $ComputerObjectsCount -Computer $Computer
    
    Try { Test-Connection $Computer -Count 2 -ErrorAction Stop | Out-Null ; $Online = $True } Catch { $Online = $False }
    
    If ($Online = $True) {
        $BasicDetails        = New-Object PSObject -Property @{
            Server                    = [String]     $Computer
            SystemRole                = [String]     (Query-WMI  -Computer $Computer -WMIQuery "Select Description from Win32_OperatingSystem"              -DomainCredentials $DomainCredentials).Description
            Domain                    = [String]     (Query-WMI  -Computer $Computer -WMIQuery "Select Domain from Win32_ComputerSystem"                    -DomainCredentials $DomainCredentials).Domain
            SerialNumber              = [String]     (Query-WMI  -Computer $Computer -WMIQuery "Select SerialNumber from Win32_BIOS"                        -DomainCredentials $DomainCredentials).SerialNumber
            TotalPhysicalMemory       = [Math]::Round((Query-WMI -Computer $Computer -WMIQuery "Select TotalPhysicalMemory from Win32_ComputerSystem"       -DomainCredentials $DomainCredentials).TotalPhysicalMemory/1024/1024/1024)
            OSVersion                 = [String]     (Query-WMI  -Computer $Computer -WMIQuery "Select Caption from Win32_OperatingSystem"                  -DomainCredentials $DomainCredentials).Caption
            OSServicePack             = [String]     (Query-WMI  -Computer $Computer -WMIQuery "Select ServicePackMajorVersion from Win32_OperatingSystem"  -DomainCredentials $DomainCredentials).ServicePackMajorVersion
            Make                      = [String]     (Query-WMI  -Computer $Computer -WMIQuery "Select Manufacturer from Win32_ComputerSystem"              -DomainCredentials $DomainCredentials).Manufacturer
            Model                     = [String]     (Query-WMI  -Computer $Computer -WMIQuery "Select Model from Win32_ComputerSystem"                     -DomainCredentials $DomainCredentials).Model
            CPUSpeed                  = [String[]]   ((Query-WMI -Computer $Computer -WMIQuery "Select MaxClockSpeed from Win32_Processor"                  -DomainCredentials $DomainCredentials).MaxClockSpeed)[0]
            CPUName                   = [String[]]   ((Query-WMI -Computer $Computer -WMIQuery "Select Name from Win32_Processor"                           -DomainCredentials $DomainCredentials).Name)[0]
            NumberOfLogicalProcessors = [String]     (Query-WMI  -Computer $Computer -WMIQuery "Select NumberOfLogicalProcessors from Win32_ComputerSystem" -DomainCredentials $DomainCredentials).NumberOfLogicalProcessors
        }
        $NetworkDetails      = Get-NICDetails  -Computer $Computer -DomainCredentials $DomainCredentials
        $DiskDetails         = Get-DiskDetails -Computer $Computer -DomainCredentials $DomainCredentials

        Write-Host "Complete" -ForegroundColor Green -NoNewline

        Try {
            Export-Excel -BasicDetails $BasicDetails -NetworkDetails $NetworkDetails -DiskDetails $DiskDetails -Computer $Computer
            Write-Host "Complete" -ForegroundColor Green
        }
        Catch { Write-Host " - Failed" -ForegroundColor Red }
    }
    Else { Write-Host "Unable to Ping $Server" -ForegroundColor Red }
    $ComputerObjectsCounter ++
}