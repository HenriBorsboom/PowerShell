Param (
    [Parameter(Mandatory=$false, Position=1)]
    [Switch] $Simple, `
    [Parameter(Mandatory=$false, Position=1)]
    [Switch] $Mail)
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
    
    $TotalVMs = @()
    ForEach ($VM in $VMs) {
        If ($VM.UserRole.ID -eq $UserRole.ID.Guid) { $TotalVMs = $TotalVMs + $VM }
    }
    Return $TotalVMs
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
        [String] $To, `
        [Parameter(Mandatory=$true, Position=2)]
        [String] $From, `
        [Parameter(Mandatory=$true, Position=3)]
        [String] $Subject, `
        [Parameter(Mandatory=$false, Position=4)]
        [String[]] $Report)
        
    $SMTPServer = "10.10.16.146"
    $Message = New-Object System.Net.Mail.MailMessage ($From, $To)
    $Message.Subject = $Subject
    $Message.IsBodyHTML = $true
    $Message.Body = $Report
        
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
        [Switch] $Launch)

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
            $TotalVMs =           Count-TenantVMs -VMs $VMs -UserRoleIDGUID $UserRole.ID.Guid
            $VMMUserID =          Split-String -VMMUserID $UserRole.Name
            $WAPUserEmail =      (Query-SQL -Query "Select ID,Name,Email from mp.Users Where Name LIKE '%$VMMUserID%'").Email
            $WAPUserID =         (Query-SQL -Query "Select ID,Name,Email from mp.Users Where Name LIKE '%$VMMUserID%'").ID
            $WAPSubscriptionID = (Query-SQL -Query "Select ID,SubscriptionID,SubScriptionName,UserID From mp.Subscriptions Where UserId = '$WAPUserID'").ID
            $WAPCoAdmins =        Query-SQL -Query "Select Username from mp.SubscriptionCoAdmins where SubscriptionId = '$WAPSubscriptionID'"
            $WAPCoAdminsCount =   $WAPCoAdmins.Username.Count
            $WAPCoAdminUsers =    $WAPCoAdmins.Username
            $Tenants =            New-Object PSObject -Property @{
                "CloudName"    = $UserRole.Cloud.Name;
                "Username"     = $UserRole.Name;
                "UserID"       = $UserRole.ID.Guid;
                "VMCount"      = $TotalVMs.Count;
                "CoAdmin"      = $WAPCoAdminUsers -join ';'
                "CoAdminCount" = $WAPCoAdminsCount;
                "OdinEmail"    = $WAPUserEmail;
            }
        }
        $TotalTenants = $TotalTenants + $Tenants
    }
    Switch ($Simple) {
        $True  { $TotalTenants = $TotalTenants | Select OdinEmail,CoAdmin,VMCount,CloudName }
        $False { $TotalTenants = $TotalTenants | Select OdinEmail,CoAdminCount,CoAdmin,VMCount,CloudName,Username,UserID }
    }
    $HTMLFile = $TotalTenants | ConvertTo-HTML -head $HTMLHeader -Body $HTMLBody
    $HTMLFile | Out-File C:\Temp\Tenants.htm
    Switch ($Launch) { $True { Invoke-Expression $HTMLFile } }
    Return $HTMLFile
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

Switch ($Simple) {
    $True  {$TenantReport = Generate-TenantReport -Simple -VirtualMachines $VMs -UserRoles $UserRoles}
    $False {$TenantReport = Generate-TenantReport -VirtualMachines $VMs -UserRoles $UserRoles}
}
Switch ($Mail) { $True  { Send-Report -To "user@company.com" -From "reports@domain1.local" -Subject "WAP Tenant Report - $Date" -Report $TenantReport } }