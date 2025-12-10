Clear-Host


$a="<style>                                               
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

$Service = Get-Service 
$Service = $Service | Select-Object Status, Name, DisplayName, CanStop
$Service = $Service | ConvertTo-HTML -head $a -body "<H2>Service Information</H2>" 
$Service = $Service | Out-File C:\Temp\Test.htm

Invoke-Expression C:\Temp\Test.htm