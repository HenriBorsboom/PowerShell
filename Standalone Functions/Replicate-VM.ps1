#Param(
#    [Parameter(Mandatory=$True, Position=1)]
#    [String] $ReplicateVM)

Function Write-Color {
    Param(
        [Parameter(Mandatory=$true, Position=1)]
        [String[]] $Text, `
        [Parameter(Mandatory=$true, Position=2)]
        [ConsoleColor[]] $Color, `
        [Parameter(Mandatory=$false, Position=3)]
        [switch] $EndLine)
    
    If ($Text.Count -ne $Color.Length) {
        Write-Host "The amount of Text variables and the amount of color variables does not match" -ForegroundColor Red
        Write-Host "Text Variables:  " -NoNewline
        Write-Host $Text.Count -ForegroundColor Yellow -NoNewline
        Write-Host " - Color Variables: " -NoNewline
        Write-Host $Color.Length -ForegroundColor Yellow
        Break
    }
    Else {
        For ($TextArrayIndex = 0; $TextArrayIndex -lt $Text.Length; $TextArrayIndex ++) {
            Write-Host $Text[$TextArrayIndex] -Foreground $Color[$TextArrayIndex] -NoNewLine
        }
        Switch ($EndLine) {
            $true  { Write-Host }
            $false { Write-Host -NoNewline}
        }
    }
}
Function Delete-LastLine {
    $x = [Console]::CursorLeft
    $y = [Console]::CursorTop
    [Console]::SetCursorPosition($x,$y - 1)
    Write-Host "                                                                                                                                            "
    [Console]::SetCursorPosition($x,$y - 1)
}
Function Spot-Update {
    Param (
        [Parameter(Mandatory = $True)] 
        [String] $Counter)
    
    #$TimeSpan =  [TimeSpan]::FromSeconds($Counter)
    #$Timer = ("{0:hh\:mm\:ss}" -f $TimeSpan)
    $CursorLeft = [Console]::CursorLeft
    $CursorTop  = [Console]::CursorTop
        
    [Console]::SetCursorPosition($CursorLeft,$CursorTop)
        Write-Host $Counter -ForegroundColor Cyan
    [Console]::SetCursorPosition($CursorLeft,$CursorTop)
}
Function Test-HyperVReplicaBroker {
# get current status 
Get-VMReplication -ComputerName $SourceHyperVReplicaBroker

#get repl server status settings 
Get-VMReplication -ComputerName $TargetHyperVReplicaBrokerHost –ReplicaServerName $TargetHyperVReplicaBroker 

#get ReplicationHealth status 
Get-VMReplication –ReplicationHealth Normal  -ComputerName $SourceHyperVReplicaBrokerHost
Get-VMReplication –ReplicationHealth Normal  -ComputerName $TargetHyperVReplicaBrokerHost
Get-VMReplication –ReplicationHealth Warning -ComputerName $SourceHyperVReplicaBrokerHost
Get-VMReplication –ReplicationHealth Warning -ComputerName $TargetHyperVReplicaBrokerHost

#get repl server 
Get-VMReplicationServer –ComputerName $SourceHyperVReplicaBroker
Get-VMReplicationServer –ComputerName $TargetHyperVReplicaBroker

Get-VMReplication -ComputerName $SourceHyperVReplicaBroker #| Format-List *
Get-VMReplication -ComputerName $TargetHyperVReplicaBroker #| Format-List *


}
Function Replicate-VM {
    Param (
        [Parameter(Mandatory=$true, Position=1)]
        [String] $ReplicateVM)
    
    #region Variables
    #region NRAZUREVMHC101 Cluster Nodes
    Write-Color -Text "Getting ", "NRAZUREVMHC101", " Cluster Nodes - " -Color White, Yellow, White
        [String[]] $SourceHyperVReplicaBrokerHost     = (Get-ClusterNode -Cluster "NRAZUREVMHC101").Name
    Write-Host "Complete" -ForegroundColor Green
    #endregion
    #region NRAPCSYSC101 Cluster Nodes
    Write-Color -Text "Getting ", "NRAPCSYSC101", " Cluster Nodes - " -Color White, Yellow, White
        [String[]] $TargetHyperVReplicaBrokerHost     = (Get-ClusterNode -Cluster "NRAPCSYSC101").Name
    Write-Host "Complete" -ForegroundColor Green
    #endregion
    #region Hyper-V Replica Brokers
    Write-Color -Text "Setting ", "Hyper-V Replica Broker Role", " Names - " -Color White, Yellow, White
        [String]   $SourceHyperVReplicaBroker         = "NRAZUREVMHR101" 
        [String]   $TargetHyperVReplicaBroker         = "NRAZUREVMHR201" 
    Write-Host "Complete" -ForegroundColor Green
    #endregion
    #region NRAZUREVMHR201 Settings
    Write-Color -Text "Getting ", "NRAZUREVMHR201", " Settings - " -Color White, Yellow, White
        [PSObject] $TargetHyperVReplicaBrokerSettings = Get-VMReplicationServer –ComputerName $TargetHyperVReplicaBroker
    Write-Host "Complete" -ForegroundColor Green
    #endregion
    #region Replicating VM Host
    $SourceVMHost = $null
    Write-Color -Text "Getting ", $ReplicateVM, " Host - " -Color White, Yellow, White
        ForEach ($VMHost in $SourceHyperVReplicaBrokerHost) {
            Try { $SourceVMHost = (Get-VM -Name $ReplicateVM -ComputerName $VMHost -ErrorAction Stop).ComputerName } Catch {}
        }
    Write-Host "Complete" -ForegroundColor Green
    If ($SourceVMHost -eq $null) { Write-Host "Empty"; Break}
    #endregion
    #endregion
    
    #region Replication
    #region Enable Replication
    Write-Color -Text "Enabling replication from ", $SourceVMHost, " to ",  $TargetHyperVReplicaBroker, " - " `
                -Color White,                       Yellow,          White, Yellow,                     White
        Enable-VMReplication -ComputerName $SourceVMHost -VMName $ReplicateVM –ReplicaServerName $TargetHyperVReplicaBroker –ReplicaServerPort $TargetHyperVReplicaBrokerSettings.KerbAuthPort -AuthenticationType Kerberos
    Write-Host "Complete" -ForegroundColor Green
    #endregion
    #region Initial Replication
    Write-Color -Text "Starting replication for ", $ReplicateVM, " from ", $SourceVMHost, " - " -Color White, Yellow, White, Yellow, White
        Start-VMInitialReplication –VMName $ReplicateVM -ComputerName $SourceVMHost
    Write-Host "Complete" -ForegroundColor Green
    #endregion
    #endregion
    #region Monitor Replication
    While ((Measure-VMReplication -ComputerName $SourceVMHost -VMName $ReplicateVM).State -ne "Replicating") {
        $ReplicationStatus = "{0:N0}" -f ([Math]::Round((Measure-VMReplication -ComputerName $SourceVMHost -VMName $ReplicateVM).PReplSize/1024/1024).ToString())
        Write-Color -Text "Replicating ", $ReplicateVM, " - ", $ReplicationStatus, " MB Pending" -Color White, Yellow, White, Cyan, White -EndLine
        #Write-Host (([Math]::Round((Measure-VMReplication -ComputerName $SourceVMHost -VMName $ReplicateVM).PReplSize/1024/1024)).ToString() + " MB Pending Replication")
        Sleep 3
        #Delete-LastLine
    }
    Write-Color -Text "Replicating ", $ReplicateVM, " - ", "Complete" -Color White, Yellow, White, Green -EndLine
    #endregion
    #region Target Host
    Write-Color -Text "Getting ", "Replicated VM", " Host - " -Color White, Yellow, White
        ForEach ($VMHost in $TargetHyperVReplicaBrokerHost) {
            Try { $TargetVMHost = (Get-VM -Name $ReplicateVM -ComputerName $VMHost -ErrorAction Stop).ComputerName } Catch {}
        }
    Write-Color -Text "Replicated VM Host - ", $TargetVMHost -Color White, Yellow -EndLine
    #endregion
}
$ErrorActionPreference = "Stop"
Import-Module FailoverClusters

$Servers = @(
    #"VMSERVER112", `
    #"NRAZUREGCS212", `
    ##"NRAZUREGCS102", `
    ##"NRAZUREGCS202", `
    ##"NRAZUREGCS101", `
    ##"VMSERVER201", `
    ##"NRAZUREFLS101", `
    "NRAZUREGCS302")

ForEach ($Server in $Servers) {
    Clear-Host 
    Try { Replicate-VM -ReplicateVM $Server -ErrorAction Stop } Catch { }
}