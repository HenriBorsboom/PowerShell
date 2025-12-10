Function Export-Excel {
    Param (
        [Parameter (Mandatory=$true, Position=1)]
        [Object[]] $Tenants)

    $ExcelTemplate             = "C:\Temp\TenantReports\Reference Folder\Template.xlsx"
    $ExcelFile                 = "C:\Temp\TenantReports\Tenants - " + $([DateTime]::Now.ToString('dd-MM-yyyy')) + ".xlsx"
    $ExcelObject               = New-Object -ComObject Excel.Application  
    $ExcelObject.Visible       = $true 
    $ExcelObject.DisplayAlerts = $false
    $Date                      = Get-Date -Format "dd-MM-yyyy"
    
    If (Test-Path $ReferenceCI) {  
        #Open the document  
        $ActiveWorkbook = $ExcelObject.WorkBooks.Open($Template)  
        $ActiveWorksheet = $ActiveWorkbook.Worksheets.Item(1)  
    }
    $i = 0
    For ($y = 3; $y -lt ($Tenants.Count); $y ++) {
        For ($x = 1; $x -lt 14; $x ++) {
            $ActiveWorksheet.Cells.Item($y,$x) = $Tenants[$i].CloudName          # Cloud Name
            $ActiveWorksheet.Cells.Item($y,$x) = $Tenants[$i].Subscriber         # Subscriber
            $ActiveWorksheet.Cells.Item($y,$x) = $Tenants[$i].OdinEmail          # Odin Email
            $ActiveWorksheet.Cells.Item($y,$x) = $Tenants[$i].Company            # Company
            $ActiveWorksheet.Cells.Item($y,$x) = $Tenants[$i].OdinSubscriptionID # Odin Subscription ID
            $ActiveWorksheet.Cells.Item($y,$x) = $Tenants[$i].CoAdmin            # Co Admin
            $ActiveWorksheet.Cells.Item($y,$x) = $Tenants[$i].CoAdminCount       # Co Admin Count
            $ActiveWorksheet.Cells.Item($y,$x) = $Tenants[$i].VMCount            # VM Count
            $ActiveWorksheet.Cells.Item($y,$x) = $Tenants[$i].VMCPU              # VM CPU
            $ActiveWorksheet.Cells.Item($y,$x) = $Tenants[$i].VMRAM              # VM RAM (GB)
            $ActiveWorksheet.Cells.Item($y,$x) = $Tenants[$i].VMDisk             # VM Disk(s) (GB)
            $ActiveWorksheet.Cells.Item($y,$x) = $Tenants[$i].WAPUsername        # WAP Username
            $ActiveWorksheet.Cells.Item($y,$x) = $Tenants[$i].WAPSubscription    # WAP Subscription
        }
    }
            
    $ActiveWorkbook.SaveAs($ExcelFile)
    $ExcelObject.Quit()
    Invoke-Expression $ExcelFile
      
}            # in Dev
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
}             # Revise
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

#    $HTMLHeader="<style>                                               
#        BODY{font-family: Arial; font-size: 8pt;}                                              
#        H1{font-size: 16px;}                                               
#        H2{font-size: 14px;}                                               
#        H3{font-size: 12px;}                                               
#        TABLE{border: 1px solid black; border-collapse: collapse; font-size: 8pt;}                                         
#        TH{border: 1px solid black; background: #dddddd; padding: 5px; color: #000000;}                                           
#        TD{border: 1px solid black; padding: 5px; }                                            
#        td.pass{background: #7FFF00;}                                             
#        td.warn{background: #FFE600;}                                             
#        td.fail{background: #FF0000; color: #ffffff;}                                          
#        </style>"
#    $HTMLBody = "<H2>Windows Azure Pack Tenants</H2>"

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
            $WAPCoAdmins       = Query-SQL -Query "Select Username from mp.SubscriptionCoAdmins where SubscriptionId = '$WAPSubscriptionID'"
            $WAPCoAdminsCount  = $WAPCoAdmins.Username.Count
            $WAPCoAdminUsers   = $WAPCoAdmins.Username
            
            If ($WAPUserEmail -ne $null) { $ADDetails = Get-ADUser -Filter { EmailAddress -like $WAPUserEmail } -Properties * -ErrorAction Stop }
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

    Export-Excel -Tenants $TotalTenants
#    $TotalTenants = $TotalTenants | Sort "Cloud Name" | Select `
#        "Cloud Name", `
#        "Subscriber", `
#        "Odin Email", `
#        "Company", `
#        "Odin Subscription ID", `
#        "Co Admin", `
#        "Co Admin Count", `
#        "VM Count", `
#        "VM CPU", `
#        "VM RAM (GB)", `
#        "VM Disk (GB)", `
#        "WAP Username", `
#        "WAP Subscription"
        
#    $HTMLOutputFile = $TotalTenants | ConvertTo-HTML -head $HTMLHeader -Body $HTMLBody
#    $HTMLOutputFile | Out-File $HTMLFile
#    Return $TotalTenants
}   # Should be replaced with Export-Excel
Function Start {
    # $ExcelFile = "C:\Temp\TenantReports\Tenants - " + $([DateTime]::Now.ToString('dd-MM-yyyy')) + ".xlsx"
    # $Date = $([DateTime]::Now.ToString('dd-MM-yyyy'))
    
    #region Collect SCVMM Data
    Write-Host "Retrieving Virtual Machines from Virtual Machine Manager - " -NoNewline
        $VMs = Get-SCVirtualMachine -All
    Write-Host "Complete" -ForegroundColor Green
    
    Write-Host "Retrieving User Roles from Virtual Machine Manager - " -NoNewline
        $UserRoles = Get-SCUserRole
    Write-Host "Complete" -ForegroundColor Green
    #endregion

    $TenantReport = Generate-TenantReport -VirtualMachines $VMs -UserRoles $UserRoles -HTMLFile $HTMLFile
    
    
    $EmailRecipients = @(
                "henri.borsboom@company.com", `
                "darrel.wright@company.com", `
                "andrew.allner@company.com", `
                "jorge.esilva@company.com", `
                "chris.dorn@company.com", `
                "CSBReportsSouthAfrica@company.com", `
                "Christian.Hagner@company.com")
    $EmailAttachments = @($HTMLFile)
    Send-Report -To $EmailRecipients -From "reports@domain1.local" -Subject "WAP Tenant Report - $Date" -Body $TenantReport -Attachments $EmailAttachments

}                   # Revise

Clear-Host

Start