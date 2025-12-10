                                                                         
param (                                                                         
                                                                         
       [Parameter( Mandatory=$false)]                                                                
       [bool]$reportmode=$true,                                                               
                                                                         
       [Parameter( Mandatory=$false)]                                                                
       [string]$reportfile= "fileprintserverhealth - $(get-date -f yyyy-MM-dd).html",                                                               
                                                                         
       [Parameter( Mandatory=$false)]                                                                
       [bool]$sendemail=$true                                                                 
       )                                                                  
                                                                   
                                                                         
#...................................                                                                      
# Email Settings                                                                      
#...................................                                                                      
                                                                         
$smtpServer = "mlgjnb01appdom2.linde.lds.grp"                                                                    
$smtpTo = "peter.chaukura@company.com,2ndLine.ServerSupportDesk@company.com"                                                                    
$smtpFrom = "health@afrox.line.com"                                                                       
$messagesubject = "File and Print Checks - AFROX $date"                                                                       
                                                                         
                                                                         
#...................................                                                                      
# Variables                                                                     
#...................................                                                                      
                                                                         
$now = Get-Date                                                                       #Used for timestamps
$date = $now.ToShortDateString()                                   #Short date format for email message subject                            
[array]$fileprintservers = @()                                            #Array for the Exchange server or servers to check                        
[int]$transportqueuehigh = 200                                            #Change this to set transport queue high threshold                        
[int]$transportqueuewarn = 100                                                        #Change this to set transport queue warning threshold       
$mapitimeout = 100                                                              #Timeout for each MAPI connectivity test, in seconds 
$pass = "Green"                                                                       
$warn = "Yellow"                                                                      
$fail = "Red"                                                                   
$ip = $null                                                                     
[array]$summaryreport = @()                                                                         
[array]$report = @()                                                                         
[array]$htmltable = @()                                                                      
[array]$summaryhtml = @()                                                                    
[array]$htmltablerow = @()                                                                   
#...................................                                                                      
# Error/Warning Strings                                                                      
#...................................                                                                      
                                                                         
$string0 = " "                                                                        
$string1 = "Server is not reachable by ping. "                                                                   
$string3 = "------ Checking"                                                                        
$string4 = "Could not test service health. "                                                                     
$string5 = "Required services not running. "                                                                     
$string6 = "Could not check queue. "                                                                      
$string7 = " "                                                                        
$string8 = " "                                                                        
$string9 = " "                                                                        
$string10 = " "                                                                       
$string11 = " "                                                                       
$string12 = " "                                                                       
$string13 = "Server not found in DNS. "                                                                   
                                                                         
                                                     
                                                                         
$fileprintservers ="MLGPRY16SAPPRN1","MLGJNB01SAPPRN1"                                                                        
#Begin the health checks                                                                      
foreach ($server in $fileprintservers)                                                                    
{                                                                        
Write-Host -ForegroundColor Blue "$string3 $server"                                                                     
                                                                         
#Custom object properties                                                                    
             $serverObj = New-Object PSObject                                                       
             $serverObj | Add-Member NoteProperty -Name "Server" -Value $server                                                            
             $serverObj | Add-Member NoteProperty -Name "DNS" -Value $null                                                            
             $serverObj | Add-Member NoteProperty -Name "Ping" -Value $null                                                            
             $serverObj | Add-Member NoteProperty -Name "Uptime (hrs)" -Value $null                                                       
             $serverObj | Add-Member NoteProperty -Name "SAPSprint Service" -Value $null                                                        
             $serverObj | Add-Member NoteProperty -Name "Print Spooler" -Value $null                                                       
             $serverObj | Add-Member NoteProperty -Name "Server Service" -Value $null                                                        
             $serverObj | Add-Member NoteProperty -Name "LPD Service" -Value $null                                                       
                                                                         
                                                                         
             #Check server name resolves in DNS                                                           
             Write-Host "DNS Check: " -NoNewline;                                                         
             try                                                         
             {                                                           
                    $ip = [System.Net.Dns]::GetHostByName($server).AddressList | Select-Object IPAddressToString -ExpandProperty IPAddressToString                                                     
             }                                                           
             catch                                                       
             {                                                           
                    Write-Host -ForegroundColor $warn $_.Exception.Message                                                     
                    $ip = $null                                                 
             }                                                           
             finally      {}                                                    
                                                                         
             if ( $ip -ne $null )                                                            
             {                                                           
                                                                         
                    Write-Host -ForegroundColor $pass "Pass"                                                     
                    $serverObj | Add-Member NoteProperty -Name "DNS" -Value "Pass" -Force                                               
                                                                         
#Is server online                                                                     
                    Write-Host "Server up: " -NoNewline;                                                  
                    $ping = new-object System.Net.NetworkInformation.Ping                                                
                    $result = $ping.send($ip)                                                
            $result = $ping.send($ip)                                                                      
            $result = $ping.send($ip)                                                                                   
                    if ($result.status.ToString() –eq "Success")                                                 
                    {                                                    
                           Write-Host -ForegroundColor $pass "Pass"                                               
                           $serverObj | Add-Member NoteProperty -Name "Ping" -Value "Pass" -Force                                         
#Uptime check                                                                   
                                                                         
                if ($wmiissueservers -icontains $server)                                                                      
                    {[string]$uptime = "Unable to retrieve uptime"}                                                                         
                else                                                                         
                    {$uptime = $null                                                                      
                               $laststart = $null                                             
                                                                         
                               try                                               
                               {                                          
                                    $laststart = [System.Management.ManagementDateTimeconverter]::ToDateTime((Get-WmiObject -Class Win32_OperatingSystem -computername $server -ErrorAction Stop).LastBootUpTime)                                       
                               }                                          
                               catch                                             
                               {                                          
                                    Write-Host -ForegroundColor $warn $_.Exception.Message                                        
                               }                                          
                               finally  {}                                      
                                                                         
                               if ($laststart -eq $null)                                             
                               {                                          
                                    [string]$uptime = "Unable to retrieve uptime"                                        
                               }                                          
                               else                                              
                               {                                          
                                    [int]$uptime = (New-TimeSpan $laststart $now).TotalHours                                     
                                    [int]$uptime = "{0:N0}" -f $uptime                                    
                               }                                          
                                                                         
                           Write-Host "Uptime (hrs): " -NoNewline;                                         
                           Switch ($uptime -gt 23) {                                          
                                 $true { Write-Host -ForegroundColor $pass $uptime }                                      
                                 $false { Write-Host -ForegroundColor $warn $uptime }                                      
                                 default { Write-Host -ForegroundColor $warn $uptime }                                      
                                 }                                       
                           }                                              
                $serverObj | Add-Member NoteProperty -Name "Uptime (hrs)" -Value $uptime -Force                                                                         
                                                                         
# check SAPSprint services status                                                                        
                Write-Host "SAPSprint Service: " -NoNewline;                                                                         
                $SAPSprintservice = get-service -ComputerName $server -name SAPSprint                                                                       
                if ($SAPSprintservice.status -eq "running")                                                                   
                {                                                                     
                Write-host -ForegroundColor $pass $SAPSprintservice.Status}                                                                         
                else                                                                         
                {                                                                     
                Write-host -ForegroundColor $fail $SAPSprintservice.Status}                                                                         
                $serverObj | Add-Member NoteProperty -Name "SAPSprint Service" -Value $SAPSprintservice.status -Force                                                                    
                                                                         
                # check Print Spooler service status                                                                    
                Write-Host "Print Spooler: " -NoNewline;                                                                      
                if ($notprtservers -icontains $server)                                                                        
                    {                                                                        
                    $spooler_status = "N/A"                                                                      
                    Write-host -ForegroundColor $pass $spooler_status                                                                      
                    $serverObj | Add-Member NoteProperty -Name "Print Spooler" -Value $spooler_status -Force                                                                       
                    }                                                                        
                else                                                                         
                    {                                                                        
                    $spoolerservice = get-service -ComputerName $server -name Spooler                                                                         
                    if ($spoolerservice.status -eq "running")                                                                        
                        {                                                                    
                        Write-host -ForegroundColor $pass $spoolerservice.Status}                                                                      
                    else                                                                     
                        {                                                                    
                        Write-host -ForegroundColor $fail $spoolerservice.Status}                                                                      
                    $serverObj | Add-Member NoteProperty -Name "Print Spooler" -Value $spoolerservice.status -Force                                                                      
                    }                                                                        
                                                                         
                # check Server Service status                                                                    
                Write-Host "Server Service: " -NoNewline;                                                                     
                $serverservice = get-service -ComputerName $server -name Server                                                                   
                if ($serverservice.status -eq "running")                                                                      
                {                                                                     
                Write-host -ForegroundColor $pass $serverservice.Status}                                                                    
                else                                                                         
                {                                                                     
                Write-host -ForegroundColor $fail $serverservice.Status}                                                                    
                $serverObj | Add-Member NoteProperty -Name "Server Service" -Value $serverservice.status -Force                                                                        
                                                                         
                # check LPD Service status                                                                       
                Write-Host "LPD Service: " -NoNewline;                                                                        
                $LPDservice = get-service -ComputerName $server -name LPDSVC                                                                         
                if ($LPDservice.status -eq "running")                                                                   
                {                                                                     
                Write-host -ForegroundColor $pass $LPDservice.Status}                                                                       
                else                                                                         
                {                                                                     
                Write-host -ForegroundColor $fail $LPDservice.Status}                                                                       
                $serverObj | Add-Member NoteProperty -Name "LPD Service" -Value $LPDservice.status -Force                                                                     
        $report = $report + $serverObj                                                                           
             }                                                           
                                                                         
                                                                         
                                                                          
        else                                                                    
                    {                                                    
                           #Server is not up                                           
                           Write-Host -ForegroundColor $warn $string1                                             
                           $serverObj | Add-Member NoteProperty -Name "Error Details" -Value ($($serverObj."Error Details") + $string1) -Force                                         
                           $serverObj | Add-Member NoteProperty -Name "Ping" -Value "Fail" -Force                                         
                           $report = $report + $serverObj                                            
                    }                                                    
             }                                                           
             else                                                        
             {                                                           
                    Write-Host -ForegroundColor $Fail "Fail"                                                     
                    Write-Host -ForegroundColor $warn $string13                                                  
                    $serverObj | Add-Member NoteProperty -Name "Error Details" -Value ($($serverObj."Error Details") + $string13) -Force                                                 
                    $serverObj | Add-Member NoteProperty -Name "DNS" -Value "Fail" -Force                                               
                    $report = $report + $serverObj                                                  
             }                                                           
       }                                                                  
                                                                         
                                                                         
#Generate the report                                                                         
if ($reportmode -or $sendemail)                                                                     
{                                                                        
       #Get report generation timestamp                                                              
       $reportime = Get-Date                                                                  
                                                                         
       #Generate report summary                                                               
       #$summaryreport = $report | select Server,"Error Details","Warning Details" | Where {$_."Error Details" -ne "" -or $_."Warning Details" -ne ""}                                                                   
                                                                         
       #Create HTML Report                                                             
       #Common HTML head and styles                                                                  
       $htmlhead="<html>                                                               
                           <style>                                               
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
                           </style>                                              
                           <body>                                         
                           <h1 align=""center"">File and Print Health Check Report</h1>                                          
                                               <h2 align=""center"">MLGPRY16SAPPRN1 and MLGJNB01SAPPRN1</h2>                       
                           <h3 align=""center"">Generated: $reportime</h3>"                                               
                                                                         
                                                                         
                                                                         
       if ($report)                                                              
       {                                                                  
             #File and Print Report Table Header                                                          
             $htmltableheader = "<h3>File and Print Health</h3>                                                         
                                               <p>                        
                                               <table>                           
                                               <tr>                       
                                               <th>Server</th>                         
                                               <th>DNS</th>                      
                                               <th>Ping</th>                     
                                               <th>Uptime (hours)</th>                        
                                               <th>SAPSprint Service</th>                     
                                               <th>Print Spooler</th>                         
                                               <th>Server Service</th>                        
                                               <th>LPD Service</th>                           
                                               </tr>"                     
                                                                         
             #File and Print Report Table                                                           
             $htmltable = $htmltable + $htmltableheader                                                          
                                                                         
             foreach ($reportline in $report)                                                       
             {                                                           
                    $htmltablerow = "<tr>"                                                   
                    $htmltablerow = $htmltablerow + "<td>$($reportline.server)</td>"                                                
                                                                         
                                                                         
                    switch ($($reportline.dns))                                                     
                    {                                                    
                           Pass {$htmltablerow = $htmltablerow + "<td class=""pass"">$($reportline.dns)</td>"}                                              
                           Fail {$htmltablerow = $htmltablerow + "<td class=""fail"">$($reportline.dns)</td>"}                                              
                    }                                                    
                                                                         
                    switch ($($reportline.ping))                                                    
                    {                                                    
                           Pass {$htmltablerow = $htmltablerow + "<td class=""pass"">$($reportline.ping)</td>"}                                             
                           Fail {$htmltablerow = $htmltablerow + "<td class=""fail"">$($reportline.ping)</td>"}                                             
                    }                                                    
                                                                         
                    if ($($reportline."uptime (hrs)") -eq "Access Denied")                                                     
                    {                                                    
                           $htmltablerow = $htmltablerow + "<td class=""warn"">Access Denied</td>"                                              
                    }                                                    
                    else                                                 
                    {                                                    
                           $hours = [int]$($reportline."uptime (hrs)")                                            
                           if ($hours -le 24)                                          
                           {                                              
                                 $htmltablerow = $htmltablerow + "<td class=""warn"">$hours</td>"                                        
                           }                                              
                           else                                           
                           {                                              
                                 $htmltablerow = $htmltablerow + "<td class=""pass"">$hours</td>"                                        
                           }                                              
                    }                                                    
                                                                         
                    switch ($($reportline."SAPSprint Service"))                                                  
                    {                                                    
                "Running" {$htmltablerow = $htmltablerow + "<td class=""pass"">$($reportline."SAPSprint Service")</td>"}                                                                      
                           Stopped {$htmltablerow = $htmltablerow + "<td class=""fail"">$($reportline."SAPSprint Service")</td>"}                                           
                "Stopping" {$htmltablerow = $htmltablerow + "<td class=""fail"">$($reportline."SAPSprint Service")</td>"}                                                                      
                "Starting" {$htmltablerow = $htmltablerow + "<td class=""fail"">$($reportline."SAPSprint Service")</td>"}                                                                      
                "Paused" {$htmltablerow = $htmltablerow + "<td class=""fail"">$($reportline."SAPSprint Service")</td>"}                                                                      
                "Disabled" {$htmltablerow = $htmltablerow + "<td class=""fail"">$($reportline."SAPSprint Service")</td>"}                                                                      
                           default {$htmltablerow = $htmltablerow + "<td>$($reportline."SAPSprint Service")</td>"}                                        
                    }                                                    
                                                                         
                    switch ($($reportline."Print Spooler"))                                               
                    {                                                    
                           Running {$htmltablerow = $htmltablerow + "<td class=""pass"">$($reportline."Print Spooler")</td>"}                                         
                           Stopped {$htmltablerow = $htmltablerow + "<td class=""fail"">$($reportline."Print Spooler")</td>"}                                         
                "Stopping" {$htmltablerow = $htmltablerow + "<td class=""fail"">$($reportline."Print Spooler")</td>"}                                                                    
                "Starting" {$htmltablerow = $htmltablerow + "<td class=""fail"">$($reportline."Print Spooler")</td>"}                                                                    
                "Paused" {$htmltablerow = $htmltablerow + "<td class=""fail"">$($reportline."Print Spooler")</td>"}                                                                    
                "Disabled" {$htmltablerow = $htmltablerow + "<td class=""fail"">$($reportline."Print Spooler")</td>"}                                                                    
                           default {$htmltablerow = $htmltablerow + "<td>$($reportline."Print Spooler")</td>"}                                            
                    }                                                    
                                                                         
                    switch ($($reportline."Server Service"))                                                     
                    {                                                    
                           Running {$htmltablerow = $htmltablerow + "<td class=""pass"">$($reportline."Server Service")</td>"}                                        
                           Stopped {$htmltablerow = $htmltablerow + "<td class=""fail"">$($reportline."Server Service")</td>"}                                        
                "Stopping" {$htmltablerow = $htmltablerow + "<td class=""fail"">$($reportline."Server Service")</td>"}                                                                   
                "Starting" {$htmltablerow = $htmltablerow + "<td class=""fail"">$($reportline."Server Service")</td>"}                                                                   
                "Paused" {$htmltablerow = $htmltablerow + "<td class=""fail"">$($reportline."Server Service")</td>"}                                                                   
                "Disabled" {$htmltablerow = $htmltablerow + "<td class=""fail"">$($reportline."Server Service")</td>"}                                                                   
                           default {$htmltablerow = $htmltablerow + "<td>$($reportline."Server Service")</td>"}                                           
                    }                                                    
                                                                         
                    switch ($($reportline."LPD Service"))                                                 
                    {                                                    
                           Running {$htmltablerow = $htmltablerow + "<td class=""pass"">$($reportline."LPD Service")</td>"}                                           
                           Stopped {$htmltablerow = $htmltablerow + "<td class=""fail"">$($reportline."LPD Service")</td>"}                                           
                "Stopping" {$htmltablerow = $htmltablerow + "<td class=""fail"">$($reportline."LPD Service")</td>"}                                                                      
                "Starting" {$htmltablerow = $htmltablerow + "<td class=""fail"">$($reportline."LPD Service")</td>"}                                                                      
                "Paused" {$htmltablerow = $htmltablerow + "<td class=""fail"">$($reportline."LPD Service")</td>"}                                                                      
                "Disabled" {$htmltablerow = $htmltablerow + "<td class=""fail"">$($reportline."LPD Service")</td>"}                                                                      
                           default {$htmltablerow = $htmltablerow + "<td>$($reportline."LPD Service")</td>"}                                              
                    }                                                    
                                                                         
                                                                         
                    $htmltablerow = $htmltablerow + "</tr>"                                               
                                                                         
                    $htmltable = $htmltable + $htmltablerow                                               
             }                                                           
             $htmltable = $htmltable + "</table></p>"                                                            
       }                                                                  
                                                                         
       $htmltail = "</body>                                                                   
                                                                         
                                                                         
                                                                         
                           </html>"                                              
                                                                         
                                                                         
       $htmlreport = $htmlhead + $summaryhtml + $htmltable + $htmltail                                                                
                                                                         
       if ($reportmode -or $reportfile)                                                              
       {                                                                  
             $htmlreport | Out-File $reportfile                                                           
       }                                                                  
                                                                         
       if ($sendemail)                                                                 
       {                                                                  
             #Get ready to send email message                                                       
             $message = New-Object System.Net.Mail.MailMessage $smtpfrom, $smtpto                                                            
             $message.Subject = $messageSubject                                                           
             $message.IsBodyHTML = $true                                                            
             $message.Body = $htmlreport                                                            
                                                                         
             #Send email message                                                      
             $smtp = New-Object Net.Mail.SmtpClient($smtpServer)                                                        
             $smtp.Send($message)                                                            
       }                                                                  
}                                                                        
                                                                         
                                                                         
                                                                         
                                                                         



Regards

 
Peter Chaukura
Systems Engineer: Advanced Managed Services
T +27 (0) 11 266 6044
F +27 (0) 86 724 0029
W bcx.mobi / www.company.com
 
    This email and its contents are subject to the Business Connexion (Pty) Ltd. Email legal notice http://www.company.com/disclaimer.htm             



