$VMHosts = Get-ADComputer -Filter {Name -notlike 'NRAZUREVMHC*' -and Name -like 'NRAZUREVMH*'}



Write-Host "Total VM Hosts as per AD: " $VMHosts.count
$x = 1
ForEach ($VMHost in $VMHosts.Name) {
    Try {
        Write-Host "$x - Obtaining VMs on $VMHost - " -NoNewline
            $HostedVMS = Get-VM -ComputerName $VMHost -ErrorAction Stop
        Write-Host "Complete" -ForegroundColor Green
        
        If ($HostedVMS -ne 0) {
            Write-Host "Total VMs on $VMHost"':' $HostedVMS.count
            $y = 1
            ForEach ($VM in $HostedVMS) {
                Try {
                    Write-Host "$x/$y - Enabling Numlock on" $VM.Name "on $VMHost - " -NoNewline
                        $empty = Set-VMBios -VMName $VM.Name -ComputerName $VMHost -EnableNumLock -ErrorAction Stop
                    Write-Host "Complete" -ForegroundColor Green
                }
                Catch {
                    Write-Host "Failed" -ForegroundColor Red
                }
                $y ++
            }
        }
        Else {
            Write-Host "No hosted VMs - Skipping"
        }
    }
    Catch {
        Write-Host "Failed" -ForegroundColor Red
    }
    $x ++
}