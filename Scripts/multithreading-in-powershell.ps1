################################################################################# 
## 
## Server Health Check 
## Created by Arun Sabale
## Date : 16 june 2014 
## Version : 1.0 
##
################################################################################ 


$wmidiskblock = {
Param($ComputerName = "LocalHost")
Get-WmiObject -ComputerName $ComputerName -Class win32_logicaldisk |  Where-Object {$_.drivetype -eq 3}
}


$Computers = @("arun-pc","JNJKRYSFPS01","psgusbrfps01") 
 #Start all jobs
ForEach($Computer in $Computers)
{
$Computer
   Start-Job -scriptblock $wmidiskblock  -ArgumentList $Computer
}
Get-Job | Wait-Job
$out = Get-Job | Receive-Job
$out |export-csv wmi.csv