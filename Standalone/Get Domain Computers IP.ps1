Function Get-DomainComputers {
    Import-Module ActiveDirectory
    $Servers = Get-ADComputer -Filter {Name -notlike "NRAZUREVMHC*" -and Name -notlike "NRAZUREDBSC*" -and Name -notLike "NRAZUREDBSQ*" -and Enabled -eq $true -and Name -like "NRAZURE*"}
    $Servers = $Servers | Sort Name
    $Servers = $Servers | Select -Unique
    Return $Servers    
}
Function GetIP {
    Param (
    [Parameter(Mandatory=$True, Position = 1)]
    [String] $Server)

    $CurrentNetAdapter = Invoke-Command -ComputerName $Server -ScriptBlock {Get-NetAdapter | where {$_.Status -eq "Up"} | Select Name}
    ForEach ($Adapter in $CurrentNetAdapter) {
        $OutputObj  = New-Object -Type PSObject
        Try {
            $ServerAdapterDetails = Invoke-Command -Computername $Server -ArgumentList $Adapter -ScriptBlock {Param($Adapter); Get-NetIPAddress -InterfaceAlias $Adapter.Name  -ErrorAction Stop | select IPv4Address}
            $OutputObj | Add-Member -MemberType NoteProperty -Name Server -Value $ServerAdapterDetails.PSComputerName[0]            $OutputObj | Add-Member -MemberType NoteProperty -Name IPv4 -Value $ServerAdapterDetails.IPv4Address
            $OutputObj
        }
        Catch {
            Write-Host "Failed on $Server" -ForegroundColor Red
            Write-Output $_
        }
    }
}
$Servers = Get-DomainComputers
$List
ForEach ($Server in $Servers.Name) {
    Write-Host $Server
}
$List | Out-File C:\temp\domaincomputers.txt
Notepad C:\temp\domaincomputers.txt