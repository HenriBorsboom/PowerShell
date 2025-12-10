## Define UPN of the Account that has impersonation rights

$AccountWithImpersonationRights = "sccmnetaccess@sysproza.net"

##Define the SMTP Address of the mailbox to impersonate

$MailboxToImpersonate = "syspro.helpdesk@za.syspro.com"

## Load Exchange web services DLL

## Download here if not present: http://go.microsoft.com/fwlink/?LinkId=255472

$dllpath = "C:\Program Files\Microsoft\Exchange\Web Services\2.2\Microsoft.Exchange.WebServices.dll"

Import-Module $dllpath

## Set Exchange Version

$ExchangeVersion = [Microsoft.Exchange.WebServices.Data.ExchangeVersion]::Exchange2013

## Create Exchange Service Object

$service = New-Object Microsoft.Exchange.WebServices.Data.ExchangeService($ExchangeVersion)

#Get valid Credentials using UPN for the ID that is used to impersonate mailbox

$psCred = Get-Credential

$creds = New-Object System.Net.NetworkCredential($psCred.UserName.ToString(),$psCred.GetNetworkCredential().password.ToString())

$service.Credentials = $creds

## Set the URL of the CAS (Client Access Server)
##$service.Url="https://sysjhbmail.sysproza.net/EWS/Exchange.asmx"

$service.AutodiscoverUrl($AccountWithImpersonationRights ,{$true})

##Login to Mailbox with Impersonation

Write-Host 'Using ' $AccountWithImpersonationRights ' to Impersonate ' $MailboxToImpersonate

$service.ImpersonatedUserId = New-Object Microsoft.Exchange.WebServices.Data.ImpersonatedUserId([Microsoft.Exchange.WebServices.Data.ConnectingIdType]::SmtpAddress,$MailboxToImpersonate );

#Connect to the Inbox and display basic statistics

$InboxFolder= new-object Microsoft.Exchange.WebServices.Data.FolderId([Microsoft.Exchange.WebServices.Data.WellKnownFolderName]::Inbox,$MailboxToImpersonate)

$Inbox = [Microsoft.Exchange.WebServices.Data.Folder]::Bind($service,$InboxFolder)

Write-Host 'Total Item count for Inbox:' $Inbox.TotalCount

Write-Host 'Total Items Unread:' $Inbox.UnreadCount 