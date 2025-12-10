Function ExportTo-Excel {
        Param (
            [Parameter(Mandatory=$True, Position=1)]
            [String] $ChangeSummary, 
            [Parameter(Mandatory=$True, Position=2)]
            [String] $ChangeRepresentative, 
            [Parameter(Mandatory=$True, Position=3)]
            [String] $TestComments
        )
        
        $ReferenceWorkbook = 'C:\Users\CP364327\OneDrive - Capitec Bank Ltd\CAB\QA_Testing_Info.xlsx'

        $ExcelObject = New-Object -ComObject Excel.Application  
        $ExcelObject.Visible = $false 
        $ExcelObject.DisplayAlerts =$false

        $Date= Get-Date -Format "yyyy/MM/dd"

        If (Test-Path $ReferenceWorkbook) {  
            $ActiveWorkbook = $ExcelObject.WorkBooks.Open($ReferenceWorkbook)  
            $ActiveWorksheet = $ActiveWorkbook.Worksheets.Item(1)  
        }
        $ActiveWorksheet.Cells.Item(6,4)  = $ChangeSummary
        $ActiveWorksheet.Cells.Item(8,4)  = $ChangeRepresentative
        $ActiveWorksheet.Cells.Item(19,2) = $TestComments
        $ActiveWorksheet.Cells.Item(34,3) = $ChangeRepresentative
        $ActiveWorksheet.Cells.Item(35,3) = $Date

        $CABChangeFile = ('C:\Users\CP364327\OneDrive - Capitec Bank Ltd\CAB\' + $ChangeOrder.ToString() + ' QA_Testing_Info.xlsx')
        $ActiveWorkbook.SaveAs($CABChangeFile)
        $ExcelObject.Quit()
        Return $CABChangeFile
}
Function New-CABTemplate {
    Param (
        [Parameter(Mandatory=$True, Position=1)]
        $ChangeOrder,
        [Parameter(Mandatory=$True, Position=2)]
        $ChangeSummary,
        [Parameter(Mandatory=$True, Position=3)]
        $BusinessJustification,
        [Parameter(Mandatory=$True, Position=4)]
        $Downtime,
        [Parameter(Mandatory=$True, Position=5)]
        $Rollback,
        [Parameter(Mandatory=$True, Position=6)]
        $Impact,
        [Parameter(Mandatory=$True, Position=7)]
        $AffectedServers,
        [Parameter(Mandatory=$True, Position=8)]
        $PostImplementationTesting,
        [Parameter(Mandatory=$True, Position=9)]
        $TestingReason
        )

$TestComments = "Positive Testing - N/A No Positive testing can be done for $TestingReason
Negative Testing - N/A No negative testing can be done for $TestingReason
Regression Testing - N/A No Regression testing can be done for $TestingReason
Security Testing - N/A No security testing can be done for $TestingReason
Load Testing - N/A No load testing can be done for $TestingReason
Stress Testing - N/A No stress testing can be done for $TestingReason
Failover Testing - N/A No Failover testing can be done for $TestingReason"

$ListAffectedServers = $AffectedServers -split ';'
$ListPostImplementationTesting = $PostImplementationTesting -split ';'
Write-Host ""
Write-host "-------------------------------------------------" -ForegroundColor Yellow
Write-Host "           Compiled Change Description" -ForegroundColor Yellow
Write-host "-------------------------------------------------" -ForegroundColor Yellow
$ChangeDescription = "Change Description:
$ChangeSummary

Business Justification:
$BusinessJustification

Downtime:
$Downtime

Rollback:
$Rollback

Impact:
$Impact

Affected Servers:
"
ForEach ($ListedServer in $ListAffectedServers) {
    $ChangeDescription += "$ListedServer
"
}

$ChangeDescription += "

Post-implementation testing:
"
ForEach ($ListedPostimplementationTest in $ListPostImplementationTesting) {
    $ChangeDescription += "$ListedPostimplementationTest
"
}

$ChangeDescription += "

$TestComments
"
Return $ChangeDescription, $TestComments
}

Clear-Host

$CABRepresentative = Read-Host "CAB Representative [Henri Borsboom]"
If ($CABRepresentative -eq "") { $CABRepresentative = 'Henri Borsboom' }

$ChangeOrder = Read-Host "Change Order [123]"
If ($ChangeOrder -eq "") { $ChangeOrder = '123' }

$ChangeSummary = Read-Host "Change Summary [123]"
If ($ChangeSummary -eq "") { $ChangeSummary = '123' }

$BusinessJustification = Read-Host "Business Justification [123]"
If ($BusinessJustification -eq "") { $BusinessJustification = '123' }

$Downtime = Read-Host "Downtime [123]"
If ($Downtime -eq "") { $Downtime = '123' }

$Rollback = Read-Host "Rollback [123]"
If ($Rollback -eq "") { $Rollback = '123' }

$Impact = Read-host "Impact [123]"
If ($Impact -eq "") { $Impact = '123' }

$AffectedServers = Read-Host "Affected Servers (Seperate with ';') [123]"
If ($AffectedServers -eq "") { $AffectedServers = '1;2;3' }

$PostImplementationTesting = Read-Host "Post Implementation Testing (Seperate with ';') [123]"
If ($PostImplementationTesting -eq "") { $PostImplementationTesting = '1;2;3' }

$TestingReason = Read-Host "'No testing can be done for ...' [123]"
If ($TestingReason -eq "") { $TestingReason = '123' }


$ChangeDescription = New-CABTemplate `
    -ChangeOrder $ChangeOrder `
    -ChangeSummary $ChangeSummary `
    -BusinessJustification $BusinessJustification `
    -Downtime $Downtime `
    -Rollback $Rollback `
    -Impact $Impact `
    -AffectedServers $AffectedServers `
    -PostImplementationTesting $PostImplementationTesting `
    -TestingReason $TestingReason
$ChangeDescription[0]
$Confirm = Read-Host "Confirm and create QA Document [N]"
If ($Confirm.ToLower() -eq 'y') {
    $CABChangeFile = ExportTo-Excel -ChangeSummary $ChangeSummary -ChangeRepresentative $CABRepresentative -TestComments $ChangeDescription[1]
    Write-Host ("QA document saved to " + $CABChangeFile)
    Set-Clipboard $ChangeDescription
    Write-Host "Change Description copied to clipboard"
}
