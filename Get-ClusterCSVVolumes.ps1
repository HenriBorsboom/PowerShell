Function Test {
    Param (
        [Parameter(Mandatory=$false, Position = 1)]
        [String] $TargetCluster, `
        [Parameter(Mandatory=$false, Position = 2)]
        [Switch] $Domain, `
        [Parameter(Mandatory=$false, Position = 3)]
        [String] $DomainFQDN)
    $ErrorActionPreference = "Stop"
    $ClusterResults = @()
    Switch ($Domain) {
        $true {$Clusters = Get-Cluster -Domain $DomainFQDN; $Clusters = $Clusters.Name}
        $false {$Clusters = $TargetCluster}
    }
    If ($Clusters -eq $null -or $Clusters -eq "") {Throw}
    ForEach ($Cluster in $Clusters) {
        Try {
            Write-Host "Getting " -NoNewline
            Write-Host $Cluster -NoNewline -ForegroundColor Cyan
            Write-Host " CSV Details - " -NoNewline
                $ClusterResults = $ClusterResults + ($Results = GetCSVDetails -Cluster $Cluster)
            Write-Host "Compete" -NoNewline -ForegroundColor Green
    
            $TimeStamp = $([DateTime]::Now.ToString('HH.mm.ss - dd-MM-yyyy'))
            $ExportFile = "C:\Temp\clusters\$Cluster - " + $TimeStamp + ".txt"
            Try {If (!(Get-ChildItem $ExportFile)) {Remove-Item $ExportFile -Force}} Catch {}
            Write-Host " - Export to " -NoNewline
            Write-Host $ExportFile -NoNewline -ForegroundColor Cyan
            Write-Host " - " -NoNewline
                $Results | Export-Csv C:\Temp\clusters\$Cluster.CSV -Append -Delimiter ";" -NoTypeInformation -Force
            Write-Host "Complete" -ForegroundColor Green
            $Results
        }
        Catch {
            Write-Host "Failed" -ForegroundColor Red
            Write-Output $_
        }
    }
}

Function GetCSVDetails {
    Param([Parameter(Mandatory=$true)] [String] $Cluster)

    $Objs = @()
    If ($Cluster -eq "NRAZUREDBSC101") {
        $Cluster = "NRAZUREDBS101"

        $ReturnOutput = @()
        $Results = Get-WmiObject -Query "select caption,freespace,size from Win32_LogicalDisk" -ComputerName $Cluster
        ForEach ($Drive in $Results) {
            $ReturnOutput = $ReturnOutput + ($Cluster + ";" + $Drive.Caption + ";" + [Math]::Round($Drive.FreeSpace/1024/1024/1024) + ";" + [Math]::Round(($Drive.Size/1024/1024/1024)-($Drive.FreeSpace/1024/1024/1024)) + ";" + [Math]::Round(($Drive.FreeSpace/1024/1024/1024)/($Drive.Size/1024/1024/1024)*100))
        }
        $Cluster = "NRAZUREDBS201"

        $Results = Get-WmiObject -Query "select caption,freespace,size from Win32_LogicalDisk" -ComputerName $Cluster
        ForEach ($Drive in $Results) {
            $ReturnOutput = $ReturnOutput + ($Cluster + ";" + $Drive.Caption + ";" + [Math]::Round($Drive.FreeSpace/1024/1024/1024) + ";" + [Math]::Round(($Drive.Size/1024/1024/1024)-($Drive.FreeSpace/1024/1024/1024)) + ";" + [Math]::Round(($Drive.FreeSpace/1024/1024/1024)/($Drive.Size/1024/1024/1024)*100))
        }

        Return $ReturnOutput
    } 
    ElseIf ($Cluster -eq "NRAZUREAPPC101") {
        $Cluster = "APPSERVER101"

        $ReturnOutput = @()
        $Results = Get-WmiObject -Query "select caption,freespace,size from Win32_LogicalDisk" -ComputerName $Cluster
        ForEach ($Drive in $Results) {
            $ReturnOutput = $ReturnOutput + ($Cluster + ";" + $Drive.Caption + ";" + [Math]::Round($Drive.FreeSpace/1024/1024/1024) + ";" + [Math]::Round(($Drive.Size/1024/1024/1024)-($Drive.FreeSpace/1024/1024/1024)) + ";" + [Math]::Round(($Drive.FreeSpace/1024/1024/1024)/($Drive.Size/1024/1024/1024)*100))
        }
        $Cluster = "NRAZUREAPP201"

        $Results = Get-WmiObject -Query "select caption,freespace,size from Win32_LogicalDisk" -ComputerName $Cluster
        ForEach ($Drive in $Results) {
            $ReturnOutput = $ReturnOutput + ($Cluster + ";" + $Drive.Caption + ";" + [Math]::Round($Drive.FreeSpace/1024/1024/1024) + ";" + [Math]::Round(($Drive.Size/1024/1024/1024)-($Drive.FreeSpace/1024/1024/1024)) + ";" + [Math]::Round(($Drive.FreeSpace/1024/1024/1024)/($Drive.Size/1024/1024/1024)*100))
        }

        Return $ReturnOutput
    }
    Else {
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
        $ReturnOutput = ($Objs | ft -auto Name,Path,@{ Label = "Size(GB)" ; Expression = {[Math]::Round($_.Size/1024/1024/1024)} },@{ Label = "FreeSpace(GB)" ; Expression = {[Math]::Round($_.FreeSpace/1024/1024/1024)}},@{ Label = "UsedSpace(GB)" ; Expression = { [Math]::Round($_.UsedSpace/1024/1024/1024)}},@{ Label = "PercentFree" ; Expression = { [Math]::Round($_.PercentFree) } })
        Return $ReturnOutput
    }
}
Test -Domain -DomainFQDN domain2.local