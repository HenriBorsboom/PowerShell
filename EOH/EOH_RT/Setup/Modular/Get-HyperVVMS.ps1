Function Get-HyperVVMS {
    Param (
        [Parameter(Mandatory=$False, Position=1)]
        [String] $VMHost = $env:COMPUTERNAME)

     # VMHost can be passed to the function but defaults to the localhost
     # Determine the OS of the target to determine the VM Namespace
     # Get the VMs from the host
     # Cycle through VMs to determine health, IP address
     # If less than half of the VMs are unhealthy, set the global to Warning, else Critical

    $VMUnhealthyCounter = 0
    $ReportVMs = @()
    $OSCaption = (Get-WmiObject -Class 'Win32_OperatingSystem' -Property 'Caption' -ComputerName $VMHost).Caption
    If ($OSCaption -like '*2008*')    { $Namespace = 'root\virtualization' }
    ElseIf ($OSCaption -like '*201*') { $Namespace = 'root\virtualization\v2' }
    Else                              { $Namespace = 'root\virtualization' }

    $VMs = Get-WmiObject -Query "Select * from MSVM_ComputerSystem Where Caption = 'Virtual Machine'" -Namespace $Namespace  -ComputerName $VMHost
    
    ForEach ($VM in $VMs) {
        If ($VM.EnabledState -eq 3) {
            $VMUnhealthyCounter += 1
            $VMHealthIcon = "[CriticalImage]"
            $VMState = 'PoweredOff'
        }
        Else {
            $VMHealthIcon = "[NonCriticalImage]"
            $VMState = 'PoweredOn'
        }
        #Get IP Address
        If ($Namespace -eq 'root\virtualization') {
            $VMIPAddress = 'Not available on this host'
        }
        Else {
            $VMIPAddress = $vm.GetRelated("Msvm_KvpExchangeComponent").GuestIntrinsicExchangeItems | `
                ForEach-Object {
                    $GuestExchangeItemXml = ([XML]$_).SelectSingleNode("/INSTANCE/PROPERTY[@NAME='Name']/VALUE[child::text()='NetworkAddressIPv4']")
                    If ($GuestExchangeItemXml -ne $null) { 
                        $GuestExchangeItemXml.SelectSingleNode("/INSTANCE/PROPERTY[@NAME='Data']/VALUE/child::text()").Value
                    }    
                }
        }
        $ReportVMs += ,(New-Object -TypeName PSObject -Property @{
            Name      = $VM.ElementName
            IPAddress = $VMIPAddress
            State     = $VMState
            Health    = $VMHealthIcon
        })
    }
    If ($VMUnhealthyCounter -eq 0) {
        $Global:VMImage = $NonCriticalImage48
        $Global:VMIcon = "[NonCriticalImage]"
    }
    ElseIf ($VMUnhealthyCounter -lt ($VMs.Count / 2)) {
        $Global:VMImage = $WarningImage48
        $Global:VMIcon = "[WarningImage]"
    }
    Else {
        $Global:VMImage = $CriticalImage48
        $Global:VMIcon = "[CriticalImage]"
    }
    Return $ReportVMs | Select-Object Name, IPAddress, State, Health
}