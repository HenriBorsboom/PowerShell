
$IPAddresses = get-content D:\HealthReports\Scripts\servers.txt

foreach($IP in $IPAddresses){
racadm -r $IP -u root -p 'PasswordForRootUser' getsysinfo | Sort-Object "Host Name" |
Select-String "Host Name", "System Model", "OS Name", "Firmware Version" ,"Firmware Build" ,"Last Firmware Update" |

Out-file D:\HealthReports\Reports\OtherReports\PGiDracInfo.txt -Append 


