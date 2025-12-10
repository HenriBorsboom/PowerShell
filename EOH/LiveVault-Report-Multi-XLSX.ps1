#<#
Param (
    [Parameter(Mandatory=$True)]
    [String[]] $CustomerIDs, `
    [Parameter(Mandatory=$True)]
    [String] $CustomerName)
#>
<#
$CustomerIDs = @()
$CustomerIDs += ,('749183')

$CustomerName = 'ERWAT'
#>
<#
$CustomerIDs = @()
$CustomerIDs += ,('702563')
$CustomerIDs += ,('710550')
$CustomerIDs += ,('765688')
$CustomerIDs += ,('809450')
$CustomerIDs += ,('823638')
$CustomerIDs += ,('904708')
$CustomerIDs += ,('942034')
$CustomerIDs += ,('943975')
$CustomerIDs += ,('943980')
$CustomerIDs += ,('947354')
$CustomerIDs += ,('964767')
$CustomerIDs += ,('988717')
$CustomerIDs += ,('1002698')
$CustomerIDs += ,('1012699')
$CustomerIDs += ,('1101920')
$CustomerIDs += ,('1117579')
$CustomerIDs += ,('1151575')
$CustomerIDs += ,('1189054')
$CustomerIDs += ,('1228522')
$CustomerIDs += ,('1238270')
$CustomerIDs += ,('1243684')
$CustomerIDs += ,('1318778')

$CustomerName = 'EOH'
#>

#Authentication
Function Get-Token {
    $user = 'henri.borsboom'
    $passwordSec = ConvertTo-SecureString -String 'YourPasswordHere' -AsPlainText -Force

    $password= [Runtime.InteropServices.Marshal]::PtrToStringAuto([Runtime.InteropServices.Marshal]::SecureStringToBSTR($passwordSec))

    <# Retrieve the  token.  #>
    $auth=Invoke-RestMethod https://api.livevault.com/api/authorize -Method Post -Body "grant_type=password&username=$user&password=$password"

    $headers = New-Object "System.Collections.Generic.Dictionary[[String],[String]]"
    $headers.Add("Authorization", 'Bearer ' + $auth.access_token)
    Return $headers
}

# Reports
Function Get-EnhancedServerReportById {
    Param (
        [Parameter(Mandatory=$True, Position = 1)]
        [String] $ID)
    $Return = Invoke-RestMethod ('https://api.livevault.com/api/v1/reports/enhancedserver/' + $ID) -Headers $headers
    Return $Return
} # Enahnced Server Status Report

#Details 
Function Get-CustomerByID {
    Param (
        [Parameter(Mandatory=$True, Position = 1)]
        [String] $ID)
    $Return = Invoke-RestMethod ('https://api.livevault.com/api/v1/customers/' + $ID) -Headers $headers
    Return $Return
} # Get Customer

# HTML

# ConsoleOutput
Function Write-Color {
    [CmdletBinding(DefaultParameterSetName='Normal')]
    Param(
        [Parameter(Mandatory=$True, Position=1,ParameterSetName='Normal')]
	    [Parameter(Mandatory=$True, Position=1,ParameterSetName='Tab')]
        [String[]] $Text, `
        [Parameter(Mandatory=$False, Position=2,ParameterSetName='Normal')]
	    [Parameter(Mandatory=$False, Position=2,ParameterSetName='Tab')]
        [ConsoleColor[]] $ForegroundColor, `
        [Parameter(Mandatory=$False, Position=3,ParameterSetName='Normal')]
	    [Parameter(Mandatory=$False, Position=3,ParameterSetName='Tab')]
        [ConsoleColor[]] $BackgroundColor, `
        [Parameter(Mandatory=$False, Position=1,ParameterSetName='Complete')]
        [Switch] $Complete, `
	    [Parameter(Mandatory=$False, Position=4,ParameterSetName='Normal')]
	    [Parameter(Mandatory=$False, Position=4,ParameterSetName='Tab')]
	    [Parameter(Mandatory=$False, Position=2,ParameterSetName='Complete')]
        [Switch] $NoNewLine, `
        [Parameter(Mandatory=$False, Position=5,ParameterSetName='Normal')]
	    [Parameter(Mandatory=$False, Position=8,ParameterSetName='Tab')]
	    [Parameter(Mandatory=$False, Position=3,ParameterSetName='Complete')]
        [String] $LogFile = "", `
	    [Parameter(Mandatory=$False, Position=5,ParameterSetName='Tab')]
        [Parameter(Mandatory=$False, Position=4,ParameterSetName='Complete')]
        [Int16] $StartTab = 0, `
        [Parameter(Mandatory=$False, Position=6,ParameterSetName='Tab')]
        [Parameter(Mandatory=$False, Position=5,ParameterSetName='Complete')]
        [Int16] $LinesBefore = 0, `
        [Parameter(Mandatory=$False, Position=7,ParameterSetName='Tab')]
        [Parameter(Mandatory=$False, Position=6,ParameterSetName='Complete')]
        [Int16] $LinesAfter = 0, `
        [Parameter(Mandatory=$False, Position=9,ParameterSetName='Tab')]
        [String] $TimeFormat = "yyyy-MM-dd HH:mm:ss", `
        [Parameter(Mandatory=$False, Position=6,ParameterSetName='Normal')]
        [Parameter(Mandatory=$False, Position=10,ParameterSetName='Tab')]
        [Parameter(Mandatory=$False, Position=1,ParameterSetName='Counter')]
        [Int64] $IndexCounter, `
        [Parameter(Mandatory=$False, Position=7,ParameterSetName='Normal')]
        [Parameter(Mandatory=$False, Position=11,ParameterSetName='Tab')]
        [Parameter(Mandatory=$False, Position=2,ParameterSetName='Counter')]
        [Int64] $TotalCounter)

    Begin {
        $CurrentActionPreference = $ErrorActionPreference;
        $ErrorActionPreference = 'Stop'

        If ($Text.Count -gt 0) {
            If ($BackgroundColor.Count -eq 0 -and $ForegroundColor.Count -eq 0) { $OperationMode = 'WriteHost' }
            ElseIf ($BackgroundColor.Count -gt 0 -and $BackgroundColor.Count -lt $Text.Count -and $ForegroundColor.Count -eq 0) { $OperationMode = 'SingleBackground' }
            ElseIf ($ForegroundColor.Count -gt 0 -and $ForegroundColor.Count -lt $Text.Count -and $BackgroundColor.Count -eq 0) { $OperationMode = 'SingleForeground' }
            ElseIf ($BackgroundColor.Count -gt 0 -and $ForegroundColor.Count -lt $Text.Count -and $ForegroundColor.Count -gt 0 -and $ForegroundColor.Count -lt $Text.Count) { $OperationMode = 'SingleForegroundBackground' }
            ElseIf ($ForegroundColor.Count -gt 0 -and $BackgroundColor.Count -lt $Text.Count -and $BackgroundColor.Count -gt 0 -and $BackgroundColor.Count -lt $Text.Count) { $OperationMode = 'SingleBackgroundForeground' }
            ElseIf ($BackgroundColor.Count -gt 0 -and $BackgroundColor.Count -ge $Text.Count -or $ForegroundColor.Count -eq 0) { $OperationMode = 'Background' }
            ElseIf ($ForegroundColor.Count -gt 0 -and $ForegroundColor.Count -ge $Text.Count -or $BackgroundColor.Count -eq 0) { $OperationMode = 'Foreground' }
            ElseIf ($BackgroundColor.Count -eq $Text.Count -and $ForegroundColor.Count -eq $Text.Count) { $OperationMode = 'Normal' }
            Else { Throw }
        }
        If ($Complete -eq $True) { $OperationMode = 'Complete' }
    }
    Process {
        If ($LinesBefore -ne 0) { For ($i = 0; $i -lt $LinesBefore; $i++) { Write-Host "`n" -NoNewline } }
        If ($StartTab -ne 0) { For ($i = 0; $i -lt $StartTab; $i++) { Write-Host "`t" -NoNewLine } }
        If ($TotalCounter -gt 0 -and $IndexCounter -ge 0) {
            $CounterLength = $TotalCounter.ToString().Length
            Write-Host ("[" + ("{0:D$CounterLength}" -f ($IndexCounter + 1) + "/" + $TotalCounter) + "] ") -ForegroundColor DarkCyan -NoNewline
        }
        If ($OperationMode -eq 'WriteHost') { For ($Index = 0; $Index -lt $Text.Length; $Index ++) { Write-Host $Text[$Index] -NoNewLine } }
        If ($OperationMode -eq 'Foreground') { For ($Index = 0; $Index -lt $Text.Length; $Index ++) { Write-Host $Text[$Index] -ForegroundColor $ForegroundColor[$Index] -NoNewLine } }
        If ($OperationMode -eq 'Background') { For ($Index = 0; $Index -lt $Text.Length; $Index ++) { Write-Host $Text[$Index] -BackgroundColor $BackgroundColor[$Index] -NoNewLine } }
        If ($OperationMode -eq 'SingleBackground') { For ($Index = 0; $Index -lt $Text.Length; $Index ++) { Write-Host $Text[$Index] -BackgroundColor $BackgroundColor[0] -NoNewLine } }
        If ($OperationMode -eq 'SingleForeground') { For ($Index = 0; $Index -lt $Text.Length; $Index ++) { Write-Host $Text[$Index] -ForegroundColor $ForegroundColor[0] -NoNewLine } }
        If ($OperationMode -eq 'SingleForegroundBackground') { For ($Index = 0; $Index -lt $Text.Length; $Index ++) { Write-Host $Text[$Index] -ForegroundColor $ForegroundColor[0] -BackgroundColor $BackgroundColor[$Index] -NoNewLine } }
        If ($OperationMode -eq 'SingleBackgroundForeground') { For ($Index = 0; $Index -lt $Text.Length; $Index ++) { Write-Host $Text[$Index] -ForegroundColor $ForegroundColor[$Index] -BackgroundColor $BackgroundColor[0] -NoNewLine } }
        If ($OperationMode -eq 'Normal') { For ($Index = 0; $Index -lt $Text.Length; $Index ++) { Write-Host $Text[$Index] -ForegroundColor $ForegroundColor[$Index] -BackgroundColor $BackgroundColor[$Index] -NoNewLine } }
        If ($OperationMode -eq 'Complete') { Write-Host 'Complete' -ForegroundColor Green -NoNewLine }
        If ($LinesAfter -ne 0) { For ($i = 0; $i -lt $LinesAfter; $i++) { Write-Host "`n" } }
    }
    End {
        If ($NoNewLine -eq $False) { Write-Host } Else { }
        If ($LogFile -ne "") {
            $TextToFile = ""
            For ($i = 0; $i -lt $Text.Length; $i++) {
                $TextToFile += $Text[$i]
            }
            Write-Output "[$([datetime]::Now.ToString($TimeFormat))] $TextToFile" | Out-File $LogFile -Encoding unicode -Append
        }
        $ErrorActionPreference = $CurrentActionPreference
    }
}
Function Strip-Line {
    Param (
        [Parameter(Mandatory=$True, Position=1)]
        [Object[]] $Line)
    
    $SplitResults = $Line -split ","
    $JoinString = ""
    For ($SplitI = 0; $SplitI -lt $SplitResults.Count; $SplitI ++) {
        If ($SplitI -eq 0) {
            If ($SplitResults[$splitI] -like '"1"') {
                $JoinString += '"Server is active",'
            }
            ElseIf ($SplitResults[$splitI] -like '"2"') {
                $JoinString += '"Server is suspended",'
            }
            ElseIf ($SplitResults[$splitI] -like '"3"') {
                $JoinString += '"Server is scheduled for deletion",'
            }
            ElseIf ($SplitResults[$splitI] -like '"4"') {
                $JoinString += '"Server is disabled",'
            }
            ElseIf ($SplitResults[$splitI] -like '"5"') {
                $JoinString += '"Server is disconnected for more than 365 days",'
            }
            ElseIf ($SplitResults[$splitI] -like '"6"') {
                $JoinString += '"Server is disconnected between 30 and 365 days",'
            }
            ElseIf ($SplitResults[$splitI] -like '"7"') {
                $JoinString += '"Server has no backup policies (unprotected)",'
            }
            ElseIf ($SplitResults[$splitI] -like '"8"') {
                $JoinString += '"Server is configured as restore only",'
            }
            Else {
                $JoinString += ($SplitResults[$splitI] + ',')
            }
        }
        ElseIf ($SplitI -eq 1) {
            If ($SplitResults[$splitI] -like '"1"') {
                $JoinString += '"Backup policy is active",'
            }
            ElseIf ($SplitResults[$splitI] -like '"2"') {
                $JoinString += '"Backup policy is disabled",'
            }
            ElseIf ($SplitResults[$splitI] -like '"3"') {
                $JoinString += '"Backup policy is scheduled for deletion",'
            }
            Else {
                $JoinString += ($SplitResults[$splitI] + ',')
            }
        }
        ElseIf ($SplitI -eq 2) {
            If ($SplitResults[$splitI] -like '"1"') {
                $JoinString += '"Latest backup in data center is from today or yesterday",'
            }
            ElseIf ($SplitResults[$splitI] -like '"2"') {
                $JoinString += '"Backups are configured for onsite (local) keeping only",'
            }
            ElseIf ($SplitResults[$splitI] -like '"3"') {
                $JoinString += '"Latest backup in data center is between 2 or 7 days old",'
            }
            ElseIf ($SplitResults[$splitI] -like '"4"') {
                $JoinString += '"Latest backup in data center is older than one week",'
            }
            ElseIf ($SplitResults[$splitI] -like '"5"') {
                $JoinString += '"No backup data in data center",'
            }
            Else {
                $JoinString += ($SplitResults[$splitI] + ',')
            }
        }
        Else {
            $JoinString += ($SplitResults[$splitI] + ',')
        }

    }
    Return $JoinString
}

Function Strip-Fragment {
    Param (
        [Parameter(Mandatory=$True, Position=1)]
        [Object[]] $Fragment)

    $Return = @()
    For ($i = 1; $i -lt $Fragment.Count; $i ++) {
        $Return += ,(Strip-Line -Line $Fragment[$i])
    }
    Return $Return
}
Function ExportTo-Excel {
    Param (
        [Parameter(Mandatory=$True, Position=1)]
        [String] $InputCSV, `
        [Parameter(Mandatory=$False, Position=2)]
        [String] $FailFile)
    
    ### Set input and output path
    $outputXLSX = $ReplFile.Replace('csv','xlsx')
    
    $excel = New-Object -ComObject excel.application 
    $workbook = $excel.Workbooks.Add(1)
    ### Create a new Excel Workbook with one empty sheet
    
    If ($Failures.Count -gt 0) {
        $extrasheets = $Workbook.Worksheets.add()
    }
    $worksheet = $workbook.worksheets.Item(1)
    $workbook.WorkSheets.item(1).Name = "Status"

    ### Build the QueryTables.Add command
    ### QueryTables does the same as when clicking "Data » From Text" in Excel
    $TxtConnector = ("TEXT;" + $inputCSV)
    $Connector = $worksheet.QueryTables.add($TxtConnector,$worksheet.Range("A1"))
    $query = $worksheet.QueryTables.item($Connector.name)

    ### Set the delimiter (, or ;) according to your regional settings
    $query.TextFileOtherDelimiter = $Excel.Application.International(5)

    ### Set the format to delimited and text for every column
    ### A trick to create an array of 2s is used with the preceding comma
    $query.TextFileParseType  = 1
    $query.TextFileColumnDataTypes = ,2 * $worksheet.Cells.Columns.Count
    $query.AdjustColumnWidth = 1

    ### Execute & delete the import query
    $query.Refresh() | Out-Null
    $query.Delete()

    If ($Failures.Count -gt 0) {
        $worksheet = $workbook.worksheets.Item(2)
        $workbook.WorkSheets.item(2).Name = "Failures"

        ### Build the QueryTables.Add command
        ### QueryTables does the same as when clicking "Data » From Text" in Excel
        $TxtConnector = ("TEXT;" + $FailFile)
        $Connector = $worksheet.QueryTables.add($TxtConnector,$worksheet.Range("A1"))
        $query = $worksheet.QueryTables.item($Connector.name)

        ### Set the delimiter (, or ;) according to your regional settings
        $query.TextFileOtherDelimiter = $Excel.Application.International(5)

        ### Set the format to delimited and text for every column
        ### A trick to create an array of 2s is used with the preceding comma
        $query.TextFileParseType  = 1
        $query.TextFileColumnDataTypes = ,2 * $worksheet.Cells.Columns.Count
        $query.AdjustColumnWidth = 1

        ### Execute & delete the import query
        $query.Refresh() | Out-Null
        $query.Delete()
    }

    ### Save & close the Workbook as XLSX. Change the output extension for Excel 2003
    $Workbook.SaveAs($outputXLSX,51)
    $excel.Quit()
    Return $outputXLSX
}

$Headers = Get-Token
$ReportProperties = @(
    "ServerStatus",
    "BackupPolicyStatus",
    "OffsiteBackupStatus",
    "CustomerName",
    "GroupName",
    "ServerName",
    "BackupPolicyName",
    "LastBackupToAppliance",
    "LastBackupToVault",
    "BackupPolicySize",
    "CurrentBackupPolicyErrors",
    "CurrentBackupPolicyWarnings",
    "ServerDisconnectedSince")

$CSVHeaderString = ""
ForEach ($Property in $ReportProperties) {
    $CSVHeaderString += '"' + $Property + '",'
}

$Failures = @()
$Fragments = @()
$Fragments += ,($CSVHeaderString)
For ($i = 0; $i -lt $CustomerIDs.Count; $i ++) {
    Write-Color -IndexCounter $i -TotalCounter $CustomerIDs.Count -Text 'Getting LiveVault name - ' -NoNewLine
    $LiveVault = (Get-CustomerByID -ID $CustomerIDs[$i]).Name
    Write-Color -Text 'Generating ', $LiveVault, ' Server Report - ' -ForegroundColor White, Yellow, White -NoNewLine
    $ServerReport = Get-EnhancedServerReportById -ID $CustomerIDs[$i]
    If ($ServerReport -eq $null) {
        $Failures += ,(New-Object -TypeName PSObject -Property @{Name = $LiveVault})
        Write-Color 'Report is empty' -ForegroundColor Red
    }
    Else {
        $Fragment = $ServerReport | Select $ReportProperties | ConvertTo-CSV -NoTypeInformation
        $Fragments += ,(Strip-Fragment -Fragment $Fragment)
        Write-Color -Complete
    }
}

Write-Color -Text 'Compiling report for ', $CustomerName, ' - ' -ForegroundColor White, Yellow, White -NoNewLine
$ReportDate = (Get-Date -Format 'yyyy-MM-dd HH:mm:ss')
$ReportSaveDate = (Get-Date -Format 'yyyy-MM-dd')
$ReplFile    = ("C:\EOH_RT\" + $CustomerName + " - Backup Report - " + $ReportSaveDate + ".csv")
$Fragments | Out-File $ReplFile
Write-Color -Text 'The report has been saved to "', $ReplFile, '"' -ForegroundColor White, Green
  
If ($Fragments.Count -gt 0) {
    Write-Color -Text 'Converting report to', ' Excel', ' - ' -ForegroundColor White, Yellow, White -NoNewLine
    If ($Failures.Count -gt 0) {
        $FailFile    = ("C:\EOH_RT\" + $CustomerName + " - Failure Report - " + $ReportSaveDate + ".csv")
        $Failures | ConvertTo-CSV -NoTypeInformation | Out-File $FailFile
        $ExcelFile = ExportTo-Excel -InputCSV $ReplFile -FailFile $FailFile
        Remove-Item $FailFile
    }
    Else {
        $ExcelFile = ExportTo-Excel -InputCSV $ReplFile
        
    }
    Write-Color -Complete
}
Write-Color -Text 'The report has been saved to "', $ExcelFile -ForegroundColor White, Green
Remove-Item $ReplFile
Write-Color -Text 'The CSV has been deleted: "', $ReplFile -ForegroundColor White, Green
#& $ExcelFile