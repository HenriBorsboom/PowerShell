Function Stamp-VM {
    Param (
        [Parameter(Mandatory=$true, Position=1)]
        [String] $VMMServer, `
        [Parameter(Mandatory=$true, Position=2)]
        [String] $Source, `
        [Parameter(Mandatory=$true, Position=3)]
        [String] $Target)

    $ErrorActionPreference = "Stop"

    Try {
        Write-Host "Connecting to VMM server - " -NoNewline
            $SCVMMSERVER = Get-SCVMMServer -ComputerName $VMMServer -ForOnBehalfOf
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

$SCVMMSrv = "SYSJHBVMM.sysproza.net"
$SourceVM = "VM-LeatitiaSVR"
$ShaneVMS = Get-SCVirtualMachine | Where Owner -eq "DOMAIN3\Shane"

Stamp-VM -VMMServer $SCVMMSrv -Source $SourceVM -Target $ShaneVMS[2]