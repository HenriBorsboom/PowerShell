Clear-Host
del c:\temp\tenants.csv -ErrorAction SilentlyContinue
del C:\temp\tenantvms\*.* -ErrorAction SilentlyContinue
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
$VMs = Get-SCVirtualMachine -All
$UserRoles = Get-SCUserRole
ForEach ($UserRole in $UserRoles) {
    If ($UserRole.UserRoleProfile -eq "TenantAdmin") {
        $TotalVMs = @()
        $FileName = "C:\Temp\tenantvms\" + $UserRole.Id.Guid + ".txt"
        ForEach ($VM in $VMs) {
            If ($VM.UserRole.ID -eq $UserRole.ID.Guid) {
                $TotalVMs = $TotalVMs + $VM
                $VM.Name | Out-file $FileName -Encoding ascii -Append -Force -NoClobber
            }
        }
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
        $Tenants | Export-CSV c:\temp\tenants.csv -Force -NoClobber -NoTypeInformation -Encoding ASCII -Append -Delimiter ";"
    
}
Notepad c:\temp\tenants.csv