Function Stamp-VM {
    Param (
        [Parameter(Mandatory=$true, Position=1)]
        [String] $Source, `
        [Parameter(Mandatory=$true, Position=1)]
        [String] $Target)

    $ErrorActionPreference = "Stop"

    Try {
        Write-Host "Connecting to VMM server - " -NoNewline
            $SCVMMSERVER = Get-SCVMMServer -ComputerName vmm01.domain2.local -ForOnBehalfOf
        Write-Host "Complete" -ForegroundColor Green
        Write-Host "Getting VM details of " -NoNewline; Write-Host $Source -ForegroundColor Yellow -NoNewline; Write-Host " - " -NoNewline
            $VMInfo = Get-SCVirtualMachine -Name $Source
        Write-Host "Complete" -ForegroundColor Green
        Write-Host "Stamping VM " -NoNewline; Write-Host $Target -ForegroundColor Yellow -NoNewline; 
        Write-Host " with Owner: " -NoNewline; Write-Host ($VMInfo.Owner) -ForegroundColor Yellow -NoNewline;
        Write-Host " and User Role: " -NoNewline; Write-Host ($VMInfo.SelfServiceUserRole) -ForegroundColor Yellow -NoNewline; Write-Host " - " -NoNewline
            $empty = Set-SCVirtualMachine –VM $Target –UserRole ($VMInfo.SelfServiceUserRole) –Owner ($VMInfo.Owner)
        Write-Host "Complete" -ForegroundColor Green
    }
    Catch {
        Write-Host $_ -ForegroundColor Red
    }
}

Stamp-VM -Source "NoNAT1" -Target "NoNATGW"