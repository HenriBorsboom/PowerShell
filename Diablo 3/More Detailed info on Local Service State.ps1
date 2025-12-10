Function Get-ServiceInfo {
    $AllServices     = Get-WmiObject -Class Win32_Service 
    $TotalCount      = $AllServices.Count
    $AutoCount       = ($AllServices | Where-Object { $_.StartMode -eq 'Auto' }).Count
    $ManualCount     = ($AllServices | Where-Object { $_.StartMode -eq 'Manual' }).Count
    $DisabledCount   = ($AllServices | Where-Object { $_.StartMode -eq 'Disabled' }).Count

    $AutoService     = ($AllServices | Where-Object { $_.StartMode -eq 'Auto' }     | Sort DisplayName | Select DisplayName, Name, StartMode, State)
    $ManualService   = ($AllServices | Where-Object { $_.StartMode -eq 'Manual' }   | Sort DisplayName | Select DisplayName, Name, StartMode, State)
    $DisabledService = ($AllServices | Where-Object { $_.StartMode -eq 'Disabled' } | Sort DisplayName | Select DisplayName, Name, StartMode, State)
    $ReturnServiceInfo = New-Object -TypeName PSObject -Property @{
        Services        = $AllServices
        TotalCount      = $TotalCount
        AutoCount       = $AutoCount
        ManualCount     = $ManualCount
        DisabledCount   = $DisabledCount
        AutoService     = $AutoService
        ManualService   = $ManualService
        DisabledService = $DisabledService
    }
    Return $ReturnServiceInfo
}
Function Write-Totals {
    Param ($Services)
    Write-Host
    Write-Host "Total Count:                        " $Services.TotalCount
    Write-Host "Auto Count:                         " $Services.AutoCount
    Write-Host "Manual Count:                       " $Services.ManualCount
    Write-Host "Disabled Count:                     " $Services.DisabledCount
    Write-Host "Total = (Auto + Manual + Disabled): " $Services.TotalCount " = " ($Services.AutoCount + $Services.ManualCount + $Services.DisabledCount)
    Write-Host
}
Function Draw-Menu {
    Param ($Services)

    Write-Totals -Services $Services
    Write-Host "1) Auto Services"
    Write-Host "2) Manual Services"
    Write-Host "3) Disabled Services"
    Write-Host "4) All Services"
    Write-Host
    Write-Host "x) Exit"
    Write-Host
    $Menu = Read-Host "Option"
    Switch ($Menu) {
        "1" { Clear-Host; $Services.AutoService;     Draw-Menu -Services $Services }
        "2" { Clear-Host; $Services.ManualService;   Draw-Menu -Services $Services }
        "3" { Clear-Host; $Services.DisabledService; Draw-Menu -Services $Services }
        "4" { Clear-Host; $Services.Services;        Draw-Menu -Services $Services }
        default {}
    }
}

Clear-Host
$Services = Get-ServiceInfo
Draw-Menu -Services $Services