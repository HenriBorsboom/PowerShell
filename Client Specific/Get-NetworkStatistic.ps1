Function Get-NetworkStatistics {
    Param (
        [Parameter(Mandatory=$false, ParameterSetName="Remote")]
        [String] $ComputerName,

        [parameter(Mandatory=$false)]
        [Switch] $Summary)

    $properties = ‘Protocol’,’LocalAddress’,’LocalPort’
    $properties += ‘RemoteAddress’,’RemotePort’,’State’,’ProcessName’,’PID’

    Switch ($PsCmdlet.ParameterSetName) {
        "Remote" {
            $Results = Invoke-Command -ComputerName $ComputerName -ScriptBlock { NetStat -ano | Select-String -Pattern ‘\s+(TCP|UDP)’ }
        }
        default {
            $Results = NetStat -ano | Select-String -Pattern ‘\s+(TCP|UDP)’ 
        }
    }

    ForEach ($Port in $Results) {
        $Item = $Port.line.split(” “,[System.StringSplitOptions]::RemoveEmptyEntries)
        If ($Item[1] -notmatch ‘^\[::’) {           
            If (($LA = $Item[1] -as [ipaddress]).AddressFamily -eq ‘InterNetworkV6’) {
               $LocalAddress  = $LA.IPAddressToString
               $LocalPort     = $Item[1].split(‘\]:’)[-1] }
            Else {
                $LocalAddress = $item[1].split(‘:’)[0]
                $LocalPort    = $item[1].split(‘:’)[-1] }

            If (($RA = $Item[2] -as [ipaddress]).AddressFamily -eq ‘InterNetworkV6’) {
               $RemoteAddress = $RA.IPAddressToString
               $RemotePort    = $Item[2].split(‘\]:’)[-1] }
            Else {
               $RemoteAddress = $Item[2].split(‘:’)[0]
               $RemotePort    = $Item[2].split(‘:’)[-1] }
            
            New-Object PSObject -Property @{
                PID = $Item[-1]
                ProcessName   = (Get-Process -Id $Item[-1] -ErrorAction SilentlyContinue).Name
                Protocol      = $Item[0]
                LocalAddress  = $LocalAddress
                LocalPort     = $LocalPort
                RemoteAddress = $RemoteAddress
                RemotePort    = $RemotePort
                State         = If ($Item[0] -eq ‘tcp’) { $Item[3] } Else { $null }
            } | Select-Object -Property $properties
        }
    }
} 
Clear-Host
Get-NetworkStatistics | FT
Get-Net