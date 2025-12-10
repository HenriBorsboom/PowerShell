Param (
    [Parameter(Mandatory=$True, Position=0)]
    [String[]] $Computers)

Function Write-Color {
    Param(
        [Parameter(Mandatory = $True  , Position = 1)]
        [String[]]       $Text, `
        [Parameter(Mandatory = $True  , Position = 2)]
        [ConsoleColor[]] $ForegroundColor, `
        [Parameter(Mandatory = $False , Position = 3)]
        [Switch]           $NoNewLine)

    $ErrorActionPreference = "Stop"
    Try {
        If ($Text.Count -ne $ForegroundColor.Count) {
            Write-Host ("Text Count, " + $Text.Count.ToString() + ", does not match Color Count, " + $ForegroundColor.Count.ToString()) -ForegroundColor Red
            Throw
        }
        For ($Index = 0; $Index -lt $Text.Length; $Index ++) {
            Write-Host $Text[$Index] -Foreground $ForegroundColor[$Index] -NoNewLine
        }
        Switch ($NoNewLine){
            $True  { Write-Host -NoNewline }
            $False { Write-Host }
        }
    }
    Catch { 
        Write-Host "Text Count:  " $Text.Count
        Write-Host "Color Count: " $Color.Count
        Write-Host $_
    }
}
Function MaintenanceMode {
    Param (
        [Parameter(Mandatory=$True, Position=1)]
        [String] $Server, `
        [Parameter(Mandatory=$True, Position=2)][ValidateSet(“Start”,”Stop”)]
        [String] $Action)

    $Instance = Get-SCOMClassInstance -Name $Server
   
    Switch ($Action) {
        "Start" {
            Write-Color -Text "Starting Maintenance mode for ", $Server.ToUpper(), " - " -ForegroundColor White, Yellow, White -NoNewLine
                $Time = ((Get-Date).AddMinutes(30))
                Start-SCOMMaintenanceMode -Instance $Instance -EndTime $Time -Reason PlannedApplicationMaintenance -Comment ("Clearing SCOM Cache. " + $env:USERNAME) -ErrorAction Continue
            Write-Color -Text "Complete" -ForegroundColor Green
        }
        "Stop" {
            Write-Color -Text "Stopping Maintenance mode for ", $Server.ToUpper(), " - " -ForegroundColor White, Yellow, White -NoNewLine
                $MMEntry = Get-SCOMMaintenanceMode -Instance $Instance
                $NewEndTime = (Get-Date).addMinutes(0)
                Set-SCOMMaintenanceMode -MaintenanceModeEntry $MMEntry -EndTime $NewEndTime -Comment ("Clearing SCOM Cache. " + $env:USERNAME)
            Write-Color -Text "Complete" -ForegroundColor Green
        }
    }

    
}
Function Clear-Health {
    Param (
        [Parameter(Mandatory=$True, Position=1)]
        [String] $Server, `
        [Parameter(Mandatory=$True, Position=2)]
        [String] $AgentPath)
    
    Try {
        Write-Color -Text "Processing ", $Server, " - " -ForegroundColor White, Yellow, White -NoNewLine
            Invoke-Command -Session (New-PSSession -ComputerName $Server) -ArgumentList $AgentPath -ScriptBlock {Param($AgentPath); Stop-Service HealthService -Force -Confirm:$false -ErrorAction Stop; Remove-Item $AgentPath -Recurse -Force -ErrorAction Stop; Start-Service HealthService -ErrorAction Stop}
        Write-Color -Text "Complete" -ForegroundColor Green
    }
    Catch {
        Write-Host "Failed" -ForegroundColor Red
        Write-Host $_
    }
}
Clear-Host

$WarningPreference = "SilentlyContinue"
$ErrorActionPreference = "Stop"

$AgentPaths = @(
    "C:\Program Files\System Center Operations Manager\Agent\Health Service State"
    "C:\Program Files\Microsoft Monitoring Agent\Agent\Health Service State")

Write-Color -Text "Importing ", "Operations Manager", " module - " -ForegroundColor White, Yellow, White -NoNewLine
    Import-Module OperationsManager
Write-Color -Text "Complete" -ForegroundColor Green
Write-Color -Text "Connecting to Operations Manager ", "SYSJHBSCOM01", " server - " -ForegroundColor White, Yellow, White -NoNewLine
    New-SCOMManagementGroupConnection -ComputerName SYSJHBSCOM01
Write-Color -Text "Complete" -ForegroundColor Green

ForEach ($Computer in $Computers) {
    Try {
        Write-Color -Text "Getting Agent Details for ", $Computer, " - " -ForegroundColor White, Yellow, White -NoNewLine
            $Server = (Get-SCOMAgent | Where-Object { $_.DisplayName -like "*$Computer*" }).DisplayName
        Write-Color -Text "Complete" -ForegroundColor Green
    
        $AgentPath0 = ("\\" + $Server.ToString() + "\C$\Program Files\System Center Operations Manager\Agent\Health Service State")
        $AgentPath1 = ("\\" + $Server.ToString() + "\C$\Program Files\Microsoft Monitoring Agent\Agent\Health Service State")

        If (Test-Path -Path $AgentPath0)     { MaintenanceMode -Server $Server -Action Start; Clear-Health -Server $Server -AgentPath $AgentPaths[0]; MaintenanceMode -Server $Server -Action Stop }
        ElseIf (Test-Path -Path $AgentPath1) { MaintenanceMode -Server $Server -Action Start; Clear-Health -Server $Server -AgentPath $AgentPaths[1]; MaintenanceMode -Server $Server -Action Stop }
        Else                                 { Write-Color -Text $Server, " - Failed" -ForegroundColor Red, Red }
    }
    Catch {
        Write-Color "Failed - $_" -ForegroundColor Red
    }
}
