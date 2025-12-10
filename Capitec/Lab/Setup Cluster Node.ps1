Function Set-VM {
    Param (
        [Parameter(Mandatory=$True)]
        [String] $Name
    )
    $PSUsername = 'Admin1'
    $PSPassword = ConvertTo-SecureString -String 'P@ssw0rd' -AsPlainText -Force
    $Credential = New-Object PSCredential($PSUsername,$PSPassword)
    Add-Computer -DomainName lab.local -ComputerName $env:COMPUTERNAME -newname $Name -Credential $Credential -Restart
}
Function Install-Roles {
    $Roles = @()
    $Roles += ,('FS-FileServer')
    $Roles += ,('Failover-Clustering')
    Install-WindowsFeature FS-FileServer, Failover-Clustering -IncludeManagementTools
}
Function Set-Cluster {
    $ClusterName = 'LABCLUSTER'
    $ClusterNode1 = 'LABNODE012025'
    $ClusterNode2 = 'LABNODE022025'
    New-Cluster -Name $ClusterName -Node $ClusterNode1,$ClusterNode2 -NoStorage
}