Clear-Host
del c:\temp\tenants.csv -ErrorAction SilentlyContinue
del C:\temp\tenantvms\*.* -ErrorAction SilentlyContinue
del C:\Temp\Tenants.htm -ErrorAction SilentlyContinue
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
$HTMLBody = "<H2>Service Information</H2>"
Function SplitString {
    Param ($VMMUserID)
    $Separator = "_"
    $Option = [System.StringSplitOptions]::RemoveEmptyEntries
    $IDSplit = $VMMUserID.Split($Separator,2, $Option)
    $SQLUserID = $IDSplit[0]
    Return $SQLUserID
}
Function QuerySQL {
    Param($Query)
    $dataSource = "NRAZUREDBSQ107\NRAZUREDBSQ107"
    $database = "Microsoft.MgmtSvc.Store"
    $connectionString = "Server=NRAZUREDBSQ107\NRAZUREDBSQ107;Database=Microsoft.MgmtSvc.Store;Integrated Security=True;"
    $connection = New-Object System.Data.SqlClient.SqlConnection
    $connection.ConnectionString = $connectionString
    $connection.Open()
    $command = $connection.CreateCommand()
    Try {
        $command.CommandText = $Query
        $result = $command.ExecuteReader()
        $table = new-object “System.Data.DataTable”
        $table.Load($result)
        Return $table
    }
    Catch { Return $null }
}
Function CountTenantVMs {
    Param (
        [Parameter(Mandatory=$true,Position=1)]
        [Object] $VMs, `
        [Parameter(Mandatory=$true,Position=2)]
        [String] $UserRoleIDGUID)
    
    $TotalVMs = @()
    #$FileName = "C:\Temp\tenantvms\" + $UserRole.Id.Guid + ".txt"
    ForEach ($VM in $VMs) {
        If ($VM.UserRole.ID -eq $UserRole.ID.Guid) {
            $TotalVMs = $TotalVMs + $VM
            #$VM.Name | Out-file $FileName -Encoding ascii -Append -Force -NoClobber
        }
    }
    Return $TotalVMs
}
$VMs = Get-SCVirtualMachine -All
$UserRoles = Get-SCUserRole
$TotalTenants = @()
ForEach ($UserRole in $UserRoles) {
    If ($UserRole.UserRoleProfile -eq "TenantAdmin") {
        
        
        $TotalVMs = CountTenantVMs -VMs $VMs -UserRoleIDGUID $UserRole.ID.Guid
        $VMMUserID = SplitString -VMMUserID $UserRole.Name
        $WAPUserEmail = (QuerySQL -Query "Select ID,Name,Email from mp.Users Where Name LIKE '%$VMMUserID%'").Email
        $WAPUserID = (QuerySQL -Query "Select ID,Name,Email from mp.Users Where Name LIKE '%$VMMUserID%'").ID
        $WAPSubscriptionID = (QuerySQL -Query "Select ID,SubscriptionID,SubScriptionName,UserID From mp.Subscriptions Where UserId = '$WAPUserID'").ID
        $WAPCoAdmins = QuerySQL -Query "Select Username from mp.SubscriptionCoAdmins where SubscriptionId = '$WAPSubscriptionID'"
        $WAPCoAdminsCount = $WAPCoAdmins.Username.Count
        $WAPCoAdminUsers = $WAPCoAdmins.Username
        $Tenants = New-Object psobject -Property @{
            "CloudName" = $UserRole.Cloud.Name;
            "Username" = $UserRole.Name;
            "UserID" = $UserRole.ID.Guid;
            "VMCount" = $TotalVMs.Count;
            "CoAdmin" = $WAPCoAdminUsers -join ';'
            "CoAdminCount" = $WAPCoAdminsCount;
            "OdinEmail" = $WAPUserEmail;
        }
    }
    $TotalTenants = $TotalTenants + $Tenants
    #$Tenants | Export-CSV c:\temp\tenants.csv -Force -NoClobber -NoTypeInformation -Encoding ASCII -Append -Delimiter ";"
}

$HTMLFile = $TotalTenants | ConvertTo-HTML -head $HTMLHeader -Body $HTMLBody
$HTMLFile | Out-File C:\Temp\Tenants.htm
Invoke-Expression C:\Temp\Tenants.htm
#Notepad c:\temp\tenants.csv