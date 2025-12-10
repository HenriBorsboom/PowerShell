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
Function Generate-Report {
    $HTMLFile = Get-TimeStampOutputFile -TargetLocation "C:\Temp\NVGRE" -Extension "HTML" -VariableName -Name "NVGRE"
    $Date = $([DateTime]::Now.ToString('dd-MM-yyyy'))

    $NetworkServices = Get-SCNetworkService -ErrorAction Stop
    $RunAsAccount = Get-SCRunAsAccount -Name "Domain2 - VMM Host Access Account"

    $AllNetworkServiceReadResults = @()
    $AllNetworkServiceTestResults = @()
    ForEach ($NetworkService in $NetworkServices) {
        Write-Host "Processing " -NoNewline
        Write-Host $NetworkService.Name -ForegroundColor Yellow
        Try {
            $NetworkServiceReadResults = Read-SCNetworkService -NetworkService $NetworkService -ErrorAction Stop
            $NetworkServiceTestResults = Test-SCNetworkService -ConnectionString $NetworkService.ConnectionString -RunAsAccount $RunAsAccount -ConfigurationProvider $NetworkService.ConfigurationProvider -ErrorAction Stop
            $AllNetworkServiceReadResults += $NetworkServiceReadResults
            $AllNetworkServiceTestResults += $NetworkServiceTestResults
        }
        Catch { Write-Host "Failed" -ForegroundColor Red; $_ }
    }
    $CombinedOutput = @()
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
    </style><H2>Windows Azure Pack Network Services</H2>"
    $HTMLBody = "<H2>Windows Azure Pack Tenants</H2>"
    $HTMLOutputFile1 = $AllNetworkServiceReadResults | ConvertTo-HTML -Fragment -PreContent ($HTMLHeader + "<H2>Windows Azure Pack Network Service Read Results</H2>")
    $HTMLOutputFile2 = $AllNetworkServiceTestResults | ConvertTo-HTML -Fragment -PreContent ($HTMLHeader + "<H2>Windows Azure Pack Network Service Read Results</H2>")
    $CombinedOutput += $HTMLOutputFile1
    $CombinedOutput += $HTMLOutputFile2
    $CombinedOutput | ConvertTo-HTML -Head $HTMLHeader -Body $HTMLBody
    $Output = $CombinedOutput | Out-File $HTMLFile -Force
    Send-Report -To @("user@company.com") -From "NVGRE@domain1.local" -Subject "NVGRE Test Results - $Date" -Body $CombinedOutput -Attachments @($HTMLFile)
    Write-Host $HTMLFile
}
Clear-Host
Generate-Report