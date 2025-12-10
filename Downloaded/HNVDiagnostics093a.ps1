param([System.String]$vmmServer="vmm01.domain2.local",
    [System.Boolean]$UseDefaultCredential = $true,
    [System.Management.Automation.PSCredential]$VMMDBCredential,
    [System.Management.Automation.PSCredential]$VMMServerCredential,
    [System.Management.Automation.PSCredential]$AllHostCredential,
    [System.String]$GatewayService,
    [System.String]$SourceVM,
    [System.String]$DestinationVM)


$HelpMesg = @"

NAME
    HNVDiagnostics

SYNTAX
    HNVDiagnostics.ps1 [-VMMServer <string>] [-UseDefaultCredential <Boolean>] [-VMMServerCredential <PSCredential>]
        [-VMMDBCredential <PSCredential>] [-AllHostCredential <PSCredential>] [-GatewayService <string>]

    HNVDiagnostics.ps1 [-VMMServer <string>] [-UseDefaultCredential <Boolean>] [-VMMServerCredential <PSCredential>]
        [-VMMDBCredential <PSCredential>] [-AllHostCredential <PSCredential>] [-SourceVM <string> [-DestinationVM <string>]]

DESCRIPTION
    VMMServer            : [LocalHost] VMM Server name. If not specified, localhost will be used.

    UseDefaultCredential : [True]. If true, does not prompt for credential to connect to VMM server and host. 
                           Set true if you are the admin of VMM server as well as all the hosts and gateway VMs.
                           If True, uses the credential of the user who runs the script to connect to targets.

    VMMServerCredential  : The credential to be used to connect to VMM server

    VMMDBCredential      : The credential to be used to connect to VMM SQL DB.(No modification done, only read)
                           Will be prompted if not specified.

    AllHostCredential    : The credential to be used to connect to All HyperV hosts and gateway VMs. 
                           Use this parameter if the credential has admin access to all hosts and gateway VMs 
                           and not same as the user running the powershell. 
                           If the admin credential varies per host, do not specify this parameter. 
                           If not specified, You will be prompted for credential.

    GatewayService       : Name of the gateway network service to be diagnosed.

    SourceVM             : Source VM Name from which connectivity has to be tested. 
                           If destinationVM is not specified, connectivity with gateway will be tested

    DestinationVM        : Destination VM Name to test connectivity from source VM

EXAMPLES
    If your account has administrator access to all hosts and VMs, just run the script without any parameter. 
    The script will prompt and walk you through the options. If your credential does not have permission, then

        HNVDiagnostics.ps1 -UseDefaultCredential `$false


    To diagnose if the HNV multi-tenant gateway has been setup correctly, run the following command

        HNVDiagnostics.ps1 -VMMDBCredential `$cred  -gatewayservice "GatewayNetworkService1"


    To diagnose connectivity problem between VM and gateway, run the following

        HNVDiagnostics.ps1 -VMMDBCredential `$cred  -sourcevm VMNameConnectedToGw


    To diagnose connectivity problem between two VMs connected in HNV network

        HNVDiagnostics.ps1 -VMMDBCredential `$cred  -sourcevm VMName1 -destinationvm VMName2
        
"@


#======================
# Editable start
#======================

$pingSuccessMatchingDictionary = @{ "0409" = "TTL="}

$httpWsmanPort  = 5985
$httpsWsmanPort = 5986


#======================
# Editable end
#======================

$ipSubnetSource = @"

using System;
using System.Net;
using System.Net.Sockets;

namespace HNVDiagnostics
{
    public class IPSubnet
    {
        System.Net.IPAddress networkAddress;
        int prefixLength;
        System.Net.IPAddress networkMask;

        public int PrefixLength
        {
            get { return this.prefixLength; }
        }

        public IPSubnet(
            IPAddress ipAddress,
            int prefixMaskLength)
        {
            this.Initialize(ipAddress, prefixMaskLength);
        }

        public IPSubnet(string networkAddress, int prefix)
            : this(IPAddress.Parse(networkAddress), prefix)
        {
        }

        private void Initialize(
            IPAddress ipAddress,
            int prefixLength)
        {

            ValidatePrefixLength(prefixLength, ipAddress.AddressFamily);

            this.prefixLength = prefixLength;
            this.networkMask = IPSubnet.NetworkMaskFromPrefixLength(ipAddress.AddressFamily, this.prefixLength);
            this.networkAddress = IPSubnet.CalculateNetworkAddress(ipAddress, networkMask);
        }

        private static void ValidatePrefixLength(
            int prefixLength,
            AddressFamily addressFamily)
        {
            // validate the prefix length size
            // We initialize the prefixes to values that will
            // always fail so new address families need to add a case
            // statement
            int minSubnetPrefixLength = -1;
            int maxSubnetPrefixLength = -2;

            switch (addressFamily)
            {
                case AddressFamily.InterNetwork:
                    minSubnetPrefixLength = 0;
                    maxSubnetPrefixLength = 32;
                    break;
                case AddressFamily.InterNetworkV6:
                    minSubnetPrefixLength = 0;
                    maxSubnetPrefixLength = 128;
                    break;
            }

            if (prefixLength < minSubnetPrefixLength ||
                prefixLength > maxSubnetPrefixLength)
            {
                throw new Exception("Invalid Subnet prefix length");
            }
        }

        private static IPAddress CalculateNetworkAddress(
            IPAddress ipAddress,
            IPAddress networkMask)
        {
            byte[] subnetIPBytes = new byte[ipAddress.AddressFamily == AddressFamily.InterNetwork ? 4 : 16];

            byte [] ipAddrBytes = ipAddress.GetAddressBytes();
            byte [] maskBytes   = networkMask.GetAddressBytes();

            for (int ndx = 0; ndx < ipAddrBytes.Length; ndx++)
            {
                subnetIPBytes[ndx] = (byte)(ipAddrBytes[ndx] & maskBytes[ndx]);
            }

            return new IPAddress(subnetIPBytes);
        }

        private static IPAddress NetworkMaskFromPrefixLength(AddressFamily addressFamily, int prefixLength)
        {
            byte[] networkMask = new byte[addressFamily == AddressFamily.InterNetwork ? 4 : 16];

            for(int lengthRemaining = prefixLength, ndx = 0; lengthRemaining > 0; lengthRemaining -= 8, ndx++)
            {
                int bitsToBeSet = lengthRemaining > 8 ? 8 : lengthRemaining;

                networkMask[ndx] = (byte)(~((1 << (8 - bitsToBeSet)) - 1) & 0xFF);
            }

            return new IPAddress(networkMask);
        }

        public bool IsValidAddress(IPAddress ipAddress)
        {
            if (ipAddress.AddressFamily != this.networkAddress.AddressFamily)
            {
                return false;
            }

            byte [] ipAddrBytes = ipAddress.GetAddressBytes();
            byte [] maskBytes   = this.networkMask.GetAddressBytes();
            byte [] subnetBytes = this.networkAddress.GetAddressBytes();
            for (int ndx = 0; ndx < ipAddrBytes.Length; ndx++)
            {
                if (subnetBytes[ndx] != (byte)(ipAddrBytes[ndx] & maskBytes[ndx]))
                {
                    return false;
                }
            }

            return true;
        }

        public bool IsValidAddress(string ipAddress)
        {
            return this.IsValidAddress(IPAddress.Parse(ipAddress));
        }

        public static IPSubnet Parse(string ipAddress, string prefixLength)
        {
            return new IPSubnet(IPAddress.Parse(ipAddress), int.Parse(prefixLength));
        }

        public static IPSubnet Parse(string ipAddress, int prefixLength)
        {
            return new IPSubnet(IPAddress.Parse(ipAddress), prefixLength);
        }

        public static IPSubnet Parse(string subnet)
        {
            string[] array = subnet.Split('/');
            if (array.Length != 2)
            {
                throw new ArgumentException("Subnet does not have two parts separated by /");
            }
            return Parse(array[0], array[1]);
        }

        public static bool Parse(string subnet, out IPSubnet ipSubnet)
        {
            ipSubnet = null;
            try
            {
                ipSubnet = Parse(subnet);
                return true;
            }
            catch (Exception)
            {
                return false;
            }
        }
        
        public static IPAddress IncrementIPAddress(IPAddress address)
        {
            byte[] subnetIP = address.GetAddressBytes();

            bool hasCarry = true;
            for (int ndx = subnetIP.Length - 1; ndx >= 0 && hasCarry; ndx--)
            {
                subnetIP[ndx]++;
                hasCarry = subnetIP[ndx] == 0;
            }

            return new IPAddress(subnetIP);
        }

        public IPAddress GetFirstIPAddress()
        {
            return IncrementIPAddress(this.networkAddress);
        }

        
        public override string ToString()
        {
            return this.networkAddress.ToString() + "/" + this.prefixLength.ToString();
        }
    }
}
"@

$global:PSSession = $null

$activeVMMServerName = $vmmServer

$deserializer = @"
using System;
using System.Net;
using System.Net.Sockets;
using System.Collections.Generic;
using Microsoft.SystemCenter.DataCenterManager.NetworkService.WindowsRemoteServerPlugin;

namespace HNVDiagnostics
{
    public class Deserializer
    {
        public static List<HostPAMetadata> GetAllHostPAMetadata(byte[] buffer)
        {
            return PluginUtils.DeserializeDataContract<List<HostPAMetadata>>(buffer);
        }
    }
}

"@


ipmo 'virtualmachinemanager\virtualmachinemanager.psd1'

$version = "0.93a"

$MaxThreads = 5
$RunspacePool = [RunspaceFactory ]::CreateRunspacePool(1, $MaxThreads)
$RunspacePool.Open()


Add-Type -TypeDefinition $ipSubnetSource -Language CSharp

$statusPrimaryColor = "Green"
$statusSecondaryColor = "DarkGreen"
$errorColor  = "Red"
$choiceColor = "Yellow"
$promptColor = "Cyan"
$operationColor = "DarkCyan"
$warningColor = $choiceColor

Write-Host -ForegroundColor $choiceColor "=============================================================================================="
Write-Host -ForegroundColor $choiceColor "HNV gateway diagnostic tool version $version"
Write-Host -ForegroundColor $choiceColor "=============================================================================================="
Write-Host -ForegroundColor $choiceColor $HelpMesg
Write-Host -ForegroundColor $choiceColor "=============================================================================================="

function ExitScript($message)
{
    Write-Host ""
    Write-Host -ForegroundColor $errorColor "=============================================================================================="
    Write-Host -ForegroundColor $errorColor  $message
    Write-Host -ForegroundColor $errorColor "=============================================================================================="

    throw $message
}

function GetCredentialFromUser($userName)
{
    $cred = $null
    $exitLoop = $false
    do
    {
        $exitLoop = $true

        $cred = Get-Credential $userName

        if( $cred -eq $null )
        {
            ExitScript "User cancelled"
        }

        if( -not (Test-SCDomainCredential -Credential $cred) )
        {
            $choice = PromptMenu2 "Credential not valid" @("Re-enter Credential")  "Continue (non-domain credential)" $true

            if( ($choice -isnot [System.String] -or $choice.Length -ne 0) -and $choice -ne 0)
            {
                $exitLoop = $false
            }

            $userName = $cred.UserName
        }
    }
    while( -not $exitLoop)

    return $cred
}

$global:credentialList = @()
$global:credentialMap =  New-Object -TypeName "System.Collections.Generic.Dictionary``2[string,object]" ([System.StringComparer]::OrdinalIgnoreCase)
function GetCredential($compName, $mustEnterCredential)
{
    if( $compName -ne "VMM DB Admin" -and $compName -ne "VMM Server" -and $AllHostCredential -ne $null)
    {
        return $AllHostCredential
    }

    if( -not $global:credentialMap.ContainsKey($compName) )
    {
        $cred = $null

        if( -not $useDefaultCredential -or ($mustEnterCredential -eq $true))
        {
            $promptList = @()
            foreach($cred in $global:credentialList)
            {
                $promptList += $cred.UserName
            }

            $choice = $null

            if($mustEnterCredential -eq $true)
            {
                $choice = PromptMenu2 "Select credential for host $compName" $promptList  "New Credential (enter or type user name)" $true

                if( $choice -is [System.String] -or $choice -eq 0)
                {
                    if( $choice -eq 0 )
                    {
                        $choice = ""
                    }
                    $cred = GetCredentialFromUser $choice
                
                    $global:credentialList += $cred
                }
                else
                {
                    $cred = $credentialList[$choice-1]
                }
            }
            else
            {
                $promptList += "New Credential (or type user name)"

                $choice = PromptMenu2 "Select credential for host $compName" $promptList  "Default Credential (Just Enter)" $true

                if( $choice -is [System.String])
                {
                    if( $choice.Length -ne 0 )
                    {

                        $cred = GetCredentialFromUser $choice
                
                        $global:credentialList += $cred
                    }
                }
                else
                {
                    if( $choice -ne 0 )
                    {
                        if( $choice -eq $credentialList.Length+1 )
                        {
                            $cred = GetCredentialFromUser ""
                            $global:credentialList += $cred
                        }
                        else
                        {
                            $cred = $credentialList[$choice-1]
                        }
                    }
                }
            }
        }

        $global:credentialMap.Add($compName, $cred)
    }

    return $global:credentialMap[$compName]

}

function AddCredential($hostName, $cred)
{
    if( $cred -ne $null )
    {
        $found = $false
        foreach($credInStore in $global:credentialList)
        {
            if( $cred.UserName -eq $credInStore.UserName )
            {
                $found = $true
            }
        }

        if( -not $found )
        {
            $global:credentialList += $cred
        }

        if( $global:credentialMap.ContainsKey($hostName) )
        {
            $global:credentialMap[$hostName] = $cred
        }
        else
        {
            $global:credentialMap.Add($hostName, $cred)
        }
    }
}

$global:cimSessionMap =  New-Object -TypeName "System.Collections.Generic.Dictionary``2[string,Object]" ([System.StringComparer]::OrdinalIgnoreCase)
function GetCimSession($hostObj, $trustedHost, $copyFromHost)
{
    $hostName = $null
    if( $hostObj -is [System.String] )
    {
        $hostName = $hostObj
    }
    else
    {
        $hostName = $hostObj.Name
        if( $trustedHost -eq $null)
        {
            $trustedHost = -not $hostObj.NonTrustedDomainHost
        }
    }

    if( $trustedHost -eq $null )
    {
        $trustedHost = $true
    }

    if(-not $global:cimSessionMap.ContainsKey($hostName) )
    {
        $cred = $null

        if( $copyFromHost -ne $null)
        {
            $cred = GetCredential $copyFromHost
            AddCredential $hostName $cred
        }
        else
        {
            $cred = GetCredential $hostObj
        }
        
        $wsmanSessionOption = New-CimSessionOption -Protocol Wsman

        if( $trustedHost )
        {
            if( $cred -ne $null )
            {
                $cimSession = New-CimSession -ComputerName $hostName -Authentication Negotiate -Credential $cred -SessionOption $wsmanSessionOption -Port $httpWsmanPort
            }
            else
            {
                $cimSession = New-CimSession -ComputerName $hostName -Authentication Negotiate -SessionOption $wsmanSessionOption -Port $httpWsmanPort
            }
        }
        else
        {
            if( $cred -ne $null )
            {
                $cimSession = New-CimSession -ComputerName $hostName -Authentication Negotiate -Credential $cred -SessionOption $wsmanSessionOption -Port $httpsWsmanPort
            }
            else
            {
                $cimSession = New-CimSession -ComputerName $hostName -Authentication Negotiate -SessionOption $wsmanSessionOption -Port $httpsWsmanPort
            }
        }
        
        if( $cimSession -eq $null )
        {
            $credentialDescription = "default credential"

            if( $cred -ne $null )
            {
                $credentialDescription = $cred.UserName
            }

            ExitScript ("Unable to get Cim Session to host "+$hostName +" using credential "+$credentialDescription+". Ensure host is running and the crendential has permission. If default credential does not have access, specify -UseDefaultCredential `$false")
        }

        $global:cimSessionMap.Add($hostName, $cimSession)
    }

    return $global:cimSessionMap[$hostName]
}


function GetVmmDbPsSession()
{
    if( $global:PSSession -eq $null )
    {
        $credential = GetCredential "VMM DB Admin" $true
        $session = $null

        if( $credential -eq $null)
        {
            $session = New-PSSession -ComputerName $activeVMMServerName
        }
        else
        {
            $session = New-PSSession -ComputerName $activeVMMServerName -Credential $credential -Authentication Credssp
        }

        if( $session -eq $null )
        {
            ExitScript "VMM DB credential does not have permission to login to VMM Server or remote powershell is not enabled on the VMM server"
        }

        $installPath = Invoke-Command  -Session $session  -ScriptBlock { (Get-ItemProperty "hklm:\SOFTWARE\Microsoft\Microsoft System Center Virtual Machine Manager Server\Setup").Installpath}

        $res = Invoke-Command -Session $session -ScriptBlock { Import-Module "$args\bin\imglibengine.dll"} -ArgumentList $installPath

        $res = Invoke-Command -Session $session -ScriptBlock { Import-Module "$args\bin\NetworkServiceInterfaces.dll"} -ArgumentList $installPath

        $res = Invoke-Command -Session $session -ScriptBlock { Import-Module "$args\bin\Configuration Providers\WindowsRemoteServerPlugin\WindowsRemoteServerPlugin.psd1"} -ArgumentList $installPath

        $res = Invoke-Command -Session $session -ScriptBlock { $conn = New-Object Microsoft.VirtualManager.DB.SqlContext; $conn.Open() }

        $res = Invoke-Command -Session $session -ScriptBlock { 
                $pluginPath = ($args[0]) + "\bin\Configuration Providers\WindowsRemoteServerPlugin\WindowsRemoteServerPlugin.dll"
                Add-Type -TypeDefinition $args[1] -Language CSharp -ReferencedAssemblies $pluginPath

                $pluginPath
            } -ArgumentList $installPath,$deserializer


        $res = Import-Module ($installPath + "\bin\imglibengine.dll")
        $res = Import-Module ($installPath + "\bin\NetworkServiceInterfaces.dll")
        $res = Import-Module ($installPath + "\bin\Configuration Providers\WindowsRemoteServerPlugin\WindowsRemoteServerPlugin.psd1")
        $res = Add-Type -TypeDefinition $deserializer -Language CSharp -ReferencedAssemblies ($installPath + "\bin\Configuration Providers\WindowsRemoteServerPlugin\WindowsRemoteServerPlugin.dll")

        $global:PSSession = $session
    }

    return $global:PSSession
}


function GetNSMetaData($networkService, $metaDataID)
{
    $result = Invoke-Command -Session (GetVmmDbPsSession) -ScriptBlock { [Microsoft.VirtualManager.DB.NetworkManagement.NetworkServiceMetadataDBAccess]::GetByMetadataIdNetworkServiceId($conn, $args[0], $args[1]) } -ArgumentList $metaDataID, $networkService.ID

    if( $result -ne $null -and $result.MetadataBytes.Length -gt 0 )
    {
        return $result[0].MetadataBytes
    }

    return $null
}

function GetHostPAMetadata($networkService)
{
    $hostPAMetaDataId = [system.guid]::Parse("FF05D31A-5F1A-46D6-A682-27F79464d2FB")

    $encodedData = GetNSMetaData $networkService $hostPAMetaDataId

    if( $encodedData -ne $null )
    {
        $result = Invoke-Command -Session (GetVmmDbPsSession) -ScriptBlock { $paMeta = [HNVDiagnostics.Deserializer]::GetAllHostPAMetadata($args) } -ArgumentList $encodedData
        $result = @(Invoke-Command -Session (GetVmmDbPsSession) -ScriptBlock { $paMeta  })

        for($ndx = 0; $ndx -lt $result.Length; $ndx++ )
        {
            $result[$ndx].ProviderAddresses = @(Invoke-Command -Session (GetVmmDbPsSession) -ScriptBlock { $paMeta[$args].ProviderAddresses } -ArgumentList $ndx)

            for($ndx2 = 0; $ndx2 -lt $result[$ndx].ProviderAddresses.Length; $ndx2++)
            {
                $result[$ndx].ProviderAddresses[$ndx2].PAGateway =  @(Invoke-Command -Session (GetVmmDbPsSession) -ScriptBlock { $paMeta[$args[0]].ProviderAddresses[$args[1]].PAGateway } -ArgumentList $ndx,$ndx2)
            }
        }

        return $result

                    
    }
    else
    {
        return $null
    }
}

function GetOnlinkAddress($vmNetwork)
{
    if( $vmNetwork.CAIPAddressPoolType -eq "IPV4" )
    {
        return "0.0.0.0"
    }
    else
    {
        return "::"
    }
}

function GetTempPAAddress($vmNetwork)
{
    if( $vmNetwork.PAIPAddressPoolType -eq "IPV4" )
    {
        return "1.1.1.1"
    }
    else
    {
        return "1111::1111"
    }
}

function GetGatewayDestinationPrefix($vmNetwork)
{
    if( $vmNetwork.CAIPAddressPoolType -eq "IPV4" )
    {
        return "0.0.0.0/0"
    }
    else
    {
        return "::/0"
    }
}



function PromptMenu2($menuTitle, $menuItems, $defaultStr, $allowStrInput)
{
    Write-Host -ForegroundColor $promptColor $menuTitle

    Write-Host -ForegroundColor $choiceColor "     0 .  $defaultStr"

    for($i = 0; $i -lt $menuItems.Length; $i++ )
    {
        Write-Host -ForegroundColor $choiceColor "    " ($i+1) ". " $menuItems[$i]
    }


    $selection = $null
    $parseResult = $null
    do
    {
        Write-Host -ForegroundColor $promptColor -NoNewline " > "
        $selectionTxt = Read-Host     
        
        $parseResult =  [System.Int32]::TryParse($selectionTxt, [ref] $selection)
    }
    while((-not $parseResult  -or $selection -lt 0 -or $selection -gt $menuItems.Length) -and -not $allowStrInput )

    if( $parseResult )
    {
        return $selection
    }
    else
    {
        return $selectionTxt
    }
}


function PromptMenu($menuTitle, $menuItems)
{
    PromptMenu2 $menuTitle $menuItems "Exit" $false
}

function SelectVMFromList($vmObjects)
{
    $menuVms = @()

    foreach($vm in $vmObjects)
    {
        $menuVms += "Host="+ $vm.HostName +".  Description="+$vm.Description+". ID="+$vm.ID
    }

    $vmSelection = PromptMenu "Select VM" $menuVms

    if($vmSelection -eq 0 )
    {
        return $null
    }
    else
    {
        return $vmObjects[$vmSelection - 1]     
    }
}


function GetVM($vmName)
{
    $vmObj = $null
    do
    {
        if( $vmName -eq $null -or $vmName.Length -eq 0 )
        {
            write-host -ForegroundColor $promptColor -NoNewline "VM Name : "
            $vmName = Read-Host 
        }

        $vmObj = Get-SCVirtualMachine -Name $vmName

        $vmName = $null
    }
    while($vmObj -eq $null -or ($vmObj -is [System.Array] -and $vmObj.Length -eq 0))

    if( $vmObj -is [System.Array] -and $vmObj.Length -gt 1 )
    {
        Write-Host -ForegroundColor $errorColor More than One VM found with the given name.
        $vmObj = SelectVMFromList $vmObj
    }

    return $vmObj
}


function SelectVNicFromList($vnicObjects)
{
    $ndx = 1
    
    $vnicObjects | ForEach-Object { New-Object -TypeName pscustomobject -Property @{
        Index  = $ndx++
        ID    = $_.ID
        VMSubnet = $_.VMSubnet
        VMNetwork = $_.VMNetwork
        }
        } | write-host


     $indexStr = $null
     $index = $null
     do
     {
        write-host -ForegroundColor $promptColor -NoNewline "Select the VNIC Index : "
        $indexStr = Read-Host
     }
     while(-not ([System.Int32]::TryParse($indexStr, [ref] $index) -and $index -gt 0 -and $index -le $vnicObjects.Length))

     return $vnicObjects[$index - 1]     
}

function GetHNVAdapter($vm)
{
    $hnvAdapters = @()
    foreach($adapter in $vm.VirtualNetworkAdapters)
    {
        if( $adapter.VMNetwork -ne $null -and $adapter.VMNetwork.IsolationType -eq [Microsoft.VirtualManager.Remoting.VMNetworkType]::WindowsNetworkVirtualization)
        {
            $hnvAdapters += $adapter
        }
    }

    if( $hnvAdapters.Count -eq 0 )
    {
        throw "No Adapters found that is connected to HNV"
    }
    else
    {
        if( $hnvAdapters.Count -gt 1 )
        {
            return SelectVNicFromList($hnvAdapters)
        }
        else
        {
            return $hnvAdapters[0]
        }
    }
}


function SelectIPFromList($ipaddresses)
{
    $ndx = 1
    
    $ipaddresses | ForEach-Object { New-Object -TypeName pscustomobject -Property @{
        Index  = $ndx++
        ID    = $_.ID
        Address = $_.Address
        }
        } | write-host


     $indexStr = $null
     $index = $null
     do
     {
        write-host -ForegroundColor $promptColor -NoNewline "Select the IP Index : "
        $indexStr = Read-Host
     }
     while(-not ([System.Int32]::TryParse($indexStr, [ref] $index) -and $index -gt 0 -and $index -le $ipaddresses.Length))

     return $ipaddresses[$index - 1]     
}

function GetHNVIPAddress($hnvAdap)
{
    $ipaddresses = @()

    foreach($ip in ( Get-SCIPAddress -GrantToObjectID $hnvAdap.ID ))
    {
        if( $ip.AllocatingAddressPool.VMSubnet -ne $null -and $ip.AllocatingAddressPool.VMSubnet.ID -eq $hnvAdap.VMSubnet.ID )
        {
          $ipaddresses += $ip
        }
    }

    if( $ipaddresses.Count -eq 0 )
    {
        throw "No IP Address found that is connected to HNV"
    }
    else
    {
        if( $ipaddresses.Count -gt 1 )
        {
            return SelectIPFromList($ipaddresses)
        }
        else
        {
            return $ipaddresses[0]
        }
    }
}


function GetAllLookupRecordsForVMSubnet($vmSubnet)
{
    Write-Host -ForegroundColor $operationColor Calculating Lookup records for VMNetwork : $vmSubnet.VMNetwork.Name, VMSubnet : $vmSubnet.name
    $allAdapters = Get-SCVirtualNetworkAdapter -All | where {$_.VMSubnet.ID -eq $vmSubnet.ID}

    $results = @()

    $rdid = $vmSubnet.VMNetwork.RoutingDomainID.ToString("B")

    foreach($vNic in $allAdapters)
    {
        $ipAddrAllocated = $null
        # find the ip address
        foreach($ipAddr in (Get-SCIPAddress -GrantToObjectID $vNic.ID))
        {
            if( $ipAddr.AllocatingAddressPool.VMSubnet -ne $null -and $ipAddr.AllocatingAddressPool.VMSubnet.ID -eq $vmSubnet.ID)
            {
                $ipAddrAllocated = $ipAddr.Address
            }
        }

        if( $ipAddrAllocated -ne $null )
        {
            $results += New-Object -TypeName PSCustomObject -Property @{
                CustomerAddress       = $ipAddrAllocated
                MacAddress      = $vNic.MACAddress.Replace(":","")
                VirtualSubnetID = $vmSubnet.VMSubnetID
                ProviderAddress       = $null
                CustomerID    = $rdid
            }
        }
    }

    return $results
}

function GetWildCardLookupRecordsForVMSubnet ($vmSubnet, $isIpv4Pa)
{
    $results = @()

    $vmSubnetObj = [HNVDiagnostics.IPSubnet]::Parse($vmSubnet.SubnetVLans[0].Subnet)
    
    $rdid = $vmSubnet.VMNetwork.RoutingDomainID.ToString("B")

    $results += New-Object -TypeName PSCustomObject -Property @{
                CustomerAddress       = $vmSubnetObj.GetFirstIPAddress()
                MacAddress      = $null
                VirtualSubnetID = $vmSubnet.VMSubnetID
                ProviderAddress       = GetTempPAAddress($vmSubnet.VMNetwork)
                CustomerID    = $rdid
            }

    $results += New-Object -TypeName PSCustomObject -Property @{
                CustomerAddress       = "192.0.2.253"
                MacAddress      = $null
                VirtualSubnetID = $vmSubnet.VMSubnetID
                ProviderAddress       = $null
                CustomerID    = $rdid
            }

    return $results
}

function GetGatewayLookupRecords($VMNetwork, $gwInfo, $isIpv4Pa)
{
    $results = @()

    $rdid = $VMNEtwork.RoutingDomainID.ToString("B")

    if( $gwInfo -ne $null)
    {
        Write-Host -ForegroundColor $operationColor Calculating Lookup records for VMNetwork : $VMNetwork.Name for gateway

        if( $isIpv4Pa )
        {
            $results += New-Object -TypeName PSCustomObject -Property @{
                        CustomerAddress       = $gwInfo.gwAddr.IPAddressToString
                        MacAddress      = $gwInfo.gwMacAddress.Replace(":","")
                        VirtualSubnetID = $gwInfo.gwVSID
                        ProviderAddress       = $gwInfo.gwPaIPv4
                        CustomerID    = $rdid
                    }
        }
        else
        {
            $results += New-Object -TypeName PSCustomObject -Property @{
                        CustomerAddress       = $gwInfo.gwAddr.IPAddressToString
                        MacAddress      = $gwInfo.gwMacAddress.Replace(":","")
                        VirtualSubnetID = $gwInfo.gwVSID
                        ProviderAddress       = $gwInfo.gwPaIPv6
                        CustomerID    = $rdid
                    }
        }
    }

    return $results
}

function GetGatewayLookupRecordsForHost($vmSubnet, $gwInfo, $isIpv4Pa)
{
    $results = @()

    #add wild card for return path
    #$results += New-Object -TypeName PSCustomObject -Property @{
    #                CustomerAddress       = GetOnlinkAddress($vmSubnet.VMnetwork)
    #                MacAddress      = $null
    #                VirtualSubnetID = $vmSubnet.VMSubnetID
    #                ProviderAddress       = $null
    #            }

    return $results
}

function IsMatchingLR($lr1, $lr2)
{
    $match = $lr1.CustomerID.ToLower() -eq $lr2.CustomerID.ToLower()
    if( $lr1.CustomerAddress -ne $null )
    {
        $match = $match -and ($lr1.CustomerAddress -eq $lr2.CustomerAddress)
    }

    if($lr1.MacAddress -ne $null )
    {
        $match = $match -and ($lr1.MacAddress.ToLower() -eq $lr2.MacAddress.ToLower())
    }

    if($lr1.VirtualSubnetID -ne $null )
    {
        $match = $match -and ($lr1.VirtualSubnetID -eq $lr2.VirtualSubnetID)
    }

    if($lr1.ProviderAddress -ne $null )
    {
        $match = $match -and ($lr1.ProviderAddress -eq $lr2.ProviderAddress)
    }

    return $match
}

function CheckLRsPresent ($expectedHostLookupRecords, $hostLRs, [ref] $policyOk)
{
    $policyOk.Value = $true
    $notFoundLRs = @()
    Write-Host -ForegroundColor $operationColor Matching calcuated lookup records against lookup records in host
    foreach($expectedLR in $expectedHostLookupRecords)
    {
        if( $expectedLR.CustomerID -eq $null )
        {
            write-host -ForegroundColor $errorColor "DEBUG: Records missing RDID"
        }

        $found = $false
        foreach($hostLR in $hostLRs)
        {
            if( IsMatchingLR $expectedLR $hostLR )
            {
                $found = $true
                break
            }
        }

        if( -not $found )
        {
            $notFoundLRs += $expectedLR
        }
    }

    if($notFoundLRs.Length -gt 0 )
    {
        Write-Host -ForegroundColor $errorColor Lookup records missing in host
        $notFoundLRs | ft CustomerAddress, MacAddress, ProviderAddress, VirtualSubnetID
        $policyOk.Value = $false
    }
    else
    {
        Write-Host -ForegroundColor $statusPrimaryColor Lookup records matching in host
        $policyOk.Value = $true
    }
}

function ValidateLookupRecordsVMHost($adapInfo, [ref]$policyOk, [ref]$vmPAAddr, [ref]$PAsInVMNetwork)
{
    $policyOk.Value = $true

    Write-Host -ForegroundColor $operationColor Calculating Lookup records for VMNetwork : $adapInfo.hnvAdap.vmSubnet.VMNetwork.Name

    $lookupRecordList = @()

    $hostLookupRecords = @()

    foreach($vmSubnetTemp in $adapInfo.hnvAdap.VMNetwork.VMSubnet)
    {
        $lookupRecordList += GetAllLookupRecordsForVMSubnet $vmSubnetTemp
    }

    $lookupRecordList += GetGatewayLookupRecords $adapInfo.hnvAdap.VMNetwork $gwInfo ($adapInfo.hnvAdap.VMNetwork.PAIPAddressPoolType -eq "IPV4")

    $expectedHostLookupRecords += $lookupRecordList

    $expectedHostLookupRecords += GetWildCardLookupRecordsForVMSubnet $adapInfo.hnvAdap.vmSubnet ($adapInfo.hnvAdap.vmSubnet.VMNetwork.PAIPAddressPoolType -eq "IPV4")

    $expectedHostLookupRecords += GetGatewayLookupRecordsForHost $adapInfo.hnvAdap.vmSubnet $gwInfo ($adapInfo.hnvAdap.vmSubnet.VMNetwork.PAIPAddressPoolType -eq "IPV4")

    Write-Host -ForegroundColor $statusPrimaryColor Expected lookup records on the host $adapInfo.vm.VMHost.Name
    $expectedHostLookupRecords | ft CustomerAddress, MacAddress, ProviderAddress, VirtualSubnetID

    $hostLRs = Get-NetVirtualizationLookupRecord -CimSession (GetCimSession $adapInfo.vm.VMHost) -CustomerID $adapInfo.hnvAdap.vmSubnet.VMNetwork.RoutingDomainId.ToString("B")
    Write-Host -ForegroundColor $statusSecondaryColor Found lookup records on the host $adapInfo.vm.VMHost.Name

    $hostLRs | ft CustomerAddress, MacAddress, ProviderAddress, VirtualSubnetID

    $vmPAAddr.Value = $null
    $vmPAAddrRecord = $hostLRs | where {$_.CustomerAddress -eq $adapInfo.ipAddr}
    if($vmPAAddrRecord -ne $null )
    {
        $vmPAAddr.Value = $vmPAAddrRecord.ProviderAddress
    }

    $allPAs = @()
    foreach($hostLR in $hostLRs)
    {
        if( $hostLR.ProviderAddress -ne (GetTempPAAddress $adapInfo.hnvAdap.VMNetwork) -and -not $allPAs.Contains($hostLR.ProviderAddress) )
        {
            $allPAs += $hostLR.ProviderAddress
        }
    }

    $PAsInVMNetwork.Value = $allPAs
    CheckLRsPresent $expectedHostLookupRecords $hostLRs -policyOk $policyOk
}

function IsMatchingCR($cr1, $cr2)
{
    $match = $true
    if( $cr1.RoutingDomainID -ne $null )
    {
        $match = $cr1.RoutingDomainID.ToLower() -eq $cr2.RoutingDomainID.ToLower()
    }

    if($cr1.DestinationPrefix -ne $null )
    {
        $match = $match -and $cr1.DestinationPrefix.ToString() -eq $cr2.DestinationPrefix
    }

    if($cr1.NextHop -ne $null )
    {
        $match = $match -and $cr1.NextHop -eq $cr2.NextHop
    }

    if($cr1.VirtualSubnetID -ne $null )
    {
        $match = $match -and $cr1.VirtualSubnetID -eq $cr2.VirtualSubnetID
    }

    return $match
}

function CheckCRsPresent($expectedHosCRs, $hostCRs, [ref] $policyOk)
{
    $policyOk.Value = $true

    $notFoundCRs = @()
    Write-Host -ForegroundColor $operationColor Matching calcuated Route records against Route records in host
    foreach($expectedCR in $expectedHosCRs)
    {
        $found = $false
        foreach($hostCR in $hostCRs)
        {
            if( IsMatchingCR $expectedCR $hostCR )
            {
                $found = $true
                break
            }
        }

        if( -not $found )
        {
            $notFoundCRs += $expectedCR
        }
    }

    if($notFoundCRs.Length -gt 0 )
    {
        Write-Host -ForegroundColor $errorColor Route records missing in host
        $notFoundCRs | ft DestinationPrefix, NextHop, VirtualSubnetID, RoutingDomainID 
        $policyOk.Value = $false
    }
    else
    {
        Write-Host -ForegroundColor $statusPrimaryColor Route records matching in host
        $policyOk.Value = $true
    }
}

function ValidateCustomerRouteRecordsVMHost($adapInfo, $gwInfo, [ref] $policyOk)
{
    $policyOk.Value = $true
    Write-Host -ForegroundColor $operationColor Calculating Route records for VMNetwork : $adapInfo.hnvAdap.vmSubnet.VMNetwork.Name, VMSubnet : $adapInfo.hnvAdap.vmSubnet.Name

    $expectedCRs = @()

    foreach($vmSubnetTemp in $adapInfo.hnvAdap.vmSubnet.VMNetwork.VMSubnet)
    {
        if( $vmSubnetTemp.ID -ne $vmSubnet.ID )
        {
            $expectedCRs +=  New-Object -TypeName PSCustomObject -Property @{
                        RoutingDomainID       = $adapInfo.hnvAdap.VMNetwork.RoutingDomainID.ToString("B")
                        DestinationPrefix =   $vmSubnetTemp.SubnetVLans[0].Subnet 
                        NextHop       = GetOnlinkAddress($adapInfo.hnvAdap.VMNetwork)
                        VirtualSubnetID = $vmSubnetTemp.VMSubnetID
                    }
        }
        else
        {
            $expectedCRs +=  New-Object -TypeName PSCustomObject -Property @{
                        RoutingDomainID       = $adapInfo.hnvAdap.VMNetwork.RoutingDomainID.ToString("B")
                        DestinationPrefix =   $vmSubnetTemp.SubnetVLans[0].Subnet 
                        NextHop       = GetOnlinkAddress($adapInfo.hnvAdap.VMNetwork)
                        VirtualSubnetID = $vmSubnetTemp.VMSubnetID
                    }
        }
    }

    #add gw route
    if( $gwInfo -ne $null )
    {
        $expectedCRs +=  New-Object -TypeName PSCustomObject -Property @{
                            RoutingDomainID       = $adapInfo.hnvAdap.VMNetwork.RoutingDomainID.ToString("B")
                            DestinationPrefix =   GetGatewayDestinationPrefix($adapInfo.hnvAdap.VMNetwork)
                            NextHop       = $gwInfo.gwAddr.ToString()
                            VirtualSubnetID = $gwInfo.gwVSID
                        }
    }

    $hostCRs = Get-NetVirtualizationCustomerRoute -CimSession (GetCimSession $adapInfo.vm.VMHost) -RoutingDomainID $adapInfo.hnvAdap.vmSubnet.VMNetwork.RoutingDomainId.ToString("B")

    Write-Host -ForegroundColor $statusPrimaryColor Expected Route records on the host $adapInfo.vm.VMHost.Name
    $expectedCRs | ft DestinationPrefix, NextHop, VirtualSubnetID, RoutingDomainID

    Write-Host -ForegroundColor $statusSecondaryColor Found Route records on the host $adapInfo.vm.VMHost.Name
    $hostCRs | ft DestinationPrefix, NextHop, VirtualSubnetID, RoutingDomainID

    CheckCRsPresent $expectedCRs $hostCRs -policyOk $policyOk
}

function IsMatchingPA($pa1, $pa2)
{
    $match = $true
    if( $pa1.ProviderAddress -ne $null )
    {
        $match = $pa1.ProviderAddress -eq $pa2.ProviderAddress
    }

    if($pa1.PrefixLength -ne $null )
    {
        $match = $match -and $pa1.PrefixLength -eq $pa2.PrefixLength
    }

    if($pa1.VlanID -ne $null )
    {
        $match = $match -and $pa1.VlanID -eq $pa2.VlanID
    }

    if($pa1.ManagedByCluster -ne $null )
    {
        $match = $match -and $pa1.ManagedByCluster -eq $pa2.ManagedByCluster
    }

    return $match
}

function CheckPAsPresent($expectedHosPAs, $hostPAs, [ref] $policyOk)
{
    $policyOk.Value = $true

    $notFoundPAs = @()
    Write-Host -ForegroundColor $operationColor Matching calcuated Provider Addresses against Provider Addresses in host
    foreach($expectedPA in $expectedHosPAs)
    {
        $found = $false
        foreach($hostPA in $hostPAs)
        {
            if( IsMatchingPA $expectedPA $hostPA )
            {
                if( $hostPA.AddressState -ne [Microsoft.PowerShell.Cmdletization.GeneratedTypes.NetVirtualizationProviderAddress.AddressState]::Preferred )
                {
                    Write-Host -ForegroundColor $errorColor PA Address $expectedPA is in invalid state $hostPA.AddressState
                    $policyOk.Value = $false
                }
                else
                {
                    $found = $true
                }
                break
            }
        }

        if( -not $found )
        {
            $notFoundPAs += $expectedPA
        }
    }

    if($notFoundPAs.Length -gt 0 )
    {
        Write-Host -ForegroundColor $errorColor Provider Records missing in host
        $notFoundPAs | ft ProviderAddress, PrefixLength, VlanID, ManagedByCluster
        $policyOk.Value =  $false
    }
    else
    {
        Write-Host -ForegroundColor $statusPrimaryColor Provider Records matching in host
        $policyOk.Value =  $policyOk.Value -and $true
    }
}

function GetPAAllocationData($logicalNetwork, $paAddr)
{
    $allAllocatedIPs = Get-SCIPAddress -IPAddress $paAddr

    $matchingAllocation = $null
    foreach($allocatedIP in $allAllocatedIPs)
    {
        if( $allocatedIP.AllocatingAddressPool.LogicalNetworkDefinition -ne $null -and $allocatedIP.AllocatingAddressPool.LogicalNetworkDefinition.LogicalNetwork.ID -eq $logicalNetwork.ID)
        {
            $matchingAllocation = $allocatedIP
            break
        }
    }

    return $matchingAllocation

}

function ValidateProviderAddressesVMHost($vm, $vmSubnet, $PAs, [ref] $policyOk)
{
    Write-Host -ForegroundColor $operationColor Calculating Provider Address for VMNetwork : $vmSubnet.VMNetwork.Name, VMSubnet : $vmSubnet.Name

    $policyOk.Value = $true
    $logicalNetwork = $vmSubnet.VMNetwork.LogicalNetwork

    $expectedPAs = @()

    foreach($pa in $PAs)
    {
        $matchingAllocation = GetPAAllocationData $logicalNetwork $pa

        if( $matchingAllocation -eq $null )
        {
            Write-Host -ForegroundColor $errorColor Provider Address $PA is not allocated 
            $policyOk.Value = $false
        }
        else
        {
            $expectedPAs += New-Object -TypeName PSCustomObject -Property @{
                        ProviderAddress       = $matchingAllocation.Address
                        PrefixLength          =   [HNVDiagnostics.IPSubnet]::Parse($matchingAllocation.AllocatingAddressPool.Subnet).PrefixLength
                        VlanID       = $matchingAllocation.AllocatingAddressPool.VLanID
                        ManagedByCluster = $false
                    }
        }
    }

    Write-Host -ForegroundColor $statusPrimaryColor Expected provider addresses on the host $adapInfo.vm.VMHost.Name
    $expectedPAs | ft ProviderAddress, PrefixLength, VlanID, ManagedByCluster

    $hostPAs = Get-NetVirtualizationProviderAddress -CimSession (GetCimSession $vm.VMHost)
    Write-Host -ForegroundColor $statusSecondaryColor Found Provider Addresses on the host $adapInfo.vm.VMHost.Name
    $hostPAs | ft ProviderAddress, PrefixLength, VlanID, ManagedByCluster

    $policyOkTemp = $null
    CheckPAsPresent $expectedPAs $hostPAs -policyOk ([ref]$policyOkTemp)
    $policyOk.Value = $policyOk.Value -and $policyOkTemp
}


function CheckPARoutesPresent ($expectedPaRoutes, $hostPARoutes, [ref] $policyOk)
{
    $policyOk.Value = $true

    $notFoundPARs = @()
    Write-Host -ForegroundColor $operationColor Matching calcuated Route records against Route records in host
    foreach($expectedPAR in $expectedPaRoutes)
    {
        $found = $false
        foreach($hostPAR in $hostPARoutes)
        {
            if( $expectedPAR.DestinationPrefix -eq $hostPAR.DestinationPrefix -and $expectedPAR.NextHop -eq $hostPAR.NextHop )
            {
                $found = $true
                break
            }
        }

        if( -not $found )
        {
            $notFoundPARs += $expectedPAR
        }
    }

    if($notFoundPARs.Length -gt 0 )
    {
        Write-Host -ForegroundColor $errorColor Provider routes missing in host
        $notFoundPARs | ft DestinationPrefix, NextHop
        $policyOk.Value =  $false
    }
    else
    {
        Write-Host -ForegroundColor $statusPrimaryColor Provider routes matching in host
        $policyOk.Value =  $policyOk.Value -and $true
    }
}


function ValidateProviderRoutesVMHost($vm, $vmSubnet, $PA, $PAsInVMNetwork, [ref] $policyOk)
{
    Write-Host -ForegroundColor $operationColor Calculating Provider Routes for VMNetwork : $vmSubnet.VMNetwork.Name, VMSubnet : $vmSubnet.Name

    $policyOk.Value = $true

    $logicalNetwork = $vmSubnet.VMNetwork.LogicalNetwork
    $vmPAAllocation = GetPAAllocationData $logicalNetwork $PA

    $vmPASubnet = [HNVDiagnostics.IPSubnet]::Parse($vmPAAllocation.AllocatingAddressPool.Subnet)

    $expectedPaRoutes = @()
    $addedPASubnets = @()

    foreach($otherPA in $PAsInVMNetwork)
    {
        # find the allocation and add routes
        $otherPAAllocation =  GetPAAllocationData $logicalNetwork $otherPA

        if( $otherPAAllocation -eq $null )
        {
            $policyOk.Value = $false
            Write-Host -ForegroundColor $errorColor PA address $otherPA used for some other VM in the same network is not having any allocation 
        }
        else
        {
            if( -not $vmPASubnet.IsValidAddress($otherPA) )
            {
                # some other subnet, need a route record
                if(-not $addedPASubnets.Contains($otherPAAllocation.AllocatingAddressPool.Subnet))
                {
                    foreach($defaultGw in $vmPAAllocation.AllocatingAddressPool.DefaultGateways)
                    {
                        $expectedPaRoutes += New-Object -TypeName PSCustomObject -Property @{
                            DestinationPrefix       = $otherPAAllocation.AllocatingAddressPool.Subnet
                            NextHop          =   $vmPAAllocation.AllocatingAddressPool.DefaultGateways[0].IPAddress.ToString()
                        }

                        $addedPASubnets += $otherPAAllocation.AllocatingAddressPool.Subnet
                    }
                }
            }
        }       
    }

    Write-Host -ForegroundColor $statusPrimaryColor Expected provider Routes on the host $adapInfo.vm.VMHost.Name
    $expectedPaRoutes | ft DestinationPrefix, NextHop

    $hostPARoutes = Get-NetVirtualizationProviderRoute -CimSession (GetCimSession $vm.VMHost)
    Write-Host -ForegroundColor $statusSecondaryColor Found Provider Routes on the host $adapInfo.vm.VMHost.Name
    $hostPARoutes | ft DestinationPrefix, NextHop

    $policyOkTemp = $null
    CheckPARoutesPresent $expectedPaRoutes $hostPARoutes -policyOk ([ref]$policyOkTemp)
    $policyOk.Value = $policyOk.Value -and $policyOkTemp
}

function RunVMHostPolicyValidation($adapInfo, $gwInfo, [ref]$policyStatus )
{
    $policyStatus.Value = $null

    $policyOkTemp = $null
    $vmPAAddr = $null
    $PAsInVMNetwork = $null

    $vmNetworkLRs = $null
    ValidateLookupRecordsVMHost $adapInfo $gwInfo -policyOk ([ref]$policyOkTemp) -vmPAAddr ([ref]$vmPAAddr) -PAsInVMNetwork ([ref]$PAsInVMNetwork)
    $policyStatus.Value = $policyOkTemp

    ValidateCustomerRouteRecordsVMHost $adapInfo $gwInfo -policyOk ([ref]$policyOkTemp)
    $policyStatus.Value = $policyStatus.Value -and $policyOkTemp

    ValidateProviderAddressesVMHost $adapInfo.vm $adapInfo.hnvAdap.VMSubnet @($vmPAAddr) -policyOk ([ref]$policyOkTemp)
    $policyStatus.Value = $policyStatus.Value -and $policyOkTemp

    ValidateProviderRoutesVMHost $adapInfo.vm $adapInfo.hnvAdap.VMSubnet $vmPAAddr $PAsInVMNetwork -policyOk ([ref]$policyOkTemp)
    $policyStatus.Value = $policyStatus.Value -and $policyOkTemp
}

function GetHyperVVmAndAdapter($adapInfo)
{
    $result = $null

    $hyperVVM = Hyper-V\Get-VM -ComputerName $adapInfo.vm.VMHost.Name -Id $adapInfo.vm.VMId -ErrorAction Ignore

    if( $hyperVVM -ne $null )
    {
        $vmAdapters = Get-VMNetworkAdapter -VM $hyperVVM 
        
        $macAddrToMatch = $adapInfo.hnvAdap.MACAddress.Replace(":","")
        $matchingAdapter = $vmAdapters | where {$_.MacAddress -eq $macAddrToMatch}

        if( $matchingAdapter -ne $null )
        {
            $result = New-Object -TypeName PSCustomObject -Property @{
                Adapter  = $matchingAdapter
                HyperVVM = $hyperVVM
                }
        }
        else
        {
            Write-Host -ForegroundColor $errorColor "Unable to get the HyperV VM adapter for $adapInfo.vm.Name"
        }
    }
    else
    {
        Write-Host -ForegroundColor $errorColor "Unable to get the hyperV VM for $adapInfo.vm.Name"
    }

    return $result
}

function RunActualPing($adapInfo, $hypervInfo, $destIPAddr, [ref]$testStatus)
{
    $vmIPSubnet = [HNVDiagnostics.IPSubnet]::Parse($adapInfo.hnvAdap.VMSubnet.SubnetVLans[0].Subnet)

    $nextHopLR = $null

    if( $vmIPSubnet.IsValidAddress($destIPAddr) )
    {                
        $nextHopLR = Get-NetVirtualizationLookupRecord -CustomerID $adapInfo.hnvAdap.VMNetwork.RoutingDomainId.ToString("B") -CustomerAddress $destIPAddr -CimSession (GetCimSession $adapInfo.vm.VMHost)
    }
    else
    {
        $subnetGwAddr = $vmIPSubnet.GetFirstIPAddress()
        $nextHopLR = Get-NetVirtualizationLookupRecord -CustomerID $adapInfo.hnvAdap.VMNetwork.RoutingDomainId.ToString("B") -CustomerAddress $subnetGwAddr.ToString() -CimSession (GetCimSession $adapInfo.vm.VMHost)
    }

    if( $nextHopLR -ne $null)
    {
        $pingResult = Test-VMNetworkAdapter -VMNetworkAdapter $hypervInfo.Adapter -Sender -SenderIPAddress $adapInfo.ipAddr -ReceiverIPAddress $destIPAddr -NextHopMacAddress $nextHopLR.MACAddress -SequenceNumber 19124 -ErrorVariable $y -ErrorAction SilentlyContinue

        if( $pingResult -ne $null )
        {
            Write-Host -ForegroundColor $statusPrimaryColor Ping succeeded with round trip time of $pingResult.RoundTripTime
            $testStatus.Value = $true
            return
        }
        else
        {
            Write-Host -ForegroundColor $errorColor Ping Failed
            $testStatus.Value = $false
        }

    }
    else
    {
        Write-Host -ForegroundColor $errorColor "Next hop lookup record not found. Is the VM really connected to the subnet or policies set correctly?"
        $testStatus.Value = $false
    }
}

function RunPingTestGW($adapInfo, $destIPAddr, [ref]$testStatus)
{
    Write-host -ForegroundColor $operationColor Running Ping test for VM $adapInfo.vm.Name from $adapInfo.ipAddr to $destIPAddr
    $testStatus.Value = $null

    $hypervInfo = GetHyperVVmAndAdapter $adapInfo

    if( $hypervInfo -ne $null )
    {
        if( $hypervInfo.HyperVVM.State -ne "Running" )
        {
            Write-Host -ForegroundColor $errorColor Ping cannot be done because the VM $adapInfo.vm.Name is not running
            return
        }

        if( -not $hypervInfo.Adapter.IsLegacy )
        {
            RunActualPing $adapInfo $hypervInfo $destIPAddr -testStatus $testStatus
        }
        else
        {
            Write-Host -ForegroundColor $errorColor Ping cannot be done because the VM $adapInfo.VM.Name is using legacy ethernet adapter
        }

        return
    }

    $testStatus.Value = $false
}

#src will have to be synthetic adapter
#destination may or may not be
function RunActualPingBetweenVMs($srcAdapInfo, $srcHyperVInfo, $dstAdapInfo, $dstHyperVInfo)
{
    Write-host -ForegroundColor $operationColor Running Ping test from VM $srcAdapInfo.vm.Name "("$srcAdapInfo.ipAddr")" to $dstAdapInfo.VM.Name "("$dstAdapInfo.ipAddr")"

    $jobHandle = $null

    if( -not $dstHyperVInfo.Adapter.IsLegacy)
    {
        #setup responder for ping
        $scriptBlock = { Test-VMNetworkAdapter -VMNetworkAdapter $args[0] -Receiver -SenderIPAddress $args[1] -ReceiverIPAddress $args[2] -SequenceNumber 19124}

        $Job = [powershell]::Create().AddScript($ScriptBlock).AddArgument($dstHyperVInfo.Adapter).AddArgument($srcAdapInfo.ipAddr).AddArgument($dstAdapInfo.ipAddr)
        $Job.RunspacePool = $RunspacePool
        $jobHandle = $job.BeginInvoke()

        Sleep 2
    }

    $testStatus = $null
    RunActualPing $srcAdapInfo $srcHyperVInfo $dstAdapInfo.ipAddr -testStatus ([ref]$testStatus)

    if( $testStatus -ne $true -and $dstHyperVInfo.Adapter.IsLegacy)
    {
        Write-Host -ForegroundColor $errorColor Ping failure may be unreliable if VM $dstAdapInfo.VM.Name has firewall blocking it. Use either synthetic NIC VMs for testing or enable firewall
        $testStatus = $null
    }

    for($cnt=0; $cnt -lt 10 -and -not $jobHandle.IsCompleted; $cnt++)
    {
        Sleep 1
    }

    
    if( -not $jobHandle.IsCompleted)
    {
        Write-Host -ForegroundColor $operationColor Async job not cleaned up
    }

    return $testStatus
}

function RunPingTestVm2Vm($srcAdapInfo, $dstAdapInfo, [ref]$testStatus)
{
    $testStatus.Value = $null
    Write-host -ForegroundColor $operationColor Running Ping test for VMs $srcAdapInfo.vm.Name "("$srcAdapInfo.ipAddr")" and $dstAdapInfo.VM.Name "("$dstAdapInfo.ipAddr")"

    $srcHyperVInfo = GetHyperVVmAndAdapter $srcAdapInfo
    if( $srcHyperVInfo -ne $null )
    {
        $dstHyperVInfo = GetHyperVVmAndAdapter $dstAdapInfo
        if( $dstHyperVInfo -ne $null )
        {
            if( $srcHyperVInfo.HyperVVM.State -ne "Running")
            {                
                Write-Host -ForegroundColor $errorColor Ping cannot be done because the VM $srcAdapInfo.vm.Name is not running
                return
            }

            if( $dstHyperVInfo.HyperVVM.State -ne "Running" )
            {
                Write-Host -ForegroundColor $errorColor Ping cannot be done because the VM $dstAdapInfo.vm.Name is not running
                return
            }

            #we can't ping from emulated, so take the synthetic and ping from there
            if( $srcHyperVInfo.Adapter.IsLegacy )
            {
                if( $dstHyperVInfo.Adapter.IsLegacy )
                {
                    Write-Host -ForegroundColor $errorColor Both VMs $srcAdapInfo.vm.Name and $dstAdapInfo.vm.Name are using emulated network adapter. Ping cannot be done
                    return
                }

                $testStatus.Value = RunActualPingBetweenVMs $dstAdapInfo $dstHyperVInfo $srcAdapInfo $srcHyperVInfo 

            }
            else
            {
                $testStatus.Value = RunActualPingBetweenVMs $srcAdapInfo $srcHyperVInfo $dstAdapInfo $dstHyperVInfo 
            }

            return

        }
    }

    $testStatus.Value = $false
}


function RunPAPingTest ($adapInfo, $srcPAAddr, $destPAAddr, [ref]$paPingStatus)
{
    Write-Host -ForegroundColor $operationColor Running PA ping from $srcPAAddr to $destPAAddr

    $pingCommandLine = '\"ping.exe\" -p '
    $pingCommandLine += $destPAAddr
    $pingCommandLine += " -S "
    $pingCommandLine += $srcPAAddr

    $gceCommandParam = @( "Executable", "ping.exe",
                    "Parameters", $pingCommandLine,
                    "TimeoutSeconds", "600",
                    "WorkingDirectory","",
                    "SetWorkingDirectoryPermissions","False",
                    "StandardOutputRegex","*",
                    "StandardErrorRegex","*",
                    "ExitCodeRegex","*",
                    "RebootExitCodeRegex","3010",
                    "StandardOutputPath","",
                    "StandardErrorPath","",
                    "MaxOutputSize","20971520",
                    "StdInBuffer","",
                    "GCEId", "67f7697e5c8943aa8b831565f1c14bfc")

    $cimSession = New-CimSession -ComputerName $adapinfo.Vm.VMHost.Name

    $paramObj = New-Object Microsoft.Management.Infrastructure.CimMethodParametersCollection
    $param1 = [Microsoft.Management.Infrastructure.CimMethodParameter]::Create("WMIVariables", $gceCommandParam, 0)
    $paramObj.Add($param1)

    $result = $cimSession.InvokeMethod("root\scvmm", "GenericCommandExecutionManagement", "Execute", $paramObj)

    if( $result.ReturnValue.Value -ne 0 )
    {
        Write-Host -ForegroundColor $errorColor "Unable to invoke ping remotely $result.ReturnValue"
        $paPingStatus.Value = $false;
        return
    }

    $resultInst = $cimSession.EnumerateInstances("root\scvmm", "AsyncTask") | where {$_.ID -eq $result.OutParameters["TaskHandle"].Value.ID}
    if( $resultInst -eq $null )
    {
        Write-Host -ForegroundColor $errorColor "Unable to invoke ping remotely. Result instance not found with ID $result.OutParameters["TaskHandle"].Value.ID"
        $paPingStatus.Value = $false;
        return
    }

    $progressResult = $null
    do
    {
        $progressResult = $cimSession.InvokeMethod("root\scvmm", $resultInst, "GetProgress", $null)
        if( $progressResult.ReturnValue.Value -ne 0 )
        {
            Write-Host -ForegroundColor $errorColor "Unable to invoke ping remotely. Progress not found"
            $paPingStatus.Value = $false;
            return
        }
    }
    while($progressResult.OutParameters["Progress"].Value -lt 100 )

    $finalResult = $cimSession.InvokeMethod("root\scvmm", $resultInst, "GetFinalResult", $null)
    if( $finalResult.ReturnValue.Value -ne 0 )
    {
        Write-Host -ForegroundColor $errorColor "Unable to invoke ping remotely. Progress not found"
        $paPingStatus.Value = $false
        return
    }

    for($ndx = 0; $ndx -lt $finalResult.OutParameters["OutputParameters"].Value.Length; $ndx += 2)
    {
        if( $finalResult.OutParameters["OutputParameters"].Value[$ndx] -eq "StdOutLastCharacters" )
        {
            $occurenceCount = 0
            $searchIndex = -1
            do
            {
                $searchIndex = $finalResult.OutParameters["OutputParameters"].Value[$ndx+1].IndexOf("TTL=",$searchIndex + 1)
                if( $searchIndex -ne -1)
                {
                    $occurenceCount++
                }
            }
            while($searchIndex -ne -1)

            if( $occurenceCount -gt 2 )
            {
                Write-Host -ForegroundColor $statusSecondaryColor Successful pings $occurenceCount
                Write-Host -ForegroundColor $statusSecondaryColor $finalResult.OutParameters["OutputParameters"].Value[$ndx+1]
                $paPingStatus.Value = $true
            }
            else
            {
                Write-Host -ForegroundColor $errorColor $finalResult.OutParameters["OutputParameters"].Value[$ndx+1]
                $paPingStatus.Value = $false
            }
        }
    }
}

function  GetGatewayVSID($gwConfig, $VMNetwork)
{
    $rdidStr = $VMNetwork.RoutingDomainId.ToString("B")

    $routingDomains = @(Get-VMNetworkAdapterRoutingDomainMapping -VMNetworkAdapter $gwConfig.BackendVMAdaptersHyperV[0])

    if( $routingDomains -eq $null -or $routingDomains.length -eq 0 )
    {
        Write-Host -ForegroundColor $errorColor Routing domain mapping on HyperV not found for VM $gwConfig.VMs[0] on host $gwCOnfig.Hosts[0]
        return $null
    }
    else
    {
        $rdidSetting = $null
        foreach($rdid in $routingDomains)
        {
            if( $rdid.RoutingDomainID.ToLower() -eq $rdidStr)
            {
                $rdidSetting = $rdid
                break
            }
        }

        if( $rdidSetting -eq $null )
        {
            Write-Host -ForegroundColor $errorColor Routing domain mapping for VMNetwork $VMNetwork.Name not found for VM $gwConfig.VMs[0] on host $gwCOnfig.Hosts[0]
            return $null
        }

        if( $rdidSetting.IsolationID -eq $null -or $rdidSetting.IsolationID.Length -eq 0 )
        {
            Write-Host -ForegroundColor $errorColor Routing domain mapping for VMNetwork $VMNetwork.Name has no VSID in VM $gwConfig.VMs[0] on host $gwCOnfig.Hosts[0]
            return $null
        }

        return $rdidSetting.IsolationID[0]
    }
}

function GatherGatewayInfo($adapInfo, [ref]$gwInfo)
{
    $gwInfo.Value = $null
    if( $adapInfo.hnvAdap.VMNetwork.VMNetworkGateways -eq $null -or $adapInfo.hnvAdap.VMNetwork.VMNetworkGateways.Count -eq 0 )
    {
        Write-host -ForegroundColor $errorColor "No gateway found connected to the VM"
        return
    }

    $vmNetwork = $adapInfo.hnvAdap.VMNetwork
    $vmSubnet  = $adapInfo.hnvAdap.VMSubnet

    Write-Host -ForegroundColor $statusPrimaryColor Found HNV VM Connected to VMNetwork : $hnvAdap.VMNetwork.Name
    foreach($vmSubnet in $adapInfo.hnvAdap.VMNetwork.VMSubnet)
    {
        Write-Host -ForegroundColor $statusSecondaryColor -NoNewline VMSubnet found : $vmSubnet.Name "   "
        foreach($subnet in $vmSubnet.SubnetVLans)
        {
            Write-Host -ForegroundColor $statusSecondaryColor $subnet.Subnet
        }
    }
    
    $gwSubnet = $adapInfo.hnvAdap.VMNetwork.VMNetworkGateways[0].IPSubnets
    $gwSubnet = [HNVDiagnostics.IPSubnet]::Parse($gwSubnet)
    Write-Host -ForegroundColor $statusSecondaryColor "Gateway Subnet : " $gwSubnet

    $networkService = $vmNetwork.VMNetworkGateways[0].NetworkGateway.Service
    Write-Host -ForegroundColor $statusPrimaryColor Found HNV VM Connected to Gateway   :  $networkService.Name


    $gwAddr = [HNVDiagnostics.IPSubnet]::IncrementIPAddress($gwSubnet.GetFirstIPAddress())
    Write-Host -ForegroundColor $statusPrimaryColor "Gateway Address : " $gwAddr

    $gwMacAddress = $null
    $gwPaIPv4 = $null
    $gwPaIPv6 = $null

    foreach($nsConn in $networkService.NetworkConnections)
    {
        if( $nsConn.ConnectionType -eq "BackEnd" )
        {
            $gwMacAddress = $nsConn.NetworkAdapter.PhysicalAddress;
            $gwPaIPv4 = $nsConn.IPv4Address
            $gwPaIPv6 = $nsConn.IPv6Address
        }
    }

    if( $gwMacAddress -eq $null )
    {
        Write-Host -ForegroundColor $errorColor Network service $networkService.Name does not have backend adapter or MAC address not configured on backend
        return
    }

    $setupStatus = $null
    $gwConfig = GetGatewayConfiguration $networkService -setupStatus ([ref]$setupStatus)

    $gwVSID = GetGatewayVSID $gwConfig $adapInfo.hnvAdap.VMNetwork

    $gwInfo.Value = New-Object -TypeName PSCustomObject -Property @{
                        vmNetwork       = $vmNetwork
                        gwSubnet        = $gwSubnet
                        networkService  = $networkService
                        gwAddr          = $gwAddr
                        gwMacAddress    = $gwMacAddress
                        gwPaIPv4        = $gwPaIPv4
                        gwPaIPv6        = $gwPaIPv6
                        gwConfig        = $gwConfig
                        gwVSID          = $gwVSID
                }
}

function GetPAAddressForCA($caAddr, $vmHost, $vmNetwork)
{
    $lr = Get-NetVirtualizationLookupRecord -CustomerAddress $caAddr -CustomerID $vmNetwork.RoutingDomainID.ToString("B") -CimSession (GetCimSession $vmHost) -ErrorAction SilentlyContinue

    if($lr -ne $null)
    { 
        return $lr.ProviderAddress
    }
    else
    {
        return $null
    }
}

function GetPADIPForHost($gwConfig, $hst)
{
    $paDipConfiguration = $null
    foreach($paDipConfig in $gwConfig.PADIPConfiguration)
    {
        if( IsHostNameMatching $paDipConfig.NodeName $hst )
        {
            $paDipConfiguration = $paDipConfig
            break
        }
    }
    return $paDipConfiguration
}

function ValidateLookupRecordsGWHost($gwInfo, $lookupRecordList, $ndx, [ref]$policyOk, [ref]$PAsInVMNetwork)
{
    $policyOk.Value = $true
    $gwHostLookupRecords = @()
    $gwHostLookupRecords += $lookupRecordList
    $rdid = $gwInfo.VMNetwork.RoutingDomainID.ToString("B")

    $gwDipAddressStart = [HNVDiagnostics.IPSubnet]::IncrementIPAddress([HNVDiagnostics.IPSubnet]::IncrementIPAddress($gwInfo.gwSubnet.GetFirstIPAddress()))

    $gwMacAddress = $null
    if($ndx -eq $gwInfo.GwConfig.OwnerNodeIndex )
    {
        #only on active node it is pointing to the VMs mac. On Passive node, it could be pointing either to preferred VMs mac or currently active VMs depending on boot sequence
        $gwMacAddress = $gwInfo.gwConfig.BackendVMAdaptersHyperV[$ndx].MACAddress
    }

    $gwVipPAAddr = $null
    if( $gwInfo.vmNetwork.PAIPAddressPoolType -eq "IPV4")
    {
        $gwVipPAAddr = $gwInfo.gwPaIPv4
    }
    else
    {
        $gwVipPAAddr = $gwInfo.gwPaIPv6
    }

    # add gw record
    $gwHostLookupRecords += New-Object -TypeName PSCustomObject -Property @{
        CustomerAddress       = $gwInfo.gwAddr.IPAddressToString
        MacAddress      = $gwMacAddress
        VirtualSubnetID = $gwInfo.gwVSID
        ProviderAddress       = $gwVipPAAddr
        CustomerID = $rdid
    }

    #wild card record
    $gwHostLookupRecords += New-Object -TypeName PSCustomObject -Property @{
        CustomerAddress       = GetOnlinkAddress($gwInfo.VMNetwork)
        MacAddress      = $gwMacAddress
        VirtualSubnetID = $gwInfo.gwVSID
        ProviderAddress       = $gwVipPAAddr
        CustomerID = $rdid
    }

    # gateway subnets WNV router address
    $gwHostLookupRecords += New-Object -TypeName PSCustomObject -Property @{
        CustomerAddress       = $gwInfo.gwSubnet.GetFirstIPAddress()
        MacAddress      = $null
        VirtualSubnetID = $gwInfo.gwVSID
        ProviderAddress       = GetTempPAAddress($gwInfo.VMNetwork)
        CustomerID = $rdid
    }

    #compute DIP LRs
    for($ndx2 = 0; $ndx2 -lt $gwInfo.gwConfig.Hosts.Length; $ndx2++)
    {
        $paDipConfiguration = GetPADIPForHost $gwInfo.gwConfig $gwINfo.GwConfig.Hosts[$ndx2]

        if( $paDipConfiguration -eq $null )
        {
            Write-Host -ForegroundColor $errorColor Unable to find DIP configuration for the host ($gwInfo.GwCOnfig.Hosts[$ndx2])
            $policyOk.Value = $false
            return
        }

        $paDipAddress = $null
        foreach($paIP in $paDipConfiguration.ProviderAddresses)
        {
            $parsedIP = [System.Net.IPAddress]::Parse($paIP.Address);
            if( $gwInfo.vmNetwork.PAIPAddressPoolType -eq "IPV4" )
            {
                if( $parsedIP.AddressFamily -eq [System.Net.Sockets.AddressFamily]::InterNetwork)
                {
                    $paDipAddress = $parsedIP
                }
            }
            else
            {
                if( $parsedIP.AddressFamily -eq [System.Net.Sockets.AddressFamily]::InterNetworkV6)
                {
                    $paDipAddress = $parsedIP
                }                
            }
        }

        if( $paDipAddress -eq $null )
        {
            Write-Host -ForegroundColor $errorColor Unable to find DIP IP for the host ($gwInfo.GwCOnfig.Hosts[$ndx2]) that matches VM network configuration
            $policyOk.Value = $false
            return
        }

        $dipAddress = $gwDipAddressStart
        for($ndx3 = 0; $ndx3 -lt $paDipConfiguration.PermanentNodeIndex; $ndx3++)
        {
            $dipAddress = [HNVDiagnostics.IPSubnet]::IncrementIPAddress($dipAddress)
        }


        $gwHostLookupRecords += New-Object -TypeName PSCustomObject -Property @{
            CustomerAddress       = $dipAddress
            MacAddress      = $gwInfo.GwConfig.BackendVMAdaptersHyperV[$ndx2].MACAddress
            VirtualSubnetID = $gwInfo.gwVSID
            ProviderAddress       = $paDipAddress.ToString()
            CustomerID = $rdid
        }

        #wild card record
        $gwHostLookupRecords += New-Object -TypeName PSCustomObject -Property @{
            CustomerAddress       = GetOnlinkAddress($gwInfo.VMNetwork)
            MacAddress      = $gwInfo.GwConfig.BackendVMAdaptersHyperV[$ndx2].MACAddress
            VirtualSubnetID = $gwInfo.gwVSID
            ProviderAddress       = $gwVipPAAddr
            CustomerID = $rdid
        }
    }

    Write-Host -ForegroundColor $statusPrimaryColor Expected lookup records on the host $adapInfo.vm.VMHost.Name
    $gwHostLookupRecords | ft CustomerAddress, MacAddress, ProviderAddress, VirtualSubnetID

    $hostLRs = Get-NetVirtualizationLookupRecord -CimSession (GetCimSession $gwInfo.GwConfig.Hosts[$ndx]) -CustomerID $gwInfo.VMNetwork.RoutingDomainId.ToString("B")
    Write-Host -ForegroundColor $statusSecondaryColor Found lookup records on the host $adapInfo.vm.VMHost.Name
    $hostLRs | ft CustomerAddress, MacAddress, ProviderAddress, VirtualSubnetID


    $allPAs = @()
    foreach($hostLR in $hostLRs)
    {
        if( $hostLR.ProviderAddress -ne (GetTempPAAddress $adapInfo.hnvAdap.VMNetwork) -and -not $allPAs.Contains($hostLR.ProviderAddress) )
        {
            $allPAs += $hostLR.ProviderAddress
        }
    }

    $PAsInVMNetwork.Value = $allPAs

    CheckLRsPresent $gwHostLookupRecords $hostLRs -policyOk $policyOk
}

function ValidateCustomerRouteRecordsGWHost($gwInfo, $ndx, [ref] $policyOk)
{
    $policyOk.Value = $true
    Write-Host -ForegroundColor $operationColor Calculating Route records for VMNetwork : $gwInfo.VMNetwork.Name

    $expectedCRs = @()

    $rdid = $gwInfo.VMNetwork.RoutingDomainID.ToString("B")

    foreach($vmSubnetTemp in $gwInfo.VMNetwork.VMSubnet)
    {
        $expectedCRs +=  New-Object -TypeName PSCustomObject -Property @{
                    RoutingDomainID       = $rdid
                    DestinationPrefix =   $vmSubnetTemp.SubnetVLans[0].Subnet 
                    NextHop       = GetOnlinkAddress($gwInfo.VMNetwork)
                    VirtualSubnetID = $vmSubnetTemp.VMSubnetID
                }
    }

    #add gw route
    $expectedCRs +=  New-Object -TypeName PSCustomObject -Property @{
                        RoutingDomainID       = $rdid
                        DestinationPrefix =   $gwINfo.gwSubnet
                        NextHop       = GetOnlinkAddress($gwInfo.VMNetwork)
                        VirtualSubnetID = $gwInfo.gwVSID
                    }

    $hostCRs = Get-NetVirtualizationCustomerRoute -CimSession (GetCimSession $gwInfo.GwConfig.Hosts[$ndx]) -RoutingDomainID $rdid

    Write-Host -ForegroundColor $statusPrimaryColor Expected Route records on the host ($gwInfo.GwConfig.Hosts[$ndx])
    $expectedCRs | ft DestinationPrefix, NextHop, VirtualSubnetID, RoutingDomainID

    Write-Host -ForegroundColor $statusSecondaryColor Found Route records on the host ($gwInfo.GwConfig.Hosts[$ndx])
    $hostCRs | ft DestinationPrefix, NextHop, VirtualSubnetID, RoutingDomainID

    CheckCRsPresent $expectedCRs $hostCRs -policyOk $policyOk
}

function ValidateProviderAddressRecordGWHost($gwInfo, $ndx, [ref]$policyOk)
{
    $policyOk.Value = $true
    Write-Host -ForegroundColor $operationColor Calculating Provider Address records for VMNetwork : $gwInfo.VMNetwork.Name

    $paDipConfiguration = $null
    foreach($paDipConfig in $gwInfo.gwConfig.PADIPConfiguration)
    {
        if( IsHostNameMatching $paDipConfig.NodeName $gwINfo.GwConfig.Hosts[$ndx] )
        {
            $paDipConfiguration = $paDipConfig
        }
    }

    if( $paDipConfiguration -eq $null )
    {
        Write-Host -ForegroundColor $errorColor Unable to find DIP configuration for the host ($gwInfo.GwCOnfig.Hosts[$ndx])
        $policyOk.Value = $false
        return
    }

    $expectedPAs = @()
    foreach($pa in $paDipConfiguration.ProviderAddresses)
    {
        $matchingAllocation = GetPAAllocationData $gwInfo.VMNetwork.LogicalNetwork $pa.Address
        if( $matchingAllocation -eq $null )
        {
            Write-Host -ForegroundColor $errorColor Unable to find the provider address allocation information for PA $pa.Address for gateway DIPs
            $policyOk.Value = $false
            return
        }

        $expectedPAs += New-Object -TypeName PSCustomObject -Property @{
                            ProviderAddress       = $pa.Address
                            PrefixLength          =   [HNVDiagnostics.IPSubnet]::Parse($matchingAllocation.AllocatingAddressPool.Subnet).PrefixLength
                            VlanID       = $pa.VLANId
                            ManagedByCluster = $false
                        }
    }

    # Add PA VIP address for active host
    if( $ndx -eq $gwInfo.GwConfig.OwnerNodeIndex )
    {
        if( $gwInfo.gwPaIPv4 -ne $null )
        {
            $matchingAllocation = GetPAAllocationData $gwInfo.VMNetwork.LogicalNetwork $gwInfo.gwPaIPv4
            if( $matchingAllocation -eq $null )
            {
                Write-Host -ForegroundColor $errorColor Unable to find the provider address allocation information for PA $gwInfo.gwPaIPv4 for gateway DIPs
                $policyOk.Value = $false
                return
            }

            $expectedPAs += New-Object -TypeName PSCustomObject -Property @{
                            ProviderAddress       = $gwInfo.gwPaIPv4
                            PrefixLength          =   [HNVDiagnostics.IPSubnet]::Parse($matchingAllocation.AllocatingAddressPool.Subnet).PrefixLength
                            VlanID       = $pa.VLANId
                            ManagedByCluster = $true
                        }
        }

        if( $gwInfo.gwPaIPv6 -ne $null )
        {
            $matchingAllocation = GetPAAllocationData $gwInfo.VMNetwork.LogicalNetwork $gwInfo.gwPaIPv6
            if( $matchingAllocation -eq $null )
            {
                Write-Host -ForegroundColor $errorColor Unable to find the provider address allocation information for PA $gwInfo.gwPaIPv6 for gateway DIPs
                $policyOk.Value = $false
                return
            }

            $expectedPAs += New-Object -TypeName PSCustomObject -Property @{
                            ProviderAddress       = $gwInfo.gwPaIPv6
                            PrefixLength          =   [HNVDiagnostics.IPSubnet]::Parse($matchingAllocation.AllocatingAddressPool.Subnet).PrefixLength
                            VlanID       = $pa.VLANId
                            ManagedByCluster = $true
                        }
        }
    }

    
    Write-Host -ForegroundColor $statusPrimaryColor Expected provider addresses on the host $gwInfo.GwConfig.Hosts[$ndx]
    $expectedPAs | ft ProviderAddress, PrefixLength, VlanID, ManagedByCluster

    $hostPAs = Get-NetVirtualizationProviderAddress -CimSession (GetCimSession $gwInfo.GwConfig.Hosts[$ndx])
    Write-Host -ForegroundColor $statusSecondaryColor Found Provider Addresses on the host $gwInfo.GwConfig.Hosts[$ndx]
    $hostPAs | ft ProviderAddress, PrefixLength, VlanID, ManagedByCluster

    $policyOkTemp = $null
    CheckPAsPresent $expectedPAs $hostPAs -policyOk ([ref]$policyOkTemp)
    $policyOk.Value = $policyOk.Value -and $policyOkTemp

}

function ValidateProviderRouteRecordGwHost($gwInfo, $PAsInVMNetwork, $ndx, [ref]$policyOk)
{
    Write-Host -ForegroundColor $operationColor Calculating Provider Routes for VMNetwork : $gwInfo.VMNetwork.Name

    $policyOk.Value = $true

    $gwPAAddr = $null
    if( $gwInfo.VMNetwork.PAIPAddressPoolType -eq "IPV4")
    {
        $gwPAAddr = $gwInfo.gwPaIPv4        
    }
    else
    {
        $gwPAAddr = $gwInfo.gwPaIPv6
    }

    $logicalNetwork = $gwInfo.VMNetwork.LogicalNetwork
    $gwPAAllocation = GetPAAllocationData $logicalNetwork $gwPAAddr

    $gwPASubnet = [HNVDiagnostics.IPSubnet]::Parse($gwPAAllocation.AllocatingAddressPool.Subnet)

    $expectedPaRoutes = @()
    $addedPASubnets = @()

    foreach($otherPA in $PAsInVMNetwork)
    {
        # find the allocation and add routes
        $otherPAAllocation =  GetPAAllocationData $logicalNetwork $otherPA

        if( $otherPAAllocation -eq $null )
        {
            $policyOk.Value = $false
            Write-Host -ForegroundColor $errorColor PA address $otherPA used for some other VM in the same network is not having any allocation 
        }
        else
        {
            if( -not $gwPASubnet.IsValidAddress($otherPA) )
            {
                # some other subnet, need a route record
                if(-not $addedPASubnets.Contains($otherPAAllocation.AllocatingAddressPool.Subnet))
                {
                    foreach($defaultGw in $gwPAAllocation.AllocatingAddressPool.DefaultGateways)
                    {
                        $expectedPaRoutes += New-Object -TypeName PSCustomObject -Property @{
                            DestinationPrefix       = $otherPAAllocation.AllocatingAddressPool.Subnet
                            NextHop          =   $vmPAAllocation.AllocatingAddressPool.DefaultGateways[0].IPAddress.ToString()
                        }

                        $addedPASubnets += $otherPAAllocation.AllocatingAddressPool.Subnet
                    }
                }
            }
        }       
    }

    Write-Host -ForegroundColor $statusPrimaryColor Expected provider Routes on the host $gwInfo.GwConfig.Hosts[$ndx]
    $expectedPaRoutes | ft DestinationPrefix, NextHop

    $hostPARoutes = Get-NetVirtualizationProviderRoute -CimSession (GetCimSession $gwInfo.GwConfig.Hosts[$ndx])
    Write-Host -ForegroundColor $statusSecondaryColor Found Provider Routes on the host $gwInfo.GwConfig.Hosts[$ndx]
    $hostPARoutes | ft DestinationPrefix, NextHop

    $policyOkTemp = $null
    CheckPARoutesPresent $expectedPaRoutes $hostPARoutes -policyOk ([ref]$policyOkTemp)
    $policyOk.Value = $policyOk.Value -and $policyOkTemp
}

function RunGWHostPolicyValidation($gwInfo, [ref]$policyStatus)
{
    $policyStatus.Value = $true

    Write-Host -ForegroundColor $operationColor Validating Policies on gateway host
    $lookupRecordList = @()

    foreach($vmSubnetTemp in $gwInfo.vmNetwork.VMSubnet)
    {
        $lookupRecordList += GetAllLookupRecordsForVMSubnet $vmSubnetTemp
    }



    for($ndx = 0 ; $ndx -lt $gwInfo.gwConfig.VMs.Length; $ndx++)
    {
        Write-Host -ForegroundColor $operationColor Validating lookup records in gateway host ($gwInfo.GwConfig.Hosts[$ndx])
        $PAsInVMNetwork = @()
        $policyOk = $null
        ValidateLookupRecordsGWHost $gwInfo $lookupRecordList $ndx -policyOk ([ref]$policyOk) -PAsInVMNetwork ([ref]$PAsInVMNetwork)
        if( $policyOk -eq $false )
        {
            $policyStatus.Value = $false
        }

        $policyOk = $null
        ValidateCustomerRouteRecordsGWHost $gwInfo $ndx -policyOk ([ref]$policyOk)
        if( $policyOk -eq $false )
        {
            $policyStatus.Value = $false
        }

        $policyOk = $null
        ValidateProviderAddressRecordGWHost $gwInfo $ndx -policyOk ([ref]$policyOk)
        if( $policyOk -eq $false )
        {
            $policyStatus.Value = $false
        }

        $policyOk = $null
        ValidateProviderRouteRecordGwHost $gwInfo $PAsInVMNetwork $ndx -policyOk ([ref]$policyOk)
        if( $policyOk -eq $false )
        {
            $policyStatus.Value = $false
        }
    }
   
}

function RunGwValidationForAdapter($gwInfo, $adapInfo, [ref]$status)
{
    if( $gwInfo.GWConfig -eq $null )
    {
        return
    }

    $status.Value.GatewaySetup = $true

    if(-not (ValidateGatewayHasCSV $gwInfo.gwConfig) )
    {
        Write-Host -ForegroundColor $errorColor "VM cluster must have a CSV volume to function as gateway"
        $status.Value.GatewaySetup = $false
        return
    }

    ValidateGatewayQuorum $gwInfo.gwConfig

    if( -not (ValidatePAGroupActiveOnProperNode $gwInfo.gwConfig) )
    {
        Write-Host -ForegroundColor $errorColor "Host cluster PA resource cannot be validated against VM resource"
        $status.Value.GatewaySetup = $false
        return
    }

    $status.Value.GatewayVmClusterConfiguration = ValidateGatewayVMCluster $gwInfo.gwConfig

    $status.Value.GatewayMetadataConfiguration  = ValidateGatewayMetaDataConfiguration $gwInfo.gwConfig

    $status.Value.GatewayRoutingDomainConfiguration = ValidateGatewayRoutingDomainForVMNetworkGateway $gwInfo.gwConfig $adapInfo.hnvAdap.VMNetwork.VMNetworkGateways[0]

    $status.Value.GatewayRoutingDomainClusterObject = ValidateGwVMNetworkClusterObject $gwInfo.gwConfig $adapInfo.hnvAdap.VMNetwork

    $status.Value.GatewayVMRoutes = ValidateGatewayVMRoutes $gwInfo.gwConfig
}

function DiagnoseGatewayConnectivity($adapInfo, [ref] $status)
{
    $status.Value = New-Object -TypeName PSCustomObject -Property @{
                        PolicyStatus    = $null
                        PingStatus      = $null
                        GatewayPolicyStatus = $null
                        PAGatewayPingStatus = $null
                        PAPingStatus    = $null
                        GatewaySetup    = $null
                        GatewayVmFeatureConfiguration = $null
                        GatewayVmClusterConfiguration = $null
                        GatewayMetadataConfiguration  = $null
                        GatewayRoutingDomainConfiguration = $null
                        GatewayRoutingDomainClusterObject = $null
                        GatewayVMRoutes        = $null
                    }


    $gwInfo = $null
    GatherGatewayInfo $adapInfo -gwInfo ([ref]$gwInfo)

    $policyStatus = $null
    RunVMHostPolicyValidation $adapInfo $gwInfo -PolicyStatus ([ref]$policyStatus)
    $status.Value.PolicyStatus = $policyStatus

    RunGwValidationForAdapter $gwInfo $adapInfo -status $status 

    $policyStatus = $null
    RunGWHostPolicyValidation $gwInfo -PolicyStatus ([ref]$policyStatus)
    $status.Value.GatewayPolicyStatus = $policyStatus

    if( $status.Value.PolicyStatus )
    {
        $pingStatus = $null
        RunPingTestGW $adapInfo $gwInfo.gwAddr -testStatus ([ref]$pingStatus)

        $status.Value.PingStatus = $pingStatus

        $paPingStatus = $null

        $srcPAAddr = GetPAAddressForCA $adapInfo.ipAddr $adapInfo.VM.VMHost $adapInfo.hnvAdap.VMNetwork

        if( $adapInfo.hnvAdap.VMNetwork.PAIPAddressPoolType -eq "IPV4" )
        {
            RunPAPingTest $adapInfo $srcPAAddr $gwInfo.gwPaIPv4 -paPingStatus ([ref]$paPingStatus) 
        }
        else
        {
            RunPAPingTest $adapInfo $srcPAAddr $gwInfo.gwPaIPv6 -paPingStatus ([ref]$paPingStatus) 
        }

        $status.Value.PAPingStatus = $paPingStatus

        $paIPAddress = GetPAAllocationData $adapInfo.hnvAdap.VMNetwork.LogicalNetwork $srcPAAddr

        foreach($defaultGw in $paIPAddress.AllocatingAddressPool.DefaultGateways)
        {
            $paGwPingStatus = $null
            RunPAPingTest $adapInfo $srcPAAddr $defaultGw.IPAddress -paPingStatus ([ref]$paGwPingStatus) 

            if( $status.Value.PAGatewayPingStatus -eq $null )
            {
                $status.Value.PAGatewayPingStatus = $true
            }
            $status.Value.PAGatewayPingStatus = $status.Value.PAGatewayPingStatus -and $paGwPingStatus
        }

    }
}

function DiagnostVm2VmConnectivity($srcAdapter, $dstAdapter, [ref]$status)
{
    $status.Value = New-Object -TypeName PSCustomObject -Property @{
                    SourceVMPolicyStatus    = $null
                    DestVMPolicyStatus      = $null
                    ConsistentPolicy        = $null
                    PingStatus              = $null
                    PAGatewayPingStatus     = $null
                    PAPingStatus            = $null
                }

    Write-Host -ForegroundColor $operationColor Running VM Policy Validation for $srcAdapter.VM.Name on $srcAdapter.vm.VMHost.Name
    $status2 = $null
    RunVMHostPolicyValidation $srcAdapter $null  -policyStatus ([ref]$status2)
    $status.Value.SourceVMPolicyStatus = $status2

    Write-Host -ForegroundColor $operationColor Running VM Policy Validation for $dstAdapter.VM.Name on $dstAdapter.vm.VMHost.Name
    $status2 = $null
    RunVMHostPolicyValidation $dstAdapter $null  -policyStatus ([ref]$status2)
    $status.Value.DestVMPolicyStatus = $status2

    if( $status.Value.SourceVMPolicyStatus -and $status.Value.DestVMPolicyStatus )
    {
        $srcPA1 = GetPAAddressForCA $srcAdapter.ipAddr $srcAdapter.vm.VMHost $srcAdapter.hnvAdap.VMNetwork
        $dstPA1 = GetPAAddressForCA $dstAdapter.ipAddr $srcAdapter.vm.VMHost $srcAdapter.hnvAdap.VMNetwork

        $srcPA2 = GetPAAddressForCA $srcAdapter.ipAddr $dstAdapter.vm.VMHost $srcAdapter.hnvAdap.VMNetwork
        $dstPA2 = GetPAAddressForCA $dstAdapter.ipAddr $dstAdapter.vm.VMHost $srcAdapter.hnvAdap.VMNetwork

        $status.Value.ConsistentPolicy = $srcPA1 -ne $null -and $dstPA1 -ne $null -and $srcPA2 -ne $null -and $dstPA2 -ne $null -and $srcPA1 -eq $srcPA2 -and $dstPA1 -eq $dstPA2 

        if( $status.Value.ConsistentPolicy )
        {
            $status2 = $null
            RunPingTestVm2Vm $srcAdapter  $dstAdapter -testStatus ([ref]$status2)
            $status.Value.PingStatus = $status2
        }


        $paPingStatus = $null
        $srcPAAddr = GetPAAddressForCA $srcAdapter.ipAddr $srcAdapter.VM.VMHost $srcAdapter.hnvAdap.VMNetwork
        $dstPAAddr = GetPAAddressForCA $dstAdapter.ipAddr $srcAdapter.VM.VMHost $srcAdapter.hnvAdap.VMNetwork

        RunPAPingTest $srcAdapter $srcPAAddr $dstPAAddr -paPingStatus ([ref]$paPingStatus) 
        $status.Value.PAPingStatus = $paPingStatus

        $paIPAddress = GetPAAllocationData $srcAdapter.hnvAdap.VMNetwork.LogicalNetwork $srcPAAddr

        foreach($defaultGw in $paIPAddress.AllocatingAddressPool.DefaultGateways)
        {
            $paGwPingStatus = $null
            RunPAPingTest $srcAdapter $srcPAAddr $defaultGw.IPAddress -paPingStatus ([ref]$paGwPingStatus) 

            if( $status.Value.PAGatewayPingStatus -eq $null )
            {
                $status.Value.PAGatewayPingStatus = $true
            }
            $status.Value.PAGatewayPingStatus = $status.Value.PAGatewayPingStatus -and $paGwPingStatus       
        }
    }
}


<#
.SYNOPSIS
Gets a parameter value from connection string.
#>
Function GetParameterFromConnectionString {
    Param (
        [Parameter(Mandatory=$true)][System.String]$ConnectionString,
        [Parameter(Mandatory=$true)][System.String]$Parameter
    )

    $parts = $connectionString.Split(";")

    foreach ($part in $parts) {
        $values = $part.Split("=")
        if ($values.Count -eq 2 -and $values[0].ToLower().Trim().Contains($parameter.ToLower()) -eq $true) {
            return $values[1].Trim()
        }
    }
}

function GetDomainName($hostName)
{
    $domainNdx = $hostName.IndexOf(".")
    if( $domainNdx -ne -1 )
    {
        return $hostName.Substring($domainNdx+1).ToLower()
    }

    return $null
}

function GetHostName($hostName)
{
    $domainNdx = $hostName.IndexOf(".")
    if( $domainNdx -ne -1 )
    {
        return $hostName.Substring(0,$domainNdx).ToLower()
    }

    return $hostName.ToLower()
}

function GetFQDNName($hostName, $domainName)
{
    if( $hostName.Contains(".") -or $domainName -eq $null)
    {
        return $hostName.ToLower()
    }

    return ($hostName + "." + $domainName).ToLower()
}

function IsHostNameMatching([System.string]$hostName1, [System.string]$hostName2)
{
    $hostName1withoutDomain = GetHostName $hostName1.ToLower()
    $hostName2withoutDomain = GetHostName $hostName2.ToLower()

    return $hostName1withoutDomain.Equals($hostName2withoutDomain)
}


function GetHostNameFromVM($cimSession)
{
    $paramObj = New-Object Microsoft.Management.Infrastructure.CimMethodParametersCollection
    $param1 = [Microsoft.Management.Infrastructure.CimMethodParameter]::Create("hDefKey", ([System.UInt32]"0x80000002"), 0)
    $paramObj.Add($param1)
    $param2 = [Microsoft.Management.Infrastructure.CimMethodParameter]::Create("sSubKeyName", "SOFTWARE\Microsoft\Virtual Machine\Guest\Parameters", 0)
    $paramObj.Add($param2)
    $param3 = [Microsoft.Management.Infrastructure.CimMethodParameter]::Create("sValueName", "PhysicalHostNameFullyQualified", 0)
    $paramObj.Add($param3)

    $result = $cimSession.InvokeMethod("root\cimv2", "StdRegProv", "GetStringValue", $paramObj)
    if( $result.ReturnValue.Value -ne 0 )
    {
        return $null
    }

    return $result.OutParameters["sValue"].Value
}

function GetVMGuid($cimSession)
{
    $paramObj = New-Object Microsoft.Management.Infrastructure.CimMethodParametersCollection
    $param1 = [Microsoft.Management.Infrastructure.CimMethodParameter]::Create("hDefKey", ([System.UInt32]"0x80000002"), 0)
    $paramObj.Add($param1)
    $param2 = [Microsoft.Management.Infrastructure.CimMethodParameter]::Create("sSubKeyName", "SOFTWARE\Microsoft\Virtual Machine\Guest\Parameters", 0)
    $paramObj.Add($param2)
    $param3 = [Microsoft.Management.Infrastructure.CimMethodParameter]::Create("sValueName", "VirtualMachineId", 0)
    $paramObj.Add($param3)

    $result = $cimSession.InvokeMethod("root\cimv2", "StdRegProv", "GetStringValue", $paramObj)
    if( $result.ReturnValue.Value -ne 0 )
    {
        return $null
    }

    return $result.OutParameters["sValue"].Value
}

function ValidateGatewayPASetup($gwInfo, $PAIp, $netConn)
{
    Write-Host -ForegroundColor $statusSecondaryColor Validating Provider Address configuration for $PAIp

    $allocatedIP = GetPAAllocationData $netConn.LogicalNetwork $PAIp

    if( $allocatedIP -eq $null )
    {
        Write-Host -ForegroundColor $errorColor Gateway PA address $PAIp not allocated from IP pool
        return $false
    }

    if( $allocatedIP.AssignedToID -ne $gwInfo.NetworkService.ID -or $allocatedIP.AssignedToType -ne "NetworkService")
    {
        Write-Host -ForegroundColor $errorColor Gateway PA address $PAIp is allocated to some other object and is expected to be assigned to NetworkService $networkService.Name
        return $false
    }

    $hostSession = GetCimSession $gwInfo.Hosts[0] -trustedHost (-not $gwInfo.vmHostUsesHttps) 

    $paClusterResources = $hostSession.QueryInstances("Root\mscluster", "WQL", "Select * from MSCluster_Resource where Type = 'Provider Address'");

    $paResourceFound = $false
    foreach($paClusterResource in $paClusterResources)
    {
        if( $paClusterResource.PrivateProperties.Address -eq $PAIp )
        {
            $paResourceFound = $true

            if( $paClusterResource.State -ne 2 )
            {
                Write-Host -ForegroundColor $warningColor PA Resource for the gateway IP $PAIP is offline. Trying to bring it online

                try
                {
                    $result = $hostSession.InvokeMethod("root\mscluster", $paClusterResource, "BringOnline", $null)
                }
                catch
                {
                    Sleep 5
                }

                $paClusterResource = $hostSession.GetInstance("root\mscluster", $paClusterResource)
                if( $paClusterResource.State -ne 2 )
                {
                    Write-Host -ForegroundColor $errorColor PA Resource for the gateway IP $PAIP is offline.
                    return $false
                }
                else
                {
                    Write-Host -ForegroundColor $statusSecondaryColor PA Resource for the gateway IP $PAIP is online.
                }
            }

            
            if( $gwInfo.BackEndHostAdapterName -ne $null -and $gwInfo.BackEndHostAdapterName -ne $paClusterResource.PrivateProperties.InterfaceAlias)
            {
                Write-Host -ForegroundColor $errorColor  "The provider address is marked with adapter name $paClusterResource.PrivateProperties.InterfaceAlias while at least one host has a physical adapter with different name $gwInfo.BackEndHostAdapterName"
                $gwInfo.NeedPARename = $true
            }
            else
            {
                $gwConfig.BackEndHostAdapterName = $paClusterResource.PrivateProperties.InterfaceAlias
            }

            $gwConfig.PAAddressResources += $paClusterResource

        }
    }

    if( -not $paResourceFound )
    {
        Write-Host -ForegroundColor $errorColor PA Resource for $PAIp not found in the cluster $gwInfo.HostClusterName 
        return $false
    }

    return $true
}

function ValidateVMConfiguration($gwConfig, $ndx)
{
    $hyperVVM = $gwConfig.hyperVVMs[$ndx]
    $hostName = $gwConfig.Hosts[$ndx]
    $vmName   = $gwConfig.VMs[$ndx]

    Write-Host -ForegroundColor $statusSecondaryColor Validating VM adapter configuration for $vmName

    $networkAdapters = Get-VMNetworkAdapter -VM $hyperVVM
    
    $backendAdapter = $null
    foreach($netAdap in $networkAdapters)
    {
        $isolationData = Get-VmNetworkAdapterIsolation -VMNetworkAdapter $netAdap
        if( $isolationData -ne $null -and $isolationData.IsolationMode -eq "NativeVirtualSubnet")
        {
            if( $backendAdapter -ne $null )
            {
                Write-Host -ForegroundColor $errorColor More than one adapter in VM $vmName is configured with NativeVirtualSubnet isolation setting data
                return $false
            }

            $backendAdapter = $netAdap
        }
    }

    if( $backendAdapter -eq $null)
    {
        Write-Host -ForegroundColor $errorColor No Adapter in VM $vmName is configured with NativeVirtualSubnet isolation setting data
        return $false
    }

    if( $backendAdapter.SwitchName -eq $null)
    {
        Write-Host -ForegroundColor $errorColor Backend Adapter in VM $vmName is not connected to the switch
        return $false        
    }

    $switch = Get-VMSwitch -ComputerName $hostName -Name $backendAdapter.SwitchName
    if($switch -eq $null)
    {
        Write-Host -ForegroundColor $errorColor Switch with name $backendAdapter.SwitchName not found in host $hostName
        return $false
    }

    if( $switch.NetAdapterInterfaceDescription -eq $null )
    {
        Write-Host -ForegroundColor $errorColor Switch with name $backendAdapter.SwitchName does not have any physical adapter $hostName
        return $false    
    }

    $adapter = Get-NetAdapter -CimSession (GetCimSession $hostName -trustedHost (-not $gwConfig.vmHostUsesHttps)) | where {$_.InterfaceDescription -eq $switch.NetAdapterInterfaceDescription}
    if( $adapter -eq $null )
    {
        Write-Host -ForegroundColor $errorColor Switch with name $backendAdapter.SwitchName does not have physical adapter $switch.NetAdapterInterfaceDescription on host $hostName
        return $false          
    }

    if( $gwConfig.BackEndHostAdapterName -ne $null -and $adapter.Name -ne $gwConfig.BackEndHostAdapterName)
    {
        Write-Host -ForegroundColor $errorColor The backend adapter physical NIC has different name on different host. On host $hostName the name is $adapter.Name while on other host the adapter is named $gwConfig.BackEndHostAdapterName
        $gwConfig.NeedPARename = $true
    }
    else
    {
        $gwConfig.BackEndHostAdapterName = $adapter.Name
    }

    $gwConfig.BackEndPAAdaptersOnHosts += $adapter
    $gwConfig.BackendVMAdaptersHyperV += $backendAdapter

    return $true
}

function RenamePhysicalAdapterOnCluster($gwConfig)
{
    Write-Host -ForegroundColor $operationColor "Wrong adapter names found on cluster nodes"
    $adapterNames = @()
    foreach($adap in $gwConfig.BackEndPAAdaptersOnHosts)
    {
        if( -not $adapterNames.Contains($adap.Name) )
        {
            $adapterNames += $adap.Name
        }
    }

    foreach($paResource in $gwConfig.PAAddressResources)
    {
        if( -not $adapterNames.Contains($paResource.PrivateProperties.InterfaceAlias) )
        {
            $adapterNames += $paResource.PrivateProperties.InterfaceAlias
        }
    }

    $choice = PromptMenu "Select the adapter name to use" $adapterNames

    if($choice -ne 0)
    {
        $adapNameToUse = $adapterNames[$choice-1]
        Write-Host -ForegroundColor $operationColor Renaming all host adapters and PA resources to name it as $adapNameToUse

        for($ndx=0; $ndx -lt $gwConfig.BackEndPAAdaptersOnHosts.Length; $ndx++)
        {
            $adap = $gwConfig.BackEndPAAdaptersOnHosts[$ndx]
            if( $adap.Name -ne $adapNameToUse)
            {
                Write-Host -ForegroundColor $operationColor Renaming adapter $adap.Name in host $adap.PSComputerName to $adapNameToUse
                $result = $adap | Rename-NetAdapter -NewName $adapNameToUse

                $adap2 = Get-NetAdapter -Name $adapNameToUse -CimSession (GetCimSession $gwConfig.Hosts[$ndx])

                if( $adap2 -eq $null -or $adap2.InterfaceIndex -ne $adap.InterfaceIndex)
                {
                    Write-Host -ForegroundColor $errorColor "Renaming adapter failed"
                    return $false
                }
                else
                {
                    Write-Host -ForegroundColor $statusPrimaryColor Renaming adapter $adap.Name in host $adap.PSComputerName to $adapNameToUse succeeded
                }

            }
        }

        for($ndx = 0; $ndx -lt $gwConfig.PAAddressResources.Length; $ndx++)
        {
            $paResource = $gwConfig.PAAddressResources[$ndx]
            if( $paResource.PrivateProperties.InterfaceAlias -ne $adapNameToUse)
            {
                Write-Host -ForegroundColor $operationColor Renaming adapter in cluster resource for $paResource.PrivateProperties.Address from $paResource.PrivateProperties.InterfaceAlias to $adapNameToUse

                $paResource.PrivateProperties.InterfaceAlias = $adapNameToUse
                $paResource.PrivateProperties = $paResource.PrivateProperties

                $hostCimSession = GetCimSession $gwConfig.Hosts[0]
                try
                {
                    $result = $hostCimSession.ModifyInstance("root\mscluster",$paResource)
                }
                catch
                {
                }

                $paResource2 = $hostCimSession.GetInstance("root\mscluster", $paResource)

                if( $paResource2.PrivateProperties.InterfaceAlias -ne $adapNameToUse )
                {
                    Write-Host -ForegroundColor $errorColor Renaming adapter name in cluster resource for $paResource.PrivateProperties.Address failed
                    return $false
                }
                else
                {
                    $result = $hostCimSession.InvokeMethod("root\mscluster",$paResource2, "TakeOffline", $null)
                    if( $result.ReturnValue -ne $null -and $result.ReturnValue.Value -ne 0 )
                    {
                        Write-Host -ForegroundColor $errorColor Renamed the adapter name in cluster resource for $paResource.PrivateProperties.Address. But could not take offline and bring it back
                        return $false                        
                    }
                    
                    $result = $hostCimSession.InvokeMethod("root\mscluster",$paResource2, "BringOnline", $null)
                    if( $result.ReturnValue -ne $null -and $result.ReturnValue.Value -ne 0 )
                    {
                        Write-Host -ForegroundColor $errorColor Renamed the adapter name in cluster resource for $paResource.PrivateProperties.Address. But could not take offline and bring it back
                        return $false                        
                    }

                    Write-Host -ForegroundColor $statusPrimaryColor Renaming adapter in cluster resource for $paResource.PrivateProperties.Address from $paResource.PrivateProperties.InterfaceAlias to $adapNameToUse succeeded
                }

            }
        }

        return $true
    }
    else
    {
        return $false
    }
}

function GetGatewayConfiguration($networkService, [ref]$setupStatus)
{
    $setupStatus.Value = $true
    Write-Host -ForegroundColor $operationColor Getting Gateway Configuration for $networkService.Name
    $gwConfig = New-Object -TypeName PSCustomObject -Property @{
                NetworkService = $networkService
                VMs = $null
                hyperVVMs = $null
                Hosts = $null
                HostToVM = New-Object -TypeName "System.Collections.Generic.Dictionary``2[string,string]" ([System.StringComparer]::OrdinalIgnoreCase)
                VmToHost = New-Object -TypeName "System.Collections.Generic.Dictionary``2[string,string]" ([System.StringComparer]::OrdinalIgnoreCase)
                isHA = $null
                vmUsesHttps = $null
                vmHostUsesHttps = $null
                DomainName = $null
                VmNameGiven = $null
                VMClusterName = $null
                HostClusterName = $null
                PAIpV4 = $null
                PAIpV6 = $null
                MACAddress = $null
                BackEndHostAdapterName = $null
                NeedPARename = $false
                BackEndPAAdaptersOnHosts = @()
                PAAddressResources = @()
                BackendVMAdaptersHyperV = @()
                PADIPConfiguration = $null
                BackendLND = $null
                OwnerNodeIndex = $null
                IsSetupTestOnly = $false
            }

    $hostName = GetParameterFromConnectionString -ConnectionString $NetworkService.ConnectionString -Parameter "VMHost"
    if( $hostName -eq $null )
    {
        Write-Host -ForegroundColor $errorColor VMHost is not specified in connections string in Network Serivce $NetworkService.Name. Connection string should be of the format VMHost=<Host>;GatewayVM=<VM>
        return $null
    }

    $vmName = GetParameterFromConnectionString -ConnectionString $NetworkService.ConnectionString -Parameter "GatewayVM"
    if( $vmName -eq $null )
    {
        Write-Host -ForegroundColor $errorColor GatewayVM is not specified in connections string in Network Serivce $NetworkService.Name. Connection string should be of the format VMHost=<Host>;GatewayVM=<VM>
        return $null
    }

    $gwConfig.DomainName = GetDomainName $vmName
    $gwConfig.VmNameGiven = $vmName

    $vmUsesHttps = GetParameterFromConnectionString -ConnectionString $NetworkService.ConnectionString -Parameter "GatewayVMWSManOverHttps"
    if( $vmUsesHttps -eq "true" )
    {
        $gwConfig.vmUsesHttps = $true
    }
    else
    {
        $gwConfig.vmUsesHttps = $false
    }

    $vmHostUsesHttps = GetParameterFromConnectionString -ConnectionString $NetworkService.ConnectionString -Parameter "VMHostWSManOverHttps"
    if( $vmHostUsesHttps -eq "true" )
    {
        $gwConfig.vmHostUsesHttps = $true
    }
    else
    {
        $gwConfig.vmHostUsesHttps = $false
    }

    $vmSession = $null
    while($true)
    {
        try
        {
            $vmSession = GetCimSession -hostObj $vmName -trustedHost (-not $gwConfig.vmUsesHttps)
            break
        }
        catch
        {
        #prad
            write-host -ForegroundColor $choiceColor ("Unable to connect to the Gateway VM. Is "+$vmName+" a node name? If so, this node seems to be down. Please provide other nodes that are online. Press enter to ignore")
            Write-Host -ForegroundColor $promptColor -NoNewline "Active Gateway VM Node Name : "
            $vmName = read-host
            if( IsNullOrEmpty $vmName)
            {
                throw
            }
        }
    }
    
    $hostSession = $null
    while($true)
    {
        try
        {
            $hostSession = GetCimSession -hostObj $hostName -trustedHost (-not $gwConfig.vmHostUsesHttps) $vmName
            break
        }
        catch
        {
        #prad
            write-host -ForegroundColor $choiceColor ("Unable to connect to the Gateway Host. Is "+$hostName+" a node name? If so, this node seems to be down. Please provide other nodes that are online. Press enter to ignore")
            Write-Host -ForegroundColor $promptColor -NoNewline "Active Gateway Host Node Name : "
            $hostName = read-host
            if( IsNullOrEmpty $hostName)
            {
                throw
            }
        }
    }    
    

    if( $vmSession -eq $null -or $hostSession -eq $null )
    {
        $setupStatus.Value = $false
        Write-Host -ForegroundColor $errorColor "Connection to VM or host cannot be established"
        return
    }


    $vmClusterNodes = $vmSession.EnumerateInstances("Root\mscluster", "mscluster_node")
    $hostClusterNodes = $hostSession.EnumerateInstances("Root\mscluster", "mscluster_node")

    if( $vmClusterNodes -eq $null )
    {
        $gwConfig.IsHa = $false
        $gwConfig.VMs  = @($vmName)
        $gwConfig.Hosts = @($hostName)
        $gwConfig.HostToVM.Add($hostName, $vmName)
        $gwConfig.VmToHost.Add($vmName, $hostName)
    }
    else
    {
        $gwConfig.IsHa = $true
        $gwConfig.VMs  = @()
        $gwConfig.Hosts = @()
        $gwConfig.hyperVVMs = @()

        if( $hostClusterNodes -eq $null )
        {
            $setupStatus.Value = $false
            Write-Host -ForegroundColor $errorColor "Gateway VMs are deployed as cluster but host on which the VMs are deployed are not clustered"
            return
        }

        $vmCluster = $vmSession.EnumerateInstances("Root\mscluster", "mscluster_cluster")
        $vmCluster = @($vmCluster)

        $hostCluster = $hostSession.EnumerateInstances("Root\mscluster", "mscluster_cluster")
        $hostCluster = @($hostCluster)

        if( $vmCluster[0] -ne $null )
        {
            $gwConfig.VMClusterName = $vmCluster[0].Name
        }
        else
        {
            $gwConfig.VMClusterName = $vmName
        }


        $hostClusterNodeNames = @()
        foreach($hostClusterNode in $hostClusterNodes)
        {
            $hostClusterNodeNames += (GetFQDNName $hostClusterNode.Name $gwConfig.DomainName)
        }

        foreach($vmClusterNode in $vmClusterNodes)
        {
            if( $vmClusterNode.State -eq 0 )
            {
                $vmFqdn = GetFQDNName $vmClusterNode.Name $gwConfig.DomainName
                $vmClusterNodeSession = GetCimSession $vmFqdn -trustedHost (-not $gwConfig.vmUsesHttps) -copyFromHost $vmName

                $hostNameForVM = GetHostNameFromVM $vmClusterNodeSession
                if($hostNameForVm -eq $null )
                {
                    $setupStatus.Value = $false
                    Write-Host -ForegroundColor $errorColor "Gateway VMs don't have host information. Is Integration components installed for VM $vmClusterNode.Name?"
                    return
                }

                $vmGuid = GetVMGuid $vmClusterNodeSession
                if( $vmGuid -eq $null )
                {
                    $setupStatus.Value = $false
                    Write-Host -ForegroundColor $errorColor "Gateway VMs don't have VMGuid information. Is Integration components installed for VM $vmClusterNode.Name?"
                    return
                }

                $hostNameOnlyForVM = GetHostName $hostNameForVM
                $fqdnHostNameForVM = GetFQDNName $hostNameForVM $gwConfig.DomainName

                if( -not $hostClusterNodeNames.Contains($hostNameOnlyForVM) -and -not $hostClusterNodeNames.Contains($fqdnHostNameForVM) )
                {
                    $setupStatus.Value = $false
                    Write-Host -ForegroundColor $errorColor "Gateway VM $vmClusterNode.Name is not deployed in the host cluster that is specified in connection string"
                    return
                }

                if($gwConfig.Hosts.Contains($fqdnHostNameForVM) )
                {
                    $setupStatus.Value = $false
                    Write-Host -ForegroundColor $errorColor "Gateway VM $vmClusterNode.Name and $gwConfig.HostToVM[$fqdnHostNameForVM] are deployed in the same host. Deploy one of the VMs in a different host"
                    return
                }

                $gwConfig.VMs += $vmFqdn
                $gwConfig.Hosts += $fqdnHostNameForVM

                $gwConfig.HostToVM.Add($fqdnHostNameForVM, $vmFqdn)
                $gwConfig.VmToHost.Add($vmFqdn, $fqdnHostNameForVM)

                $hstCimSession = GetCimSession $fqdnHostNameForVM -trustedHost (-not $gwConfig.vmHostUsesHttps) -copyFromHost $vmName
                $hyperVVm = Hyper-V\Get-VM -ComputerName $fqdnHostNameForVM -Id $vmGuid

                if( $hyperVVm -eq $null )
                {
                    Write-Host -ForegroundColor $errorColor VM $vmName with id $vmGuid not found in $fqdnHostNameForVM
                    return
                }

                $gwConfig.hyperVVMs += $hyperVVm

                Write-Host -ForegroundColor $statusSecondaryColor "VM $vmName is found in host $fqdnHostNameForVM"
            }

        }
    }


    foreach($hst in $gwConfig.Hosts)
    {
        $vmmHost = Get-SCVMHost -ComputerName $hst

        if(-not $vmmHost.IsDedicatedToNetworkVirtualizationGateway)
        {
            Write-Host -ForegroundColor $errorColor "HyperV Host $hst is not marked as dedicated to Network Virtualization gateway"
            return
        }
    }

    $backEndAdapterFound = $false
    $frontEndConnectionFound = $false
    foreach($netConn in $networkService.NetworkConnections)
    {
        if( $netConn.ConnectionType -eq "BackEnd" )
        {
            $gwConfig.BackendLND = $netConn.LogicalNetworkDefinition

            $backEndAdapterFound = $true

            $gwConfig.PAIpV4  = $netConn.IPv4Address
            $gwConfig.PAIpV6  = $netConn.IPv6Address
            $gwConfig.MACAddress = $netConn.NetworkAdapter.PhysicalAddress.Replace(":","")

            if( $gwConfig.PAIpV4 -eq $null -and $gwConfig.PAIpV6 -eq $null )
            {
                if($networkService.NetworkGateway.VMNetworkGateways.Count -gt 0)
                {
                    Write-Host -ForegroundColor $errorColor "Gateway does not have PA addresses setup in network connection but has VMNetworks attached"
                    return
                }
                else
                {
                    Write-Host -ForegroundColor $warningColor "No VM Network gateways attached. Only partial testing will be done"
                    $gwConfig.IsSetupTestOnly = $true
                }
            }

            if( $netConn.IPv4Address -ne $null )
            {
                if( -not (ValidateGatewayPASetup $gwConfig $netConn.IPv4Address $netConn) )
                {
                    return                    
                }
            }

            if( $netConn.IPv6Address -ne $null )
            {
                if( -not (ValidateGatewayPASetup $gwConfig $netConn.IPv6Address $netConn) )
                {
                    return                    
                }
            }
        }

        if( $netConn.ConnectionType -eq "FrontEnd" )
        {
            $frontEndConnectionFound = $true
        }
    }


    if( -not $backEndAdapterFound )
    {
        Write-Host -ForegroundColor $errorColor Backend connection and adapter cannot be found on the network service. Setup network service connnections.
        return
    }

    if( -not $frontEndConnectionFound )
    {
        Write-Host -ForegroundColor $errorColor Frontend connection and adapter cannot be found on the network service. Setup network service connnections.
        return
    }

    
    #gateway configuration
    $cimSession = GetCimSession $gwConfig.VMs[0]
    $gatewayGroups = $cimSession.QueryInstances("root\mscluster", "WQL", "select * from MSCluster_ResourceGroup where Name = 'HyperV Network Virtualization Gateway'")
    if( $gatewayGroups -eq $null -or $gatewayGroups.Length -eq 0 )
    {
        Write-Host -ForegroundColor $errorColor "Active node of the gateway VM can't be found"
        return
    }

    for($ndx=0; $ndx -lt $gwConfig.VMs.Length; $ndx++)
    {
        if( IsHostNameMatching $gatewayGroups[0].OwnerNode $gwCOnfig.VMs[$ndx]) 
        {
            $gwConfig.OwnerNodeIndex = $ndx
        }
    }

    if($gwConfig.OwnerNodeIndex -eq $null)
    {
        Write-Host -ForegroundColor $errorColor "Gateway owner node name not found in the VMs list"
        return        
    }

    
    $gwConfig.PADIPConfiguration = GetHostPAMetadata $networkService

    $physicalAdapters = @()
    for($ndx = 0; $ndx -lt $gwConfig.VMs.Length; $ndx++)
    {
        $physicalAdapter = $null
        if( -not (ValidateVMConfiguration $gwConfig $ndx))
        {
            return
        }
    }

    if( $gwConfig.NeedPARename -eq $true)
    {
        if( -not (RenamePhysicalAdapterOnCluster $gwConfig))
        {
            return
        }
    }



    return $gwConfig
}

function ValidateGatewayHasCSV ($gwConfig)
{
    $cimSession = GetCimSession -hostObj $gwConfig.VMs[0] -trustedHost (-not $gwConfig.vmUsesHttps)

    $csvs = $cimSession.EnumerateInstances("root\mscluster", "MSCluster_ClusterSharedVolume")

    if( $csvs -ne $null )
    {
        foreach( $csv in $csvs)
        {
            return $true
        }
    }

    return $false
}

function ValidateGatewayQuorum($gwConfig)
{
    $cimSession = GetCimSession -hostObj $gwConfig.VMs[0] -trustedHost (-not $gwConfig.vmUsesHttps)
    $cluster = @($cimSession.EnumerateInstances("root\mscluster", "MSCluster_Cluster"))

    if( $cluster.Length -eq 0 )
    {
        Write-Host -ForegroundColor $errorColor Unable to find cluster object in VM $gwConfig.VMs[0]
        return $false
    }

    if($cluster[0].QuorumTypeValue -ne 2 -and $cluster[0].QuorumTypeValue -ne 3 )
    {
        #no quorum specified in system. Check the number of nodes
        $nodes = @($cimSession.EnumerateInstances("root\mscluster", "MSCluster_Node"))

        if( $nodes.Length -eq 2 )
        {
            Write-Host -ForegroundColor $errorColor "ISSUE: Gateway VM Cluster is setup with 2 nodes, but without QUORUM disk or share. If any node fails, the entire gateway will fail"
        }
        else
        {
            Write-Host -ForegroundColor $warningColor "WARNING: Gateway VM Cluster is setup without Quorum, but does not affect availability"
        }
    }
}

function GetHostClusterPAResource($gwConfig, $paAddr)
{
    $cimSession = GetCimSession $gwConfig.Hosts[0]
    $paClusterResources = $cimSession.QueryInstances("Root\mscluster", "WQL", "Select * from MSCluster_Resource where Type = 'Provider Address'");

    foreach($paClusterResource in $paClusterResources)
    {
        if( $paClusterResource.PrivateProperties.Address -eq $paAddr.ToString())
        {
            return $paClusterResource
        }
    }

    return $null
}

function MoveClusterResource ($resource, $targetHost)
{
    $cimSession = GetCimSession $targetHost

    $resourceGroup = @($cimSession.QueryInstances("root\mscluster", "WQL", ("select * from MSCluster_ResourceGroup where Name = '" + $resource.OwnerGroup + "'")))

    if( $resourceGroup.Length -eq 0 )
    {
        Write-Host -ForegroundColor $errorColor Resource group $resource.OwnerGroup for Host cluster resource $resource.Name can not be found
        return $false
    }
    
    $paramObj = New-Object Microsoft.Management.Infrastructure.CimMethodParametersCollection
    $param1 = [Microsoft.Management.Infrastructure.CimMethodParameter]::Create("NodeName", (GetHostName $targetHost), 0)
    $paramObj.Add($param1)

    $result = $cimSession.InvokeMethod("root\mscluster", $resourceGroup[0], "MoveToNewNode", $paramObj)

    $grp = $cimSession.GetInstance("root\mscluster", $resourceGroup[0]);
    if( -not (IsHostNameMatching $grp.OwnerNode $targetHost) )
    {
        return $false
    }

    return $true
}

function ValidateHostCLusterPAResourceInRightHost($gwConfig, $paAddr)
{
    $resource = GetHostClusterPAResource $gwConfig $paAddr

    if( $resource -eq $null )
    {
        Write-Host -ForegroundColor $errorColor Provider Address cluster resource for address $paAddr not found in Gateway host cluster
        return $false
    }

    if( -not (IsHostNameMatching $resource.OwnerNode $gwConfig.Hosts[$gwConfig.OwnerNodeIndex]) )
    {
        Write-Host -ForegroundColor $warningColor Provider Address cluster resource for address $paAddr is found in host $resource.OwnerNode while gateway resource is running on VM ($gwConfig.VMs[$gwConfig.OwnerNodeIndex]) in host ($gwConfig.Hosts[$gwConfig.OwnerNodeIndex])

        if(-not (MoveClusterResource $resource $gwConfig.Hosts[$gwConfig.OwnerNodeIndex]) )
        {
            Write-Host -ForegroundColor $errorColor Provider Address cluster resource for address $paAddr is found in host $resource.OwnerNode while gateway resource is running on VM ($gwConfig.VMs[$gwConfig.OwnerNodeIndex]) in host ($gwConfig.Hosts[$gwConfig.OwnerNodeIndex])
            return $false
        }
        else
        {
            Write-Host -ForegroundColor $statusSecondaryColor Provider Address cluster resource for address $paAddr is moved to the right host
        }
    }
    
    return $true
}

function ValidatePAGroupActiveOnProperNode($gwConfig)
{
    if( $gwConfig.PAIpV4 -ne $null )
    {
        if( -not (ValidateHostCLusterPAResourceInRightHost $gwConfig $gwConfig.PAIpV4) )
        {
            return $false
        }
    }

    if( $gwConfig.PAIpV6 -ne $null )
    {
        if( -not (ValidateHostCLusterPAResourceInRightHost $gwConfig $gwConfig.PAIpV6) )
        {
            return $false
        }
    }

    return $true
}


function ValidateGatewayVMCluster($gwConfig)
{
    $returnValue = $true

    $cimSession = GetCimSession $gwConfig.VMs[0]
    $gatewayGroups = $cimSession.QueryInstances("root\mscluster", "WQL", "select * from MSCluster_ResourceGroup where Name = 'HyperV Network Virtualization Gateway'")

    $gatewayGroup = $null
    if( $gatewayGroups -ne $null )
    {
        foreach($gwGrp in $gatewayGroups)
        {
            $gatewayGroup = $gwGrp
        }
    }

    if( $gatewayGroup -eq $null )
    {
        Write-Host -ForegroundColor $errorColor "Gateway cluster group not found in gateway"
        return $false
    }

    if( $gatewayGroup.State -ne 0 )
    {
        Write-Host -ForegroundColor $errorColor "Gateway cluster group is not online"
    }

    $clusterResources = $cimSession.QueryInstances("root\mscluster", "WQL", "select * from MSCluster_Resource where OwnerGroup = 'HyperV Network Virtualization Gateway'")
    if( $clusterResources -eq $null )
    {
        Write-Host -ForegroundColor $errorColor "Gateway cluster resources not found"
        return $false
    }

    $rrasResource = $null
    $ipResource = $null
    foreach($clusterRes in $clusterResources)
    {
        if( $clusterRes.Name -eq "RasResource" )
        {
            $rrasResource = $clusterRes
        }
        else
        {
            if( $clusterRes.Type -eq "IP Address" )
            {
                $ipResource = $clusterRes
            }
        }

        if( $clusterRes.State -ne 2 )
        {
            Write-Host -ForegroundColor $warningColor Cluster Resource ($clusterRes.Name) is not online, in state ($clusterRes.State). Trying to bring it online

            try
            {
                $result = $cimSesssion.InvokeMethod("root\mscluster", $clusterRes, "BringOnline", $null)
            }
            catch
            {
                Sleep 5
            }

            $clusterRes = $cimSession.GetInstance("root\mscluster", $clusterRes)

            if( $clusterRes.State -ne 2 )
            {
                Write-Host -ForegroundColor $errorColor Cluster Resource ($clusterRes.Name) is not online, in state ($clusterRes.State)
                $returnValue = $false
            }
            else
            {
                Write-Host -ForegroundColor $statusSecondaryColor Cluster Resource ($clusterRes.Name) is online
            }
        }
    }

    
    if( -not $gwConfig.NetworkService.ConnectionString.Contains("FrontEndServerAddress") )
    {
        $rrasClusterResourceType = $cimSession.QueryInstances("root\mscluster", "WQL", "select * from MSCluster_ResourceType where DllName = 'rasclusterres.dll' and DisplayName = 'RAS Cluster Resource'")
        $rrasClusterResourceTypeArr = @($rrasClusterResourceType)
        if( $rrasClusterResourceType -eq $null -or $rrasClusterResourceTypeArr[0] -eq $null)
        {
            Write-Host -ForegroundColor $warningColor "RRAS Cluster Resource type not found"

            $result = Add-ClusterResourceType -Name "RAS Cluster Resource" -Dll $env:windir\System32\RasClusterRes.dll -Cluster $gwConfig.VMClusterName 

            $rrasClusterResourceType = $cimSession.QueryInstances("root\mscluster", "WQL", "select * from MSCluster_ResourceType where DllName = 'rasclusterres.dll' and DisplayName = 'RAS Cluster Resource'")
            $rrasClusterResourceTypeArr = @($rrasClusterResourceType)
            if( $rrasClusterResourceType -eq $null -or $rrasClusterResourceTypeArr[0] -eq $null)
            {
                Write-Host -ForegroundColor $errorColor 'RRAS Cluster Resource type not found. Run this command on one of nodes of the VM cluster > Add-ClusterResourceType -Name "RAS Cluster Resource" -Dll $env:windir\System32\RasClusterRes.dll'          

                return $false
            }
        }
    }

    if($rrasResource -eq $null -and -not $gwConfig.NetworkService.ConnectionString.Contains("FrontEndServerAddress") )
    {
        Write-Host -ForegroundColor $errorColor "RRAS Cluster Resource not found"
        return $false
    }


    if( $ipResource -eq $null )
    {
        Write-Host -ForegroundColor $errorColor "RRAS Front end IP address resource not found"
        return $false
    }

    return $returnValue
}

function ValidateGatewayMetaDataConfiguration($gwConfig)
{
    $result = $true
    if($gwConfig.PADIPConfiguration -eq $null )
    {
        if( $gwConfig.IsSetupTestOnly )
        {
            Write-Host -ForegroundColor $warningColor "Provider address DIP allocation missing for gateway. This is expected if gateway was never configured with VMNetworks"
        }
        else
        {
            Write-Host -ForegroundColor $errorColor "Provider address DIP allocation missing for gateway"
            $result = $false
        }
    }
    else
    {
        $permanentNodeIndex = @{}
        for($ndx = 0; $ndx -lt $gwConfig.Hosts.Length; $ndx++)
        {
            $hst = $gwConfig.Hosts[$ndx]

            $paDipConfiguration = $null
            foreach($padip in $gwConfig.PADIPConfiguration)
            {
                if(IsHostNameMatching $hst $paDip.NodeName )
                {
                    $paDipConfiguration = $padip
                }
            }

            if($paDipConfiguration -eq $null)
            {
                Write-Host -ForegroundColor $errorColor "Provider address DIP Allocation missing for host $hst"
                $result = $false
            }
            else
            {
                if(-not (IsHostNameMatching $paDipConfiguration.GatewayVMNodeName $gwConfig.HostToVM[$hst]) ) 
                {
                    Write-Host -ForegroundColor $errorColor "Provider address DIP Allocation has wrong VM Name for host $hst. Expected $gwConfig.HostToVM[$hst] actual $paDipConfiguration.GatewayVMNodeName"
                    $result = $false
                }

                if($gwConfig.BackendVMAdaptersHyperV[$ndx].MacAddress.ToLower() -ne $paDipConfiguration.BackendAdapterMACAddress.ToLower() )
                {
                    Write-Host -ForegroundColor $errorColor "Provider address DIP Allocation has wrong MAC Address for host $hst. Expected $gwConfig.BackendVMAdaptersHyperV[$ndx].MacAddress actual $paDipConfiguration.BackendAdapterMACAddress"
                    $result = $false
                }

                if( $permanentNodeIndex.ContainsKey($paDipConfiguration.PermanentNodeIndex) )
                {
                    Write-Host -ForegroundColor $errorColor Provider address DIP allocation has duplicate permanent node index with value $paDipConfiguration.PermanentNodeIndex. Hosts are $hst and ($permanentNodeIndex[$paDipConfiguration.PermanentNodeIndex])
                    $result = $false
                }
                else
                {
                    $permanentNodeIndex.Add($paDipConfiguration.PermanentNodeIndex, $hst)
                }

                foreach($paAddr in $paDipConfiguration.ProviderAddresses)
                {
                    $paAddrAllocation = GetPAAllocationData $gwConfig.BackendLND.LogicalNetwork $paAddr.Address
                    if( $paAddrAllocation -eq $null )
                    {
                        Write-Host -ForegroundColor $errorColor Provider address DIP allocation for host $hst is not reserved in IP pool. IP Address $paAddr.Address
                        $result = $false
                    }
                    else
                    {
                        if( $paAddrAllocation.AssignedToID -ne $gwConfig.NetworkService.ID -or $paAddrAllocation.AssignedToType -ne "NetworkService")
                        {
                            Write-Host -ForegroundColor $errorColor Provider address DIP allocation $paAddr.Address for host $hst is not assigned to network service
                            $result = $false
                        }

                        if( $paAddrAllocation.AllocatingAddressPool.VLanID -ne $paAddr.VLANId )
                        {
                            Write-Host -ForegroundColor $errorColor Provider address DIP $paAddr.Address allocation for host $hst has wrong VLAN. Expected $paAddrAllocation.AllocatingAddressPool.VLanID actual $paAddr.VLANId
                            $result = $false
                        }

                        if( $paAddr.PAGateway.Length -ne $paAddrAllocation.AllocatingAddressPool.DefaultGateways.Count )
                        {
                            Write-Host -ForegroundColor $errorColor Provider address DIP $paAddr.Address allocation for host $hst has wrong gateway setting
                            $result = $false
                        }
                        else
                        {
                            foreach($paGw in $paAddr.PAGateway)
                            {
                                $foundMatch = $false
                                foreach($defGw in $paAddrAllocation.AllocatingAddressPool.DefaultGateways)
                                {
                                    if( $defGw.IPAddress -eq $paGw.GatewayAddress )
                                    {
                                        $foundMatch = $true
                                    }
                                }

                                if( -not $foundMatch )
                                {
                                    Write-Host -ForegroundColor $errorColor Provider address DIP $paAddr.Address allocation for host $hst has gateway address $paGw.GatewayAddress that is not found in IP pool
                                    $result = $false                                    
                                }
                            }
                        }
                    }
                }
            }
        }
    }



    #validate PA VIP address

    return $result

}

function ValidateVMNetworkRoutingDOmainOnVM( $gwCOnfig, $ndx, $routingVSID, $VMNetwork)
{
    $returnValue = $true

    # find the adapter
    $rdid = $vmNetwork.RoutingDomainID.ToString("B").ToLower()

    $compartment = Get-NetCompartment -CimSession (GetCimSession $gwConfig.VMs[$ndx]) | where {$_.CompartmentGuid.ToLower() -EQ $rdid}
    if( $compartment -eq $null )
    {
        Write-Host -ForegroundColor $errorColor Compartment for VMNetwork $vmNetwork.Name not found in VM $gwConfig.VMs[$ndx]
        return $false
    }

    $ipInterface = Get-NetIPInterface -CimSession (GetCimSession $gwConfig.VMs[$ndx]) -IncludeAllCompartments -CompartmentId $compartment.CompartmentId | where {$_.AddressFamily -eq $vmNetwork.CAIPAddressPoolType.ToString() -and $_.InterfaceAlias -eq ("WNVAdap_" + $routingVSID)}
    if( $ipInterface -eq $null )
    {
        Write-Host -ForegroundColor $errorColor IP Interface for VMNetwork $vmNetwork.Name not found in VM $gwConfig.VMs[$ndx]
        return $false
    }

    if( $ipINterface.InterfaceAlias -ne ("WNVAdap_" + $routingVSID) )
    {
        Write-Host -ForegroundColor $errorColor IP Interface for VMNetwork $vmNetwork.Name has unexpected name in VM $gwConfig.VMs[$ndx]. Expected ("WNVAdap_" + $routingVSID) actual $ipINterface.InterfaceAlias
        return $false
    }

    $ipAddress = Get-NetIPAddress -CimSession (GetCimSession $gwConfig.VMs[$ndx]) -IncludeAllCompartments -InterfaceIndex $ipINterface.InterfaceIndex -AddressFamily $vmNetwork.CAIPAddressPoolType.ToString()
    if( $ipAddress -eq $null )
    {
        Write-Host -ForegroundColor $errorColor IP Interface for VMNetwork $vmNetwork.Name has unexpected name in VM $gwConfig.VMs[$ndx]. Expected ("WNVAdap_" + $routingVSID) actual $ipINterface.InterfaceAlias
        return $false
    }

    $gwVIPAddress = $null
    $gwSubnet = $null
    if( $vmNetwork.CAIPAddressPoolType -eq "IPV4")
    {
        $gwVIPAddress = $vmNetwork.VMNetworkGateways[0].IPv4Address
        $gwSubnet = [HNVDiagnostics.IPSubnet]::Parse($vmNetwork.VMNetworkGateways[0].IPv4Subnet)
    }
    else
    {
        $gwVIPAddress = $vmNetwork.VMNetworkGateways[0].IPv6Address
        $gwSubnet = [HNVDiagnostics.IPSubnet]::Parse($vmNetwork.VMNetworkGateways[0].IPv6Subnet)
    }

    if( $ndx -eq $gwConfig.OwnerNodeIndex )
    {
        # check if the IP resource is created
        $cimSession = GetCimSession $gwConfig.VMs[$ndx]
        $clusterResource = @($cimsession.QueryInstances("root\mscluster", "WQL", ("select * from mscluster_resource where name = 'Customer Gateway IP "+ $routingVSID +"' and OwnerGroup  = 'HyperV Network Virtualization Gateway'")))
        if( $clusterResource.Length -eq 0 )
        {
            Write-Host -ForegroundColor $errorColor Cluster Resource for IP $gwVIPAddress for VMNetwork $vmNetwork.Name is not found in cluster. Expected resource VIP address Address $gwVIPAddress, prefix length $gwSubnet.PrefixLength, VSID  $routingVSID, RDID $rdid
            $returnValue = $false
        }

        if( $clusterResource[0].PrivateProperties.Address -ne $gwVIPAddress -or $clusterResource[0].PrivateProperties.PrefixLength -ne $gwSubnet.PrefixLength -or $clusterResource[0].PrivateProperties.RDID -ne $rdid -or $clusterResource[0].PrivateProperties.VSID -ne $routingVSID )
        {
            Write-Host -ForegroundColor $errorColor Cluster Resource for IP $gwVIPAddress for VMNetwork $vmNetwork.Name is not found in cluster. Expected resource VIP address Address $gwVIPAddress, prefix length $gwSubnet.PrefixLength, VSID  $routingVSID, RDID $rdid. Actual resource VIP address Address $clusterResource[0].PrivateProperties.Address, prefix length $clusterResource[0].PrivateProperties.PrefixLength, VSID  $clusterResource[0].PrivateProperties.VSID, RDID $clusterResource[0].PrivateProperties.RDID
            $returnValue = $false
        }

        $ipMatch = $ipAddress | where {$_.IPAddress -eq $gwVIPAddress }
        if( $ipMatch -eq $null )
        {
            Write-Host -ForegroundColor $errorColor IP Interface for VMNetwork $vmNetwork.Name in VM $gwConfig.VMs[$ndx] does not have VIP address $gwVIPAddress online on NICInterface $ipINterface.InterfaceIndex on compartment $compartment.CompartmentId.
            $returnValue = $false
        }  
    }

    $gwDipConfiguration = GetPADIPForHost $gwConfig $GwConfig.Hosts[$ndx]
    if( $gwDipConfiguration -eq $null )
    {
        Write-Host -ForegroundColor $errorColor DIP Configuration information not found for VM $gwConfig.VMs[$ndx]
        $returnValue = $false
    }
    else
    {
        $gwDipAddressStart = [HNVDiagnostics.IPSubnet]::IncrementIPAddress([HNVDiagnostics.IPSubnet]::IncrementIPAddress($gwSubnet.GetFirstIPAddress()))
        $gwDIPAddress = $gwDipAddressStart

        for($ndx2 = 0; $ndx2 -lt $gwDipConfiguration.PermanentNodeIndex; $ndx2++)
        {
            $gwDIPAddress = [HNVDiagnostics.IPSubnet]::IncrementIPAddress($gwDIPAddress)
        }

        $ipMatch = $ipAddress | where {$_.IPAddress -eq $gwDIPAddress.ToString() }
        if( $ipMatch -eq $null )
        {
            Write-Host -ForegroundColor $warningColor IP Interface for VMNetwork $vmNetwork.Name in VM $gwConfig.VMs[$ndx] does not have DIP address $gwDIPAddress on NICInterface $ipINterface.InterfaceIndex on compartment $compartment.CompartmentId.. Should not impact service. IGNORED
        }
    } 

    $routes = Get-NetRoute -CimSession (GetCimSession $gwConfig.VMs[$ndx]) -IncludeAllCompartments -InterfaceIndex $ipINterface.InterfaceIndex

    #check for gateway subnet routes
    $route = $routes | where {$_.DestinationPrefix -eq $gwSubnet.ToString() -and $_.NextHop -eq (GetOnlinkAddress $VMNetwork)}
    if( $route -eq $null )
    {
        Write-Host -ForegroundColor $errorColor Gateway VM $gwConfig.VMs[$ndx] does not have correct route for VMNetwork $vmNetwork.Name on NICInterface $ipINterface.InterfaceIndex on compartment $compartment.CompartmentId. Missing route $gwSubnet to (GetOnlinkAddress $VMNetwork)
        $returnValue = $false
    }

    #check for VMSubnet routes
    foreach($vmSubnet in $vmNetwork.VMSubnet)
    {
        $route = $routes | where {$_.DestinationPrefix -eq $vmSubnet.SubnetVLans[0].Subnet -and $_.NextHop -eq ($gwSubnet.GetFirstIPAddress().ToString())}
        if( $route -eq $null )
        {
            Write-Host -ForegroundColor $errorColor Gateway VM $gwConfig.VMs[$ndx] does not have correct route for VMNetwork $vmNetwork.Name on NICInterface $ipINterface.InterfaceIndex on compartment $compartment.CompartmentId. Missing route $vmSubnet.SubnetVLans[0].Subnet to ($gwSubnet.GetFirstIPAddress().ToString())
            $returnValue = $false
        }
    }

    return $returnValue
}

function ValidateGatewayRoutingDomainForVMNetworkGateway($gwConfig, $vmNetworkGw)
{
    Write-Host -ForegroundColor $operationColor Validating Routing domain settings for VM Network $vmNetworkGw.VMNetwork.Name

    $vmNetworkStatus = $true

    $rdidStr = $vmNetworkGw.VMNetwork.RoutingDomainID.ToString("B").ToLower()

    $routingSubnet = $null
    if( $vmNetworkGw.VMNetwork.CAIPAddressPoolType -eq "IPV4")
    {
        $routingSubnet = $vmNetworkGw.IPv4Subnet
    }
    else
    {
        $routingSubnet = $vmNetworkGw.IPv6Subnet
    }

    for($ndx=0; $ndx -lt $gwConfig.BackendVMAdaptersHyperV.Length; $ndx++)
    {
        $bkEndAdapter = $gwConfig.BackendVMAdaptersHyperV[$ndx]

        $routingDomains = @(Get-VMNetworkAdapterRoutingDomainMapping -VMNetworkAdapter $bkEndAdapter)
            
        if( $routingDomains -eq $null -or $routingDomains.length -eq 0 )
        {
            Write-Host -ForegroundColor $errorColor Routing domain mapping on HyperV not found for VM $gwConfig.VMs[$ndx] on host $gwCOnfig.Hosts[$ndx]
            $vmNetworkStatus = $false
        }
        else
        {
            $rdidSetting = $null
            foreach($rdid in $routingDomains)
            {
                if( $rdid.RoutingDomainID.ToLower() -eq $rdidStr)
                {
                    $rdidSetting = $rdid
                    break
                }
            }

            if( $rdidSetting -eq $null )
            {
                Write-Host -ForegroundColor $errorColor Routing domain mapping for VMNetwork $vmNetworkGw.VMNetwork.Name not found for VM $gwConfig.VMs[$ndx] on host $gwCOnfig.Hosts[$ndx]
                $vmNetworkStatus = $false
            }
            else
            {
                if( $rdidSetting.IsolationID.Length -ne 1 -or $rdidSetting.IsolationName.Length -ne 1)
                {

                    Write-Host -ForegroundColor $errorColor Routing domain mapping for VMNetwork $vmNetworkGw.VMNetwork.Name configured incorrectly for VM $gwConfig.VMs[$ndx] on host $gwCOnfig.Hosts[$ndx]
                    $vmNetworkStatus = $false
                }
                else
                {
                    $routingVSID = $rdidSetting.IsolationID[0]

                    if( -not (ValidateVMNetworkRoutingDOmainOnVM $gwCOnfig $ndx $routingVSID $vmNetworkGw.VMNetwork) )
                    {
                        $vmNetworkStatus = $false
                    }
                }
            }
        }
    }

    return $vmNetworkStatus
}

function ValidateGatewayRoutingDomain($gwConfig)
{
    $returnValue = $true
    foreach($vmNetworkGw in $gwCOnfig.NetworkService.NetworkGateway.VMNetworkGateways)
    {

        if( -not (ValidateGatewayRoutingDomainForVMNetworkGateway $gwConfig $vmNetworkGw) )
        {
            $returnValue = $false
        }
    }

    return $returnValue
}

function GetNatClusterObject($gwConfig, $vmNetwork)
{
    $cimSession = GetCimSession $gwConfig.VMs[$gwConfig.OwnerNodeIndex]

    $natInstances = @($cimSession.QueryInstances("root\mscluster", "WQL", "select * from mscluster_resource where Type = 'nat' and OwnerGroup  = 'HyperV Network Virtualization Gateway'"))

    foreach($natInst in $natInstances)
    {
        if( $natInst.PrivateProperties.Name.ToLower() -eq $vmNetwork.RoutingDomainId.ToString().ToLower() -and $natInst.PrivateProperties.InternalRDID.ToLower() -eq $vmNetwork.RoutingDomainId.ToString("B").ToLower())
        {
            return $natInst
        }
    }

    return $null
}

function ValidateNatConnectionObject($gwConfig, $vmNetwork)
{
    $clusObj = GetNatClusterObject $gwConfig $vmNetwork

    if( $clusObj -eq $null )
    {
        write-host -ForegroundColor $errorColor VM network $vmNetwork.Name does not have NAT cluster objects
        return $false
    }

    if( $clusObj.State -ne 2 )
    {
        write-host -ForegroundColor $errorColor VM network $vmNetwork.Name NAT resource object $clusObj.Name is not online. It is in state $clusObj.State
        return $false
    }

    $wmiNatObject = Get-NetNat -CimSession (GetCimSession $gwConfig.VMs[$gwConfig.OwnerNodeIndex]) -Name $clusObj.Name
    if($wmiNatObject -eq $null)
    {
        write-host -ForegroundColor $errorColor VM network $vmNetwork.Name NAT resource object $clusObj.Name does not have corresponding NAT object in WMI
        return $false
    }

    $wmiExternalIP = Get-NetNatExternalAddress -CimSession (GetCimSession $gwConfig.VMs[$gwConfig.OwnerNodeIndex]) -NatName $clusObj.Name
    if( $wmiExternalIP -eq $null -or $wmiExternalIP.IPAddress -ne $vmnetwork.VMNetworkGateways[0].NATConnections[0].Rules[0].ExternalIPAddress.ToString())
    {
        write-host -ForegroundColor $errorColor VM network $vmNetwork.Name NAT resource object $clusObj.Name does not have corresponding NAT object for IP address
        return $false
    }

    $wmiStaticMappings = Get-NetNatStaticMapping -CimSession (GetCimSession $gwConfig.VMs[$gwConfig.OwnerNodeIndex]) -NatName $clusObj.Name -ErrorAction SilentlyContinue
    foreach($natRule in $vmNetwork.VMNetworkGateways[0].NATConnections[0].Rules)
    {
        if( $natRule.InternalIPAddress -ne $null)
        {
            $wmiMapping = $wmiStaticMappings | where {$_.Protocol.ToString() -eq $natRule.Protocol.ToString() -and $_.InternalIPAddress -eq $natRule.InternalIPAddress -and $_.InternalPort -eq $natRule.InternalPort -and $_.ExternalPort -eq $natRule.ExternalPort -and $_.ExternalIPAddress -eq $natRule.ExternalIPAddress}

            if( $wmiMapping -eq $null )
            {
                Write-Host -ForegroundColor $errorColor VM network $vmNetwork.Name NAT resource object $clusObj.Name does not have corresponding NAT Rule for $natRule.ExternalIPAddress:$natRule.ExternalPort to $natRule.InternalIPAddress:$natRule.InternalPort
                return $false
            }
        }
    }
    
    return $true
}

function ValidateVPNConnectionObject($gwConfig, $vpnConn)
{
    $cimSession = GetCimSession $gwCOnfig.VMs[$gwConfig.OwnerNodeIndex]

    $compartment = Get-NetCompartment -CimSession $cimSession | where {$_.CompartmentGuid -eq $vpnConn.VMNetworkGateway.VMNetwork.RoutingDomainId.ToString("B")}

    if( $compartment -eq $null )
    {
        Write-Host -ForegroundColor $errorColor Unable to find the Compartment for VMNetwork $vpnConn.VMNetworkGateway.VMNetwork.Name in VM $gwCOnfig.VMs[$gwConfig.OwnerNodeIndex]
        return $false
    }

    $paramObj = New-Object Microsoft.Management.Infrastructure.CimMethodParametersCollection
    $param1 = [Microsoft.Management.Infrastructure.CimMethodParameter]::Create("RoutingDomain", $compartment.CompartmentDescription , 0)
    $paramObj.Add($param1)
    $result = $cimSession.InvokeMethod("root\Microsoft\Windows\RemoteAccess", "PS_VpnS2SInterface", "Get", $paramObj)

    $targetAddr = $null
    $cloudIP = $null
    if( [System.String]::IsNullOrEmpty($vpnConn.TargetVPNIPv4Address) )
    {
        $targetAddr = $vpnConn.TargetVPNIPv6Address
        $cloudIP = $vpnConn.CloudVPNIPv6Address
    }
    else
    {
        $targetAddr = $vpnConn.TargetVPNIPv4Address
        $cloudIP = $vpnConn.CloudVPNIPv4Address
    }

    $wmiVPNObj = $null
    foreach($vpnObj in $result.OutParameters["cmdletOutput"].Value)
    {
        if( ($vpnObj.Destination.Contains($targetAddr.ToString()) -or $vpnObj.Destination.Contains($targetAddr.ToString()) ) -and $vpnObj.SourceIpAddress -eq $cloudIP.ToString())
        {
            $wmiVPNObj = $vpnObj
            break
        }
    }

    if( $wmiVPNObj -eq $null )
    {
        Write-Host -ForegroundColor $errorColor Unable to find VPN connection for VMNetwork $vpnConn.VMNetworkGateway.VMNetwork.Name for target address $targetAddr
        return $false
    }

    if( -not $wmiVPNObj.AdminStatus)
    {
        Write-Host -ForegroundColor $errorColor VPN connection for VMNetwork $vpnConn.VMNetworkGateway.VMNetwork.Name for target address $targetAddr is not enabled
        return $false
    }

    if( $wmiVPNObj.ConnectionState -ne "Connected" )
    {
        Write-Host -ForegroundColor $warningColor VPN connection for VMNetwork $vpnConn.VMNetworkGateway.VMNetwork.Name for target address $targetAddr failed to connect. Current state $wmiVPNObj.ConnectionState.  Error code $wmiVPNObj.LastError
    }

    return $true
}

function ValidateBGPConfiguration($gwConfig, $VMNEtwork)
{
    $returnValue = $true
    $cimSession = GetCimSession $gwCOnfig.VMs[$gwConfig.OwnerNodeIndex]

    $compartment = Get-NetCompartment -CimSession $cimSession | where {$_.CompartmentGuid -eq $vpnConn.VMNetworkGateway.VMNetwork.RoutingDomainId.ToString("B")}

    if( $compartment -eq $null )
    {
        Write-Host -ForegroundColor $errorColor Unable to find the Compartment for VMNetwork $vpnConn.VMNetworkGateway.VMNetwork.Name in VM $gwCOnfig.VMs[$gwConfig.OwnerNodeIndex]
        return $false
    }

    $paramObj = New-Object Microsoft.Management.Infrastructure.CimMethodParametersCollection
    $routingDomain = @($compartment.CompartmentDescription)
    $param1 = [Microsoft.Management.Infrastructure.CimMethodParameter]::Create("RoutingDomain", $routingDomain, 0)
    $paramObj.Add($param1)
    $result = $cimSession.InvokeMethod("root\Microsoft\Windows\RemoteAccess", "PS_BgpRouter", "Get", $paramObj)

    foreach($bgpRouter in $result.OutParameters["cmdletOutput"].Value)
    {
        if( $bgpRouter.LocalASN -ne $vmNetwork.VMNetworkGateways[0].AutonomousSystemNumber -or ($bgpRouter.BgpIdentifier -ne $vmNetwork.VMNetworkGateways[0].IPv4Address -and $bgpRouter.BgpIdentifier -ne $vmNetwork.VMNetworkGateways[0].IPv6Address) )
        {
            Write-Host -ForegroundColor $errorColor BGP ASN is not setup correctly. Expected values for ASN $vmNetwork.VMNetworkGateways[0].AutonomousSystemNumber found $bgRouter.LocalASN, BGP Identifier expected $vmNetwork.VMNetworkGateways[0].IPv4Address found $bgRouter.BgpIdentifier
            $returnValue = $false
        }
    }

    $paramObj = New-Object Microsoft.Management.Infrastructure.CimMethodParametersCollection
    $param1 = [Microsoft.Management.Infrastructure.CimMethodParameter]::Create("RoutingDomain", $compartment.CompartmentDescription, 0)
    $paramObj.Add($param1)
    $result = $cimSession.InvokeMethod("root\Microsoft\Windows\RemoteAccess", "PS_BgpPeer", "Get", $paramObj)
    foreach($bgpPeer in $vmNetwork.VMNetworkGateways[0].BGPPeers)
    {
        $bgpPeerFound = $false
        foreach($bgpPeer2 in $result.OutParameters["cmdletOutput"].Value)
        {
            if( ($bgpPeer2.LocalIPAddress -eq $vmNetwork.VMNetworkGateways[0].IPv4Address -or $bgpPeer2.LocalIPAddress -eq $vmNetwork.VMNetworkGateways[0].IPv6Address) -and ($bgpPeer2.PeerIPAddress -eq $bgpPeer.PeerIPAddress) -and $bgpPeer2.PeerASN -eq $bgpPeer.PeerASN)
            {
                $bgpPeerFound = $true

                if( $bgpPeer2.ConnectivityStatus -ne 3 )
                {
                    $StatusString = "Connected"
                    switch($bgpPeer2.ConnectivityStatus)  
                    {
                        1 { $StatusString = "Idle" }
                        2 { $StatusString = "Connecting" }
                        4 { $StatusString = "Stopped" }
                    }

                    Write-Host -ForegroundColor $warningColor BGP Peer $bgpPeer2.PeerIPAddress for VMNetwork $vmNetwork.Name is in state $StatusString
                }
            }

            if(-not $bgpPeerFound)
            {
                Write-Host -ForegroundColor $errorColor BGP Peer $bgpPeer2.PeerIPAddress for VMNetwork $vmNetwork.Name is not found in gateway
                $returnValue = $false
            }
        }
    }

    $result = $cimSession.InvokeMethod("root\Microsoft\Windows\RemoteAccess", "PS_BgpCustomRoute", "Get", $paramObj)
    $customRoutes = $result.OutParameters["cmdletOutput"].Value[0]

    foreach($vmSubnet in $vmNetwork.VMSubnet)
    {
        if(-not $customRoutes.Network.Contains($vmSubnet.SubnetVLans[0].Subnet) )
        {
            Write-Host -ForegroundColor $errorColor BGP for VMNetwork $vmNetwork.Name does not have BGP custom routes configured for subnet $vmSubnet.SubnetVLans[0].Subnet
            $returnValue = $false
        }
    }

    if( -not $customRoutes.Network.Contains($vmNetwork.VMNetworkGateways[0].IPv4Subnet) -and -not $customRoutes.Network.Contains($vmNetwork.VMNetworkGateways[0].IPv6Subnet))
    {
        Write-Host -ForegroundColor $errorColor BGP for VMNetwork $vmNetwork.Name does not have BGP custom routes configured for gateway subnet $vmNetwork.VMNetworkGateways[0].IPv4Subnet or $vmNetwork.VMNetworkGateways[0].IPv6Subnet
        $returnValue = $false
    }

    return $returnValue
}

function ValidateGwVMNetworkClusterObject($gwConfig, $VMNEtwork)
{
    Write-Host -ForegroundColor $operationColor Validating Routing domain cluster objects for VM Network $VMNetwork.Name

    $returnValue = $true
    # validate NAT objects
    $cimSession = GetCimSession $gwConfig.VMs[$gwConfig.OwnerNodeIndex]

    foreach($natConn in $VMNEtwork.VMNetworkGateways[0].NATConnections)
    {
        if(-not (ValidateNatConnectionObject $gwConfig $vmNetwork) )
        {
            $returnValue = $false
        }
    }

    foreach($vpnConn in $VMNEtwork.VMNetworkGateways[0].VPNConnections)
    {
        if( -not (ValidateVPNConnectionObject $gwConfig $vpnConn) )
        {
            $returnValue = $false
        }
    }

    if( $vmNetwork.VMNetworkGateways[0].EnableBGP )
    {
        if( -not (ValidateBGPConfiguration $gwConfig $VMNEtwork) )
        {
            $returnValue = $false
        }
    }

    return $returnValue
}

function ValidateGatewayRoutingDomainClusterObjects($gwConfig)
{
    $returnValue = $true
    foreach($vmNetworkGw in $gwCOnfig.NetworkService.NetworkGateway.VMNetworkGateways)
    {
        if(-not (ValidateGwVMNetworkClusterObject $gwConfig $vmNetworkGw.VMNEtwork))
        {
            $returnValue = $false
        }
    }

    return $returnValue
}

function ValidateGatewayVMRoutes($gwConfig)
{
    $returnValue = $true

    $frontEndConnection = $gwConfig.NetworkService.NetworkConnections | where {$_.ConnectionType -eq "FrontEnd"}
    $frontEndSubnet = [HNVDiagnostics.ipsubnet]::Parse($frontEndConnection.LogicalNetworkDefinition.SubnetVLans[0].Subnet)

    foreach($vm in $gwConfig.VMs)
    {
        Write-Host -ForegroundColor $operationColor Validating routing configuration in gateway VM $vm

        $cimSession = GetCimSession $vm

        $defaultGWs = @(Get-NetRoute -CimSession $cimSession -DestinationPrefix "0.0.0.0/0")

        $gatewayToSameAdapter = $true
        $wrongDefaultGwAddresses = @()

        $frontendGwMetric = [System.Int32]::MaxValue;
        $metricsLower = $true

        if($defaultGWs.Count -gt 0 )
        {
            $defaultGwAddresses += $defaultGws[0].NextHop

            foreach($defaultGW in $defaultGWs)
            {
                if( $frontEndSubnet.IsValidAddress($defaultGw.NextHop))
                {
                    if( $defaultGw.RouteMetric -lt $frontendGwMetric )
                    {
                        $frontendGwMetric = $defaultGw.RouteMetric
                    }
                }
            }

            foreach($defaultGw in $defaultGws)
            {
                if($defaultGw.ifIndex -ne $defaultGws[0].IfIndex )
                {
                    $gatewayToSameAdapter = $false
                }

                if(-not $frontEndSubnet.IsValidAddress($defaultGw.NextHop))
                {
                    $wrongDefaultGwAddresses += $defaultGw.NextHop
                    if( $defaultGW.RouteMetric -le $frontendGwMetric)
                    {
                        $metricsLower = $false
                    }
                }
            }
        }

        if( -not $gatewayToSameAdapter )
        {
            $colorToPrint = $errorColor

            if( $metricsLower )
            {
                $colorToPrint = $warningColor
            }

            Write-Host -ForegroundColor $colorToPrint Gateway VM $VM has more than one default gateway. Only front end adapter should have default gateway and management adapter should have specific routes configured. Invalid gateways found are
            foreach($defGw in $wrongDefaultGwAddresses)
            {
                Write-Host -ForegroundColor $colorToPrint $defGw
            }
            Write-Host -ForegroundColor $colorToPrint Remove the above default gateways and setup explicit routes on the VMs for subnets that can be reached through those gateways

            if(-not $metricsLower)
            {
                $returnValue = $false
            }
        }
    }


    return $returnValue
}

function DiagnoseGwSetup($networkService, [ref]$status)
{
    Write-Host -ForegroundColor $operationColor Running tests on gateway $networkService.Name

    $status.Value = New-Object -TypeName PSCustomObject -Property @{
                Setup                  = $null
                VmFeatureConfiguration = $null
                VmClusterConfiguration = $null
                MetadataConfiguration  = $null
                RoutingDomainConfiguration = $null
                RoutingDomainClusterObject = $null
                GatewayVMRoutes        = $null
            }

    $isHA = $false;
    $hostToVm = New-Object -TypeName "System.Collections.Generic.Dictionary``2[string,string]"

    $setupStatus = $null
    $gwConfig = GetGatewayConfiguration $networkService -setupStatus ([ref]$setupStatus)
    $status.Value.Setup = $setupStatus

    if( $gwConfig -eq $null )
    {
        return
    }

    if(-not (ValidateGatewayHasCSV $gwConfig) )
    {
        Write-Host -ForegroundColor $errorColor "VM cluster must have a CSV volume to function as gateway"
        $status.Value.Setup = $false
        return
    }

    ValidateGatewayQuorum $gwConfig

    if( -not (ValidatePAGroupActiveOnProperNode $gwConfig) )
    {
        Write-Host -ForegroundColor $errorColor "Host cluster PA resource cannot be validated against VM resource"
        $status.Value.Setup = $false
        return
    }

    $status.Value.VmClusterConfiguration = ValidateGatewayVMCluster $gwConfig

    $status.Value.MetadataConfiguration  = ValidateGatewayMetaDataConfiguration $gwConfig

    $status.Value.RoutingDomainConfiguration = ValidateGatewayRoutingDomain $gwConfig

    $status.Value.RoutingDomainClusterObject = ValidateGatewayRoutingDomainClusterObjects $gwConfig

    $status.Value.GatewayVMRoutes = ValidateGatewayVMRoutes $gwConfig
}

function WriteResult3($result, $operationType, $ignoreFailure)
{
    for($ndx = $operationType.Length; $ndx -le 60 ; $ndx++)
    {
        $operationType += " "
    }
    Write-Host -ForegroundColor $statusSecondaryColor -NoNewline "    $operationType : "

    if( $result -eq $null )
    {
        Write-Host -ForegroundColor $operationColor Not run
    }

    if( $result -eq $false )
    {
        if( $ignoreFailure )
        {
            Write-Host -ForegroundColor $operationColor "Failed (Ignored)"
        }
        else
        {
            Write-Host -ForegroundColor $errorColor Failed
        }
    }

    if( $result -eq $true )
    {
        Write-Host -ForegroundColor $statusPrimaryColor Success
    }
}

function WriteResult($result, $operationType)
{
    WriteResult3 $result $operationType $false
}


function GetHNVAdapterFromUser($vmName)
{
    $vm1 = GetVM $vmName
    $hnvAdap1 = GetHNVAdapter $vm1
    $ipAddr1 = GetHNVIPAddress $hnvAdap1

    $adapterInfo = New-Object -TypeName PSCustomObject -Property @{
                    vm = $vm1
                    hnvAdap = $hnvAdap1
                    ipAddr = $ipAddr1
                }

    Write-Host -ForegroundColor $statusSecondaryColor VM $vm1.Name connected to VMNetwork $hnvAdap1.VMNetwork.Name "("$hnvAdap1.VMSubnet.Name")" with IP address $ipAddr1 is selected for testing

    return $adapterInfo 
}

function ProcessGwConnectivityDiagnosticsAndPrint($srcAdapter, [ref]$result)
{
        DiagnoseGatewayConnectivity $srcAdapter -status $result
        Write-Host -ForegroundColor $statusPrimaryColor ============================================================================
        Write-Host -ForegroundColor $statusPrimaryColor Status of VM to Gateway test
        Write-Host -ForegroundColor $statusPrimaryColor ============================================================================
        WriteResult $result.Value.GatewaySetup "Gateway VM setup Test"
        WriteResult $result.Value.GatewayVmClusterConfiguration "Gateway VM Cluster Test"
        WriteResult $result.Value.GatewayMetadataConfiguration "Metadata store for the gateway Test"
        WriteResult $result.Value.GatewayRoutingDomainConfiguration "Gateway Routing Domain Configuration Test"
        WriteResult $result.Value.GatewayRoutingDomainClusterObject "Gateway Routing Domain Cluster Object Test"
        WriteResult $result.Value.GatewayVMRoutes     "Routing Configuration in gateway VMs Test"
        WriteResult $result.Value.PolicyStatus "Host Policy Test"
        WriteResult $result.Value.GatewayPolicyStatus "Gateway Host Policy Test"
        WriteResult $result.Value.PingStatus  "Ping VM to Gateway Test"
        WriteResult3 $result.Value.PAGatewayPingStatus  "Ping VM PA Address to PA Router" $result.Value.PAPingStatus
        WriteResult $result.Value.PAPingStatus  "Ping VM PA Address to HNV Gateway's PA"
        Write-Host -ForegroundColor $statusPrimaryColor ============================================================================
}

function ProcessUserInputGwDiagnostics($srcAdapter)
{
    $continueLoop = $false
    do
    {
        $continueLoop = $false

        $result = $null
        ProcessGwConnectivityDiagnosticsAndPrint $srcAdapter -result ([ref]$result)

        if($result.PolicyStatus -ne $true -or $result.GatewayPolicyStatus -ne $true)
        {
                $choice = PromptMenu "Policy Errors. Select what to do" @("Fix policy error")
                switch($choice)
                {
                1 
                {
                    Write-Host -ForegroundColor $operationColor Refreshing VM $srcAdapter.vm.Name
                    $tmp = Read-SCVirtualMachine -VM $srcAdapter.vm -Force
                    Write-Host -ForegroundColor $operationColor Waiting 10 seconds for policy to be published
                    Sleep 10
                    $continueLoop = $true
                }
                }
        }
        else
        {
            if($result.PAPingStatus -ne $true)
            {
                Write-Host -ForegroundColor $errorColor "Fix the issue in provider address space and retry the operation (is the gateway devices (routes) and switches (VLANs) in PA space configured correctly?)"
            }
        }
    }
    while($continueLoop)
}

function ProcessVMConnectivityDiagnosticsAndPrint($srcAdapter, $dstAdapter, [ref]$status)
{
        DiagnostVm2VmConnectivity $srcAdapter $dstAdapter  -status $status

        Write-Host -ForegroundColor $statusPrimaryColor ============================================================================
        Write-Host -ForegroundColor $statusPrimaryColor Status of VM to VM test
        Write-Host -ForegroundColor $statusPrimaryColor ============================================================================
        WriteResult $status.Value.SourceVMPolicyStatus "Source VM Host Policy Test"
        WriteResult $status.Value.DestVMPolicyStatus "Destination VM Host Policy Test"
        WriteResult $status.Value.ConsistentPolicy "Policy consistency between VMs Test"
        WriteResult $status.Value.PingStatus "Ping between VM Test"
        WriteResult3 $status.Value.PAGatewayPingStatus  "Ping VM PA Address to PA Router" $status.Value.PAPingStatus
        WriteResult $status.Value.PAPingStatus  "Ping Source VM PA Address to Destingation VM PA Address"
        Write-Host -ForegroundColor $statusPrimaryColor ============================================================================

}

function ProcessUserInputVm2VmDiagnostics($srcAdapter)
{
    Write-Host -ForegroundColor $promptColor Select Destination VM to test connectivity against
    $dstAdapter = GetHNVAdapterFromUser

    while($dstAdapter.hnvAdap.VMNetwork.ID -ne $srcAdapter.hnvAdap.VMNetwork.ID)
    {
        Write-Host -ForegroundColor $errorColor The VM/adapters are connected to different VMNetwork. Connectivity cannot be tested
        $dstAdapter  = GetHNVAdapterFromUser
    }

    $continueLoop = $false
    do
    {
        $continueLoop = $false

        $status = $null
        ProcessVMConnectivityDiagnosticsAndPrint $srcAdapter $dstAdapter -status ([ref]$status)

        if( $status.SourceVMPolicyStatus -ne $true -or $status.DestVMPolicyStatus -ne $true)
        {
                $choice = PromptMenu "Policy Errors. Select what to do" @("Fix policy error")
                switch($choice)
                {
                    1 
                    {
                        Write-Host -ForegroundColor $operationColor Cleaning up bad WNV policies
                        Remove-NetVirtualizationProviderAddress -AddressState Duplicate -CimSession (GetCimSession $srcAdapter.vm.VMHost) -ErrorAction SilentlyContinue -ErrorVariable $t
                        Remove-NetVirtualizationProviderAddress -AddressState Duplicate -CimSession (GetCimSession $dstAdapter.vm.VMHost) -ErrorAction SilentlyContinue -ErrorVariable $t

                        Write-Host -ForegroundColor $operationColor Refreshing VM $srcAdapter.vm.Name
                        $tmp = Read-SCVirtualMachine -VM $srcAdapter.vm -Force
                        
                        Write-Host -ForegroundColor $operationColor Refreshing VM $dstAdapter.vm.Name
                        $tmp = Read-SCVirtualMachine -VM $dstAdapter.vm -Force

                        Write-Host -ForegroundColor $operationColor Waiting 10 seconds for policy to be published
                        Sleep 10
                        $continueLoop = $true
                    }
                }
        }
        else
        {
            if($status.PAPingStatus -ne $true)
            {
                Write-Host -ForegroundColor $errorColor "Fix the issue in provider address space and retry the operation (is the gateway (routes) and switches (VLANs) in PA space configured correctly?)"
            }
        }
    }
    while($continueLoop)
}



function ProcessUserInputVMDiagnostics()
{
    Write-Host -ForegroundColor $promptColor Select Source VM To Run Diagnostics against
    $srcAdapter = GetHNVAdapterFromUser

    $choice = PromptMenu "Select target type" @("VM-to-Gateway connectivity diagnostics", "VM-to-VM connectivity Diagnostics")

    switch($choice)
    {
        1 
        {
            ProcessUserInputGwDiagnostics $srcAdapter
        }

        2
        {
            ProcessUserInputVm2VmDiagnostics $srcAdapter
        }
    }
}

function DiagnoseGwSetupAndPrintStatus($selectedNS)
{
        $status = $null
        DiagnoseGwSetup $selectedNS -status ([ref]$status)
        
        Write-Host -ForegroundColor $statusPrimaryColor ============================================================================
        Write-Host -ForegroundColor $statusPrimaryColor Status of Gateway Setup test
        Write-Host -ForegroundColor $statusPrimaryColor ============================================================================
        WriteResult $status.Setup "Gateway VM setup Test"
        WriteResult $status.VmClusterConfiguration "Gateway VM Cluster Test"
        WriteResult $status.MetadataConfiguration "Metadata store for the gateway Test"
        WriteResult $status.RoutingDomainConfiguration "Routing Domain Configuration Test"
        WriteResult $status.RoutingDomainClusterObject "Routing Domain Cluster Object Test"
        WriteResult $status.GatewayVMRoutes     "Routing Configuration in gateway VMs Test"
        Write-Host -ForegroundColor $statusPrimaryColor ============================================================================
}

function ProcessUserInputGWSetupDiagnostics()
{
    $nses = Get-SCNetworkService | where {$_.ConfigurationProvider.Name -eq "Microsoft Windows Server Gateway Provider"}

    $userPromptInfo = @()
    foreach($ns in $nses)
    {
        $descriptionString = $ns.Name
        $descriptionString += "   "
        $descriptionString += $ns.ConnectionString
        $userPromptInfo += $descriptionString
    }

    if($userPromptInfo.Length -gt 0)
    {
        $selectedNS = $nses[0]

        if($userPromptInfo.Length -gt 1)
        {
            $choice = PromptMenu "Select Gateway Network Service" $userPromptInfo
            if( $choice -eq 0 )
            {
                return
            }

            $selectedNS = $nses[$choice-1]
        }

        DiagnoseGwSetupAndPrintStatus $selectedNS

    }
}

function IsNullOrEmpty($argument)
{
    return $argument -eq $null -or $argument.Length -eq 0
}

#main script start

if( -not (IsNullOrEmpty $GatewayService) )
{
    if( -not (IsNullOrEmpty $SourceVM) -or -not (IsNullOrEmpty $DestinationVM) )
    {
        ExitScript "GatewayService and VM parameters cannot be specified together"
    }
}

if( -not (IsNullOrEmpty $DestinationVM) )
{
    if(IsNullOrEmpty $SourceVM)
    {
        ExitScript "DestinationVM cannot be specified without SourceVM parameter"
    }
}

$hypervCmdlets = Get-WindowsFeature -Name Hyper-V-PowerShell
if( $hypervCmdlets -eq $null -or -not $hypervCmdlets.Installed)
{
    $choice = PromptMenu "HyperV Powershell modules not installed. Do you want to install it" @("Yes")

    switch($choice)
    {
        0 { ExitScript "HyperV Powershell modules required for this script" }
        1 { 
            Write-Host -ForegroundColor $operationColor "Installing HyperV Powershell modules"
            Install-WindowsFeature -Name Hyper-V-PowerShell -IncludeAllSubFeature 
        }
    }
}

if($VMMDBCredential -ne $null )
{
    AddCredential "VMM DB Admin" $VMMDBCredential
}

if( $VMMServerCredential -ne $null )
{
    AddCredential "VMM Server" $VMMServerCredential 
}

if( $AllHostCredential -ne $null )
{
    AddCredential "All Server" $AllHostCredential 
}

if(IsNullOrEmpty $vmmServer)
{
    Write-Host -ForegroundColor $promptColor -NoNewline "VMM Server : "
    $vmmServer = Read-Host
}

$vmmCredential  = GetCredential "VMM Server"
$vmmServerConnection = $null
if($vmmCredential -eq $null)
{
    $vmmServerConnection = Get-SCVMMServer -ComputerName $vmmServer
}
else
{
    $vmmServerConnection = Get-SCVMMServer -ComputerName $vmmServer -Credential $vmmCredential
}

if( $vmmServerConnection -eq $null )
{
    ExitScript "VMM Server connection failed. Ensure VMM server is running and the credential provided has access. If credential does not have permission, specify the VMM credential using VMMServerCredential option"
}

if(-not (IsNullOrEmpty $vmmServerConnection.ActiveVMMNode) )
{
    $activeVMMServerName = $vmmServerConnection.ActiveVMMNode
}

if( $GatewayService -ne $null -and $GatewayService.Length -ne 0 )
{
    $gwSvc = Get-SCNetworkService -Name $GatewayService
    if( $gwSvc -eq $null )
    {
        Write-Host -ForegroundColor $errorColor "The gateway service with the name $GatewayService not found"
    }
    else
    {
        DiagnoseGwSetupAndPrintStatus $gwSvc
    }
}
else
{
    if( $sourceVM -ne $null -and $sourceVM.Length -gt 0 )
    {
        $srcAdapter = GetHNVAdapterFromUser $sourceVM

        if( $srcAdapter -eq $null )
        {
            Write-Host -ForegroundColor $errorColor "Source VM with the given name cannot be found or not unique"
        }
        else
        {
            if( $DestinationVM -ne $null -and $DestinationVM.Length -gt 0 )
            {
                $dstAdapter = GetHNVAdapterFromUser $DestinationVM
                if( $dstAdapter -eq $null )
                {
                    Write-Host -ForegroundColor $errorColor "Destination VM with the given name cannot be found or not unique"
                }
                else
                {
                    $status = $null
                    ProcessVMConnectivityDiagnosticsAndPrint $srcAdapter $dstAdapter -status ([ref]$status)
                }
            }
            else
            {
                $result = $null
                ProcessGwConnectivityDiagnosticsAndPrint $srcAdapter -result ([ref]$result)
            }
        }
    }
    else
    {
        $choice = PromptMenu "Select diagnostic type" @("Validate Gateway setup", "Diagnose Connectivity Problem")
        switch($choice)
        {
            1
            {
                ProcessUserInputGWSetupDiagnostics
            }

            2
            {
                ProcessUserInputVMDiagnostics
            }
        }
    }
}

$RunspacePool.Dispose()

if( $global:PSSession -ne $null )
{
    $tmp = Disconnect-PSSession -Session $global:PSSession
    $tmp = Remove-PSSession -Session $global:PSSession
}
$global:PSSession = $null