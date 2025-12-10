Clear-Host
$ClusterHosts = @()
$ClusterHosts = ,("$env:COMPUTERNAME")
$ClusterDetails = @()
ForEach ($Node in $ClusterHosts) {
    $VHDDetails = @()
    $CSVPath = ("\\" + $Node + "\C$\ClusterStorage")
    Write-Host "Getting VHDs from $CSVPath"
    $VHDs = Get-ChildItem $CSVPath -Include "*.vhd", "*.vhdx" -Recurse
    ForEach ($VHD in $VHDs) {
        Write-Host ("Getting File Info for " + $VHD.FullName + " - ") -NoNewline
        Try {
            $VHDInfo = Get-VHD $VHD.FullName -ErrorAction Stop
            $VHDDetails += ,(New-Object -TypeName PSObject -Property @{
                Node = $Node
                Path = $VHDInfo.Path
                VHDFormat = $VHDInfo.VHDFormat
                VHDType = $VHDInfo.VHDType
                FileSize = $VHDInfo.FileSize
                Size = $VHDInfo.Size
            })
            Write-Host "Success" -ForegroundColor Green
        }
        Catch {
            $VHDDetails += ,(New-Object -TypeName PSObject -Property @{
                Node = $Node
                Path = $VHD.FullName
                VHDFormat = $null
                VHDType = $null
                FileSize = $VHD.Length
                Size = $null
            })
            Write-Host "Failed" -ForegroundColor Red
        }
    }
    $VHDDetails | Format-Table -AutoSize
    $ThinSize = [Math]::Round(($VHDDetails | Measure-Object -Sum FileSize).Sum / 1024 / 1024 / 1024, 2)
    $ThickSize = [Math]::Round(($VHDDetails | Measure-Object -Sum Size).Sum / 1024 / 1024 / 1024, 2)
    Write-Host "Thin Provisioned Size:  $ThinSize"
    Write-Host "Thick Provisioned Size: $ThickSize"
    $ClusterDetails += ,(New-Object -TypeName PSObject -Property @{
        Node = $Node
        ThinProvisionSize  = $ThinSize
        ThickProvisionSize = $ThickSize
    })
}
$ClusterDetails