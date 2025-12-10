Function Get-vCenterVMS {
    Param (
        [Parameter(Mandatory=$False, Position=1)]
        [Switch] $Dummy)

    # Dummy can be passed to the Function to generate dummy info
    # Get all VMs from the VMWare Platform by selecting Name, PowerState, IPAddress[0]
    # Cycle through all VMs and tag critical if not PoweredOn
    # If less than half of the VMs are unhealthy, set the global to Warning, else Critical
    
    $ReportVMs = @()
    Switch ($Dummy) {
        $True {
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
        $False {
            $VMUnhealthyCounter = 0
            
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