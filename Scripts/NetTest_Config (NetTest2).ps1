Function Rename_Networks
{    Param(    [Parameter(Mandatory=$True,Position=1)]
    [string]$Set)
    if ($Set = "1")
    {
        Rename-NetAdapter -Name "2174 - Ten 5" -NewName "2166 - VM" | Write-Host "Renaming Network Adapter to '2166 - VM'"
        Rename-NetAdapter -Name "2175 - Ten 6" -NewName "2167 - CSV" | Write-Host "Renaming Network Adapter to '2167 - CSV'"
        Rename-NetAdapter -Name "2176 - Ten 7" -NewName "2168 - HB" | Write-Host "Renaming Network Adapter to '2168 - HB'"        Rename-NetAdapter -Name "2177 - Ten 8" -NewName "2169 - MGMT" | Write-Host "Renaming Network Adapter to '2169 - MGMT'"
        Rename-NetAdapter -Name "2178 - Ten 9" -NewName "2170 - Ten 1" | Write-Host "Renaming Network Adapter to '2170 - Ten 1'"        Rename-NetAdapter -Name "2179 - Ten 10" -NewName "2171 - Ten 2" | Write-Host "Renaming Network Adapter to '2171 - Ten 2'"
        Rename-NetAdapter -Name "2180 - Ten 11" -NewName "2172 - Ten 3" | Write-Host "Renaming Network Adapter to '2172 - Ten 3'"        Rename-NetAdapter -Name "2181 - Ten 12" -NewName "2173 - Ten 4" | Write-Host "Renaming Network Adapter to '2173 - Ten 4'"        }    Elseif ($Set = "2")
    {
        Rename-NetAdapter -Name  -NewName "2174 - Ten 5" | Write-Host "Renaming Network Adapter to '2174 - Ten 5'"
        Rename-NetAdapter -Name  -NewName "2175 - Ten 6" | Write-Host "Renaming Network Adapter to '2175 - Ten 6'"
        Rename-NetAdapter -Name  -NewName "2176 - Ten 7" | Write-Host "Renaming Network Adapter to '2176 - Ten 7'"        Rename-NetAdapter -Name  -NewName "2177 - Ten 8" | Write-Host "Renaming Network Adapter to '2177 - Ten 8'"
        Rename-NetAdapter -Name  -NewName "2178 - Ten 9" | Write-Host "Renaming Network Adapter to '2178 - Ten 9'"        Rename-NetAdapter -Name  -NewName "2179 - Ten 10" | Write-Host "Renaming Network Adapter to '2179 - Ten 10'"        Rename-NetAdapter -Name  -NewName "2180 - Ten 11" | Write-Host "Renaming Network Adapter to '2180 - Ten 11'"        Rename-NetAdapter -Name  -NewName "2181 - Ten 12" | Write-Host "Renaming Network Adapter to '2181 - Ten 12'"
    }
}

Function Set_IPs
{
    Param(
        [Parameter(Mandatory=$True,Position=1)]
        [string]$Set)
    If ($Set = "1")
    {        Enable_DHCP "1"        netsh interface ipv4 set address "2166 - VM" static 10.10.16.241 255.255.255.128 10.10.16.129
        netsh interface ipv4 set address "2167 - CSV" static 10.10.145.22 255.255.255.192 10.10.145.1        netsh interface ipv4 set address "2168 - HB" static 10.10.145.82 255.255.255.192 10.10.145.65        netsh interface ipv4 set address "2169 - MGMT" static 10.10.231.232 255.255.255.192 10.10.231.193
        netsh interface ipv4 set address "2170 - Ten 1" static 10.10.29.3 255.255.255.240 10.10.29.1
        netsh interface ipv4 set address "2171 - Ten 2" static 10.10.29.19 255.255.255.240 10.10.29.17
        netsh interface ipv4 set address "2172 - Ten 3" static 10.10.29.35 255.255.255.240 10.10.29.33        netsh interface ipv4 set address "2173 - Ten 4" static 10.10.29.51 255.255.255.240 10.10.29.49
    }
    Elseif ($Set = "2")
    {
        Enable_DHCP "2"
        netsh interface ipv4 set address "2174 - Ten 5" static 10.10.29.67 255.255.255.240 10.10.29.65
        netsh interface ipv4 set address "2175 - Ten 6" static 10.10.29.83 255.255.255.240 10.10.29.81
        Netsh interface ipv4 set address "2176 - Ten 7" static 10.10.29.99 255.255.255.240 10.10.29.97
        netsh interface ipv4 set address "2177 - Ten 8" static 10.10.29.115 255.255.255.240 10.10.29.113
        netsh interface ipv4 set address "2178 - Ten 9" static 10.10.29.131 255.255.255.224 10.10.29.129
        netsh interface ipv4 set address "2179 - Ten 10" static 10.10.29.163 255.255.255.224 10.10.29.161
        netsh interface ipv4 set address "2180 - Ten 11" static 10.10.29.195 255.255.255.224 10.10.29.193
        netsh interface ipv4 set address "2181 - Ten 12" static 10.10.29.227 255.255.255.224 10.10.29.225
    }
}

Function Enable_Networks{
    Param(
        [Parameter(Mandatory=$True,Position=1)]
        [string]$Set)

    $Set1Adapters = @("2166 - VM", `
        "2167 - CSV", `
        "2168 - HB", `
        "2169 - MGMT", `
        "2170 - Ten 1", `        "2171 - Ten 2", `
        "2172 - Ten 3", `        "2173 - Ten 4")
    $Set2Adapters = @("2174 - Ten 5", `
        "2175 - Ten 6", `
        "2176 - Ten 7", `
        "2177 - Ten 8", `
        "2178 - Ten 9", `        "2179 - Ten 10", `
        "2180 - Ten 11", `
        "2181 - Ten 12")
    If ($Set = "1")
    {        ForEach ($Adapter in $Set1Adapters)
        {            Write-Host " Enabling $Adapter"            Enable-NetAdapter -Name $Adapter
        }
    }
    ElseIf ($Set = "2")    {
        ForEach ($Adapter in $Set2Adapters)
        {
            Write-Host " Enabling $Adapter"            Enable-NetAdapter -Name $Adapter        }
    }    Else    {
        Write-Host "$Set is incorrect. Set it to 1 or 2"
    }
}

Function Disable_Networks
{
    Param(
        [Parameter(Mandatory=$True,Position=1)]
        [string] $Set)
    $Set1Adapters = @("2166 - VM", `
        "2167 - CSV", `
        "2168 - HB", `
        "2169 - MGMT", `        "2170 - Ten 1", `
        "2171 - Ten 2", `
        "2172 - Ten 3", `
        "2173 - Ten 4")
    $Set2Adapters = @("2174 - Ten 5", `
        "2175 - Ten 6", `        "2176 - Ten 7", `
        "2177 - Ten 8", `
        "2178 - Ten 9", `
        "2179 - Ten 10", `        "2180 - Ten 11", `
        "2181 - Ten 12")
    If ($Set = "1")    {
        ForEach ($Adapter in $Set1Adapters)
        {            Write-Host " Disabling $Adapter"            Disable-NetAdapter -Name $Adapter        }    }    ElseIf ($Set = "2")
    {
        ForEach ($Adapter in $Set2Adapters)
        {
            Write-Host " Disabling $Adapter"
            Disable-NetAdapter -Name $Adapter
        }
    }
    Else    {
        Write-Host "$Set is incorrect. Set it to 1 or 2"    }}Function Enable_DHCP
{
    Param(
        [Parameter(Mandatory=$True,Position=1)]
        [string] $Set)
    
    If ($Set = "1")
    {
        Set-NetIPInterface -Dhcp Enabled -InterfaceAlias "2166 - VM"
        Set-NetIPInterface -Dhcp Enabled -InterfaceAlias "2167 - CSV"        Set-NetIPInterface -Dhcp Enabled -InterfaceAlias "2168 - HB"        Set-NetIPInterface -Dhcp Enabled -InterfaceAlias "2169 - MGMT"
        Set-NetIPInterface -Dhcp Enabled -InterfaceAlias "2170 - Ten 1"
        Set-NetIPInterface -Dhcp Enabled -InterfaceAlias "2171 - Ten 2"
        Set-NetIPInterface -Dhcp Enabled -InterfaceAlias "2172 - Ten 3"
        Set-NetIPInterface -Dhcp Enabled -InterfaceAlias "2173 - Ten 4"
    }
    ElseIf ($Set = "2")
    {
        Set-NetIPInterface -Dhcp Enabled -InterfaceAlias "2174 - Ten 5"
        Set-NetIPInterface -Dhcp Enabled -InterfaceAlias "2175 - Ten 6"
        Set-NetIPInterface -Dhcp Enabled -InterfaceAlias "2176 - Ten 7"
        Set-NetIPInterface -Dhcp Enabled -InterfaceAlias "2177 - Ten 8"
        Set-NetIPInterface -Dhcp Enabled -InterfaceAlias "2178 - Ten 9"
        Set-NetIPInterface -Dhcp Enabled -InterfaceAlias "2179 - Ten 10"
        Set-NetIPInterface -Dhcp Enabled -InterfaceAlias "2180 - Ten 11"
        Set-NetIPInterface -Dhcp Enabled -InterfaceAlias "2181 - Ten 12"    }
    Else
    {        Write-Host "$Set is incorrect. Set it to 1 or 2"
    }
}
#Rename_Networks "1"
#Rename_Networks "2"
#Enable_Networks "1"#Enable_Networks "2"
#Disable_Networks "1"#Disable_Networks "2"#Set_IPs "1"
#Set_IPs "2"