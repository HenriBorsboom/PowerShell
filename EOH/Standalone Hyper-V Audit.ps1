Clear-Host

$Properties = @("Name", "State", "CPUUsage(%)", "MemoryAssigned(M)", "Uptime", "Status", "ComputerName")

$Hosts = @()
$Hosts += ,("IFAJHBHYPV01")
$Hosts += ,("IFAJHBHYPV02")

$AllVMS = @()
ForEach ($VMHost in $Hosts) {
    $VMS = Get-VM -ComputerName $VMHost | Select $Properties
    $AllVMS += $VMS
}
$AllVMS | Select $Properties | Format-Table -AutoSize

# Sample Output
<#
Name             State CPUUsage(%) MemoryAssigned(M) Uptime      Status             ComputerName
----             ----- ----------- ----------------- ------      ------             ------------
IFAJHBFNP01    Running                               5.20:10:35  Operating normally IFAJHBHYPV01
IFAJHBSP01     Running                               35.07:59:19 Operating normally IFAJHBHYPV01
IFAJHBTS02_New Running                               35.07:59:27 Operating normally IFAJHBHYPV01
IFAJHBAPP02    Running                               13.05:44:29 Operating normally IFAJHBHYPV02
IFAJHBDC02     Running                               35.11:04:56 Operating normally IFAJHBHYPV02
IFAJHBSQL01    Running                               35.11:04:56 Operating normally IFAJHBHYPV02
#>