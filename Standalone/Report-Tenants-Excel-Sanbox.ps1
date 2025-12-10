#region Global Variables
$EmailRecipients = @(
    "henri.borsboom@company.com", `
    "darrel.wright@company.com", `
    "andrew.allner@company.com", `
    "jorge.esilva@company.com", `
    "chris.dorn@company.com", `
    "CSBReportsSouthAfrica@company.com", `
    "Christian.Hagner@company.com")
#endregion
#region Primary Functions
Function Collect-SCVMMData {
    Write-Host "Collecting SCVMM Data - " -NoNewline
        $VMs = Get-SCVirtualMachine -All
        $UserRoles = Get-SCUserRole
    Write-Host "Complete" -ForegroundColor Green

    Return (Filter-SCVMMData -VirtualMachines $VMs -UserRoles $UserRoles)
}                   # Revise
Function Filter-SCVMMData {
    Param (
        [Parameter(Mandatory=$True ,Position=1)]
        [Object[]] $VirtualMachines, `
        [Parameter(Mandatory=$True ,Position=2)]
        [Object[]] $UserRoles)

    Write-Host "Filtering SCVMM Data - " -NoNewline
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
            $WAPCoAdmins       = Query-SQL -Query "Select Username from mp.SubscriptionCoAdmins where SubscriptionId = '$WAPSubscriptionID'"
            $WAPCoAdminsCount  = $WAPCoAdmins.Username.Count
            $WAPCoAdminUsers   = $WAPCoAdmins.Username
            
            If ($WAPUserEmail.ToString().Length -ne 0 ) { $ADDetails = Get-ADUser -Filter { EmailAddress -like $WAPUserEmail } -Properties * -ErrorAction Stop }
            If ($ADDetails -ne $null) { 
                [String] $OdinSubscriptionID  = $ADDetails.Description
                [String] $OdinSubscriptionID = $OdinSubscriptionID.Remove(0, 26)
                [String] $Company            = $ADDetails.DisplayName
                [String] $Subscriber         = $ADDetails.Name
            }
            Else { 
                [String] $OdinSubscriptionID = ""
                [String] $Company            = "" 
                [String] $Subscriber         = "" 
            }
            
            $Tenants = New-Object PSObject -Property @{
                    "CloudName"          = $UserRole.Cloud.Name;
                    "OdinSubscriptionID" = $OdinSubscriptionID;
                    "Company"            = $Company -join ";";
                    "Subscriber"         = $Subscriber -join ";";
                    "WAPUsername"        = $SplitStrings[0];
                    "WAPSubscription"    = $SplitStrings[1];
                    "VMCount"            = $TotalVMResults.TotalVMs.Count;
                    "VMCPU"              = $TotalVMResults.TotalVMCPU;
                    "VMRAM"              = $TotalVMResults.TotalVMRAM;
                    "VMDisk"             = $TotalVMResults.TotalVMDisk;
                    "CoAdmin"            = $WAPCoAdminUsers -join ';'
                    "CoAdminCount"       = $WAPCoAdminsCount;
                    "OdinEmail"          = $WAPUserEmail;
                } -ErrorAction Stop
        }
        $TotalTenants = $TotalTenants + $Tenants
    }
    Write-Host "Complete" -ForegroundColor Green
    Return $TotalTenants
}   # Should be replaced with Export-Excel
Function Export-Excel {
    Param (
        [Parameter (Mandatory=$true, Position=1)]
        [Object[]] $Tenants)

    Write-Host "Generating Excel Spreadsheet - " -NoNewline
    $ExcelTemplate             = "C:\Temp\TenantReports\Reference Folder\Template.xlsx"
    $ExcelFile                 = 'C:\Temp\TenantReports\Tenants - ' + $([DateTime]::Now.ToString('dd-MM-yyyy')) + '.xlsx'
    $ExcelObject               = New-Object -ComObject Excel.Application  
    $ExcelObject.Visible       = $false 
    $ExcelObject.DisplayAlerts = $true
    $Date                      = Get-Date -Format "dd-MM-yyyy"
    
    If (Test-Path $ExcelTemplate) {  
        #Open the document  
        $ActiveWorkbook = $ExcelObject.WorkBooks.Open($ExcelTemplate)  
        $ActiveWorksheet = $ActiveWorkbook.Worksheets.Item(1)  
    }
    $i = 0
    For ($y = 3; $y -lt ($Tenants.Count); $y ++) {
            $ActiveWorksheet.Cells.Item($y, 1)  = $Tenants[$i].CloudName          # Cloud Name
            $ActiveWorksheet.Cells.Item($y, 2)  = $Tenants[$i].Subscriber         # Subscriber
            $ActiveWorksheet.Cells.Item($y, 3)  = $Tenants[$i].OdinEmail          # Odin Email
            $ActiveWorksheet.Cells.Item($y, 4)  = $Tenants[$i].Company            # Company
            $ActiveWorksheet.Cells.Item($y, 5)  = $Tenants[$i].OdinSubscriptionID # Odin Subscription ID
            $ActiveWorksheet.Cells.Item($y, 6)  = $Tenants[$i].CoAdmin            # Co Admin
            $ActiveWorksheet.Cells.Item($y, 7)  = $Tenants[$i].CoAdminCount       # Co Admin Count
            $ActiveWorksheet.Cells.Item($y, 8)  = $Tenants[$i].VMCount            # VM Count
            $ActiveWorksheet.Cells.Item($y, 9)  = $Tenants[$i].VMCPU              # VM CPU
            $ActiveWorksheet.Cells.Item($y, 10) = $Tenants[$i].VMRAM              # VM RAM (GB)
            $ActiveWorksheet.Cells.Item($y, 11) = $Tenants[$i].VMDisk             # VM Disk(s) (GB)
            $ActiveWorksheet.Cells.Item($y, 12) = $Tenants[$i].WAPUsername        # WAP Username
            $ActiveWorksheet.Cells.Item($y, 13) = $Tenants[$i].WAPSubscription    # WAP Subscription
        $i ++
    }
            
    $ActiveWorkbook.SaveAs($ExcelFile)
    $ExcelObject.Quit()
    Write-Host "Complete" -ForegroundColor Green
}            # in Dev
Function Send-Report {
    Param (
        [Parameter(Mandatory=$true, Position=1)]
        [String[]] $To, `
        [Parameter(Mandatory=$true, Position=2)]
        [String]   $From, `
        [Parameter(Mandatory=$true, Position=3)]
        [String]   $Subject, `
        [Parameter(Mandatory=$false,Position=4)]
        [String[]] $Body)
        
    $SMTPServer = "10.10.16.146"
    $Message = New-Object System.Net.Mail.MailMessage
    $Message.From = $From
    ForEach ($EmailRecipient in $To) { 
        $Message.To.Add($EmailRecipient)
        $Message.Subject = $Subject
        $Message.IsBodyHTML = $true
        $Message.Body = $Body
        $Message.Attachments.Add($ExcelFile)
        
        $SMTP = New-Object Net.Mail.SmtpClient($smtpServer)
        $SMTP.Send($Message)
    }

}             # Revise
#endregion
#region Secondary Functions
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
}         # Done
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
}               # Done
#endregion

Clear-Host

$TotalTenants = Collect-SCVMMData
Export-Excel -Tenants $TotalTenants

#Send-Report -To $EmailRecipients -From "reports@domain1.local" -Subject "WAP Tenant Report - $Date" -Body $TenantReport