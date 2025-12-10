Clear-Host
$WarningPreference = "SilentlyContinue"
$ErrorActionPreference = "Stop"
$Computers = @(
    "PRGPRDRDSBR01.sysprolive.cloud"
    "PRGPRDDCINFRA01.sysprolive.cloud"
    "PRGPRDRDSGW01.sysprolive.cloud"
    "PRGPRDSYSAPP02.sysprolive.cloud"
    "PRGPRDSQLDB01.sysprolive.cloud"
    "PRGPRDDCINFRA02.sysprolive.cloud"
    "PRGPRDSQLDB02.sysprolive.cloud"
    "PRGPRDSYSAPP01.sysprolive.cloud"
    "PRGPRDFPINFRA01.sysprolive.cloud"
    "PRGPRDRDSSH01.sysprolive.cloud"
    "PRGPRDRDSSH02.sysprolive.cloud")

$AgentFiles = Get-Childitem "C:\Program Files\System Center Operations Manager\Gateway\AgentManagement\amd64"
ForEach ($Computer in $Computers) {
    $TempPath = ("\\" + $Computer.ToString() + "\C$\Temp\SCOMAgent")

    If (!(Test-Path -Path $TempPath)) {
        Try {
            Write-Host "Processing " -NoNewline; Write-Host $Computer -ForegroundColor Yellow -NoNewline; Write-Host " - " -NoNewline 
                md $TempPath
                ForEach ($File in $AgentFiles) { Copy-Item -Path $File.Fullname -Destination $TempPath }
                Invoke-Command -Session (New-PSSession -ComputerName $Computer) -ScriptBlock { C:\Windows\System32\msiexec.exe /i C:\Temp\SCOMAgent\MOMAgent.msi /qn USE_SETTINGS_FROM_AD=0 USE_MANUALLY_SPECIFIED_SETTINGS==1 MANAGEMENT_GROUP=SYSPRO-SCOM MANAGEMENT_SERVER_DNS=PRGPRDOMINFRA01.sysprolive.cloud MANAGEMENT_SERVER_AD_NAME=PRGPRDOMINFRA01.sysprolive.cloud SECURE_PORT=5723 ACTIONS_USE_COMPUTER_ACCOUNT=1 AcceptEndUserLicenseAgreement=1}
            Write-Host "Complete" -ForegroundColor Green
        }
        Catch {
            Write-Host "Failed" -ForegroundColor Red
            Write-Host $_
        }
    }
    Else {
        Write-Host ($Computer + " - " + "Failed")
    }
}
