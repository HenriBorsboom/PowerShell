Param (
    [Parameter (Mandatory=$False)]
    [ValidateSet ("Domain2", "Domain1", "Both")]
    [String[]] $Domain, `
    [Parameter (Mandatory=$False)]
    [String] $Target)
Function Query-WMI {
    Param (
        [Parameter(Mandatory=$true, Position=1)]
        [String] $Server, `
        [Parameter(Mandatory=$true, Position=2)]
        [String] $WMIQuery, `
        [Parameter(Mandatory=$false, Position=3)]
        [Switch] $Domain1, `
        [Parameter(Mandatory=$false, Position=4)]
        [PSCredential] $Creds)

    Try { 
        If ($Server -eq $env:COMPUTERNAME) {
            Switch ($Domain1) {
                $true  {$WMIResults = Get-WmiObject -Query $WMIQuery -Credential $Creds}
                $false {$WMIResults = Get-WmiObject -Query $WMIQuery}
            }
        }
        Else {
            Switch ($Domain1) {
                $true {$Server = (Resolve-DnsName -Name $Server).IPAddress; $WMIResults = Get-WmiObject -Query $WMIQuery -ComputerName $Server -Credential $Creds}
                $false {$WMIResults = Get-WmiObject -Query $WMIQuery -ComputerName $Server}
            }
        }
        Return $WMIResults
    }
    Catch { Return $false }
}
Function Get-NICDetails {
    Param (
        [Parameter(Mandatory=$true, Position=1)]
        [String] $Server, `
        [Parameter(Mandatory=$false, Position=2)]
        [Switch] $Domain1, `
        [Parameter(Mandatory=$false, Position=3)]
        [PSCredential] $Creds)
    $NICDetails = @()
    Switch ($Domain1) {
        $true  {$ConnectedNICs = Query-WMI -Server $Server -WMIQuery "Select NetConnectionID,MACAddress,InterfaceIndex from Win32_NetworkAdapter Where NetConnectionStatus = ""2""" -Domain1 -Credential $Creds}
        $false {$ConnectedNICs = Query-WMI -Server $Server -WMIQuery "Select NetConnectionID,MACAddress,InterfaceIndex from Win32_NetworkAdapter Where NetConnectionStatus = ""2"""}
    }
    
    ForEach ($NIC in $ConnectedNICs) {
        $InterfaceIndex = $NIC.InterfaceIndex
        Switch ($Domain1) {
            $true  {$IPDetails = Query-WMI -Server $Server -WMIQuery "Select IPAddress,IPSubnet,DefaultIPGateway,DNSServerSearchOrder from Win32_NetworkAdapterConfiguration Where InterfaceIndex = ""$InterfaceIndex""" -Domain1 -Credential $Creds}
            $false {$IPDetails = Query-WMI -Server $Server -WMIQuery "Select IPAddress,IPSubnet,DefaultIPGateway,DNSServerSearchOrder from Win32_NetworkAdapterConfiguration Where InterfaceIndex = ""$InterfaceIndex"""}
        }
        
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
        [String] $Server, `
        [Parameter(Mandatory=$false, Position=2)]
        [Switch] $Domain1, `
        [Parameter(Mandatory=$false, Position=3)]
        [PSCredential] $Creds)
        
    $DisksDetails = @()
    Switch ($Domain1) {
        $true  {$Disks = Query-WMI -Server $Server -WMIQuery "Select Caption,Size,VolumeName from Win32_LogicalDisk Where DriveType = 3" -Domain1 -Credential $Creds}
        $false {$Disks = Query-WMI -Server $Server -WMIQuery "Select Caption,Size,VolumeName from Win32_LogicalDisk Where DriveType = 3"}
    }
    

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
Function New-HTML {
    Param (
        [Parameter(Mandatory=$true, Position=1)]
        [Object] $BasicDetails, `
        [Parameter(Mandatory=$true, Position=1)]
        [Object] $NetworkDetails, `
        [Parameter(Mandatory=$true, Position=1)]
        [Object] $DiskDetails, `
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
                    <h1 align=""center"">Configuration Item: $Server</h1>"

        $HTMLBody = "<h2 align=""center"">Basic Details</h2>"
        $HTMLOutput = $HTMLHeader
        $HTMLOutput += $HTMLBody

        $HTMLOutput += $BasicDetails | ConvertTo-HTML -Fragment
    
        $HTMLOutput += "<h2 align=""center"">Network Details</h2>"
        $HTMLOutput += $NetworkDetails | ConvertTo-HTML -Fragment
    
        $HTMLOutput += "<h2 align=""center"">Disk Details</h2>"
        $HTMLOutput += $DiskDetails | ConvertTo-HTML -Fragment
    
    Switch ($Overwrite) {
        $true  { If ((Get-ChildItem $OutputFile) -eq $true) { Remove-Item $OutputFile -Force -ErrorAction SilentlyContinue } $HTMLOutput = $HTMLOutput | Out-File $OutputFile -Encoding ascii }
        $False { $HTMLOutput = $HTMLOutput | Out-File $OutputFile -Encoding ascii }
    }
    Switch ($Launch) {
        $true { Start-Process $OutputFile }
    }
}
Function Domain1Credentials {
    $SecPWD = ConvertTo-SecureString "YourPasswordHere" -AsPlainText -Force
    $Creds = New-Object PSCredential("DOMAIN1\username", $SecPWD)
    Return $Creds
}
Function Domain1ADComputers {
    Param (
        [Parameter(Mandatory=$true, Position=1)]
        [PSCredential] $Creds)
    $Domain1Computers = Get-ADComputer -Filter {Name -like "N*"} -Properties * -Credential $Creds -Server VMSERVER112
    $Domain1Computers = $Domain1Computers | Sort Name
    $Domain1Computers = $Domain1Computers
    Return $Domain1Computers
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

$Domain = "domain1"

#Begin {
    Clear-Host
    #region Start
    $HTMLOutput ="<html>                                                               
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
                <body>"
    $SingleFile = $HTMLOutput
    $AllCMDB = $HTMLOutput
    $AllCMDBOutputFile = Get-TimeStampOutputFile -TargetLocation "C:\Temp\CI\All Combined" -Extension ".htm"
    $ReferenceCI = "C:\Temp\CI\CI Template.xlsx"
    $ErrorActionPreference = "SilentlyContinue"
    #endregion
#}
#Process {
    Switch ($Domain) {
        "Domain2" {
            #region BCX Online
            $Servers = Get-ADComputer -Filter { ObjectClass -eq "computer" }
            $Servers = $Servers.Name
            $Servers = $Servers | Sort Name
            $ServerCounter = 1
            $ServerCount = $Servers.Count
            Write-Host "Total Servers: " -NoNewline
            Write-Host $ServerCount -ForegroundColor Yellow
            ForEach ($Server in $Servers) {
                Write-Host "$ServerCounter\$ServerCount" -NoNewline -ForegroundColor Cyan
                Write-Host " - Generating CI for - " -NoNewline
                Write-Host $Server -ForegroundColor Yellow -NoNewline
                Write-Host " - " -NoNewline
                $HTMLOutputFile = Get-TimeStampOutputFile -TargetLocation "C:\Temp\CI" -Extension ".html" -VariableName -Name $Server
                $ExcelOutputFile = Get-TimeStampOutputFile -TargetLocation "C:\Temp\CI" -Extension ".xlsx" -VariableName -Name $Server
                If (Test-Connection $Server -Count 1) {
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
                    #region Single HTML Output
                    $SingleFile += "<h1 align=""center"">Configuration Item: $Server</h1>"
                    $SingleFile += "<h2 align=""center"">Basic Details</h2>"
                    $SingleFile += $BasicDetails | ConvertTo-HTML -Fragment
    
                    $SingleFile += "<h2 align=""center"">Network Details</h2>"
                    $SingleFile += $NetworkDetails | ConvertTo-HTML -Fragment
    
                    $SingleFile += "<h2 align=""center"">Disk Details</h2>"
                    $SingleFile += $DiskDetails | ConvertTo-HTML -Fragment
                    #endregion
                    #region Global HTML Output
                    $AllCMDB += "<h1 align=""center"">Configuration Item: $Server</h1>"
                    $AllCMDB += "<h2 align=""center"">Basic Details</h2>"
                    $AllCMDB += $BasicDetails | ConvertTo-HTML -Fragment
    
                    $AllCMDB += "<h2 align=""center"">Network Details</h2>"
                    $AllCMDB += $NetworkDetails | ConvertTo-HTML -Fragment
    
                    $AllCMDB += "<h2 align=""center"">Disk Details</h2>"
                    $AllCMDB += $DiskDetails | ConvertTo-HTML -Fragment
                    #endregion    
                    $SingleFile = $SingleFile | Out-File $HTMLOutputFile -Encoding ascii 
                    Write-Host "Complete" -ForegroundColor Green -NoNewline

                    #region Excel
                    Write-Color -Text " - Exporting to - ", $ExcelOutputFile, " - " -Color White, Yellow, White
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
                    $ActiveWorksheet.Cells.Item(142,3)  = (Get-Cluster (Get-VM $Server).VMHost.Name).Name # Virtual Cluster
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
        
                    $ActiveWorkbook.SaveAs($ExcelOutputFile)
                    $ExcelObject.Quit()
                    #Invoke-Expression $OutputFile
                    #endregion
                    Write-Host "Complete" -ForegroundColor Green
                }
                Else { Write-Host "Cannot Ping" -ForegroundColor Red }
                $ServerCounter ++
            }
            #endregion
        }
        "Domain1" {
            #region BCX Cloud
            $Domain1Credentials = New-Object PSCredential("DOMAIN1\username",(ConvertTo-SecureString "YourPasswordHere" -AsPlainText -Force))
            #$Servers = Invoke-Command -ComputerName VMSERVER112 -Credential $Domain1Credentials -ScriptBlock { Get-ADComputer -Filter { ObjectClass -eq "computer" } | Select Name }
            #$Servers = $Servers.Name
            #$Servers = $Servers | Sort Name
            $Servers = @("NRAPCDBS111")
            $ServerCounter = 1
            $ServerCount = $Servers.Count
            Write-Host "Total Servers: " -NoNewline
            Write-Host $ServerCount -ForegroundColor Yellow
            ForEach ($Server in $Servers) {
                Write-Host "$ServerCounter\$ServerCount" -NoNewline -ForegroundColor Cyan
                Write-Host " - Generating CI for - " -NoNewline
                Write-Host $Server -ForegroundColor Yellow -NoNewline
                Write-Host " - " -NoNewline
                $HTMLOutputFile = Get-TimeStampOutputFile -TargetLocation "C:\Temp\CI" -Extension ".html" -VariableName -Name $Server
                $ExcelOutputFile = Get-TimeStampOutputFile -TargetLocation "C:\Temp\CI" -Extension ".xlsx" -VariableName -Name $Server
                If (Test-Connection $Server -Count 1) {
                    $SerialNumber = (Query-WMI -Server $Server -WMIQuery "Select SerialNumber from Win32_BIOS" -Domain1 -Creds $Domain1Credentials).SerialNumber
                    $TotalPhysicalMemory = [Math]::Round((Query-WMI -Server $Server -WMIQuery "Select TotalPhysicalMemory from Win32_ComputerSystem" -Domain1 -Creds $Domain1Credentials).TotalPhysicalMemory/1024/1024/1024)
                    $OSVersion = (Query-WMI -Server $Server -WMIQuery "Select Caption from Win32_OperatingSystem" -Domain1 -Creds $Domain1Credentials).Caption
                    $OSServicePack = (Query-WMI -Server $Server -WMIQuery "Select ServicePackMajorVersion from Win32_OperatingSystem" -Domain1 -Creds $Domain1Credentials).ServicePackMajorVersion
                    $Make = (Query-WMI -Server $Server -WMIQuery "Select Manufacturer from Win32_ComputerSystem" -Domain1 -Creds $Domain1Credentials).Manufacturer
                    $Model = (Query-WMI -Server $Server -WMIQuery "Select Model from Win32_ComputerSystem" -Domain1 -Creds $Domain1Credentials).Model
                    [String[]] $CPUSpeed = (Query-WMI -Server $Server -WMIQuery "Select MaxClockSpeed from Win32_Processor" -Domain1 -Creds $Domain1Credentials).MaxClockSpeed
                    [String[]] $CPUName = (Query-WMI -Server $Server -WMIQuery "Select Name from Win32_Processor" -Domain1 -Creds $Domain1Credentials).Name
                    $NumberOfLogicalProcessors = (Query-WMI -Server $Server -WMIQuery "Select NumberOfLogicalProcessors from Win32_ComputerSystem" -Domain1 -Creds $Domain1Credentials).NumberOfLogicalProcessors
                    $SystemRole = $Server.Description
                    $ServerDomain = (Query-WMI -Server $Server -WMIQuery "Select Domain from Win32_ComputerSystem" -Domain1 -Creds $Domain1Credentials).Domain
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
                    $NetworkDetails = Get-NICDetails -Server $Server -Domain1 -Creds $Domain1Credentials
                    $DiskDetails = Get-DiskDetails -Server $Server  -Domain1 -Creds $Domain1Credentials
                    #region Single HTML Output
                    $SingleFile += "<h1 align=""center"">Configuration Item: $Server</h1>"
                    $SingleFile += "<h2 align=""center"">Basic Details</h2>"
                    $SingleFile += $BasicDetails | ConvertTo-HTML -Fragment
    
                    $SingleFile += "<h2 align=""center"">Network Details</h2>"
                    $SingleFile += $NetworkDetails | ConvertTo-HTML -Fragment
    
                    $SingleFile += "<h2 align=""center"">Disk Details</h2>"
                    $SingleFile += $DiskDetails | ConvertTo-HTML -Fragment
                    #endregion
                    #region Global HTML Output
                    $AllCMDB += "<h1 align=""center"">Configuration Item: $Server</h1>"
                    $AllCMDB += "<h2 align=""center"">Basic Details</h2>"
                    $AllCMDB += $BasicDetails | ConvertTo-HTML -Fragment
    
                    $AllCMDB += "<h2 align=""center"">Network Details</h2>"
                    $AllCMDB += $NetworkDetails | ConvertTo-HTML -Fragment
    
                    $AllCMDB += "<h2 align=""center"">Disk Details</h2>"
                    $AllCMDB += $DiskDetails | ConvertTo-HTML -Fragment
                    #endregion    
                    $SingleFile = $SingleFile | Out-File $HTMLOutputFile -Encoding ascii 
                    Write-Host "Complete" -ForegroundColor Green -NoNewline

                    #region Excel
                    Write-Color -Text " - Exporting to - ", $ExcelOutputFile, " - " -Color White, Yellow, White
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
                    $ActiveWorksheet.Cells.Item(142,3)  = (Get-Cluster (Get-VM $Server).VMHost.Name).Name # Virtual Cluster
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
        
                    $ActiveWorkbook.SaveAs($ExcelOutputFile)
                    $ExcelObject.Quit()
                    #Invoke-Expression $OutputFile
                    #endregion
                    Write-Host "Complete" -ForegroundColor Green
                }
                Else { Write-Host "Cannot Ping" -ForegroundColor Red }
                $ServerCounter ++
            }
            #endregion
        }
        "Both" {
            #region BCX Online
            $Servers = Get-ADComputer -Filter { ObjectClass -eq "computer" }
            $Servers = $Servers.Name
            $Servers = $Servers | Sort Name
            $ServerCounter = 1
            $ServerCount = $Servers.Count
            Write-Host "Total Servers: " -NoNewline
            Write-Host $ServerCount -ForegroundColor Yellow
            ForEach ($Server in $Servers) {
                Write-Host "$ServerCounter\$ServerCount" -NoNewline -ForegroundColor Cyan
                Write-Host " - Generating CI for - " -NoNewline
                Write-Host $Server -ForegroundColor Yellow -NoNewline
                Write-Host " - " -NoNewline
                $HTMLOutputFile = Get-TimeStampOutputFile -TargetLocation "C:\Temp\CI" -Extension ".html" -VariableName -Name $Server
                $ExcelOutputFile = Get-TimeStampOutputFile -TargetLocation "C:\Temp\CI" -Extension ".xlsx" -VariableName -Name $Server
                If (Test-Connection $Server -Count 1) {
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
                    #region Single HTML Output
                    $SingleFile += "<h1 align=""center"">Configuration Item: $Server</h1>"
                    $SingleFile += "<h2 align=""center"">Basic Details</h2>"
                    $SingleFile += $BasicDetails | ConvertTo-HTML -Fragment
    
                    $SingleFile += "<h2 align=""center"">Network Details</h2>"
                    $SingleFile += $NetworkDetails | ConvertTo-HTML -Fragment
    
                    $SingleFile += "<h2 align=""center"">Disk Details</h2>"
                    $SingleFile += $DiskDetails | ConvertTo-HTML -Fragment
                    #endregion
                    #region Global HTML Output
                    $AllCMDB += "<h1 align=""center"">Configuration Item: $Server</h1>"
                    $AllCMDB += "<h2 align=""center"">Basic Details</h2>"
                    $AllCMDB += $BasicDetails | ConvertTo-HTML -Fragment
    
                    $AllCMDB += "<h2 align=""center"">Network Details</h2>"
                    $AllCMDB += $NetworkDetails | ConvertTo-HTML -Fragment
    
                    $AllCMDB += "<h2 align=""center"">Disk Details</h2>"
                    $AllCMDB += $DiskDetails | ConvertTo-HTML -Fragment
                    #endregion    
                    $SingleFile = $SingleFile | Out-File $HTMLOutputFile -Encoding ascii 
                    Write-Host "Complete" -ForegroundColor Green -NoNewline

                    #region Excel
                    Write-Color -Text " - Exporting to - ", $ExcelOutputFile, " - " -Color White, Yellow, White
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
                    $ActiveWorksheet.Cells.Item(142,3)  = (Get-Cluster (Get-VM $Server).VMHost.Name).Name # Virtual Cluster
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
        
                    $ActiveWorkbook.SaveAs($ExcelOutputFile)
                    $ExcelObject.Quit()
                    #Invoke-Expression $OutputFile
                    #endregion
                    Write-Host "Complete" -ForegroundColor Green
                }
                Else { Write-Host "Cannot Ping" -ForegroundColor Red }
                $ServerCounter ++
            }
            #endregion
            #region BCX Cloud
            $Domain1Credentials = New-Object PSCredential("DOMAIN1\username",(ConvertTo-SecureString "YourPasswordHere" -AsPlainText -Force))
            $Servers = Invoke-Command -ComputerName VMSERVER112 -Credential $Domain1 -ScriptBlock { Get-ADComputer -Filter { ObjectClass -eq "computer" } | Select Name }
            $Servers = $Servers.Name
            $Servers = $Servers | Sort Name

            $ServerCounter = 1
            $ServerCount = $Servers.Count
            Write-Host "Total Servers: " -NoNewline
            Write-Host $ServerCount -ForegroundColor Yellow
            ForEach ($Server in $Servers) {
                Write-Host "$ServerCounter\$ServerCount" -NoNewline -ForegroundColor Cyan
                Write-Host " - Generating CI for - " -NoNewline
                Write-Host $Server -ForegroundColor Yellow -NoNewline
                Write-Host " - " -NoNewline
                $HTMLOutputFile = Get-TimeStampOutputFile -TargetLocation "C:\Temp\CI" -Extension ".html" -VariableName -Name $Server
                $ExcelOutputFile = Get-TimeStampOutputFile -TargetLocation "C:\Temp\CI" -Extension ".xlsx" -VariableName -Name $Server
                If (Test-Connection $Server -Count 1) {
                    $SerialNumber = (Query-WMI -Server $Server -WMIQuery "Select SerialNumber from Win32_BIOS" -Domain1 -Creds $Domain1Credentials).SerialNumber
                    $TotalPhysicalMemory = [Math]::Round((Query-WMI -Server $Server -WMIQuery "Select TotalPhysicalMemory from Win32_ComputerSystem" -Domain1 -Creds $Domain1Credentials).TotalPhysicalMemory/1024/1024/1024)
                    $OSVersion = (Query-WMI -Server $Server -WMIQuery "Select Caption from Win32_OperatingSystem" -Domain1 -Creds $Domain1Credentials).Caption
                    $OSServicePack = (Query-WMI -Server $Server -WMIQuery "Select ServicePackMajorVersion from Win32_OperatingSystem" -Domain1 -Creds $Domain1Credentials).ServicePackMajorVersion
                    $Make = (Query-WMI -Server $Server -WMIQuery "Select Manufacturer from Win32_ComputerSystem" -Domain1 -Creds $Domain1Credentials).Manufacturer
                    $Model = (Query-WMI -Server $Server -WMIQuery "Select Model from Win32_ComputerSystem" -Domain1 -Creds $Domain1Credentials).Model
                    [String[]] $CPUSpeed = (Query-WMI -Server $Server -WMIQuery "Select MaxClockSpeed from Win32_Processor" -Domain1 -Creds $Domain1Credentials).MaxClockSpeed
                    [String[]] $CPUName = (Query-WMI -Server $Server -WMIQuery "Select Name from Win32_Processor" -Domain1 -Creds $Domain1Credentials).Name
                    $NumberOfLogicalProcessors = (Query-WMI -Server $Server -WMIQuery "Select NumberOfLogicalProcessors from Win32_ComputerSystem" -Domain1 -Creds $Domain1Credentials).NumberOfLogicalProcessors
                    $SystemRole = $Server.Description
                    $ServerDomain = (Query-WMI -Server $Server -WMIQuery "Select Domain from Win32_ComputerSystem" -Domain1 -Creds $Domain1Credentials).Domain
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
                    $NetworkDetails = Get-NICDetails -Server $Server -Domain1 -Creds $Domain1Credentials
                    $DiskDetails = Get-DiskDetails -Server $Server  -Domain1 -Creds $Domain1Credentials
                    #region Single HTML Output
                    $SingleFile += "<h1 align=""center"">Configuration Item: $Server</h1>"
                    $SingleFile += "<h2 align=""center"">Basic Details</h2>"
                    $SingleFile += $BasicDetails | ConvertTo-HTML -Fragment
    
                    $SingleFile += "<h2 align=""center"">Network Details</h2>"
                    $SingleFile += $NetworkDetails | ConvertTo-HTML -Fragment
    
                    $SingleFile += "<h2 align=""center"">Disk Details</h2>"
                    $SingleFile += $DiskDetails | ConvertTo-HTML -Fragment
                    #endregion
                    #region Global HTML Output
                    $AllCMDB += "<h1 align=""center"">Configuration Item: $Server</h1>"
                    $AllCMDB += "<h2 align=""center"">Basic Details</h2>"
                    $AllCMDB += $BasicDetails | ConvertTo-HTML -Fragment
    
                    $AllCMDB += "<h2 align=""center"">Network Details</h2>"
                    $AllCMDB += $NetworkDetails | ConvertTo-HTML -Fragment
    
                    $AllCMDB += "<h2 align=""center"">Disk Details</h2>"
                    $AllCMDB += $DiskDetails | ConvertTo-HTML -Fragment
                    #endregion    
                    $SingleFile = $SingleFile | Out-File $HTMLOutputFile -Encoding ascii 
                    Write-Host "Complete" -ForegroundColor Green -NoNewline

                    #region Excel
                    Write-Color -Text " - Exporting to - ", $ExcelOutputFile, " - " -Color White, Yellow, White
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
                    $ActiveWorksheet.Cells.Item(142,3)  = (Get-Cluster (Get-VM $Server).VMHost.Name).Name # Virtual Cluster
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
        
                    $ActiveWorkbook.SaveAs($ExcelOutputFile)
                    $ExcelObject.Quit()
                    #Invoke-Expression $OutputFile
                    #endregion
                    Write-Host "Complete" -ForegroundColor Green
                }
                Else { Write-Host "Cannot Ping" -ForegroundColor Red }
                $ServerCounter ++
            }
            #endregion
        }
        Else {
            $Servers = @($Target)
            $ServerCounter = 1
            $ServerCount = $Servers.Count
            Write-Host "Total Servers: " -NoNewline
            Write-Host $ServerCount -ForegroundColor Yellow
            ForEach ($Server in $Servers) {
                Write-Host "$ServerCounter\$ServerCount" -NoNewline -ForegroundColor Cyan
                Write-Host " - Generating CI for - " -NoNewline
                Write-Host $Server -ForegroundColor Yellow -NoNewline
                Write-Host " - " -NoNewline
                $HTMLOutputFile = Get-TimeStampOutputFile -TargetLocation "C:\Temp\CI" -Extension ".html" -VariableName -Name $Server
                $ExcelOutputFile = Get-TimeStampOutputFile -TargetLocation "C:\Temp\CI" -Extension ".xlsx" -VariableName -Name $Server
                If (Test-Connection $Server -Count 1) {
                    $SerialNumber = (Query-WMI -Server $Server -WMIQuery "Select SerialNumber from Win32_BIOS" -Domain1 -Creds $Domain1Credentials).SerialNumber
                    $TotalPhysicalMemory = [Math]::Round((Query-WMI -Server $Server -WMIQuery "Select TotalPhysicalMemory from Win32_ComputerSystem" -Domain1 -Creds $Domain1Credentials).TotalPhysicalMemory/1024/1024/1024)
                    $OSVersion = (Query-WMI -Server $Server -WMIQuery "Select Caption from Win32_OperatingSystem" -Domain1 -Creds $Domain1Credentials).Caption
                    $OSServicePack = (Query-WMI -Server $Server -WMIQuery "Select ServicePackMajorVersion from Win32_OperatingSystem" -Domain1 -Creds $Domain1Credentials).ServicePackMajorVersion
                    $Make = (Query-WMI -Server $Server -WMIQuery "Select Manufacturer from Win32_ComputerSystem" -Domain1 -Creds $Domain1Credentials).Manufacturer
                    $Model = (Query-WMI -Server $Server -WMIQuery "Select Model from Win32_ComputerSystem" -Domain1 -Creds $Domain1Credentials).Model
                    [String[]] $CPUSpeed = (Query-WMI -Server $Server -WMIQuery "Select MaxClockSpeed from Win32_Processor" -Domain1 -Creds $Domain1Credentials).MaxClockSpeed
                    [String[]] $CPUName = (Query-WMI -Server $Server -WMIQuery "Select Name from Win32_Processor" -Domain1 -Creds $Domain1Credentials).Name
                    $NumberOfLogicalProcessors = (Query-WMI -Server $Server -WMIQuery "Select NumberOfLogicalProcessors from Win32_ComputerSystem" -Domain1 -Creds $Domain1Credentials).NumberOfLogicalProcessors
                    $SystemRole = $Server.Description
                    $ServerDomain = (Query-WMI -Server $Server -WMIQuery "Select Domain from Win32_ComputerSystem" -Domain1 -Creds $Domain1Credentials).Domain
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
                    $NetworkDetails = Get-NICDetails -Server $Server -Domain1 -Creds $Domain1Credentials
                    $DiskDetails = Get-DiskDetails -Server $Server  -Domain1 -Creds $Domain1Credentials
                    #region Single HTML Output
                    $SingleFile += "<h1 align=""center"">Configuration Item: $Server</h1>"
                    $SingleFile += "<h2 align=""center"">Basic Details</h2>"
                    $SingleFile += $BasicDetails | ConvertTo-HTML -Fragment
    
                    $SingleFile += "<h2 align=""center"">Network Details</h2>"
                    $SingleFile += $NetworkDetails | ConvertTo-HTML -Fragment
    
                    $SingleFile += "<h2 align=""center"">Disk Details</h2>"
                    $SingleFile += $DiskDetails | ConvertTo-HTML -Fragment
                    #endregion
                    #region Global HTML Output
                    $AllCMDB += "<h1 align=""center"">Configuration Item: $Server</h1>"
                    $AllCMDB += "<h2 align=""center"">Basic Details</h2>"
                    $AllCMDB += $BasicDetails | ConvertTo-HTML -Fragment
    
                    $AllCMDB += "<h2 align=""center"">Network Details</h2>"
                    $AllCMDB += $NetworkDetails | ConvertTo-HTML -Fragment
    
                    $AllCMDB += "<h2 align=""center"">Disk Details</h2>"
                    $AllCMDB += $DiskDetails | ConvertTo-HTML -Fragment
                    #endregion    
                    $SingleFile = $SingleFile | Out-File $HTMLOutputFile -Encoding ascii 
                    Write-Host "Complete" -ForegroundColor Green -NoNewline

                    #region Excel
                    Write-Color -Text " - Exporting to - ", $ExcelOutputFile, " - " -Color White, Yellow, White
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
                    $ActiveWorksheet.Cells.Item(142,3)  = (Get-Cluster (Get-VM $Server).VMHost.Name).Name # Virtual Cluster
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
        
                    $ActiveWorkbook.SaveAs($ExcelOutputFile)
                    $ExcelObject.Quit()
                    #Invoke-Expression $OutputFile
                    #endregion
                    Write-Host "Complete" -ForegroundColor Green
                }
                Else { Write-Host "Cannot Ping" -ForegroundColor Red }
                $ServerCounter ++
            }
        }
    }
#}

#End {
    $AllCMDB = $AllCMDB | Out-File $AllCMDBOutputFile -Encoding ascii  
#}