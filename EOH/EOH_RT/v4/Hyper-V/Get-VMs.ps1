Param (
    [Parameter(Mandatory=$False, Position=1)]						# Target System Must contain: SystemName, IPAddress, CommonName, Platform, Username, Password
    [Object[]] $ReportingEnvironment)	

Function Get-VMs {
    Param (
        [Parameter(Mandatory=$True, Position=1)]
        [Object[]] $Environment)

    $ReportVMs = @()
    $VMWarningCounter = 0
    $VMCriticalCounter = 0

    $OSCaption = (Get-WmiObject -Class 'Win32_OperatingSystem' -Property 'Caption' -ComputerName $Environment.'IP Address').Caption
    If ($OSCaption -like '*201*') { 
        $Namespace = 'root\virtualization\v2' 
        $VMs = Get-VM -ComputerName $Environment.'IP Address'
        ForEach ($VM in $VMs) {
            If ($VM.State -ne 'Running') {
                $VMUnhealthyCounter  += 1
                $VMState              = 'PoweredOff'
                ForEach ($Exclusion in $VMCriticalExclusionList) {
                    If ($VM.Name -like $Exclusion) {
                        $VMHealthIcon = "[WarningImage]"
                    }
                    Else {
                        $VMHealthIcon         = "[CriticalImage]"
                    }
                }
            }
            Else {
                $VMHealthIcon         = "[NonCriticalImage]"
                $VMState              = 'PoweredOn'
            }
            If ($VM.NetworkAdapters.IPAddresses -eq $null) {
                $VMIPAdress = ''
            }
            Else {
                If ($VM.NetworkAdapters.IPAddresses.GetType().Name -eq 'Object[]') { 
                    ForEach ($VMIP in $VM.NetworkAdapters.IPAddresses) {
                        If (([System.Net.IPAddress] $VMIP).AddressFamily -ne 'InterNetworkV6') { $VMIPAddress = $VMIP }
                    }
                }
                Else {$VMIPAddress = $VM.NetworkAdapters.IPAddresses}
            }
            $ReportVMs += ,(New-Object -TypeName PSObject -Property @{
                'Name'       = $VM.Name
                'IP Address' = $VMIPAddress
                'State'      = $VMState
                'Tools State' = ''
                'Health'     = $VMHealthIcon
            })
            $VMIPAddress = $null
        }
    }
    Else { 
        $VMs = Get-WmiObject -Query "Select * from MSVM_ComputerSystem Where Caption = 'Virtual Machine'" -Namespace 'root\virtualization'  -ComputerName $Environment.'IP Address'
    
        ForEach ($VM in $VMs) {
            If ($VM.EnabledState -eq 3) {
                $VMUnhealthyCounter  += 1
                $VMState              = 'PoweredOff'
                ForEach ($Exclusion in $VMCriticalExclusionList) {
                    If ($VM.ElementName -like $Exclusion) {
                        $VMHealthIcon = "[WarningImage]"
                    }
                    Else {
                        $VMHealthIcon = "[CriticalImage]"
                    }
                }
            }
            Else {
                $VMHealthIcon         = "[NonCriticalImage]"
                $VMState              = 'PoweredOn'
            }
                    
            $ReportVMs += ,(New-Object -TypeName PSObject -Property @{
                'Name'       = $VM.ElementName
                'IP Address' = 'Not available on this host'
                'State'      = $VMState
                'Tools State' = ''
                'Health'     = $VMHealthIcon
            })
        }
    }

    Return $ReportVMs | Select-Object 'Name', 'IP Address', 'State', 'Tools State', 'Health'
}