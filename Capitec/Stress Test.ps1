Function Start-MemoryStress {
    $mem_stress = @()
    for ($i = 0; $i -lt 10; $i++) {
        $mem_stress += ("a" * 350MB)
    }
}
Function Start-CPUStress {
    $StartDate = Get-Date
    Write-Output "=-=-=-=-=-=-=-=-=-= Stress Machine Started: $StartDate =-=-=-=-=-=-=-=-=-="
    Write-Warning "This script will saturate all available CPUs in the machine"
    Write-Warning "To cancel execution of all jobs, close the PowerShell Host Window (or terminate the remote session)"

    # CPUs in the machine
    $cpus = $env:NUMBER_OF_PROCESSORS

    # Lower the thread priority so it won't overwhelm the system for other tasks
    [System.Threading.Thread]::CurrentThread.Priority = 'Lowest'

    # Perfmon counters for CPU
    $Global:psPerfCPU = New-Object System.Diagnostics.PerformanceCounter("Processor", "% Processor Time", "_Total")
    $psPerfCPU.NextValue() | Out-Null

    Write-Output "=-=-=-=-=-=-=-=-=-= CPUs in box: $cpus =-=-=-=-=-=-=-=-=-="

    # This will stress the CPU
    foreach ($loopnumber in 1..$cpus) {
        Start-Job -ScriptBlock {
            $result = 1
            foreach ($number in 1..0x7FFFFFFF) {
                $result = $result * $number
            }
        }
    }

    Write-Output "Created sub-jobs to consume the CPU"

    # Ask the user if they want to clear out RAM; if so, we will continue
    Read-Host -Prompt "Press any key to stop the JOBS. Press CTRL+C to quit."

    Write-Output "Clearing CPU Jobs"
    Receive-Job *
    Stop-Job *
    Remove-Job *

    $EndDate = Get-Date
    Write-Output "=-=-=-=-=-=-=-=-=-= Stress Machine Complete: $EndDate =-=-=-=-=-=-=-=-=-="
}
#Start-MemoryStress
#Start-CPUStress