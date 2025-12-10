$ServerListFile = "C:\temp\AllServersList.txt"  
$ServerList = Get-Content $ServerListFile -ErrorAction SilentlyContinue 
$Result = @() 
$thresholdspace = '10'
For ($i = 0; $i -lt $ServerList.Count; $i ++) {
    $computername = $ServerList[$i]
    Write-Host (($i + 1).ToString() + '/' + $ServerList.Count.ToString() + ' - Processing ' + $computername)
    $Savetime = Get-Date -UFormat "%d-%B-%Y"
    $CurrentTime = Get-Date
    Write-Host "|- Getting Average CPU" -ForegroundColor Cyan
    $AVGProc = Get-WmiObject -computername $computername win32_processor | Measure-Object -property LoadPercentage -Average | Select-Object -ExpandProperty Average

    $AVGProcResults = If ($AVGProc -ge 90) {        
       "<b><u><p style=color:#FF0000>CRITICAL CPU: </p></b></u>"
       "$AVGproc%"
    }
    Else { 
        "<b><u><p style=color:#00e600>GOOD AVG CPU: </p></b></u>"
        "$AVGproc%"
    }

    Write-Host "|- Getting OS" -ForegroundColor Cyan
    $OS = gwmi -Class win32_operatingsystem -computername $computername -ErrorAction SilentlyContinue | `
        Select-Object @{Name = "MemoryUsage"; Expression = {“{0:N2}” -f ((($_.TotalVisibleMemorySize - $_.FreePhysicalMemory)*100)/ $_.TotalVisibleMemorySize) }}

    Write-Host "|- Getting Memory usage" -ForegroundColor Cyan
    $MemoryResult = If ($($OS.MemoryUsage) -ge 90) {
        "<b><u><p style=color:#FF0000>CRITICAL MEMORY: </p></b></u>"
            "$($OS.MemoryUsage)%"
    }
    Else { 
        "<b><u><p style=color:#00e600>GOOD MEMORY: </p></b></u>"
        "$($OS.MemoryUsage)%"
    }

    Function Get-Uptime {
        Param ( [string] $ComputerName = $env:COMPUTERNAME )
        Write-Host "|- Getting Uptime" -ForegroundColor Cyan
        $os = Get-WmiObject win32_operatingsystem -ComputerName $ComputerName -ErrorAction SilentlyContinue
        $uptime = (Get-Date) - $os.ConvertToDateTime($os.LastBootUpTime)
        if ($uptime.Days -ge 60) {
            "<b><u><p style=color:#FF0000>CRITICAL UPTIME: </p></b></u>"
            Write-Output ("Uptime   : " + $uptime.Days + " Days " + $uptime.Hours + " Hours " + $uptime.Minutes + " Minutes" )
        }
        Else {
            "<b><u><p style=color:#00e600>GOOD UPTIME: </p></b></u>"
            Write-Output ("Uptime   : " + $uptime.Days + " Days " + $uptime.Hours + " Hours " + $uptime.Minutes + " Minutes" )
        }
    }


    $Uptime = Get-Uptime -ComputerName $computername -ErrorAction SilentlyContinue

    $date = (get-date).AddDays(-7)
    Write-Host "|- Getting System Logs" -ForegroundColor Cyan
    $EventSys = $(Get-WinEvent -ComputerName $computername -ErrorAction SilentlyContinue -FilterHashTable @{LogName='System';Level='1';StartTime = $date;} | measure).count
    $Eventsysresult = If($Eventsys) {
        "<b><u><p style=color:#FF0000>CRITICAL SYSTEM ERRORS FOUND:</p></b></u>"
        $Eventsys
    } 
    Else {
        "<u><b><p style=color:#00e600>SYSTEM:</p></b></u> No Results Found"
    }
    
    Write-Host "|- Getting Application Logs" -ForegroundColor Cyan
    $EventApp = $(Get-WinEvent -ComputerName $computername -ErrorAction SilentlyContinue -FilterHashTable @{LogName='Application';Level='1';StartTime = $date;} | measure).count
    $Eventappresult = If($Eventapp) {
        "<b><u><p style=color:#FF0000>CRITICAL APPLICATION ERRORS FOUND:</p></b></u>"
        $Eventapp
    } 
    Else {
        "<u><b><p style=color:#00e600>APPLICATION:</p></b></u> No Results Found"
    }
    
    Write-Host "|- Security " -ForegroundColor Cyan
    $EventSec = $(Get-WinEvent -ComputerName $computername -ErrorAction SilentlyContinue -FilterHashTable @{LogName='Security';Level='1';StartTime = $date;} | measure).count
    $Eventsecresult = If($Eventsec) {
        "<b><u><p style=color:#FF0000>CRITICAL SECURITY ERRORS FOUND:</p></b></u>"
        $Eventsec
    } 
    Else {
        "<u><b><p style=color:#00e600>SECURITY:</p></b></u> No Results Found"
    }
    
    Write-Host "|- Getting Setup" -ForegroundColor Cyan
    $EventSet = $(Get-WinEvent -ComputerName $computername -ErrorAction SilentlyContinue -FilterHashTable @{LogName='Setup';Level='1';StartTime = $date;} | measure).count
    $Eventsetresult = If($Eventset) {
        "<b><u><p style=color:#FF0000>CRITICAL SETUP ERRORS FOUND:</p></b></u>"
        $Eventset
    } 
    Else {
        "<u><b><p style=color:#00e600>SETUP:</p></b></u> No Results Found"
    }
    
    Write-Host "|- Getting Disk space" -ForegroundColor Cyan
    $DateFileName = Get-Date -format MMM_dd_h:mm
    $LogicalDiskInfo = Get-WMIObject -ComputerName $computername Win32_LogicalDisk  | Where-Object{$_.DriveType -eq 3} | Select-Object Name, `
        @{n='<u><b>PercentFree</b></u>';e={
            if($_.freespace/$_.size*100 -le $thresholdspace) {
                "~red" + "CRITICAL - " + "{0:n2}" -f ($_.freespace/$_.size*100) 
            }
            else {
                "~Green" + "{0:n2}"-f ($_.freespace/$_.size*100)}
            }} | ConvertTo-Html -Fragment

    $LogicalDiskInfo = $LogicalDiskInfo -replace '<td>~red', '<td style="font:Arial, Helvetica, sans-serif; font-lifting training:bold; color:#F00">'
    $LogicalDiskInfo = $LogicalDiskInfo -replace '<td>~Green', '<td style="font:Arial, Helvetica, sans-serif; font-lifting training:bold; color:#00e600">'

  
    $result += [PSCustomObject] @{ 
        ServerName = "$computername"
        CPULoad = "$AVGProcResults"
        MemLoad = "$MemoryResult"
        DriveSpace = "$LogicalDiskInfo"
        SysUptime = "$Uptime"
        Eventsys = "$Eventsysresult"
        Eventapp = "$Eventappresult"
        Eventsec = "$Eventsecresult"
        Eventset = "$Eventsetresult"
    }

    $Outputreport = "<HTML><TITLE> PG Group - Server Health Report $CurrentTime</TITLE>
    <BODY background-color:peachpuff>
    <font color =""#99000"" face=""Microsoft Tai le"">
    <H2> BB - Server Health Report $CurrentTime</H2></font>
                      
    <style>
        BODY{background-color:#b0c4de;}
        TABLE{border-width: 1px;border-style: solid;border-color: black;border-collapse: collapse;}
        TH{border-width: 1px;padding: 3px;border-style: solid;border-color: black;background-color:#778899}
        TD{border-width: 1px;padding: 3px;border-style: solid;border-color: black;}
        tr:nth-child(odd) { background-color:#d3d3d3;} 
        tr:nth-child(even) { background-color:white;} 
    </style>
    <Table border=1 cellpadding=10 cellspacing=0>
    <TR bgcolor=gray align=center>
    <TD><B>Server Name</B></TD>
    <TD><B>Average CPU Utilization</B></TD>
    <TD><B>Current Memory Utilization</B></TD>
    <TD><B>Drive Free Space</B></TD>
    <TD><B>System Up Time</B></TD>
    <TD><B>Critical Events Last 7days</B></TD></TR>"
                        
    Foreach($Entry in $Result) { 
        if(($Entry.CpuLoad) -or ($Entry.memload) -ge "80") { 
            $Outputreport += "<TR bgcolor=White>" 
        } 
        else {
            $Outputreport += "<TR>" 
        }
        
        $Outputreport += "<TD>$($Entry.Servername)</TD><TD align=center>$($Entry.CPULoad)</TD><TD align=center>$($Entry.MemLoad)</TD><TD align=center>$($Entry.DriveSpace)</TD><TD align=center>$($Entry.SysUptime)</TD><TD align=center>$($Entry.Eventsys + $Entry.Eventapp + $Entry.Eventsec + $Entry.Eventset)</TD></TR>" 
    }
    $Outputreport += "</Table></BODY></HTML>"
} 
 
$Outputreport | out-file "C:\Temp\BB_All Server Health Report $Savetime.html"