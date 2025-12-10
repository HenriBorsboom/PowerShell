Function Set-ComputerDescription {
    Param (
        [Parameter(Mandatory=$true, Position=1)]
        [String] $Server, `
        [Parameter(Mandatory=$true, Position=2)]
        [String] $Description)

    Try {
        If ($Server -eq $env:COMPUTERNAME) {
            $WMIResults = Get-WMIObject Win32_OperatingSystem -ErrorAction Stop
        }
        Else {
            $WMIResults = Get-WMIObject Win32_OperatingSystem -ComputerName $Server -ErrorAction Stop
        }
        $WMIResults.Description = $Description
        $empty = $WMIResults.Put()
        Return $true
    }
    Catch { Return $false }
}
Function Get-VMHostName {
    Param (
        [Parameter(Mandatory=$true, Position=1)]
        [String] $VMName)
    Try { Return $VMHost = (Get-SCVirtualMachine -Name $VMName).VMHost.Name }
    Catch { Return $false }
}
Function Get-SerialNumber {
    Param (
        [Parameter(Mandatory=$true, Position=1)]
        [String] $Server)
    Try { 
        If ($Server -eq $env:COMPUTERNAME) {
            $WMIResults = Get-WmiObject -Query "Select SerialNumber from Win32_BIOS"
        }
        Else {
            $WMIResults = Get-WmiObject -Query "Select SerialNumber from Win32_BIOS" -ComputerName $Server
        }
        $SerialNumber = $WMIResults.SerialNumber
        Return $SerialNumber
    }
    Catch { Return $false }
}
Function Get-Model {
    Param (
        [Parameter(Mandatory=$true, Position=1)]
        [String] $Server)
    Try { 
        If ($Server -eq $env:COMPUTERNAME) {
            $WMIResults = Get-WmiObject -Query "Select Model from Win32_ComputerSystem"
        }
        Else {
            $WMIResults = Get-WmiObject -Query "Select Model from Win32_ComputerSystem" -ComputerName $Server
        }
        $Model = $WMIResults.Model
        Return $Model
    }
    Catch { Return $false }
}
Function Get-OSVersion {
    Param (
        [Parameter(Mandatory=$true, Position=1)]
        [String] $Server)
    $WMIQuery = "Select Caption from Win32_OperatingSystem"
    Try { 
        If ($Server -eq $env:COMPUTERNAME) {
            $WMIResults = Get-WmiObject -Query $WMIQuery
        }
        Else {
            $WMIResults = Get-WmiObject -Query $WMIQuery -ComputerName $Server
        }
        $OSVersion = $WMIResults.Caption
        Return $OSVersion
    }
    Catch { Return $false }
}
Function Get-LogicalCPUCount {
    Param (
        [Parameter(Mandatory=$true, Position=1)]
        [String] $Server)
    $WMIQuery = "Select NumberOfLogicalProcessors from Win32_ComputerSystem"
    Try { 
        If ($Server -eq $env:COMPUTERNAME) {
            $WMIResults = Get-WmiObject -Query $WMIQuery
        }
        Else {
            $WMIResults = Get-WmiObject -Query $WMIQuery -ComputerName $Server
        }
        $NumberOfLogicalProcessors = $WMIResults.NumberOfLogicalProcessors
        Return $NumberOfLogicalProcessors
    }
    Catch { Return $false }
}
Function Get-CPUName {
    Param (
        [Parameter(Mandatory=$true, Position=1)]
        [String] $Server)
    $WMIQuery = "Select Name from Win32_Processor"
    Try { 
        If ($Server -eq $env:COMPUTERNAME) {
            $WMIResults = Get-WmiObject -Query $WMIQuery
        }
        Else {
            $WMIResults = Get-WmiObject -Query $WMIQuery -ComputerName $Server
        }
        $Name = $WMIResults.Name
        Return $Name
    }
    Catch { Return $false }
}
Function Get-CPUSpeed {
    Param (
        [Parameter(Mandatory=$true, Position=1)]
        [String] $Server)
    $WMIQuery = "Select MaxClockSpeed from Win32_Processor"
    Try { 
        If ($Server -eq $env:COMPUTERNAME) {
            $WMIResults = Get-WmiObject -Query $WMIQuery
        }
        Else {
            $WMIResults = Get-WmiObject -Query $WMIQuery -ComputerName $Server
        }
        $MaxClockSpeed = $WMIResults.MaxClockSpeed
        Return $MaxClockSpeed
    }
    Catch { Return $false }
}
Function Get-RAM {
    Param (
        [Parameter(Mandatory=$true, Position=1)]
        [String] $Server)
    $WMIQuery = "Select TotalPhysicalMemory from Win32_ComputerSystem"
    Try { 
        If ($Server -eq $env:COMPUTERNAME) {
            $WMIResults = Get-WmiObject -Query $WMIQuery
        }
        Else {
            $WMIResults = Get-WmiObject -Query $WMIQuery -ComputerName $Server
        }
        $TotalPhysicalMemory = [Math]::Round($WMIResults.TotalPhysicalMemory/1024/1024/1024)
        Return $TotalPhysicalMemory
    }
    Catch { Return $false }
}
Function Get-TotalDisks {
    Param (
        [Parameter(Mandatory=$true, Position=1)]
        [String] $Server)
    $WMIQuery = "Select Caption from Win32_LogicalDisk Where DriveType = 3"
    Try { 
        If ($Server -eq $env:COMPUTERNAME) { $WMIResults = Get-WmiObject -Query $WMIQuery }
        Else                               { $WMIResults = Get-WmiObject -Query $WMIQuery -ComputerName $Server }
        $TotalDisks = ($WMIResults.Caption).Count
        Return $TotalDisks
    }
    Catch { Return $false }
}
Function Get-DiskSize {
    Param (
        [Parameter(Mandatory=$true, Position=1)]
        [String] $Server, `
        [Parameter(Mandatory=$true, Position=2)]
        [String] $Drive)
    $WMIQuery = "Select Size from Win32_LogicalDisk Where Caption = ""$Drive"""
    Try { 
        If ($Server -eq $env:COMPUTERNAME) { $WMIResults = Get-WmiObject -Query $WMIQuery }
        Else                               { $WMIResults = Get-WmiObject -Query $WMIQuery -ComputerName $Server }
        $Size = [Math]::Round($WMIResults.Size / 1024 / 1024 / 1024)
        Return $Size
    }
    Catch { Return $false }
}
Function Get-Disks {
    Param (
        [Parameter(Mandatory=$true, Position=1)]
        [String] $Server)
    $WMIQuery = "Select Caption from Win32_LogicalDisk Where DriveType = 3"
    Try { 
        If ($Server -eq $env:COMPUTERNAME) { $WMIResults = Get-WmiObject -Query $WMIQuery }
        Else                               { $WMIResults = Get-WmiObject -Query $WMIQuery -ComputerName $Server }
        $Disks = $WMIResults.Caption
        Return $Disks
    }
    Catch { Return $false }
}
Function Get-MACAddress {
    Param (
        [Parameter(Mandatory=$true, Position=1)]
        [String] $Server)
        
    $WMIQuery = "Select MACAddress from Win32_NetworkAdapter Where NetConnectionStatus = ""2"""
    Try { 
        If ($Server -eq $env:COMPUTERNAME) { $WMIResults = Get-WmiObject -Query $WMIQuery }
        Else                               { $WMIResults = Get-WmiObject -Query $WMIQuery -ComputerName $Server }
        $MACAddress = $WMIResults.MACAddress
        Return $MACAddress
    }
    Catch { Return $false }
}
Function Get-NetworkAdapterName {
    Param (
        [Parameter(Mandatory=$true, Position=1)]
        [String] $Server, `
        [Parameter(Mandatory=$true, Position=2)]
        [String] $MACAddress)
        
    $WMIQuery = "Select NetConnectionID from Win32_NetworkAdapter Where MACAddress = ""$MACAddress"""
    Try { 
        If ($Server -eq $env:COMPUTERNAME) { $WMIResults = Get-WmiObject -Query $WMIQuery }
        Else                               { $WMIResults = Get-WmiObject -Query $WMIQuery -ComputerName $Server }
        $NetConnectionID = $WMIResults.NetConnectionID
        Return $NetConnectionID
    }
    Catch { Return $false }
}
Function Get-IPAddress {
    Param (
        [Parameter(Mandatory=$true, Position=1)]
        [String] $Server, `
        [Parameter(Mandatory=$true, Position=2)]
        [String] $MACAddress)
        
    $WMIQuery = "Select IPAddress from Win32_NetworkAdapterConfiguration Where MACAddress = ""$MACAddress"""
    Try { 
        If ($Server -eq $env:COMPUTERNAME) { $WMIResults = Get-WmiObject -Query $WMIQuery }
        Else                               { $WMIResults = Get-WmiObject -Query $WMIQuery -ComputerName $Server }
        $IPAddress = $WMIResults.IPAddress
        Return $IPAddress
    }
    Catch { Return $false }
}
Function Get-DefaultGateway {
    Param (
        [Parameter(Mandatory=$true, Position=1)]
        [String] $Server, `
        [Parameter(Mandatory=$true, Position=2)]
        [String] $MACAddress)
        
    $WMIQuery = "Select DefaultIPGateway from Win32_NetworkAdapterConfiguration Where MACAddress = ""$MACAddress"""
    Try { 
        If ($Server -eq $env:COMPUTERNAME) { $WMIResults = Get-WmiObject -Query $WMIQuery }
        Else                               { $WMIResults = Get-WmiObject -Query $WMIQuery -ComputerName $Server }
        $DefaultIPGateway = $WMIResults.DefaultIPGateway
        Return $DefaultIPGateway
    }
    Catch { Return $false }
}
Function Get-Subnet {
    Param (
        [Parameter(Mandatory=$true, Position=1)]
        [String] $Server, `
        [Parameter(Mandatory=$true, Position=2)]
        [String] $NetworkAdapterName)
        
    $WMIQuery = "Select IPSubnet from Win32_NetworkAdapterConfiguration Where MACAddress = ""$NetworkAdapterName"""
    Try { 
        If ($Server -eq $env:COMPUTERNAME) { $WMIResults = Get-WmiObject -Query $WMIQuery }
        Else                               { $WMIResults = Get-WmiObject -Query $WMIQuery -ComputerName $Server }
        $IPSubnet = $WMIResults.IPSubnet
        Return $IPSubnet
    }
    Catch { Return $false }
}

Clear-Host
$Servers = @(
"APPSERVER101", `
"NRAZUREAPP102", `
"APPSERVER103", `
"NRAZUREAPP104", `
"NRAZUREAPP105", `
"NRAZUREAPP106", `
"NRAZUREAPP107", `
"NRAZUREAPP108", `
"NRAZUREAPP109", `
"NRAZUREAPP110", `
"NRAZUREAPP111", `
"NRAZUREAPP113", `
"NRAZUREAPP201", `
"NRAZUREAPP202", `
"NRAZUREAPP203", `
"NRAZUREAPP204", `
"NRAZUREAPP206", `
"NRAZUREAPP207", `
"NRAZUREAPP208", `
"NRAZUREAPP209", `
"NRAZUREAPP210", `
"NRAZUREAPP211", `
"NRAZUREAPP212", `
"NRAZUREAPP213", `
"NRAZUREAPP214", `
"NRAZUREBCK101", `
"NRAZUREDBS101", `
"NRAZUREDBS201", `
"NRAZUREDSCW101", `
"NRAZUREFLS101", `
"NRAZUREFLS201", `
"NRAZUREGCS101", `
"NRAZUREGCS102", `
"VMSERVER201", `
"NRAZUREGCS202", `
"NRAZURESQL101", `
"NRAZURESQM101", `
"NRAZURETS101", `
"TSSERVER201", `
"NRAZUREVMH101", `
"NRAZUREVMH102", `
"NRAZUREVMH103", `
"NRAZUREVMH104", `
"NRAZUREVMH105", `
"NRAZUREVMH201", `
"NRAZUREVMH202", `
"NRAZUREVMH203", `
"NRAZUREVMH204", `
"NRAZUREVMH205", `
"NRAZUREVMH206", `
"NRAZUREVMH207", `
"NRAZUREVMH208", `
"WEBSERVER101", `
"WEBSERVER102", `
"WEBSERVER103", `
"WEBSERVER104", `
"WEBSERVER105", `
"WEBSERVER106", `
"WEBSERVER107", `
"WEBSERVER108", `
"NRAZUREWGS101", `
"NRAZUREWGS102")

ForEach ($Server in $Servers) {
    #Write-Host "$Server;" -NoNewline
    #$Result = Get-MACAddress -Server $Server
    #Write-Host ($Result -join ";")
    
    $Result = Get-MACAddress -Server $Server
    ForEach ($MACAddress in $Result) {
        $NetworkAdapterName = Get-NetworkAdapterName -Server $Server -MACAddress $MACAddress
        Write-Host "$Server;" -NoNewline
        #Write-Host $MACAddress -NoNewline
        #Write-Host ";" -NoNewline
        #Write-Host ($NetworkAdapterName -join ";") -NoNewline
        #Write-Host ";" -NoNewline
        
        $IPAddresses = Get-IPAddress -Server $Server -MACAddress $MACAddress
        ForEach ($IPAddress in $IPAddresses) {
            $JoinedIP = $IPAddress -join "."
            If ($JoinedIP -notlike "fe*") {
                Write-Host ($IPAddress -join ".") -NoNewline
                Write-Host ";" -NoNewline
                $Subnet = Get-Subnet -Server $Server -NetworkAdapterName $NetworkAdapterName
                Write-Host ($Subnet -join ".") -NoNewline
                Write-Host ";"
            }
        }
        #$DefaultGateway = Get-DefaultGateway -Server $Server -MACAddress $MACAddress
        #Write-Host ($DefaultGateway -join ".") -NoNewline
        Write-Host #";"
    }
}
