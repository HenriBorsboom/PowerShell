Function Get-HAVMs {
    Param (
        [Parameter(Mandatory=$True, Position=0, ParameterSetName="Single")]
        [String] $Cluster, `
        [Parameter(Mandatory=$True, Position=0, ParameterSetName="Domain")]
        [String] $Domain)

    Switch ($PSCmdlet.ParameterSetName) {
        "Single" {$Clusters = @($Cluster)}
        "Domain" {$Clusters = (Get-Cluster -Domain $Domain).Name}
    }

    $VMs = @()
    ForEach ($Cluster in $Clusters) {
        $HAVms = ((Get-ClusterResource -Cluster $Cluster | Where ResourceType -eq "Virtual Machine").OwnerGroup).Name
        ForEach ($Server in (Get-ClusterNode -Cluster $Cluster).Name) {
            ForEach ($VM in (Get-VM -ComputerName $Server)) {
                If ($HAVms.Contains($VM.Name)) { $HA = $True } Else {$HA = $False}
                $Details = New-Object PSObject -Property @{
                    Cluster = $Cluster
                    Server  = $Server
                    VMName  = $VM.Name
                    VMState = $VM.State
                    HA      = $HA
                }
                $VMS = $VMS + $Details
            }
        }
    }
    Return $VMs
    
}


Clear-Host

$VMs = Get-HAVMs -Domain DOMAIN3
$VMs | Select Cluster, Server, VMName, VMState, HA | Ft -AutoSize