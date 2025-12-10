Clear-Host
Function Write-Color {
    Param(
        [String[]] $Text, `
        [ConsoleColor[]] $Color, `
        [switch] $EndLine)
    
    If ($Text.Count -ne $Color.Length) {
        Write-Host "DEBUG!!!!! - Write-Color" -ForegroundColor Red
        Write-Host "The amount of Text variables and the amount of color variables does not match"
        Write-Host "Text Variables:  " $Text.Count
        Write-Host "Color Variables: " $Color.Length
        Break
    }
    Else {
        For ($i = 0; $i -lt $Text.Length; $i++) {
            Write-Host $Text[$i] -Foreground $Color[$i] -NoNewLine
        }
        Switch ($EndLine){
            $true {Write-Host}
            $false {Write-Host -NoNewline}
        }
    }
}
Function RefreshFailoverCluster {
    Param (
        [Parameter(Mandatory=$true)] 
        [String] $ClusterName)

    Import-Module FailoverClusters
    Get-ClusterResource -c $ClusterName | where {$_.resourcetype.name -eq 'virtual machine configuration'} | Update-ClusterVirtualMachineConfiguration
}
Function RefreshSCVMCluster {
    Param (
        [Parameter(Mandatory=$True, Position=1)]
        [String] $TargetCluster, `
        [Parameter(Mandatory=$False, Position=2)]
        [Switch] $FailoverCluster)

#region Clusters
    $ManagementCluster = @(
        "NRAZUREVMH101", `
        "NRAZUREVMH102")
    $IBMTenantCluster = @(
        "NRAZUREVMH201", `
        "NRAZUREVMH202", `
        "NRAZUREVMH203", `
        "NRAZUREVMH204", `
        "NRAZUREVMH205", `
        "NRAZUREVMH206", `
        "NRAZUREVMH207", `
        "NRAZUREVMH208")
    $IBMTenantSQLCluster = @(
        "NRAZUREVMH104", `
        "NRAZUREVMH105")
    $CiscoTenantCluster = @(
        "NRAPCAPP101", `
        "NRAPCAPP102")
    $CiscoManagementCluster = @(
        "NRAPCSYS101", `
        "NRAPCSYS102")
    $CiscoTenantSQLCluster = @(
        "NRAPCDBS101.domain1.local", `
        "NRAPCDBS201.domain1.local")
#endregion
#region SelectionConversion
    If ($TargetCluster -eq "ManagementCluster")      {$Servers = $ManagementCluster;      $ClusterName = "NRAZUREVMHC101"}
    If ($TargetCluster -eq "IBMTenantCluster")       {$Servers = $IBMTenantCluster;       $ClusterName = "NRAZUREVMHC102"}
    If ($TargetCluster -eq "IBMTenantSQLCluster")    {$Servers = $IBMTenantSQLCluster;    $ClusterName = "NRAZUREDBSC102"}
    If ($TargetCluster -eq "CiscoTenantCluster")     {$Servers = $CiscoTenantCluster;     $ClusterName = "NRAZUREVMHC103"}
    If ($TargetCluster -eq "CiscoManagementCluster") {$Servers = $CiscoManagementCluster; $ClusterName = "NRAPCSYSC101"}
    If ($TargetCluster -eq "CiscoTenantSQLCluster")  {$Servers = $CiscoTenantSQLCluster;  $ClusterName = "NRAPCDBSC101.domain1.local"}
#endregion
#region Refresh Cluster
    Switch ($FailoverCluster) {
        $True {
            Write-Color "Refreshing Failover Cluster - ", $ClusterName -Color White, Yellow -EndLine
            RefreshFailoverCluster -ClusterName $ClusterName}
    }
    $ServerCounter = 1
    $ServerCount = $Servers.Count
    Write-Color -Text "Total Servers: ", $ServerCount -Color White, Yellow -Endline
    ForEach ($Server in $Servers) {
        #region Get Host
        Write-Color -Text "$ServerCounter/$ServerCount", " - Getting VM Host ", $Server, " - " -Color Cyan, White, Yellow, White
            $VMHost = Get-SCVMHost -ComputerName $Server
        Write-Host "Refreshing - " -NoNewline
            $Empty = Read-SCVMHost -VMHost $VMHost
        Write-Host "Complete" -ForegroundColor Green
        #endregion
        #region Get VMs
        Write-Color -Text "$ServerCounter/$ServerCount", " - Getting VMs on ", $Server, " - " -Color Cyan, White, Yellow, White
            $VMs = Get-SCVirtualMachine -VMHost $VMHost
            $Count = $VMs.Count
            If ($Count -gt 1) { Write-Host "$Count Found" -ForegroundColor Green }
            Else              { Write-Host "0 Found"      -ForegroundColor Yellow }
        #endregion
        #region Refresh VMs
        $Counter = 1
        If ($Count -gt 1) {
            Write-Color -Text "$ServerCounter/$ServerCount", " - Total VMs on ", $Server, ": ", $Count -Color Cyan, White, Yellow, White, Yellow -EndLine
            ForEach ($VM in $VMs) {
                Try {
                    Write-Color -Text "$ServerCounter/$ServerCount", " - ", "$Counter/$Count", " - Refreshing ", $VM.name, " on ", $Server, " - " -Color Cyan, White, Cyan, White, Yellow, White, Yellow, White
                        #$RefreshVM = Get-SCVirtualMachine -Name $VM 
                        $Empty = Read-SCVirtualMachine -VM $RefreshVM
                    Write-Host "Complete" -ForegroundColor Green
                }
                Catch { Write-Host "Failed" -ForegroundColor Red -NoNewline; Write-Output $_ }
                $Counter ++
            }
            #endregion
        }
        $ServerCounter ++
    }
    Write-Color -Text "1/1", " - Refreshing cluster ", $ClusterName, " - " -Color Cyan, White, Yellow, White
        $Empty = Get-SCVMHostCluster -Name $ClusterName
    Write-Host "Complete" -ForegroundColor Green
#endregion
}
#region Selection
Write-Host "Possible Options: "
Write-Host "1) IBM Management Cluster   - NRAZUREVMHC101"   -ForegroundColor Green  -BackgroundColor Black
Write-Host "2) IBM Tenant Cluster       - NRAZUREVMHC102"       -ForegroundColor Green  -BackgroundColor Black
Write-Host "3) IBM Tenant SQL Cluster   - NRAZUREDBSC102"   -ForegroundColor Green  -BackgroundColor Black
Write-Host "4) Cisco Tenant Cluster     - NRAZUREVMHC103"     -ForegroundColor Yellow -BackgroundColor Black
Write-Host "5) Cisco Management Cluster - NRAPCSYSC101" -ForegroundColor Yellow -BackgroundColor Black
Write-Host "6) Cisco Tenant SQL Cluster - NRAPCDBSC101" -ForegroundColor Yellow -BackgroundColor Black
Write-Host
$Selection = Read-Host "Selection (1 - 6)"
$RefreshFailoverCluster = Read-Host "Refresh Failover Cluster (Y/N)"
    If ($Selection -eq 1) {If ($RefreshFailoverCluster -eq "y") {RefreshSCVMCluster -TargetCluster "ManagementCluster" -FailoverCluster} Else {RefreshSCVMCluster -TargetCluster "ManagementCluster"}}
ElseIf ($Selection -eq 2) {If ($RefreshFailoverCluster -eq "y") {RefreshSCVMCluster -TargetCluster "IBMTenantCluster" -FailoverCluster} Else {RefreshSCVMCluster -TargetCluster "IBMTenantCluster"}}
ElseIf ($Selection -eq 3) {If ($RefreshFailoverCluster -eq "y") {RefreshSCVMCluster -TargetCluster "IBMTenantSQLCluster" -FailoverCluster} Else {RefreshSCVMCluster -TargetCluster "IBMTenantSQLCluster"}}
ElseIf ($Selection -eq 4) {If ($RefreshFailoverCluster -eq "y") {RefreshSCVMCluster -TargetCluster "CiscoTenantCluster" -FailoverCluster} Else {RefreshSCVMCluster -TargetCluster "CiscoTenantCluster"}}
ElseIf ($Selection -eq 5) {If ($RefreshFailoverCluster -eq "y") {RefreshSCVMCluster -TargetCluster "CiscoManagementCluster" -FailoverCluster} Else {RefreshSCVMCluster -TargetCluster "CiscoManagementCluster"}}
ElseIf ($Selection -eq 6) {If ($RefreshFailoverCluster -eq "y") {RefreshSCVMCluster -TargetCluster "CiscoTenantSQLCluster" -FailoverCluster} Else {RefreshSCVMCluster -TargetCluster "CiscoTenantSQLCluster"}}
Else {Write-Host "Invalid Option"}
#endregion