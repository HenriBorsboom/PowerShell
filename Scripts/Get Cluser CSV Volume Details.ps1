Function GetCSVDetails {
    Param([Parameter(Mandatory=$true)] [String] $Cluster)

    $Objs = @()
    $CSVs = Get-ClusterSharedVolume -Cluster $Cluster
    ForEach ($CSV in $CSVs) {
       $CSVInfos = $CSV | Select -Property Name -ExpandProperty SharedVolumeInfo
       ForEach ($CSVInfo in $CSVInfos) {
          $Obj = New-Object PSObject -Property @{
             Name        = $CSV.Name
             Path        = $CSVInfo.FriendlyVolumeName
             Size        = $CSVInfo.Partition.Size
             FreeSpace   = $CSVInfo.Partition.FreeSpace
             UsedSpace   = $CSVInfo.Partition.UsedSpace
             PercentFree = $CSVInfo.Partition.PercentFree
          }
          $Objs += $Obj
       }
    }

    If ($Objs -eq $null) {
        $Results = Get-WmiObject -Query "select caption,freespace from Win32_LogicalDisk" -ComputerName $Cluster
        Return $Results
    }
    Else {
        $ReturnOutput = ($Objs | ft -auto Name,Path,@{ Label = "Size(GB)" ; Expression = { "{0:N2}" -f ($_.Size/1024/1024/1024) } },@{ Label = "FreeSpace(GB)" ; Expression = { "{0:N2}" -f ($_.FreeSpace/1024/1024/1024) } },@{ Label = "UsedSpace(GB)" ; Expression = { "{0:N2}" -f ($_.UsedSpace/1024/1024/1024) } },@{ Label = "PercentFree" ; Expression = { "{0:N2}" -f ($_.PercentFree) } })
        Return $ReturnOutput
    }
   
}
#$ClusterResults = @()
ForEach ($Cluster in (Get-Cluster -Domain "domain2.local")) {
    Write-Host $Cluster
    #$ClusterResults = $ClusterResults + ($Results = GetCSVDetails -Cluster $Cluster)
    $Results = GetCSVDetails -Cluster $Cluster
    $Results | Out-File C:\Temp\clusters\$Cluster.txt -Force -Encoding ascii
    $Results
}

#$ClusterResults