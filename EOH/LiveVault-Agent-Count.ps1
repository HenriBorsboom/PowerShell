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
$CustomerIDs += ,('749183')
$CustomerIDs += ,('760304')
$CustomerIDs += ,('793523')
$CustomerIDs += ,('873176')
$CustomerIDs += ,('897417')
$CustomerIDs += ,('941674')
$CustomerIDs += ,('951340')
$CustomerIDs += ,('1035261')
$CustomerIDs += ,('1086932')
$CustomerIDs += ,('1094936')
$CustomerIDs += ,('1127279')
$CustomerIDs += ,('1128532')
$CustomerIDs += ,('1182767')
$CustomerIDs += ,('1183404')
$CustomerIDs += ,('1185811')
$CustomerIDs += ,('1188752')
$CustomerIDs += ,('1197050')
$CustomerIDs += ,('1202825')
$CustomerIDs += ,('1318967')

$CustomerName = 'LiveVault '
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

#Details 
Function Get-CustomerAgentsByID {
    Param (
        [Parameter(Mandatory=$True, Position = 1)]
        [String] $ID)
    Try {
        $Return = Invoke-RestMethod ('https://api.livevault.com/api/v1/customers/' + $ID.tostring() + '/agents') -Headers $headers
    }
    Catch {
        $Return = $null
    }
    Return $Return
} # Get list of customer agents
Function Get-CustomerByID {
    Param (
        [Parameter(Mandatory=$True, Position = 1)]
        [String] $ID)
    
    $Return = Invoke-RestMethod ('https://api.livevault.com/api/v1/customers/' + $ID.toString()) -Headers $headers -ErrorAction Stop

    Return $Return
} # Get Customer

# HTML
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
    </style>
<title>$Title Agent Counts</title>
</head>
<body>
"@

    $Paragraph = "<p></p>"

    $Table1Header = "<h1 align = 'center'>" + $Title + " Agent Counts</h1>"
    $TableTimeStamp = "<h3 align = 'center'>Date & Time: $ReportDate</h3>"

    $Foot = "</body></html>"

    $Body = $Head + $Table1Header + $TableTimeStamp + $Fragments + $Foot        

    Return $Body
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
    "Customer",
    "AgentCount")
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
$CustomerAgents = @()
For ($i = 0; $i -lt $CustomerIDs.Count; $i ++) {
    Write-Color -IndexCounter $i -TotalCounter $CustomerIDs.Count -Text 'Getting LiveVault name - ' -NoNewLine
    $LiveVault = (Get-CustomerByID -ID $CustomerIDs[$i]).Name
    Write-Color -Text 'Generating ', $LiveVault, ' Agent count - ' -ForegroundColor White, Yellow, White -NoNewLine
    $ServerReport = Get-CustomerAgentsByID -ID $CustomerIDs[$i]
    If ($ServerReport -eq $null) {
        $CustomerAgents += ,(New-Object -TypeName PSObject -Property @{
            Customer= $LiveVault
            AgentCount= 0
        })
        Write-Color 'Report is empty' -ForegroundColor Red
    }
    Else {
        $CustomerAgents += ,(New-Object -TypeName PSObject -Property @{
            Customer= $LiveVault
            AgentCount= $ServerReport.Hostname.Count
        })
        Write-Color -Complete
    }
}

Write-Color -Text 'Compiling report for ', $CustomerName, ' - ' -ForegroundColor White, Yellow, White -NoNewLine
$ReportDate = (Get-Date -Format 'yyyy-MM-dd HH:mm:ss')
$ReportSaveDate = (Get-Date -Format 'yyyy-MM-dd')
$ReplFile    = ("C:\EOH_RT\" + $CustomerName + " - Agent Count - " + $ReportSaveDate + ".html")
    
$Fragment = $CustomerAgents | Sort-Object Customer | ConvertTo-Html -Fragment -Property $Properties
$ReportBody = Compile-Body -Fragments $Fragment -Properties $ReportProperties -Title $CustomerName

$ReportBody | Out-File $ReplFile
Write-Color -Text 'The report has been saved to "', $ReplFile -ForegroundColor White, Green
& $ReplFile