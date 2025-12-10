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
Clear-Host

$ReferenceCI = "C:\Users\username\Documents\BCX\Azure\CI\Test1.xlsx"
$Servers = @($env:COMPUTERNAME)

#$Servers = (Get-ADComputer -Filter {Name -like "NRA*"}) | Sort Name

$ServerCounter = 1
$ServerCount = $Servers.Count
Write-Host "Total Servers: " -NoNewline
Write-Host $ServerCount -ForegroundColor Yellow

ForEach ($Server in $Servers) {
    Write-Host "$ServerCounter\$ServerCount" -NoNewline -ForegroundColor Cyan
    Write-Host " - Generating CI for - " -NoNewline
    Write-Host $Server -ForegroundColor Yellow -NoNewline
    Write-Host " - " -NoNewline
    
    If (Test-Connection $Server -Count 1) {
        $OutputFile = "C:\Users\username\Documents\BCX\Azure\CI\" + $Server + ".xlsx"
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
        
        
        #region Excel
        $ExcelObject = New-Object -ComObject Excel.Application  
        $ExcelObject.Visible = $true 
        $ExcelObject.DisplayAlerts =$false
        $Date= Get-Date -Format "dd-MM-yyyy"
        If (Test-Path $ReferenceCI) {  
            #Open the document  
            $ActiveWorkbook = $ExcelObject.WorkBooks.Open($ReferenceCI)  
            $ActiveWorksheet = $ActiveWorkbook.Worksheets.Item(1)  
        }
        
        $ActiveWorksheet.Cells.Item(11,3) = $Model                     # Model
        $ActiveWorksheet.Cells.Item(12,3) = $Server                    # Server
        $ActiveWorksheet.Cells.Item(13,3) = $Make                      # Make
        $ActiveWorksheet.Cells.Item(15,3) = $SerialNumber              # SerialNumber
        $ActiveWorksheet.Cells.Item(18,3) = $SystemRole                # SystemRole
        $ActiveWorksheet.Cells.Item(19,5) = $ServerDomain              # ServerDomain
        $ActiveWorksheet.Cells.Item(87,3) = $TotalPhysicalMemory       # TotalPhysicalMemory
        $ActiveWorksheet.Cells.Item(91,3) = $OSVersion                 # OSVersion
        $ActiveWorksheet.Cells.Item(92,3) = $OSServicePack             # OSServicePack
        $ActiveWorksheet.Cells.Item(90,3) = $CPUSpeed                  # CPUSpeed
        $ActiveWorksheet.Cells.Item(88,3) = $CPUName                   # CPUName
        $ActiveWorksheet.Cells.Item(89,3) = $NumberOfLogicalProcessors # NumberOfLogicalProcessors
        
        $introw = 98
        ForEach ($Line in $DiskDetails){
              $ActiveWorksheet.cells.item($introw, 2) = $Line.DriveLetter
              $ActiveWorksheet.cells.item($introw, 3) = $Line.Size
              $ActiveWorksheet.cells.item($introw, 4) = $Line.VolumeName
              $introw ++
        }
        
        $ActiveWorkbook.SaveAs($OutputFile)
        $ExcelObject.Quit()
        Invoke-Expression $OutputFile
        
        
        
        #endregion
        Write-Host "Complete" -ForegroundColor Green
    }
    Else { Write-Host "Cannot Ping" -ForegroundColor Red }
    $ServerCounter ++
}
#$AllCMDB = $AllCMDB | Out-File $AllCMDBOutputFile -Encoding ascii  