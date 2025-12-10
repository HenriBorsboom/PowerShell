Function Query-WMI {
    Param (
        [Parameter(Mandatory=$true, Position=1)]
        [String] $Server, `
        [Parameter(Mandatory=$true, Position=2)]
        [String] $WMIQuery)

    Try { 
        If ($Server -eq $env:COMPUTERNAME) {
            $WMIResults = Get-WmiObject -Query $WMIQuery
        }
        Else {
            $WMIResults = Get-WmiObject -Query $WMIQuery -ComputerName $Server
        }
        Return $WMIResults
    }
    Catch { Return $false }
}
Function Get-NICDetails {
    Param (
        [Parameter(Mandatory=$true, Position=1)]
        [String] $Server)
    $NICDetails = @()
    $ConnectedNICs = Query-WMI -Server $Server -WMIQuery "Select NetConnectionID,MACAddress,InterfaceIndex from Win32_NetworkAdapter Where NetConnectionStatus = ""2"""
    ForEach ($NIC in $ConnectedNICs) {
        $InterfaceIndex = $NIC.InterfaceIndex
        $IPDetails = Query-WMI -Server $Server -WMIQuery "Select IPAddress,IPSubnet,DefaultIPGateway,DNSServerSearchOrder from Win32_NetworkAdapterConfiguration Where InterfaceIndex = ""$InterfaceIndex"""
	    For ($Index = 0; $Index -lt $IPDetails.IPAddress.Count; $Index ++) {
            If ([IPAddress]::TryParse([IPAddress] $IPDetails.IPAddress[$Index], [Ref] "0.0.0.0") -and (([IPAddress] $IPDetails.IPAddress[$Index]).IsIPv6LinkLocal) -eq $false) {
                #region Set Results to Variables
                Try { $AdapterName          = $NIC.NetConnectionID }                      Catch { $AdapterName = "" }
                Try { $MACAddress           = $NIC.MACAddress }                           Catch { $MACAddress = "" }
                Try { $InterfaceIndex       = $NIC.InterfaceIndex }                       Catch { $InterfaceIndex = "" }
                Try { $IPAddress            = $IPDetails.IPAddress[$Index] }              Catch { $IPAddress = "" }
                Try { $IPSubnet             = $IPDetails.IPSubnet[$Index] }               Catch { $IPSubnet = "" }
                Try { $DefaultIPGateway     = $IPDetails.DefaultIPGateway[$Index] }       Catch { $DefaultIPGateway = "" }
                Try { $DNSServerSearchOrder = $IPDetails.DNSServerSearchOrder -join ";" } Catch { $DNSServerSearchOrder = "" }
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
                #$NICDetail
            }
        }
    }
    Return $NICDetails
}
Function Get-DiskDetails {
    Param (
        [Parameter(Mandatory=$true, Position=1)]
        [String] $Server)
        
    $DisksDetails = @()
    $Disks = Query-WMI -Server $Server -WMIQuery "Select Caption,Size,VolumeName from Win32_LogicalDisk Where DriveType = 3"

    ForEach ($Disk in $Disks) {
        $DiskDetails = New-Object PSObject -Property @{
            DriveLetter = $Disk.Caption
            Size        = [Math]::Round($Disk.Size/1024/1024/1024)
            VolumeName  = $Disk.VolumeName
        }
        $DisksDetails += $DiskDetails
    }
    Return $DisksDetails
}
Function Get-TimeStampOutputFile {
    Param (
        [Parameter(Mandatory=$true, Position=1)]
        [String] $TargetLocation, `
        [Parameter(Mandatory=$true, Position=2)]
        [String] $Extension, `
        [Parameter(Mandatory=$false, Position=3)]
        [Switch] $VariableName, `
        [Parameter(Mandatory=$false, Position=4)]
        [String] $Name)

    Switch ($VariableName) {
        $True  { $OutputFile = $TargetLocation + "\" + $Name + " - " + $([DateTime]::Now.ToString('HH.mm.ss - dd-MM-yyyy')) + $Extension }
        $False { $OutputFile = $TargetLocation + " - " + $([DateTime]::Now.ToString('yyyyMMdd')) + $Extension }
    }
    Return $OutputFile
}
Function Write-Color {
    Param(
        [Parameter(Mandatory=$true, Position=1)]
        [String[]] $Text, `
        [Parameter(Mandatory=$true, Position=2)]
        [ConsoleColor[]] $Color, `
        [Parameter(Mandatory=$false, Position=3)]
        [switch] $EndLine)
    
    If ($Text.Count -ne $Color.Length) {
        Write-Host "The amount of Text variables and the amount of color variables does not match" -ForegroundColor Red
        Write-Host "Text Variables:  " -NoNewline
        Write-Host $Text.Count -ForegroundColor Yellow -NoNewline
        Write-Host " - Color Variables: " -NoNewline
        Write-Host $Color.Length -ForegroundColor Yellow
        Break
    }
    Else {
        For ($TextArrayIndex = 0; $TextArrayIndex -lt $Text.Length; $TextArrayIndex ++) {
            Write-Host $Text[$TextArrayIndex] -Foreground $Color[$TextArrayIndex] -NoNewLine
        }
        Switch ($EndLine) {
            $true  { Write-Host }
            $false { Write-Host -NoNewline}
        }
    }
}

Clear-Host
Import-Module VirtualMachineManager
Import-Module ActiveDirectory
$ReferenceCI = "C:\Temp\CI\CI Template.xlsx"

#$Servers = @($env:COMPUTERNAME)
$Servers = (Get-ADComputer -Filter {ObjectClass -eq "computer"}) | Sort Name

$ServerCounter = 1
$ServerCount = $Servers.Count
Write-Color -Text "Total Servers: ", $ServerCount -Color White, Yellow -EndLine

ForEach ($Server in $Servers.Name) {
    Write-Color -Text "$ServerCounter\$ServerCount", " - Gathering CI Info - ", $Server, " - " -Color Cyan, White, Yellow, White
    
    If (Test-Connection $Server -Count 1) {
        $OutputFile = Get-TimeStampOutputFile -TargetLocation "C:\Temp\CI\Excel" -Extension ".xlsx" -VariableName -Name $Server
        $SerialNumber = (Query-WMI -Server $Server -WMIQuery "Select SerialNumber from Win32_BIOS").SerialNumber
        $TotalPhysicalMemory = [Math]::Round((Query-WMI -Server $Server -WMIQuery "Select TotalPhysicalMemory from Win32_ComputerSystem").TotalPhysicalMemory/1024/1024/1024)
        $OSVersion = (Query-WMI -Server $Server -WMIQuery "Select Caption from Win32_OperatingSystem").Caption
        $OSServicePack = (Query-WMI -Server $Server -WMIQuery "Select ServicePackMajorVersion from Win32_OperatingSystem").ServicePackMajorVersion
        $Make = (Query-WMI -Server $Server -WMIQuery "Select Manufacturer from Win32_ComputerSystem").Manufacturer
        $Model = (Query-WMI -Server $Server -WMIQuery "Select Model from Win32_ComputerSystem").Model
        [String[]] $CPUSpeed = (Query-WMI -Server $Server -WMIQuery "Select MaxClockSpeed from Win32_Processor").MaxClockSpeed
        [String[]] $CPUName = (Query-WMI -Server $Server -WMIQuery "Select Name from Win32_Processor").Name
        $NumberOfLogicalProcessors = (Query-WMI -Server $Server -WMIQuery "Select NumberOfLogicalProcessors from Win32_ComputerSystem").NumberOfLogicalProcessors
        $SystemRole = (Get-AdComputer $Server -Properties *).Description
        $ServerDomain = (Query-WMI -Server $Server -WMIQuery "Select Domain from Win32_ComputerSystem").Domain
        $BasicDetails = New-Object PSObject -Property @{
                        SystemRole                = $SystemRole
                        Domain                    = $ServerDomain
                        SerialNumber              = $SerialNumber
                        TotalPhysicalMemory       = $TotalPhysicalMemory
                        OSVersion                 = $OSVersion
                        OSServicePack             = $OSServicePack
                        Make                      = $Make
                        Model                     = $Model
                        CPUSpeed                  = $CPUSpeed[0]
                        CPUName                   = $CPUName[0]
                        NumberOfLogicalProcessors = $NumberOfLogicalProcessors
        }
        $NetworkDetails = Get-NICDetails -Server $Server
        $DiskDetails = Get-DiskDetails -Server $Server
        Write-Host "Complete" -ForegroundColor Green -NoNewline

        #region Excel
        Write-Color -Text " - Exporting to - ", $OutputFile, " - " -Color White, Yellow, White
        $ExcelObject = New-Object -ComObject Excel.Application  
        $ExcelObject.Visible = $false 
        $ExcelObject.DisplayAlerts =$false
        $Date= Get-Date -Format "dd-MM-yyyy"
        If (Test-Path $ReferenceCI) {  
            $ActiveWorkbook = $ExcelObject.WorkBooks.Open($ReferenceCI)  
            $ActiveWorksheet = $ActiveWorkbook.Worksheets.Item(1)  
        }
        If ($Model -like "*Virtual*") {
        $ActiveWorksheet.Cells.Item(8,3)    = "Virtual"                                       # Tier 1
        $ActiveWorksheet.Cells.Item(141,3)  = (Get-VM $Server).VMHost.Name                    # Physical Host
        Try {
            $ActiveWorksheet.Cells.Item(142,3)  = (Get-Cluster (Get-VM $Server).VMHost.Name).Name # Virtual Cluster
        }
        Catch {
            $ActiveWorksheet.Cells.Item(142,3)  = (Get-Cluster (Get-VM $Server).VMHost.Name[0]).Name # Virtual Cluster
        }
        }
        Else {
        $ActiveWorksheet.Cells.Item(8,3)    = "Hardware"                                      # Tier 1
        }
        $ActiveWorksheet.Cells.Item(9,3)    = "Processing Unit"                               # Tier 2
        $ActiveWorksheet.Cells.Item(10,3)   = "Server"                                        # Tier 3
        $ActiveWorksheet.Cells.Item(11,3)   = $Model                                          # Model
        $ActiveWorksheet.Cells.Item(12,3)   = $Server                                         # Server
        $ActiveWorksheet.Cells.Item(13,3)   = $Make                                           # Make
        $ActiveWorksheet.Cells.Item(15,3)   = $SerialNumber                                   # SerialNumber
        $ActiveWorksheet.Cells.Item(18,3)   = $SystemRole                                     # SystemRole
        $ActiveWorksheet.Cells.Item(19,5)   = $ServerDomain                                   # ServerDomain
        $ActiveWorksheet.Cells.Item(87,3)   = $TotalPhysicalMemory                            # TotalPhysicalMemory
        $ActiveWorksheet.Cells.Item(91,3)   = $OSVersion                                      # OSVersion
        $ActiveWorksheet.Cells.Item(92,3)   = $OSServicePack                                  # OSServicePack
        $ActiveWorksheet.Cells.Item(90,3)   = $CPUSpeed                                       # CPUSpeed
        $ActiveWorksheet.Cells.Item(88,3)   = $CPUName                                        # CPUName
        $ActiveWorksheet.Cells.Item(89,3)   = $NumberOfLogicalProcessors                      # NumberOfLogicalProcessors
        
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
        
        $ActiveWorkbook.SaveAs($OutputFile)
        $ExcelObject.Quit()
        #Invoke-Expression $OutputFile
        #endregion
        Write-Host "Complete" -ForegroundColor Green
    }
    Else { Write-Host "Cannot Ping" -ForegroundColor Red }
    $ServerCounter ++
}
