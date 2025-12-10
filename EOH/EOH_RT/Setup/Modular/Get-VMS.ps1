Function Get-VMS {
    Param (
        [Parameter(Mandatory=$True, Position=1)][ValidateSet('HyperVCluster', 'HyperVStandalone', 'VMWare', 'Dummy')]
        [String] $Platform, `
        [Parameter(Mandatory=$False, Position=2)]
        [String] $VMHost = $env:COMPUTERNAME)

    If ($Platform -like 'Hyper*') { $Platform = 'HyperV' }
    
    $ReportVMs = @()
    $VMUnhealthyCounter = 0

    Switch ($Platform) {
        'HyperV' {
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
        }
        'VMWare' {
            ForEach ($VM in (Get-VM | Select Name, PowerState, @{N="IPAddress";E={@($_.guest.IPAddress[0])}})) {
                If ($VM.PowerState -ne 'PoweredOn') {
                    $VMUnhealthyCounter += 1 
                    $VMHealthIcon        = "[CriticalImage]" 
                }
                Else {
                    $VMHealthIcon        = "[NonCriticalImage]"
                }
                $ReportVMs += ,(New-Object -TypeName PSObject -Property @{
                    Name      = $VM.Name
                    IPAddress = $VM.IPAddress
                    State     = $VM.PowerState
                    Health    = $VMHealthIcon
                })
            }
        }
        'Dummy' {
            $VMUnhealthyCounter = 2
            $ReportVMs += ,(New-Object -TypeName PSObject -Property @{
                Name      = 'Test VM 1'
                IPAddress = '1.1.1.1'
                State     = 'PoweredOn'
                Health    = '[NonCriticalImage]'
            }) # Non Critical
            $ReportVMs += ,(New-Object -TypeName PSObject -Property @{
                Name      = 'Test VM 2'
                IPAddress = '2.2.2.2'
                State     = 'PoweredOff'
                Health    = '[CriticalImage]'
            }) # Critical
            $ReportVMs += ,(New-Object -TypeName PSObject -Property @{
                Name      = 'Test VM 3'
                IPAddress = '3.3.3.3'
                State     = 'PoweredMissing'
                Health    = '[WarningImage]'
            }) # Warning
        }
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
Get-VMS -Platform Dummy