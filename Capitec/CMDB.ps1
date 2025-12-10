Param (
    [Parameter (Mandatory=$False)]
    [ValidateSet ("SNDDomain", "MBLCard")]
    [String[]] $Domain = "SNDDOMAIN")

Function Get-NICDetails {
    Param (
        [Parameter(Mandatory=$true, Position=1)]
        [String] $Server, `
        [Parameter(Mandatory=$false, Position=2)]
        [PSCredential] $Creds)

    $NICDetails = @()

    If ($Creds -ne $null) {
        $ConnectedNICs = Get-WMIObject -Query "Select NetConnectionID,MACAddress,InterfaceIndex from Win32_NetworkAdapter Where NetConnectionStatus = ""2""" -ComputerName $Server -Credential $Creds
    }
    Else {
        $ConnectedNICs = Get-WMIObject -Query "Select NetConnectionID,MACAddress,InterfaceIndex from Win32_NetworkAdapter Where NetConnectionStatus = ""2""" -ComputerName $Server
    }
    
    ForEach ($NIC in $ConnectedNICs) {
        $InterfaceIndex = $NIC.InterfaceIndex
        If ($Creds -ne $null) {
            $IPDetails = Get-WMIObject -Computername $Server -Query "Select IPAddress,IPSubnet,DefaultIPGateway,DNSServerSearchOrder from Win32_NetworkAdapterConfiguration Where InterfaceIndex = ""$InterfaceIndex""" -Credential $Creds
        }
        Else {
            $IPDetails = Get-WMIObject -Computername $Server -Query "Select IPAddress,IPSubnet,DefaultIPGateway,DNSServerSearchOrder from Win32_NetworkAdapterConfiguration Where InterfaceIndex = ""$InterfaceIndex"""
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
        [PSCredential] $Creds)
        
    $DisksDetails = @()
    If ($Creds -ne $null) {
        $Disks = Get-WMIObject -Computername $Server -Query "Select Caption, Size, FreeSpace, VolumeName from Win32_LogicalDisk Where DriveType = 3" -Credential $Creds
    }
    Else {
        $Disks = Get-WmiObject -Computername $Server -Query "Select Caption, Size, FreeSpace, VolumeName from Win32_LogicalDisk Where DriveType = 3"
    }
    
    ForEach ($Disk in $Disks) {
        $DiskDetails = New-Object PSObject -Property @{
            DriveLetter = $Disk.Caption
            Size        = [Math]::Round($Disk.Size/1024/1024/1024)
            FreeSpace   = [Math]::Round($Disk.FreeSpace/1024/1024/1024)
            FreePerc    = [Math]::Round($Disk.FreeSpace/$Disk.Size*100)
            VolumeName  = $Disk.VolumeName
        }
        $DisksDetails += $DiskDetails
    }
    Return $DisksDetails
}
Function Write-Color {
    <#
    .SYNOPSIS
	    Write Host with Simpler Color Management
    .DESCRIPTION
	    Write-Color gives you the same functionality as Write-Host but with simpler and quicker color management
    .EXAMPLE
	    Write-Color -Text 'Test 1 '
    .EXAMPLE
	    Write-Color -Text 'Test 1 ' -ForegroundColor Black
    .EXAMPLE
	    Write-Color -Text 'Test 1 ' -BackgroundColor Yellow
    .EXAMPLE
	    Write-Color -Text 'Test 1 ' -ForegroundColor Black -BackgroundColor Yellow
    .EXAMPLE
	    Write-Color -Text 'Test 1 ', 'Test 2 ' -ForegroundColor Yellow -BackgroundColor Black
    .EXAMPLE
	    Write-Color -Text 'Test 1 ', 'Test 2 ' -ForegroundColor Yellow, Green -BackgroundColor Black, Yellow
    .EXAMPLE
	    Write-Color -Complete
    .EXAMPLE
	    Write-Color -Text 'Test 1 ', 'Test 2 ' -ForegroundColor Yellow, Green -BackgroundColor Black, Yellow -NoNewline
    .EXAMPLE
	    Write-Color -Complete -NoNewline
    .INPUTS
	    [String[]]
    .PARAMETER Text
	    This is the collection of text that needs to be written to the host
    .INPUTS
	    [ConsoleColor[]]
    .PARAMETER ForegroundColor
	    This is the collection of Foreground colors that needs to be applied to the text
	    If there is more text in the collection and only 1 Foreground color is specified
	    then the first foreground color will be applied to all text
    .INPUTS
	    [ConsoleColor[]]
    .PARAMETER BackgroundColor
	    This is the collection of Background colors that needs to be applied to the text
	    If there is more text in the collection and only 1 Background color is specified
	    then the first Background color will be applied to all text
    .INPUTS
	    [Switch]
    .PARAMETER NoNewLine
	    This is to specify if you want to terminate the line or not
    .INPUTS
	    [Switch]
    .PARAMETER Complete
	    This is will write to the host "Complete" with the Foreground color set to Green
    .INPUTS
	    [Int64]
    .PARAMETER IndexCounter
	    This is the counter for the current item
    .INPUTS
	    [Int64]
    .PARAMETER TotalCounter
	    This is the total number of items that needs to be processed. This is needed
        to format the counter properly
    .Notes
        NAME:  Write-Color
        AUTHOR: Henri Borsboom
        LASTEDIT: 30/08/2017
        KEYWORDS: Write-Host, Console Output, Color
    .Link
        https://www.linkedin.com/pulse/powershell-<>-henri-borsboom
        #Requires -Version 2.0
    #>
    [CmdletBinding(DefaultParameterSetName='Normal')]
    Param(
        [Parameter(Mandatory=$True, Position=1,ParameterSetName='Normal')]
	    [Parameter(Mandatory=$True, Position=1,ParameterSetName='Tab')]
        [String[]] $Text, `
        [Parameter(Mandatory=$False, Position=2,ParameterSetName='Normal')]
	    [Parameter(Mandatory=$False, Position=2,ParameterSetName='Tab')]
        [ConsoleColor[]] $ForegroundColor, `
        [Parameter(Mandatory=$False, Position=3,ParameterSetName='Normal')]
	    [Parameter(Mandatory=$False, Position=3,ParameterSetName='Tab')]
        [ConsoleColor[]] $BackgroundColor, `
        [Parameter(Mandatory=$False, Position=1,ParameterSetName='Complete')]
        [Switch] $Complete, `
	    [Parameter(Mandatory=$False, Position=4,ParameterSetName='Normal')]
	    [Parameter(Mandatory=$False, Position=4,ParameterSetName='Tab')]
	    [Parameter(Mandatory=$False, Position=2,ParameterSetName='Complete')]
        [Switch] $NoNewLine, `
        [Parameter(Mandatory=$False, Position=5,ParameterSetName='Normal')]
	    [Parameter(Mandatory=$False, Position=8,ParameterSetName='Tab')]
	    [Parameter(Mandatory=$False, Position=3,ParameterSetName='Complete')]
        [String] $LogFile = "", `
	    [Parameter(Mandatory=$False, Position=5,ParameterSetName='Tab')]
        [Parameter(Mandatory=$False, Position=4,ParameterSetName='Complete')]
        [Int16] $StartTab = 0, `
        [Parameter(Mandatory=$False, Position=6,ParameterSetName='Tab')]
        [Parameter(Mandatory=$False, Position=5,ParameterSetName='Complete')]
        [Int16] $LinesBefore = 0, `
        [Parameter(Mandatory=$False, Position=7,ParameterSetName='Tab')]
        [Parameter(Mandatory=$False, Position=6,ParameterSetName='Complete')]
        [Int16] $LinesAfter = 0, `
        [Parameter(Mandatory=$False, Position=9,ParameterSetName='Tab')]
        [String] $TimeFormat = "yyyy-MM-dd HH:mm:ss", `
        [Parameter(Mandatory=$False, Position=6,ParameterSetName='Normal')]
        [Parameter(Mandatory=$False, Position=10,ParameterSetName='Tab')]
        [Parameter(Mandatory=$False, Position=1,ParameterSetName='Counter')]
        [Int64] $IndexCounter, `
        [Parameter(Mandatory=$False, Position=7,ParameterSetName='Normal')]
        [Parameter(Mandatory=$False, Position=11,ParameterSetName='Tab')]
        [Parameter(Mandatory=$False, Position=2,ParameterSetName='Counter')]
        [Int64] $TotalCounter)

    Begin {
        $CurrentActionPreference = $ErrorActionPreference;
        $ErrorActionPreference = 'Stop'

        If ($Text.Count -gt 0) {
            If ($BackgroundColor.Count -eq 0 -and $ForegroundColor.Count -eq 0) { $OperationMode = 'WriteHost' }
            ElseIf ($BackgroundColor.Count -gt 0 -and $BackgroundColor.Count -lt $Text.Count -and $ForegroundColor.Count -eq 0) { $OperationMode = 'SingleBackground' }
            ElseIf ($ForegroundColor.Count -gt 0 -and $ForegroundColor.Count -lt $Text.Count -and $BackgroundColor.Count -eq 0) { $OperationMode = 'SingleForeground' }
            ElseIf ($BackgroundColor.Count -gt 0 -and $ForegroundColor.Count -lt $Text.Count -and $ForegroundColor.Count -gt 0 -and $ForegroundColor.Count -lt $Text.Count) { $OperationMode = 'SingleForegroundBackground' }
            ElseIf ($ForegroundColor.Count -gt 0 -and $BackgroundColor.Count -lt $Text.Count -and $BackgroundColor.Count -gt 0 -and $BackgroundColor.Count -lt $Text.Count) { $OperationMode = 'SingleBackgroundForeground' }
            ElseIf ($BackgroundColor.Count -gt 0 -and $BackgroundColor.Count -ge $Text.Count -or $ForegroundColor.Count -eq 0) { $OperationMode = 'Background' }
            ElseIf ($ForegroundColor.Count -gt 0 -and $ForegroundColor.Count -ge $Text.Count -or $BackgroundColor.Count -eq 0) { $OperationMode = 'Foreground' }
            ElseIf ($BackgroundColor.Count -eq $Text.Count -and $ForegroundColor.Count -eq $Text.Count) { $OperationMode = 'Normal' }
            Else { Throw }
        }
        If ($Complete -eq $True) { $OperationMode = 'Complete' }
    }
    Process {
        If ($LinesBefore -ne 0) { For ($i = 0; $i -lt $LinesBefore; $i++) { Write-Host "`n" -NoNewline } }
        If ($StartTab -ne 0) { For ($i = 0; $i -lt $StartTab; $i++) { Write-Host "`t" -NoNewLine } }
        If ($TotalCounter -gt 0 -and $IndexCounter -ge 0) {
            $CounterLength = $TotalCounter.ToString().Length
            Write-Host ("[" + ("{0:D$CounterLength}" -f ($IndexCounter + 1) + "/" + $TotalCounter) + "] ") -ForegroundColor DarkCyan -NoNewline
        }
        If ($OperationMode -eq 'WriteHost') { For ($Index = 0; $Index -lt $Text.Length; $Index ++) { Write-Host $Text[$Index] -NoNewLine } }
        If ($OperationMode -eq 'Foreground') { For ($Index = 0; $Index -lt $Text.Length; $Index ++) { Write-Host $Text[$Index] -ForegroundColor $ForegroundColor[$Index] -NoNewLine } }
        If ($OperationMode -eq 'Background') { For ($Index = 0; $Index -lt $Text.Length; $Index ++) { Write-Host $Text[$Index] -BackgroundColor $BackgroundColor[$Index] -NoNewLine } }
        If ($OperationMode -eq 'SingleBackground') { For ($Index = 0; $Index -lt $Text.Length; $Index ++) { Write-Host $Text[$Index] -BackgroundColor $BackgroundColor[0] -NoNewLine } }
        If ($OperationMode -eq 'SingleForeground') { For ($Index = 0; $Index -lt $Text.Length; $Index ++) { Write-Host $Text[$Index] -ForegroundColor $ForegroundColor[0] -NoNewLine } }
        If ($OperationMode -eq 'SingleForegroundBackground') { For ($Index = 0; $Index -lt $Text.Length; $Index ++) { Write-Host $Text[$Index] -ForegroundColor $ForegroundColor[0] -BackgroundColor $BackgroundColor[$Index] -NoNewLine } }
        If ($OperationMode -eq 'SingleBackgroundForeground') { For ($Index = 0; $Index -lt $Text.Length; $Index ++) { Write-Host $Text[$Index] -ForegroundColor $ForegroundColor[$Index] -BackgroundColor $BackgroundColor[0] -NoNewLine } }
        If ($OperationMode -eq 'Normal') { For ($Index = 0; $Index -lt $Text.Length; $Index ++) { Write-Host $Text[$Index] -ForegroundColor $ForegroundColor[$Index] -BackgroundColor $BackgroundColor[$Index] -NoNewLine } }
        If ($OperationMode -eq 'Complete') { Write-Host 'Complete' -ForegroundColor Green -NoNewLine }
        If ($LinesAfter -ne 0) { For ($i = 0; $i -lt $LinesAfter; $i++) { Write-Host "`n" } }
    }
    End {
        If ($NoNewLine -eq $False) { Write-Host } Else { }
        If ($LogFile -ne "") {
            $TextToFile = ""
            For ($i = 0; $i -lt $Text.Length; $i++) {
                $TextToFile += $Text[$i]
            }
            Write-Output "[$([datetime]::Now.ToString($TimeFormat))] $TextToFile" | Out-File $LogFile -Encoding unicode -Append
        }
        $ErrorActionPreference = $CurrentActionPreference
    }
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
Clear-Host

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
$ReferenceCI = "C:\temp\CI\CI-Reference.xlsx"
$ErrorActionPreference = "Stop"

Switch ($Domain) {
    "SNDDOMAIN" {
        $Servers = Get-ADComputer -Filter { OperatingSystem -like '*server*' -and Enabled -eq $true } | Sort-Object Name | Select-Object Name
        Write-Color -Text $Servers.Count.ToString(), ' found' -ForegroundColor Cyan, White
        $FailedServers = @()
        $SuccessServers = @()
        For ($a = 0; $a -lt $Servers.Count; $a ++) {
            # $Servers[$a].Name
            Write-Color -IndexCounter $a -TotalCounter $Servers.Count -Text 'Generating CI for - ', $Servers[$a].Name, ' - ' -ForegroundColor White, Yellow, White -NoNewLine
            $HTMLOutputFile = Get-TimeStampOutputFile -TargetLocation "C:\Temp\CI" -Extension ".html" -VariableName -Name $Servers[$a].Name
            $ExcelOutputFile = Get-TimeStampOutputFile -TargetLocation "C:\Temp\CI" -Extension ".xlsx" -VariableName -Name $Servers[$a].Name
            If (Test-Connection $Servers[$a].Name -Count 1 -Quiet) {
                Try {
                    $Serialnumber = (Get-WmiObject -Query "Select SerialNumber from Win32_BIOS" -ComputerName $Servers[$a].Name -ErrorAction Stop).SerialNumber
                    $TotalPhysicalMemory = [Math]::Round((Get-WmiObject -Query "Select TotalPhysicalMemory from Win32_ComputerSystem" -ComputerName $Servers[$a].Name -ErrorAction Stop).TotalPhysicalMemory/1024/1024/1024)
                    $OSVersion = (Get-WmiObject -Query "Select Caption from Win32_OperatingSystem" -ComputerName $Servers[$a].Name -ErrorAction Stop).Caption
                    $OSServicePack = (Get-WmiObject -Query "Select ServicePackMajorVersion from Win32_OperatingSystem" -ComputerName $Servers[$a].Name -ErrorAction Stop).ServicePackMajorVersion
                    $Make = (Get-WmiObject -Query "Select Manufacturer from Win32_ComputerSystem" -ComputerName $Servers[$a].Name -ErrorAction Stop).Manufacturer
                    $Model = (Get-WmiObject -Query "Select Model from Win32_ComputerSystem" -ComputerName $Servers[$a].Name -ErrorAction Stop).Model                                
                    [String[]] $CPUSpeed = (Get-WmiObject -Query "Select MaxClockSpeed from Win32_Processor" -ComputerName $Servers[$a].Name -ErrorAction Stop).MaxClockSpeed
                    [String[]] $CPUName = (Get-WmiObject -Query "Select Name from Win32_Processor" -ComputerName $Servers[$a].Name -ErrorAction Stop).Name
                    $NumberOfLogicalProcessors = (Get-WmiObject -Query "Select NumberOfLogicalProcessors from Win32_ComputerSystem" -ComputerName $Servers[$a].Name -ErrorAction Stop).NumberOfLogicalProcessors                
                    $SystemRole = (Get-AdComputer $Servers[$a].Name -Properties Description -ErrorAction Stop).Description
                    $ServerDomain = (Get-WmiObject -Query "Select Domain from Win32_ComputerSystem" -ComputerName $Servers[$a].Name -ErrorAction Stop).Domain
             
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
                    $NetworkDetails = Get-NICDetails -Server $Servers[$a].Name
                    $DiskDetails = Get-DiskDetails -Server $Servers[$a].Name
                
                    #region Single HTML Output
                    $Server = $Servers[$a].Name
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
                    $Servers[$a].Name | Out-File C:\Temp\CI\SuccessServers.txt -Encoding ascii -Append
                <#region Excel
                Write-Color -Text " - Exporting to - ", $ExcelOutputFile, " - " -ForegroundColor White, Yellow, White
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
                    #$ActiveWorksheet.Cells.Item(141,3)  = (Get-VM $Server).VMHost.Name                    # Physical Host
                    #$ActiveWorksheet.Cells.Item(142,3)  = (Get-Cluster (Get-VM $Server).VMHost.Name).Name # Virtual Cluster
                }
                Else {
                    $ActiveWorksheet.Cells.Item(8,3)    = "Hardware"                                      # Tier 1
                }
                $ActiveWorksheet.Cells.Item(9,3)    = "Processing Unit"                               # Tier 2
                $ActiveWorksheet.Cells.Item(10,3)   = "Server"                                        # Tier 3
                $ActiveWorksheet.Cells.Item(11,3)   = $Model                                          # Model
                $ActiveWorksheet.Cells.Item(12,3)   = $Servers[$a].Name                                         # Server
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
                #> #endregion
                    Write-Color -Complete
                }
                Catch {
                    Write-Host $_ -ForegroundColor Red
                    $FailedServers += ,(New-Object -TypeName PSObject -Property @{
                        Server = $Servers[$a].Name
                        Failure = $_
                    })
                    $Servers[$a].Name | Out-File C:\Temp\CI\FailedServers.txt -Encoding ascii -Append
                }
            }
            Else { 
                $FailedServers += ,(New-Object -TypeName PSObject -Property @{
                        Server = $Servers[$a].Name
                        Failure = 'No ping response'
                    })
                Write-Host "Cannot Ping" -ForegroundColor Red 
            }
        }
    }
}