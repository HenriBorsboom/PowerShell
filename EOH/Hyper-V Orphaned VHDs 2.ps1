Clear-Host

$ClusterNode = 'SLBHYPTST201'

Write-Host "Getting Clustername - " -NoNewline
$ClusterName = (Get-WmiObject -Class 'MSCluster_Cluster' -Property 'Name' -Namespace 'root\MSCluster' -ComputerName $ClusterNode).Name
Write-Host ($ClusterName) -ForegroundColor Green
Write-Host "Getting Cluster Nodes - " -NoNewline
$ClusterNodes = (Get-WmiObject -Class 'MSCluster_Node' -Property 'Name' -Namespace 'root\MSCluster' -Computer $ClusterNode).Name
Write-Host ($ClusterNodes.Count.ToString() + ' found') -ForegroundColor Green
$MountedVHDs = @()
$MountedVHDCount = 0
$VMCount = 0
For ($NodeI = 0; $NodeI -lt $ClusterNodes.Count; $NodeI ++) {
    Write-Host (($NodeI + 1).ToString() + '/' + $ClusterNodes.Count.ToString() + ' Getting VM IDs on ' + $ClusterNodes[$NodeI] + ' - ') -NoNewline
    $HostedVMs = (Get-VM -ComputerName $ClusterNodes[$NodeI]).VMID
    $VMCount += $HostedVMs.Count
    Write-Host ($HostedVMs.Count.ToString() + ' VMs found') -ForegroundColor Yellow
    For ($VMi = 0; $VMi -lt $HostedVMs.Count; $VMi ++) {
        Write-Host ("   " + ($VMi + 1).ToString() + '/' + $HostedVMs.Count.ToString() + ' - Getting VHDs on ' + $HostedVMs[$VMi] + ' - ') -NoNewline
        $VMVHDs = Get-VHD -VMId $HostedVMs[$VMi] -ComputerName $ClusterNodes[$NodeI]
        ForEach ($VMVHD in $VMVHDs) {
            $MountedVHDs +=, (New-Object -TypeName PSObject -Property @{
                Path = $VMVHD.Path.ToUpper()
                FileSize = $VMVHD.FileSize
            })
        }
        $MountedVHDCount += $VMVHDs.Count
        Write-Host ($VMVHDs.Count.ToString() + ' found') -ForegroundColor Green
    }
}
Write-Host ("Getting CSVs for " + $ClusterName + ' - ') -NoNewline
$ClusterVolumes = (Get-WmiObject -Class 'MSCluster_ClusterSharedVolume' -Property 'Name' -Namespace 'root\MSCluster' -ComputerName $ClusterNode).Name
Write-Host ($ClusterVolumes.Count.ToString() + ' found') -ForegroundColor Green
$VHDDetails  = @()
$CSVVHDCount = 0
For ($CSVi = 0; $CSVi -lt $ClusterVolumes.Count; $CSVi ++) {
#ForEach ($Volume in $ClusterVolumes) {
    Write-Host (($CSVi + 1).ToString() + '/' + $ClusterVolumes.Count.ToString() + ' Getting VHD files on ' + $ClusterVolumes[$CSVi] + ' - ') -NoNewline
    #Write-Host "   Getting VHD files on CSV"
    $VHDsonCSV = (Invoke-Command -ComputerName $ClusterNode -ArgumentList $ClusterVolumes[$CSVi] -ScriptBlock { Param ($Volume); Get-ChildItem -Path $Volume -Recurse -Include "*vhd*" }) | Select FullName, Length
    ForEach ($VHD in $VHDsonCSV) {
        $VHDDetails += (New-Object -TypeName PSObject -Property @{
            FullName = $VHD.FullName.ToUpper()
            Length = $VHD.Length
        })
    }
    $CSVVHDCount += $VHDsonCSV.Count
    Write-Host ($VHDsonCSV.Count.Tostring() + ' found') -ForegroundColor Green
}
Write-Host ($CSVVHDCount.ToString() + ' found') -ForegroundColor Green


Write-Host ("Comparing Mounted VHDs to VHD Files - ") -NoNewline
$InUse = @()
$Unused = @()
#ForEach ($VHD in $VHDDetails) {
For ($VHDi = 0; $VHDi -lt $VHDDetails.Count; $VHDi ++) {
    Write-Host (($VHDi + 1).ToString() + '/' + $VHDDetails.Count.ToString() + ' Processing ' + $VHDDetails[$VHDi].Fullname)
    If ($MountedVHDs.Path.Contains($VHDDetails[$VHDi].FullName)) {
        $InUse += ,($VHDDetails[$VHDi])
    }
    Else {
        $Unused += ,($VHDDetails[$VHDi])
    }
}
Write-Host "Complete" -ForegroundColor Green

Write-Host "Complete" -ForegroundColor Green
Write-host "--------------------------------------" -ForegroundColor Yellow
Write-host ("Hosted VMs:             " + $VMCount.ToString()) -ForegroundColor Yellow
Write-host ("Mounted VHDs:           " + $MountedVHDs.Count.ToString()) -ForegroundColor Yellow
Write-host ("VHDs on CSVs:           " + $CSVVHDCount.ToString()) -ForegroundColor Yellow
Write-host ("VHDs in Use:            " + $InUse.Count.ToString()) -ForegroundColor Yellow
Write-Host ("VHDs not in use:        " + $Unused.Count.ToString()) -ForegroundColor Yellow
Write-Host ("Potential Wasted Space: " + [Math]::Round(($Unused | Measure-Object -sum Length).Sum / 1024 / 1024 / 1024, 2) + ' GB') -ForegroundColor Red
Write-host "--------------------------------------" -ForegroundColor Yellow
If (Test-Path ($env:temp + '\log.txt')) { Remove-Item ($env:temp + '\log.txt') }
If (Test-Path ($Env:temp + '\vhddetails.csv')) { Remove-Item ($Env:temp + '\vhddetails.csv') }
If (Test-Path ($Env:temp + '\MountedVHDs.csv')) { Remove-Item ($Env:temp + '\MountedVHDs.csv') }

$Unused | Select FullName, Length | Out-File ($env:temp + '\log.txt') -Encoding ascii -Force -NoClobber
$VHDDetails | Export-Csv ($Env:temp + '\vhddetails.csv') -Delimiter ";" -NoClobber -NoTypeInformation -Force
$MountedVHDs | Export-Csv ($Env:temp + '\MountedVHDs.csv') -Delimiter ";" -NoClobber -NoTypeInformation -Force
Write-host ("Output of Unused VHDs saved to: " + ($env:temp + '\log.txt')) -ForegroundColor Red
Write-host ("Output of Mapped VHDs saved to: " + ($env:temp + '\MountedVHDs.csv')) -ForegroundColor Red
Write-host ("Output of CSV VHDs saved to:    " + ($env:temp + '\vhddetails.csv')) -ForegroundColor Red

$Unused | Select FullName, Length | Out-GridView