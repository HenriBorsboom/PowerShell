<#
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
#<#
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
Function Make-Fragment {
    Param (
        [Parameter(Mandatory=$True, Position=1)]
        [Object[]] $TableHeaders, `
        [Parameter(Mandatory=$True, Position=2)]
        [Object[]] $TableData, `
        [Parameter(Mandatory=$False, Position=3)]
        [Switch] $UpperCase)

    $FragmentStart =  "<table border = '1'> <colgroup> "
    For ($ColumnCount = 0; $ColumnCount -lt $TableHeaders.Count; $ColumnCount ++) {
        $FragmentStart +=  "<col/>"
    }
    $FragmentStart += "</colgroup>"
          
    $HeadersString = ""
    $TableString = ""
    $FragmentEnd = "</table>"
    
    $HeadersString += "<tr>"
    ForEach($Head in $TableHeaders) {
        $HeadersString += "<th>" + $Head + "</th>"
    }
    $HeadersString += "</tr>"
    Switch ($UpperCase) {
        $True {
            For ($RowCount = 0; $RowCount -lt $TableData.Count; $RowCount ++) {
                $TableString += "<tr>"
                For ($ColumnCount = 0; $ColumnCount -lt $TableHeaders.Count; $ColumnCount ++) {
                    $TableString += "<td>" + $TableData[$RowCount].($TableHeaders[$ColumnCount]).ToUpper() + "</td>"
                }
                $TableString += "</tr>"
            }
        }
        $False {
            For ($RowCount = 0; $RowCount -lt $TableData.Count; $RowCount ++) {
                $TableString += "<tr>"
                For ($ColumnCount = 0; $ColumnCount -lt $TableHeaders.Count; $ColumnCount ++) {
                    $TableString += ("<td>" + $TableData[$RowCount].ToString() + "</td>")
                }
                $TableString += "</tr>"
            }
        }
    }
    $Fragment = $FragmentStart + $HeadersString + $TableString + $FragmentEnd
    Return $Fragment
}
Function Compile-Body {
    Param (
        [Parameter(Mandatory=$True, Position=1)]
        [Object[]] $Fragments, `
        [Parameter(Mandatory=$True, Position=2)]
        [Object[]] $Properties, `
        [Parameter(Mandatory=$True, Position=3)]
        [String] $Title = "", `
        [Parameter(Mandatory=$False, Position=3)]
        [String[]] $Failures)

$Head = @"
<style>

    h1 {

        font-family: Arial, Helvetica, sans-serif;
        color: #e68a00;
        font-size: 28px;

    }

    
    h2 {

        font-family: Arial, Helvetica, sans-serif;
        color: #000099;
        font-size: 16px;

    }


    h3 {

        font-family: Arial, Helvetica, sans-serif;
        color: #203BD6;
        font-size: 12px;

    }
    
    
   table {
		font-size: 12px;
		border: 0px; 
		font-family: Arial, Helvetica, sans-serif;
	} 
	
    td {
		padding: 4px;
		margin: 0px;
		border: 0;
	}
	
    th {
        background: #395870;
        background: linear-gradient(#49708f, #293f50);
        color: #fff;
        font-size: 11px;
        text-transform: uppercase;
        padding: 10px 15px;
        vertical-align: middle;
	}

    tbody tr:nth-child(even) {
        background: #f0f0f2;
    }

        #CreationDate {

        font-family: Arial, Helvetica, sans-serif;
        color: #ff3300;
        font-size: 12px;

    }
    
    .ErrorStatus {
    color: #ff0000;
}


</style>
<title>$Title Report Information</title>
    </head>
<body>
"@


    $Paragraph = "<p></p>"

    $Table1Header = "<h1 align = 'center'>" + $Title + " Report Information</h1>"
    $TableTimeStamp = "<h3 align = 'center'>Date & Time: $ReportDate</h3>"
    $SearchInput = '<input type="text" id="myInput" onkeyup="myFunction()" placeholder="Search for ..." title="Type in a name">'
    $Script = '<script>
function myFunction() {
  var input, filter, table, tr, td, i;
  input = document.getElementById("myInput");
  filter = input.value.toUpperCase();
  table = document.getElementById("myTable");
  var rows = table.getElementsByTagName("tr");
  for (i = 0; i < rows.length; i++) {
    var cells = rows[i].getElementsByTagName("td");
    var j;
    var rowContainsFilter = false;
    for (j = 0; j < cells.length; j++) {
      if (cells[j]) {
        if (cells[j].innerHTML.toUpperCase().indexOf(filter) > -1) {
          rowContainsFilter = true;
          continue;
        }
      }
    }

    if (! rowContainsFilter) {
      rows[i].style.display = "none";
    } else {
      rows[i].style.display = "";
    }
  }
}
</script>'
    $TableDataStart = '<table id="myTable">'
    $TableColGroup = $ColGroupString
    $TableHeaders = $ColHeaderString
    $TableClose = "</table>"

    $FailuresHeader = "<h1 align = 'center' style='background-color:lightblue'> Empty reports</h1>"

    $Foot = "</body></html>"
    If ($Failures.Count -gt 0) {
        $Body = $Head + $Table1Header + $TableTimeStamp + $SearchInput + $Script + $TableDataStart + $TableColGroup + $TableHeaders + $Fragments + $TableClose + $Paragraph + $FailuresHeader + $Failures + $Paragraph + $Foot        
    }
    Else {
        $Body = $Head + $Table1Header + $TableTimeStamp + $SearchInput + $Script + $TableDataStart + $TableColGroup + $TableHeaders + $Fragments + $TableClose + $Paragraph + $Foot        
    }
    
    Return $Body
}
Function Strip-Line {
    Param (
        [Parameter(Mandatory=$True, Position=1)]
        [Object[]] $Line)
    $SplitResults = $Line -split "<td>"
    $JoinString = $SplitResults[0]
    For ($SplitI = 1; $SplitI -lt $SplitResults.Count; $SplitI ++) {
        If ($SplitI -eq 1) {
            If ($SplitResults[$splitI] -like "1</td>") {
                $JoinString += "<td>Server is active</td>"
            }
            ElseIf ($SplitResults[$splitI] -like "2</td>") {
                $JoinString += "<td>Server is suspended</td>"
            }
            ElseIf ($SplitResults[$splitI] -like "3</td>") {
                $JoinString += "<td>Server is scheduled for deletion</td>"
            }
            ElseIf ($SplitResults[$splitI] -like "4</td>") {
                $JoinString += "<td>Server is disabled</td>"
            }
            ElseIf ($SplitResults[$splitI] -like "5</td>") {
                $JoinString += "<td>Server is disconnected for more than 365 days</td>"
            }
            ElseIf ($SplitResults[$splitI] -like "6</td>") {
                $JoinString += "<td>Server is disconnected between 30 and 365 days</td>"
            }
            ElseIf ($SplitResults[$splitI] -like "7</td>") {
                $JoinString += "<td>Server has no backup policies (unprotected)</td>"
            }
            ElseIf ($SplitResults[$splitI] -like "8</td>") {
                $JoinString += "<td>Server is configured as restore only</td>"
            }
            Else {
                $JoinString += ("<td>" + $SplitResults[$splitI])
            }
        }
        ElseIf ($SplitI -eq 2) {
            If ($SplitResults[$splitI] -like "1</td>") {
                $JoinString += "<td>Backup policy is active</td>"
            }
            ElseIf ($SplitResults[$splitI] -like "2</td>") {
                $JoinString += "<td>Backup policy is disabled</td>"
            }
            ElseIf ($SplitResults[$splitI] -like "3</td>") {
                $JoinString += "<td>Backup policy is scheduled for deletion</td>"
            }
            Else {
                $JoinString += ("<td>" + $SplitResults[$splitI])
            }
        }
        ElseIf ($SplitI -eq 3) {
            If ($SplitResults[$splitI] -like "1</td>") {
                $JoinString += "<td>Latest backup in data center is from today or yesterday</td>"
            }
            ElseIf ($SplitResults[$splitI] -like "2</td>") {
                $JoinString += "<td>Backups are configured for onsite (local) keeping only</td>"
            }
            ElseIf ($SplitResults[$splitI] -like "3</td>") {
                $JoinString += "<td>Latest backup in data center is between 2 or 7 days old</td>"
            }
            ElseIf ($SplitResults[$splitI] -like "4</td>") {
                $JoinString += "<td>Latest backup in data center is older than one week</td>"
            }
            ElseIf ($SplitResults[$splitI] -like "5</td>") {
                $JoinString += "<td>No backup data in data center</td>"
            }
            Else {
                $JoinString += ("<td>" + $SplitResults[$splitI])
            }
        }
        ElseIf ($SplitI -eq 11) {
            If ($SplitResults[$splitI] -notlike "0</td>") {
                $JoinString += ('<td class="ErrorStatus">' + $SplitResults[$splitI].ToString())
            }
            Else {
                $JoinString += ("<td>" + $SplitResults[$splitI])
            }
        }
        ElseIf ($SplitI -eq 12) {
            If ($SplitResults[$splitI] -notlike "0</td>") {
                $JoinString += ('<td class="ErrorStatus">' + $SplitResults[$splitI].ToString())
            }
            Else {
                $JoinString += ("<td>" + $SplitResults[$splitI])
            }
        }
        Else {
            $JoinString += ("<td>" + $SplitResults[$splitI])
        }

    }
    Return $JoinString
}
Function Strip-Fragment {
    Param ($Fragment)

    $NewFragment = @()
    $NewFragment += ,($Fragment[0])
    $NewFragment += ,($Fragment[1])
    $NewFragment += ,($Fragment[2])
    For ($i = 3; $i -lt $Fragment.Count; $i ++) {
        $StrippedLine = Strip-Line $Fragment[$i]
        If ($StrippedLine -like '*class="ErrorStatus"*') {
            $NewFragment += ,($StrippedLine.Replace('<td>', '<td class="ErrorStatus">'))
        }
        Else {
            $NewFragment += ,($StrippedLine)
        }
    }

    [String] $Result = $NewFragment.Replace("<table>","")
    [String] $Result = $Result.Replace($ColGroupString,"")
    [String] $Result = $Result.Replace($ColHeaderString,"")
    [String] $Result = $Result.Replace("</table>","")
    Return $Result
}

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
$ColGroupString = "<colgroup>"
For ($ColGroupI = 0; $ColGroupI -lt $ReportProperties.Count; $ColGroupI ++) {
    $ColGroupString += "<col/>"
}
$ColGroupString += "</colgroup>"

$ColHeaderString = "<tr>"
For ($ColHeadI = 0; $ColHeadI -lt $ReportProperties.Count; $ColHeadI ++) {
    $ColHeaderString += ("<th>" + $ReportProperties[$ColHeadI] + "</th>")
}
$ColHeaderString += "</tr>"


$Failures = @()
$Fragments = @()
For ($i = 0; $i -lt $CustomerIDs.Count; $i ++) {
    Write-Color -IndexCounter $i -TotalCounter $CustomerIDs.Count -Text 'Getting LiveVault name - ' -NoNewLine
    $LiveVault = (Get-CustomerByID -ID $CustomerIDs[$i]).Name
    Write-Color -Text 'Generating ', $LiveVault, ' Server Report - ' -ForegroundColor White, Yellow, White -NoNewLine
    $ServerReport = Get-EnhancedServerReportById -ID $CustomerIDs[$i]
    If ($ServerReport -eq $null) {
        $Failures += ,($LiveVault)
        Write-Color 'Report is empty' -ForegroundColor Red
    }
    Else {
        $Fragment = $ServerReport | ConvertTo-Html -Fragment -Property $ReportProperties
        $Fragments += ,(Strip-Fragment -Fragment $Fragment)
        Write-Color -Complete
    }
}

Write-Color -Text 'Compiling report for ', $CustomerName, ' - ' -ForegroundColor White, Yellow, White -NoNewLine
$ReportDate = (Get-Date -Format 'yyyy-MM-dd HH:mm:ss')
$ReportSaveDate = (Get-Date -Format 'yyyy-MM-dd')
$ReplFile    = ("C:\EOH_RT\" + $CustomerName + " - Backup Report - " + $ReportSaveDate + ".html")
    
If ($Fragments.Count -gt 0) {
    If ($Failures.Count -gt 0) {
        $FailureFragments = Make-Fragment -TableHeaders @('Name') -TableData $Failures
        $ReportBody = Compile-Body -Fragments $Fragments -Properties $ReportProperties -Title $CustomerName -Failures $FailureFragments
    }
    Else {
        $ReportBody = Compile-Body -Fragments $Fragments -Properties $ReportProperties -Title $CustomerName
    }

}
Else {
    Write-Color -Text 'Compiling report for ', $CustomerName, ' - ' -ForegroundColor White, Yellow, White -NoNewLine
    $ReportBody = "<style>

        h1 {

            font-family: Arial, Helvetica, sans-serif;
            color: #e68a00;
            font-size: 28px;

        }

    
        h2 {

            font-family: Arial, Helvetica, sans-serif;
            color: #000099;
            font-size: 16px;

        }

        h3 {

            font-family: Arial, Helvetica, sans-serif;
            color: #203BD6;
            font-size: 12px;

        }
    
       table {
		    font-size: 12px;
		    border: 0px; 
		    font-family: Arial, Helvetica, sans-serif;
	    } 
	
        td {
		    padding: 4px;
		    margin: 0px;
		    border: 0;
	    }
	
        th {
            background: #395870;
            background: linear-gradient(#49708f, #293f50);
            color: #fff;
            font-size: 11px;
            text-transform: uppercase;
            padding: 10px 15px;
            vertical-align: middle;
	    }

        tbody tr:nth-child(even) {
            background: #f0f0f2;
        }

            #CreationDate {

            font-family: Arial, Helvetica, sans-serif;
            color: #ff3300;
            font-size: 12px;

        }
    
        .ErrorStatus {
        color: #ff0000;
    }


    </style>
    <title>$CustomerName Report Information</title>
        </head>
    <body><h1 align = 'center'>$CustomerName Report Information</h1>
    <h3 align = 'center'>Date & Time: $ReportDate</h3>
    <h2 align = 'center'>Report Empty</h2>
    </body></html>"
}
$ReportBody | Out-File $ReplFile
Write-Color -Text 'The report has been saved to "', $ReplFile -ForegroundColor White, Green
& $ReplFile
