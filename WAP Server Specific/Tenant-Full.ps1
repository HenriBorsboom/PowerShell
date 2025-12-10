Function Split-String {
    Param (
        [Parameter(Mandatory=$True, Position=1)]
        [String] $VMMUserID)
    $Separator = "_"
    $Option = [System.StringSplitOptions]::RemoveEmptyEntries
    $IDSplit = $VMMUserID.Split($Separator,2, $Option)
    $SQLUserID = $IDSplit[0]
    Return $SQLUserID
}
Function Query-SQL {
    Param (
        [Parameter(Mandatory=$True, Position=1)]
        [String] $Query)

    $DataSource = "NRAZUREDBSQ107\NRAZUREDBSQ107"
    $Database = "Microsoft.MgmtSvc.Store"
    $ConnectionString = "Server=NRAZUREDBSQ107\NRAZUREDBSQ107;Database=Microsoft.MgmtSvc.Store;Integrated Security=True;"
    $Connection = New-Object System.Data.SqlClient.SqlConnection
    $Connection.ConnectionString = $ConnectionString
    $Connection.Open()
    $Command = $Connection.CreateCommand()
    Try {
        $Command.CommandText = $Query
        $Result = $Command.ExecuteReader()
        $Table = New-Object “System.Data.DataTable”
        $Table.Load($Result)
        Return $Table
    }
    Catch { Return $null }
}
Function Count-TenantVMs {
    Param (
        [Parameter(Mandatory=$True,Position=1)]
        [Object] $VMs, `
        [Parameter(Mandatory=$True,Position=2)]
        [String] $UserRoleIDGUID)
    
    $TotalVMs    = @()
    $TotalVMCPU  = 0
    $TotalVMRAM  = 0
    $TotalVMDisk = 0

    ForEach ($VM in $VMs) {
        If ($VM.UserRole.ID -eq $UserRole.ID.Guid) { 
            $TotalVMs   = $TotalVMs + $VM
            $TotalVMCPU = $TotalVMCPU + $VM.CPUCount
            $TotalVMRAM = $TotalVMRAM + [Math]::Round($VM.Memory/1024)
            ForEach ($Disk in $VM.VirtualHardDisks) {
                $TotalVMDisk = $TotalVMDisk + [Math]::Round($Disk.Size/1024/1024/1024)
            }
        }
    }
    
    $TenantVMResults = New-Object PSObject
    $TenantVMResults | Add-Member -MemberType NoteProperty -Name "TotalVMs"    -Value $TotalVMs
    $TenantVMResults | Add-Member -MemberType NoteProperty -Name "TotalVMCPU"  -Value $TotalVMCPU
    $TenantVMResults | Add-Member -MemberType NoteProperty -Name "TotalVMRAM"  -Value $TotalVMRAM
    $TenantVMResults | Add-Member -MemberType NoteProperty -Name "TotalVMDisk" -Value $TotalVMDisk
    
    Return $TenantVMResults
}
Function Delete-TempFiles {
    Del c:\temp\tenants.csv   -ErrorAction SilentlyContinue
    Del C:\temp\tenantvms\*.* -ErrorAction SilentlyContinue
    Del C:\Temp\Tenants.htm   -ErrorAction SilentlyContinue
}
Function Get-TimeStampOutputFile {
    Param (
        [Parameter(Mandatory=$true, Position=1)]
        [String] $TargetLocation, `
        [Parameter(Mandatory=$true, Position=2)]
        [String] $Extension, `
        [Parameter(Mandatory=$false, Position=3)]
        [Switch] $VariableName, `
        [Parameter(Mandatory=$false, Position=4)]
        [String] $Name)

    Switch ($VariableName) {
        $True  { $OutputFile = $TargetLocation + "\" + $Name + " - " + $([DateTime]::Now.ToString('dd-MM-yyyy')) + "." + $Extension }
        $False { $OutputFile = $TargetLocation + $([DateTime]::Now.ToString('dd-MM-yyyy')) + $Extension }
    }
    Return $OutputFile
}
Function Send-Report {
    Param (
        [Parameter(Mandatory=$true, Position=1)]
        [String[]] $To, `
        [Parameter(Mandatory=$true, Position=2)]
        [String]   $From, `
        [Parameter(Mandatory=$true, Position=3)]
        [String]   $Subject, `
        [Parameter(Mandatory=$false,Position=4)]
        [String[]] $Body, `
        [Parameter(Mandatory=$false,Position=54)]
        [String[]] $Attachments)
        
    $SMTPServer = "10.10.16.146"
    $Message = New-Object System.Net.Mail.MailMessage # ($From, $To)
    $Message.From = $From
    ForEach ($EmailRecipient in $To) { $Message.To.Add($EmailRecipient) }
    $Message.Subject = $Subject
    $Message.IsBodyHTML = $true
    $Message.Body = $Body
    ForEach ($Attachment in $Attachments) { $Message.Attachments.Add($Attachment) }
        
    $SMTP = New-Object Net.Mail.SmtpClient($smtpServer)
    $SMTP.Send($Message)
}
Function Generate-TenantReport {
    Param (
        [Parameter(Mandatory=$True ,Position=1)]
        [Object[]] $VirtualMachines, `
        [Parameter(Mandatory=$True ,Position=2)]
        [Object[]] $UserRoles, `
        [Parameter(Mandatory=$false,Position=3)]
        [Switch] $Simple, `
        [Parameter(Mandatory=$false,Position=4)]
        [Switch] $Launch, `
        [Parameter(Mandatory=$true, Position=5)]
        [String] $HTMLFile)

    $HTMLHeader="<style>                                               
    BODY{font-family: Arial; font-size: 8pt;}                                              
    H1{font-size: 16px;}                                               
    H2{font-size: 14px;}                                               
    H3{font-size: 12px;}                                               
    TABLE{border: 1px solid black; border-collapse: collapse; font-size: 8pt;}                                         
    TH{border: 1px solid black; background: #dddddd; padding: 5px; color: #000000;}                                           
    TD{border: 1px solid black; padding: 5px; }                                            
    td.pass{background: #7FFF00;}                                             
    td.warn{background: #FFE600;}                                             
    td.fail{background: #FF0000; color: #ffffff;}                                          
    </style>"
    $HTMLBody = "<H2>Windows Azure Pack Tenants</H2>"
    $TotalTenants = @()
    ForEach ($UserRole in $UserRoles) {
        If ($UserRole.UserRoleProfile -eq "TenantAdmin") {
            $Separator = "_"
            $Option = [System.StringSplitOptions]::RemoveEmptyEntries
            $SplitStrings = $UserRole.Name.Split($Separator,2, $Option)
            
            $TotalVMResults    = Count-TenantVMs -VMs $VMs -UserRoleIDGUID $UserRole.ID.Guid
            $VMMUserID         = $SplitStrings[0]
            $WAPUserEmail      = (Query-SQL -Query "Select ID,Name,Email from mp.Users Where Name LIKE '%$VMMUserID%'").Email
            $WAPUserID         = (Query-SQL -Query "Select ID,Name,Email from mp.Users Where Name LIKE '%$VMMUserID%'").ID
            $WAPSubscriptionID = (Query-SQL -Query "Select ID,SubscriptionID,SubScriptionName,UserID From mp.Subscriptions Where UserId = '$WAPUserID'").ID
            $WAPSubscriptionState = (Query-SQL -Query "Select ID,SubscriptionID,SubScriptionName,State,UserID From mp.Subscriptions Where UserId = '$WAPUserID'").State
            If ($WAPSubscriptionState -eq 1) { $WAPSubscriptionState = "Active" } ElseIf ($WAPSubscriptionState -eq 2) { $WAPSubscriptionState = "Suspended" }
            $WAPCoAdmins = @()
            ForEach ($WAPSubscription in $WAPSubscriptionID) { 
                $WAPCoAdmins       += Query-SQL -Query "Select Username from mp.SubscriptionCoAdmins where SubscriptionId = '$WAPSubscription'"
            }
            $WAPCoAdminsCount  = $WAPCoAdmins.Username.Count
            $WAPCoAdminUsers   = $WAPCoAdmins.Username
            $WAPCoAdminUsers   = $WAPCoAdminUsers | Select -Unique
            
            If ($WAPUserEmail -ne $null) { Try { $ADDetails = Get-ADUser -Filter {EmailAddress -like $WAPUserEmail} -Properties * -ErrorAction Stop } Catch { $ADDetails = $null } }
            If ($ADDetails -ne $null) { 
                [String] $OdinSubscriptionID  = $ADDetails.Description
                $OdinSubscriptionID = $OdinSubscriptionID.Remove(0, 26)
                $Company            = $ADDetails.DisplayName
                $Subscriber         = $ADDetails.Name
                $AccountCreated     = $ADDetails.whenCreated
            }
            Else { 
                $OdinSubscriptionID = ""
                $Company            = "" 
                $Subscriber         = "" 
                $AccountCreated     = ""
            }
            
            $Tenants = New-Object PSObject -Property @{
                    "Cloud Name"           = $UserRole.Cloud.Name;
                    "Odin Subscription ID" = $OdinSubscriptionID;
                    "Company"              = $Company -join ";";
                    "Subscriber"           = $Subscriber -join ";";
                    "Subscriber Created"   = $AccountCreated -join ";";
                    "WAP Username"         = $SplitStrings[0];
                    "WAP Subscription"     = $SplitStrings[1];
                    "WAP Subscription Count" = $WAPSubscriptionID.Count;
                    "VM Count"             = $TotalVMResults.TotalVMs.Count;
                    "VM CPU"               = $TotalVMResults.TotalVMCPU;
                    "VM RAM (GB)"          = $TotalVMResults.TotalVMRAM;
                    "VM Disk (GB)"         = $TotalVMResults.TotalVMDisk;
                    "Co Admin"             = $WAPCoAdminUsers -join ';'
                    "Co Admin Count"       = $WAPCoAdminsCount;
                    "Odin Email"           = $WAPUserEmail;
                    "Subscription Active"  = $WAPSubscriptionState;
                } -ErrorAction Stop
            
        }
        $TotalTenants = $TotalTenants + $Tenants
    }
    $TotalTenants = $TotalTenants | Sort "Odin Email" | Select `
        "Cloud Name", `
        "Subscriber", `
        "Subscriber Created", `
        "Odin Email", `
        "Company", `
        "Odin Subscription ID", `
        "Co Admin", `
        "Co Admin Count", `
        "VM Count", `
        "VM CPU", `
        "VM RAM (GB)", `
        "VM Disk (GB)", `
        "WAP Username", `
        "WAP Subscription", `
        "WAP Subscription Count", `
        "Subscription Active"
        
    $HTMLOutputFile = $TotalTenants | ConvertTo-HTML -head $HTMLHeader -Body $HTMLBody
    $HTMLOutputFile | Out-File $HTMLFile
    Return $HTMLOutputFile
}

Clear-Host

$HTMLFile = Get-TimeStampOutputFile -TargetLocation "C:\Temp\TenantReports" -Extension "HTML" -VariableName -Name "Tenants"
$Date = $([DateTime]::Now.ToString('dd-MM-yyyy'))

Write-Host "Retrieving Virtual Machines from Virtual Machine Manager - " -NoNewline
    $VMs = Get-SCVirtualMachine -All
Write-Host "Complete" -ForegroundColor Green
Write-Host "Retrieving User Roles from Virtual Machine Manager - " -NoNewline
    $UserRoles = Get-SCUserRole
Write-Host "Complete" -ForegroundColor Green

$TenantReport = Generate-TenantReport -VirtualMachines $VMs -UserRoles $UserRoles -HTMLFile $HTMLFile
$EmailRecipients = @(
            "henri.borsboom@company.com", `
            "darrel.wright@company.com", `
            "andre.mills@company.com", `
            "jorge.esilva@company.com", `
            "chris.dorn@company.com", `
            "CSBReportsSouthAfrica@company.com")
$EmailAttachments = @($HTMLFile)
& '.\Tenants - 28-10-2015.HTML'
Break
Send-Report -To $EmailRecipients -From "reports@domain1.local" -Subject "WAP Tenant Report - $Date" -Body $TenantReport -Attachments $EmailAttachments
