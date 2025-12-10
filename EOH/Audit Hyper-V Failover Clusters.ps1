Import-Module Hyper-V
Import-Module FailoverClusters

Write-Host "Getting clusters in domain"
$Clusters = Get-Cluster -Domain $env:UserDomain

$Results = @()
$OtherResults = @()
ForEach ($Cluster in $Clusters) {
    Write-Host " Processing $Cluster"
    # Check if VMs hosted on Cluster
    Write-Host "  Checking if cluster has Virtual Machine Resources"
    Try { $ClusterResources = Get-ClusterResource -Cluster $Cluster -ErrorAction Stop }
    Catch { Write-Host ("Cluster Failed - " + $_) -ForegroundColor Red }
    If ($ClusterResources.ResourceType -contains "Virtual Machine") {
    #If ($VMs.Count -gt 0) {
        # VM Cluster
        Write-Host "  Getting cluster nodes"
        $ClusterNodes = Get-ClusterNode -Cluster $Cluster | Select Name
        ForEach ($Node in $ClusterNodes.Name) {
            Write-Host "  Getting VMs on $Node"
            $NodeVMs = Get-VM -ComputerName $Node
            Write-Host "  Formatting results"
            ForEach ($VM in $NodeVMs) {
                $Result = New-Object -TypeName PSObject -Property @{
                    Cluster = $Cluster
                    Node    = $Node
                    Name    = $VM.Name
                    State   = $VM.State
                }
                $Results += ,($Result)
            }
        }
    }
    Else {
        Write-Host "  Not a VM Cluster"
        $Resources = Get-ClusterResource -Cluster $Cluster
        ForEach ($Resource in $Resources) {
            $Result = New-Object -TypeName PSObject -Property @{
                Cluster      = $Cluster
                Name         = $Resource.Name
                State        = $Resource.State
                ResourceType = $Resource.ResourceType
            }
            $OtherResults += ,($Result)
        }
    }
}
Write-Host "Hyper-V Results" -ForegroundColor Green
$Results
Write-Host "Other Results" -ForegroundColor Yellow
$OtherResults
