Param (
    [Parameter(Mandatory=$true, Position = 1)]
    [String] $SourceToEmpty, `
    [Parameter(Mandatory=$true, Position = 2)]
    [String[]] $DestinationHosts)

Function Delete-LastLine {
    $x = [Console]::CursorLeft
    $y = [Console]::CursorTop
    [Console]::SetCursorPosition($x,$y - 1)
    Write-Host "                                                                                                                                            "
    [Console]::SetCursorPosition($x,$y - 1)
}
Try {
    Write-Host "Getting VMs on " -NoNewline
    Write-Host $SourceToEmpty -ForegroundColor Yellow -NoNewline
    Write-Host " - " -NoNewline
        $VMS = Get-SCVirtualMachine -VMHost $SourceToEmpty
    Write-Host "Complete" -ForegroundColor Green
    
    $VMHosts = $DestinationHosts
    $x = 0
    $Counter = 1
    $VMCount = $VMs.Count
    Write-Host "Total VMS: " -NoNewline
    Write-Host $VMCount -ForegroundColor Green
    
    ForEach ($VM in $VMS) {
        If ($VMHosts.Count -gt 1) {
            If ($x -eq ($VMHosts.Count - 1)) {$x = 0}
        }
        Else {
            Ty {
                $vmHost = Get-SCVMHost -ComputerName $VMHosts[$x] # | where { $_.Name -like $VMHosts[$x] }
                Write-Host "$Counter/$VMCount - " -ForegroundColor Green -NoNewline
                $Empty = Move-SCVirtualMachine -VM $vm -VMHost $vmHost -HighlyAvailable $true -RunAsynchronously -UseDiffDiskOptimization
                Write-Host "Moving " -NoNewline
                Write-Host $VM.Name -NoNewline -ForegroundColor Yellow
                Write-Host " to " -NoNewline
                Write-Host $VMHosts[$x] -NoNewline  -ForegroundColor Yellow
                Write-Host " Started" 
                For ($SleepTime = 1; $SleepTime -lt 31; $SleepTime ++) {
                    Write-host "Sleeping " -NoNewline
                    Write-Host $SleepTime -ForegroundColor Red
                    Sleep (1)
                    Delete-LastLine
                }
                Delete-LastLine
            }
            Catch {
                Write-Host "Failed" -ForegroundColor Red
                Write-Output $_
                Break
            }
            $x ++
        }
    }
}
Catch {
        Write-Host "Failed" -ForegroundColor Red
        Write-Output $_
        Break
}