Param (
    [Parameter(Mandatory=$True)]
    [String[]] $CustomerIDs, `
    [Parameter(Mandatory=$True)]
    [String] $CustomerName)


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
        [Object[]] $Fragments, `
        [Parameter(Mandatory=$True, Position=2)]
        [Object[]] $Properties, `
        [Parameter(Mandatory=$True, Position=3)]
        [String] $Title = "")

    $Head = "<title>" + $Title + " Report Information</title>
        </head><body>"
    $Paragraph = "<p></p>"

    $Table1Header = "<h1 align = 'center' style='background-color:lightblue'>" + $Title +"</h1>"
    $TableData = "<table border = '1'> <colgroup><col/><col/><col/><col/><col/><col/><col/></colgroup> "
    $TableColumn = "<table> <colgroup><col/><col/><col/><col/><col/><col/><col/><col/>"
    $TableHeaders = "<tr><th>CustomerName</th><th>GroupName</th><th>ServerName</th><th>BackupPolicyName</th><th>Schedulename</th><th>CurrentBackupPolicyErrors</th><th>CurrentBackupPolicyWarnings</th></tr>"
    $TableClose = "</table>"

    $Foot = "</body></html>"

    $Body = $Head + $Table1Header + $TableData + $Table1Column + $TableHeaders + $Fragments + $TableClose + $Paragraph + $Foot
    Return $Body
}
Function Strip-Fragment {
    Param ($Fragment)

    [String] $Result = $Fragment.Replace("<table>","")
    [String] $Result = $Result.Replace("<colgroup><col/><col/><col/><col/><col/><col/><col/></colgroup>","")
    [String] $Result = $Result.Replace("<tr><th>CustomerName</th><th>GroupName</th><th>ServerName</th><th>BackupPolicyName</th><th>Schedulename</th><th>CurrentBackupPolicyErrors</th><th>CurrentBackupPolicyWarnings</th></tr>","")
    [String] $Result = $Result.Replace("</table>","")
    Return $Result
}
$Headers = Get-Token
$ReportProperties = @("CustomerName", "GroupName", "ServerName", "BackupPolicyName", "Schedulename", "CurrentBackupPolicyErrors", "CurrentBackupPolicyWarnings")
$Fragments = @()
For ($i = 0; $i -lt $CustomerIDs.Count; $i ++) {
    $ServerReport = Get-EnhancedServerReportById -ID $CustomerIDs[$i]
    $Fragment = $ServerReport | ConvertTo-Html -Fragment -Property $ReportProperties
    $Fragments += ,(Strip-Fragment -Fragment $Fragment)
}



$ReportBody = Compile-Body -Fragments $Fragments -Properties $ReportProperties -Title $CustomerName
$ReportDate = (Get-Date -Format 'dd-MM-yyyy')
$ReplFile    = ("C:\EOH_RT\" + $ServerReport.CustomerName[0] + " - Backup - " + $ReportDate + ".html")

$ReportBody | Out-File $ReplFile
& $ReplFile