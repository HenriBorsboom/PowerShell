$ErrorActionPreference = "Stop"
<#
Hosts
SLBHYPDRP101
SLBHYPDRP102

Need 

Server name  # Win32_ComputerSystem Caption
OS           # Win32_OperatingSystem Caption
CPU          # Win32_Processor NumberOfLogicalProcessors
RAM          # Win32_ComputerSystem TotalPhysicalMemory
Disks        # Win32_LogicalDisk DeviceID, Size
#>
Clear-Host
$Hosts = @()
$Hosts += ,("SLBHYPDRP101")
$Hosts += ,("SLBHYPDRP102")

$Details = @()
$Properties = @("VMHost", "VMName", "OS", "CPU", "RAM", "Drives")
For ($HostIndex = 0; $HostIndex -lt $Hosts.Count; $HostIndex ++) {
#ForEach ($VMHost in $Hosts) {
    Write-Host (($HostIndex + 1).ToString() + "/" + $Hosts.Count.ToString() + " Getting VMs from " + $Hosts[$HostIndex]) -ForegroundColor DarkCyan
    $HostedVMs = Get-VM -ComputerName $Hosts[$HostIndex]
    For ($VMIndex = 0; $VMIndex -lt $HostedVMs.Count; $VMIndex ++) {
    #ForEach ($VM in $HostedVMs) {
        Write-Host (($VMIndex + 1).ToString() + "/" + $HostedVMs.Count.ToString() + " Running WMI queries against " + $HostedVMs[$VMIndex].Name + " - ") -NoNewline
        $VM = Get-VM $HostedVMs[$VMIndex].VMName -ComputerName $Hosts[$HostIndex]
            
        $VMName = $VM.VMName
        $CPU = $VM.ProcessorCount
        $RAM = $VM.MemoryStartup
        $Disks  = Get-VHD $VM.HardDrives.Path -ComputerName $Hosts[$HostIndex]
        $Drives = @()
        ForEach ($Disk in $Disks) {
            $Drives += ,("FileSize: " + $Disk.FileSize.ToString() + " - Max Size: " + $Disk.Size.ToString())
        }
        Try {    
            $OSName = (Get-WmiObject -Class "Win32_OperatingSystem" -Property "Caption" -ComputerName $HostedVMs[$VMIndex].Name).Caption
            Write-Host "Complete" -ForegroundColor Green
        }
        Catch {
            $OSName = $_
            Write-Host $_ -ForegroundColor Yellow
        }
        Finally {
            $Details += ,(New-Object -TypeName PSObject -Property @{
                VMHost = $Hosts[$HostIndex]
                VMName = $VMName
                OS     = $OSName
                CPU    = $CPU 
                RAM    = $RAM
                Drives = $Drives -join ";"
            })
        }
    }
}
$OutFile = $Env:temp + "\vms.csv"
$Details | Select $Properties | ft -AutoSize
$Details | Select $Properties | Export-CSV $OutFile -Delimiter "," -NoTypeInformation -Force
Notepad $OutFile