Function Temp1 {
Function Update-Host {
    Param ([ValidateSet("Start","Stop")]$Action)

    Switch ($Action) {
        "Start" {
            Write-Host "Getting Updates - " -NoNewline
        }
        "Stop"  {
            Write-Host "Complete" -ForegroundColor Green
        }
    }
}
Function Build-Scripts {
$Approvals = @()
$Approvals += ,("Unapproved")
$Approvals += ,("Declined")
$Approvals += ,("Approved")
$Approvals += ,("AnyExceptDeclined")

$Classifications = @()
$Classifications += ,("All")
$Classifications += ,("Critical")
$Classifications += ,("Security")
$Classifications += ,("WSUS")

$Statuses = @()
$Statuses += ,("Needed")
$Statuses += ,("FailedOrNeeded")
$Statuses += ,("InstalledNotApplicableOrNoStatus")
$Statuses += ,("Failed")
$Statuses += ,("InstalledNotApplicable")
$Statuses += ,("NoStatus")
$Statuses += ,("Any")

$Scripts = @()
ForEach ($Approval in $Approvals) {
    ForEach ($Classification in $Classifications) {
        ForEach ($Status in $Statuses) {
            $Scripts += ,('Update-Host -Action Start; $AllUpdates += ,(Get-WsusUpdate -UpdateServer (Get-WsusServer -Name SYSJHBSYSCENTRE -PortNumber 8530) -Approval ' + $Approval + ' -Classification ' + $Classification + ' -Status ' + $Status + '); Update-Host -Action Stop')
        }
    }
}

    Return $Scripts
}
$AllUpdates = @()
$WSUSServer = Get-WsusServer -Name SYSJHBSYSCENTRE -PortNumber 8530
$Scripts = Build-Scripts
For ($i = 0; $i -lt $Scripts.Count; $i ++) {
    Write-Host (($i + 1).ToString() + '/' + $Scripts.Count.ToString() + ' - ') -NoNewline
    Write-Host $Scripts[$i]
    # Invoke-Expression $Scripts[$i]
}
}
Function Temp2 {
Get-WsusUpdate -UpdateServer (Get-WsusServer -Name SYSJHBSYSCENTRE -PortNumber 8530) -Approval Unapproved -Classification All -Status Needed
Get-WsusUpdate -UpdateServer (Get-WsusServer -Name SYSJHBSYSCENTRE -PortNumber 8530) -Approval Unapproved -Classification All -Status FailedOrNeeded
Get-WsusUpdate -UpdateServer (Get-WsusServer -Name SYSJHBSYSCENTRE -PortNumber 8530) -Approval Unapproved -Classification All -Status InstalledNotApplicableOrNoStatus
Get-WsusUpdate -UpdateServer (Get-WsusServer -Name SYSJHBSYSCENTRE -PortNumber 8530) -Approval Unapproved -Classification All -Status Failed
Get-WsusUpdate -UpdateServer (Get-WsusServer -Name SYSJHBSYSCENTRE -PortNumber 8530) -Approval Unapproved -Classification All -Status InstalledNotApplicable
Get-WsusUpdate -UpdateServer (Get-WsusServer -Name SYSJHBSYSCENTRE -PortNumber 8530) -Approval Unapproved -Classification All -Status NoStatus
Get-WsusUpdate -UpdateServer (Get-WsusServer -Name SYSJHBSYSCENTRE -PortNumber 8530) -Approval Unapproved -Classification All -Status Any
Get-WsusUpdate -UpdateServer (Get-WsusServer -Name SYSJHBSYSCENTRE -PortNumber 8530) -Approval Unapproved -Classification Critical -Status Needed
Get-WsusUpdate -UpdateServer (Get-WsusServer -Name SYSJHBSYSCENTRE -PortNumber 8530) -Approval Unapproved -Classification Critical -Status FailedOrNeeded
Get-WsusUpdate -UpdateServer (Get-WsusServer -Name SYSJHBSYSCENTRE -PortNumber 8530) -Approval Unapproved -Classification Critical -Status InstalledNotApplicableOrNoStatus
Get-WsusUpdate -UpdateServer (Get-WsusServer -Name SYSJHBSYSCENTRE -PortNumber 8530) -Approval Unapproved -Classification Critical -Status Failed
Get-WsusUpdate -UpdateServer (Get-WsusServer -Name SYSJHBSYSCENTRE -PortNumber 8530) -Approval Unapproved -Classification Critical -Status InstalledNotApplicable
Get-WsusUpdate -UpdateServer (Get-WsusServer -Name SYSJHBSYSCENTRE -PortNumber 8530) -Approval Unapproved -Classification Critical -Status NoStatus
Get-WsusUpdate -UpdateServer (Get-WsusServer -Name SYSJHBSYSCENTRE -PortNumber 8530) -Approval Unapproved -Classification Critical -Status Any
Get-WsusUpdate -UpdateServer (Get-WsusServer -Name SYSJHBSYSCENTRE -PortNumber 8530) -Approval Unapproved -Classification Security -Status Needed
Get-WsusUpdate -UpdateServer (Get-WsusServer -Name SYSJHBSYSCENTRE -PortNumber 8530) -Approval Unapproved -Classification Security -Status FailedOrNeeded
Get-WsusUpdate -UpdateServer (Get-WsusServer -Name SYSJHBSYSCENTRE -PortNumber 8530) -Approval Unapproved -Classification Security -Status InstalledNotApplicableOrNoStatus
Get-WsusUpdate -UpdateServer (Get-WsusServer -Name SYSJHBSYSCENTRE -PortNumber 8530) -Approval Unapproved -Classification Security -Status Failed
Get-WsusUpdate -UpdateServer (Get-WsusServer -Name SYSJHBSYSCENTRE -PortNumber 8530) -Approval Unapproved -Classification Security -Status InstalledNotApplicable
Get-WsusUpdate -UpdateServer (Get-WsusServer -Name SYSJHBSYSCENTRE -PortNumber 8530) -Approval Unapproved -Classification Security -Status NoStatus
Get-WsusUpdate -UpdateServer (Get-WsusServer -Name SYSJHBSYSCENTRE -PortNumber 8530) -Approval Unapproved -Classification Security -Status Any
Get-WsusUpdate -UpdateServer (Get-WsusServer -Name SYSJHBSYSCENTRE -PortNumber 8530) -Approval Unapproved -Classification WSUS -Status Needed
Get-WsusUpdate -UpdateServer (Get-WsusServer -Name SYSJHBSYSCENTRE -PortNumber 8530) -Approval Unapproved -Classification WSUS -Status FailedOrNeeded
Get-WsusUpdate -UpdateServer (Get-WsusServer -Name SYSJHBSYSCENTRE -PortNumber 8530) -Approval Unapproved -Classification WSUS -Status InstalledNotApplicableOrNoStatus
Get-WsusUpdate -UpdateServer (Get-WsusServer -Name SYSJHBSYSCENTRE -PortNumber 8530) -Approval Unapproved -Classification WSUS -Status Failed
Get-WsusUpdate -UpdateServer (Get-WsusServer -Name SYSJHBSYSCENTRE -PortNumber 8530) -Approval Unapproved -Classification WSUS -Status InstalledNotApplicable
Get-WsusUpdate -UpdateServer (Get-WsusServer -Name SYSJHBSYSCENTRE -PortNumber 8530) -Approval Unapproved -Classification WSUS -Status NoStatus
Get-WsusUpdate -UpdateServer (Get-WsusServer -Name SYSJHBSYSCENTRE -PortNumber 8530) -Approval Unapproved -Classification WSUS -Status Any
Get-WsusUpdate -UpdateServer (Get-WsusServer -Name SYSJHBSYSCENTRE -PortNumber 8530) -Approval Declined -Classification All -Status Needed
Get-WsusUpdate -UpdateServer (Get-WsusServer -Name SYSJHBSYSCENTRE -PortNumber 8530) -Approval Declined -Classification All -Status FailedOrNeeded
Get-WsusUpdate -UpdateServer (Get-WsusServer -Name SYSJHBSYSCENTRE -PortNumber 8530) -Approval Declined -Classification All -Status InstalledNotApplicableOrNoStatus
Get-WsusUpdate -UpdateServer (Get-WsusServer -Name SYSJHBSYSCENTRE -PortNumber 8530) -Approval Declined -Classification All -Status Failed
Get-WsusUpdate -UpdateServer (Get-WsusServer -Name SYSJHBSYSCENTRE -PortNumber 8530) -Approval Declined -Classification All -Status InstalledNotApplicable
Get-WsusUpdate -UpdateServer (Get-WsusServer -Name SYSJHBSYSCENTRE -PortNumber 8530) -Approval Declined -Classification All -Status NoStatus
Get-WsusUpdate -UpdateServer (Get-WsusServer -Name SYSJHBSYSCENTRE -PortNumber 8530) -Approval Declined -Classification All -Status Any
Get-WsusUpdate -UpdateServer (Get-WsusServer -Name SYSJHBSYSCENTRE -PortNumber 8530) -Approval Declined -Classification Critical -Status Needed
Get-WsusUpdate -UpdateServer (Get-WsusServer -Name SYSJHBSYSCENTRE -PortNumber 8530) -Approval Declined -Classification Critical -Status FailedOrNeeded
Get-WsusUpdate -UpdateServer (Get-WsusServer -Name SYSJHBSYSCENTRE -PortNumber 8530) -Approval Declined -Classification Critical -Status InstalledNotApplicableOrNoStatus
Get-WsusUpdate -UpdateServer (Get-WsusServer -Name SYSJHBSYSCENTRE -PortNumber 8530) -Approval Declined -Classification Critical -Status Failed
Get-WsusUpdate -UpdateServer (Get-WsusServer -Name SYSJHBSYSCENTRE -PortNumber 8530) -Approval Declined -Classification Critical -Status InstalledNotApplicable
Get-WsusUpdate -UpdateServer (Get-WsusServer -Name SYSJHBSYSCENTRE -PortNumber 8530) -Approval Declined -Classification Critical -Status NoStatus
Get-WsusUpdate -UpdateServer (Get-WsusServer -Name SYSJHBSYSCENTRE -PortNumber 8530) -Approval Declined -Classification Critical -Status Any
Get-WsusUpdate -UpdateServer (Get-WsusServer -Name SYSJHBSYSCENTRE -PortNumber 8530) -Approval Declined -Classification Security -Status Needed
Get-WsusUpdate -UpdateServer (Get-WsusServer -Name SYSJHBSYSCENTRE -PortNumber 8530) -Approval Declined -Classification Security -Status FailedOrNeeded
Get-WsusUpdate -UpdateServer (Get-WsusServer -Name SYSJHBSYSCENTRE -PortNumber 8530) -Approval Declined -Classification Security -Status InstalledNotApplicableOrNoStatus
Get-WsusUpdate -UpdateServer (Get-WsusServer -Name SYSJHBSYSCENTRE -PortNumber 8530) -Approval Declined -Classification Security -Status Failed
Get-WsusUpdate -UpdateServer (Get-WsusServer -Name SYSJHBSYSCENTRE -PortNumber 8530) -Approval Declined -Classification Security -Status InstalledNotApplicable
Get-WsusUpdate -UpdateServer (Get-WsusServer -Name SYSJHBSYSCENTRE -PortNumber 8530) -Approval Declined -Classification Security -Status NoStatus
Get-WsusUpdate -UpdateServer (Get-WsusServer -Name SYSJHBSYSCENTRE -PortNumber 8530) -Approval Declined -Classification Security -Status Any
Get-WsusUpdate -UpdateServer (Get-WsusServer -Name SYSJHBSYSCENTRE -PortNumber 8530) -Approval Declined -Classification WSUS -Status Needed
Get-WsusUpdate -UpdateServer (Get-WsusServer -Name SYSJHBSYSCENTRE -PortNumber 8530) -Approval Declined -Classification WSUS -Status FailedOrNeeded
Get-WsusUpdate -UpdateServer (Get-WsusServer -Name SYSJHBSYSCENTRE -PortNumber 8530) -Approval Declined -Classification WSUS -Status InstalledNotApplicableOrNoStatus
Get-WsusUpdate -UpdateServer (Get-WsusServer -Name SYSJHBSYSCENTRE -PortNumber 8530) -Approval Declined -Classification WSUS -Status Failed
Get-WsusUpdate -UpdateServer (Get-WsusServer -Name SYSJHBSYSCENTRE -PortNumber 8530) -Approval Declined -Classification WSUS -Status InstalledNotApplicable
Get-WsusUpdate -UpdateServer (Get-WsusServer -Name SYSJHBSYSCENTRE -PortNumber 8530) -Approval Declined -Classification WSUS -Status NoStatus
Get-WsusUpdate -UpdateServer (Get-WsusServer -Name SYSJHBSYSCENTRE -PortNumber 8530) -Approval Declined -Classification WSUS -Status Any
Get-WsusUpdate -UpdateServer (Get-WsusServer -Name SYSJHBSYSCENTRE -PortNumber 8530) -Approval Approved -Classification All -Status Needed
Get-WsusUpdate -UpdateServer (Get-WsusServer -Name SYSJHBSYSCENTRE -PortNumber 8530) -Approval Approved -Classification All -Status FailedOrNeeded
Get-WsusUpdate -UpdateServer (Get-WsusServer -Name SYSJHBSYSCENTRE -PortNumber 8530) -Approval Approved -Classification All -Status InstalledNotApplicableOrNoStatus
Get-WsusUpdate -UpdateServer (Get-WsusServer -Name SYSJHBSYSCENTRE -PortNumber 8530) -Approval Approved -Classification All -Status Failed
Get-WsusUpdate -UpdateServer (Get-WsusServer -Name SYSJHBSYSCENTRE -PortNumber 8530) -Approval Approved -Classification All -Status InstalledNotApplicable
Get-WsusUpdate -UpdateServer (Get-WsusServer -Name SYSJHBSYSCENTRE -PortNumber 8530) -Approval Approved -Classification All -Status NoStatus
Get-WsusUpdate -UpdateServer (Get-WsusServer -Name SYSJHBSYSCENTRE -PortNumber 8530) -Approval Approved -Classification All -Status Any
Get-WsusUpdate -UpdateServer (Get-WsusServer -Name SYSJHBSYSCENTRE -PortNumber 8530) -Approval Approved -Classification Critical -Status Needed
Get-WsusUpdate -UpdateServer (Get-WsusServer -Name SYSJHBSYSCENTRE -PortNumber 8530) -Approval Approved -Classification Critical -Status FailedOrNeeded
Get-WsusUpdate -UpdateServer (Get-WsusServer -Name SYSJHBSYSCENTRE -PortNumber 8530) -Approval Approved -Classification Critical -Status InstalledNotApplicableOrNoStatus
Get-WsusUpdate -UpdateServer (Get-WsusServer -Name SYSJHBSYSCENTRE -PortNumber 8530) -Approval Approved -Classification Critical -Status Failed
Get-WsusUpdate -UpdateServer (Get-WsusServer -Name SYSJHBSYSCENTRE -PortNumber 8530) -Approval Approved -Classification Critical -Status InstalledNotApplicable
Get-WsusUpdate -UpdateServer (Get-WsusServer -Name SYSJHBSYSCENTRE -PortNumber 8530) -Approval Approved -Classification Critical -Status NoStatus
Get-WsusUpdate -UpdateServer (Get-WsusServer -Name SYSJHBSYSCENTRE -PortNumber 8530) -Approval Approved -Classification Critical -Status Any
Get-WsusUpdate -UpdateServer (Get-WsusServer -Name SYSJHBSYSCENTRE -PortNumber 8530) -Approval Approved -Classification Security -Status Needed
Get-WsusUpdate -UpdateServer (Get-WsusServer -Name SYSJHBSYSCENTRE -PortNumber 8530) -Approval Approved -Classification Security -Status FailedOrNeeded
Get-WsusUpdate -UpdateServer (Get-WsusServer -Name SYSJHBSYSCENTRE -PortNumber 8530) -Approval Approved -Classification Security -Status InstalledNotApplicableOrNoStatus
Get-WsusUpdate -UpdateServer (Get-WsusServer -Name SYSJHBSYSCENTRE -PortNumber 8530) -Approval Approved -Classification Security -Status Failed
Get-WsusUpdate -UpdateServer (Get-WsusServer -Name SYSJHBSYSCENTRE -PortNumber 8530) -Approval Approved -Classification Security -Status InstalledNotApplicable
Get-WsusUpdate -UpdateServer (Get-WsusServer -Name SYSJHBSYSCENTRE -PortNumber 8530) -Approval Approved -Classification Security -Status NoStatus
Get-WsusUpdate -UpdateServer (Get-WsusServer -Name SYSJHBSYSCENTRE -PortNumber 8530) -Approval Approved -Classification Security -Status Any
Get-WsusUpdate -UpdateServer (Get-WsusServer -Name SYSJHBSYSCENTRE -PortNumber 8530) -Approval Approved -Classification WSUS -Status Needed
Get-WsusUpdate -UpdateServer (Get-WsusServer -Name SYSJHBSYSCENTRE -PortNumber 8530) -Approval Approved -Classification WSUS -Status FailedOrNeeded
Get-WsusUpdate -UpdateServer (Get-WsusServer -Name SYSJHBSYSCENTRE -PortNumber 8530) -Approval Approved -Classification WSUS -Status InstalledNotApplicableOrNoStatus
Get-WsusUpdate -UpdateServer (Get-WsusServer -Name SYSJHBSYSCENTRE -PortNumber 8530) -Approval Approved -Classification WSUS -Status Failed
Get-WsusUpdate -UpdateServer (Get-WsusServer -Name SYSJHBSYSCENTRE -PortNumber 8530) -Approval Approved -Classification WSUS -Status InstalledNotApplicable
Get-WsusUpdate -UpdateServer (Get-WsusServer -Name SYSJHBSYSCENTRE -PortNumber 8530) -Approval Approved -Classification WSUS -Status NoStatus
Get-WsusUpdate -UpdateServer (Get-WsusServer -Name SYSJHBSYSCENTRE -PortNumber 8530) -Approval Approved -Classification WSUS -Status Any
Get-WsusUpdate -UpdateServer (Get-WsusServer -Name SYSJHBSYSCENTRE -PortNumber 8530) -Approval AnyExceptDeclined -Classification All -Status Needed
Get-WsusUpdate -UpdateServer (Get-WsusServer -Name SYSJHBSYSCENTRE -PortNumber 8530) -Approval AnyExceptDeclined -Classification All -Status FailedOrNeeded
Get-WsusUpdate -UpdateServer (Get-WsusServer -Name SYSJHBSYSCENTRE -PortNumber 8530) -Approval AnyExceptDeclined -Classification All -Status InstalledNotApplicableOrNoStatus
Get-WsusUpdate -UpdateServer (Get-WsusServer -Name SYSJHBSYSCENTRE -PortNumber 8530) -Approval AnyExceptDeclined -Classification All -Status Failed
Get-WsusUpdate -UpdateServer (Get-WsusServer -Name SYSJHBSYSCENTRE -PortNumber 8530) -Approval AnyExceptDeclined -Classification All -Status InstalledNotApplicable
Get-WsusUpdate -UpdateServer (Get-WsusServer -Name SYSJHBSYSCENTRE -PortNumber 8530) -Approval AnyExceptDeclined -Classification All -Status NoStatus
Get-WsusUpdate -UpdateServer (Get-WsusServer -Name SYSJHBSYSCENTRE -PortNumber 8530) -Approval AnyExceptDeclined -Classification All -Status Any
Get-WsusUpdate -UpdateServer (Get-WsusServer -Name SYSJHBSYSCENTRE -PortNumber 8530) -Approval AnyExceptDeclined -Classification Critical -Status Needed
Get-WsusUpdate -UpdateServer (Get-WsusServer -Name SYSJHBSYSCENTRE -PortNumber 8530) -Approval AnyExceptDeclined -Classification Critical -Status FailedOrNeeded
Get-WsusUpdate -UpdateServer (Get-WsusServer -Name SYSJHBSYSCENTRE -PortNumber 8530) -Approval AnyExceptDeclined -Classification Critical -Status InstalledNotApplicableOrNoStatus
Get-WsusUpdate -UpdateServer (Get-WsusServer -Name SYSJHBSYSCENTRE -PortNumber 8530) -Approval AnyExceptDeclined -Classification Critical -Status Failed
Get-WsusUpdate -UpdateServer (Get-WsusServer -Name SYSJHBSYSCENTRE -PortNumber 8530) -Approval AnyExceptDeclined -Classification Critical -Status InstalledNotApplicable
Get-WsusUpdate -UpdateServer (Get-WsusServer -Name SYSJHBSYSCENTRE -PortNumber 8530) -Approval AnyExceptDeclined -Classification Critical -Status NoStatus
Get-WsusUpdate -UpdateServer (Get-WsusServer -Name SYSJHBSYSCENTRE -PortNumber 8530) -Approval AnyExceptDeclined -Classification Critical -Status Any
Get-WsusUpdate -UpdateServer (Get-WsusServer -Name SYSJHBSYSCENTRE -PortNumber 8530) -Approval AnyExceptDeclined -Classification Security -Status Needed
Get-WsusUpdate -UpdateServer (Get-WsusServer -Name SYSJHBSYSCENTRE -PortNumber 8530) -Approval AnyExceptDeclined -Classification Security -Status FailedOrNeeded
Get-WsusUpdate -UpdateServer (Get-WsusServer -Name SYSJHBSYSCENTRE -PortNumber 8530) -Approval AnyExceptDeclined -Classification Security -Status InstalledNotApplicableOrNoStatus
Get-WsusUpdate -UpdateServer (Get-WsusServer -Name SYSJHBSYSCENTRE -PortNumber 8530) -Approval AnyExceptDeclined -Classification Security -Status Failed
Get-WsusUpdate -UpdateServer (Get-WsusServer -Name SYSJHBSYSCENTRE -PortNumber 8530) -Approval AnyExceptDeclined -Classification Security -Status InstalledNotApplicable
Get-WsusUpdate -UpdateServer (Get-WsusServer -Name SYSJHBSYSCENTRE -PortNumber 8530) -Approval AnyExceptDeclined -Classification Security -Status NoStatus
Get-WsusUpdate -UpdateServer (Get-WsusServer -Name SYSJHBSYSCENTRE -PortNumber 8530) -Approval AnyExceptDeclined -Classification Security -Status Any
Get-WsusUpdate -UpdateServer (Get-WsusServer -Name SYSJHBSYSCENTRE -PortNumber 8530) -Approval AnyExceptDeclined -Classification WSUS -Status Needed
Get-WsusUpdate -UpdateServer (Get-WsusServer -Name SYSJHBSYSCENTRE -PortNumber 8530) -Approval AnyExceptDeclined -Classification WSUS -Status FailedOrNeeded
Get-WsusUpdate -UpdateServer (Get-WsusServer -Name SYSJHBSYSCENTRE -PortNumber 8530) -Approval AnyExceptDeclined -Classification WSUS -Status InstalledNotApplicableOrNoStatus
Get-WsusUpdate -UpdateServer (Get-WsusServer -Name SYSJHBSYSCENTRE -PortNumber 8530) -Approval AnyExceptDeclined -Classification WSUS -Status Failed
Get-WsusUpdate -UpdateServer (Get-WsusServer -Name SYSJHBSYSCENTRE -PortNumber 8530) -Approval AnyExceptDeclined -Classification WSUS -Status InstalledNotApplicable
Get-WsusUpdate -UpdateServer (Get-WsusServer -Name SYSJHBSYSCENTRE -PortNumber 8530) -Approval AnyExceptDeclined -Classification WSUS -Status NoStatus
Get-WsusUpdate -UpdateServer (Get-WsusServer -Name SYSJHBSYSCENTRE -PortNumber 8530) -Approval AnyExceptDeclined -Classification WSUS -Status Any
}
Function Temp3 {
$Approvals = @()
$Approvals += ,("Unapproved")
$Approvals += ,("Declined")
$Approvals += ,("Approved")
$Approvals += ,("AnyExceptDeclined")

$Classifications = @()
$Classifications += ,("All")
$Classifications += ,("Critical")
$Classifications += ,("Security")
$Classifications += ,("WSUS")

$Statuses = @()
$Statuses += ,("Needed")
$Statuses += ,("FailedOrNeeded")
$Statuses += ,("InstalledNotApplicableOrNoStatus")
$Statuses += ,("Failed")
$Statuses += ,("InstalledNotApplicable")
$Statuses += ,("NoStatus")
$Statuses += ,("Any")

$Scripts = @()
ForEach ($Approval in $Approvals) {
    ForEach ($Classification in $Classifications) {
        ForEach ($Status in $Statuses) {
            $Scripts += ,('Update-Host -Action Start; $AllUpdates += ,(Get-WsusUpdate -UpdateServer (Get-WsusServer -Name SYSJHBSYSCENTRE -PortNumber 8530) -Approval ' + $Approval + ' -Classification ' + $Classification + ' -Status ' + $Status + '); Update-Host -Action Stop')
        }
    }
}

$Scripts
}