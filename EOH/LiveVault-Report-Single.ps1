Param (
    [Parameter(Mandatory=$True)]
    [String] $CustomerID)


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
                    $TableString += "<td>" + $TableData[$RowCount].($TableHeaders[$ColumnCount]) + "</td>"
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
        [Object[]] $Table, `
        [Parameter(Mandatory=$True, Position=2)]
        [Object[]] $Properties, `
        [Parameter(Mandatory=$True, Position=3)]
        [String] $Title = "")

    $Head = "<title>" + $Title + " Report Information</title>
        </head><body>"
    $Paragraph = "<p></p>"

    $Table1Header = "<h1 align = 'center' style='background-color:lightblue'>" + $Title +"</h1>"
    $Table1 = Make-Fragment -TableHeaders $Properties -TableData ($Table | Select $Properties)

    $Foot = "</body></html>"

    $Body = $Head + $Table1Header + $Table1 + $Paragraph + $Foot
    Return $Body
}

$Headers = Get-Token
$ReportProperties = @("CustomerName", "GroupName", "ServerName", "BackupPolicyName", "Schedulename", "CurrentBackupPolicyErrors", "CurrentBackupPolicyWarnings")
$ServerReport = Get-EnhancedServerReportById -ID $CustomerID
$ReportBody = Compile-Body -Table $ServerReport -Properties $ReportProperties -Title $ServerReport.CustomerName[0]
$ReportDate = (Get-Date -Format 'dd-MM-yyyy')
$ReplFile    = ("C:\EOH_RT\" + $ServerReport.CustomerName[0] + " - Backup - " + $ReportDate + ".html")

$ReportBody | Out-File $ReplFile
& $ReplFile